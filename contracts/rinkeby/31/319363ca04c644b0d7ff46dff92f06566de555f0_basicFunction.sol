/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Basics101Test {
    uint public myBalance = 15;
    int private txAmount = -2;
    string internal coinName = 'Apic coin';
    bool isValid;

    uint public blockTime = block.timestamp;
    address public sender = msg.sender;

    string[] public tokenNames = ['Chainlink', 'Ethereum', 'Doge'];
    uint[5] levels = [1,2,3,4,5];
    uint public daytime = 1 days;

    struct user {
        address userAddress;
        string name;
        bool hasTraded;
    }
    user public users;
    mapping  (string => string) public accountNmae;
}

contract basicFunction {
    uint public myBalance = 100;    
    string coinName = 'Epic coin';

    struct Coin {
        string Name;
        string symball;
        uint Supply;
        }
    mapping(address => Coin) internal myCoins;

    function guessNumber(uint guess) external pure returns(bool) {
        if(guess == 5) {return true;}
        else {return false;}
    }
    function getMyCoinName() external view returns(string memory) {
        return coinName;
    }
    function multiplyMyBalance(uint _value) external {
        myBalance = myBalance * _value;
    }
    function findCoinName(string[] memory _name, string memory find, uint startFrom) external pure returns(uint) {
        for(uint i = startFrom; i < _name.length; i++) {
            string memory coin = _name[i];
            if ( keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(find)) ) { return i;}
        } return 999;
    }
    function addCoin(string memory _name, string memory _symball, uint _supply) public {
        myCoins[msg.sender] = Coin(_name, _symball, _supply);
    }
    function getCoin() public view returns(Coin memory) {
        return myCoins[msg.sender];
    }



}