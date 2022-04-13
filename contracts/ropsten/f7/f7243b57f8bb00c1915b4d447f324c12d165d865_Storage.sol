/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint add;

    event stored (address, uint);

    function store(uint num) public {
        require(num<=10,"il numero e troppo grande");
        add = num;
        emit stored (msg.sender, num);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint){
        return add;
    }
}