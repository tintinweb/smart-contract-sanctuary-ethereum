pragma solidity ^0.5.9;

import "oraclizeAPI.sol";


contract RpsGameMain is usingOraclize
{
    event newRandomNumber_player_rpsytes(bytes);
    event newRandomNumber_uint(uint);
    uint8 public c_ui8NewRandom;
    uint8 public round = 0;
    mapping (uint => string) public round2PlayerResult;
    mapping (uint => string) public round2ComputerResult;
    mapping (uint => string) public round2FinalResult;
    
    //Get random num wrote by CC teacher---------------------------------
    constructor() payable public
    {
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        update(); // let's ask for N random bytes immediately when the contract is created!
    }

    
    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof)public
    { 
        // if we reach this point successfully, it means that the attached authenticity proof has passed!
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) 
        {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } 
        else 
        {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            
            emit newRandomNumber_player_rpsytes(bytes(_result)); // this is the resulting random number (bytes)
            
            // for simplicity of use, let's also convert the random bytes to uint if we need
            //uint16 maxRange = 2**8; // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            uint8 randomNumber = uint8(uint(keccak256(abi.encodePacked(_result))) % 256); // this is an efficient way to get the uint out in the [0, maxRange] range
            c_ui8NewRandom = randomNumber;
            
            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
        }
    }

    
    function update() payable public
    { 
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }
    //end random num ------------------------------------------


    function checkGameResult(uint _computer_rps, uint _player_rps) internal pure returns (string memory _result)
    {
        string memory strResult;

        if (_computer_rps == _player_rps)
            strResult = "Tie!";
        else if (_computer_rps == 0 && _player_rps  == 1)
            strResult = "Player Win!";
        else if (_computer_rps == 0 && _player_rps  == 2)
            strResult = "Computer Win!";
        else if (_computer_rps == 1 && _player_rps  == 0)
            strResult = "Computer Win!";
        else if (_computer_rps == 1 && _player_rps  == 2)
            strResult = "Player Win!";
        else if (_computer_rps == 2 && _player_rps  == 0)
            strResult = "Player Win!";
        else if (_computer_rps == 2 && _player_rps  == 1)
            strResult = "Computer Win!";

        return strResult;
    }

    
    function cmpStr(string memory _strResult, string memory _strCompare) internal pure returns(bool)
    {
        bool ret = (keccak256(abi.encodePacked(_strResult)) == keccak256(abi.encodePacked(_strCompare)));
        return ret;
    }
    
    
    function RpsMain (uint _rps2num) payable public
    {
        require (msg.value == 0.01 ether);
        require (_rps2num == 0 || _rps2num == 1 || _rps2num == 2);

        uint computer_rps;
        uint player_rps;
        string memory strComputer;
        string memory strPlayer;
        string memory strResult;
        string memory strCompare = "Player Win!";
        
        //game start
        round++; 
        update ();
        computer_rps = c_ui8NewRandom % 3;
        player_rps = _rps2num;
        strResult = checkGameResult (computer_rps, player_rps);
        if ( cmpStr (strResult, strCompare) )
            msg.sender.transfer (0.02 ether);

        if (computer_rps == 0)
            strComputer = "Rock";
        else if (computer_rps == 1)
            strComputer = "Paper";
        else if (computer_rps == 2)
            strComputer = "Scissors";

        if (player_rps == 0)
            strPlayer = "Rock";
        else if (player_rps == 1)
            strPlayer = "Paper";
        else if (player_rps == 2)
            strPlayer = "Scissors";

        round2ComputerResult[round] = strComputer;
        round2PlayerResult[round] = strPlayer;
        round2FinalResult[round] = strResult;
    }
}