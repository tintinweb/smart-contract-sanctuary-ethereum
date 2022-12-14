/**
 *Submitted for verification at Etherscan.io on 2022-12-13
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
        uint256 etherWon;
        uint256 latestBlockHashAsUinty;
        uint256 nbylength;
    }

    // variable that represents the index of the winner in the Lassywinners array as calculated by the random function
    uint256 public tonightsWinningNumber;

    // create an arrary of objects called "noobs" that contains the address of the winner, and the timestamp of when they won, and is accessible by any part of this contract, and retrievable by anyone who calls this contract
    Noob[] public noobs;

    // ensure that Noob[] has been properly defined and declared as a public array of objects
    struct Noob {
        address addressToSendEthTo;
        uint256 timestamp;
    }

    // ensure that noobsLength is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public noobsLength;

    // ensure that lastTimeUpdated is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public lastTimeUpdated;

    // ensure that latestBlockHashAsUint is properly defined and declared as a public variable of type uint256 and begins with a value of 0
    uint256 public latestBlockHashAsUint;

    //ensure that latestBlockHashAsBytes is properly defined and declared as a public variable of type bytes32 and begins with a value of 0
    bytes32 public latestBlockHashAsBytes;

    // function that gets the length of the noobs array
    function totalTicketsSold() external view returns (uint256) {
        return noobs.length;
    }

    // function that returns the number of times an address has bought a ticket
    function numberOfTicketsBoughtByAddress(address _address) external view returns (uint256) {
        uint256 numberOfTicketsBought = 0;
        for (uint256 i = 0; i < noobs.length; i++) {
            if (noobs[i].addressToSendEthTo == _address) {
                numberOfTicketsBought++;
            }
        }
        return numberOfTicketsBought;
    }

    receive() external payable {}

    // function that enables this contract to receive 0.001 eth from any address, and then records the address that sent it in an array of objects called "noobs" containing: the address, and the timestamp of the transaction
    function buyNoobTicket() external payable {
        require(msg.value == 0.001 ether, "You need to send exactly 0.001 eth");
        noobs.push(Noob(msg.sender, block.timestamp));
    }

    // function that allows anyone to query any address by index in the noobs array, and returns the address and the timestamp of the transaction
    function getNoob(uint256 index) external view returns (address, uint256) {
        return (noobs[index].addressToSendEthTo, noobs[index].timestamp);
    }

    // function that allows anyone to query any address by index in the Lassywinners array, and returns the address and the timestamp of the transaction
    function getLassywinner(uint256 index) external view returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (Lassywinners[index].winningAddress, Lassywinners[index].timestamp, Lassywinners[index].winningNumber, Lassywinners[index].etherWon, Lassywinners[index].latestBlockHashAsUinty, Lassywinners[index].nbylength);
    }

    // function that allows anyone to return the entire noobs array
    function getAllNoobs() external view returns (Noob[] memory) {
        return noobs;
    }

    // function that returns all the Lassywinners in the Lassywinners array
    function getAllLassywinners() external view returns (Lassywinner[] memory) {
        return Lassywinners;
    }

    // update the winningTicketHolder variable by calling random function, and then setting the winningTicketHolder variable to the address of the noob at the index returned by random
    function chooseWinner() external {
        // call getNoobsLength() to get the length of the noobs array
        noobsLength = noobs.length;
        tonightsWinningNumber = uint(keccak256(abi.encodePacked(block.timestamp, noobsLength))) % noobsLength;
        tonightsWinningTicketHolder = noobs[tonightsWinningNumber].addressToSendEthTo;
        lastTimeUpdated = block.timestamp;
        // update the Lassywinner array with the winning address, the timestamp of the transaction, and the winning number, and the amount of eth won
        Lassywinners.push(Lassywinner(tonightsWinningTicketHolder, block.timestamp, tonightsWinningNumber, address(this).balance * 95 / 100, latestBlockHashAsUint, noobsLength));        
        // send 95% of the contract balance to the winning address
        payable(tonightsWinningTicketHolder).transfer(address(this).balance * 95 / 100);
        // send 5% of the contract balance to the contract owner: 0x3eEc626fDf8C827b5c449D46c286879Fb98a6A12
        payable(0x3eEc626fDf8C827b5c449D46c286879Fb98a6A12).transfer(address(this).balance);
        // reset the noobs array to empty, so that the next time the contract is executed, it will start with a fresh array of noobs
        delete noobs;
        delete tonightsWinningNumber;
        delete noobsLength;
        delete tonightsWinningTicketHolder;
    }


    // choose winner using blockhash, block.timestamp, and the length of the noobs array as inputs to a keccak256 hash function, and then use the modulus operator to get a random number between 0 and the length of the noobs array, and then use that number as an index to get the address of the winning noob
    function chooseWinnerUsingBlockhash() external {
        noobsLength = noobs.length;
        latestBlockHashAsUint = uint256(blockhash(block.number - 1));
        tonightsWinningNumber = uint(keccak256(abi.encodePacked(latestBlockHashAsUint, block.timestamp, noobsLength))) % noobsLength;
        tonightsWinningTicketHolder = noobs[tonightsWinningNumber].addressToSendEthTo;
        lastTimeUpdated = block.timestamp;
        // update the Lassywinner array with the winning address, the timestamp of the transaction, and the winning number, and the amount of eth won
        Lassywinners.push(Lassywinner(tonightsWinningTicketHolder, block.timestamp, tonightsWinningNumber, address(this).balance * 95 / 100, latestBlockHashAsUint, noobsLength));        
        // send 95% of the contract balance to the winning address
        payable(tonightsWinningTicketHolder).transfer(address(this).balance * 95 / 100);
        // send 5% of the contract balance to the contract owner: 0x3eEc626fDf8C827b5c449D46c286879Fb98a6A12
        payable(0x3eEc626fDf8C827b5c449D46c286879Fb98a6A12).transfer(address(this).balance);
        // reset the noobs array to empty, so that the next time the contract is executed, it will start with a fresh array of noobs
        delete noobs;
        delete tonightsWinningNumber;
        delete noobsLength;
        delete tonightsWinningTicketHolder;
        delete latestBlockHashAsUint;
        delete latestBlockHashAsBytes;
    }


}