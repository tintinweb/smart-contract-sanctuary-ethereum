//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract Register{
    struct RegistrationInfo {
        address owner;
        uint askingPrice;
    }
    struct ReturnTypeRegistrationInfo {
        uint plotNumber;
        address owner;
        uint askingPrice;
    }
    mapping (uint => RegistrationInfo) Plots;
    uint[] keyArray;

    event OwnershipTransfered(uint plotNumber,address newOwner);
    event NewRegistration(uint plotNumber, address ownerAddres, uint askingPrice);
    event ChangeAskingPrice(uint plotNumber, uint newAskingPrice);

    function checkRegistration(uint plotNumber) public view returns (RegistrationInfo memory info){
        return Plots[plotNumber];
    }
    function getRegistrationList() public view returns (ReturnTypeRegistrationInfo[] memory data){
        ReturnTypeRegistrationInfo[] memory array = new ReturnTypeRegistrationInfo[](keyArray.length);
        for(uint i=0; i<keyArray.length; i++){
            array[i].plotNumber = keyArray[i];
            array[i].owner = Plots[keyArray[i]].owner; 
            array[i].askingPrice = Plots[keyArray[i]].askingPrice; 
        }
        return array;
    }

    function transferOwnership(uint plotNumber) public payable{
        require(msg.value >= Plots[plotNumber].askingPrice);
        payable(Plots[plotNumber].owner).transfer(msg.value);
        RegistrationInfo storage newOwner = Plots[plotNumber];
        newOwner.owner = msg.sender;
        emit OwnershipTransfered(plotNumber, msg.sender);
    }

    function registerPlot(uint plotNumber,uint price) public{
        RegistrationInfo memory newOwner = RegistrationInfo(msg.sender,price);
        Plots[plotNumber] = newOwner;
        keyArray.push(plotNumber);
        emit NewRegistration(plotNumber, msg.sender, price);
    }

    function changeAskingPrice(uint plotNumber, uint newAskingPrice) public {
        require(msg.sender == Plots[plotNumber].owner,'Only the owner can change the asking Price');
        Plots[plotNumber].askingPrice = newAskingPrice;
        emit ChangeAskingPrice(plotNumber, newAskingPrice);
    }
}