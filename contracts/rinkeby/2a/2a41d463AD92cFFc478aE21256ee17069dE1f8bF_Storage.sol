/**
 *Submitted for verification at Etherscan.io on 2022-05-12
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
    string[] ppl;

    /**
     * @dev Store value in variable
     * @param num value to store
     * @param _name value to store
     */
    function store(uint256 num, string memory _name, string[] memory _people) public {
        number = num;
        name = _name;
        ppl = _people;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256, string memory, string[] memory){
        return (number, name, ppl);
    }
}