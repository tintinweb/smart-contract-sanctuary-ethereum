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

    //mando i soldi e poi me li riprendo
    receive () external payable {
        depositTime=block.timestamp;
        //payable(msg.sender).send(msg.value)
    }

    function redeem() public {
        //controlla che siano passate due settimane dal deposito
        //if(block.timestamp > depositTime + 14 days)
        //meglio usare require
        require(block.timestamp > depositTime +5 minutes, "Deposit still frozen");
        //require(condizione, messaggio)
        //require(condizione, messaggio)
        payable(msg.sender).transfer(address(this).balance);
    }
}