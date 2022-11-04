/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error NotOwnerError();

contract Ledger {
    address public immutable i_owner;
    address[] public users;
    mapping(address => uint256) public s_donatorToDonatedAmounts;
    mapping(string => address) public s_cidToAddress;
    mapping(address => string[]) public s_addressToOwnedCids;

    event NewCidRegistered(address ownerAddress, string cid);
    event DonationsWithdrawal();
    event NewDonation();

    constructor() {
        i_owner = msg.sender;
    }

    function registerNewData(string memory cid) public {
        s_cidToAddress[cid] = msg.sender;
        s_addressToOwnedCids[msg.sender].push(cid);
        emit NewCidRegistered(msg.sender, cid);
    }

    function withdraw() public onlyOwner {
        emit DonationsWithdrawal();
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed!");
    }

    // called when no call data is specifiess
    receive() external payable {
        s_donatorToDonatedAmounts[msg.sender] += msg.value;
        emit NewDonation();
    }

    // called when the function from call data is not found
    fallback() external payable {
        revert();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwnerError();
        }
        _;
    }
}