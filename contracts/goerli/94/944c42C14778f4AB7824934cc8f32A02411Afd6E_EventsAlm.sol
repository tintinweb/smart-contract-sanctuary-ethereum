// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract EventsAlm {
    event Log(bytes32 indexed dealNumber, bytes32 indexed fileMsg, bytes32 indexed filehash);

    function log(bytes32 _dealNumber, bytes32 _fileMsg, bytes32 _filehash) public {
        emit Log(_dealNumber, _fileMsg, _filehash);
    }
}