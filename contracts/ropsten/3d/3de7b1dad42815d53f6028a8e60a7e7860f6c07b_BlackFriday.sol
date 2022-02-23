/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract BlackFriday {

    uint tempo;

    function deposita () payable public {
        tempo = block.timestamp;
    }

    function preleva () public {

        require(block.timestamp > tempo + 5 minutes, "Troppa fretta! Aspetta!");
        payable(msg.sender).transfer(address(this).balance);

    }

}