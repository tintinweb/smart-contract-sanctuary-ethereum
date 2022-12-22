/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title IDX_Buy_Sale
 * @dev Implements voting process along with vote delegation
 */

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IDX_Buy_Sale {
    using SafeMath for uint256;
    mapping (address => uint) public investors;
    mapping (address => uint) public sellers;
    mapping (address => uint) public owners;

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function transferMoney(address payable _toSeller, address payable _toOwner) public payable {
        uint256 amountOwner = msg.value.div(50);
        uint256 amountSeller = msg.value.sub(amountOwner);
        investors[msg.sender] += msg.value;
        sellers[_toSeller] += amountSeller;
        owners[_toOwner] += amountOwner;
        _toSeller.transfer(amountSeller);
        _toOwner.transfer(amountOwner);
    }

}