// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PBULLToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    address public BullManager;
    address public IcoAddress;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply)
         {
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            totalSupply = _totalSupply;
            balances[msg.sender] = _totalSupply;
            IcoAddress = msg.sender;
        }
        
    modifier onlyICO() {
        require(IcoAddress == msg.sender, "Caller should be ICO address!");
        _;
    }

    modifier onlyBullManager() {
        require(BullManager == msg.sender, "Transfer is not available for presale token!");
        _;
    }
    
    function setBullManager(address _bullManager) external onlyICO() {
        BullManager = _bullManager;
    }

    function transfer(address to, uint value) public onlyICO() returns(bool) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns(uint) {
        return allowed[owner][spender];
    }
    function transferFrom(address from, address to, uint value) public onlyBullManager() returns(bool) {
        uint _allowance = allowed[from][to];
        require(balances[from] >= value && _allowance >= value, "low balance");
        allowed[from][to] -= value;
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        require(spender != msg.sender);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
}

contract ICO {
    struct Sale {
        address investor;
        uint quantity;
    }
    Sale[] public sales;
    mapping(address => uint) public allocated;
    address public token;
    address public admin;
    address private OPERATING_COST = 0x9741De8EbCc09D4e0405Ed2d5581Cc9166c893C9;
    // IERC20 private USDC = IERC20(0x3e5570072f96a72703B0276109232eDe994e241E); //mumbai
    IERC20 private USDC = IERC20(0x7dAA6eb798cf8cDdD1B9D73236694371C0Cb58B7); //rinkeby
    uint public quantity = 10 * 1e18;

    uint public end;
    uint public price = 50 * 10 ** 18;
    uint public availableTokens;
    bool public released;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply)
         {
        token = address(new PBULLToken(
            _name,
            _symbol,
            _decimals,
            _totalSupply
        ));
        admin = msg.sender;
        released = false;
    }
    
    function start(
        uint duration,
        uint _availableTokens)
        external
        onlyAdmin() 
        icoNotActive() {
        require(duration > 0, "duration should be > 0");
        uint totalSupply = PBULLToken(token).totalSupply();
        require(_availableTokens > 0 && _availableTokens <= totalSupply, "totalSupply should be > 0 and <= totalSupply");
        end = duration * 1 days + block.timestamp; 
        availableTokens = _availableTokens;
    }

    function setBullManager(address _bullManager) external onlyAdmin() {
        PBULLToken(token).setBullManager(_bullManager);
    }
    
    function buy() external icoActive() {
        require(quantity <= availableTokens, "Not enough tokens left for sale");
        require(allocated[msg.sender] <= 2 * quantity, "Overflow the limit allocated to you");
        USDC.transferFrom(msg.sender, address(this), price * 10);
        sales.push(Sale(
            msg.sender,
            quantity
        ));
        allocated[msg.sender] += quantity;
        availableTokens -= quantity;
    }
    
    function release()
        external
        onlyAdmin()
        icoEnded()
        tokensNotReleased() {
        PBULLToken tokenInstance = PBULLToken(token);
        for(uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            tokenInstance.transfer(sale.investor, sale.quantity);
        }
        released = true;
    }
    
    function refund() external onlyAdmin() icoEnded() tokensNotReleased() {
        for(uint i = 0; i < sales.length; i ++) {
            Sale storage sale = sales[i];
            USDC.transfer(sale.investor, price * 10);
        }
    }
    function withdraw() external onlyAdmin() icoEnded() tokensReleased() {
        uint balance = USDC.balanceOf(address(this));
        USDC.transfer(OPERATING_COST, balance);
        // to.transfer(amount);    
    }
    
    function getBalance() external view onlyAdmin() returns(uint) {
        return USDC.balanceOf(address(this));
    }
    modifier icoActive() {
        require(end > 0 && block.timestamp < end && availableTokens > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(end == 0, "ICO should not be active");
        _;
    }
    
    modifier icoEnded() {
        require(end > 0 && (block.timestamp >= end || availableTokens == 0), "ICO must have ended");
        _;
    }
    
    modifier tokensNotReleased() {
        require(released == false, "Tokens must NOT have been released");
        _;
    }
    
    modifier tokensReleased() {
        require(released == true, "Tokens must have been released");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}