/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

pragma solidity ^0.8.4;

contract AASPool {
    struct Poll {
        string question;
        string[] options;
        mapping(address => uint) votes;
        mapping(uint => uint) results;
    }

    Poll[] public polls;

    function createPoll(string memory question, string[] memory options) public {
        Poll storage newPoll = polls.push();
        newPoll.question = question;
        newPoll.options = options;
    }

    function vote(uint pollIndex, uint optionIndex, bytes memory signature) public {
        address signer = recoverSigner(pollIndex, optionIndex, signature);
        require(signer == msg.sender, "Signature is not valid");

        polls[pollIndex].votes[msg.sender] = optionIndex;
        polls[pollIndex].results[optionIndex]++;
    }

    function recoverSigner(uint pollIndex, uint optionIndex, bytes memory signature) public pure returns (address) {
        bytes32 message = prefixed(keccak256(abi.encodePacked(pollIndex, optionIndex)));
        return recoverSigner(message, signature);
    }

    // Helper functions for handling signatures

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}