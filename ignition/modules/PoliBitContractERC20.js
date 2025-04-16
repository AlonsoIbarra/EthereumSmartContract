// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("PoliBitTokenModule", (m) => {
  // Define the parameters for the PoliBitContractERC20 token
  const name = m.getParameter("name", "PoliBitToken");
  const symbol = m.getParameter("symbol", "POLSD3");
  const tokenValue = m.getParameter("tokenValue", 270000);
  const maxTokens = m.getParameter("maxTokens", 15000000000000000000); // 1 full token = 1,000,000,000,000,000,000 wei (10^18 decimals)

  // Deploy the PoliBitContractERC20 contract with the specified parameters
  const poliBitToken = m.contract("PoliBitContractERC20", [
    name,
    symbol,
    tokenValue,
    maxTokens
  ]);

  return { poliBitToken };
});