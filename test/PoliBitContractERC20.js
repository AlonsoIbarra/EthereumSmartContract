const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("PoliBitERC20", function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const initialSupply = 1000;
    const maxSupply = 5000;
    
    const PoliBit = await ethers.getContractFactory("PoliBitContractERC20");
    const token = await PoliBit.deploy("TestToken", "TT", 1, maxSupply);
    
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

  describe("Token Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);
      await token.mint(owner.address, 1000);
      
      await token.transfer(addr1.address, 500);
      expect(await token.balanceOf(owner.address)).to.equal(500);
      expect(await token.balanceOf(addr1.address)).to.equal(500);
    });

    it("Should fail transfer with insufficient balance", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);
      await expect(token.transfer(addr1.address, 1000))
        .to.be.revertedWith("ERC20: transfer amount exceds balance");
    });
  });

  describe("Minting", function () {
    it("Should mint tokens correctly", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      await token.mint(owner.address, 1000);
      
      expect(await token.totalSupply()).to.equal(1000);
      expect(await token.balanceOf(owner.address)).to.equal(1000);
    });

    it("Should enforce max supply limit", async function () {
      const { token, owner, maxSupply } = await loadFixture(deployTokenFixture);
      await token.mint(owner.address, maxSupply);
      
      await expect(token.mint(owner.address, 1))
        .to.be.revertedWith("ERC20: Exceeds max supply");
    });
  });

  describe("Allowances", function () {
    it("Should approve and transferFrom correctly", async function () {
      const { token, owner, addr1, addr2 } = await loadFixture(deployTokenFixture);
      await token.mint(owner.address, 1000);
      
      await token.approve(addr1.address, 300);
      await token.connect(addr1).transferFrom(owner.address, addr2.address, 300);
      
      expect(await token.balanceOf(addr2.address)).to.equal(300);
      expect(await token.allowences(owner.address, addr1.address)).to.equal(0);
    });

    it("Should handle allowance changes", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);
      await token.approve(addr1.address, 1000);
      await token.increaceAllowence(addr1.address, 500);
      expect(await token.allowences(owner.address, addr1.address)).to.equal(1500);
      
      await token.decreaseAllowence(addr1.address, 700);
      expect(await token.allowences(owner.address, addr1.address)).to.equal(800);
    });
  });

  describe("Events", function () {
    it("Should emit Transfer event on mint", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      await expect(token.mint(owner.address, 1000))
        .to.emit(token, "Transfer")
        .withArgs(ethers.ZeroAddress, owner.address, 1000);
    });

    it("Should emit Approval event", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);
      await expect(token.approve(addr1.address, 500))
        .to.emit(token, "Approval")
        .withArgs(owner.address, addr1.address, 500);
    });
  });
});
