/**
 *Submitted for verification at Etherscan.io on 2022-08-22
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

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) internal returns (uint256) {
        num += 2;
        num *= 8;
        number = num;
        return retrieve();
    }



    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() internal view returns (uint256){
        return number;
    }

    function integermax1() public pure returns(uint256){
        return type(uint8).max;
    }

    function integermax2() public view returns(uint256){
        return number;
    }

    function integermax3() public {
        number = 5;
    }

    function integermax4() public payable {
        number = msg.value;
    }
}