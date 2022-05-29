// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Spotify {
    struct AlbumStruct {
        address user;
        string idAlbum;
    }

    AlbumStruct[] albums;

    function getAlbums() public view returns (AlbumStruct[] memory){
        return albums;
    }

    function addAlbum(string memory idAlbum, address user) public{
        albums.push(AlbumStruct(user, idAlbum));
    }
}