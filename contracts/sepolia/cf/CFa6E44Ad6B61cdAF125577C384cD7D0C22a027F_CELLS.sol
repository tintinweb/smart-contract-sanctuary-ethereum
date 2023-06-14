/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract CELLS{


    struct cell{
        address to;
        uint256 value;
        bytes32 sHash;
        uint256 timeLock;
        bool completed;
        bool isInit;
        address from;
        bytes32 secret;
    }


    constructor() {}

    mapping(uint256 => cell) public cellsList;
    

    function newCell(uint256 _cellNumber, address _to, bytes32 _sHash, uint256 _timeLock, uint256 value) internal returns (bool){
        require(!(cellsList[_cellNumber].isInit));
        uint256 __timeLock = block.timestamp+_timeLock;
        cellsList[_cellNumber] = cell(_to, value, _sHash, __timeLock, false, true, msg.sender, bytes32(0));
        return true;
    }
    
    function completeCell(uint256 _cellNumber, bytes32 _secret) public returns(bool){
        require(keccak256(abi.encodePacked(_secret)) == cellsList[_cellNumber].sHash);
        require(cellsList[_cellNumber].isInit);
        require(!(cellsList[_cellNumber].completed));
        require(block.timestamp < cellsList[_cellNumber].timeLock);

        cellsList[_cellNumber].secret = _secret;
        cellsList[_cellNumber].completed = true;
        address payable walletAddress = payable(cellsList[_cellNumber].to);
        
        (bool success, ) = walletAddress.call{value: cellsList[_cellNumber].value}("");
        require(success);
        return true;
    }

    function completeByTime(uint256 _cellNumber) public returns(bool){
        require(!(cellsList[_cellNumber].completed));
        require(cellsList[_cellNumber].isInit);
        require(block.timestamp > cellsList[_cellNumber].timeLock);

        cellsList[_cellNumber].completed = true;
        address payable walletAddress = payable(cellsList[_cellNumber].from);

        (bool success, ) = walletAddress.call{value: cellsList[_cellNumber].value}("");
        require(success);
        return true;
    }

    function time() public view returns (uint256){
        return block.timestamp;
    }

    function newFourHoursCell(uint256 _cellNumber, address _to, bytes32 _sHash) public payable returns (bool){
        newCell(_cellNumber, _to, _sHash, 14400, msg.value);
        return true;
    }

    function newTwoHoursCell(uint256 _cellNumber, address _to, bytes32 _sHash) public payable  returns (bool){
        newCell(_cellNumber, _to, _sHash, 7200, msg.value);
        return true;
    }

    function newCustomCell(uint256 _cellNumber, address _to, uint256 timeLock, bytes32 _sHash) public payable returns (bool){
        newCell(_cellNumber, _to, _sHash, timeLock, msg.value);
        return true;
    }

    function newHalfCell(uint256 _cellNumber, address _to, uint256 origTimeLock, bytes32 _sHash) public payable returns (bool){
        newCell(_cellNumber, _to, _sHash, (origTimeLock - block.timestamp) / 2, msg.value);
        return true;
    }
}