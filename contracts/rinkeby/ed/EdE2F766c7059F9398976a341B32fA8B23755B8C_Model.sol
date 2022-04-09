/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Model {
    struct Booking{
        uint tablePos;
        uint numPeople;
        string time;
    }

    mapping(uint=>Booking) public bookingMapping;
    uint count;

    function storeBooking(uint _tablePos, uint _numPeople, string memory _time) public {
        bookingMapping[count].tablePos = _tablePos;
        bookingMapping[count].numPeople = _numPeople;
        bookingMapping[count].time = _time;
        count++;
    }

    function retrieveAllBooking() public view returns (uint[] memory, uint[] memory, string[] memory){
        uint[] memory _tablePos = new uint[](count);
        uint[] memory _numPeople = new uint[](count);
        string[] memory _time = new string[](count);
        for(uint loop = 0; loop < count; loop++){
            _tablePos[loop] = bookingMapping[loop].tablePos;
            _numPeople[loop] = bookingMapping[loop].numPeople;
            _time[loop] = bookingMapping[loop].time;
        }
        return (_tablePos,_numPeople,_time);
    }


}