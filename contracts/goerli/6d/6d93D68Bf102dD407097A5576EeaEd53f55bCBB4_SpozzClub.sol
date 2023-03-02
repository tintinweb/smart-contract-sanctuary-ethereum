/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Contract to implement the ERC20 standard
contract SpozzClub {
    // Variables to store the name, symbol, and decimals of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    // Variables to store the total supply, minted supply, and maximum mint amount of the token
    uint256 public totalSupply;
    uint256 public mintedSupply;
    uint256 public maxMint;

    // Variables to store the flags for token burning behavior
    bool public destroyFlag = false;
    bool public assignFlag = false;
    uint256 public burnLimit;

    // Variable to store the liquidity pool amount
    uint256 public liquidityPool;

    // Mapping to store the balance of each address
    mapping (address => uint256) public balances;

    // Mapping to store the approved transfer amount from one address to another
    mapping (address => mapping (address => uint256)) public allowed;

    // Address to store the owner of the contract
    address public owner;

    // Nonce to prevent replay attacks
    uint256 public nonce;

    // Variable to prevent reentrancy attacks
    bool private locked;

    // Event to emit transfer of tokens
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to emit approval of token transfer
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Constructor to initialize the contract and set the owner, total supply, minted supply, maxMint, liquidity pool, and flags
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _maxMint,
        uint256 _liquidityPool,
        bool _destroyFlag,
        bool _assignFlag,
        uint256 _burnLimit
    ) {
        // Set the name of the token
        name = _name;
        // Set the symbol of the token
        symbol = _symbol;
        // Set the decimals of the token
        decimals = _decimals;
        // Set the total supply to the value specified in the constructor
        totalSupply = _totalSupply;
        // Set the minted supply to the value specified in the constructor
        mintedSupply = _totalSupply;
        // Set the maximum mint amount to the value specified in the constructor
        maxMint = _maxMint;
        // Set the liquidity pool to the value specified in the constructor
        liquidityPool = _liquidityPool;
        // Set the destroy flag to the value specified in the constructor
        destroyFlag = _destroyFlag;
        // Set the assign flag to the value specified in the constructor
        assignFlag = _assignFlag;
        // Set the balance of the owner to the total supply
        balances[msg.sender] = totalSupply;

        // Only set the burn limit if either of the burn flags are set to true
        if (destroyFlag || assignFlag) {
            burnLimit = _burnLimit;
        } else {
            burnLimit = 0;
        }

        // Set the owner to the address that deployed the contract
        owner = msg.sender;
    }

    // Function to mint new tokens, accessible only by the owner
    function mint(uint256 _value) public onlyOwner {
        // Ensure that maxMint is greater than zero
        require(maxMint > 0, "Maximum mint amount not set");
        // Ensure that the minted amount does not exceed the maximum mint amount
        require(safeAdd(mintedSupply, _value) <= maxMint, "Exceeds maximum mint amount");
        // Increment the total supply and minted supply
        totalSupply = safeAdd(totalSupply, _value);
        mintedSupply = safeAdd(mintedSupply, _value);
        // Increment the balance of the owner
        balances[owner] = safeAdd(balances[owner], _value);
        // Emit the transfer event
        emit Transfer(address(0), owner, _value);
    }

    // Function to transfer tokens from one address to another
    function transfer(address _to, uint256 _value) public nonReentrant returns (bool) {
        // Ensure the sender has enough balance
        require(balances[msg.sender] >= _value && _value > 0, "Not enough balance");
        // Increment the nonce to prevent replay attacks
        nonce++;
        // Decrement the sender's balance
        balances[msg.sender] -= _value;
        // Increment the recipient's balance
        balances[_to] += _value;
        // Emit the transfer event
        emit Transfer(msg.sender, _to, _value);
        // Return true to indicate success
        return true;
    }

    // Internal function to transfer tokens from one account to another
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid transfer amount");

        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Function to transfer tokens from one account to another, with approval
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowed[sender][msg.sender], "Insufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to approve a transfer of tokens from one address to another
    function approve(address _spender, uint256 _value) public nonReentrant returns (bool) {
        // Set the approved transfer amount from one address to another
        allowed[msg.sender][_spender] = _value;
        // Emit the approval event
        emit Approval(msg.sender, _spender, _value);
        // Return true to indicate success
        return true;
    }

    // Internal function to approve a transfer of tokens from one account to another
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "Invalid owner address");
        require(_spender != address(0), "Invalid spender address");
        require(_amount >= 0, "Invalid allowance amount");

        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // Function to burn tokens and decrease the total supply, minted supply, and maxMint
    function burn(uint256 _value) public nonReentrant {
        // Ensure the sender has enough balance
        require(balances[msg.sender] >= _value && _value > 0, "Not enough balance");
        // Only allow burning if either of the burn flags are set to true
        require(destroyFlag || assignFlag, "Burning tokens is not allowed");
        // Check if the burn amount is within the burn limit
        require(_value <= burnLimit, "Burn amount exceeds the burn limit");
        // Increment the nonce to prevent replay attacks
        nonce++;
        // Decrement the sender's balance
        balances[msg.sender] -= _value;
        // Decrement the total supply
        totalSupply -= _value;
        // Decrement the minted supply
        mintedSupply -= _value;
        // Decrement the maxMint
        maxMint -= _value;

        // Check if the destroy flag is set to true
        if (destroyFlag) {
            // If the destroy flag is set to true, destroy the burned tokens
        } else {
            // Check if the assign flag is set to true
            if (assignFlag) {
                // If the assign flag is set to true, assign the burned tokens back to the owner
                balances[owner] += _value;
            }
        }
    }

    // Function to set the burn limit
    function setBurnLimit(uint256 limit) public {
        require(msg.sender == owner, "Only owner can set burn limit");
        burnLimit = limit;
    }

    // Function to toggle the destroy flag, accessible only by the owner
    function toggleDestroyFlag() public onlyOwner {
        // Invert the value of the destroy flag
        destroyFlag = !destroyFlag;
    }

    // Function to toggle the assign flag, accessible only by the owner
    function toggleAssignFlag() public onlyOwner {
        // Invert the value of the assign flag
        assignFlag = !assignFlag;
    }

    // Function to view the current value of the destroy flag
    function viewDestroyFlag() public view returns (bool) {
        // Return the current value of the destroy flag
        return destroyFlag;
    }

    // Function to view the current value of the assign flag
    function viewAssignFlag() public view returns (bool) {
        // Return the current value of the assign flag
        return assignFlag;
    }

    // Function to view the total supply in ether units
    function viewTotalSupply() public view onlyOwner returns (uint256) {
        // Return the current value of the total supply in ether units
        return fromWei(totalSupply);
    }

    // Function to view the liquidity pool in ether units
    function viewLiquidityPool() public view returns (uint256) {
        // Return the current value of the liquidity pool in ether units
        return fromWei(liquidityPool);
    }

    // Function to view the maxMint in ether units
    function viewMaxMint() public view returns (uint256) {
        // Return the current value of the maxMint in ether units
        return fromWei(maxMint);
    }

    // Function to view the maxMintedSupply in ether units
    function viewMintedSupply() public view returns (uint256) {
        // Return the current value of the mintedSupply in ether units
        return fromWei(mintedSupply);
    }

    // Function to withdraw ether from the contract
    function withdraw(uint256 _amount) public onlyOwner {
        // Ensure the contract has enough balance
        require(_amount <= address(this).balance, "Insufficient balance");
        // Increment the nonce to prevent replay attacks
        nonce++;
        // Transfer the ether to the owner's address
        payable(owner).transfer(_amount);
    }

    // Safe subtraction function to prevent underflow
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Ensure that the subtraction does not result in an underflow
        require(a >= b, "Subtraction underflow");
        // Return the result of the subtraction
        return a - b;
    }

    // Safe addition function to prevent overflow
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        // Ensure that the addition does not result in an overflow
        require(a + b >= a, "Addition overflow");
        // Return the result of the addition
        return a + b;
    }

    // Function to convert an amount in wei to ether
    function fromWei(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount / 1 ether;
    }

    // Function to convert an amount in ether to wei
    function toWei(uint256 etherAmount) internal view returns (uint256) {
        return etherAmount * 1 ether;
    }

    // Function to get the balance of a specific address
    function balanceOf(address account) public view returns (uint256) {
        return fromWei(balances[account]);
    }

    // Function to get the amount of tokens approved for transfer from one address to another
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return fromWei(allowed[_owner][_spender]);
    }

    // Modifier to restrict access to only the owner
    modifier onlyOwner() {
        // Ensure the caller is the owner
        require(msg.sender == owner, "Access restricted to owner only");
        // Apply the changes
        _;
    }

    // Modifier to prevent reentrancy
    modifier nonReentrant() {
        // Ensure that the function is not called recursively
        require(!locked, "Reentrancy protection");
        // Lock the function
        locked = true;
        // Apply the changes
        _;
        // Unlock the function
        locked = false;
    }
}