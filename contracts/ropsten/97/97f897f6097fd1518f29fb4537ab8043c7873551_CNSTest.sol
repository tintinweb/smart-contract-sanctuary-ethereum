/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.4.22;

contract CNSTest {
    address challenge = 0xC0770a88816Ff575960928AA0AAe0AB0d727d3F6;

    function guess(string studentID) public {
        uint16 number = uint16(keccak256(block.blockhash(block.number - 1), block.timestamp)) * 8191 + 12347;
        challenge.call(bytes4(keccak256("guessRandomNumber(string studentID, uint16 numberGuessed)")), studentID, number);
    }
}