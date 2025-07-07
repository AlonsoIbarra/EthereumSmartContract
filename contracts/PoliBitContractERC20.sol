// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./PoliBitBaseContractERC20.sol";

/**
 * @title PoliBitContractERC20
 * @dev ERC20 token contract that extends PoliBitBaseContractERC20
 * @notice This contract provides PoliBitBaseContractERC20 functionality and exposes mint function.
 */
contract PoliBitContractERC20 is PoliBitBaseContractERC20 {

    address[] private _holders;
    mapping(address => bool) private _isHolder;

    /**
     * @notice Contract constructor
     * @dev Initializes the token by calling the parent constructor
     * @param _nameP The name of the token
     * @param _symbolP The symbol of the token
     * @param _companyP The symbol of the token
     * @param _currencyP The symbol of the token
     * @param _tokenValueP The value of each token
     * @param _maxTokensP The maximum supply of tokens
     */
    constructor(
        string memory _nameP, 
        string memory _symbolP, 
        string memory _companyP, 
        string memory _currencyP, 
        uint _tokenValueP, 
        uint _maxTokensP
    ) PoliBitBaseContractERC20(_nameP, _symbolP, _companyP, _currencyP, _tokenValueP, _maxTokensP) {}

    /**
     * @notice Mints new tokens and assigns them to the specified account
     * @dev Public function allowing anyone to mint tokens
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) public virtual {
        // Calls the internal _mint function inherited from the parent contract
        _mint(account, amount);
    }

    /**
     * @dev Public function to burn tokens with improved holder tracking
     * @param account The address from which tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) public virtual {
        require(balanceOf(account) >= amount, "Insufficient balance");
        _burn(account, amount);
        
        if (balanceOf(account) == 0) {
            _removeHolder(account);
        }
    }
    
    /**
     * @dev Returns the list of addresses that currently hold tokens
     * @return An array of addresses that have a positive token balance
     */
    function getTokenHolders() public view returns (address[] memory) {
        return _holders;
    }
    
    /**
     * @dev Override the _afterTokenTransfer hook to track token holders
     * @param from The sender address
     * @param to The recipient address
     * @param amount The amount of tokens transferred
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override virtual{
        super._afterTokenTransfer(from, to, amount);
        
        if (from == address(0)) {
            _addHolder(to);
        } else if (to == address(0)) {
            if (balanceOf(from) == 0) {
                _removeHolder(from);
            }
        } else {
            if (balanceOf(to) == amount) {
                _addHolder(to);
            }
            if (balanceOf(from) == 0) {
                _removeHolder(from);
            }
        }
    }
    
    /**
     * @dev Internal function to add an address to the token holders list
     * @param account The address to add to the token holders list
     */
    function _addHolder(address account) internal {
        if (!_isHolder[account]) {
            _holders.push(account);
            _isHolder[account] = true;
        }
    }
    
    /**
     * @dev Internal function to remove an address from the token holders list
     * @param account The address to remove from the token holders list
     */
    function _removeHolder(address account) internal {
        if (_isHolder[account]) {
            uint256 len = _holders.length;
            for (uint256 i = 0; i < len; i++) {
                if (_holders[i] == account) {
                    _holders[i] = _holders[len - 1];
                    _holders.pop();
                    _isHolder[account] = false;
                    break;
                }
            }
        }
    }
}