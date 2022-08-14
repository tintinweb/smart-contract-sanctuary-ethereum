/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bible {
    struct BibleVerse {
        string BIBLE_VERSE; //string containing the full bible verse
        bool BIBLE_VERSE_LOCKED; // true value meaning it is locked and cannot be edited
    }
    // identifier for bible verses are in the format: BookNumber-ChapterNumber-verseNumber-TranslationID
    mapping(string=>BibleVerse) public BIBLE_VERSES;
    // the original owner of the smart contract 
    address public immutable SUPER_ADMIN;
    // maapping of all admins that returns true if given address is an admin
    mapping(address=>bool) public ADMINS;

    constructor() {
        SUPER_ADMIN = msg.sender;
        ADMINS[msg.sender] = true;
    }

    // Function to add or remove admin. Can only be done by super admin
    function addNewAdmin(address newAdminAddress, bool shouldSetAsAdmin) public returns (bool) {
        if(SUPER_ADMIN == msg.sender) ADMINS[newAdminAddress] = shouldSetAsAdmin;
        return ADMINS[newAdminAddress];
    }

    // Function to set OR update LOCK on existing bible verse based on verse identifier
    function lockBibleVerse(string memory verseIdentifier, bool shouldLockVerse) public returns (bool) {
        if(ADMINS[msg.sender]) BIBLE_VERSES[verseIdentifier].BIBLE_VERSE_LOCKED = shouldLockVerse;
        return BIBLE_VERSES[verseIdentifier].BIBLE_VERSE_LOCKED;
    }

    // Function to set OR update an existing bible verse based on verse identifier
    function updateBibleVerse(string memory verseIdentifier, string memory verse) public returns (string memory) {
        if(!BIBLE_VERSES[verseIdentifier].BIBLE_VERSE_LOCKED) BIBLE_VERSES[verseIdentifier].BIBLE_VERSE = verse;
        return BIBLE_VERSES[verseIdentifier].BIBLE_VERSE;
    }
}