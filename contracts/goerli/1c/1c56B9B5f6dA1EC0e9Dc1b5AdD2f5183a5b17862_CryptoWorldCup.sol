/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.4.19;

contract CryptoWorldCup {

    //event NewSweetstake(uint sweetstakeId, string _team1, string _team2, uint _score1 uint _score2);


    struct Sweetstake {
        string team1;
        string team2;
        uint score1;
        uint score2;
    }

    Sweetstake[] public sweetstakes;

    mapping (uint => address) public sweetstakeToOwner;
    mapping (address => uint) ownerSweetstakeCount;
    mapping (address => uint[]) ownerToSweetstake;

    function _createSweetstake(string _team1, string _team2, uint _score1, uint _score2) private {
        uint id = sweetstakes.push(Sweetstake(_team1, _team2, _score1, _score2)) - 1;
        sweetstakeToOwner[id] = msg.sender;
        ownerSweetstakeCount[msg.sender]++;
        ownerToSweetstake[msg.sender].push(id);
        //NewSweetstake(id, _team1, _team2, _score1, _score2);
    }

    //Funcion que devuelve 
    function getSweetstakeByOwner(address _owner) external view returns (uint[]) {
        return ownerToSweetstake[_owner];
    }


}