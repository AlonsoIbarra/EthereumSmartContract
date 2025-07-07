// scripts/deploy.js
async function main() {
    try {
      const [deployer] = await ethers.getSigners();
      console.log("Deploying contracts with the account:", deployer.address);
      console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());
  
      // Get contract factory
      const PoliBitContract = await ethers.getContractFactory("PoliBitContractERC20");
      
      // Define constructor parameters
      const name = "PoliBit Token";
      const symbol = "PBIT";
      const company = "Polibit";
      const currency = "USD";
      const tokenValue = ethers.parseUnits("270000", 0); // Adjust as needed
      const maxTokens = ethers.parseUnits("150", 0); // Adjust
      
      console.log("Deploying PoliBit contract...");
      console.log(`Parameters: Name=${name}, Symbol=${symbol}, Company=${company}, Currency=${currency}, Value=${tokenValue}, MaxTokens=${maxTokens}`);
      
      // Deploy with higher gas limit and price if needed
      const contract = await PoliBitContract.deploy(
        name, 
        symbol,
        company,
        currency,
        tokenValue, 
        maxTokens,
        {
          gasLimit: 5000000, // Adjust 
        }
      );
  
      await contract.waitForDeployment();
      const contractAddress = await contract.getAddress();
      
      console.log("Contract deployed to:", contractAddress);
      console.log("Deployment transaction hash:", contract.deploymentTransaction().hash);
      
      // Verify basic contract functions
      console.log("\nVerifying contract...");
      const contractName = await contract.name();
      const contractSymbol = await contract.symbol();
      const contractDecimals = await contract.decimals();
      const contractTotalSupply = await contract.totalSupply();
      
      console.log("Contract name:", contractName);
      console.log("Contract symbol:", contractSymbol);
      console.log("Contract decimals:", contractDecimals);
      console.log("Contract total supply:", contractTotalSupply.toString());
      
      console.log("\nDeployment completed successfully!");
      
      // Return the contract address for use in scripts
      return contractAddress;
    } catch (error) {
      console.error("Deployment failed with error:", error);
      process.exit(1);
    }
  }
  
  // Execute the deployment
  main()
    .then((address) => {
      console.log("Returned contract address:", address);
      process.exit(0);
    })
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });