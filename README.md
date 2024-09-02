# Fair Launch Token

### Constructor

#### `constructor(uint256 amount, uint256 startDate, uint256 endDate, uint256 lpPercent, uint256 ticks)`

- amount: The amount of token to be minted
- startDate: The start date of the sale
- endDate: The end date of the sale
- lpPercent: The percent of the token to be used for LP
- ticks: The total ticks of the sale

### Read Functions

#### `getCurrentTokenForUser(address user)`

Returns the minted token amount for the user in the current tick

#### `getTokenPerTick()`

Returns the assigned token account per tick

#### `getCurrentTickIndex()`

Returns the current tick

### Write Functions

#### `setTicks(uint256 ticks) onlyOwner`

Updates the total ticks

- ticks: The total ticks of the sale

#### `enter(uint256 _usdtAmount)`

Adds the user with USDT deposit in the current tick

- \_usdtAmount: The USDT deposit amount

#### `exit()`

Removes the user from the sale with returning the USDT deposit

#### `claim()`

Sends the mined token amount to the user after the sale finished

#### `createPair()`

Creates a LP with the token and USDT after the sale finished

### Gas Usage (Estimation)

- Enter: 174975 = 0,0013998 (4$)
- Exit: 141069 = 0,001128552 (3$)
- Claim: 114821 = 0,000918568 (2.70$)
- Create: 2750300 = 0,0220024 (66.24$)
