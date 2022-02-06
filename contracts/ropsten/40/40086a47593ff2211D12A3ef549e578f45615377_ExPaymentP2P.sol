/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract ExPaymentP2P {
    address payable public sender;
    address payable public receiver;

    uint256 public expireAt;
    

    constructor(uint256 expiration, address payable _receiver) payable {
        require( expiration > 0);
        
        sender = payable(msg.sender);
        receiver = _receiver;
        expireAt = block.timestamp + expiration;
    }

    function close( uint256 amount, bytes memory sig) external {
        require(msg.sender == receiver);
        
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, this)));
        require(recoverSigner(message, sig) == sender);

        receiver.transfer(amount);
        selfdestruct( sender);
    }

    function extendTime( uint256 newExpire) external {        
        require( sender == msg.sender);
        require( newExpire > expireAt);
        expireAt = newExpire;
    }

    function claimTimeout() external {
        require( block.timestamp >= expireAt);
        selfdestruct( sender);
    }
    

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s){
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }


    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address){
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function prefixed( bytes32 hash ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


}