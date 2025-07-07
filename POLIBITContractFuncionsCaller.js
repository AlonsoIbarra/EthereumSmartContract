
const hre = require("hardhat");
require("dotenv").config();

// Import the contract ABI from the compiled artifacts
const PoliBitContractJson = require("./artifacts/contracts/PoliBitContractERC20.sol/PoliBitContractERC20.json");
const abi = PoliBitContractJson.abi;

async function main() {
    // Set up provider and wallet
    const provider = new hre.ethers.JsonRpcProvider(process.env.API_URL);
    const ownerWallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY, provider);

    // Connect to the deployed PoliBit contract
    const poliBitContractAddress = process.env.POLIBIT_CONTRACT_ADDRESS;
    const poliBitContract = new hre.ethers.Contract(
        poliBitContractAddress,
        abi,
        ownerWallet
    );

    console.log("---- PoliBit Contract Information ----");
    console.log("Contract address:", poliBitContractAddress);
    
    // Get token metadata
    const name = await poliBitContract.name();
    const symbol = await poliBitContract.symbol();
    const decimals = await poliBitContract.decimals();
    const totalSupply = await poliBitContract.totalSupply();
    const userWallet = process.env.POLIBIT_USER_ADDRESS;
    
    // Define source and destination addresses
    const destinationWallet = process.env.TRANSFER_DESTINATION_ADDRESS;
    const sourceWallet = process.env.TRANSFER_SOURCE_ADDRESS;
    const stringAmount = process.env.TRANSFER_AMOUNT;


    console.log("********* CONTRACT DATA *************");
    console.log("contract address:", poliBitContractAddress);
    console.log("contract token name:", name);
    console.log("contrat symbol:", symbol);
    console.log("contract decimals:", decimals);
    console.log("Current tokens:", hre.ethers.formatUnits(totalSupply, decimals));
    
    // Get token parameters specific to PoliBit
    try {
        const tokenValue = await poliBitContract.value();
        console.log("token value:", tokenValue.toString());
    } catch (error) {
        console.log("error:", error.message);
    }
    
    try {
        const maxTokens = await poliBitContract.maxTokens();
        console.log("Max token allowed:", maxTokens.toString());
    } catch (error) {
        console.log("error geting max tokens:", error.message);
    }

    // const walletBalance = await poliBitContract.balanceOf(userWallet);
    // console.log("address:", userWallet);
    // console.log("balance:", hre.ethers.formatUnits(walletBalance, decimals));
    
    // console.log("********* INCREASING ALLOWANCE *************");
    // await increaseAllowance(poliBitContract, sourceWallet, destinationWallet, stringAmount, decimals);
    
    // // Comment/uncomment this line to execute the transfer
    // console.log("********* TRANSFERING TOKENS *************");
    // await transferTokens(poliBitContract, sourceWallet, destinationWallet, stringAmount, decimals);


    
    // // Get token holders
    // console.log("********* GETING TOKENS HOLDERS *************");
    // try {
    //     const tokenHolders = await poliBitContract.getTokenHolders();
    //     console.log("Token holders:", tokenHolders);
    //     console.log("Number of token holders:", tokenHolders.length);
        
    //     // Optionally, you can iterate through the holders and display their balances
    //     console.log("\nToken holder balances:");
    //     for (let i = 0; i < tokenHolders.length; i++) {
    //         const holderAddress = tokenHolders[i];
    //         const balance = await poliBitContract.balanceOf(holderAddress);
    //         console.log(`Address: ${holderAddress}`);
    //         console.log(`Balance: ${hre.ethers.formatUnits(balance, decimals)}`);
    //         console.log("---");
    //     }
    // } catch (error) {
    //     console.log("Error getting token holders:", error.message);
    // }

    // // Mint tokens
    // console.log("********* MINTING TOKENS *************");
    // await  mint(poliBitContract, userWallet, stringAmount,decimals);
}

// Add a function to transfer tokens between wallets
async function transferTokens(poliBitContract, fromAddress, toAddress, amount, decimals) {
    try {
        console.log(`Transferring ${hre.ethers.formatUnits(amount, decimals)} tokens from ${fromAddress} to ${toAddress}`);
        
        // Check if the owner has enough allowance to transfer tokens from the source wallet
        const allowance = await poliBitContract.allowance(fromAddress, toAddress);
        console.log(`Current allowance: ${hre.ethers.formatUnits(allowance, decimals)}`);
        
        if (allowance <  parseFloat(amount)) {
            console.log("Insufficient allowance. The source wallet must approve your wallet to spend their tokens.");
            return;
        }
        
        // Execute the transferFrom transaction
        const transferTx = await poliBitContract.transferFrom(fromAddress, toAddress, amount);
        const receipt = await transferTx.wait();
        console.log("Transfer successful:", receipt.hash);
        
        // Check updated balances
        const fromBalance = await poliBitContract.balanceOf(fromAddress);
        const toBalance = await poliBitContract.balanceOf(toAddress);
        console.log(`New balance of sender (${fromAddress}): ${hre.ethers.formatUnits(fromBalance, decimals)}`);
        console.log(`New balance of recipient (${toAddress}): ${hre.ethers.formatUnits(toBalance, decimals)}`);
    } catch (error) {
        console.log("Error transferring tokens:", error.message);
    }
}

async function increaseAllowance(poliBitContract, addressFrom, addressTo, stringAmount, decimals) {
    const additionalAllowance = hre.ethers.parseUnits(stringAmount, decimals); // Amount to add to current allowance
    
    try {
        // Check current allowance first
        const currentAllowance = await poliBitContract.allowance(addressFrom, addressTo);
        console.log(`Current allowance: ${hre.ethers.formatUnits(currentAllowance, decimals)}`);
        
        console.log(`Increasing allowance for ${addressFrom} by ${hre.ethers.formatUnits(additionalAllowance, decimals)} tokens`);
        const increaseTx = await poliBitContract.increaceAllowance(addressFrom, addressTo, additionalAllowance);
        const receipt = await increaseTx.wait();
        console.log("Allowance increase successful:", receipt.hash);
        
        // Check the new allowance
        const newAllowance = await poliBitContract.allowance(addressFrom, addressTo);
        console.log(`New allowance: ${hre.ethers.formatUnits(newAllowance, decimals)}`);
    } catch (error) {
        console.log("Error increasing allowance:", error.message);
    }
}

// Add a function to transfer tokens between wallets
async function mint(poliBitContract, userWallet, stringAmount, decimals) {
    const mintAmount = hre.ethers.parseUnits(stringAmount, decimals);
    try {
        console.log(`minting -> ${hre.ethers.formatUnits(mintAmount, decimals)}`);
        const mintTx = await poliBitContract.mint(userWallet, mintAmount);
        const receipt = await mintTx.wait();
        console.log("Mint successful! Transaction hash:", receipt.hash);
        
        // Check updated balance
        const newBalance = await poliBitContract.balanceOf(userWallet);
        console.log("current balance:", hre.ethers.formatUnits(newBalance, decimals));
    } catch (error) {
        console.log("error minting:", error.message);
    }
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});
