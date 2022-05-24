/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: contracts/SwapPQL.sol
// SPDX-License-Identifier: MIT
//library
library SafeMath {
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");
       return c;
   }
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return sub(a, b, "SafeMath: subtraction overflow");
   }
   function sub(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
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
   function div(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b > 0, errorMessage);
       uint256 c = a / b;
       return c;
   }
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return mod(a, b, "SafeMath: modulo by zero");
   }
   function mod(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b != 0, errorMessage);
       return a % b;
   }
}

pragma solidity 0.8.9;

interface IBEP20 {
        function totalSupply() external view returns (uint256);
        function decimals() external view returns (uint8);
        function symbol() external view returns (string memory);
        function name() external view returns (string memory);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address _owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
    }
contract Swapper {
    using SafeMath for uint256;
    
    IBEP20 public PiqsolToken;
    address owner;
    
    //address person ;

    constructor(address _piqsol) {
       owner = msg.sender;
       PiqsolToken = IBEP20(_piqsol);   
    }

    function getTokenBalance() public view returns (uint256){
        uint256 value = PiqsolToken.balanceOf(0x95696F1A2c35a48e3F8Aafbfc4b8c8Fb00f3Ff15);
        return value;

    } 


}