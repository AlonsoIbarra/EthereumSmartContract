const hre = require("hardhat");
const ContractJson = require("./artifacts/contracts/Lock.sol/Lock.json");
const abi = ContractJson.abi;
require("dotenv").config();

async function main() {
    const provider = new hre.ethers.JsonRpcProvider(process.env.API_URL);
    const userWallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const lockAddress = process.env.CONTRACT_ADDRESS;
    const Lock = new hre.ethers.Contract(
        lockAddress,
        abi,
        userWallet
    );

    // Check contract state
    const currentUnlockTime = await Lock.unlockTime();
    const contractOwner = await Lock.owner();
    const balance = await provider.getBalance(lockAddress);
    
    console.log("Contract address:", lockAddress);
    console.log("Contract balance:", hre.ethers.formatEther(balance), "ETH");
    console.log("Unlock time:", new Date(Number(currentUnlockTime) * 1000).toLocaleString());
    console.log("Owner address:", contractOwner);
    console.log("Current wallet address:", userWallet.address);
    console.log("Is wallet the owner?", contractOwner.toLowerCase() === userWallet.address.toLowerCase());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});