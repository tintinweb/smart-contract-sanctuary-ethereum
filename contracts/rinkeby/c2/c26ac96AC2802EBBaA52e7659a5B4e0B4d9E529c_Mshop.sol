// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256 totalTokens;
    address owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    string _name;
    string _symbol;

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint256 _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens!");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address shop
    ) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, shop);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount)
        external
        enoughTokens(msg.sender, amount)
    {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function mint(uint256 amount, address shop) public onlyOwner {
        _beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function burn(address _from, uint256 amount) public onlyOwner {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    function allowance(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public {
        _appove(msg.sender, spender, amount);
    }

    function _appove(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public enoughTokens(sender, amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        //require(allowances[sender][recipient]>=amount, "check allowance");
        allowances[sender][recipient] -= amount;

        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract AMRTok is ERC20 {
    constructor(address shop) ERC20("AMRTok", "AMR", 200, shop) {}
}

contract Mshop {
    IERC20 public token;
    address payable public owner;
    event Bought(uint256 _amount, address indexed _bayer);
    event Sold(uint256 _amount, address _seller);

    constructor() {
        token = new AMRTok(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    function sell(uint256 _amountToSell) external {
        require(
            _amountToSell > 0 && token.balanceOf(msg.sender) >= _amountToSell,
            "incorrect amount"
        );
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "check allowance");
        token.transferFrom(msg.sender, address(this), _amountToSell);
        payable(msg.sender).transfer(_amountToSell);
        emit Sold(_amountToSell, msg.sender);
    }

    receive() external payable {
        uint256 tokensToBuy = msg.value;
        require(tokensToBuy > 0, "not enough founds");

        require(tokenBalance() >= tokensToBuy, "not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    }
    function tokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
}