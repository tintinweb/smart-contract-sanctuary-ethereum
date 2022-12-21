/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Lassy {

    uint256 public timelastwinnerwaschosen = 0;
    
    address public tonightsWinningTicketHolder;

    Lassywinner[] public Lassywinners;
    
    address public normalAddress;

    struct Lassywinner {
        address winningAddress;
        uint256 timestamp;
        uint256 winningNumber;
        uint256 weiWon;
        uint256 blockHashThisRound;
        uint256 ticketsSoldThisRound;
    }

    uint256 public tonightsWinningNumber;

    Allticket[] public alltickets;

    struct Allticket {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    Normal[] public normals;

    struct Normal {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    Big[] public bigs;

    struct Big {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    Biggest[] public biggests;

    struct Biggest {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    uint256 public normalsLength;

    uint256 public bigsLength;

    uint256 public biggestsLengths;

    uint256 public allticketsLength;

    uint256 public latestBlockHashAsUint;

    receive() external payable {}

    function totalTicketsSoldThisRound() external view returns (uint256) {
        return alltickets.length;
    }

    function totalBigTicketsSoldThisRound() external view returns (uint256) {
        return bigs.length;
    }

    function totalBiggestTicketsSoldThisRound() external view returns (uint256) {
        return biggests.length;
    }

    function totalLassywinners() external view returns (uint256) {
        return Lassywinners.length;
    }
    
    function buyNormalTicket() external payable {
        require(msg.value == 0.01 ether, "You need to send exactly 0.01 eth to buy a normal ticket");
        normals.push(Normal(msg.sender, block.timestamp));
        alltickets.push(Allticket(msg.sender, block.timestamp));
    }

    function buyBigTicket() external payable {
        require(msg.value == 0.1 ether, "You need to send exactly 0.1 eth to buy a big ticket");
        for (uint256 i = 0; i < 15; i++) {
            alltickets.push(Allticket(msg.sender, block.timestamp));
        }
        bigs.push(Big(msg.sender, block.timestamp));
    }

    function buyBiggestTicket() external payable {
        require(msg.value == 1 ether, "You need to send exactly 1 eth to buy a biggest ticket");
        for (uint256 i = 0; i < 200; i++) {
            alltickets.push(Allticket(msg.sender, block.timestamp));
        }
        biggests.push(Biggest(msg.sender, block.timestamp));
    }

    function getAllticket(uint256 index) external view returns (address, uint256) {
        return (alltickets[index].addressToSendEthTo, alltickets[index].timestamp);
    }

    function getNormals(uint256 index) external view returns (address, uint256) {
        return (normals[index].addressToSendEthTo, normals[index].timestamp);
    }

    function getNormalsLength() external view returns (uint256) {
        return normals.length;
    }

    function getBigLength() external view returns (uint256) {
        return bigs.length;
    }

    function getbiggestsLengths() external view returns (uint256) {
        return biggests.length;
    }

    function getBig(uint256 index) external view returns (address, uint256) {
        return (bigs[index].addressToSendEthTo, bigs[index].timestamp);
    }

    function getBiggest(uint256 index) external view returns (address, uint256) {
        return (biggests[index].addressToSendEthTo, biggests[index].timestamp);
    }

    function getLassywinner(uint256 index) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (Lassywinners[index].winningAddress, Lassywinners[index].timestamp, Lassywinners[index].winningNumber, Lassywinners[index].weiWon, Lassywinners[index].blockHashThisRound, Lassywinners[index].ticketsSoldThisRound);
    }

    function getAllNormals() external view returns (Normal[] memory) {
        return normals;
    }

    function getAllBigs() external view returns (Big[] memory) {
        return bigs;
    }

    function getAllBiggests() external view returns (Biggest[] memory) {
        return biggests;
    }

    function getAlltickets() external view returns (Allticket[] memory) {
        return alltickets;
    }

    function getAllLassywinners() external view returns (Lassywinner[] memory) {
        return Lassywinners;
    }

    function whenCanNextWinnerBeChosen() external view returns (uint256) {
        return timelastwinnerwaschosen + 24 hours;
    }

    function howManyNormalTicketsHasThisAddressBought(address _address) external view returns (uint256) {
        uint256 numberOfNormalTicketsBought = 0;
        for (uint256 i = 0; i < normals.length; i++) {
            if (normals[i].addressToSendEthTo == _address) {
                numberOfNormalTicketsBought++;
            }
        }
        return numberOfNormalTicketsBought;
    }

    function howManyBigTicketsHasThisAddressBought(address _address) external view returns (uint256) {
        uint256 numberOfBigTicketsBought = 0;
        for (uint256 i = 0; i < bigs.length; i++) {
            if (bigs[i].addressToSendEthTo == _address) {
                numberOfBigTicketsBought++;
            }
        }
        return numberOfBigTicketsBought;
    }

    function howManyBiggestTicketsHasThisAddressBought(address _address) external view returns (uint256) {
        uint256 numberOfBiggestTicketsBought = 0;
        for (uint256 i = 0; i < biggests.length; i++) {
            if (biggests[i].addressToSendEthTo == _address) {
                numberOfBiggestTicketsBought++;
            }
        }
        return numberOfBiggestTicketsBought;
    }

    function howManyTicketsHasThisAddressBoughtInTotal(address _address) external view returns (uint256) {
        uint256 numberOfTicketsBought = 0;
        for (uint256 i = 0; i < alltickets.length; i++) {
            if (alltickets[i].addressToSendEthTo == _address) {
                numberOfTicketsBought++;
            }
        }
        return numberOfTicketsBought;
    }

    function getLassyPotBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getLassywinnerByIndex(uint256 index) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (Lassywinners[index].winningAddress, Lassywinners[index].timestamp, Lassywinners[index].winningNumber, Lassywinners[index].weiWon, Lassywinners[index].blockHashThisRound, Lassywinners[index].ticketsSoldThisRound);
    }

    function getLassywinnerByAddress(address _address) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        for (uint256 i = 0; i < Lassywinners.length; i++) {
            if (Lassywinners[i].winningAddress == _address) {
                return (Lassywinners[i].winningAddress, Lassywinners[i].timestamp, Lassywinners[i].winningNumber, Lassywinners[i].weiWon, Lassywinners[i].blockHashThisRound, Lassywinners[i].ticketsSoldThisRound);
            }
        }
        return (address(0), 0, 0, 0, 0, 0);
    }

    function getLassywinnerByTimestamp(uint256 _timestamp) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        for (uint256 i = 0; i < Lassywinners.length; i++) {
            if (Lassywinners[i].timestamp == _timestamp) {
                return (Lassywinners[i].winningAddress, Lassywinners[i].timestamp, Lassywinners[i].winningNumber, Lassywinners[i].weiWon, Lassywinners[i].blockHashThisRound, Lassywinners[i].ticketsSoldThisRound);
            }
        }
        return (address(0), 0, 0, 0, 0, 0);
    }

    function getLassywinnerByWeiWon(uint256 _weiWon) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        for (uint256 i = 0; i < Lassywinners.length; i++) {
            if (Lassywinners[i].weiWon == _weiWon) {
                return (Lassywinners[i].winningAddress, Lassywinners[i].timestamp, Lassywinners[i].winningNumber, Lassywinners[i].weiWon, Lassywinners[i].blockHashThisRound, Lassywinners[i].ticketsSoldThisRound);
            }
        }
        return (address(0), 0, 0, 0, 0, 0);
    }

    function getTicketNumbersByAddress(address _address) external view returns (uint256) {
        for (uint256 i = 0; i < alltickets.length; i++) {
            if (alltickets[i].addressToSendEthTo == _address) {
                return i;
            }
        }
        return 0;
    }

    function chooseWinner() external {
        require(block.timestamp > timelastwinnerwaschosen + 24 hours || timelastwinnerwaschosen == 0, "You can only choose a winner once every 24 hours");
        allticketsLength = alltickets.length;
        latestBlockHashAsUint = uint256(blockhash(block.number - 1));
        tonightsWinningNumber = uint(keccak256(abi.encodePacked(latestBlockHashAsUint, block.timestamp, allticketsLength))) % allticketsLength;
        tonightsWinningTicketHolder = alltickets[tonightsWinningNumber].addressToSendEthTo;
        timelastwinnerwaschosen = block.timestamp;
        Lassywinners.push(Lassywinner(tonightsWinningTicketHolder, block.timestamp, tonightsWinningNumber, address(this).balance * 95 / 100, latestBlockHashAsUint, allticketsLength));        
        payable(tonightsWinningTicketHolder).transfer(address(this).balance * 95 / 100);
        payable(0x4B90aFbE1B4574ECA1C78a25a62E590b2589f180).transfer(address(this).balance);
        delete normals;
        delete bigs;
        delete biggests;
        delete alltickets;
        delete tonightsWinningNumber;
        delete normalsLength;
        delete allticketsLength;
        delete tonightsWinningTicketHolder;
        delete latestBlockHashAsUint;
    }
}