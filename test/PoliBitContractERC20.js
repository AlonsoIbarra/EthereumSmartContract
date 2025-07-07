const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("PoliBitERC20", function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const initialSupply = 1000;
    const maxSupply = 5000;
    
    const PoliBit = await ethers.getContractFactory("PoliBitContractERC20");
    const token = await PoliBit.deploy("TestToken", "TT", "Company Name", "MXN", 1, maxSupply);
    
    return { token, owner, addr1, addr2, initialSupply, maxSupply };
  }

  describe("Deployment", function () {
    it("Should set correct token metadata", async function () {
      const { token } = await loadFixture(deployTokenFixture);
      expect(await token.name()).to.equal("TestToken");
      expect(await token.symbol()).to.equal("TT");
      expect(await token.value()).to.equal(1);
    });

    it("Should set correct max supply", async function () {
      const { token, maxSupply } = await loadFixture(deployTokenFixture);
      expect(await token.maxTokens()).to.equal(maxSupply);
    });

    it("Should set deployer as owner", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      expect(await token._owner()).to.equal(owner.address);
    });
  });

  // Other existing test sections...

  describe("Token Holders Tracking", function () {
    async function deployTokenWithHoldersFixture() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      const maxSupply = 5000;
      
      const PoliBit = await ethers.getContractFactory("PoliBitContractERC20");
      const token = await PoliBit.deploy("TestToken", "TT", "Company Name", "MXN", 1, maxSupply);
      
      // Mint some tokens to have initial data to test with
      await token.mint(owner.address, 1000);
      
      return { token, owner, addr1, addr2, maxSupply };
    }

    it("Should initially have only owner in token holders list", async function () {
      const { token, owner } = await deployTokenWithHoldersFixture();
      
      const holders = await token.getTokenHolders();
      expect(holders.length).to.equal(1);
      expect(holders[0]).to.equal(owner.address);
    });

    it("Should add address to holders after transfer", async function () {
      const { token, owner, addr1 } = await deployTokenWithHoldersFixture();
      
      // Transfer tokens to another address
      await token.transfer(addr1.address, 300);
      
      const holders = await token.getTokenHolders();
      expect(holders.length).to.equal(2);
      expect(holders).to.include(owner.address);
      expect(holders).to.include(addr1.address);
    });

    it("Should remove address from holders when balance becomes zero", async function () {
      const { token, owner, addr1 } = await deployTokenWithHoldersFixture();
      
      // Transfer all tokens to another address
      await token.transfer(addr1.address, 1000);
      
      const holders = await token.getTokenHolders();
      expect(holders.length).to.equal(1);
      expect(holders[0]).to.equal(addr1.address);
      expect(holders).to.not.include(owner.address);
    });

    it("Should handle multiple transfers correctly", async function () {
      const { token, owner, addr1, addr2 } = await deployTokenWithHoldersFixture();
      
      // Create multiple holders
      await token.transfer(addr1.address, 300);
      await token.transfer(addr2.address, 300);
      
      let holders = await token.getTokenHolders();
      expect(holders.length).to.equal(3);
      
      // Now let's have addr1 transfer all their tokens to addr2
      await token.connect(addr1).transfer(addr2.address, 300);
      
      holders = await token.getTokenHolders();
      expect(holders.length).to.equal(2);
      expect(holders).to.include(owner.address);
      expect(holders).to.include(addr2.address);
      expect(holders).to.not.include(addr1.address);
    });

    it("Should add holder on mint", async function () {
      const [owner, addr1] = await ethers.getSigners();
      const maxSupply = 5000;
      
      const PoliBit = await ethers.getContractFactory("PoliBitContractERC20");
      const token = await PoliBit.deploy("TestToken", "TT", "Company Name", "MXN", 1, maxSupply);
      
      // Initial state - no holders
      let holders = await token.getTokenHolders();
      expect(holders.length).to.equal(0);
      
      // Mint tokens to address
      await token.mint(addr1.address, 500);
      
      holders = await token.getTokenHolders();
      expect(holders.length).to.equal(1);
      expect(holders[0]).to.equal(addr1.address);
    });

    it("Should remove holder on burn", async function () {
      const { token, owner } = await deployTokenWithHoldersFixture();
      
      // Initially owner has 1000 tokens
      let holders = await token.getTokenHolders();
      expect(holders.length).to.equal(1);
      
      // Burn all tokens
      await token.burn(owner.address, 1000);
      
      holders = await token.getTokenHolders();
      expect(holders.length).to.equal(0);
    });

    it("Should not add duplicate entries for the same holder", async function () {
      const { token, owner, addr1 } = await deployTokenWithHoldersFixture();
      
      // First transfer to addr1
      await token.transfer(addr1.address, 200);
      
      // Second transfer to addr1
      await token.transfer(addr1.address, 200);
      
      const holders = await token.getTokenHolders();
      expect(holders.length).to.equal(2);
      
      // Count occurrences of addr1
      const addr1Entries = holders.filter(addr => addr === addr1.address);
      expect(addr1Entries.length).to.equal(1);
    });

    it("Should handle circular transfers correctly", async function () {
      const { token, owner, addr1 } = await deployTokenWithHoldersFixture();
      
      // Transfer to addr1
      await token.transfer(addr1.address, 500);
      
      // addr1 sends back to owner
      await token.connect(addr1).transfer(owner.address, 500);
      
      const holders = await token.getTokenHolders();
      expect(holders.length).to.equal(1);
      expect(holders[0]).to.equal(owner.address);
    });

    it("Should not count addresses with zero balance", async function () {
      const { token, owner, addr1, addr2 } = await deployTokenWithHoldersFixture();
      
      // Create some activity
      await token.transfer(addr1.address, 300);
      await token.transfer(addr2.address, 200);
      await token.connect(addr1).transfer(addr2.address, 300);
      
      const holders = await token.getTokenHolders();
      
      // Should only have owner and addr2 (addr1 has 0 balance)
      expect(holders.length).to.equal(2);
      expect(holders).to.include(owner.address);
      expect(holders).to.include(addr2.address);
      expect(holders).to.not.include(addr1.address);
    });
  });
});