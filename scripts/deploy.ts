import { ethers } from "hardhat";

async function main() {
    const startDate = BigInt(Math.floor(Date.now() / 1000))
    const endDate = startDate + 600n
    const token = await ethers.deployContract("Token", [1000000000000000000000000n, startDate, endDate, 6000n, 10n]);

    await token.waitForDeployment();

    console.log("Token:", token.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
