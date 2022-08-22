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
    string myMessage;

    function sayHello(string memory myMsg) public {
        if (keccak256(bytes(myMsg)) == keccak256(bytes("forbidden")))
            revert("This is a forbidden message");
        myMessage = myMsg;
    }

    function getHello() public view returns (string memory){
        return myMessage;
    }
}