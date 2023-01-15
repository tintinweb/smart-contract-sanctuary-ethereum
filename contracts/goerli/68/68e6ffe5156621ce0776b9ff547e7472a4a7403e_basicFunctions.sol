/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;


contract basicFunctions 
{

    // Setting things up

    string coinname = "sat coin";
    uint public myBalances = 2000;


    struct coin {
        string name;
        string symbol;
        uint supply;
        

    }

    mapping (address => coin) internal mycoins;

    //function function_name (string memory, type variable2, public/private, view/pure, returns (type)

    function guessnumber (uint guess) public pure returns (bool) {
        if 
            (guess == 5) {
                return true;
            }
        
        
        else{
            return false;
        }

    }


    // returns a string

    function getcoinname () public view returns (string memory)
    {
        return coinname;
    }



    // A function that can only be called externally

        function multiplybalance (uint _multiplier) external {
            myBalances = myBalances*_multiplier;

        }


        // function that uses for loop to find coin in an index

        function findcoin(string[] memory _mycoins, string memory _find, uint _startfrom) public pure returns(uint) {
            for (uint i = _startfrom; i < _mycoins.length; i++){
                string memory coin = _mycoins[i];
                if(keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                    return i;
                    
                }
            }
        }


    // update a mapping


    function addcoin(string memory _name, string memory _symbol, uint _supply) external {
        mycoins[msg.sender] = coin(_name, _symbol, _supply);
    }


    // function to get a coin from mycoin mapping

    function getmycoin () public view returns(coin memory) {
            return mycoins[msg.sender];
    }
        









}