// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Error
error Donation__NotOwner();

contract Donation {
    // State Variables
    address public immutable i_owner;
    uint256 public totalDonations;
    address[] public donators;
    mapping(address => uint) public donatorToDoantion;

    constructor() {
        i_owner = msg.sender;
    }

    // Events

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Donation__NotOwner();
        }
        _;
    }

    // Receive
    receive() external payable {
        totalDonations += msg.value;
    }

    // Fallback
    fallback() external payable {
        totalDonations += msg.value;
    }

    // External Functions

    // Public Functions
    function donate() public payable {
        totalDonations += msg.value;
        donators.push(msg.sender);

        uint previousDonation = donatorToDoantion[msg.sender];
        donatorToDoantion[msg.sender] = previousDonation + msg.value;
    }

    function withdraw() public {
        require(msg.sender == i_owner);
        payable(msg.sender).transfer(totalDonations);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance / 1 ether;
    }

    function getDonators() public view returns (address[] memory) {
        return donators;
    }

    function rankByDonation() public view returns (address[] memory) {
        address[] memory _donators = donators;
        for (uint i = 0; i < _donators.length; i++) {
            bool swapped = false;
            for (uint j = i + 1; j < _donators.length; j++) {
                if (donatorToDoantion[_donators[i]] < donatorToDoantion[_donators[j]]) {
                    address temp = _donators[i];
                    _donators[i] = _donators[j];
                    _donators[j] = temp;
                    swapped = true;
                }
            }
            if (!swapped) {
                break;
            }
        }
        return _donators;
    }

    /**
     * @dev get donation of a donator in ether
     * @param _donator address of the donator
     * @return donation of the donator in ether
     */
    function getDonationOf(address _donator) public view returns (uint) {
        return donatorToDoantion[_donator] / 1 ether;
    }

    // Internal Functions

    // Private Functions
}