/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Donate {

    struct Donor {
        bool donated; 
        uint money;
    }

    uint num; 
    mapping(address => Donor) public Donors;
    address[] public donorHash;
    uint numberofdonate=0;

    event NewDonate(
        address donor
    );

    function donorsHashCount() public view returns (uint) {
        return donorHash.length;
    }

    function getnumberofdonate() public view returns (uint) {
        return numberofdonate;
    }

    function getTotalDonation() public view returns (uint) {
        return num;
    }

    // Actions
    function donate(address donor,uint count)  public returns (bool) {

        Donor storage sender = Donors[donor];

        if (sender.donated != true) {
          donorHash.push(donor);
          sender.donated=true;
        }
        sender.money=count;

        num+=count;

        emit NewDonate(donor);

        numberofdonate++;

        return true;
    }
}