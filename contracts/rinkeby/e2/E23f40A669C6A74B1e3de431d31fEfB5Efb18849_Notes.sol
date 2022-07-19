// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error Notes__NotAuthorizedToDelete();

contract Notes {
    /* State Variables */

    /* Struct */
    struct Note {
        uint256 noteId;
        uint256 createdAt;
        bool isDeleted;
        string title;
        string description;
    }

    Note[] public notes;

    /* Mappings */
    mapping(uint256 => address) public noteId; // which noteId belongs to which address or user;

    /* Events */
    event AddNote(address recipient, uint256 _noteId);
    event DeleteNote(uint256 _noteId, bool isDeleted);

    /* Get/Pure Functions */

    function getNotes() public view returns (Note[] memory) {
        Note[] memory tempNotes = new Note[](notes.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (noteId[i] == msg.sender && notes[i].isDeleted == false) {
                tempNotes[counter] = notes[i];
                counter++;
            }
        }
        Note[] memory result = new Note[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = tempNotes[i];
        }

        return result;
    }

    /* Logics */

    // AddNote
    function addNote(
        bool _isDeleted,
        string memory _title,
        string memory _description
    ) public {
        address recipient = msg.sender;
        uint256 _noteId = notes.length;

        notes.push(
            Note(_noteId, block.timestamp, _isDeleted, _title, _description)
        );
        noteId[_noteId] = recipient;

        emit AddNote(recipient, _noteId);
    }

    // DeleteNote
    function deleteNote(uint256 _noteId, bool _delete) public {
        if (noteId[_noteId] != msg.sender) {
            revert Notes__NotAuthorizedToDelete();
        }
        notes[_noteId].isDeleted = _delete;
        emit DeleteNote(_noteId, _delete);
    }
}