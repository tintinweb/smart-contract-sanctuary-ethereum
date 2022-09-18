/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity >= 0.7.0 < 0.9.0;

contract BFunctions {

    string coinName = "Epic Coin";

    struct Coin {

        string name;
        string symbol;
        string supply;

    }

    mapping (address => Coin) internal myCoins;

    function guessNumber(uint _guess) public pure returns(bool){
        if(_guess == 5){
            return true;
        }
        return false;
    }

    function getMyCoinName() public view returns(string memory) {
        return coinName;
    }

}