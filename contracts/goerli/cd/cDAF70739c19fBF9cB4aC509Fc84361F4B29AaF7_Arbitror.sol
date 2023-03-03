/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity 0.8.19;

contract Arbitror {
    address public Alice;
    address public Bob;
    address public Judge;

    constructor(
        address AliceAddress,
        address BobAddress,
        address JudgeAddress
    ) {
        Alice = AliceAddress;
        Bob = BobAddress;
        Judge = JudgeAddress;
    }

    function deposit() payable public {
        require(msg.sender == Alice, "Sender not Alice");
    }

    function withdrawToBob() public {
        require(msg.sender == Judge, "Sender not Judge");
        payable(Bob).transfer(address(this).balance);
    }

    function withdrawToAlice() public {
        require(msg.sender == Judge, "Sender not Judge");
        payable(Alice).transfer(address(this).balance);
    }
}