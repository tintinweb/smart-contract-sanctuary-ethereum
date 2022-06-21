/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity 0.8.7;

contract permis{
    address owner;
    struct permisb{
        string neph;
        string nom;
        string prenom;
        uint points;
        string dateObtention;
    }
    //mapping (address => permisb) Permis;
    permisb permis1;
    constructor (){
        owner = msg.sender;
    }
    function addPermis (string memory _neph, uint _points, string memory _nom, string memory _prenom, string memory _dateObtention) public {
        require(msg.sender == owner);
        permis1 = permisb(_neph, _nom, _prenom, _points, _dateObtention);
    }
    /*function retraitPoints(uint _points) public {
        require(msg.sender == owner);
        require(_points <= 6);
        Permis.points -= _points; 
    }
    function ajoutPoints(uint _points) public {
        require(msg.sender == owner);
        require(_points <= 6);
        Permis.points += _points; 
    }*/
}