// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Ledger__NotOwner();

contract Ledger {
    address public immutable i_owner;
    address[] public users;
    mapping(address => uint256) public s_donatorToDonatedAmounts;
    mapping(address => uint256) public s_addressToDataHash;

    event NewDataStore(address owner, string data);
    event DonationWithdrawal();
    event NewDonation();

    constructor() {
        i_owner = msg.sender;
    }

    function registerNewData(string memory data) public {
        emit NewDataStore(msg.sender, data);
    }

    function withdraw() public onlyOwner {
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
            revert Ledger__NotOwner();
        }
        _;
    }
}