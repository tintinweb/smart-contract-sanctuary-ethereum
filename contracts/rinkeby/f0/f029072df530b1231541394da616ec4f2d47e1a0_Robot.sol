/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Robot{

    struct head {
        address location;
        string serial;
        bool normal;

    }

    struct arm{
        address location;
        string serial;
        bool normal;

    }

    struct leg {
        address location;
        string serial;
        bool normal;


    }

    struct body {
        address location;
        string serial;
        bool normal;


    }
    constructor(){

    }

    function addHead() public {}
    function addBody() public {}
    function addArm() public {}
    function addLeg() public {}

}