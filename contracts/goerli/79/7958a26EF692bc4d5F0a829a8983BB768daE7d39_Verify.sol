// File: Verify.sol


pragma solidity ^0.8.0;

// game developer depoloys contract
contract Verify {

    // game developer's account
    address public owner = 0xdD4c825203f97984e7867F11eeCc813A036089D1;

    // player claims price
    function claimPrize(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        // if the signature is signed by the owner
        if (signer == owner) {
            // give player (msg.sender) a prize
            return true;
        }

        return false;
    }
}