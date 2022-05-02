pragma solidity ^0.5.1;

import "./oraclizeAPI_0.5.sol";

//主合約
//使用Oraclize取得亂數合約(外部API)
contract RpsGameMain is usingOraclize
{
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    uint8 public c_ui8NewRandom;
    uint8 public c_ui8GameRound = 0;     //uint8 範圍: 0~255，超過先不處理
    mapping (uint => string) public c_mapuitosPlayerResult;
    mapping (uint => string) public c_mapuitosBankerResult;
    mapping (uint => string) public c_mapuitosGameResult;
    
    ////////////////////////////////////copy CC老師的oraclize實作////////////////////////////////////
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
            
            emit newRandomNumber_bytes(bytes(_result)); // this is the resulting random number (bytes)
            
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
    ////////////////////////////////////copy CC老師的oraclize實作////////////////////////////////////


    function checkGameResult(uint _a, uint _b) internal pure returns (string memory _result)
    {
        string memory strResult;

        if (_a == _b)
            strResult = "Tie!";
        else if (_a == 0 && _b  == 1)
            strResult = "Player Win!";
        else if (_a == 0 && _b  == 2)
            strResult = "Banker Win!";
        else if (_a == 1 && _b  == 0)
            strResult = "Banker Win!";
        else if (_a == 1 && _b  == 2)
            strResult = "Player Win!";
        else if (_a == 2 && _b  == 0)
            strResult = "Player Win!";
        else if (_a == 2 && _b  == 1)
            strResult = "Banker Win!";

        return strResult;
    }
    
    function cmpStr(string memory str1, string memory str2) internal pure returns(bool)
    {
        bool ret = (keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2)));
        return ret;
    }
    
    function playGame (uint _localInput) payable public
    {
        //需求投入 0.01 ehter && 只能選擇0、1、2，這裡可以靠Web api來限制
        require (msg.value == 0.01 ether);
        require (_localInput == 0 || _localInput == 1 || _localInput == 2);

        //宣告變數
        uint uiBanker;
        uint uiPlayer;
        string memory strBanker;
        string memory strPlayer;
        string memory strResult;
        string memory strCompare = "Player Win!";
        
        //遊戲開始，局數加一
        c_ui8GameRound++; 
        
        //取得數值
        update (); //呼叫Oraclize
        uiBanker = c_ui8NewRandom % 3;
        uiPlayer = _localInput;

        //比較輸贏，
        strResult = checkGameResult (uiBanker, uiPlayer);
        if ( cmpStr (strResult, strCompare) )
            msg.sender.transfer (0.02 ether);

        //儲存結果
        if (uiBanker == 0)
            strBanker = "Rock";
        else if (uiBanker == 1)
            strBanker = "Paper";
        else if (uiBanker == 2)
            strBanker = "Scissors";

        if (uiPlayer == 0)
            strPlayer = "Rock";
        else if (uiPlayer == 1)
            strPlayer = "Paper";
        else if (uiPlayer == 2)
            strPlayer = "Scissors";

        c_mapuitosBankerResult[c_ui8GameRound] = strBanker;
        c_mapuitosPlayerResult[c_ui8GameRound] = strPlayer;
        c_mapuitosGameResult[c_ui8GameRound] = strResult;
    }
}