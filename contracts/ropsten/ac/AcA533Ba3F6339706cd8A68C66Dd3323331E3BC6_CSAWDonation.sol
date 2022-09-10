/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract CSAWDonation {
    mapping(address => uint256) public balances;
    mapping(address => bool) public doneDonating;
    event sendToAuthor(bytes32 token);

    function newAccount() public payable{
        require(msg.value >= 0.0001 ether); 
        balances[msg.sender] = 10;
        doneDonating[msg.sender] = false;
    }

    function donateOnce() public {
        require(balances[msg.sender] >= 1);
        if(doneDonating[msg.sender] == false) {
            balances[msg.sender] += 10;
            msg.sender.call{value: 0.0001 ether}("");
            doneDonating[msg.sender] = true;
        }
    }

    function getBalance() public view returns (uint256 donatorBalance) {
        return balances[msg.sender];
    }

    function getFlag(bytes32 _token) public {
        require(balances[msg.sender] >= 30);
        emit sendToAuthor(_token); //sends the token 
    }
}