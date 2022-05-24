/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Run {

    bytes32[] runList= [
            bytes32(0xc6060de721cc74bb0e1fcdf49e31cc9d3762d6f1f782f411c8a996a6761a2e65), // 5 cards
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x76905548d02c922179e04fa971d87a82d1b3ec0acdc3f6d3cc31917397c20c29), // D8D7,A9B2
            bytes32(0x23cae99f146fad7e102a23bd5474af85b2aeee01ff09a5035ed7c779f1f8dc93), // C8D7,A9B2
            bytes32(0xdb8931f81d35ab40d28bc98162876a52b185eeb21016d10b7e637b6a7f56f3af), // A8D7,A9B2
            bytes32(0x23ee040eafb08cfaac04dc7fbf331c03099fcffe6c0ef899888c999d1c014914), // B8D7,A7B2
            bytes32(0xa798eed2c710b39a366bd0dbea94d8c2792330c91167f9fcc0cf69a7b759d611), // C2D7,A7D2 
            bytes32(0x0d918be6699c3a25ce9846a42a79a43634025c185b3f2ac85737026897d37495), // C2C7,A7A2 
            bytes32(0xd37edb40c494e0cfb3a6989bb5a1b8b15079756d8f37bc935f4321e7c9b09dc7), // A3C7,B7A2
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x76905548d02c922179e04fa971d87a82d1b3ec0acdc3f6d3cc31917397c20c29), // D8D7,A9B2
            bytes32(0x23cae99f146fad7e102a23bd5474af85b2aeee01ff09a5035ed7c779f1f8dc93), // C8D7,A9B2
            bytes32(0xdb8931f81d35ab40d28bc98162876a52b185eeb21016d10b7e637b6a7f56f3af), // A8D7,A9B2
            bytes32(0x23ee040eafb08cfaac04dc7fbf331c03099fcffe6c0ef899888c999d1c014914), // B8D7,A7B2
            bytes32(0xa798eed2c710b39a366bd0dbea94d8c2792330c91167f9fcc0cf69a7b759d611), // C2D7,A7D2 
            bytes32(0x0d918be6699c3a25ce9846a42a79a43634025c185b3f2ac85737026897d37495), // C2C7,A7A2 
            bytes32(0xd37edb40c494e0cfb3a6989bb5a1b8b15079756d8f37bc935f4321e7c9b09dc7), // A3C7,B7A2
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x76905548d02c922179e04fa971d87a82d1b3ec0acdc3f6d3cc31917397c20c29), // D8D7,A9B2
            bytes32(0x23cae99f146fad7e102a23bd5474af85b2aeee01ff09a5035ed7c779f1f8dc93), // C8D7,A9B2
            bytes32(0xdb8931f81d35ab40d28bc98162876a52b185eeb21016d10b7e637b6a7f56f3af), // A8D7,A9B2
            bytes32(0x23ee040eafb08cfaac04dc7fbf331c03099fcffe6c0ef899888c999d1c014914), // B8D7,A7B2
            bytes32(0xa798eed2c710b39a366bd0dbea94d8c2792330c91167f9fcc0cf69a7b759d611), // C2D7,A7D2 
            bytes32(0x0d918be6699c3a25ce9846a42a79a43634025c185b3f2ac85737026897d37495), // C2C7,A7A2 
            bytes32(0xd37edb40c494e0cfb3a6989bb5a1b8b15079756d8f37bc935f4321e7c9b09dc7), // A3C7,B7A2
            bytes32(0x71ab9a5855079e4eb1193531dc35dac6da8f3c3d9cecd84ae64e8ea0fde37fa4), // A2B3,A5C7
            bytes32(0xfa21e25f994f035d26a38281a012182d2ea4eb4510cc452444e57139d71c5a1c), // C4D2,A8B5
            bytes32(0x76905548d02c922179e04fa971d87a82d1b3ec0acdc3f6d3cc31917397c20c29), // D8D7,A9B2
            bytes32(0x23cae99f146fad7e102a23bd5474af85b2aeee01ff09a5035ed7c779f1f8dc93), // C8D7,A9B2
            bytes32(0xdb8931f81d35ab40d28bc98162876a52b185eeb21016d10b7e637b6a7f56f3af), // A8D7,A9B2
            bytes32(0x23ee040eafb08cfaac04dc7fbf331c03099fcffe6c0ef899888c999d1c014914), // B8D7,A7B2
            bytes32(0xa798eed2c710b39a366bd0dbea94d8c2792330c91167f9fcc0cf69a7b759d611), // C2D7,A7D2 
            bytes32(0x0d918be6699c3a25ce9846a42a79a43634025c185b3f2ac85737026897d37495), // C2C7,A7A2 
            bytes32(0xd37edb40c494e0cfb3a6989bb5a1b8b15079756d8f37bc935f4321e7c9b09dc7), // A3C7,B7A2
            bytes32(0x658a8b543537d70f4ac82dd2628b0156397e9a2fb533b86e5d141645f08854f8) // all last card
        ];


    // function addRun(bytes32 runKey)
    //     public
    //     returns(bool success)
    // {
    //     runList.push(runKey);
    //     return true;
    // }

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