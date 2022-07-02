/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface Collection{
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract QR{

    address owner;

    constructor(){
        owner = msg.sender;
    }

    struct display{
        uint256 tokenId;
        // string name;
        uint256 startTime;
        uint256 endTime;
        address collectionAddress;
        address senderAddress;
        uint256 rentPer10Mins;
    }

    mapping (uint256 => display) public mapp;

    event Display(uint256 _displayId, display _displayDetails);

    function getMapp(uint256 _no) public view virtual returns (display memory){
        return mapp[_no];
    }   

    function setMapp(uint256 _no, display memory _str) public{
        mapp[_no] = _str;
    }

    function setImage(address _NFTAddress, uint256 _tokenId, uint256 _displayId, uint256 _time) public payable{
        require(mapp[_displayId].endTime < block.timestamp, "The display is occupied");
        Collection thisCollection = Collection(_NFTAddress);
        require(thisCollection.ownerOf(_tokenId) == msg.sender, "Sender is not the owner of NFT");
        mapp[_displayId].tokenId = _tokenId;
        uint256 start = block.timestamp;
        mapp[_displayId].startTime = start;
        mapp[_displayId].endTime = start + _time;
        mapp[_displayId].collectionAddress = _NFTAddress;
        mapp[_displayId].senderAddress = msg.sender;
        emit Display(_displayId, mapp[_displayId]);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function setRent(uint256 _displayId, uint256 _cost) public onlyOwner{
        mapp[_displayId].rentPer10Mins = _cost;
    }
}