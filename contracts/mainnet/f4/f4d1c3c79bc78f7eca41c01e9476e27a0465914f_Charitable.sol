/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

pragma solidity ^0.5.8;

/// @title A contract that is able to facilitate donations to different charities
/// whenever a user wants to make a transfer of funds to another user.
contract Charitable {
    address payable owner;
    address payable taxCollectAddress;
    uint256 taxPercent;
    uint256 totalDonationsAmount;
    uint256 highestDonation;
    address payable highestDonor;

    /// @param address_ The tax address to store tax
    constructor(address payable address_) public {
        owner = msg.sender;
        taxCollectAddress = address_;
        taxPercent = 5;
        totalDonationsAmount = 0;
        highestDonation = 0;
    }

    /// Restricts the access only to the user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to the to the user that deployed the contract');
        _;
    }

    /// Validates that the amount to transfer is not zero.
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0.');
        _;
    }

    /// Validates that the donated amount is within acceptable limits.
    ///
    /// @param donationAmount The target donation amount.
    /// @dev donated amount >= 1% of the total transferred amount and <= 50% of the total transferred amount.
    modifier validateDonationAmount(uint256 donationAmount) {
        require(donationAmount >= msg.value / 100 && donationAmount <= msg.value / 2,
            'Donation amount has to be from 1% to 50% of the total transferred amount');
        _;
    }

    /// Transmits the address of the donor and the amount donated.
    event Donation(
        address indexed _donor,
        uint256 _value
    );

    /// Transmits the previous and new owner
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /// Transmits the previous and new tax address
    event TaxAddressTransferred(
        address indexed previousTaxAddress, 
        address indexed newTaxAddress
    );

    /// Transmits the previous and new tax percent
    event TaxPercentageTransferred(
        uint256 indexed previousPercentage, 
        uint256 indexed newPercentage
    );

    /// Redirects transferred funds to the target charity excluding tax.
    /// Whenever a transfer of funds is complete, it emits the event `Donation`.
    ///
    /// @param charityAddress The target donation Address.
    function donate(address payable charityAddress) public validateTransferAmount() payable {
        uint256 taxAmount = msg.value * taxPercent / 100;
        uint256 donationAmount = msg.value - taxAmount;

        charityAddress.transfer(donationAmount);
        taxCollectAddress.transfer(taxAmount);

        emit Donation(msg.sender, donationAmount);

        totalDonationsAmount += donationAmount;

        if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = msg.sender;
        }
    }

    /// Returns tax collect address.
    /// @return taxCollectAddress
    function getAddress() public view returns (address payable) {
        return taxCollectAddress;
    }

    /// Returns the total amount raised by all donations (in wei) towards any charity.
    /// @return totalDonationsAmount
    function getTotalDonationsAmount() public view returns (uint256) {
        return totalDonationsAmount;
    }

    /// Returns the address that made the highest donation, along with the amount donated.
    /// @return (highestDonation, highestDonor)
    function getHighestDonation() public view restrictToOwner() returns (uint256, address payable)  {
        return (highestDonation, highestDonor);
    }

    // Destroys the contract and renders it unusable.
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }

    /// Transfer Ownership
    ///
    /// @param newOwner The new owner of this smart contract.
    function transferOwnership(address payable newOwner) public restrictToOwner() {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// change tax address
    ///
    /// @param newTaxAddress The new tax address
    function setTaxAddress(address payable newTaxAddress) public restrictToOwner() {
        require(newTaxAddress != address(0));
        emit TaxAddressTransferred(taxCollectAddress, newTaxAddress);
        taxCollectAddress = newTaxAddress;
    }

    /// change tax percent
    ///
    /// @param newTaxPercent New tax percent
    function setTaxAddress(uint256 newTaxPercent) public restrictToOwner() {
        require(newTaxPercent != 0);
        emit TaxPercentageTransferred(taxPercent, newTaxPercent);
        taxPercent = newTaxPercent;
    }
}