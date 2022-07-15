// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error BuyMeACoffee__NotOwner();
error BuyMeACoffee__WithdrawFailed();
error BuyMeACoffee__DidNotSendEnough();

contract BuyMeACoffee {
    uint256 private immutable i_minimumDonation;
    address private immutable i_owner;
    address[] private s_donators;
    mapping(address => uint256) private s_addressToAmountDonated;
    mapping(address => string) private s_addressToMessage;
    mapping(address => bool) private s_addressToExists;

    event Withdraw(uint256 amount);
    event BuyCoffee(address indexed donator, uint256 amount, string message);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert BuyMeACoffee__NotOwner();
        }
        _;
    }

    modifier minDonation(uint256 minimumDonation) {
        if (msg.value < (minimumDonation)) {
            revert BuyMeACoffee__DidNotSendEnough();
        }
        _;
    }

    constructor(uint256 minimumDonation) {
        i_owner = msg.sender;
        i_minimumDonation = minimumDonation;
    }

    function buyCoffee(string memory message) public payable minDonation(i_minimumDonation) {
        s_addressToAmountDonated[msg.sender] += msg.value;
        s_addressToMessage[msg.sender] = string(
            abi.encodePacked(s_addressToMessage[msg.sender], "\n", message)
        );

        if (!s_addressToExists[msg.sender]) {
            s_addressToExists[msg.sender] = true;
            s_donators.push(msg.sender);
        }

        emit BuyCoffee(msg.sender, msg.value, message);
    }

    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = i_owner.call{value: amount}("");

        if (!success) {
            revert BuyMeACoffee__WithdrawFailed();
        } else {
            emit Withdraw(amount);
        }
    }

    function getMinimumDonation() public view returns (uint256) {
        return i_minimumDonation;
    }

    function getAddressToAmountDonated(address donator) public view returns (uint256) {
        return s_addressToAmountDonated[donator];
    }

    function getAddressToMessage(address donator) public view returns (string memory) {
        return s_addressToMessage[donator];
    }

    function getDonator(uint256 index) public view returns (address) {
        return s_donators[index];
    }

    function getDonatorsCount() public view returns (uint256) {
        return s_donators.length;
    }

    function getAddressToExists(address donator) public view returns (bool) {
        return s_addressToExists[donator];
    }
}