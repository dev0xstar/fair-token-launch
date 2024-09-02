import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  mocha: {
    timeout: 6000000000000
  },
  networks: {
    hardhat: {
      forking: {
        url: 'https://eth-mainnet.g.alchemy.com/v2/AcptWBmH9mRjOCvY0LdPiTvOK9vZVXFe'
      }
    }
  }
};

export default config;
