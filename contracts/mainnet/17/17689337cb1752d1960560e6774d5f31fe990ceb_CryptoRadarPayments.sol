/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.4;

contract CryptoRadarPayments {
    struct Users {
        address user;
        string discordHandle;
        uint256 startDate;
        uint256 endDate;
        uint256 months;
    }

    struct Payments {
        address user;
        uint256 timestamp;
        uint256 amount;
    }

    mapping(address => bool) public owners;
    mapping(address => Users) public userData;
    mapping(string => address) public discordToAddress;
    mapping(address => Payments[]) public userPayments;

    uint256 public price;
    // 10% percentage = 1000
    uint256 public sponsorPercentage;
    // 10% reduction = 9000
    uint256 public sponsoredReduction;
    uint256 public totalSubscribersCount = 0;

    bool public pause = false;

    constructor(
        uint256 _price,
        uint256 _sponsorPercentage,
        uint256 _sponsoredReduction
    ) {
        owners[msg.sender] = true;
        price = _price;
        sponsorPercentage = _sponsorPercentage;
        sponsoredReduction = _sponsoredReduction;
    }

    modifier onlyOwners() {
        require(owners[msg.sender] == true, "Not owner");
        _;
    }

    // OWNER FUNCTIONS

    function setPrice(uint256 _newPrice) external onlyOwners{
        price = _newPrice;
    }

    function setSponsorPercentage(uint256 _sponsorPercentage) external onlyOwners {
        sponsorPercentage = _sponsorPercentage;
    }

    function setSponsoredReduction(uint256 _sponsoredReduction) external onlyOwners {
        sponsoredReduction = _sponsoredReduction;
    }

    function pauseNewUsers(bool _pause) external onlyOwners {
        pause = _pause;
    }

    function addOwner(address _newOwner) external onlyOwners {
        owners[_newOwner] = true;
    }

    function removeOwner(address _owner) external onlyOwners {
        owners[_owner] = false;
    }

    function withdraw() external onlyOwners {
        payable(msg.sender).transfer(address(this).balance);
    }

    // USERS FUNCTIONSx

    function joinCryptoRadar(address sponsor, uint256 months, string calldata discordHandle) payable external {
        require(!pause, "Contract is paused");
        require(bytes(discordHandle).length>5 && bytes(discordHandle)[bytes(discordHandle).length-5] == "#", "Error in discord Handle");
        require(months == 1 || months == 6 || months == 12, "Months must be 1, 6 or 12");
        if (sponsor != address(0)) {
            require(isActiveSubscriber(sponsor), "Sponsor must be a subscriber");
            require(sponsor != msg.sender, "You cant sponsor yourself");
            uint256 amount = 0;

            if (months == 1) {
                amount = calculatePrice(true, 1);
                require(msg.value == amount);
            } else if (months == 6) {
                amount = calculatePrice(true, 6);
                require(msg.value == amount);
            } else if (months == 12) {
                amount = calculatePrice(true, 12);
                require(msg.value == amount);
            }
            uint256 amountForSponsor = amount * sponsorPercentage / 10000;
            (bool sent,) = sponsor.call{value: amountForSponsor}("");
            require(sent, "Failed to send Ether");

        } else {
            if (months == 1) {
                require(msg.value == calculatePrice(false, 1));
            } else if (months == 6) {
                require(msg.value == calculatePrice(false, 6));
            } else if (months == 12) {
                require(msg.value == calculatePrice(false, 12));
            }
        }

        userPayments[msg.sender].push( Payments(msg.sender, block.timestamp, msg.value) );
        discordToAddress[discordHandle] = msg.sender;
        totalSubscribersCount++;
        if (isActiveSubscriber(msg.sender)) {
            userData[msg.sender] = Users(msg.sender, discordHandle, block.timestamp, userData[msg.sender].endDate + 31 days * months, months);
        } else {
            userData[msg.sender] = Users(msg.sender, discordHandle, block.timestamp, block.timestamp + 31 days * months, months);
        }
    }

    // VIEW FUNCTIONS

    function isActiveSubscriber(address _user) public view returns (bool) {
        return userData[_user].endDate >= block.timestamp;
    }

    function isDiscordActiveSubscriber(string calldata _account) public view returns (bool) {
        return userData[discordToAddress[_account]].endDate >= block.timestamp;
    }

    function discordUserPayments(string calldata _account) public view returns (Payments[] memory) {
        return userPayments[discordToAddress[_account]];
    }

    function calculatePrice(bool _withSponsor, uint256 months) public view returns (uint256) {
        if (_withSponsor) {
            if (months == 1) {
                return price * sponsoredReduction / 10000;
            } else if (months == 6) {
                return 5 * price * sponsoredReduction / 10000;
            } else if (months == 12) {
                return 9 * price * sponsoredReduction / 10000;
            }
        } else {
            if (months == 1) {
                return price;
            } else if (months == 6) {
                return price * 5;
            } else if (months == 12) {
                return price * 9;
            }
        }
        return 0;
    }

}