/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;
contract BasicFunctions {
    //Anatomy of a function - type _variable scope view/pure returns
    // First declare that it is a function the you declare the variables; variables must have an underscore before them 
    //before you declare the variable, you need to declare the type (parameter) e.g. string integer uint, can have more than one variable
    //then you declare whether it is public or private (this is called the scope) 
    //you then need to declare whether the function is going to interact with other variables outside the function or if the function all encompassing
    //inorder to do the above you declare view/pure pure = all encompassing i.e. all variables are inside this function
    //then you have to say what it returns - specify what type of variable will be returned for true or false use bool.
    //e.g. - function (string _variable1, uint _variable2) public pure returns(bool) {}
    
    //Setting Things Up - A proper example
    string coinName = "EPIC COIN";
    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply; 
    }
mapping (address => Coin) internal myCoins;

function guessNumber(uint _guess) public pure returns(bool) {
    if (_guess == 75) {
        return true; 
    } else {
        return false;
    }
}

//function that returns a string the keyword memory must always follow
function getMyCoinName() public view returns(string memory){
    return coinName;
}

//that can only be called externally
function multiplyBalance (uint _multiplier) external {
    myBalance = myBalance * _multiplier;
}

//this function uses a for loop and multiplies params and string comparisons
function findCoinIndex (string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
    for (uint i = _startFrom; i < _myCoins.length; i++) {
        string memory coin = _myCoins[i];
        if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
            return i; 
        }
    }
    return 9999;
}
//update a mapping 
function addCoin(string memory _name, string memory _symbol, uint _supply) external {
    myCoins [msg.sender] = Coin(_name, _symbol, _supply);
       
}

//get coin from a mapping 
function getMyCoin() public view returns (Coin memory){
    return myCoins[msg.sender];
}


}