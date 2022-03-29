/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//known errors: / emit log for burn and mint 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function _approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);

}
// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity ^0.8.13;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {        uint256 c = a + b;        if (c < a) return (false, 0);        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {        if (b > a) return (false, 0);        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {        if (a == 0) return (true, 0);        uint256 c = a * b;        if (c / a != b) return (false, 0);        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {        if (b == 0) return (false, 0);        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {        if (b == 0) return (false, 0);        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {        uint256 c = a + b;        require(c >= a, "SafeMath: addition overflow");        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {        require(b <= a, "SafeMath: subtraction overflow");        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {        if (a == 0) return 0;        uint256 c = a * b;        require(c / a == b, "SafeMath: multiplication overflow");        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {        require(b > 0, "SafeMath: division by zero");        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {        require(b > 0, "SafeMath: modulo by zero");        return a % b;
    }
}

pragma solidity ^0.8.13;
//made with love by InvaderTeam 
contract Tie20 is ERC20 {
    using SafeMath for uint256;    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;

    string constant private _name = "TieToken 22";
    string constant private _symbol = "TIE22";
    uint256 private  _supply = 50000 * (10 ** 6);
    uint8 constant private _decimals = 6;
    address private _owner;
    bool private _reentrant = false;
    
    constructor() {
        _owner = 0x875a40A7CB1DB3F563066E748acDf58fB6334c23;
        /*_name = "TieToken 21";
        _symbol = "TIE21";
        _decimals = 6;        
        _supply = 50000 * (10 ** _decimals);
        _balances[_owner] = _supply;
        _reentrant = false;*/
        _balances[_owner] = _supply;
        emit Transfer(address(this), _owner, _supply);
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }

    modifier noreentrancy {
        require(!_reentrant, "Reentrancy hijack detected");
        _reentrant = true;
        _;
        _reentrant = false;
    }
    
    function name() external pure returns(string memory) {
        return _name;   
    }
    
    function symbol() external pure returns(string memory) {
        return _symbol;
    }
    
    function decimals() external pure returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns(uint256) {
        return _supply.div( 10 ** _decimals);
    }    
    
    function balanceOf(address wallet) public view virtual override  returns(uint256) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    function subSupply(uint256 amount) private {
        _supply = _supply.sub(amount);
    }   
    
    function addSupply(uint256 amount) private {
        _supply = _supply.add(amount);
    }

    function beforeTokenTransfer(address to, uint256 amount) internal virtual {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(!_blackList[to], "Recipient is backlisted");
        require(to != address(0), "ERC20: burn from the zero address");
        
        require(amount > 0, "Empty transaction consume gas as well you moron");
    }
    
    function afterTokenTransfer(address to, uint256 amount) internal virtual { 
    } 

    function transfer(address to, uint256 amount) external override noreentrancy returns(bool) {
       beforeTokenTransfer(to, amount);
       require(balanceOf(msg.sender) >= amount, "Insufficient funds."); //require this as a safety prevention for anyone to send tokens

       _balances[msg.sender] = balanceOf(msg.sender).sub(amount);
       _balances[to] = balanceOf(to).add(amount);      

       emit Transfer(msg.sender, to, amount);
       return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override owner noreentrancy returns(bool) {
        beforeTokenTransfer(to, amount);
        require(balanceOf(from) >= amount, "Insufficient funds.");

        //        _sellers[from] = true;  // He sold?
        _allowances[from][msg.sender] = allowance(from, msg.sender).add(amount);
        _balances[from] = balanceOf(from).sub(amount); 
        _balances[to] = balanceOf(to).add(amount); 

        emit Transfer(from, to, amount);
        return true;
    }

    function _approve(address spender, uint256 amount) external override returns (bool) {
        beforeTokenTransfer(spender, amount);

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view virtual override returns (uint256) {
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

    function mint(address account, uint256 amount) external owner{
        beforeTokenTransfer(account, amount);

        addSupply(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
        afterTokenTransfer(account, amount);
    }

    
    function burn(address account, uint256 amount) external owner{
        beforeTokenTransfer(account, amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked { _balances[account] = _balances[account].sub(amount); }
        subSupply(amount);

        emit Transfer(account, address(0), amount);
        afterTokenTransfer(account, amount);
    }
}