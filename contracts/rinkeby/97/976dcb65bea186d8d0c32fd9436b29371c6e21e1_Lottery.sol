/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

    struct history//歷屆紀錄
    {
        address winner;//當屆贏家
        uint256 money;//當屆總投注金鶚
        uint256 p_num;//當屆投注人數
    }

    history[] private info;

    address[] private players;
    uint256 private bank;
    address public recentWinner;
    address private _owner;
    uint256 public entranceFee;
    

    modifier onlyOwner() 
    {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    enum LOTTERY_STATE 
    {
        OPEN, //開始
        PENDING,//結算中 
        CLOSED//結束
    }
    
    LOTTERY_STATE public lottery_state;

    constructor() 
    {
        lottery_state = LOTTERY_STATE.CLOSED;
        _owner = msg.sender;
    }

    function enter() external payable//player 投注
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "lottery closed");      
        require(msg.value >= entranceFee, "money < entrancefee"); 
        players.push (msg.sender);
        bank += msg.value ;
    }

    function startLottery( uint256 fee ) public onlyOwner
    {
        if(lottery_state != LOTTERY_STATE.OPEN)
            lottery_state = LOTTERY_STATE.OPEN;
        entranceFee=fee;
    }

    function endLottery( address charity ) public onlyOwner
    {
        //state check and change
        require(lottery_state == LOTTERY_STATE.OPEN, "lottery closed");
        lottery_state = LOTTERY_STATE.PENDING;

        //counting for the winner
        uint256 indexOfWinner = uint256(
            keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp) )
        ) % players.length; 
        recentWinner=players[indexOfWinner];

        //send money to player and charity
        (bool sent, ) = payable ( recentWinner ).call {value: ((bank*9)/10)} ("");
        require(sent, "Send failed.");
        (bool sent2, ) = payable ( charity ).call {value: ((bank*1)/10)} ("");
        require(sent2, "Send failed.");
        
        //save the data into history
        info.push(history({winner: recentWinner, money: bank, p_num: players.length}));
        
        //reset the varibles and state
        while(players.length>0)
            players.pop();
        lottery_state = LOTTERY_STATE.CLOSED;
        bank=0;
    }
    
    //get the informations 查詢某屆贏家的Address & 獲得金額 & 該屆投注人數
    function inquery_by_history( uint256 n ) public view
        returns ( address, uint256, uint256)
    {
        history storage h = info[n];
        uint256 m;
        m=h.money * 9;
        m=m / 10;
        return (h.winner, m, h.p_num);
    }

    //歷史開彩總次數
    function history_open_times() public view
        returns (uint256)
    {
        return (info.length);
    }

    //歷史總投注金額
    function history_money() public view
        returns (uint256)
    {
        uint256 m;
        for(uint256 i=0; i<info.length; i++)
        {
            history storage h = info[i];
            m+=h.money;
        }
        
        return m;
    }

    //歷史總投注人次
    function history_people() public view
        returns (uint256)
    {
        uint256 p;
        for(uint256 i=0; i<info.length; i++)
        {
            history storage h = info[i];
            p+=h.p_num;
        }
        
        return p;
    }

    function charity_money() public view
        returns (uint256)
    {
        uint256 m;
        for(uint256 i=0; i<info.length; i++)
        {
            history storage h = info[i];
            m+=h.money;
        }
        m=m/10;      
        return m;
    }
}