//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
WITNESS THE DRAFT.
 __        _____ _____ _   _ _____ ____ ____    _____ _   _ _____   ____  ____      _    _____ _____ 
 \ \      / /_ _|_   _| \ | | ____/ ___/ ___|  |_   _| | | | ____| |  _ \|  _ \    / \  |  ___|_   _|
  \ \ /\ / / | |  | | |  \| |  _| \___ \___ \    | | | |_| |  _|   | | | | |_) |  / _ \ | |_    | |  
   \ V  V /  | |  | | | |\  | |___ ___) |__) |   | | |  _  | |___  | |_| |  _ <  / ___ \|  _|   | |  
    \_/\_/  |___| |_| |_| \_|_____|____/____/    |_| |_| |_|_____| |____/|_| \_\/_/   \_\_|     |_|  
                                                                                                     
Performance art in writing a draft for the book, "Witnesses of Gridlock", the sequel to "Hope Runners of Gridlock".
Each day, the amount of words written + a snippet will be logged.
Thereafter, an NFT (or NFTs) will be created from this data that was logged over the course of 30 days.
Published through Untitled Frontier Labs (https://untitledfrontier.studio). 
By Simon de la Rouviere.
As part of #NaNoWriMo (National Novel Writing Month).

Start: 1667275200 Tue Nov 01 2022 00:00:00 GMT-0400 (Eastern Daylight Time)
End: 1669870800 Thu Dec 01 2022 00:00:00 GMT-0500 (Eastern Standard Time)
*/

contract Witness {
    
    uint256 public start;
    uint256 public end;
    address public owner;
    Day[] public dayss;

    struct Day {
        uint256 logged;
        string day;
        string wordCount;
        string words;
        string extra;
    }

    constructor(address _owner, uint256 _start, uint256 _end) {
        owner = _owner;
        start = _start;
        end = _end;
    }

    function returnDayss() public view returns (Day[] memory) {
        return dayss;
    }

    function witness(string memory _day, string memory _wordCount, string memory _words, string memory _extra) public {
        require(block.timestamp > start, "not ready for witness");
        require(block.timestamp < end, "witnessing has ended");
        require(msg.sender == owner, "not owner");
        Day memory day;

        day.logged = block.timestamp;
        day.day = _day;
        day.wordCount = _wordCount;
        day.words = _words;
        day.extra = _extra;

        dayss.push(day);
    }
}