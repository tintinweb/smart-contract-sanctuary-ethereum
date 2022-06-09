/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: tests/final_project2.sol


pragma solidity ^0.8.10;

contract lottery2 {
    // Store information of different time's lottery.
    struct Info {
        address winner;
        uint256 Awards;
        uint256 Numofplayer;
    }
    // Store the total number information of the lottery.
    struct History{
        uint256 Total_sum_of_awards;    
        uint256 Total_num_of_players;
        uint256 Total_times_of_Lottery;
    }
    History history;

    uint total_times_of_Lottery = 0;
    uint withdraw_times = 0;
    address payable[] public players;
    address public recentWinner;
    address public charityaddress;
    address private _owner;
    uint256 private entranceFee;

    // 紀錄每次lottery 的資訊：winner , awards, player number.
    mapping (uint256=>Info) private info;
    // 儲存慈善機構提款紀錄
    mapping (uint256=>uint256) private charity_record;


    // 建立onlyOwner的modifier
    modifier onlyOwner(){
        require(msg.sender == _owner,"You are not the owner, byebye");
        _;
    }
    // 定義enum
    enum State {Started, Closed, Calculating}
    State state;
    // 建立 constructor
    constructor(){
        state = State.Started;
        _owner = msg.sender;
    }
    //由owner 將lottery 打開，並且設定entrance fee
    function startLottery(uint256 _entranceFee) public onlyOwner{
        if( state == State.Closed) state = State.Started;
        entranceFee = _entranceFee;
    }
    //由owner 設定 Charity 的位址
    function setcharity(address _charityaddress) public onlyOwner{
        charityaddress = _charityaddress;
    }

    // 使Player 可以參加lottery.
    function enter() public payable {
        require(state == State.Started,"The lottery is not available now.");
        require(msg.value == entranceFee,"Your lottery is less than entranceFee, sorry.");
        players.push(payable(msg.sender));
    }


    // Get the Entrance Fee in this time's Lottery 
    function EntraneFee() public view returns(uint256){
        return entranceFee;
    }
    // Get the Number of player in this time's Lottery
    function NumofPlayer() public view returns(uint256){
        return players.length;
    }
    function Total_data()public view returns(uint256 Total_player, uint256 Total_awards, uint256 Total_times_lottery){
        return(history.Total_num_of_players,history.Total_sum_of_awards,history.Total_times_of_Lottery);
    }
    function Charity_record(uint id) public view returns(uint256){
        return charity_record[id];
    }
    // return some information of a pecific times of lottery. return winner address, awards, number of player.
    function History_data(uint256 id) public view returns(address winner,uint256 Awards,uint256 Numofplayer){
        Info memory p = info[id];
        return(p.winner, p.Awards, p.Numofplayer);
    }

    // 結束lottery 除了將獎金transfer 給winner 以外，同時將本次的lottery資料更新到歷史資料上
    event Winner(address _winner);
    function endLottery() public onlyOwner{
        require(state == State.Started,"The lottery doesn't open.");
        require(players.length != 0,"There is no player in this turn of lottery.");
        state = State.Calculating;
        uint256 indexOfWinner = uint256( keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        recentWinner = players[indexOfWinner];
        // To upload this time's winner, awards, and number of player into storage.
        info[total_times_of_Lottery].winner = recentWinner;
        info[total_times_of_Lottery].Awards = address(this).balance*90/100;
        info[total_times_of_Lottery].Numofplayer = players.length;
        total_times_of_Lottery++;

        // To upload the Total number of players, sum of awards, times of lottery.
        history.Total_num_of_players += players.length;
        history.Total_sum_of_awards += address(this).balance*90/100;
        history.Total_times_of_Lottery ++;

        payable(recentWinner).transfer(address(this).balance*90/100);
        charity_record[withdraw_times] = address(this).balance;
        payable(charityaddress).transfer(address(this).balance);
        withdraw_times++;
        
        emit Winner(recentWinner);
        players = new address payable[](0);
        entranceFee = 0;
        state = State.Closed;
    }
}