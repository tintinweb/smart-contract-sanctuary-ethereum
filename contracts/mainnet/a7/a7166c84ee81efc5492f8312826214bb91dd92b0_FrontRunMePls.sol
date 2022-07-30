/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity >=0.8.7;

contract FrontRunMePls {
    event success();
    event fail();

    bytes32 public secretHash;

    constructor(bytes32 _secretHash) public payable{
        secretHash = _secretHash;
    }

    function withdrawAllPls(string calldata _secret, uint256 data) external{
        if(keccak256(abi.encodePacked(_secret)) == secretHash) {
            uint256 _myBalance = address(this).balance / data;
            payable(msg.sender).transfer(_myBalance);
            emit success();
        }else{
            emit fail();
        }
    }
}