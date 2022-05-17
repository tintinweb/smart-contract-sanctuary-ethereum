//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract Register{
    struct RegistrationInfo {
        address owner;
        uint askingPrice;
    }
    mapping (uint => RegistrationInfo) Plots;

    event OwnershipTransfered(uint plotNumber,address newOwner);
    event NewRegistration(uint plotNumber, address ownerAddres, uint askingPrice);
    event ChangeAskingPrice(uint plotNumber, uint newAskingPrice);

    function checkRegistration(uint plotNumber) public view returns (RegistrationInfo memory info){
        return Plots[plotNumber];
    }

    function transferOwnership(address buyerAddress, uint plotNumber) public payable{
        require(msg.value >= Plots[plotNumber].askingPrice);
        payable(Plots[plotNumber].owner).transfer(msg.value);
        RegistrationInfo storage newOwner = Plots[plotNumber];
        newOwner.owner = buyerAddress;
        emit OwnershipTransfered(plotNumber, buyerAddress);
    }

    function registerPlot(address newOwnerAddress, uint plotNumber,uint price) public{
        RegistrationInfo memory newOwner = RegistrationInfo(newOwnerAddress,price);
        Plots[plotNumber] = newOwner;
        emit NewRegistration(plotNumber, newOwnerAddress, price);
    }

    function changeAskingPrice(uint plotNumber, uint newAskingPrice) public {
        require(msg.sender == Plots[plotNumber].owner,'Only the owner can change the asking Price');
        Plots[plotNumber].askingPrice = newAskingPrice;
        emit ChangeAskingPrice(plotNumber, newAskingPrice);
    }
}