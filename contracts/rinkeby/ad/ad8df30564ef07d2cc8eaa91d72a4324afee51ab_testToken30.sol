/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
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

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract testToken30 {
    using SafeMath for uint256;
        uint256 private _sTotal =  (1100*1000)* 10**18;    
        string private _name = "testToken";
        string private _symbol = "test30";
        uint8 private _decimals = 18;
        mapping (address => uint256) private _Owned;
        constructor()
        {
         _Owned[msg.sender]=_sTotal;    
        }
        event Transfer(address indexed from, address indexed to, uint256 value);
        function ProGetBalanceOf(address md) public view returns (uint256)
        {
            return _Owned[md];
        }
         function transfer(address recipient, uint256 amount) public  returns (bool) 
         {       
            _transfer(msg.sender, recipient, amount);
            return true;
        }
     function _transfer(address from, address to, uint256 amount ) private {
       
          _Owned[from] = _Owned[from] - amount;
            _Owned[to] = _Owned[to] + amount;

         //_Owned[from] = _Owned[from].sub(amount, "ERC20: transfer amount exceeds balance");
            //_Owned[to] = _Owned[to].add(amount);
        
            emit Transfer(from, to, amount);    
     }
}