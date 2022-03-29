// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    struct participant {
        uint256 numberOfEntries;
    }

    string private nameLottery;
    address private owner;
    address payable[] private arrayParticipants;
    mapping(address => participant) private mapParticipants;
    uint256 private startDate;
    uint256 private endDate;
    uint256 private pickedDate;
    uint256 private priceOfEntrance;
    bool private hasEnded = false;
    bool private ownerWithdrawedCommission = false;
    uint256 private indexFirstPrize;
    uint256 private indexSecondPrize;
    uint256 private maxNumberOfEntries;

    constructor(
        address _owner,
        string memory _nameLottery,
        uint256 _endDate,
        uint256 _priceOfEntrance,
        uint256 _maxNumberOfEntries
    ) {
        nameLottery = _nameLottery;
        maxNumberOfEntries = _maxNumberOfEntries;
        owner = _owner;
        endDate = _endDate;
        startDate = block.timestamp;
        priceOfEntrance = _priceOfEntrance * 1 wei;
    }

    function getLotteryInfo()
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            nameLottery,
            owner,
            startDate,
            endDate,
            pickedDate,
            priceOfEntrance,
            maxNumberOfEntries,
            hasEnded
        );
    }

    function enter() public payable {
        require(msg.value == priceOfEntrance, "Incorrect amount!");
        require(
            mapParticipants[msg.sender].numberOfEntries <= maxNumberOfEntries,
            "To many entries"
        );

        if (mapParticipants[msg.sender].numberOfEntries == 0) {
            mapParticipants[msg.sender] = participant(1);
        } else {
            mapParticipants[msg.sender].numberOfEntries += 1;
        }
        arrayParticipants.push(payable(msg.sender));
    }

    function getRandomNumber(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        owner,
                        block.timestamp,
                        block.number,
                        block.difficulty,
                        number
                    )
                )
            );
    }

    function pickWinner() public onlyowner {
        require(address(this).balance > 0, "Balance is 0");
        require(hasEnded == false, "The lottery has ended!");

        indexFirstPrize = getRandomNumber(1) % arrayParticipants.length;
        indexSecondPrize = getRandomNumber(2) % arrayParticipants.length;

        arrayParticipants[indexFirstPrize].transfer(
            (address(this).balance / 100) * 70
        );
        arrayParticipants[indexSecondPrize].transfer(
            (address(this).balance / 100) * 83
        );

        hasEnded = true;

        pickedDate = block.timestamp;
    }

    function withdrawCommission() public onlyowner {
        require(hasEnded == true, "Please pick the winner first!");
        require(
            ownerWithdrawedCommission == false,
            "You received the commsision"
        );
        address payable copy;
        copy = payable(owner);
        copy.transfer(address(this).balance);
        ownerWithdrawedCommission = true;
    }

    function getWinner1() public view returns (address) {
        require(hasEnded == true, "The lottery hasn't ended!");
        return arrayParticipants[indexFirstPrize];
    }

    function getWinner2() public view returns (address) {
        require(hasEnded == true, "The lottery hasn't end!");
        return arrayParticipants[indexSecondPrize];
    }

    function getPlayers() public view returns (address payable[] memory) {
        return arrayParticipants;
    }

    function getNumberOfEntriesForUser(address player)
        public
        view
        returns (uint256)
    {
        return mapParticipants[player].numberOfEntries;
    }

    function getOwnerWithdrawedCommission()
        public
        view
        onlyowner
        returns (bool)
    {
        return ownerWithdrawedCommission;
    }

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }
}