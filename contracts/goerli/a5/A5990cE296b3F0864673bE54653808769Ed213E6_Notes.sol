// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
contract Notes{
    struct Note{
         string note;
         address uid;
    }
    Note[] public notes;
    function createNote(string memory _note) public{   
        notes.push(Note(_note,msg.sender));
    }
    function getNotes() public view returns(Note[] memory){   
        return notes;   
    }
}
/*
pragma solidity ^0.8.9;
contract Notes{

    struct Note{
         string note;
    }

    mapping(address => Note) public notes;

    string[] public userNotes ;

    function createNote(string memory note) public{
//map address type to User type
        notes[msg.sender] = Note(note);
    }
    function getNotes() external view returns(string [] memory){
        userNotes = notes[msg.sender].note 
        return userNotes;
    }
}*/