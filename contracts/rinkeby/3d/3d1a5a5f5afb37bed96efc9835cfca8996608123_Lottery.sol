/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// File: project/final_project.sol



pragma solidity ^0.8.10;



contract Lottery {



    struct FeeData{

        uint256 fee;

        bool isExist;

    }



    struct History{

        address winner;

        uint256 winnerPrice;

        address charity;

        uint256 charityPrice;

        uint256 playerNumber;

    }



    enum State {

        IDLE,

        RUNNING,

        PENDING

    }



    State public state;

    mapping (address => FeeData) public players;

    mapping (address => FeeData) public charityTotal;

    address[] public playersAddr;

    address public recentWinner;

    address private owner_;

    address private charity_;

    uint256 public playerNumber;

    uint256 public entranceFee;

    uint256 public total;

    //history variables

    uint256 public historyDraw;

    uint256 public historyPlayerNum;

    uint256 public historyTotal;

    History[] public history;

    mapping (address => uint256[]) public historyCharityWithdraw;





    constructor() {

        state = State.IDLE;

        delete playersAddr;

        recentWinner = address(0x0);

        owner_ = msg.sender;

        charity_ = address(0x0);

        playerNumber = 0;

        entranceFee = 0;

        total = 0;

        historyDraw = 0;

        historyPlayerNum = 0;

        historyTotal = 0;

        delete history;

    }



    modifier onlyOwner(){

        require(msg.sender == owner_, "Error: Permission denied.");

        _;

    }



    function enter() public payable {

        require(state == State.RUNNING, "Error: The lottery is not available now");

        require(msg.value >= entranceFee, "Error: The fee you pay isn't enough!");

        total += msg.value;

        if(players[msg.sender].isExist){

            players[msg.sender].fee += msg.value;

        } 

        else{

            players[msg.sender] = FeeData(msg.value, true);

            playersAddr.push(msg.sender);

            ++playerNumber;

        }

    }



    function startLottery(uint256 entryFee, address charity) public onlyOwner {

        require(state == State.IDLE, "Error: The lottery is already running");

        state = State.RUNNING;

        charity_ = charity;

        entranceFee = entryFee;

    }



    function endLottery() public onlyOwner returns (address winnerAddr, uint256 winnerPrice) {

        require(state == State.RUNNING, "Error: The lottery is no longer running");

        require(total != 0, "Error: There is no player!");

        state = State.PENDING;

        uint256 rdm = uint256(

            keccak256(

                abi.encodePacked(msg.sender, block.difficulty, block.timestamp)

            )

        ) % total;

        for(uint256 i = 0;i < playerNumber;++i){

            address nowAddr = playersAddr[i];

            if(rdm < players[nowAddr].fee){

                winnerAddr = nowAddr;

                break;

            }

            rdm -= players[nowAddr].fee;

        }

        uint256 charityPrice = total/10;

        winnerPrice = total-charityPrice;

        if(charityTotal[charity_].isExist){

            charityTotal[charity_].fee += charityPrice;

        }

        else{

            charityTotal[charity_] = FeeData(charityPrice, true);

        }

        (bool sent, ) = winnerAddr.call{value: winnerPrice}("");

        require(sent, "Error: Pending failed!");

        

        //history record

        ++historyDraw;

        historyPlayerNum += playerNumber;

        historyTotal += total;

        history.push(History(winnerAddr, winnerPrice, charity_, charityPrice, playerNumber));



        recentWinner = winnerAddr;

        state = State.IDLE;

        total = 0;

        playerNumber = 0;

        for(uint256 i = 0;i < playerNumber;++i){

            delete players[playersAddr[i]];

        }

        delete playersAddr;

    }



    function charityWithdraw() public {

        require(charityTotal[msg.sender].isExist, "Error: You are not charity!");

        require(charityTotal[msg.sender].fee != 0, "Error: You don't have any price to withdraw");

        (bool sent, ) = msg.sender.call{value: charityTotal[msg.sender].fee}("");

        require(sent, "Error: Withdraw failed!");

        historyCharityWithdraw[msg.sender].push(charityTotal[msg.sender].fee);

        charityTotal[msg.sender].fee = 0;

    }



    function getAddrTotalPrice(address addr) public view returns (uint256 totalPrice){

        totalPrice = 0;

        for(uint256 i = 0;i < historyDraw;++i){

            if(history[i].winner == addr) totalPrice += history[i].winnerPrice;

            if(history[i].charity == addr) totalPrice += history[i].charityPrice;

        }

    }

}