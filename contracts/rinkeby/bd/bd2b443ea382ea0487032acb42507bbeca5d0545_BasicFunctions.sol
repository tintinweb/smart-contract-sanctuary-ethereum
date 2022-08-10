/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// Name of the file on Solidity - BasicsFunctions (under the contracts folder)

// SPDX-License-Identifier: MIT

// Solidity Crash Course Part IV- About functions

pragma solidity >= 0.7.0 < 0.9.0;

contract BasicFunctions {
    // function (string _variable1, int _variable2) -> basically, you need to specify the type of the variable and then give it a name 
    // function (string _variable1, int _variable2) public -> you need to specify the scope -> so, it's public, private, internal or external
    // you need to specify if the function is going to act purely within itself or it can interact with variables outside the function:
    // you have two options - view and pure (within the function) -> function (string _variable1, int _variable2) public view/pure
    // then, you need to declare what it returns, and you type "returns(type - like "boolean) {}" function (string _variable1, int _variable2) public view/pure returns(bool) {}

// Setting things up 

    string coinName = "EPIC Coin";
    uint public myBalance = 1000;

    struct Coin {
        string name;
        string symbol;
        uint supply;
    }

    mapping (address => Coin) internal myCoins;  // mapping crypto address to a specific coin

    function guessNumber (uint _guess) public pure returns (bool) { //basically here I'm setting a function where I am saying that people need to guess the number - the supply
        if (_guess == 5) {
            return true;
        } else {
            return false;
        }
    }

    // Solidity Crash Course Part V- More on functions
    // creating more variations of functions


    //returns a string

    function getMyCoinName () public view returns(string memory) { // memory - we don't know how large the string is, so this element allocates memory. It's better to always use "memory" to return a string
        return coinName;
    } // here we use "view" because we need to interact with the function above to get the name of the coin

    
    
    //now let's see functions that can only be called externally

    function multiplyBalance (uint _multiplier) external {
        myBalance = myBalance * _multiplier;  // if I compile this now, it gives me an error because actually I didn't create anything called myBalance, so going to create it above
    }

    // Solidity Crash Course Part VI - String comparison and for loop


    // a function that uses a for loop and multiplies parameters and string comparison

    function findCoinIndex (string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for (uint i = _startFrom; i < _myCoins.length; i++) { // i++ means increment i 
            string memory coin = _myCoins[i];
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }  // in other languages, to compare strings we can just write "if(coin == _find) { return i; }" , but here we need to do something more complex
        }
        return 9999; // if I add this I'm telling it what to return in case it doesn't find anything. I have to give it this option, otherwise it'll give me an error
    } // find the coin in an index and return that coin
        
// after I deploy, i can interact with this function and need to give it a string - in _myCoins I'm adding ["Bitcoin", "Ethereum", "Chainlink"] ; in _find i'm adding "Chainlink" ; and in _startFrom I'm adding 0 to start from the beginning of the array
// if I call, it returns 2, which corresponds to Chainlink in my array. so, it's working
// if I type Bitcoin and start from 2, it returns 9999 because it can't find the element I'm looking for if I start from the end of the array




// Solidity Crash Course Part VII - Functions and mapping


    // update a mapping 


    function addCoin(string memory _name, string memory _symbol, uint _supply) external {
        myCoins [msg.sender] = Coin (_name, _symbol, _supply);
    }

    // function to get a coin from myCoin mapping 
    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
        
    // when I hit deploy, I find some parts in orange - in this case "addCoin" and "multiplybalance"- it happens because here you need to add data to the blockchain and it costs gas
    // things I'm adding to the addCoin section after deployment
    // _name "The Most Epic Coin"
    // _symbol "EPIC"
    // _supply 1500000
    // then, I hit transact
    // Now, if i click "getMyCoin" I got the data I just added - and i can change that

}