/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {

    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] -= value;
        _balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;    
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply -= amount;
        _balances[account] -= amount;

        emit Transfer(account, address(0), amount);

    }

    function _burnFrom(address account, uint256 amount) internal {
        _allowed[account][msg.sender] -= amount;
        _burn(account, amount);
    }

}


contract MyToken is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 amount) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        _mint(msg.sender, amount);
    }

   function burn(uint256 amount) public {
       require(msg.sender == owner);
       _burn(msg.sender, amount);
   }



}