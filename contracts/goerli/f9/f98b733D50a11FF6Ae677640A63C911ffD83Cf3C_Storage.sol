/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 depositTime;

    receive () external payable {
        depositTime = block.timestamp;
        // payable(msg.sender).send(msg.value);
    }

    function redeem() public {
        // controlla che siano passate almeno 2 settimane dal deposito
        require(
            block.timestamp > depositTime + 5 minutes, 
            "Deposito bloccato");
        payable(msg.sender).transfer(address(this).balance);        
    }

}