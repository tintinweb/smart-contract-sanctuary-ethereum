// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    function decimals() external pure returns(uint); // 0

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address to, uint amount) external;

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external;

    function transferFrom(address sender, address recipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed owner, address indexed to, uint amount);
}

contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;
    uint private immutable _cap;

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

   constructor(string memory name_, string memory symbol_,
    uint initialSupply,
    uint _initialCap,
    address _shop) {
            _name = name_;
            _symbol = symbol_;
            owner = msg.sender;
            _cap = _initialCap;
            mint(initialSupply, _shop);
    }

    function decimals() public pure returns(uint) {
        return 18;
    }

    function totalSupply() public view returns(uint) {
        return totalTokens;
    }

    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function allowance(address _owner, address spender) public view returns(uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);
    }

    function _approve(address sender, address spender, uint amount) internal {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public enoughTokens(sender, amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        allowances[sender][recipient] -= amount; // overflow
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function cap() public view returns (uint) {
        return _cap;
    }

    function mint(uint amount, address shop) public onlyOwner {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function _burn(address _from, uint amount) public onlyOwner enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }
}

contract MCSToken is ERC20 {
    constructor(address shop) ERC20("MCSToken", "MCT", 10, 20, shop) {}
}

contract MShop {
    IERC20 public token;
    address payable owner;
    event Bought(uint _amount, address _buyer);
    event Sold(uint _amount, address _seller);

    constructor() {
        token = new MCSToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }

    function approveProxy(address spender, uint amount) public {
        token.approve(spender, amount);
    }

    function buy() external payable {
        uint tokensToBuy = msg.value;
        require(tokensToBuy > 0, "not enough funds!");
        uint currentBalance = tokenBalance();
        require(currentBalance >= tokensToBuy, "not enough tokens!");

        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    }

    function sell(uint _amountToSell) external {
        require(
            _amountToSell > 0 && token.balanceOf(msg.sender) >= _amountToSell,
            "incorrect amount"
        );
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "please check allowance!");

        token.transferFrom(msg.sender, address(this), _amountToSell);
        emit Sold(_amountToSell, msg.sender);
    }

    function withdrawAll() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "not enough funds!");
        owner.transfer(balance);
    }

    function tokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
}