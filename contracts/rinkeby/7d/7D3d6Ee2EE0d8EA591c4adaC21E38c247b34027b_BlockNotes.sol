// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BlockNotes {

	// Properties

	address owner;
	mapping(uint256 => string) notes;
	uint256[] noteIds;
	uint256 noteCounter = 0;

	// Init

	constructor() {
        owner = msg.sender;
    }

    // Modifiers

    modifier onlyOwner {
        require(msg.sender == owner, "you're not the owner");
        _; // _; will be substituted with your code
    }

	// Interface

	function putNote(string memory _note) onlyOwner public returns(uint256) {
		uint256 _noteId = noteCounter + 1;
		noteCounter = _noteId;
		notes[_noteId] = _note;
		noteIds.push(_noteId);
		return _noteId;
	}

	function postNote(uint256 _noteId, string memory _note) onlyOwner public returns(uint256) {
		notes[_noteId] = _note;
		return _noteId;
	}

	function getNote(uint256 _noteId) onlyOwner public view returns(string memory) {
		require(noteCounter >= _noteId);
		return notes[_noteId];
	}

	function delNote(uint256 _noteId) onlyOwner public {
		require(noteCounter >= _noteId);
		delete notes[_noteId];
	}

	function getNotes() onlyOwner public view returns(uint256[] memory) {
		return noteIds;
	}
}