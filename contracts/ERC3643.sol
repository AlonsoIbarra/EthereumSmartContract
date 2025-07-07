// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// =============================================================================
// INTERFACES TO IMPLMENT
// =============================================================================

/**
 * @title IERC20 Interface
 * @dev Standard ERC20 interface for basic token functionality
 */
interface IERC20 {
    function totalSupply() external returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title IERC3643 Interface
 * @dev Interface for ERC-3643 compliant tokens with identity and compliance features
 */
interface IERC3643 {
    function identityRegistry() external view returns (IIdentityRegistry);
    function complianceRegistry() external view returns (IComplianceRegistry);
    function forcedTransfer(address from, address to, uint256 amount) external returns (bool);
    function batchTransfer(address[] calldata to, uint256[] calldata amounts) external;
    function setIdentityRegistry(address registry) external;
    function setComplianceRegistry(address registry) external;
    
    event IdentityRegistrySet(address indexed registry);
    event ComplianceRegistrySet(address indexed registry);
}

/**
 * @title IIdentityRegistry Interface
 * @dev Interface for managing user identities and verification status
 */
interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function getCountry(address user) external view returns (uint16);
    function getInvestorType(address user) external view returns (uint8);
    function registerIdentity(address user, uint16 country, uint8 investorType) external;
    function deleteIdentity(address user) external;
}

/**
 * @title IComplianceRegistry Interface
 * @dev Interface for managing compliance rules and transfer validation
 */
interface IComplianceRegistry {
    function canTransfer(address from, address to, uint256 amount) external view returns (bool);
    function transferred(address from, address to, uint256 amount) external;
    function updateBalance(address user, uint256 newBalance) external;
}

// =============================================================================
// ACCESS CONTROL FOR OWNER
// =============================================================================

/**
 * @title Ownable
 * @dev Contract module which provides basic access control mechanism
 * Only the owner can execute certain functions
 */
contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Returns the address of the current owner
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        return true;
    }
}

// =============================================================================
// IDENTITY REGISTRY IMPLEMENTATION
// =============================================================================

/**
 * @title IdentityRegistry
 * @dev Manages user identities with country codes and investor types
 * Supports registration agents who can verify identities
 */
contract IdentityRegistry is IIdentityRegistry, Ownable {
    /**
     * @dev Structure to store identity information
     * @param isVerified Boolean indicating if the identity is verified
     * @param country ISO 3166-1 numeric country code
     * @param investorType Type of investor (0: retail, 1: professional, 2: institutional)
     */
    struct Identity {
        bool isVerified;
        uint16 country;
        uint8 investorType;
    }
    
    mapping(address => Identity) private _identities;
    mapping(address => bool) public isRegistrationAgent;
    
    event IdentityRegistered(address indexed user, uint16 country, uint8 investorType);
    event IdentityDeleted(address indexed user);
    event RegistrationAgentAdded(address indexed agent);
    event RegistrationAgentRemoved(address indexed agent);
    
    /**
     * @dev Modifier to restrict access to registration agents and owner only
     */
    modifier onlyRegistrationAgent() {
        require(isRegistrationAgent[msg.sender] || msg.sender == owner(), 
                "IdentityRegistry: caller is not a registration agent");
        _;
    }
    
    /**
     * @dev Adds a new registration agent
     * @param agent Address of the agent to add
     */
    function addRegistrationAgent(address agent) external onlyOwner returns (bool) {
        isRegistrationAgent[agent] = true;
        emit RegistrationAgentAdded(agent);
        return true;
    }

    /**
     * @dev Removes a registration agent
     * @param agent Address of the agent to remove
     */
    function removeRegistrationAgent(address agent) external onlyOwner returns (bool) {
        isRegistrationAgent[agent] = false;
        emit RegistrationAgentRemoved(agent);
        return true;
    }
    
    /**
     * @dev Checks if a user is verified
     * @param user Address to check
     * @return Boolean indicating verification status
     */
    function isVerified(address user) external view override returns (bool) {
        return _identities[user].isVerified;
    }
    
    /**
     * @dev Gets the country code for a verified user
     * @param user Address to query
     * @return Country code (ISO 3166-1 numeric)
     */
    function getCountry(address user) external view override returns (uint16) {
        require(_identities[user].isVerified, "IdentityRegistry: user is not verified");
        return _identities[user].country;
    }
    
    /**
     * @dev Gets the investor type for a verified user
     * @param user Address to query
     * @return Investor type (0: retail, 1: professional, 2: institutional)
     */
    function getInvestorType(address user) external view override returns (uint8) {
        require(_identities[user].isVerified, "IdentityRegistry: user is not verified");
        return _identities[user].investorType;
    }
    
    /**
     * @dev Registers a new identity
     * @param user Address of the user to register
     * @param country ISO 3166-1 numeric country code
     * @param investorType Type of investor (0: retail, 1: professional, 2: institutional)
     */
    function registerIdentity(address user, uint16 country, uint8 investorType) 
        external 
        override 
        onlyRegistrationAgent
    {
        require(user != address(0), "IdentityRegistry: invalid user address");
        require(country > 0, "IdentityRegistry: invalid country code");
        
        _identities[user] = Identity({
            isVerified: true,
            country: country,
            investorType: investorType
        });
        
        emit IdentityRegistered(user, country, investorType);
    }
    
    /**
     * @dev Deletes an existing identity
     * @param user Address of the user to delete
     */
    function deleteIdentity(address user) external override onlyRegistrationAgent {
        require(_identities[user].isVerified, "IdentityRegistry: user is not verified");
        
        delete _identities[user];
        emit IdentityDeleted(user);
    }
}

