/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;
    string name;

    /**
     * @dev Store value in variable
     * @param _num number to store
     * @param _name name to store
     */
    function store(uint256 _num, string memory _name) public {
        number = _num;
        name = _name;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveNumber() public view returns (uint256){
        return number;
    }

    /**
     * @dev Return value 
     * @return value of 'name'
     */
    function retrieveName() public view returns (string memory){
        return name;
    }
}