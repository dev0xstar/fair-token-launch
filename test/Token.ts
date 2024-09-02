import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployToken() {
    const [owner] = await hre.ethers.getSigners()

    const users = await Promise.all(Array(400).fill('').map(async () => {
      const wallet = ethers.Wallet.createRandom()
      await ethers.provider.send("hardhat_impersonateAccount", [wallet.address]);
      return ethers.provider.getSigner(wallet.address);
    }))
    const USDT = await hre.ethers.getContractAt('IERC20', '0xdAC17F958D2ee523a2206206994597C13D831ec7')



    const Token = await hre.ethers.getContractFactory("Token");
    const startDate = BigInt(Math.floor(Date.now() / 1000) + 1200)
    const endDate = startDate + 60000n
    const token = await Token.deploy(1000000000000000000000000n, startDate, endDate, 6000n, 10n);

    const usdtVaults = await hre.ethers.getImpersonatedSigner('0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503')


    for (let i = 0; i < 400; i++) {
      await owner.sendTransaction({ from: owner.address, to: users[i].address, value: ethers.parseEther('1') })
      await (await USDT.connect(usdtVaults).transfer(users[i].address, ethers.parseUnits('1000', 6))).wait()
    }

    return { token, users, owner, USDT, startDate, endDate };
  }

  describe("Token", function () {
    it("Enter ticks", async function () {
      const { token, owner, users, USDT, startDate, endDate } = await loadFixture(deployToken);

      for (let i = 0; i < 40; i++) {
        await (await USDT.connect(users[i]).approve(token.target, ethers.parseUnits('1000', 6))).wait()
      }

      await time.increaseTo(Number(startDate) + 100);
      console.log(await token.getCurrentTickIndex())
      for (let i = 1; i < 100; i++) {
        await (await token.connect(users[i]).enter(ethers.parseUnits(Math.floor(Math.random() * 999 + 1).toString(), 6))).wait()
      }

      await time.increaseTo(Number(startDate) + 6100);
      console.log(await token.getCurrentTickIndex())
      for (let i = 100; i < 200; i++) {
        await (await token.connect(users[i]).enter(ethers.parseUnits(Math.floor(Math.random() * 999 + 1).toString(), 6))).wait()
      }

      await time.increaseTo(Number(startDate) + 18100);
      console.log(await token.getCurrentTickIndex())
      for (let i = 200; i < 300; i++) {
        await (await token.connect(users[i]).enter(ethers.parseUnits(Math.floor(Math.random() * 999 + 1).toString(), 6))).wait()
      }

      await time.increaseTo(Number(startDate) + 30100);
      console.log(await token.getCurrentTickIndex())
      for (let i = 300; i < 400; i++) {
        await (await token.connect(users[i]).enter(ethers.parseUnits(Math.floor(Math.random() * 999 + 1).toString(), 6))).wait()
      }

      const enterTx = await (await token.connect(users[0]).enter(ethers.parseUnits(Math.floor(Math.random() * 999 + 1).toString(), 6))).wait()

      console.log('Enter: ', enterTx?.gasPrice, enterTx?.gasUsed)


      await time.increaseTo(Number(startDate) + 48100);

      const exitTx = await (await token.connect(users[300]).exit()).wait()

      console.log('Exit: ', exitTx?.gasPrice, exitTx?.gasUsed)

      await time.increaseTo(Number(endDate) + 100)

      const claimTx = await (await token.connect(users[200]).claim()).wait()

      console.log('Claim: ', claimTx?.gasPrice, claimTx?.gasUsed)

      const createTx = await (await token.createPair()).wait()

      console.log('Create: ', createTx?.gasPrice, createTx?.gasUsed)


    });
  });

});
