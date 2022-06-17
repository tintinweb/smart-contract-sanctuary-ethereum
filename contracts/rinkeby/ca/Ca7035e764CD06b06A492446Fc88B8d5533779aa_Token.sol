pragma solidity ^0.8.0;

contract Token {

    string public name = "Ayzat token";
    string public symbol = "ATON";

    uint256 public totalSupply = 200;

    address tokenOwner;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) approveList;

    event Approval(address indexed owner, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed spender, uint256 value);

    modifier onlyOwner {
        require(msg.sender == tokenOwner, "You don't have privilege");
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply;
        tokenOwner = msg.sender;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough token");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256){
        return approveList[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        approveList[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(approveList[sender][msg.sender] >= amount, "You don't have privilege or amount big");
        require(balances[sender] >= amount, "Sender don't have tokens");
        approveList[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, msg.sender, amount);
        return true;
    }

    function mint(uint256 emissionValue) external onlyOwner returns (bool) {
        totalSupply += emissionValue;
        balances[msg.sender] += emissionValue;
        return true;
    }

    function burn(uint256 burnValue) external onlyOwner returns (bool) {
        require(balances[msg.sender] >= burnValue, "Don't have tokens to burn");
        totalSupply -= burnValue;
        balances[msg.sender] -= burnValue;
        return true;
    }
}