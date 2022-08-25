/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SampleERC721
 * @dev Create a sample ERC721 standard token
 */
contract MikeHW  {

string public thisIsMyName;
    constructor() {
       thisIsMyName="michael";
    }
      function setName(string memory aName) public {
        thisIsMyName = aName;
    }
    function getName()public view returns(string memory){
        return thisIsMyName;
    }
}