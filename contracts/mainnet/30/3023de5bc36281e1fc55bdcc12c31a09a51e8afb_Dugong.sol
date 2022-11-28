/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Dugong
{
    address private _owner;
    address private _bridge;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    bool private _isRunning;

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor()
    {
        _owner = msg.sender;

        _name = "Dugong";
        _symbol = "DGNG";
        _decimals = 18;
        _totalSupply = 1000000 ether;

        _balanceOf[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        _allowance[address(this)][_owner] = _totalSupply;
        emit Approval(address(this), _owner, _totalSupply);

        _isRunning = true;
    }

    function name() external view returns (string memory)
    {
        return _name;
    }

    function symbol() external view returns (string memory)
    {
        return _symbol;
    }

    function decimals() external view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() external view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256)
    {
        return _balanceOf[owner];
    }

    function allowance(address owner, address spender) external view returns (uint256)
    {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) run external returns (bool)
    {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) run external returns (bool)
    {
        require(_balanceOf[msg.sender] > 0, "Zero Balance!");
        require(_balanceOf[msg.sender] >= amount, "Low Balance!");

        _balanceOf[msg.sender] -= amount;
        _balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) run external returns (bool)
    {
        require(_allowance[sender][msg.sender] > 0, "Zero Allowance!");
        require(_allowance[sender][msg.sender] >= amount, "Low Allowance!");
        require(_balanceOf[sender] > 0, "Zero Balance!");
        require(_balanceOf[sender] >= amount, "Low Balance!");

        _allowance[sender][msg.sender] -= amount;
        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function mint(address to, uint256 amount) run onlyAdmin external returns (bool)
    {
        _balanceOf[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);

        return true;
    }

    function burn(address from, uint256 amount) run onlyAdmin external returns (bool)
    {
        require(_balanceOf[from] > 0, "Zero Balance!");
        require(_balanceOf[from] >= amount, "Low Balance!");

        _balanceOf[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);

        return true;
    }

    function isRunning() external view returns (bool)
    {
        return _isRunning;
    }

    function start() onlyOwner external returns (bool)
    {
        require(!_isRunning, "Transaction is already Enabled!");

        _isRunning = !_isRunning;

        return true;
    }

    function stop() onlyOwner external returns (bool)
    {
        require(_isRunning, "Transaction is already Disabled!");

        _isRunning = !_isRunning;

        return true;
    }

    function setOwner(address newOwner) onlyOwner external returns (bool)
    {
        require(newOwner != address(0), "Invalid Address!");
        _owner = newOwner;
        return true;
    }

    function getOwner() external view returns (address)
    {
        return _owner;
    }

    function setBridge(address newBridge) onlyOwner external returns (bool)
    {
        require(newBridge != address(0), "Invalid Address!");
        _bridge = newBridge;
        return true;
    }

    function getBridge() external view returns (address)
    {
        return _bridge;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Access Denied, You're not the Owner!");
        _;
    }

    modifier onlyAdmin
    {
        require((msg.sender == _owner) || (msg.sender == _bridge), "Access Denied, You're not the Admin!");
        _;
    }

    modifier run
    {
        require(_isRunning, "Transaction is Temporarily Disabled!");
        _;
    }
}