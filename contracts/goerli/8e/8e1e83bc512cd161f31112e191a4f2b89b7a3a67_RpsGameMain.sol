pragma solidity ^0.4.11;

import "Oraclize.sol";

contract RpsGameMain is usingOraclize {
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    event GameResult(address Player1,uint16 GameRound,string YourChoise,string DealerChoise,string YourResult);
    address public Player;
    uint8 public new_random;
    uint8 public PlayerInput;
    uint8 public c_ui8NewRandom;
    uint16 public c_ui8GameRound = 0;


   constructor() payable public {
        oraclize_setProof(proofType_Ledger); 
        update(); 
    }
    
    function __callback(bytes32 _queryId, string _result, bytes _proof) public
    { 
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            
        } else {
        
            emit newRandomNumber_bytes(bytes(_result)); 
            uint8 randomNumber = uint8(uint(keccak256(abi.encodePacked(_result))) % 256);//0-255
            new_random = randomNumber;
            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
        }

        c_ui8NewRandom=new_random % 3;
        Result(c_ui8NewRandom,PlayerInput);
    }
    
    function update() payable public{ 
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
    }
    

    function playgameCost10Finney(uint8 Input) payable public{ //0剪刀 1石頭 2布
        require(msg.value == 0.01 ether);
        require(Input == 0 || Input == 1 || Input == 2);
        Player=msg.sender;
        c_ui8GameRound++;
        PlayerInput=Input;
        update();
    }

    function Result(uint8 _a,uint8 _b) internal { //dealer  player
        if( _a==0 && _b==0 ){
            msg.sender.transfer(0.01 ether);
            emit GameResult(Player,c_ui8GameRound,"Rock","Rock","tie");}
        else if( _a==0 && _b==1){
            emit GameResult(Player,c_ui8GameRound,"Scissors","Rock","You lose");}
        else if( _a==0 && _b==2){
            msg.sender.transfer(0.02 ether);
            emit GameResult(Player,c_ui8GameRound,"Paper","Rock","You win");}
        else if( _a==1 && _b==0){
            msg.sender.transfer(0.02 ether);
            emit GameResult(Player,c_ui8GameRound,"Rock","Scissors","You win");}
        else if( _a==1 && _b==1){
            msg.sender.transfer(0.01 ether);
            emit GameResult(Player,c_ui8GameRound,"Scissors","Scissors","tie");}
        else if( _a==1 && _b==2){
            emit GameResult(Player,c_ui8GameRound,"Paper","Scissors","You lose");}
        else if( _a==2 && _b==0){
            emit GameResult(Player,c_ui8GameRound,"Rock","Paper","You lose");}
        else if( _a==2 && _b==1){
            msg.sender.transfer(0.02 ether);
            emit GameResult(Player,c_ui8GameRound,"Scissors","Paper","You win");}
        else if( _a==2 && _b==2){
            msg.sender.transfer(0.01 ether);
            emit GameResult(Player,c_ui8GameRound,"Paper","Paper","tie");} 
    }
}