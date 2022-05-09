// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IAirdrop.sol";

contract GSI is IERC20, IERC20Metadata, IAirdrop
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowed;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor()
    {
        _name = "Giant Shiba Inu";
        _symbol = "GSI";
        _decimals = 18;
        _totalSupply = 1000000000000 * 10 ** _decimals;
        _balance[msg.sender] = _totalSupply;
        emit Transfer(msg.sender, address(0), _totalSupply);
    }

    function name() public view virtual override returns (string memory)
    {
        return _name;
    }

    function symbol() public view virtual override returns (string memory)
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256)
    {
        return _balance[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
    {
        require(_balance[msg.sender] >= amount, "balance too low");
        _balance[msg.sender] = _balance[msg.sender].sub(amount);
        _balance[recipient] = _balance[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool)
    {
        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        require(_balance[sender] >= amount, "balance too low");
        require(_allowed[sender][msg.sender] >= amount, "allowance too low");
        _balance[sender] = _balance[sender].sub(amount);
        _allowed[sender][msg.sender] = _allowed[sender][msg.sender].sub(amount);
        _balance[recipient] = _balance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function airdrop(address[] memory recipient, uint256 amount) public virtual override returns (bool)
    {
        require(_balance[msg.sender] >= amount, "balance too low");
        _balance[msg.sender] = _balance[msg.sender].sub(amount);
        for(uint256 i=0; i<recipient.length; i++)
        {
            _balance[recipient[i]] = _balance[recipient[i]].add(amount.div(recipient.length));
            emit Airdrop(msg.sender, recipient[i], amount.div(recipient.length));
        }
        return true;
    }
}