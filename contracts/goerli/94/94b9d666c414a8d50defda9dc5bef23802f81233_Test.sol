/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    address public wallet;
    //專輯
    mapping(uint => music) public MUSIC;
    //使用者購買專輯
    mapping(address => mapping (uint=> personal))public playerlist;
    //註冊

    struct personal {
        address Uid;
        uint id;
        bool status;
        //uint time;  //播放次數限制
    }

    //專輯
    struct music {
        uint id; //專輯編號
        string Name; //專輯名稱
        string Info; //簡介
        string Singer; //演出者
        string Time; //發行時間
        string Url; //網址
    }

    personal public PP = personal({Uid:msg.sender,id:1,status:false});
    music public Music = music({id:1,Name:"",Info:"",Singer:"",Time:"",Url:""});

    constructor() payable  {
        wallet = msg.sender;
    }

    //1.專輯資料註冊(v)
    function login(uint _id,string memory _Name,string memory _Info,string memory _Singer,string memory _Time,string memory _Url) public {
        music storage musics = MUSIC[_id];
        musics.id = _id;
        musics.Name = _Name;
        musics.Info = _Info;
        musics.Singer = _Singer;
        musics.Time = _Time;
        musics.Url = _Url;
    }

    //2.使用者購買專輯(v) 
    function collect(address _Uid, uint _id) public payable{
        require(msg.value == 1000 wei, "must give 1000wei");
        personal storage UUID = playerlist[_Uid][_id];
        UUID.Uid = _Uid;
        UUID.id = _id;
        UUID.status = true;
        //(MUSIC[_id],playerlist[_Uid][_id]) = play();
    }

    //3.利用使用者編號及專輯編號提取資料(v)
    function play(address _Uid, uint _id)public view returns (music memory,personal memory){
        require(wallet == msg.sender && _Uid == playerlist[_Uid][_id].Uid,"You have not purchased this album");
        return (MUSIC[_id],playerlist[_Uid][_id]);
    }
}