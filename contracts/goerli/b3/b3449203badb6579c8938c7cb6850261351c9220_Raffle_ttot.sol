/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle_ttot {
    enum Status { None, Waiting, Ongoing, End } // 래플상태
    struct RaffleInfo { // 래플정보
        Status status;
        address owner;
        string desc;
        uint endDate;
        uint pickedLength;
        address[] inputList;
        address[] pickedList;
    }

    mapping(string => RaffleInfo) RaffleMap; // 참여코드 => 래플정보

    function setRaffle(string memory _code, string memory _desc, uint _endDate, uint _pickedLength) public {
        require(RaffleMap[_code].status == Status.None, "already exist code");

        RaffleMap[_code].owner = msg.sender;
        RaffleMap[_code].status = Status.Waiting;
        RaffleMap[_code].desc = _desc;
        RaffleMap[_code].endDate = _endDate;
        RaffleMap[_code].pickedLength = _pickedLength;
    }

    function getRaffle(string memory _code) public view returns(RaffleInfo memory) {
        require(RaffleMap[_code].status != Status.None, "code does not exist.");

        return RaffleMap[_code];
    }
    function getRaffleInputList(string memory _code) public view returns(address[] memory) {
        require(RaffleMap[_code].status != Status.None, "code does not exist.");

        return RaffleMap[_code].inputList;
    }
    function getRaffleOutputList(string memory _code) public view returns(address[] memory) {
        require(RaffleMap[_code].status != Status.None, "code does not exist.");

        return RaffleMap[_code].pickedList;
    }

    function setRaffleStart(string memory _code) public {
        require(RaffleMap[_code].owner == msg.sender,"only raffle owner");
        require(RaffleMap[_code].status == Status.Waiting, "already ongoing code");
        // require(RaffleMap[_code].endDate > block.timestamp, "out of date");

        RaffleMap[_code].status = Status.Ongoing;
    }

    function join (string memory _code) external { 
        require(RaffleMap[_code].status == Status.Ongoing, "It's not an ongoing Raffle");
        // require(RaffleMap[_code].endDate > block.timestamp, "out of date");

        RaffleMap[_code].inputList.push(msg.sender);
    }

    function draw(string memory _code) public returns(address[] memory) {
        require(RaffleMap[_code].owner == msg.sender,"only raffle owner");
        require(RaffleMap[_code].status == Status.Ongoing, "It's not an ongoing Raffle");
        // require(RaffleMap[_code].endDate < block.timestamp, "not a draw period");

        RaffleInfo memory info = RaffleMap[_code];
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, info.inputList, info.pickedLength, block.difficulty)));
        
        address[] memory inputList = info.inputList;
        address[] memory pickedList = new address[](info.pickedLength);
        uint index;
        while(index < info.pickedLength){
            pickedList[index] = inputList[random % (info.pickedLength - index)];
            inputList[random % (info.pickedLength - index)] = inputList[info.pickedLength - index - 1];
            index++;
        }

        RaffleMap[_code].pickedList = pickedList;
        RaffleMap[_code].status = Status.End;

        return pickedList;
    }
    

}