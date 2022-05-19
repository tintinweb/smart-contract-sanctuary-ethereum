/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;

	contract STD {

		address owner;
		string info = "610721225";

		event record(string);

		mapping(uint256 => bool) usedNonces;

		constructor() public {
			owner = msg.sender;
		}

		function verify(bytes32 _message, uint8 nonce, bytes memory signture) public{			
			require(!usedNonces[nonce]);
			usedNonces[nonce] = true;

			bytes memory prefix = "\x19Ethereum Signed Message:\n32";
 			_message = keccak256(abi.encodePacked(prefix, _message));			
 	        require(recoverSigner(_message, signture) == owner);			 
			emit record(info);
		}
		function kill() public {
			require(msg.sender == owner);
			selfdestruct(msg.sender);
		}

		function splitSignature(bytes memory sig) internal pure returns(uint8 v, bytes32 r, bytes32 s){
			require(sig.length == 65);
	
			assembly {
                r := mload(add(sig, 32))

				s := mload(add(sig, 64)) 

				v := byte(0, mload(add(sig, 96)))
			}
			return (v, r, s);
		}

		function recoverSigner(bytes32 _message, bytes memory sig) internal pure 
		returns (address)
		{
			(uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
			return ecrecover(_message, v, r, s); 
		}
	}