/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

library SimpleSquanch {

    function squanch(bytes32[] calldata _input) public pure returns (bytes32[] memory _result){

        assembly {
            _result := mload(0x40)
            let lengthInput := calldataload(0x24)
            let _cursor := add(_result,0x40)    // skip length and starting from right to left
            for { let i := 0x0} lt(i, lengthInput) { i:= add(i, 0x01)}{

                let _encodedInputSlot := encode(calldataload(add(mul(0x20,i),0x44)))

                let inputCursor := 1
                for {} gt(_encodedInputSlot, 0x00) { }{
                    mstore8(sub(_cursor,inputCursor),_encodedInputSlot)
                    inputCursor := add(inputCursor,0x01)
                    _encodedInputSlot := shr(8,_encodedInputSlot)
                    if eq(mod(sub(_cursor,sub(inputCursor,0x01)),0x20),0) {
                        _cursor := add(sub(_cursor,sub(inputCursor,0x01)),0x40)
                        inputCursor := 1
                    }
                }
                _cursor := sub(_cursor,sub(inputCursor,0x01))
            }

            mstore(_result,div(sub(_cursor,_result),0x20)) // store length
            mstore(0x40, add(_cursor,0x60)) // Update/return the result array ofsset + length of the data (=i*32)

            function encode(_inputSlot) -> resultSlot {
                resultSlot := 0x0
                let moreFlag := 0x0
                let i := 0x0
                for { } true { } {
                    switch lt(_inputSlot, 0x80)
                    case true{
                        resultSlot := add(resultSlot, add( moreFlag , shl(mul(8,i),_inputSlot)))
                        break
                    }
                    default{
                        moreFlag := add(0x80, shl(0x8,moreFlag))
                        resultSlot := add(resultSlot,shl(mul(8,i),and(_inputSlot, 0x7F)))
                        i := add(i,0x1)
                        _inputSlot := shr(7,_inputSlot)
                        continue
                    }
                    break
                }
            }
        }
    }


    function unsquanch(bytes32[] calldata _input) public pure returns (bytes32[] memory _result){

        assembly {

            _result := mload(0x40)
            let _cursorResult := add(_result,0x20)
            let counter :=0
            let decodedCursorLast := 0
            let encodedLength := calldataload(0x24)
            let currentEncoded := calldataload(0x44)
            let NextEncoded := 0
            for {} lt(counter,encodedLength) {} { 
                let _decodedInputSlot, decodedCursor , complete:= decode(currentEncoded)
                switch complete
                case true{
                    mstore(_cursorResult, _decodedInputSlot)
                    _cursorResult := add(_cursorResult, 0x20)
                    if gt(decodedCursorLast,0){
                        decodedCursor := sub(decodedCursor,decodedCursorLast)
                        decodedCursorLast := 0
                        currentEncoded := NextEncoded
                        counter := add(counter,0x01)
                    }
                    currentEncoded := shr(mul(8,decodedCursor),currentEncoded)
                    if eq(currentEncoded,0){
                        counter := add(counter, 0x01)
                        if lt(counter,encodedLength){
                            currentEncoded := calldataload(add(0x44,mul(counter,0x20)))
                        }
                    }
                }
                default {
                    NextEncoded := calldataload(add(0x44,mul(add(counter,0x01),0x20)))
                    decodedCursorLast := decodedCursor
                    currentEncoded := add(shl(mul(8,decodedCursor),NextEncoded),currentEncoded)
                }
            }

            mstore(_result,sub(div(sub(_cursorResult,_result),0x20),0x01)) // store length
            mstore(0x40, _cursorResult) // Update/return the result array ofsset + length of the data (=i*32)
            
            function decode(_inputSlot) -> _resultSlot, _cursorProgress, _complete{
                _resultSlot := 0x0
                _cursorProgress := 0x0
                _complete := true
                for { } true { } {
                    _resultSlot := add(_resultSlot,shl(mul(7,_cursorProgress),and(_inputSlot, 0x7F)))
                    switch eq(and(_inputSlot, 0x80),0)
                    case true{
                        _cursorProgress := add(_cursorProgress,0x1)
                        if eq(_inputSlot,0 ){
                            _complete := false
                            _cursorProgress := sub(_cursorProgress,0x1)
                        }
                        break
                    }
                    default{
                        _inputSlot := shr(8,_inputSlot)
                        _cursorProgress := add(_cursorProgress,0x1)
                        continue
                    }
                    break
                }
            }
        }
    }

    function encode(bytes32 _input) public pure returns (bytes32  result){
        assembly {
            result := 0x0
            let moreFlag := 0x0
            let i := 0x0
            for { } true { } {
                switch lt(_input, 0x80)
                case true{
                    result := add(result, add( moreFlag , shl(mul(8,i),_input)))
                    break
                }
                default{
                    moreFlag := add(0x80, shl(0x8,moreFlag))
                    result := add(result,shl(mul(8,i),and(_input, 0x7F)))
                    i := add(i,0x1)
                    _input := shr(7,_input)
                    continue
                }
                break
            }
        }
    }   

    function decode(bytes32 _input) public pure returns (bytes32  result){
        assembly {
            result := 0x0
            let i := 0x0
            for { } true { } {
                result := add(result,shl(mul(7,i),and(_input, 0x7F)))
                switch eq(and(_input, 0x80),0)
                case true{
                    break
                }
                default{
                    _input := shr(8,_input)
                    i := add(i,0x1)
                    continue
                }
                break
            }
        }
    } 
}