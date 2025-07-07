require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config();

const { API_URL, PRIVATE_KEY } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200  // Low runs value for deployment optimization
      }
    }
  },
  networks: {
    amoy: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 80002,
      gasPrice: 35000000000,
    }
  }
};
