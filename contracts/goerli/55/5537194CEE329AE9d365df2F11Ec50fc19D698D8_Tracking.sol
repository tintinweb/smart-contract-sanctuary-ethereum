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
        string parcel_hash;
        string location;
        string vehicle_id;
        string status;
    }
    mapping(uint256=>Track_Info) public track_details;

    mapping(uint256=>address[]) public outward_history;

    //To generate a new Parcel ID. 
    function generate_New_Parcel_ID() public{
        parcel_ID=parcel_ID+1;
    }

    //Must call , when the parcel is deaprted 
    function parcel_departed(uint256 _parcelID,string memory _location,string memory _vID) public {
        track_details[_parcelID].location=_location;
        track_details[_parcelID].vehicle_id=_vID;
        outward_history[_parcelID].push(msg.sender);
    }

    //If want to update the location, call this function
    function change_Location(uint256 _parcelID,string memory _location) public {
        track_details[_parcelID].location=_location;
    }

    //must call thihs function by the person, who hand over the parcel to reciepient
    function parcel_hand_over(uint256 _parcelID,address _reciepient) public{
            uint last=outward_history[_parcelID].length-1;
            address _givenby=outward_history[_parcelID][last];
            //checking correct person is hand over the parcel
            require(msg.sender==_givenby);
            //hand over the parcel to _reciepient
             outward_history[_parcelID].push(_reciepient);
    }

    //When the parcel is delivered, call this function to update the status
     function update_StatusAsDelivered(uint256 _parcelID) public {
        track_details[_parcelID].status="Delivered";
    }
    //set hash value for tamperproof
    function set_hash_for_parcel(uint256 _parcelID,string memory _parcelHash) public {
        track_details[_parcelID].parcel_hash=_parcelHash;
    }

}