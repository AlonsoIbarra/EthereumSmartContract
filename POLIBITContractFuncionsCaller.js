
const hre = require("hardhat");
require("dotenv").config();

// Import the contract ABI from the compiled artifacts
const PoliBitContractJson = require("./artifacts/contracts/PoliBitContractERC20.sol/PoliBitContractERC20D3.json");
const abi = PoliBitContractJson.abi;

async function main() {
    // Set up provider and wallet
    const provider = new hre.ethers.JsonRpcProvider(process.env.API_URL);
    const userWallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY, provider);

    // Connect to the deployed PoliBit contract
    const poliBitContractAddress = process.env.POLIBIT_CONTRACT_ADDRESS;
    const poliBitContract = new hre.ethers.Contract(
        poliBitContractAddress,
        abi,
        userWallet
    );

    console.log("---- PoliBit Contract Information ----");
    console.log("Contract address:", poliBitContractAddress);
    
    // Get token metadata
    const name = await poliBitContract.name();
    const symbol = await poliBitContract.symbol();
    const decimals = await poliBitContract.decimals();
    const totalSupply = await poliBitContract.totalSupply();
    
    console.log("Token name:", name);
    console.log("Token symbol:", symbol);
    console.log("Token decimals:", decimals);
    console.log("Total supply:", hre.ethers.formatUnits(totalSupply, decimals));
    
    // Get token parameters specific to PoliBit
    try {
        const tokenValue = await poliBitContract.tokenValue();
        console.log("Token value:", tokenValue.toString());
    } catch (error) {
        console.log("Token value function not available on this contract");
    }
    
    try {
        const maxTokens = await poliBitContract.maxTokens();
        console.log("Max tokens:", maxTokens.toString());
    } catch (error) {
        console.log("Max tokens function not available on this contract");
    }
    
    // Check wallet balance
    const walletBalance = await poliBitContract.balanceOf(userWallet.address);
    console.log("Wallet address:", userWallet.address);
    console.log("Wallet token balance:", hre.ethers.formatUnits(walletBalance, decimals));
    
    // return;
    // Try minting tokens (this will only work if there are no access controls)
    const mintAmount = hre.ethers.parseUnits("1", decimals);
    try {
        console.log(`\nAttempting to mint ${hre.ethers.formatUnits(mintAmount, decimals)} tokens to wallet...`);
        const mintTx = await poliBitContract.mint(userWallet.address, mintAmount);
        const receipt = await mintTx.wait();
        console.log("Mint successful! Transaction hash:", receipt.hash);
        
        // Check updated balance
        const newBalance = await poliBitContract.balanceOf(userWallet.address);
        console.log("Updated wallet token balance:", hre.ethers.formatUnits(newBalance, decimals));
    } catch (error) {
        console.log("Mint operation failed:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
