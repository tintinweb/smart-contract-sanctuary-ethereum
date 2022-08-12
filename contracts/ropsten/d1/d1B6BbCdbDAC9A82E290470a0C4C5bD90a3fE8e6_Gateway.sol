// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "./Donation.sol";

contract Gateway {
    Donation public donation;

    constructor(address _donationAddress){
        donation = Donation(_donationAddress);
    }

    function sendValue() public payable{
        donation.receiveDonation{value:msg.value}();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Donation {
    uint public totalDonatedAmount;

    event donationReceived(
        address _from,
        string message
    );

    function receiveDonation() public payable{
        totalDonatedAmount += msg.value;
        emit donationReceived(msg.sender,"Donation has been received");
    }
}