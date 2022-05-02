pragma solidity ^0.5.17;
import "./oraclizeAPI_0.5.sol";
contract RPS is usingOraclize{
    event Play(address indexed Player, uint PlayerInput, uint OpponentInput, uint Win);
    
    constructor() public payable{
        oraclize_setProof(proofType_Ledger);
    }
    
    mapping(address=>mapping(bytes32=>uint))public players;
    uint public win;
    uint public input;
    uint public rand;
    address payable public user;
    //1=剪刀
    //2=石頭
    //3=布
    //每次0.01個ether
    
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public
    {
        // if (msg.sender != oraclize_cbAddress()) revert();
        // if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
        //     revert();
        // } 
        // else {
            uint maxRange = 3;
            rand = 1 + uint(keccak256(abi.encodePacked(_result))) % maxRange;
        // }
        players[user][_queryId]=input;
        if(input==1){
            if(rand==1) win=2;
            else if(rand==2) win=0;
            else win=1;
        }
        else if(input==2){
            if(rand==1) win=1;
            else if(rand==2) win=2;
            else win=0;
        }
        else{
            if(rand==1) win=0;
            else if(rand==2) win=1;
            else win=2;
        }
        if(win==1) user.transfer(2*10**16);
        else if(win==2) user.transfer(1*10**16);
        //0=輸
        //1=贏
        //2=平手
        emit Play(user, input, rand, win);
    }

    function play(uint punch) payable public{
        require(punch==1||punch==2||punch==3);
        require(msg.value==10**16);
        user = msg.sender;
        input = punch;
        uint N = 7;
        uint delay = 0;
        uint callbackGas = 200000; 
        oraclize_newRandomDSQuery(delay, N, callbackGas);
    }
    
}