// =============================================================================
// COMPLIANCE REGISTRY IMPLEMENTATION
// =============================================================================

/**
 * @title ComplianceRegistry
 * @dev Manages compliance rules and validates transfers
 * Includes country restrictions, investor type restrictions, and token limits
 */
contract ComplianceRegistry is IComplianceRegistry, Ownable {
    /**
     * @dev Structure to store compliance rules
     * @param isActive Whether compliance checking is active
     * @param maxTokens Maximum tokens a user can hold
     * @param maxTransferAmount Maximum amount per transfer
     * @param allowedCountries Mapping of allowed country codes
     * @param allowedInvestorTypes Mapping of allowed investor types
     */
    struct ComplianceRule {
        bool isActive;
        uint256 maxTokens;
        uint256 maxTransferAmount;
        mapping(uint16 => bool) allowedCountries;
        mapping(uint8 => bool) allowedInvestorTypes;
    }
    
    ComplianceRule private _globalRule;
    mapping(address => uint256) private _balances;
    mapping(address => bool) public isComplianceAgent;

    IIdentityRegistry public identityRegistry;
    
    // Country and investor type restrictions
    uint16[] public allowedCountriesList;
    uint8[] public allowedInvestorTypesList;
    
    event ComplianceRuleUpdated();
    event ComplianceAgentAdded(address indexed agent);
    event ComplianceAgentRemoved(address indexed agent);
    event TransferValidated(address indexed from, address indexed to, uint256 amount);
    
    /**
     * @dev Modifier to restrict access to compliance agents and owner only
     */
    modifier onlyComplianceAgent() {
        require(isComplianceAgent[msg.sender] || msg.sender == owner(), 
                "ComplianceRegistry: caller is not a compliance agent");
        _;
    }
    
    /**
     * @dev Sets the identity registry address
     * @param _identityRegistry Address of the identity registry contract
     */
    function setIdentityRegistry(address _identityRegistry) external onlyOwner returns (bool) {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        return true;
    }
    
    /**
     * @dev Constructor initializes default compliance rules
     * Sets up allowed countries and investor types
     */
    constructor() {
        _globalRule.isActive = true;
        _globalRule.maxTokens = 150;
        _globalRule.maxTransferAmount = 10;
        

        // Add some default allowed countries
        _globalRule.allowedCountries[320] = true; // Guatemala
        _globalRule.allowedCountries[222] = true; // El Salvador
        _globalRule.allowedCountries[340] = true; // Honduras
        _globalRule.allowedCountries[484] = true; // México
        _globalRule.allowedCountries[724] = true; // España
        _globalRule.allowedCountries[840] = true; // EU
        allowedCountriesList.push(320);
        allowedCountriesList.push(222);
        allowedCountriesList.push(340);
        allowedCountriesList.push(484);
        allowedCountriesList.push(724);
        allowedCountriesList.push(840);
        
        // Add default investor types (0: retail, 1: professional, 2: institutional)
        _globalRule.allowedInvestorTypes[0] = true;
        _globalRule.allowedInvestorTypes[1] = true;
        _globalRule.allowedInvestorTypes[2] = true;
        allowedInvestorTypesList.push(0);
        allowedInvestorTypesList.push(1);
        allowedInvestorTypesList.push(2);
    }
    
    /**
     * @dev Adds a new compliance agent
     * @param agent Address of the agent to add
     */
    function addComplianceAgent(address agent) external onlyOwner returns (bool) {
        isComplianceAgent[agent] = true;
        emit ComplianceAgentAdded(agent);
        return true;
    }
    
    /**
     * @dev Removes a compliance agent
     * @param agent Address of the agent to remove
     */
    function removeComplianceAgent(address agent) external onlyOwner returns (bool) {
        isComplianceAgent[agent] = false;
        emit ComplianceAgentRemoved(agent);
        return true;
    }
    
    /**
     * @dev Sets the maximum tokens a user can hold
     * @param maxTokens New maximum token limit
     */
    function setMaxTokens(uint256 maxTokens) external onlyComplianceAgent returns (bool) {
        _globalRule.maxTokens = maxTokens;
        emit ComplianceRuleUpdated();
        return true;
    }
    
    /**
     * @dev Sets the maximum amount per transfer
     * @param maxAmount New maximum transfer amount
     */
    function setMaxTransferAmount(uint256 maxAmount) external onlyComplianceAgent returns (bool) {
        _globalRule.maxTransferAmount = maxAmount;
        emit ComplianceRuleUpdated();
        return true;
    }
    
    /**
     * @dev Adds a country to the allowed list
     * @param country ISO 3166-1 numeric country code
     */
    function addAllowedCountry(uint16 country) external onlyComplianceAgent returns (bool) {
        if (!_globalRule.allowedCountries[country]) {
            _globalRule.allowedCountries[country] = true;
            allowedCountriesList.push(country);
            emit ComplianceRuleUpdated();
        }
        return true;
    }
    
    /**
     * @dev Removes a country from the allowed list
     * @param country ISO 3166-1 numeric country code
     */
    function removeAllowedCountry(uint16 country) external onlyComplianceAgent returns (bool) {
        if (_globalRule.allowedCountries[country]) {
            _globalRule.allowedCountries[country] = false;
            // Remove from list
            for (uint i = 0; i < allowedCountriesList.length; i++) {
                if (allowedCountriesList[i] == country) {
                    allowedCountriesList[i] = allowedCountriesList[allowedCountriesList.length - 1];
                    allowedCountriesList.pop();
                    break;
                }
            }
            emit ComplianceRuleUpdated();
        }
        return true;
    }
    
    /**
     * @dev Adds an investor type to the allowed list
     * @param investorType Type to add (0: retail, 1: professional, 2: institutional)
     */
    function addAllowedInvestorType(uint8 investorType) external onlyComplianceAgent returns (bool) {
        require(investorType <= 2, "ComplianceRegistry: invalid investor type");
        
        if (!_globalRule.allowedInvestorTypes[investorType]) {
            _globalRule.allowedInvestorTypes[investorType] = true;
            allowedInvestorTypesList.push(investorType);
            emit ComplianceRuleUpdated();
        }
        return true;
    }
    
    /**
     * @dev Removes an investor type from the allowed list
     * @param investorType Type to remove
     */
    function removeAllowedInvestorType(uint8 investorType) external onlyComplianceAgent returns (bool) {
        if (_globalRule.allowedInvestorTypes[investorType]) {
            _globalRule.allowedInvestorTypes[investorType] = false;
            
            // Remove from array - swap with last element and pop
            for (uint i = 0; i < allowedInvestorTypesList.length; i++) {
                if (allowedInvestorTypesList[i] == investorType) {
                    allowedInvestorTypesList[i] = allowedInvestorTypesList[allowedInvestorTypesList.length - 1];
                    allowedInvestorTypesList.pop();
                    break;
                }
            }
            emit ComplianceRuleUpdated();
        }
        return true;
    }
    
    /**
     * @dev Checks if a transfer is compliant with all rules
     * @param from Address sending tokens (address(0) for minting)
     * @param to Address receiving tokens (address(0) for burning)
     * @param amount Amount of tokens to transfer
     * @return Boolean indicating if transfer is allowed
     */
    function canTransfer(address from, address to, uint256 amount) 
        external 
        view 
        override 
        returns (bool) 
    {
        if (!_globalRule.isActive) return true;
        
        if (amount > _globalRule.maxTransferAmount) return false;
        
        // Mint
        if (from == address(0)) {
            return _checkRecipientCompliance(to, amount);
        }
        
        // Burn
        if (to == address(0)) return true;
        
        // Single Transfer
        return _checkRecipientCompliance(to, amount);
    }
    
    /**
     * @dev Internal function to check recipient compliance
     * @param to Address receiving tokens
     * @param amount Amount of tokens to receive
     * @return Boolean indicating if recipient is compliant
     */
    function _checkRecipientCompliance(address to, uint256 amount) private view returns (bool) {
        if (address(identityRegistry) != address(0)) {
            // Is verified
            if (!identityRegistry.isVerified(to)) return false;
            
            // Is valid country code
            uint16 country = identityRegistry.getCountry(to);
            if (!_globalRule.allowedCountries[country]) return false;
            
            // Investor type
            uint8 investorType = identityRegistry.getInvestorType(to);
            if (!_globalRule.allowedInvestorTypes[investorType]) return false;
        }

        // Max token validation
        if (_balances[to] + amount > _globalRule.maxTokens) return false;
        
        return true;
    }
    
    /**
     * @dev Called after a transfer to update internal state
     * @param from Address that sent tokens
     * @param to Address that received tokens
     * @param amount Amount transferred
     */
    function transferred(address from, address to, uint256 amount) external override {
        // Update balances
        if (from != address(0)) {
            _balances[from] -= amount;
        }
        if (to != address(0)) {
            _balances[to] += amount;
        }
        
        emit TransferValidated(from, to, amount);
    }

    // =============================================================================
    // VIEW FUNCTIONS FOR COMPLIANCE RULES
    // =============================================================================

    function getMaxTokens() external view returns (uint256) {
        return _globalRule.maxTokens;
    }
    
    function getMaxTransferAmount() external view returns (uint256) {
        return _globalRule.maxTransferAmount;
    }

    function isInvestorTypeAllowed(uint8 investorType) external view returns (bool) {
        return _globalRule.allowedInvestorTypes[investorType];
    }

    function isCountryAllowed(uint16 country) external view returns (bool) {
        return _globalRule.allowedCountries[country];
    }
    
    function updateBalance(address user, uint256 newBalance) external override {
        _balances[user] = newBalance;
    }
    
    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }
    
    function getAllowedCountries() external view returns (uint16[] memory) {
        return allowedCountriesList;
    }
    
    function getAllowedInvestorTypes() external view returns (uint8[] memory) {
        return allowedInvestorTypesList;
    }

    function setComplianceActive(bool active) external onlyComplianceAgent returns (bool) {
        _globalRule.isActive = active;
        emit ComplianceRuleUpdated();
        return true;
    }

    function isComplianceActive() external view returns (bool) {
        return _globalRule.isActive;
    }
}

