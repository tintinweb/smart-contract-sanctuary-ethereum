/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity ^0.8.0;

contract ByteReadWriteContract {
    bytes private data;

    event DataWritten(bytes newData);
    event DataRead(bytes dataRead);

    function writeBytes(bytes memory newData) public {
        data = newData;
        emit DataWritten(newData);
    }

    function readBytes() public view returns (bytes memory) {
        return data;
    }
}