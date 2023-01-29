/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

contract VerifySignature
{
	function getMsgHash
	(
		address reciever,
		uint value,
		string memory message,
		uint nonce
	) public pure returns (bytes32) 
	{
		return keccak256(abi.encodePacked(reciever, value, message, nonce));
	}

	function formatHashedMessage
	(
		bytes32 messageHash
	) public pure returns (bytes32)
	{
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)); 
	}

	function recoverSigner
	(
		bytes32 signedMessageHash,
		bytes memory sig
	) public pure returns (address)
	{
		(bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
		return ecrecover(signedMessageHash, v, r, s);
	}

	function splitSig
	(
		bytes memory sig
	) public pure returns (bytes32 r, bytes32 s, uint8 v)
	{
		require(sig.length == 65, "if siglen != 65 then invalid sig!");
		assembly {
			r := mload(add(sig, 32))
			s := mload(add(sig, 64))
			v := byte(0, mload(add(sig, 96)))
		}
		//implicit return of (r, s, v)
	}

	function verify
	(
		address signer,
		address reciever,
		uint value, 
		string memory message,
		uint nonce,
		bytes memory sig
	) public pure returns (bool)
	{
		bytes32 messageHash = getMsgHash(reciever, value, message, nonce);
		bytes32 signedMessageHash = formatHashedMessage(messageHash);
		return recoverSigner(signedMessageHash, sig) == signer;
	}
}