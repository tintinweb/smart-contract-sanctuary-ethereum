/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SmartVehicleCheckpoint
{

    string public ev_name;
    string public ev_id;
    string public latitude;
    string public longitude;
    string public altitude;
    string public soc;

    constructor(
        string memory _ev_name, 
        string memory _ev_id, 
        string memory _latitude, 
        string memory _longitude, 
        string memory _altitude, 
        string memory _soc) 
    {
        ev_name = _ev_name;
        ev_id = _ev_id;
        latitude = _latitude;
        longitude = _longitude;
        altitude = _altitude;
        soc = _soc;
    }

}