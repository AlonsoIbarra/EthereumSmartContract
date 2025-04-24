// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "contracts/PoliBitBaseContractERC20.sol";

/**
 * @title PoliBitContractERC20
 * @dev ERC20 token contract that extends PoliBitBaseContractERC20
 * @notice This contract provides PoliBitBaseContractERC20 functionality and exposes mint function.
 */
contract PoliBitContractERC20D26 is PoliBitBaseContractERC20 {

    /**
     * @dev Storage for addresses that hold tokens
     * Tracks addresses with non-zero balances
     */
    address[] private _tokenHolders;
    mapping(address => bool) private _isTokenHolder;

    /**
     * @notice Contract constructor
     * @dev Initializes the token by calling the parent constructor
     * @param _nameP The name of the token
     * @param _symbolP The symbol of the token
     * @param _tokenValueP The value of each token
     * @param _maxTokensP The maximum supply of tokens
     */
    constructor(string memory _nameP, string memory _symbolP, uint _tokenValueP, uint _maxTokensP) 
        PoliBitBaseContractERC20(_nameP, _symbolP, _tokenValueP, _maxTokensP) {}

    /**
     * @notice Mints new tokens and assigns them to the specified account
     * @dev Public function allowing anyone to mint tokens
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) public {
        // Calls the internal _mint function inherited from the parent contract
        _mint(account, amount);
    }

    /**
     * @dev Public function to burn tokens with improved holder tracking
     * @param account The address from which tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) public {
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        // Check if this burn will reduce balance to zero
        bool willHaveZeroBalance = (accountBalance == amount);
        
        // First burn the tokens
        _burn(account, amount);
        
        // If all tokens are burned, ensure the account is removed from holders
        if (willHaveZeroBalance) {
            _removeTokenHolder(account);
        }
    }
    
    /**
     * @dev Returns the list of addresses that currently hold tokens
     * @return An array of addresses that have a positive token balance
     */
    function getTokenHolders() public view returns (address[] memory) {
        return _tokenHolders;
    }
    
    /**
     * @dev Override the _afterTokenTransfer hook to track token holders
     * @param from The sender address
     * @param to The recipient address
     * @param amount The amount of tokens transferred
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        super._afterTokenTransfer(from, to, amount);
        
        // Handle minting (from == address(0))
        if (from == address(0)) {
            _addTokenHolder(to);
        }
        
        // Handle burning (to == address(0))
        else if (to == address(0)) {
            // If balance becomes zero, remove from holders
            if (balanceOf(from) == 0) {
                _removeTokenHolder(from);
            }
        }
        
        // Handle transfers between accounts
        else {
            // If receiver gets their first tokens, add them to holders
            if (balanceOf(to) == amount) {
                _addTokenHolder(to);
            }
            
            // If sender has no tokens left, remove them from holders
            if (balanceOf(from) == 0) {
                _removeTokenHolder(from);
            }
        }
    }
    
    /**
     * @dev Internal function to add an address to the token holders list
     * @param account The address to add to the token holders list
     */
    function _addTokenHolder(address account) internal {
        if (!_isTokenHolder[account]) {
            _tokenHolders.push(account);
            _isTokenHolder[account] = true;
        }
    }
    
    /**
     * @dev Internal function to remove an address from the token holders list
     * @param account The address to remove from the token holders list
     */
    function _removeTokenHolder(address account) internal {
        if (_isTokenHolder[account]) {
            // Find the index of the account in the _tokenHolders array
            for (uint256 i = 0; i < _tokenHolders.length; i++) {
                if (_tokenHolders[i] == account) {
                    // Swap with the last element and then pop
                    _tokenHolders[i] = _tokenHolders[_tokenHolders.length - 1];
                    _tokenHolders.pop();
                    _isTokenHolder[account] = false;
                    break;
                }
            }
        }
    }
}