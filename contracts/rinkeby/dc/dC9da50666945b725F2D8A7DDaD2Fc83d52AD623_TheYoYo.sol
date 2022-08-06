/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


/**
* Standard SafeMath, stripped down to just add/sub/mul/div
*/
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
       // Solidity only automatically asserts when dividing by 0
       require(b > 0, errorMessage);
       uint256 c = a / b;
       // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
       return c;
   }
}


abstract contract Auth {
   address internal owner;
   mapping (address => bool) internal authorizations;
 
   constructor(address _owner) {
       owner = _owner;
       authorizations[_owner] = true;
   }
}
interface IERC20 {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    // function transfer(address to, uint value) external returns (bool);
    // function transferFrom(address from, address to, uint value) external returns (bool);
}


contract TheYoYo is IERC20{
    using SafeMath for uint256;

    string constant _name = "YoYo";
    string constant _symbol = "YO";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
}