/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity 0.8.13;


contract test{

    function keccak(bytes32 mystery) public pure returns(bytes32){
        return keccak256(abi.encodePacked(mystery));
    }
}