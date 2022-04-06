// SPDX-License-Identifier: MIT

/**
*   @title Royalty Split
*   @author Transient Labs
*   @notice contract to receive ether on royalty payouts and then payout to each party
*/

pragma solidity ^0.8.0;

contract RoyaltySplit {

    address payable[] public payoutAddresses;
    mapping(address => bool) internal isPayoutAddress;
    uint256[] public royaltyPerc; // decimal representation of split multiplied by 1000

    event etherReceived(address from, uint256 value);
    event royaltiesPaid(address to, uint256 value);

    /**
    *   @notice constructor
    *   @dev requires the input parameters to be the same length
    *   @dev requires that the elements in perc add up to 1000
    *   @param addr is an array of addresses to payout royalties too
    *   @param perc is an array of uint256 values 
    */
    constructor(address[] memory addr, uint256[] memory perc) {
        require(addr.length == perc.length, "Error: arguments are not the same length");

        uint256 sum;
        for (uint256 i = 0; i < perc.length; i++) {
            sum = sum + perc[i];
        }
        require(sum == 1000, "Error: percentage values don't add to 1000");

        for (uint256 i = 0; i < addr.length; i++) {
            payoutAddresses.push(payable(addr[i]));
            isPayoutAddress[addr[i]] = true;
            royaltyPerc.push(perc[i]);
        }
    }

    modifier payoutAddr {
        require(isPayoutAddress[msg.sender], "Error: caller is not a payout address");
        _;
    }

    /**
    *   @notice function to payout royalties
    *   @dev this pays out to every recipient, so that tracking royalties is easy
    *   @dev recipients should take turns calling this function to spread out gas fees
    */
    function payoutRoyalties() public payoutAddr {
        require(address(this).balance != 0); // dev: 0 ether balance
        // store current state of the balance
        uint256 balance = address(this).balance;
        
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 val = balance * royaltyPerc[i] / 1000;
            payoutAddresses[i].transfer(val);
            emit royaltiesPaid(payoutAddresses[i], val);
        }
    }

    /**
    *   @notice function to receive ether
    *   @dev emits an event showing that ether has been received
    */
    receive() external payable {
        emit etherReceived(msg.sender, msg.value);
    }
}