//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract ERC20 is Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply,
        address supplyOwner
    ) Ownable() {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(supplyOwner, initialSupply);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 currentAllowance = allowance(from, msg.sender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "Insufficient allowance");
            _approve(from, msg.sender, currentAllowance - value);
        }
        
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(address owner, uint256 value) public onlyOwner {
        _mint(owner, value);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(_balances[from] >= value, "Not enough tokens");
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address owner, uint256 value) internal {
        require(owner != address(0), "Mint to the zero address");
        totalSupply += value;
        _balances[owner] += value;
        emit Transfer(address(0), owner, value);
    }

    function _burn(address owner, uint256 value) internal {
        require(owner != address(0), "Burn from the zero address");
        uint256 ownerBalance = _balances[owner];
        require(ownerBalance >= value, "Burn amount exceeds balance");
        _balances[owner] = ownerBalance - value;
        totalSupply -= value;
        emit Transfer(owner, address(0), value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Ownable {
    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    } 
}