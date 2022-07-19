// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlockTune{
    address public owner;
   
    uint256 songsCounter;
    constructor() {
        songsCounter = 0;
        owner = msg.sender;
    }
  
    struct Song {
        uint256 songID;
        string songName;
        string songImage;
        string musicHash; 
        string artist; 

        address payable songArtist; 
    }
    
    
   
    event SongCreated (
        uint256 songID,
        string songName,
        string songImage,
        string musicHash, 
        string artist, 
        address payable songArtist );
    
    mapping(uint => Song) public songs;
    uint256[] public songIds;
    
    function storeSong(string memory songName,address payable songArtist,string memory musicHash,string memory artist,string memory songImage) public
        {
            Song storage newSong = songs[songsCounter];
            newSong.songName=songName;
            newSong.songArtist=songArtist;
            newSong.musicHash=musicHash;
            newSong.songImage=songImage;
            newSong.artist=artist;
            newSong.songID=songsCounter;
            songIds.push(songsCounter);
            emit SongCreated (
                songsCounter,
                songName,
                songImage,
                musicHash, 
                artist,
                songArtist );
            songsCounter++;
        }

         function getSong(uint _songID)public view returns(Song memory){
                return songs[_songID];
        }

        // Method to get only your Tweets
    function getMySong() external view returns (Song[] memory) {
        Song[] memory temporary = new Song[](songIds.length);
        uint counter = 0;
        for(uint i=0; i< songIds.length; i++) {
            if(songs[i].songArtist == msg.sender) 
            {
                temporary[counter] = songs[i];
                counter++;
            }
        }

        Song[] memory result = new Song[](counter);
        for(uint i=0; i<counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

            function getCount()external view returns (uint)
            {
                return songIds.length;

            }

            // Method to get only your Tweets
function getOtherSong() external view returns (Song[] memory) {
        Song[] memory temporary = new Song[](songIds.length);
        uint counter = 0;
        for(uint i=0; i< songIds.length; i++) {
            if(songs[i].songArtist != msg.sender) 
            {
                temporary[counter] = songs[i];
                counter++;
            }
        }
        
        Song[] memory result = new Song[](counter);
        for(uint i=0; i<counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }   
}