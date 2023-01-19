// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This contract generates a random number between 1 and 100000

contract RandomNumberGenerator {
    event FinishedOneFight(address winner, uint256 roundnum);

    struct Roominfo {
        bool status;
        address[] fighters;
        uint256[] randoms;
    }

    mapping(address => uint256) public reward;
    mapping(uint256 => Roominfo) public roominfo;

    uint256 public firstrandom;
    uint256 public secondrandom;
    uint256 public maxroomnum;

    function bet(uint256 _roomnum) public {
        if(_roomnum > maxroomnum) {
            maxroomnum = _roomnum;
            roominfo[_roomnum] = Roominfo({
                status: false,
                randoms: new uint256[](0),
                fighters: new address[](0)
            });
            firstrandom = 0;
            secondrandom = 0;
        }
        require(roominfo[_roomnum].status != true, "This betting game is already finished!");
        require(roominfo[_roomnum].fighters.length != 2, "There are already enough players!");
        roominfo[_roomnum].fighters.push(msg.sender);
        firstrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        require(roominfo[_roomnum].fighters.length == 2, "There aren't enough players!");
        secondrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        reward[roominfo[_roomnum].fighters[0]] = 0;
        reward[roominfo[_roomnum].fighters[1]] = 0;
        if(firstrandom > secondrandom) {
            reward[roominfo[_roomnum].fighters[0]] += 20;
        } else {
            reward[roominfo[_roomnum].fighters[1]] += 20;
        }
        roominfo[_roomnum].status = true;
        emit FinishedOneFight(roominfo[_roomnum].fighters[0], _roomnum);
    }
}