//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

contract Register{
    struct RegistrationInfo {
        address owner;
        uint price;
        uint askingPrice;
    }
    struct RegistrationInfoReturn {
        uint plotNumber;
        RegistrationInfo[] transactions;
    }
    mapping (uint => RegistrationInfo[]) Plots;
    uint[] keyArray;

    event OwnershipTransfered(uint plotNumber,address newOwner);
    event NewRegistration(uint plotNumber, address ownerAddres, uint askingPrice);
    event ChangeAskingPrice(uint plotNumber, uint newAskingPrice);

    function checkRegistration(uint plotNumber) public view returns (RegistrationInfo[] memory info){
        return Plots[plotNumber];
    }
    function getRegistrationList() public view returns (RegistrationInfoReturn[] memory data){
        RegistrationInfoReturn[] memory array = new RegistrationInfoReturn[](keyArray.length);
        for(uint i=0; i<keyArray.length; i++){
        RegistrationInfo[] storage member = Plots[keyArray[i]];
        array[i] = RegistrationInfoReturn(keyArray[i], member);
        }
        return array;
    }

    function transferOwnership(uint plotNumber) public payable{
        require(msg.value >= Plots[plotNumber][Plots[plotNumber].length - 1].askingPrice);
        RegistrationInfo[] storage newOwner = Plots[plotNumber];
        RegistrationInfo memory newOwnerObject = RegistrationInfo(msg.sender,newOwner[newOwner.length - 1].askingPrice, newOwner[newOwner.length - 1].askingPrice);
        payable(newOwner[newOwner.length - 1].owner).transfer(msg.value);
        newOwner.push(newOwnerObject);
        Plots[plotNumber] = newOwner;
        emit OwnershipTransfered(plotNumber, msg.sender);
    }

    function registerPlot(uint plotNumber,uint price) public{
        RegistrationInfo memory newOwnerObject = RegistrationInfo(msg.sender,price,price);
        RegistrationInfo[] storage newOwner = Plots[plotNumber];
        newOwner.push(newOwnerObject);
        Plots[plotNumber] = newOwner;
        keyArray.push(plotNumber);
        emit NewRegistration(plotNumber, msg.sender, price);
    }

    function changeAskingPrice(uint plotNumber, uint newAskingPrice) public {
        RegistrationInfo[] storage newOwner = Plots[plotNumber];
        require(msg.sender == newOwner[newOwner.length - 1].owner,'Only the owner can change the asking Price');
        newOwner[newOwner.length - 1].askingPrice = newAskingPrice;
        Plots[plotNumber] = newOwner;
        emit ChangeAskingPrice(plotNumber, newAskingPrice);
    }
}