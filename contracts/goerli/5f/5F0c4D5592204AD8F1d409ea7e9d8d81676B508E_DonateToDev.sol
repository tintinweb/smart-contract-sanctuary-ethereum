//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.4;

// Switch this to your own contract address once deployed, for bookkeeping!
//Contract Address on Goerli:  0x5F0c4D5592204AD8F1d409ea7e9d8d81676B508E

contract DonateToDev {
    // Event to emit when a Donation is happens.
    event NewDonation(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    
    // Donation struct.
    struct Donation{
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;
    // List of all Donations received from coffee purchases.
    Donation[] donations;
    
    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored Donations
     */
    function getDonations() public view returns (Donation[] memory) {
        return donations;
    }
    /**
     * @dev donate to the dev (sends an ETH tip and leaves a memo)
     * @param _name name of donor
     * @param _message a nice message from the donor
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "value isn't greater than 0");

        // Add the memo to storage!
        donations.push(Donation(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewDonation event with details about the donation.
        emit NewDonation(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}