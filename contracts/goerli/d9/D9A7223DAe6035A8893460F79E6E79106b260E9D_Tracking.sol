/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <=0.9.1;
contract Tracking {
    uint256 public parcel_ID=1000; //Assume parcel ID starting from 1000

    //Tracking Informations
    struct Track_Info{
        uint256 parcel_ID;
        string location;
        string vehicle_id;
        string status;
    }
    mapping(uint256=>Track_Info) public track_details;

    //To generate a new Parcel ID. 
    function generate_New_Parcel_ID() public{
        parcel_ID=parcel_ID+1;
    }

    //Must call , when the parcel is deaprted 
    function parcel_departed(uint256 _parcelID,string memory _location,string memory _vID) public {
        track_details[_parcelID]=Track_Info(_parcelID,_location,_vID,"Dispatched");
    }

    //If want to update the location, call this function
    function update_Location(uint256 _parcelID,string memory _location) public {
        track_details[_parcelID].location=_location;
    }

    //When the parcel is delivered, call this function to update the status
     function update_StatusAsDelivered(uint256 _parcelID) public {
        track_details[_parcelID].status="Delivered";
    }
}