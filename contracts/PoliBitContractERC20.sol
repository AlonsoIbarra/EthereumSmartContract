// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "contracts/PoliBitBaseContractERC20.sol";

/**
 * @title PoliBitContractERC20
 * @dev ERC20 token contract that extends PoliBitBaseContractERC20
 * @notice This contract provides PoliBitBaseContractERC20 functionality and exposes mint function.
 */
contract PoliBitContractERC20 is PoliBitBaseContractERC20 {
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
}