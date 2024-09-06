// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import "hardhat/console.sol";

contract Token is ERC20, Ownable {
    using SafeERC20 for IERC20;

    struct TickAccount {
        uint256 enter;
        uint256 exit;
        uint256 deposit;
        bool isClaimed;
    }

    struct TickState {
        uint256 deposit;
        uint256 users;
    }

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;

    uint256 public _totalSupply;
    uint256 public _startDate;
    uint256 public _endDate;
    uint256 public _ticks;
    uint256 public _lpPercent;

    uint256 public _totalDeposit;
    uint256 public _totalUsers;

    mapping(address => TickAccount) public tickAccounts;
    mapping(uint256 => TickState) public tickStates;

    event Entered(address indexed user, uint256 amount, uint256 tick);
    event Exited(
        address indexed user,
        uint256 amount,
        uint256 entered,
        uint256 exited
    );
    event Claimed(address indexed user, uint256 amount);

    constructor(
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 lpPercent,
        uint256 ticks
    ) ERC20("", "") Ownable(msg.sender) {
        _totalSupply = amount;
        _startDate = startDate;
        _endDate = endDate;
        _lpPercent = lpPercent;
        _ticks = ticks;

        _mint(address(this), _totalSupply);
    }

    function setTicks(uint256 ticks) external onlyOwner {
        require(block.timestamp < _startDate, "Sale started");

        _ticks = ticks;
    }

    function enter(uint256 _usdtAmount) external {
        TickAccount storage tickAccount = tickAccounts[msg.sender];
        require(tickAccount.enter == 0, "Already entered");
        require(_usdtAmount > 0, "Invalid usdt amount");

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), _usdtAmount);

        uint256 curTick = getCurrentTickIndex();

        tickAccount.enter = curTick + 1;
        tickAccount.deposit = _usdtAmount;

        _totalDeposit += _usdtAmount;
        _totalUsers += 1;

        for (uint i = curTick + 1; i <= _ticks; i++) {
            TickState storage tickState = tickStates[i];
            tickState.deposit += _usdtAmount;
            tickState.users += 1;
        }

        emit Entered(msg.sender, _usdtAmount, curTick + 1);
    }

    function exit() external {
        TickAccount storage tickAccount = tickAccounts[msg.sender];
        require(block.timestamp <= _endDate, "Sale finished");
        require(tickAccount.enter > 0, "Not entered");
        require(tickAccount.exit == 0, "Already exited");

        uint256 curTick = getCurrentTickIndex();

        tickAccount.exit = curTick;

        uint256 usdtAmount = tickAccount.deposit;

        IERC20(USDT).safeTransfer(msg.sender, usdtAmount);

        for (uint i = tickAccount.enter; i <= _ticks; i++) {
            TickState storage tickState = tickStates[i];
            tickState.deposit -= usdtAmount;
            tickState.users -= 1;
        }

        emit Exited(
            msg.sender,
            tickAccount.deposit,
            tickAccount.enter,
            tickAccount.exit
        );
    }

    function claim() external {
        TickAccount storage tickAccount = tickAccounts[msg.sender];
        require(block.timestamp > _endDate, "Sale not finished");
        require(tickAccount.enter > 0, "Not entered");
        require(tickAccount.exit == 0, "Exited");
        require(!tickAccount.isClaimed, "Already claimed");

        tickAccount.isClaimed = true;

        uint256 userAmount = getCurrentTokenForUser(msg.sender);

        _transfer(address(this), msg.sender, userAmount);

        emit Claimed(msg.sender, userAmount);
    }

    function createPair() external {
        require(block.timestamp > _endDate, "Sale not finished");

        address _pair = IUniswapV2Factory(IUniswapV2Router(ROUTER).factory())
            .createPair(address(this), USDT);

        pair = _pair;

        uint256 tokenAmountDesired = (_totalSupply * _lpPercent) / 10000;
        uint256 usdtAmountDesired = IERC20(USDT).balanceOf(address(this));

        _approve(address(this), ROUTER, tokenAmountDesired);
        IERC20(USDT).forceApprove(ROUTER, usdtAmountDesired);

        IUniswapV2Router(ROUTER).addLiquidity(
            USDT,
            address(this),
            usdtAmountDesired,
            tokenAmountDesired,
            0,
            0,
            owner(),
            block.timestamp + 1000
        );
    }

    function getCurrentTokenForUser(
        address user
    ) public view returns (uint256) {
        TickAccount memory tickAccount = tickAccounts[user];

        if (tickAccount.enter == 0 || tickAccount.exit > 0) {
            return 0;
        }

        uint256 curTick = getCurrentTickIndex();

        uint256 amountPerTick = getTokenPerTick();

        uint256 userAmount = 0;

        for (uint i = tickAccount.enter; i <= curTick; i++) {
            uint256 userAmountInTick = (amountPerTick * tickAccount.deposit) /
                tickStates[i].deposit;

            userAmount += userAmountInTick;
        }

        return userAmount;
    }




}
