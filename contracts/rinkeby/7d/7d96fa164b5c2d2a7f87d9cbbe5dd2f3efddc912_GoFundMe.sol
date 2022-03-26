/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

//SPDX-License-Identifier: MIT
pragma solidity = 0.7.0;

contract GoFundMe {

    uint minimunWei = 5000000000000000; // 10 ** 9 ; 10^9 to the power of 9
    address Bob = 0xE8054C9DF760392F6ACcfC937Dc999Dd304Afc4C;

    function fund() payable public {
        require(msg.sender != Bob, "Ok, Bob...");
        require(msg.value >= minimunWei, "Error: Minimun is 0.1E , please send more ETH. :)");   
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() payable public {
        require(msg.sender == Bob, "This is only for Bob");
        require(address(this).balance > 0, "No ETH available.");
        msg.sender.transfer(address(this).balance);
    }
}