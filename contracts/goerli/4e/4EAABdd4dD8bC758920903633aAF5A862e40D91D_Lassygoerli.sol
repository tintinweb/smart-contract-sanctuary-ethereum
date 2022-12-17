/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Lassygoerli {
    
    // create a variable called winningTicketHolder that is a uint256 that is accessible by any part of this contract, and retrievable by anyone who calls this contract
    address public tonightsWinningTicketHolder;

    // create a public array of objects called "Lassywinners" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Lassywinner[] public Lassywinners;
    
    // create a public variable called noobAddress that is an address and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    address public noobAddress;

    // ensure that Lassywinner[] has been properly defined and declared as a public array of objects
    struct Lassywinner {
        address winningAddress;
        uint256 timestamp;
        uint256 winningNumber;
        uint256 weiWon;
        uint256 blockHashThisRound;
        uint256 ticketsSoldThisRound;
    }

    // variable that represents the index of the winner in the Lassywinners array as calculated by the random function
    uint256 public tonightsWinningNumber;

        // create an arrary of objects called "alltickets" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Allticket[] public alltickets;

    // ensure that Allticket[] has been properly defined and declared as a public array of objects
    struct Allticket {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    // create an arrary of objects called "normals" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Normal[] public normals;

    // ensure that Normal[] has been properly defined and declared as a public array of objects
    struct Normal {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    // create an arrary of objects called "bigs" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Big[] public bigs;

    // ensure that Big[] has been properly defined and declared as a public array of objects
    struct Big {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    // create an arrary of objects called "biggests" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Biggest[] public biggests;

    // ensure that Biggest[] has been properly defined and declared as a public array of objects
    struct Biggest {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    // ensure that noobsLength is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public noobsLength;

    // ensure that commonersLength is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public commonersLength;

    // ensure that biggerballsLength is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public biggerballsLength;

    // ensure that allticketsLength is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public allticketsLength;

    // ensure that lastTimeUpdated is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public lastTimeUpdated;

    // ensure that latestBlockHashAsUint is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public latestBlockHashAsUint;

    receive() external payable {}

    // create an ERC-20 token called "Lassy" fd

    // function that gets the length of the normals array
    function totalTicketsSoldThisRound() external view returns (uint256) {
        return alltickets.length;
    }

    // function that gets the length of the bigs array
    function totalCommonerTicketsSoldThisRound() external view returns (uint256) {
        return bigs.length;
    }

    // function that gets the length of the biggests array
    function totalBiggerBallsTicketsSoldThisRound() external view returns (uint256) {
        return biggests.length;
    }

    // function that gets the length of the Lassywinners array
    function totalLassywinners() external view returns (uint256) {
        return Lassywinners.length;
    }
    
    // function that returns the number of times an address has bought a ticket
    function numberOfTicketsBoughtByAddress(address _address) external view returns (uint256) {
        uint256 numberOfTicketsBought = 0;
        for (uint256 i = 0; i < alltickets.length; i++) {
            if (alltickets[i].addressToSendEthTo == _address) {
                numberOfTicketsBought++;
            }
        }
        return numberOfTicketsBought;
    }

    // function that enables this contract to receive 0.001 eth from any address, and then records the address that sent it in an array of objects called "normals" containing: the address, and the timestamp of the transaction
    function buyNormalTicket() external payable {
        require(msg.value == 0.001 ether, "You need to send exactly 0.001 eth");
        normals.push(Normal(msg.sender, block.timestamp));
        // add the address that sent the transaction to the alltickets array, but add it 1 time
        alltickets.push(Allticket(msg.sender, block.timestamp));
    }

    // function that enables this contract to receive 0.002 eth from any address, and then records the address that sent it in an array of objects called "normals" containing: the address, and the timestamp of the transaction
    function buyBigTicket() external payable {
        require(msg.value == 0.002 ether, "You need to send exactly 0.002 eth");
        // add the address that sent the transaction to the alltickets array, but add it 13 times
        for (uint256 i = 0; i < 13; i++) {
            alltickets.push(Allticket(msg.sender, block.timestamp));
        }
        // add the address that sent the transaction to the bigs array, but add it 1 time
        bigs.push(Big(msg.sender, block.timestamp));
    }

    // function that enables this contract to receive 0.003 eth from any address, and then records the address that sent it in an array of objects called "normals" containing: the address, and the timestamp of the transaction
    function buyBiggestTicket() external payable {
        require(msg.value == 0.003 ether, "You need to send exactly 0.003 eth");
        // add the address that sent the transaction to the alltickets array, but add it 165 times
        for (uint256 i = 0; i < 165; i++) {
            alltickets.push(Allticket(msg.sender, block.timestamp));
        }
        // add the address that sent the transaction to the bigBalls array, but add it 1 time
        biggests.push(Biggest(msg.sender, block.timestamp));
    }


    // function that allows anyone to query any address by index in the alltickets array, and returns the address and the timestamp of the transaction
    function getAllticket(uint256 index) external view returns (address, uint256) {
        return (alltickets[index].addressToSendEthTo, alltickets[index].timestamp);
    }

    // function that allows anyone to query any address by index in the normals array, and returns the address and the timestamp of the transaction
    function getNoob(uint256 index) external view returns (address, uint256) {
        return (normals[index].addressToSendEthTo, normals[index].timestamp);
    }

    // function that gets normals array length
    function getNoobLength() external view returns (uint256) {
        return normals.length;
    }

    // function that gets bigs array length
    function getCommonerLength() external view returns (uint256) {
        return bigs.length;
    }

    // function that gets biggests array length
    function getBiggerBallsLength() external view returns (uint256) {
        return biggests.length;
    }

    // function that gets alltickets array length
    function getAllticketLength() external view returns (uint256) {
        return alltickets.length;
    }

    // function that allows anyone to query any address by index in the bigs array, and returns the address and the timestamp of the transaction
    function getCommoner(uint256 index) external view returns (address, uint256) {
        return (bigs[index].addressToSendEthTo, bigs[index].timestamp);
    }

    // function that allows anyone to query any address by index in the biggests array, and returns the address and the timestamp of the transaction
    function getBiggerBalls(uint256 index) external view returns (address, uint256) {
        return (biggests[index].addressToSendEthTo, biggests[index].timestamp);
    }

    // function that allows anyone to query any address by index in the Lassywinners array, and returns the address and the timestamp of the transaction
    function getLassywinner(uint256 index) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (Lassywinners[index].winningAddress, Lassywinners[index].timestamp, Lassywinners[index].winningNumber, Lassywinners[index].weiWon, Lassywinners[index].blockHashThisRound, Lassywinners[index].ticketsSoldThisRound);
    }

    // function that allows anyone to return the entire normals array
    function getAllNoobs() external view returns (Normal[] memory) {
        return normals;
    }

    // function that allows anyone to return the entire bigs array
    function getAllCommoners() external view returns (Big[] memory) {
        return bigs;
    }

    // function that allows anyone to return the entire biggests array
    function getAllBiggerBalls() external view returns (Biggest[] memory) {
        return biggests;
    }

    // function that returns all the Lassywinners in the Lassywinners array
    function getAllLassywinners() external view returns (Lassywinner[] memory) {
        return Lassywinners;
    }

    // choose winner using blockhash, block.timestamp, and the length of the normals array as inputs to a keccak256 hash function, and then use the modulus operator to get a random number between 0 and the length of the normals array, and then use that number as an index to get the address of the winning Normal
    function chooseWinner() external {
        allticketsLength = alltickets.length;
        latestBlockHashAsUint = uint256(blockhash(block.number - 1));
        tonightsWinningNumber = uint(keccak256(abi.encodePacked(latestBlockHashAsUint, block.timestamp, allticketsLength))) % allticketsLength;
        tonightsWinningTicketHolder = alltickets[tonightsWinningNumber].addressToSendEthTo;
        lastTimeUpdated = block.timestamp;
        // update the Lassywinner array with the winning address, the timestamp of the transaction, and the winning number, and the amount of eth won
        Lassywinners.push(Lassywinner(tonightsWinningTicketHolder, block.timestamp, tonightsWinningNumber, address(this).balance * 95 / 100, latestBlockHashAsUint, allticketsLength));        
        // send 95% of the contract balance to the winning address
        payable(tonightsWinningTicketHolder).transfer(address(this).balance * 95 / 100);
        // send 5% of the contract balance to the contract owner: 0x3eEc626fDf8C827b5c449D46c286879Fb98a6A12
        payable(0x22f018a80d7aBE622C59A9b8106a865a37B0639F).transfer(address(this).balance);
        // reset the normals array to empty, so that the next time the contract is executed, it will start with a fresh array of normals
        delete normals;
        delete bigs;
        delete biggests;
        delete alltickets;
        delete tonightsWinningNumber;
        delete noobsLength;
        delete allticketsLength;
        delete tonightsWinningTicketHolder;
        delete latestBlockHashAsUint;

    }
}