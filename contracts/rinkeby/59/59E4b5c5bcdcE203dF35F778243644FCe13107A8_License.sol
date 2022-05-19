/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract License {

    address[] public licenses;
    uint256 timeLimit;
    address public owner;

    constructor (){
        owner = msg.sender;
    }

    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }


    function setLicense(address newLicense) external OnlyOwner {
        licenses.push(newLicense);
    }


    function getArray() public view returns (address[] memory){
       return licenses;
    }

    function removeLicenses() external OnlyOwner {
        delete licenses;
    }

}