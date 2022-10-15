/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; //version

contract SimpleStorage {
    bool x = true;
    uint256 numb = 18; //senza specifier, è di default internal
    uint y; //default = 0 
    int256 negative = -5;     //uint / int XX -> XX sono bits, max 256
    bytes32 bytesss = "cat";  //bytesXX -> XX sono bytes, max 32

    mapping(string => uint256) public nameToAmounts;

    struct Player{
        uint256 amount;
        string name;
    }

    Player[] public players;
    uint256[] public amounts; 


    Player public tone = Player({amount:100,name:"Tone"});

    function setNumb (uint256 _chosen) public{
        numb = _chosen;
    }

    //funzioni pure e view non dovrebbero spendere gas ma a me risulta che lo spendano (no, è solo amount di gas che viene calcolato e mostrato)
    //stessa cosa vale per il getter automatico per una variabile public 
    //una funzione pure o view consuma cmq gas se viene chiamata all'interno di una funzione che a sua volta consuma gas
    function getNumb() public view returns (uint256){
        return numb;
    }

    function addPlayer(uint256 _amount,string memory _name) public {
        players.push(Player(_amount,_name));
        nameToAmounts[_name] = _amount;
    }


    //6 modi per storare informazioni
    //calldata: esiste temporaneamente nella funzione e non puo essere modificato
    //memory: esiste temporaneamente nella funzione e puo essere modificato
    //storage: permamente, le variabili globali lo sono di default
    //map,struct e array se param di una funzione, devono essere dichiarati memory o calldata, gli altri types (tipo uint) no 
    //altri 3 meno importanti ora
}