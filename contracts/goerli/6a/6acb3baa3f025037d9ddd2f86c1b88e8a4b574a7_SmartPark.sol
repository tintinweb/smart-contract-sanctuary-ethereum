/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract SmartPark {

    struct CarSpace {
        address owner;
        uint starttime;
        uint endtime;
        uint price;

        uint status;

        address renter;
        uint rstarttime;
        uint rendtime;

    }

    mapping(uint => CarSpace) public carSpaces;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function shareCarSpace(uint id, uint starttime, uint endtime, uint price) public {
        require(starttime < endtime, "SmartPark: start time must be lower than end time");
        carSpaces[id] = CarSpace({
            owner: msg.sender,
            starttime: starttime,
            endtime: endtime,
            price: price,
            status: 0,
            renter: address(0),
            rstarttime: 0,
            rendtime: 0
        });
    } 

    function rentCarSpace(uint spaceId, uint starttime, uint endtime) public {
        CarSpace storage cs = carSpaces[spaceId];
        require(cs.status == 0, "SmartPark: car space used");
        require(cs.starttime <= starttime && cs.endtime >= endtime && starttime < endtime, "SmartPark: time is error");
        cs.status = 1;
        cs.renter = msg.sender;
        cs.rstarttime = starttime;
        cs.rendtime = endtime;
    }

}