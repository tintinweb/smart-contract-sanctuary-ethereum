/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.8.14;

interface ERC20 {
    //fns
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    //events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Owned {
    address public owner;
    mapping( address => bool ) admins;

    constructor () {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function isAdmin(address account) onlyOwner public view returns (bool) {
        return admins[account];
    }

    function addAdmin(address account) onlyOwner public {
        require(account != address(0) && !admins[account]);
        admins[account] = true;
    }

    function removeAdmin(address account) onlyOwner public {
        require(account != address(0) && !admins[account]);
        delete admins[account];
    }
}

contract Pausable is Owned {
    event PausedEvent(address account);
    event UnpausedEvent(address account);
    bool private paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        paused = true;
        emit PausedEvent(msg.sender);
    }

    function unpause() public onlyAdmin whenPaused {
        paused = false;
        emit UnpausedEvent(msg.sender);
    }
}

contract MalcolmERC20 is ERC20, Pausable{
    TokenSummary public tokenSummary;
    mapping( address => uint256 ) internal balances;
    mapping( address => mapping (address => uint256) ) internal allowedToSpend;
    uint256 internal _initialSupply = 100000;
    uint256 internal _totalSupply = 1000000;
    event Burn(address from, uint256 value);
    event Receive(address from, uint256 value);

    struct TokenSummary {
        address initialAccount;
        string name;
        string symbol;
    }

    constructor() payable {
        balances[msg.sender] = _initialSupply;
        //_totalSupply = initialBalance;
        tokenSummary = TokenSummary(msg.sender, "MalcolmERC20", "M20");

    }

    function name() public view returns (string memory) {
        return tokenSummary.name;
    }

    function symbol() public view returns (string memory) {
        return tokenSummary.symbol;
    }

    function decimals() public view returns (uint8) {
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        //ensure valid address & sender has enough tokens in balances for transfer(deposit)
        //to address
        require(to != address(0) && balances[msg.sender] > value);
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
        //log txn in blockchain
        emit Transfer(msg.sender, to , value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        //---For withdrawals, allowing contracts to transfer tokens on our behalf---
        //ensure to address is valid, and value is <= balances of from address &&
        //value <= tokens that from address has allowed msg.sender(invoker) to spend.
        require(to != address(0) && value <= balances[from] &&
            value <= allowedToSpend[from][msg.sender]);
        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        //update no of tokens that from address has allowed invoker to spend
        allowedToSpend[from][msg.sender] = allowedToSpend[from][msg.sender] - value;
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        //Check spender address is valid, then allow spender to withdraw value from account
        require(spender != address(0));
        allowedToSpend[msg.sender][spender] = value;
        //log txn in blockchain
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowedToSpend[owner][spender];
    }

    function burn(uint256 value) public whenNotPaused onlyAdmin returns (bool success) {
        //reduce target address' token values and total supply value
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender] - value;
        _totalSupply = totalSupply() - value;
        emit Burn(msg.sender, value);
        return true;
    }

    function mint(address account, uint256 value) public onlyAdmin returns (bool) {
        //increase target address' token values and total supply value
        require(account != address(0));
        _totalSupply = totalSupply() + value;
        balances[account] = balances[account] + value;
        emit Transfer(address(0), account, value);
        return true;
    }

    receive () external payable {
        emit Receive(msg.sender, msg.value);
    }

    fallback () external payable {
        revert();
    }

}