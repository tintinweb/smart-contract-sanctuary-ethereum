/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * Contract to create map and store name and age
 */   
contract AssignmentTwo {
    mapping (address => string) public userNames;
    mapping (address => uint) public userAges;

    /**
     * @dev Store name and age in mapping
     * @param _address, _name, _age value to store
     */
    function storeName(address _address, string memory _name, uint _age) public {
        userNames[_address] = _name;
        userAges[_address] = _age;
    }

    /**
     * @dev Return value 
     * @return value of 'userName'
     */
    function retrieveName(address _address) public view returns (string memory){
        return userNames[_address];
    }

    /**
     * @dev Return value 
     * @return value of 'userAge'
     */
    function retrieveAge(address _address) public view returns (uint){
        return userAges[_address];
    }
}