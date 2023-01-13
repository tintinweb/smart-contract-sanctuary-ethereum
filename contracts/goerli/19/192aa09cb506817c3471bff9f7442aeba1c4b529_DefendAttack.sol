/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface FrontLinesInterface {
    function setDefendingQ00tantSquad(address _q00tantSquad) external;
    function attack(address _cornSquad) external;
}

contract DefendAttack {

    address FrontLinesAddress = 0x0F9B1418694ADAEe240Cb0d76B805d197da5ae8a;

    FrontLinesInterface FrontLinesContract = FrontLinesInterface(FrontLinesAddress);

    function lol(address q00tantSquad, address cornSquad) external {

        FrontLinesContract.setDefendingQ00tantSquad(q00tantSquad);
        FrontLinesContract.attack(cornSquad);

    }

}