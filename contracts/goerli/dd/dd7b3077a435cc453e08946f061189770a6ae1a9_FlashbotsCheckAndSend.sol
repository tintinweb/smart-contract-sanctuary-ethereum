/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/*
  Copyright 2021 Flashbots: Scott Bigelow ([email protected]).
*/

// This contract performs one or many staticcall's, compares their output, and pays
// the miner directly if all calls exactly match the specified result
// For how to use this script, read the Flashbots searcher docs: https://hackmd.io/@flashbots/ryxxWuD6D
contract FlashbotsCheckAndSend {
    function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;
    
        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;
    
        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }
    
        stringData = new string(requiredAlloc);
    
        //copy data in 32 byte blocks
        assembly {
            let cycle := 0
    
            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }
    
        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function check32BytesAndSend(address _target, bytes memory _payload, bytes32 _resultMatch) external payable {
        _check32Bytes(_target, _payload, _resultMatch);
        block.coinbase.transfer(msg.value);
    }

    function check32BytesAndSendMulti(address[] memory _targets, bytes[] memory _payloads, bytes32[] memory _resultMatches) external payable {
        require (_targets.length == _payloads.length);
        require (_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _check32Bytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
        block.coinbase.transfer(msg.value);
    }

    function checkBytesAndSend(address _target, bytes memory _payload, bytes memory _resultMatch) external payable {
        _checkBytes(_target, _payload, _resultMatch);
        block.coinbase.transfer(msg.value);
    }

    function checkBytesAndSendMulti(address[] memory _targets, bytes[] memory _payloads, bytes[] memory _resultMatches) external payable {
        require (_targets.length == _payloads.length);
        require (_targets.length == _resultMatches.length);
        for (uint256 i = 0; i < _targets.length; i++) {
            _checkBytes(_targets[i], _payloads[i], _resultMatches[i]);
        }
        block.coinbase.transfer(msg.value);
    }

    // ======== INTERNAL ========
    
    function _check32Bytes(address _target, bytes memory _payload, bytes32 _resultMatch) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(_response.length >= 32, "response less than 32 bytes");
        bytes32 _responseScalar;
        assembly {
            _responseScalar := mload(add(_response, 0x20))
        }
        require(_responseScalar == _resultMatch, bytesToString(_response));
    }

    function _checkBytes(address _target, bytes memory _payload, bytes memory _resultMatch) internal view {
        (bool _success, bytes memory _response) = _target.staticcall(_payload);
        require(_success, "!success");
        require(keccak256(_resultMatch) == keccak256(_response), bytesToString(_response));
    }
}