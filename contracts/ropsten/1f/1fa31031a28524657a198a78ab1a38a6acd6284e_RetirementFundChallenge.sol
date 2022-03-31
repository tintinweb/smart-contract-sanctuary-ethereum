/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.4.21;

contract RetirementFundChallenge {
    uint256 public startBalance;
    address public owner = msg.sender;
    address public beneficiary;
    uint256 public expiration = now + 10 years;

    function RetirementFundChallenge(address player) public payable {
        require(msg.value == 1 ether);

        beneficiary = player;
        startBalance = msg.value;
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function withdraw() public {
        require(msg.sender == owner);

        if (now < expiration) {
            // early withdrawal incurs a 10% penalty
            msg.sender.transfer(address(this).balance * 9 / 10);
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }

    function collectPenalty() public {
        require(msg.sender == beneficiary);

        uint256 withdrawn = startBalance - address(this).balance;

        // an early withdrawal occurred
        require(withdrawn > 0);

        // penalty is what's left
        msg.sender.transfer(address(this).balance);
    }
}