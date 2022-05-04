/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarRecord {
    uint price;
    uint suggestPrice;
    uint modelYear;
    uint milage;
    string model;

    uint numMaintenance;
    uint numRepair;
    uint numTireChange;

    uint numPrevOwners;
    address owner;
    uint numSold;

    bool isSold;
    bool posted;
    
    
    constructor() {
        price = 0;
        suggestPrice = 0;
        modelYear = 0;
        milage = 0;
        model = "none";

        numMaintenance = 0;
        numRepair = 0;
        numTireChange = 0;

        numPrevOwners = 0;
        owner = msg.sender;
        numSold = 0;

        isSold = false;
        posted = false;
    }

    function postCar(uint _price, uint _year, uint _milage, uint _maint, uint _repair, uint _tirechange, string memory _model, uint _numsold) public returns (bool success) {
        price = _price;
        suggestPrice = _price;
        modelYear = _year;
        milage = _milage;
        model = _model;

        numMaintenance = _maint;
        numRepair = _repair;
        numTireChange = _tirechange;

        numPrevOwners = _numsold;
        numSold = _numsold;

        posted = true;
        return posted;
    }
    
    function getPrice() public view returns(uint) {
        return price;
    }

    function adjustPrice(uint _priceAdjust, uint adjustType) public {
        require(posted && !isSold);
        if (adjustType == 0) {
            price = price - _priceAdjust;
        }
        else {
            price = price + _priceAdjust;
        }
    }
    
    function adjustMilage (uint _milage) public {
        require(posted && !isSold);
        milage = _milage;
    }

    function performMaintenance() public {
        require(posted && !isSold);
        numMaintenance = numMaintenance + 1;
    }

    function performTireChange() public {
        require(posted && !isSold);
        numTireChange = numTireChange + 1;
    }

    function performRepair() public {
        require(posted && !isSold);
        numRepair = numRepair + 1;
    }

    function viewMaintenance() public view returns (uint) {
        return numMaintenance;
    }

    function viewTireChange() public view returns (uint) {
        return numTireChange;
    }

    function viewRepair() public view returns (uint) {
        return numRepair;
    }
    
    function getSuggestedPrice() public view returns (uint) {
        return price - 100 * (numMaintenance + numRepair + numTireChange);
    }

    function transactCar() public payable {
        require(posted && !isSold);
        
        numPrevOwners  = numPrevOwners + 1;
        isSold = true;

    }
    
}