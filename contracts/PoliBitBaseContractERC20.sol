// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IERC20 Interface
 * @dev Standard ERC20 token interface as defined in the EIP-20 standard
 * This interface defines the required functions and events for ERC20 compliance
 */
interface IERC20 {
    // Returns the total token supply
    function totalSupply() external returns(uint256);
    
    // Returns the token balance of a specific account
    function balanceOf(address account) external view returns(uint256);
    
    // Transfers tokens from the caller to another address
    function transfer(address to, uint256 amount) external returns(bool);
    
    // Returns the remaining allowance that a spender has from an owner
    function allowance(address owner, address spender) external view returns(uint256);
    
    // Approves a spender to spend tokens on behalf of the owner
    function approve(address spender, uint256 amount) external returns(bool);
    
    // Transfers tokens from one address to another (requires approval)
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    
    // Event emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Event emitted when allowance is set
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20 PoliBit Smart Contract Token Implementation
 * @dev Implementation of the ERC20 standard
 * This contract provides a standard implementation of the ERC20 interface
 */
contract PoliBitBaseContractERC20 is IERC20 {
    // Mapping of account addresses to their token balances
    mapping(address => uint256) private _balances;
    
    // Double mapping for allowances: owner => spender => amount
    mapping(address => mapping (address => uint256)) private _allowances;
    
    // Total supply of tokens
    uint256 private _totalSupply;

    // Max amount tokens allowd
    uint256 private _maxTokens;

    // Current token value
    uint256 private _tokenValue;

    // Contract token name
    string private _name;

    // Contract token symbol
    string private _symbol;

    // Contract owner Company
    string private _company;

    // Contract token value currency
    string private _currency;

    // Contract owner address
    address public _owner;

    /**
     * @dev Constructor initializes the token with a name and symbol
     * @param _nameP The name of the token
     * @param _symbolP The symbol of the token
     */
    constructor(string memory _nameP, string memory _symbolP, string memory _companyP, string memory _currencyP, uint _tokenValueP, uint _maxTokensP) {
       _owner = msg.sender; // Set deployer as owner
       _name = _nameP;
       _symbol = _symbolP;
       _tokenValue = _tokenValueP;
       _maxTokens = _maxTokensP;
       _company = _companyP;
       _currency = _currencyP;
    }

    /**
     * @dev Returns the name of the token
     * @return The token name
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token value
     * @return The token value
     */
    function value() public view virtual returns (uint256) {
        return _tokenValue;
    }

    /**
     * @dev Returns the limit of tokens to mint
     * @return The max token value
     */
    function maxTokens() public view virtual returns (uint256) {
        return _maxTokens;
    }

    /**
     * @dev Returns the company token owner
     * @return The company name
     */
    function company() public view virtual returns (string memory) {
        return _company;
    }

    /**
     * @dev Returns the currency token value
     * @return The currency
     */
    function currency() public view virtual returns (string memory) {
        return _currency;
    }

    /**
     * @dev Returns the symbol of the token
     * @return The token symbol
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals for token display
     * @return The decimal places (18 is standard for most ERC20 tokens)
     */
    function decimals() public view virtual returns(uint8) {
        return 0;
    }

    /**
     * @dev Returns the total supply of tokens
     * @return The total token supply
     */
    function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
    }

    /**
     * @dev Returns the token balance of an account
     * @param account The address to query the balance of
     * @return The account's token balance
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfers tokens from caller to another address
     * @param to The recipient address
     * @param amount The amount of tokens to transfer
     * @return A boolean indicating whether the transfer was successful
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev Returns the amount of tokens approved for a spender by an owner
     * @param owner The address that owns the tokens
     * @param spender The address that can spend the tokens
     * @return The remaining allowance
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets amount as the allowance of spender over the caller's tokens
     * @param spender The address authorized to spend
     * @param amount The amount that can be spent
     * @return A boolean indicating whether the approval was successful
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) { 
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another using the allowance mechanism
     * @param from The address from which tokens are transferred
     * @param to The recipient address
     * @param amount The amount of tokens to transfer
     * @return A boolean indicating whether the transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(_owner == msg.sender, "ERC20: Only owner can call transferFrom function.");
        _spendAllowance(from, to, amount);
        _transfer(from, to, amount);
        return true;  
    }

    /**
     * @dev Increases the allowance granted to spender by the caller
     * @param spender The address authorized to spend
     * @param _addedValue The amount to increase the allowance by
     * @return A boolean indicating whether the operation was successful
     */
    function increaseAllowance(address owner, address spender, uint256 _addedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[owner][spender];
        _approve(owner, spender, currentAllowance + _addedValue);
        return true;
    }

    /**
     * @dev Decreases the allowance granted to spender by the caller
     * @param spender The address authorized to spend
     * @param _value The amount to decrease the allowance by
     * @return A boolean indicating whether the operation was successful
     */
    function decreaseAllowance(address owner, address spender, uint256 _value) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[owner][spender];

        require(currentAllowance >= _value, "ERC20: decreased allowance below zero.");
        unchecked {
            _approve(owner, spender, currentAllowance - _value);  
        }
        return true;
    }

    /**
     * @notice Checks if the caller is the owner of the contract
     * @dev Compares the message sender address with the stored owner address
     * @return bool Returns true if the caller is the owner, false otherwise
     */
    function isOwner() public virtual returns (bool) {
        return (msg.sender == _owner);
    }

    /**
     * @dev Internal function to perform token transfers
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param amount The amount of tokens to transfer
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        _beforeTokenTransfer(from, to, amount);
        
        uint256 fromBalance = _balances[from];
        
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Internal function to create tokens and assign them to an account
     * @param account The account that will receive the created tokens
     * @param amount The amount of tokens to create
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(_owner == msg.sender, "ERC20: Only owner can mint tokens.");
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= _maxTokens, "ERC20: Exceeds max supply");
        
        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
        
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to destroy tokens from an account
     * @param account The account from which tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(_owner == msg.sender, "ERC20: Only owner can burn tokens.");
        require(account != address(0), "ERC20: Burn from zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        uint accountBalance = _balances[account];  
        
        require(accountBalance >= amount, "ERC20: Burn exceeds Balance");
        
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount; 

        emit Transfer(account, address(0), amount); 
        
        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Internal function to set allowance
     * @param owner The owner of the tokens
     * @param spender The spender to be granted permission
     * @param amount The amount of tokens allowed to spend
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from zero address.");
        require(spender != address(0), "ERC20: approve to zero address.");
        
        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Internal function to check and update allowance when transferring on behalf of someone
     * @param owner The owner of the tokens
     * @param spender The spender of the tokens
     * @param amount The amount of tokens to spend
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: spending exceeds allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer
     * This empty implementation can be overridden in derived contracts
     * @param from The sender address
     * @param to The recipient address
     * @param amount The amount of tokens to transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }

    /**
     * @dev Hook that is called after any token transfer
     * This empty implementation can be overridden in derived contracts
     * @param from The sender address
     * @param to The recipient address
     * @param amount The amount of tokens transferred
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }
}