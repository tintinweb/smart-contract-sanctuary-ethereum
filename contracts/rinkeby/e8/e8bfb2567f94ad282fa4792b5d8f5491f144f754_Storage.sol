/**
 *Submitted for verification at Etherscan.io on 2022-05-20
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
    uint256 private _publicSaleTime;


    constructor(){
        _publicSaleTime = block.timestamp + 20; 
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public payable {
        require(isPublicSaleActive(), "Public Sale not active!");
        number = num;
    }

    function isPublicSaleActive() public view returns (bool) {
        return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
    }

    function updatePublicSaleTime() public {
        _publicSaleTime = block.timestamp + 20;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}