/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12;

/**
 * Contract to store and retrive name
 *
 */
 contract NameManagement {
    string public userName;

    /**
     * @dev Store value in variable
     * @param _name value to store
     */
    function storeName(string memory _name) public {
        userName = _name;
    }

    /**
     * @dev Return value 
     * @return value of 'userName'
     */
    function retrieveName() public view returns (string memory){
        return userName;
    }
    
 }