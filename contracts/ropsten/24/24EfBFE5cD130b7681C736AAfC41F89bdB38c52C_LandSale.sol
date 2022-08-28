/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract LandSale{
    //declare structure to store owners details
    struct ownerDetails{
        string ownerName;
        string ownerAdhaar;
        string dob;
        address ownerAddr;
    }
    ownerDetails public owner;
    // constructor for register the owner while deploying
    constructor(string memory _name,string memory _adhaarno,string memory _dateob,address _addr){
        owner=ownerDetails(_name,_adhaarno,_dateob,_addr);
    }
    //enum is used to store the land status whether it is available to sale or not
    enum landState{available,sold}

    //declare structure to store Buyer's details
    struct BuyerDetails{
        address buyerAddr;
        string buyerName;
        string buyerAadhar;
        string buyerDOB;
    }
    mapping(address => BuyerDetails) public buyer;

    //declare structure to store Land information
    struct LandDetails{
        uint id;
        uint price;
        landState landStatus;
    }
    mapping(uint => LandDetails) public land;
    
    //function is used to add the land details
    function addLand(uint _id, uint _price)public{
        land[_id]=LandDetails(_id,_price,landState.available);
    }

    //function is used to delete the land from the mapping structure after being sold
    function delLand(uint _id) public{
        delete land[_id];
        land[_id].landStatus=landState.sold;
    }

    //function to add the buyers details who wants to purchase the land 
    function wantBuy(uint _landID, string calldata _buyerName,string calldata _buyerAadhaar, string calldata _buyerDOB, address _buyerAddr) public {
        buyer[_buyerAddr]=BuyerDetails(_buyerAddr,_buyerName,_buyerAadhaar,_buyerDOB);

        //require is use to check whether the requesting land of purchase is available or not
        require(land[_landID].landStatus==landState.available,"LAND IS SOLD");
        owner=ownerDetails(_buyerName,_buyerAadhaar,_buyerDOB,_buyerAddr);      //ownership is changed
        delLand(_landID);
        
    }
    
}