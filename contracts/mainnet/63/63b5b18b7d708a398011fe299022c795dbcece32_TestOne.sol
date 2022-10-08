/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Test One - calling missing functions on old contracts without crashing
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

contract TestOne {

    bool public lastSuccess;
    string public lastSymbol;

    function getERC20Symbol(address token) public view returns (bool _success, string memory _symbol) {
        bytes memory returnBytes;
        (_success, returnBytes) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (_success) {
            if (returnBytes.length >= 64) {
                _symbol = abi.decode(returnBytes, (string));
            } else if (returnBytes.length == 32) {
                uint8 i = 0;
                while (i < 32 && returnBytes[i] != 0) {
                    i++;
                }
                bytes memory bytesArray = new bytes(i);                
                for (i = 0; i < 32 && returnBytes[i] != 0; i++) {
                    bytesArray[i] = returnBytes[i];
                }
                _symbol = string(bytesArray);
            } else {
                _success = false;
                _symbol = "?";
            }
        } else {
            _symbol = "?";
        }
    }

    function testIt(address token) public {
        (lastSuccess, lastSymbol) = getERC20Symbol(token);
    }
}