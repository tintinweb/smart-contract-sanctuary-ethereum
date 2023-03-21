// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed user, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");

        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address account, uint256 amount) external {
        balances[account] = balances[account] + amount;
    }

    // comment this function out because Ethersjs cannot tell two functions with same name
    // function mint(uint256 amount) external {
    //     balances[msg.sender] = balances[msg.sender] + amount;
    // }

    // Make forge coverage ignore
    function testSuccess() public {}

    function burn(address user, uint256 amount) external {
        require(amount <= balances[user], "BALANCE_NOT_ENOUGH");
        balances[user] = balances[user] - amount;
        balances[address(0)] = balances[address(0)] + amount;
        emit Burn(user, amount);
    }
}