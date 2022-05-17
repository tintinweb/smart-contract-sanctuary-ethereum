/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity ^0.8.13;

contract Random {

    uint result;
    uint private immutable sides = 6;
    mapping(uint => uint) results;

    function random(uint nonce) internal returns(uint) {
        uint _result = uint(
            keccak256(
                abi.encodePacked(
                    block.difficulty, 
                    block.timestamp, 
                    msg.sender,
                    nonce
                )
            ) 
        ) % sides + 1;
        return _result;
    }

    function roll(uint number) public {
        uint _roll;
        uint _result;
        for(uint i=0; i < number; i++) {
            _roll = random(i);
            _result += _roll;
            results[i] = _roll;  
        }
        result = _result;
    }

    function getSumResult() public view returns(uint) {
        return result;
    }

    function getIndResult(uint die) public view returns(uint) {
        return results[die];
    }

}