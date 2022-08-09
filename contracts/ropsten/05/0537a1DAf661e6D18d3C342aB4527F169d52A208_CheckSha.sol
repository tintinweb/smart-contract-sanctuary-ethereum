// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

contract CheckSha {
    function checkShaOnBytes32(bytes32 _bytes) public view returns (bytes32) {
        return sha256(abi.encodePacked(_bytes));
    }

    function checkShaOnString(string memory _string)
        public
        view
        returns (bytes32)
    {
        return sha256(abi.encodePacked(_string));
    }
}