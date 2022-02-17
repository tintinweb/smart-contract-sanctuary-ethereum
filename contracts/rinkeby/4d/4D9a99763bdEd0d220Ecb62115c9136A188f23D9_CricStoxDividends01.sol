/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

// 
contract CricStoxDividends01 {
    using SafeMath for uint256;
    
    address public serverAddress;
    mapping (address => uint256) public totalPools; // address of stox token to quantity
    mapping (address => uint256) public availablePools;
    mapping (address => mapping(address => uint256)) public claimedDividends; // user address => (stox address => quantity)

    constructor(address serverAddress_) {
        serverAddress = address(serverAddress_);
    }
    
    function addToPool(address stox_, uint256 quantity_) public {
        totalPools[stox_] = totalPools[stox_].add(quantity_);
        availablePools[stox_] = availablePools[stox_].add(quantity_);
    }

    // On server
    // get the list of total dividends (stox => quantity) for that particular wallet address
    // we will abi encode (user_, stox_[], quantity_[])
    // take hash of it
    // ecSign the hash using server wallet private key
    function claimDividend(address user_, address[] memory stox_, uint256[] memory quantity_, bytes memory signature_) public {
        // we will abi encode (user_, stox_[], quantity_[])
        // take hash of it
        // ecAddress = ecRecover of signature_ (parameters to this will be hash and signature)
        // we will check if the address if our server wallet (require ecAddress = serverAddress)
        // calculate transferrable amount (quantity - claimedDividends)
        // transfer the transferrable amount to user from pool (while transferring, we should check if transferrable<= availablePools)
        // update availablePools (sub transferrable amount to the current)
        // update the claimedDividends for the user (add transferrable amount to the current)
    }
}