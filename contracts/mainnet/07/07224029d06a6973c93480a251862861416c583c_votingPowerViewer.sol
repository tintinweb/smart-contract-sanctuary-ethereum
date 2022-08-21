/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: UNLICENSED

interface sHakka {
    function votingPower(address) external view returns (uint256);
}

contract votingPowerViewer {
    function votingPower(address user) external view returns (uint256) {
        sHakka SH = sHakka(0xd9958826Bce875A75cc1789D5929459E6ff15040);
        uint256 time = block.timestamp;
        if (time > 1686646318) return 0;
        else return SH.votingPower(user) * (1686646318 - time) / 1461 days;
    }
}