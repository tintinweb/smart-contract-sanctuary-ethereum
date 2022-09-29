// SPDX-License-Identifier: AGPL-3.0-or-later

// _/\/\/\/\/\/\__/\/\________________________/\/\/\/\/\____/\/\____________________________________________/\/\______/\/\__________________________/\/\________/\/\___________________________
// _____/\/\______/\/\__________/\/\/\________/\/\____/\/\__/\/\______/\/\/\______/\/\/\____/\/\/\/\________/\/\/\__/\/\/\__/\/\/\________/\/\/\/\__/\/\________________/\/\/\/\______/\/\/\___
// _____/\/\______/\/\/\/\____/\/\/\/\/\______/\/\/\/\/\____/\/\____/\/\/\/\/\__/\/\/\/\/\__/\/\__/\/\______/\/\/\/\/\/\/\______/\/\____/\/\________/\/\/\/\____/\/\____/\/\__/\/\__/\/\/\/\/\_
// _____/\/\______/\/\__/\/\__/\/\____________/\/\____/\/\__/\/\____/\/\________/\/\________/\/\/\/\________/\/\__/\__/\/\__/\/\/\/\____/\/\________/\/\__/\/\__/\/\____/\/\__/\/\__/\/\_______
// _____/\/\______/\/\__/\/\____/\/\/\/\______/\/\/\/\/\____/\/\/\____/\/\/\/\____/\/\/\/\__/\/\____________/\/\______/\/\__/\/\/\/\/\____/\/\/\/\__/\/\__/\/\__/\/\/\__/\/\__/\/\____/\/\/\/\_
// _________________________________________________________________________________________/\/\_______________________________________________________________________________________________

// The Bleep Machine Generates Music From Executing Ethereum Bytecode.

// It is an implementation of Bytebeat on the EVM.
//
// Try the following:
//
// cast call --rpc-url https://rpc.bleeps.art machine.bleeps.eth "WAV(bytes,uint256,uint256)(bytes)" 0x808060081c9160091c600e1661ca98901c600f160217  0 100000 | xxd -r -p | aplay
//
// Note: this requires cast (see: https://github.com/foundry-rs) + aplay + xxd + a working ethereum rpc node (here: https://rpc.bleeps.art).
//
// This will execute the following formula: `t*(0xCA98>>(t>>9&14)&15)|t>>8` (taken from http://viznut.fi/texts-en/bytebeat_exploring_space.pdf)
//
// It will be executed 100,000 times with t starting at 0 and increasing by one on each iteration.
//
// This will produce a WAV file of 100,000 samples (8 bits, mono) at 8000 hz (or 12.5 seconds).

// Copyright (C) 2022 Ronan Sandford

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.16;

error MusicByteCodeTooLarge();
error MusicContractCreationFailure();
error MusicExecutionFailure();

