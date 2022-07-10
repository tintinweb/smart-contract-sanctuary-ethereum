/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier:  MIT

pragma solidity >= 0.7.0 <0.9.0;

contract basicFunctions {

    //some variables
    string coinName="epiccoin";
    struct coin {
        string coinName;
        string symbol;
        uint supply;
    }
    mapping (address=>coin) internal myCoins;
    // function (string _variable1,int _variable2,..) public view/pure returns (bool) {}

    uint public myBalance=1000;

    function guessNumber(uint _guess) public pure returns (bool)
    {
        if(_guess==5)
            return true;
        else
            return false;

    }

    //ara strings i memory, ojaldre. Memoria per strings es diferent, rollo
    //dels punters imagino. Deu ser una referencia a la @ de l'string
    //mes que l'string en si. Smelba que tan per parametres com en returns,
    //s'ha de posar lo de memory (com un &??)
    function getMyCoinName() public view returns (string memory)
    {
        return coinName;
    }

    //only be called externally
    function multiplyBalance(uint _multiplier) external
    {
        myBalance=myBalance*_multiplier;       
    }

    //for loop que tampoc fa falta venga espabil
    function findCoinIndex(string[] memory _myCoins,string memory _coin, uint _startFrom) public pure returns (uint)
    {
        for(uint i=_startFrom;i<_myCoins.length;i++)
        {
            //bueno, el rollo de la memory, s'ha de posar això
            if(keccak256(abi.encodePacked(_myCoins[i]))==keccak256(abi.encodePacked(_coin)) )
                return i;
        }
        return 9999;
    }

    //update a mapping
    function addCoin(string memory _name,string memory _symbol, uint _supply) external
    {
        myCoins[msg.sender] = coin(_name,_symbol,_supply);       
        
    }

    function getMyCoin() public view returns( coin memory )
    {
        return myCoins[msg.sender];
    }


}