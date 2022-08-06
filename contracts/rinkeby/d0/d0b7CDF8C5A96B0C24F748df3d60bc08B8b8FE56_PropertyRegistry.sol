pragma solidity >=0.7.0 <0.9.0;

import "./Property.sol";

contract PropertyRegistry {
    mapping(address => address) public userToContract;
  
    function deploy() public {
        Property contractAddress = new Property(msg.sender);
        userToContract[msg.sender] = address(contractAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Property {
    address payable public owner;
    uint public x_coord;
    uint public y_coord;

    string public detailsIpfsHash;
    mapping(address => uint) public interestedRenters;

    address public approvedInterestedRenter;
    uint public approvedInterestedRenterTime;
    
    address payable public currentRenter;
    uint public currentRenterTime;
    uint lastRentPaid;

    uint public rentPerMonth;
    uint public securityDepositTime;
    uint securityDeposit;

    constructor(address payable propertyOwner) {
        owner = propertyOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setPropertyRent(uint temp_rentPerMonth, uint temp_securityDepositTime) public onlyOwner {
        require(currentRenter == address(0), "agreement already in place");
        
        rentPerMonth = temp_rentPerMonth;
        securityDepositTime = temp_securityDepositTime;
    }

    function updateInterestedRenter(uint timeInMonths) public {
        require(timeInMonths < 24, "time has to be less than 24 months");
        require(timeInMonths > 0, "time has to be atleast 1 month");

        interestedRenters[msg.sender] = timeInMonths;
        return;
    }

    function removeInterestedRenter() public {
        delete interestedRenters[msg.sender];
        return;
    }

    function approveInterestedRenter(address potentialRenter) public payable onlyOwner {
        require(interestedRenters[potentialRenter] > 0, "renter does not exist");
        require(currentRenter == address(0), "agreement already in place");

        if (securityDeposit > 0) {
            (bool sent, bytes memory data) = owner.call{value: msg.value}("");
            require(sent, "failed to owner");
            securityDeposit = 0;
        }

        approvedInterestedRenter = potentialRenter;
        approvedInterestedRenterTime = interestedRenters[potentialRenter];
        return;
    }

    function acceptAgreement() public payable {
        require(msg.sender == approvedInterestedRenter, "not approved by the owner");
        require(msg.value >= rentPerMonth*securityDepositTime, "security deposit not enough");
        securityDeposit = msg.value;

        currentRenter = payable(approvedInterestedRenter);
        currentRenterTime = approvedInterestedRenterTime;

        approvedInterestedRenter = address(0);
        approvedInterestedRenterTime = 0;

        lastRentPaid = block.timestamp;
    }

    function payRent() public payable {
        require(msg.sender == currentRenter, "unauthorzied");
        require(msg.value >= rentPerMonth, "rent amount is less than required");
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        

        lastRentPaid = block.timestamp;
        currentRenterTime -= 1;
        if (currentRenterTime == 0) {
            endAgreement();
        }   
    }

    function claimRentFromSecurity() public payable onlyOwner {
        require(block.timestamp > lastRentPaid + 30 days, "renter has time to make payment");
        
        (bool sent, bytes memory data) = owner.call{value: securityDeposit >= rentPerMonth ? rentPerMonth : securityDeposit}("");
        require(sent, "Failed to send Ether To property owner");
        securityDeposit -= securityDeposit >= rentPerMonth ? rentPerMonth : securityDeposit;

        currentRenterTime -= 1;
        if (currentRenterTime == 0) {
            endAgreement();
        }

        lastRentPaid = block.timestamp;
    }

    function endAgreement() internal {
        require(currentRenterTime == 0, "time remaining in contract");

        if (securityDeposit > 0) {
            (bool sent, bytes memory data) = currentRenter.call{value: securityDeposit}("");
            require(sent, "Failed to security back to renter");
        }

        securityDeposit = 0;
        currentRenter = payable(address(0));
    }
}