// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeSharp.sol";

contract SafeSharp is Ownable {
    mapping(address => bool) public referralPartners;

    /*****------- CONSTANTS -------******/
    bool public survivorBettingOn = true;
    uint256 public HOUSE_PAY_BIP = 1000;
    uint256 public REFERRAL_PAY_BIP = 180;
    uint256 public PARTNER_REFERRAL_PAY_BIP = 250;
    uint256 public betSize = 0.06 ether;

    address public HOUSE_ADDRESS = 0xcE6377f66982d3C9dc83f1d7E08D29839296e2F5;

    /*****------- DATATYPES -------******/
    /// Status

    struct SurvivorBet {
        uint256 betAmount;
        uint256 paidOut;
        uint256[18] picks;
        uint dateTime;
        address picker;
        address referral;
        bool active;
    }

    mapping(address => uint256) public survivorBetLog;

    // map week to an array of bets. e.g. weeklyBets[1] = array of week 1 bets
    SurvivorBet[] public survivorBet;

    SurvivorBet[] public winnersSurvivor;

    // map week to the pool amount for that week. e.g. weeklyPoolSmall[4] = 50 which means 50 ETH
    uint256 public survivorPool;

    /*****------- CONSTRUCTOR -------******/
    constructor() public {}


    function setPartnerRoyalty(address _address) external onlyOwner {
        referralPartners[_address] = true;
    }

    function resetPartnerRoyalty(address _address) external onlyOwner {
        referralPartners[_address] = false;
    }

    function setPartnerReferral(uint256 bip) external onlyOwner {
        require(bip <= HOUSE_PAY_BIP, "Partner referral BIP is higher than the House BIP");
        PARTNER_REFERRAL_PAY_BIP = bip;
    }

    function setNormalReferral(uint256 bip) external onlyOwner {
        require(bip <= HOUSE_PAY_BIP, "Referral BIP is higher than the House BIP");
        REFERRAL_PAY_BIP = bip;
    }

    function setHouse(uint256 bip) external onlyOwner {
        require(bip <= 10000, "Referral BIP is higher than 100%");
        HOUSE_PAY_BIP = bip;
    }

    function getSurvivorPicksByAddress(address _address) public view returns (SurvivorBet[] memory) {
        SurvivorBet[] memory pool = new SurvivorBet[](survivorBetLog[_address]);
        uint256 counter = 0;

        for (uint256 i; i < survivorBet.length; i++) {
            if (_address == survivorBet[i].picker) {
                pool[counter] = survivorBet[i];
                counter += 1;
            }
        }

        return pool;
    }

    function getSurvivorPool() public view returns (SurvivorBet[] memory) {
        SurvivorBet[] memory pool;
        pool = new SurvivorBet[](survivorBet.length);
        for (uint256 i; i < survivorBet.length; i++) {
            pool[i] = survivorBet[i];
        }
        return pool;
    }

    function setSurvivor(uint256[18] memory _picks, address _referral, uint _dateTime) external payable {
        require(msg.value == betSize, "Not enough for a bet");
        require(survivorBettingOn, "Survivor betting is not live");

        SurvivorBet memory _survivorBet = SurvivorBet(
            msg.value,
            0,
            _picks,
            _dateTime, 
            msg.sender,
            _referral,
            true
        );
        survivorBetLog[msg.sender] = survivorBetLog[msg.sender] + 1;
        survivorBet.push(_survivorBet);
        survivorPool += msg.value - ((msg.value * HOUSE_PAY_BIP) / 10000);


        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        // if the referring address is a non-zero address:
        if (_referral != address(0)) {
            // check if referral address is true in referral partners
            if (referralPartners[_referral]) {
                payable(_referral).transfer((msg.value * PARTNER_REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - PARTNER_REFERRAL_PAY_BIP;
            } else {
                payable(_referral).transfer((msg.value * REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
            }
        }
        payable(HOUSE_ADDRESS).transfer(
            (msg.value * HOUSE_PAY_NET_BIP) / 10000
        );
    }

    /*****------- OWNER FUNCTIONS -------******/

    function flipSurvivor() external onlyOwner {
        survivorBettingOn = !survivorBettingOn;
    }

    function setHouseAddress(address _address) external onlyOwner {
        HOUSE_ADDRESS = _address;
    }

    function setHouseAmount(uint256 _percentage) external onlyOwner {
        HOUSE_PAY_BIP = _percentage;
    }

    function setReferralAmount(uint256 _referral) external onlyOwner {
        REFERRAL_PAY_BIP = _referral;
    }

    /**** PICK AND PAY OUT SIZE POOL FOR SURVIVOR  ****/
    /*** Size 0 = small, Size 1 = medium, Size 2 = large ***/
    function pickSurvivorWinner(uint256[][] memory correctPicks) external onlyOwner returns (uint256) {
        // require(correctPicks.length == 18, "Picks array must be 19 in length");
        uint256 highestRightCount = 0;
        SurvivorBet[] memory pool;
        uint256 winningAmount;

        pool = survivorBet;
        winningAmount = survivorPool;
        survivorPool = 0;


        for (uint256 i; i < pool.length; i++) {
            survivorBet[i].active = false;
            uint256 thisPickersCount = 0;
            for (uint256 x; x < pool[i].picks.length; x++) {
                bool weekPickCorrect;
                for (uint256 cp; cp < correctPicks[x].length; cp++) {
                    if (correctPicks[x][cp] == pool[i].picks[x]) {
                        weekPickCorrect = true;
                        break;
                    }
                }
                if (weekPickCorrect) {
                    thisPickersCount++;
                    weekPickCorrect = false;
                } else {
                    break;
                }
            }

            if (thisPickersCount > highestRightCount) {
                delete winnersSurvivor;
                winnersSurvivor.push(pool[i]);
                highestRightCount = thisPickersCount;
            } else if (thisPickersCount == highestRightCount) {
                winnersSurvivor.push(pool[i]);
            }
        }

        for (uint256 i; i < winnersSurvivor.length; i++) {
            uint256 payAmount = winningAmount / winnersSurvivor.length;
            address winnersAddress = winnersSurvivor[i].picker;
            for (uint256 x; x < pool.length; x++) {
                if (survivorBet[x].picker == winnersAddress) {
                    survivorBet[x].paidOut = payAmount;
                }
            }
            payable(winnersAddress).transfer(payAmount);
        }
        delete winnersSurvivor;
        return highestRightCount;
    }

    /// Betsize is either 0,1,2
    /// if pulling from survivor, input week = -1 
    function withdrawFromPool() external onlyOwner {
        uint256 winningAmount;

        winningAmount = survivorPool;
        survivorPool = 0;
        
        (bool success, ) = msg.sender.call{value: winningAmount}("");
        require(success, "Withdraw failed.");
    }
}