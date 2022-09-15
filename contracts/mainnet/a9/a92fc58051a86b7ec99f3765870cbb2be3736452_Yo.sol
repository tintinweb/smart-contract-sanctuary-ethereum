/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Yo
 * @dev Returns "Yo"
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Yo {

    /**
     * @dev WhatsUp value 
     * @return "Yo"
     */
    function WhatsUp() public pure returns (string memory){
        string memory foo;
        foo = "Yo";
        return foo;
    }
}