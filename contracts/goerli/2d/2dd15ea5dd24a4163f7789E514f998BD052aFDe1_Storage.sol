/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address own;
    uint256 number;

    constructor(){
        own=msg.sender;
    } 

    modifier onlyOwner(){
        require(msg.sender==own);
        _;
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public onlyOwner {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    /**
     * @dev Return owner's address 
     * @return the address of 'own'
     */
    function showOwner() public view returns (address){
        return own;
    }
}