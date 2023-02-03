// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract DEducation {
    struct Transcript {
        string Hashcode;
        string Semester;
        string Subject;
    }

    event AddNewTranscript(
        address _studentAddress,
        string _hashcode,
        string _semester,
        string _subject
    );

    mapping(address => mapping(address => Transcript[]))
        public TranscriptUploaded;

    function addNewTranscript(
        address _studentAddress,
        string memory _hashcode,
        string memory _semester,
        string memory _subject
    ) public {
        TranscriptUploaded[msg.sender][_studentAddress].push(
            Transcript(_hashcode, _semester, _subject)
        );
        emit AddNewTranscript(_studentAddress, _hashcode, _semester, _subject);
    }

    function isCorrectTranscript(
        address _teacherAddress,
        address _studentAddress,
        string memory _hashcode,
        string memory _semester,
        string memory _subject
    ) public returns (bool) {
        uint256 amountOfTranscriptUploaded = TranscriptUploaded[
            _teacherAddress
        ][_studentAddress].length;
        for (uint256 i = 0; i < amountOfTranscriptUploaded; i++) {
            Transcript memory temporaryTranscript = TranscriptUploaded[
                _teacherAddress
            ][_studentAddress][i];
            if (
                keccak256(
                    abi.encodePacked(
                        temporaryTranscript.Hashcode,
                        temporaryTranscript.Semester,
                        temporaryTranscript.Subject
                    )
                ) == keccak256(abi.encodePacked(_hashcode, _semester, _subject))
            ) {
                return true;
            }
        }
        return false;
    }
}