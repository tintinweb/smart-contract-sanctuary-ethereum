/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

/*
* \copyright
* MIT License
*
* Copyright (c) 2022 Infineon Technologies AG
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE
*
* \endcopyright
*/


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract EVcharging{

    address private Delpoyed_Owner;
    constructor(){
        Delpoyed_Owner=msg.sender;
    }
    struct EVChargingStationOwner{
        string name;
        uint8 Age;
        string Gender;
        string Contact_number;
        string Email;
        bool Status_of_Registration;
    }
    
    struct EVUser{
        string name;
        uint8 Age;
        string Gender;
        string Contact_number;
        string Email;
        bool Status_of_Registration;
    }

    enum availability {AVAILABLE,  OCCUPIED}

    struct EVChargingStation{
        uint64 UniqueStationId;
        StationDetails Station_details;
        availability Availability ;
        uint PriceRate;
        uint slotTime;
        uint FeeCollected;
        address payable Owner; //owner of charging station
        uint TimeOperation;
        address payable CurrentUser;
        bool StatusOfRegistration;
    }

    struct StationDetails{
        string name;
        string location;
        uint8 PowerSupply;
        string chargingType;
    
    }

    event LogRegisterUser(address indexed user_address ,string  registration_Status);
    event LogRegisterStation(uint UniqueStationId, address indexed user_address ,string registration_Status );
    event LogStartCharging(uint FeeCollected, string charging_Status );
    event LogStopCharging(string transaction_status, string feedback);


    mapping (address=>EVChargingStation) public Station_Registration_Details;
    mapping (uint=>EVChargingStation) public Station_Registration_DetailsID;
    
    mapping (address =>EVChargingStationOwner) public Charging_Station_owner_Details;
    mapping (address =>EVUser) public EV_Users_Details;
    
    function RegisterUser(string memory name,
        uint8 Age,
        string memory Gender,
        string memory Contact_number,
        string memory Email) public {
        EVUser memory evuser = EV_Users_Details[msg.sender];
        require(!evuser.Status_of_Registration,"re-registration of User is not possible");
        EV_Users_Details[msg.sender]=EVUser(name,Age,Gender,Contact_number,Email ,true);
        emit LogRegisterUser(msg.sender,"User registration Succesfully");
    }

    function RegisterChargingStation (uint64 UniqueStationId,
        string memory name,
        string memory location,
        uint8 PowerSupply,
        string memory chargingType,
        uint8 priceRate
        ) public {
        EVChargingStation memory evChargingStation=Station_Registration_Details[msg.sender];
        require(!evChargingStation.StatusOfRegistration,"re-registration of charging station is not possible");

        emit LogRegisterStation(UniqueStationId,msg.sender,"User registration Succesfully" );


    StationDetails memory station_details= StationDetails(name,location,PowerSupply,chargingType);

        Station_Registration_Details[msg.sender]=EVChargingStation(
            UniqueStationId,station_details ,availability.AVAILABLE,priceRate,0,0,payable (msg.sender), 0, payable (address(0)) , true);
        Station_Registration_DetailsID[UniqueStationId]=EVChargingStation(
            UniqueStationId,station_details ,availability.AVAILABLE,priceRate,0,0,payable (msg.sender), 0, payable( address(0)) , true);

    
    }

    function StartCharging (uint UniqueStationId, uint current_time, uint slot_time, uint time_operation) payable public {
        EVChargingStation storage evChargingStationID=Station_Registration_DetailsID[UniqueStationId];
        require(!evChargingStationID.StatusOfRegistration,"EV Charging station is not registered on network");
        EVUser memory evuser = EV_Users_Details[msg.sender];
        require(evuser.Status_of_Registration,"EV User is not registered.");

        if(evChargingStationID.Availability==availability.AVAILABLE || (evChargingStationID.slotTime+evChargingStationID.TimeOperation <current_time)) {
            evChargingStationID.Availability=availability.OCCUPIED;
            evChargingStationID.slotTime=slot_time;
            evChargingStationID.TimeOperation=time_operation;
            evChargingStationID.CurrentUser= payable (msg.sender);
            evChargingStationID.FeeCollected=msg.value;
                
        }
        else   {
            revert ("charging Station is occupied now.");

        }

        emit LogStartCharging(msg.value,"charge starting successfully");
    
    }
    function StopCharging (uint UniqueStationId,uint current_time) payable public {
        EVChargingStation storage evChargingStationID=Station_Registration_DetailsID[UniqueStationId];
        require(!evChargingStationID.StatusOfRegistration,"EV Charging station is not registered on network");
        require(evChargingStationID.CurrentUser!=msg.sender,"only current user can access this function");
        require(evChargingStationID.Availability==availability.AVAILABLE,"it is avilable for charging ");
        uint feeCollected=evChargingStationID.FeeCollected;
        uint slot_time=evChargingStationID.slotTime;
        uint Chargingprice=slot_time*evChargingStationID.PriceRate;
        evChargingStationID.Availability=availability.AVAILABLE;
        evChargingStationID.CurrentUser=payable (address(0));
        evChargingStationID.FeeCollected=0;
        evChargingStationID.slotTime=0;
        evChargingStationID.TimeOperation=0;
        if (evChargingStationID.slotTime+evChargingStationID.TimeOperation >current_time){

            evChargingStationID.Owner.transfer(Chargingprice);
            uint remain_amount=feeCollected-Chargingprice;
            (bool success, )=evChargingStationID.CurrentUser.call{value:remain_amount}("");
            require(success,"transaction revert for refund amount of users ");


        }
        else{
            evChargingStationID.Owner.transfer(evChargingStationID.FeeCollected);
        }

        emit LogStopCharging("charging transaction succesfully ", "give positive feedback");
    }


    function PriceRate(uint UniqueStationId) public view returns(uint){
        return Station_Registration_DetailsID[UniqueStationId].PriceRate;

    }

    function UpdatePriceRate(address Owner, uint8 pricerate) public {
        EVChargingStation storage evChargingStation=Station_Registration_Details[Owner];
        evChargingStation.PriceRate=pricerate;
    } 
}