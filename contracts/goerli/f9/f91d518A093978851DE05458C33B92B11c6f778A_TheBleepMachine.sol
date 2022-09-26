// SPDX-License-Identifier: AGPL-3.0-or-later

// _/\/\/\/\/\/\__/\/\________________________/\/\/\/\/\____/\/\____________________________________________/\/\______/\/\__________________________/\/\________/\/\___________________________
// _____/\/\______/\/\__________/\/\/\________/\/\____/\/\__/\/\______/\/\/\______/\/\/\____/\/\/\/\________/\/\/\__/\/\/\__/\/\/\________/\/\/\/\__/\/\________________/\/\/\/\______/\/\/\___
// _____/\/\______/\/\/\/\____/\/\/\/\/\______/\/\/\/\/\____/\/\____/\/\/\/\/\__/\/\/\/\/\__/\/\__/\/\______/\/\/\/\/\/\/\______/\/\____/\/\________/\/\/\/\____/\/\____/\/\__/\/\__/\/\/\/\/\_
// _____/\/\______/\/\__/\/\__/\/\____________/\/\____/\/\__/\/\____/\/\________/\/\________/\/\/\/\________/\/\__/\__/\/\__/\/\/\/\____/\/\________/\/\__/\/\__/\/\____/\/\__/\/\__/\/\_______
// _____/\/\______/\/\__/\/\____/\/\/\/\______/\/\/\/\/\____/\/\/\____/\/\/\/\____/\/\/\/\__/\/\____________/\/\______/\/\__/\/\/\/\/\____/\/\/\/\__/\/\__/\/\__/\/\/\__/\/\__/\/\____/\/\/\/\_
// _________________________________________________________________________________________/\/\_______________________________________________________________________________________________

// The Bleep Machine Generates Music From Ethereum bytecode

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
	function play(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length
	) external returns (string memory) {
		bytes
			memory dynHeader = hex"524946460000000057415645666d74201000000001000100401f0000401f0000010008006461746100000000";
		assembly {
			let t := add(length, 36)
			mstore8(add(dynHeader, 36), and(t, 0xFF))
			mstore8(add(dynHeader, 37), and(shr(8, t), 0xFF))
			mstore8(add(dynHeader, 38), and(shr(16, t), 0xFF))

			mstore8(add(dynHeader, 72), and(length, 0xFF))
			mstore8(add(dynHeader, 73), and(shr(8, length), 0xFF))
			mstore8(add(dynHeader, 74), and(shr(16, length), 0xFF))
		}

		return
			string(
				bytes.concat(
					"data:audio/wav;base64,",
					bytes(Base64.encode(bytes.concat(dynHeader, _execute(musicBytecode, start, length))))
				)
			);
	}

	function _execute(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length
	) internal returns (bytes memory) {
		bytes memory executorCreation = bytes.concat(
			hex"61006d600081600b8239f36000358060801b806000529060801c60205260006040525b",
			musicBytecode,
			hex"60ff9016604051806080019091905360010180604052602051600051600101806000529110601757602051806060526020016060f3"
		);
		uint256 len = musicBytecode.length;

		uint256 codeLen;
		unchecked {
			codeLen = 0x4d + len;
		}
		if (codeLen > 0xFFFF) {
			revert MusicByteCodeTooLarge();
		}
		assembly {
			mstore8(add(executorCreation, 33), shr(8, codeLen))
			mstore8(add(executorCreation, 34), and(codeLen, 0xFF))
		}

		address executor;
		assembly {
			executor := create(0, add(executorCreation, 32), mload(executorCreation))
		}

		if (executor == address(0)) {
			revert MusicContractCreationFailure();
		}

		(bool success, bytes memory buffer) = executor.staticcall(abi.encode(start | (length << 128)));
		if (!success) {
			revert MusicExecutionFailure();
		}

		return buffer;
	}
}


// Following is Taken from https://github.com/Brechtpd/base64

// MIT License

// Copyright (c) 2021 Brecht Devos

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';


    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

}