contract TheBleepMachine {
	/// @notice return the name of the contract
	function name() external pure returns (string memory) {
		return "The Bleep Machine";
	}

	/// @notice Generates a WAV file (8 bits, 8000Hz, mono) by executing the EVM bytecode provided (`musicBytecode`).
	/// The time offset is the only element on the stack at each loop iteration.
	/// Such offset starts at `start` and is increased by one for each iteration.
	/// The code is expected to provide an 8 bits sample as the only element in the stack at the end of each iteration.
	/// The loop is executed `length` times to generate `length` samples which compose the music generated.
	/// @param musicBytecode the EVM bytecode that the Bleep Machine will execute in a loop.
	/// @param start sample offset at which the music starts.
	/// @param length the number of samples to generate.
	/// @return WAV file (8 bits, 8000Hz, mono).
	function WAV(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length
	) external returns (bytes memory) {
		// Create empty wav file of size `length` with proper header.
		bytes memory wavFile = _wavFile(length);
		// Generate the samples in it at offset 44 (header size)
		_generateAndwrite(musicBytecode, start, length, wavFile, 44);
		return wavFile;
	}

	/// @notice Generates raw 8 bits samples by executing the EVM bytecode provided (`musicBytecode`).
	/// The time offset is the only element on the stack at each loop iteration.
	/// Such offset starts at `start` and is increased by one for each iteration.
	/// The code is expected to provide an 8 bits sample as the only element in the stack at the end of each iteration.
	/// The loop is executed `length` times to generate `length` samples which compose the music generated.
	/// @param musicBytecode the EVM bytecode that the Bleep Machine will execute in a loop.
	/// @param start sample offset at which the music starts.
	/// @param length the number of samples to generate.
	/// @return 8 bits samples buffer.
	function generate(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length
	) external returns (bytes memory) {
		// Create empty bytes array of exact length
		bytes memory samples = new bytes(length);
		// Generate the samples in it
		_generateAndwrite(musicBytecode, start, length, samples, 0);
		return samples;
	}

	/// @notice Generates a WAV file (8 bits, 8000Hz, mono) from contract's code at a specific address.
	/// @param addr address of any contract. Most will generate noises.
	/// @return WAV file (8 bits, 8000Hz, mono).
	function listenTo(address addr) external view returns (bytes memory) {
		uint256 size;
		assembly {
			size := extcodesize(addr)
		}
		bytes memory buffer = _wavFile(size);
		assembly {
			// copy code in that buffer at pos 76 = 44 (wav header size) + 32 (where bytes size is stored)
			extcodecopy(addr, add(buffer, 76), 0, size)
		}
		return buffer;
	}

	// ----------------------------------------------------------------------------------------------------------------
	// INTERNAL
	// ----------------------------------------------------------------------------------------------------------------

	/// @dev generate sample data by executing the EVM bytecode provided (`musicBytecode`) and write it in buffer.
	/// It generates the data in the provided buffer (assumed to have the correct length already, see _wavFile)
	/// @param musicBytecode the EVM bytecode the Bleep Machine will execute in a loop.
	/// @param start sample offset at which the music starts.
	/// @param length the number of samples to generate.
	/// @param buffer buffer to write to
	/// @param offset offset to start writing to
	function _generateAndwrite(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length,
		bytes memory buffer,
		uint256 offset
	) internal {
		// We create the contract from the music bytecode.
		address executor = _create(musicBytecode);

		bool success;
		assembly {
			// We ask solidity for the pointer to free memory (not yet used)
			let argsPointer := mload(0x40)
			// We then store at that position the arguments <start><length> (in 32 bytes, 128 bits each)
			mstore(argsPointer, or(shr(128, shl(128, start)), shl(128, length)))
			// We then make the call
			// and store the result in the existing buffer at pos = offset + 32
			// (the first 32 bytes store the length of the bytes array)
			success := staticcall(gas(), executor, argsPointer, 32, add(buffer, add(offset, 32)), length)
		}

		// If there is any error, we revert.
		if (!success) {
			revert MusicExecutionFailure();
		}
	}

	/// @dev Creates a new contract that generate the music from a given start offset and length.
	/// @param musicBytecode the EVM bytecode the Bleep Machine will execute in a loop.
	/// @return executor address of the contract that will generate samples when executed.
	function _create(bytes memory musicBytecode) internal returns (address executor) {
		// This code generates a contract creation-code that loops over the provided `musicBytecode`.

		// 61006d600081600b8239f3 => simply copy the code after it.
		// Note that 006d will is overwritten below with the new length

		// 6000358060801b60801c806000529060801c6020525b => prepare the data
		// In particular it parses the call-data to extract the start and length parameters (Stored in 128bit each).
		// It then ensures that the starting time is on top of the stack before the loop starts.
		// The last `5b` is a JUMPDEST that will be jumped to at each iteration.

		// 6040519060ff16816060015360010180604052600051810190602051116015576020516060f3
		// => Performs the loop and when it ends (start + time >= length), it copy the generated buffer in return data.

		bytes memory executorCreation = bytes.concat(
			hex"61006d600081600b8239f36000358060801b60801c806000529060801c6020525b",
			musicBytecode,
			hex"6040519060ff16816060015360010180604052600051810190602051116015576020516060f3"
		);
		uint256 len = musicBytecode.length;

		// We make sure the generated code length can be encoded in the PUSH2.
		uint256 codeLen;
		unchecked {
			codeLen = 0x3C + len;
		}
		if (codeLen > 0xFFFF) {
			revert MusicByteCodeTooLarge();
		}

		// We store the generated creationCode length so that the creationCode work with its new length.
		assembly {
			mstore8(add(executorCreation, 33), shr(8, codeLen))
			mstore8(add(executorCreation, 34), and(codeLen, 0xFF))
		}

		// We create the contract.
		assembly {
			executor := create(0, add(executorCreation, 32), mload(executorCreation))
		}

		// If there is any error, we revert.
		if (executor == address(0)) {
			revert MusicContractCreationFailure();
		}
	}

	/// @dev generate an empty WAV file of length `length`
	/// @param length the number of samples in the WAV file.
	/// @return wavFile : zeroed out WAV file with correct headers data.
	function _wavFile(uint256 length) internal pure returns (bytes memory wavFile) {
		unchecked {
			wavFile = new bytes(length + 44); // 44 is the header size
		}

		assembly {
			// WAV file header, 8 bits, 8000Hz, mono, empty length.
			mstore(add(wavFile, 32), 0x524946460000000057415645666d74201000000001000100401f0000401f0000)
			mstore(add(wavFile, 64), 0x0100080064617461000000000000000000000000000000000000000000000000)

			// Top header length is length of data + 36 bytes.
			// More precisely: (4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)).
			// Where SubChunk1Size is 16 (for PCM) and SubChunk2Size is the length of the data.
			let t := add(length, 36)
			// We write that length info in the top header (in little-endian).
			mstore8(add(wavFile, 36), and(t, 0xFF))
			mstore8(add(wavFile, 37), and(shr(8, t), 0xFF))
			mstore8(add(wavFile, 38), and(shr(16, t), 0xFF))
			// We also write the exact data length just before the data stream as per WAV file format spec (in little-endian).
			mstore8(add(wavFile, 72), and(length, 0xFF))
			mstore8(add(wavFile, 73), and(shr(8, length), 0xFF))
			mstore8(add(wavFile, 74), and(shr(16, length), 0xFF))
		}
	}
}