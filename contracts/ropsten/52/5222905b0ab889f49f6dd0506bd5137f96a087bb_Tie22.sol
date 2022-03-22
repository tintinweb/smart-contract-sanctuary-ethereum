/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

//known errors: / emit log for burn and mint 
// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.8.13;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.13;
//made with love by InvaderTeam 
contract Tie22 {
    using SafeMath for uint256;    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);

    string private _name;
    string private _symbol;
    uint private  _supply;
    uint8 private _decimals;
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        _name = "TieToken 22";
        _symbol = "TIE22";
        _decimals = 6;        
        _supply = 50000 * (10 ** _decimals);
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }

modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return _supply.div( 10 ** _decimals);
    }    
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    function subSupply(uint amount) private {
        _supply = _supply.sub(amount);
    }   
    
    function addSupply(uint amount) private {
        _supply = _supply.add(amount);
    }

    function transfer(address from, address to, uint amount) public returns(bool) {
       require(!_blackList[to], "Recipient is backlisted");
       require(balanceOf(from) >= amount, "Insufficient funds.");
        _balances[from] = balanceOf(from).sub(amount);
        _balances[to] = balanceOf(to).add(amount);       
       emit Transfer(msg.sender, to, amount);
       return true;
    }

    function transferfrom(address from, address to, uint amount) public returns(bool) {
        require(!_blackList[to], "Recipient is backlisted");
        require(balanceOf(from) >= amount, "Insufficient funds.");
        _allowances[from][msg.sender] = allowance(from, msg.sender).sub(amount);
        _balances[from] = balanceOf(from).sub(amount);
        _balances[to] = balanceOf(to).add(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function _approve(address sender, address spender, uint amount) public returns (bool) {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }

    function whitelist(address _user) public owner {
        require(_blackList[_user], "user already whitelisted");
        _blackList[_user] = false;
    }

    function blackList(address _user) public owner {
        require(!_blackList[_user], "user already blacklisted");
        _blackList[_user] = true;
    }
    
    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
    }    
    function mint(address account, uint256 amount) public {
        require(!_blackList[account], "Recipient is backlisted");
        require(account != address(0), "ERC20: mint to the zero address");
        beforeTokenTransfer(address(0), account, amount);
        addSupply(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        afterTokenTransfer(address(0), account, amount);
    }

    function afterTokenTransfer(address from, address to, uint256 amount) internal virtual { 
    }
    function burn(address account, uint256 amount) public {
        require(!_blackList[account], "Recipient is backlisted");
        require(account != address(0), "ERC20: burn from the zero address");
        beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] = _balances[account].sub(amount); }
        subSupply(amount);
        emit Transfer(account, address(0), amount);
        afterTokenTransfer(account, address(0), amount);
    }
}