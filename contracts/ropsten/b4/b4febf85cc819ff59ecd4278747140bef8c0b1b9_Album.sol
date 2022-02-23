/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//  SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Album{
    string public artist;
    string public albumTitle;
    uint public tracks;
    string public constant constractAuthor = "Ki On Chan";
    constructor(){
        artist = "Nirvana";
        albumTitle = "NeverMind";
        tracks = 13;
    }

    function getAlbum() public view returns (string memory, string memory, uint){
        return (artist, albumTitle, tracks);
    }

    function setAlbum(string memory _artist, string memory _albumTitle, uint _tracks) public{
        artist = _artist;
        albumTitle = _albumTitle;
        tracks = _tracks;
    }
}