// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NotesContract {
    event AddNotes(address recipient, uint notesId);
    event DeleteNotes(uint notesId, bool isDeleted);

    struct Notes {
        uint id;
        address username;
        string taskText;
        bool isDeleted;
    }

    Notes[] private notes;

    // Mapping of TnotesID to the address
    mapping(uint256 => address) notesToOwner;

    function addNotes(string memory taskText, bool isDeleted) external {
        // this function will add notes and will be called from front end
        uint notesId = notes.length;
        notes.push(Notes(notesId, msg.sender, taskText, isDeleted));
        notesToOwner[notesId] = msg.sender;
        emit AddNotes(msg.sender, notesId);
    }

    function getMyNotes() external view returns (Notes[] memory) {
        // this function will get all the tasks belonging to msg.sender
        Notes[] memory temporary = new Notes[](notes.length);
        uint counter = 0;
        for (uint i = 0; i < notes.length; i++) {
            if (notesToOwner[i] == msg.sender && notes[i].isDeleted == false) {
                temporary[counter] = notes[i];
                counter++;
            }
        }

        Notes[] memory result = new Notes[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function deleteNotes(uint notesId, bool isDeleted) external {
        // this function will delete the smart contract
        if (notesToOwner[notesId] == msg.sender) {
            notes[notesId].isDeleted = isDeleted;
            emit DeleteNotes(notesId, isDeleted);
        }
    }
}