/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;




contract example {
    mapping  (address => uint256) exampleMapping;

    function migrate(address _beneficiary, uint256 _amount) external  { 
    exampleMapping[_beneficiary] = _amount;
    }

   function returnMappingValue(address _address) public view returns (uint) {
        return exampleMapping[_address];
    }
}