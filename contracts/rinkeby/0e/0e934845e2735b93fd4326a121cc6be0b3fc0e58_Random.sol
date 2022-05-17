/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity ^0.8.13;

contract Random {

    uint result;
    uint private immutable sides = 6;

    function random() private returns(uint) {
        uint _result = uint(
            keccak256(
                abi.encodePacked(
                    block.difficulty, 
                    block.timestamp, 
                    msg.sender
                )
            ) 
        ) % sides;
        return _result;
    }

    function roll(uint number) public {
        uint _result;
        for(uint i=1; i < number; i++) {
            _result += random();
        }
        result = _result;
    }

    function getResult() public view returns(uint) {
        return result;
    }
}