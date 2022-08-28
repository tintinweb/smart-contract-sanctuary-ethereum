/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract FlightInsurance{
    
    //creating event for company
    event Company(address company,uint indexed companyCount);
    //creating event for buyer
    event Buyer(address buyer,uint indexed companyCount);
    //creating event for Late flight
    event Late(address claimer,bool _ans);

    //enum is created to store the status of claimed Insurance
    enum Status{not_claimed,claimed}
    uint public companyCount=0;
    uint public buyerCount=0;
    //declare structure to store the company details
    struct companyDetails{
        uint id;
        string name;
        uint value;
    }
    mapping(uint => companyDetails) public company;
    //declare structure to store the details of Insurance buyer
    struct buyerDetails{
        uint id;
        Status status;
        string name;
        uint amt;
    }
    mapping(uint => buyerDetails) public buyer;

    //function for registering the insurance company
    function registerCompany(string calldata _name, uint _value) public{
        require(_value==10000,"REGISTRATION FEES IS 10000");
        companyCount++;
        company[companyCount]=companyDetails(companyCount,_name,_value);
        emit Company(msg.sender,companyCount);  //emit the company event
    }
    //function for registering the insurance buyer
    function buyInsurance(uint _compID,string calldata _name,uint _amt) public{
        require(_amt==500,"Rs. 500 IS REQUIRED TO BUY");
        require(_compID > 0 && _compID <=companyCount,"COMPANY NOT EXISTS");
        company[_compID].value+=10000;
        buyerCount++;
        buyer[buyerCount]=buyerDetails(buyerCount,Status.not_claimed,_name,_amt);
        emit Buyer(msg.sender,buyerCount);  //emit the buyer event
    }

    //function for getting the late flight info from the client
    function isLate(uint _compID,uint _buyerID,bool _ans) public{
        //if the buyer registered and flight is not late he/she is not eligible for claim
        if(buyer[_buyerID].amt==500&&_ans==false){
            revert("NOT ELIGIBLE");
        }

        //if the buyer do not have the balance of 500, he/she does not have insurance
        require(buyer[_buyerID].amt==500&&_ans==true,"You do not have Insurance");
        buyer[_buyerID].amt+=10000;
        company[_compID].value-=10000;
        buyer[_buyerID].status=Status.claimed;
        emit Late(msg.sender,_ans);     //emit the late event
    }
}