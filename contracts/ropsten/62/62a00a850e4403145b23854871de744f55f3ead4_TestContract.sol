/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.8.14;

contract TestContract {
    event otherEvent(address _myaddress, uint amount);


    function getAns(uint8 block_number) public view returns(uint8) {
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block_number - 1), block.timestamp)))) % 10;
        return answer;
    }
}