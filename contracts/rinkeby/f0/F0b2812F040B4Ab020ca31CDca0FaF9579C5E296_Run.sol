/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Run {

    bytes32[] runList= [
            bytes32(0xc6060de721cc74bb0e1fcdf49e31cc9d3762d6f1f782f411c8a996a6761a2e65), // 5 cards
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x658a8b543537d70f4ac82dd2628b0156397e9a2fb533b86e5d141645f08854f8) // all last card
        ];

    function getRunCount()
        public view
        returns(uint runCount)
    {
        return runList.length;
    }

    function getRunAtIndex(uint row)
        public view
        returns(bytes32 runKey)
    {
        return runList[row];
    }

}