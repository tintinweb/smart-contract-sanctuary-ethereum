/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract EventsManager {
    event Publish(address[] authors, string uri, string digest);
    constructor() {
    }
    function deposit(address[] calldata authors, string calldata uri, string calldata digest) public {      
      emit Publish(authors, uri, digest);
   }
}