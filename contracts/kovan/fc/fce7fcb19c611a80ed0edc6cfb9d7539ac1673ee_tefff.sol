/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract tefff{

    struct Trip {
        address addr;
        uint num;
        string str;
    }
    mapping(uint => Trip) trips;
    // mapping(uint => Trip[]) trips_1;
    

    function getTest() public view returns(Trip[] memory){
        // return trips[0];
        // Trip memory m;
        // m.addr = 0xbaa65281c2FA2baAcb2cb550BA051525A480D3F4;
        // m.num = 100;
        // m.str = "qwerty";
        // return m;

        Trip[] memory trrips = new Trip[](2);
        // Trip memory trrip = trips[0]
        trrips[0] = trips[0];
        trrips[1] = trips[0];

        // for (uint i = 0; i < 2; i++) {
        //     Trip storage trrip = trips[i];
        //     trrips[i] = trrip;
        // }
        return trrips;

    }

    function setTest() public {
        Trip memory m;
        m.addr = 0xbaa65281c2FA2baAcb2cb550BA051525A480D3F4;
        m.num = 100;
        m.str = "qwerty";
        trips[0]=m;
        
    }
}