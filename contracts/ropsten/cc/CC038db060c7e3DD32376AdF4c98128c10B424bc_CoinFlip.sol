/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.0;

contract CoinFlip {

    uint private coinFace;

    mapping(address => uint) private _entry;

    function unsafeEntry(uint guess, uint salt)
        public
        payable
        returns (bool) {
        // Make sure guess is either 0-Heads or 1-Tails only
        require(guess < 2);
        // Make sure 1 eth bet is placed
        require(msg.value == 1 ether);
        _entry[msg.sender] = guess;
        return flipCoin(generateHash(guess, salt));
    }

    /**
    * This should be external to the Coinflip contract.
    */
    function generateHash(uint guess, uint salt)
        public
        pure
        returns (uint) {
        return uint(keccak256(guess + salt));
    }

    function flipCoin(uint hash)
        public
        returns (bool) {
        coinFace = hash % 2;
        if (coinFace == _entry[msg.sender]) {
            msg.sender.transfer(1 ether);
            return true;
        }
        return false;
    }
}