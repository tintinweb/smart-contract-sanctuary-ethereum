/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

contract ShanM {
    
    address public wallet;
 
    mapping(uint => music) internal MUSIC;
    
    mapping(address => mapping (uint=> personal))public playerlist;
    
    uint public ListenEndtime;


    struct personal{
        address Uid;
        uint id;
        bool status;
    }

    struct music {
        uint id; 
        string Name; 
        string Info; 
        string Singer; 
        string Time; 
        string Url; 
    }


    constructor() payable  {
        wallet = msg.sender;
    }

    function login(uint _id,string memory _Name,string memory _Info,string memory _Singer,string memory _Time,string memory _Url) public {
        music storage musics = MUSIC[_id];
        musics.id = _id;
        musics.Name = _Name;
        musics.Info = _Info;
        musics.Singer = _Singer;
        musics.Time = _Time;
        musics.Url = _Url;
    }

    function collect(address _Uid, uint _id) public payable{
        require(msg.value == 1000 wei, "must give 1000wei");
        personal storage UUID = playerlist[_Uid][_id];
        UUID.Uid = _Uid;
        UUID.id = _id;
        UUID.status = true;
        uint stoptime = 60; 
        ListenEndtime = block.timestamp + stoptime ;
        //(MUSIC[_id],playerlist[_Uid][_id]) = play();
    }

    function play(address _Uid, uint _id)public returns (music memory,personal memory){
        require(block.timestamp <= ListenEndtime, "Time's up!");//timestamp limit
        require(wallet == msg.sender && _Uid == playerlist[_Uid][_id].Uid,"You have not purchased this album");
        return (MUSIC[_id],playerlist[_Uid][_id]);
        //return (PP(playerlist[_Uid][_id]),Music(MUSIC[_id]));
    }
}