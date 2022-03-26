/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage 
{
  // bijv. "aap" => 4, "noot" => 5
  mapping(string => uint256) public numbers;

  function store(string memory celidentifier, uint256 waarde) public {
      numbers[celidentifier] = waarde;
  }

  /**
   * @dev Return value 
   * @return value of 'number'
   */
  function retrieve(string memory celidentifier) public view returns (uint256){
      return numbers[celidentifier];
  }
}