// ************************************************
// ERC-3643 TOKEN IMPLEMENTATION
// ************************************************

/**
 * @title ERC3643Token
 * @dev Implementation of ERC-3643 compliant token with built-in compliance and identity checking
 * Combines ERC-20 functionality with regulatory compliance features
 */
contract ERC3643Token is IERC20, IERC3643, Ownable {
    
    address[] private _holders;
    mapping(address => bool) private _isHolder;
    string public name;
    string public symbol;
    string public company;
    string public currency;
    uint public tokenValue;
    uint public maxTokens;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    IIdentityRegistry private _identityRegistry;
    IComplianceRegistry private _complianceRegistry;
    
    mapping(address => bool) public isAgent;
    
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount);
    event BatchTransferCompleted(uint256 totalAmount);
    
    /**
     * @dev Modifier to restrict access to agents and owner only
     */
    modifier onlyAgent() {
        require(isAgent[msg.sender] || msg.sender == owner(), 
                "ERC3643Token: caller is not an agent");
        _;
    }
    
    /**
     * @dev Modifier to ensure user is verified in identity registry
     */
    modifier onlyVerified(address user) {
        require(_identityRegistry.isVerified(user), 
                "ERC3643Token: user is not verified");
        _;
    }
    
    /**
     * @dev Constructor initializes the token with metadata and registry addresses
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _companyP Company name
     * @param _currencyP Currency denomination
     * @param _tokenValueP Value per token
     * @param _maxTokensP Maximum tokens allowed
     * @param _identityRegistryAddress Address of identity registry
     * @param _complianceRegistryAddress Address of compliance registry
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _companyP,
        string memory _currencyP,
        uint _tokenValueP,
        uint _maxTokensP,
        address _identityRegistryAddress,
        address _complianceRegistryAddress
    ) {
        name = _name;
        symbol = _symbol;
        company = _companyP;
        currency = _currencyP;
        tokenValue = _tokenValueP;
        maxTokens = _maxTokensP;
        _identityRegistry = IIdentityRegistry(_identityRegistryAddress);
        _complianceRegistry = IComplianceRegistry(_complianceRegistryAddress);
        
        // Owner is automatically an agent
        isAgent[msg.sender] = true;
    }
    
    // ************************************************
    // AGENT MANAGEMENT
    // ************************************************
    
    /**
     * @dev Adds a new agent who can perform administrative actions
     * @param agent Address to add as agent
     */
    function addAgent(address agent) external onlyOwner returns (bool) {
        isAgent[agent] = true;
        emit AgentAdded(agent);
        return true;
    }
    
    /**
     * @dev Removes an agent
     * @param agent Address to remove from agents
     */
    function removeAgent(address agent) external onlyOwner returns (bool) {
        isAgent[agent] = false;
        emit AgentRemoved(agent);
        return true;
    }
    
    // ************************************************
    // ERC20 OLDER FUNCTIONS
    // ************************************************

    /**
     * @dev Returns the token value
     * @return The token value
     */
    function value() public view virtual returns (uint256) {
        return tokenValue;
    }
    /**
     * @notice Checks if the caller is the owner of the contract
     * @dev Compares the message sender address with the stored owner address
     * @return bool Returns true if the caller is the owner, false otherwise
     */
    function isOwner() public virtual returns (bool) {
        return (msg.sender == owner());
    }
    
    /**
     * @dev Returns the number of decimals used for token amounts
     */
    function decimals() public view virtual returns(uint8) {
        return 0;
    }

    /**
     * @dev Returns the total supply of tokens
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the balance of the specified address
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Transfers tokens from caller to specified address
     * Both sender and recipient must be verified
     */
    function transfer(address to, uint256 amount) 
        external 
        override 
        onlyVerified(msg.sender)
        onlyVerified(to)
        returns (bool) 
    {
        return _transfer(msg.sender, to, amount);
    }

    /**
     * @dev Increases the allowance granted to spender by the caller
     * @param spender The address authorized to spend
     * @param _addedValue The amount to increase the allowance by
     * @return A boolean indicating whether the operation was successful
     */
    function increaseAllowance(address owner, address spender, uint256 _addedValue) public virtual onlyAgent returns (bool) {
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
    function decreaseAllowance(address owner, address spender, uint256 _value) public virtual onlyAgent returns (bool) {
        uint256 currentAllowance = _allowances[owner][spender];

        require(currentAllowance >= _value, "ERC20: decreased allowance below zero.");
        unchecked {
            _approve(owner, spender, currentAllowance - _value);  
        }
        return true;
    }
    
    /**
     * @dev Returns the allowance amount for spender from owner
     */
    function allowance(address owner, address spender) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev Approves spender to spend amount of tokens on behalf of caller
     */
    function approve(address spender, uint256 amount) 
        external 
        override 
        returns (bool) 
    {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens from one address to another using allowance
     * All parties must be verified
     */
    function transferFrom(address from, address to, uint256 amount) 
        external 
        override 
        onlyVerified(from)
        onlyVerified(to)
        returns (bool) 
    {
        uint256 currentAllowance = _allowances[from][to];
        require(currentAllowance >= amount, "ERC3643Token: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, to, currentAllowance - amount);
        
        return true;
    }
    
    /**
     * @dev Returns array of all token holders
     */
    function getTokenHolders() public view returns (address[] memory) {
        return _holders;
    }
    
    /**
     * @dev Internal transfer function with compliance checking
     * @param from Address sending tokens
     * @param to Address receiving tokens
     * @param amount Amount to transfer
     */
    function _transfer(address from, address to, uint256 amount) 
        internal 
        returns (bool) 
    {
        require(from != address(0), "ERC3643Token: transfer from the zero address");
        require(to != address(0), "ERC3643Token: transfer to the zero address");
        require(_balances[from] >= amount, "ERC3643Token: transfer amount exceeds balance");
        
        // Check compliance
        require(_complianceRegistry.canTransfer(from, to, amount), 
                "ERC3643Token: transfer not compliant");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        
        // Notify compliance registry
        _complianceRegistry.transferred(from, to, amount);
        
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC3643Token: approve from the zero address");
        require(spender != address(0), "ERC3643Token: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            // Minting
            _addHolder(to);
        } else if (to == address(0)) {
            // Burning
            if (_balances[from] == 0) {
                _removeHolder(from);
            }
        } else {
            // Normal transfer
            if (_balances[to] == amount) {
                _addHolder(to);
            }
            if (_balances[from] == 0) {
                // No more tokens in account
                _removeHolder(from);
            }
        }
    }
    
    function _addHolder(address account) internal {
        if (!_isHolder[account]) {
            _holders.push(account);
            _isHolder[account] = true;
        }
    }
    
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
    
    // ************************************************
    // ERC3643 FUNCTIONS
    // ************************************************
    
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return _identityRegistry;
    }
    
    function complianceRegistry() external view override returns (IComplianceRegistry) {
        return _complianceRegistry;
    }
    
    function forcedTransfer(address from, address to, uint256 amount) 
        external 
        override 
        onlyAgent 
        returns (bool) 
    {
        require(_balances[from] >= amount, "ERC3643Token: transfer amount exceeds balance");
        require(to != address(0), "ERC3643Token: transfer to the zero address");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        
        // Update compliance registry
        _complianceRegistry.transferred(from, to, amount);
        
        emit ForcedTransfer(from, to, amount);
        emit Transfer(from, to, amount);
        
        _afterTokenTransfer(from, to, amount);
        return true;
    }
    
    function batchTransfer(address[] calldata to, uint256[] calldata amounts) 
        external 
        override 
        onlyVerified(msg.sender)
    {

        require(to.length == amounts.length, "Array length mismatch");
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < to.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(_balances[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], amounts[i]);
        }
        emit BatchTransferCompleted(totalAmount);
    }
    
    function setIdentityRegistry(address registry) external override onlyOwner {
        require(registry != address(0), "ERC3643Token: invalid registry address");
        _identityRegistry = IIdentityRegistry(registry);
        emit IdentityRegistrySet(registry);
    }
    
    function setComplianceRegistry(address registry) external override onlyOwner {
        require(registry != address(0), "ERC3643Token: invalid registry address");
        _complianceRegistry = IComplianceRegistry(registry);
        emit ComplianceRegistrySet(registry);
    }

    // ************************************************
    // MINTING AND BURNING
    // ************************************************
    
    function mint(address to, uint256 amount) 
        external 
        onlyAgent 
        onlyVerified(to)
        returns (bool) 
    {
        require(_complianceRegistry.canTransfer(address(0), to, amount), 
                "ERC3643Token: transfer not compliant");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        _complianceRegistry.transferred(address(0), to, amount);
        
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        
        return true;
    }
    
    function burn(address from, uint256 amount) 
        external 
        onlyAgent 
        returns (bool) 
    {
        require(_balances[from] >= amount, "ERC3643Token: burn amount exceeds balance");
        
        _balances[from] -= amount;
        _totalSupply -= amount;
        
        _complianceRegistry.transferred(from, address(0), amount);
        
        if (_balances[from] == 0) {
            _removeHolder(from);
        }
        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
        
        return true;
    }

    function isUserVerified(address user) external view returns (bool) {
        return _identityRegistry.isVerified(user);
    }

    function canPerformAgentActions(address caller) external view returns (bool) {
        return isAgent[caller] || caller == owner();
    }

    function getRegistryAddresses() external view returns (address identity, address compliance) {
        return (address(_identityRegistry), address(_complianceRegistry));
    }
}

