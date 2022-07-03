/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0<0.9.0;

contract BasicFunctions {
    // setting things up
    string coinName = "EPIC Coin";
    uint public myBalance = 1000;
    struct Coin {
        string name;
        string symbol;
        uint supply;
    }
    mapping (address => Coin) internal myCoins;

    // function (string memory _variable1, int _variable2) public view/pure returns (typeOfReturn) {}
    function guessNumber (uint _guess) public pure returns(bool){
        if (_guess == 5){
            return true;
        }else {
            return false;
        }
    }
    // function returns a string
    function getMyCoinName () public view returns (string memory) {
        return coinName;
    }
    // that can only be called exetrnaly
    function multiplyBalance (uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    // that uses a for loop multiplys params and strings comparrison

    function findCoinIndex (string [] memory _myCoins, string memory _find, uint _startFrom ) public pure returns (uint){
        for (uint i = _startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];
            // below in the if statmnet to compare to things you need to use the below sintagm
            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))) {
                return i;
            }

        }
        return 999;
    }

    //update a mapping

    function addCoin (string memory _name, string memory _symbol, uint _supply) external {
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
        // above is aclling my coins mapping and used the global variable msg.sender insetad of a specific address 
        //

    }

    // function to get a coin from coin mapping 
    function getMyCoin () public view returns (Coin memory){
        return myCoins[msg.sender];
        // if not a straight forward variable you need to use memory in the declaration of the varaible. 
        // returns only the coins created or related to the messaage sender so if an adress was passed above in the add coin function
        // same adderss should be used here 
    }

}