// ************************************************
// DEPLOYMENT CONTRACT
// ************************************************

contract ERC3643Factory is Ownable {
    
    event TokenDeployed(
        address indexed token,
        address indexed identityRegistry,
        address indexed complianceRegistry,
        string name,
        string symbol
    );
    
    function deployToken(
        string memory name,
        string memory symbol,
        string memory company,
        string memory currency,
        uint tokenValue,
        uint maxTokens
    ) external returns (address token, address identityRegistry, address complianceRegistry) {
        
        // Get identity management instance
        identityRegistry = address(new IdentityRegistry());
        
        // Get compliance management isntance 
        complianceRegistry = address(new ComplianceRegistry());
        
        ComplianceRegistry(complianceRegistry).setIdentityRegistry(identityRegistry);
        
        // Deploy token contract and related contracts
        token = address(new ERC3643Token(
            name,
            symbol,
            company,
            currency,
            tokenValue,
            maxTokens,
            identityRegistry,
            complianceRegistry
        ));
        
        // Transfer ownership to the caller
        Ownable(identityRegistry).transferOwnership(msg.sender);
        Ownable(complianceRegistry).transferOwnership(msg.sender);
        Ownable(token).transferOwnership(msg.sender);
        
        emit TokenDeployed(token, identityRegistry, complianceRegistry, name, symbol);
        
        return (token, identityRegistry, complianceRegistry);
    }
}