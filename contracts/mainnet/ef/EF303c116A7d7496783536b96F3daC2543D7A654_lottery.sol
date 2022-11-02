// SPDX-License-Identifier: UNLICENSED

/*
    DISCLAIMER:
    The programmer hired to produce this smart contract and the associated front-end
    code for this DApp, has built all of these in the capacity of a freelancer. This
    DApp project has been accepted by the programmer in good faith and shall not
    be held liable for any financial loss resulting from the use of this smart contract,
    or any related DApps, smart contracts, or activites originating from the client,
    The Lucky Rat token.
*/

pragma solidity ^0.8.0;

import "safemath_min.sol";
 
interface IERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
contract lottery is SafeMath {

    IERC20 _token;
    uint256 public minTokenBalance; // minimum token holdings required to participate
    
    uint8 public mode; // 0: pre-launch | 1: post-launch
    uint8 public status; // 1: active | 0: stopped | 2: game ended (locked forever)   

    uint8 public ticketsPerRound; // no of tickets to be sold per round
    uint8 public ticketsRemaining; // tickets remaining in current round. resets to ticketsPerRound
    uint256 public ticketPrice; // ticket price in wei

    uint256 public roundNo; // must be 1-based for simplicity
    uint256 public lastPreLaunchRound; // the roundNo up to which, the prizes are manually sent by team
    
    address internal deployer;
    address public owner;
    address public teamWallet;
    address public tokenAddress;

    uint8 public teamSharePct; // 33% | the rest goes to prizePool (67%)
    uint256 public totalRevenue; // total team earnings in wei

    uint256 public prizePool; // collected prize fund for the current round
    uint256 public totalPrizePoolTeam; // total prizePool sent to teamWallet during pre-launch mode
    
    struct player{
        uint256 totalWins;
        uint256 totalWinnings;
        uint256 totalTicketsBought;
        uint256 totalSpent;
    }
    mapping(address => player) public players;

    mapping(address => mapping(uint256 => uint8)) public ticketCount; // ticket counter per user per round
    // ticketCount[address][roundNo]=total tickets purchased

    struct ticket{
        address ticketOwner;
        uint256 ticketRoundNo;
    }

    mapping(uint256 => address) public winnerOf; // winnerOf[roundNo]=address

    mapping(uint256 => uint8) public winningTicketOf; // winningTicketOf[roundNo]=ticketNo

    mapping(uint256 => uint256) public winningPrizeOf; // winningPrizeOf[roundNo]=prizePool

    mapping(uint8 => ticket) public tickets; // 1-based
    // ticketOwner[ticketNo]=address;

    mapping(address => bool) public isAdmin;

    modifier adminOnly {
        require(isAdmin[msg.sender]==true);
        _;
    }

    modifier ownerOnly {
        require(msg.sender==owner);
        _;
    }
 
    constructor(){
        tokenAddress=address(0x0); // can be set after deployment
        _token=IERC20(tokenAddress);
        minTokenBalance=0;

        deployer=msg.sender;
        owner=0xA9De8967ea67E380f64D02b1de1f5A6a37466044;
        teamWallet=0xF6fb90bDee51895524a9586902aB465ccFe6927B;

        isAdmin[owner]=true;
        isAdmin[teamWallet]=true;
        isAdmin[msg.sender]=true;

        teamSharePct=33; // 67% goes to prizePpol

        ticketsPerRound=15; // 15
        ticketsRemaining=ticketsPerRound;
        ticketPrice=50000000000000000; // .05 ETH

        roundNo=1;
        lastPreLaunchRound=roundNo;

        mode=1;
        status=1;
    }

    function buyTickets(uint256 _quantity,uint256 nonce) public payable returns (bool success){
        // checks
        uint8 quantity=uint8(_quantity);
        updateNonce(nonce); // re-entrancy guard
        require(status==1,"Contract is stopped.");
        require(quantity>0,"Minimum quantity is 1.");
        require(ticketsRemaining>=quantity,"Not enough tickets to match quantity.");
        require(msg.value==mul(quantity,ticketPrice),"Not enough ETH sent.");
        if(tokenAddress!=address(0x0)){
            require(_token.balanceOf(msg.sender)>=minTokenBalance,"Address does not hold enough token balance to participate.");
        }

        // split value sent between teamWallet and prizePool
        uint256 teamShareETH=vxr(msg.value,teamSharePct,0x64);
        uint256 prizeShareETH=msg.value-teamShareETH;
        prizePool=add(prizePool,prizeShareETH);
        payable(teamWallet).transfer(teamShareETH); // forward team's share right away
        totalRevenue=add(totalRevenue,teamShareETH); // record totalRevenue

        ticketCount[msg.sender][roundNo]+=quantity; // add quantity to user's total tickets this round
        players[msg.sender].totalTicketsBought=add(players[msg.sender].totalTicketsBought,quantity);
        players[msg.sender].totalSpent=add(players[msg.sender].totalSpent,msg.value);

        for(uint8 i=0;i<quantity;i++){
            uint8 currentTicketNo=(ticketsPerRound-ticketsRemaining)+1;
            ticketsRemaining--;
            tickets[currentTicketNo].ticketOwner=msg.sender;
            tickets[currentTicketNo].ticketRoundNo=roundNo;
            /*
                if player1 bought 3 tickets:
                ticketsRemaining = 15
                currentTicketNo = (15-15)+1 = 1; ticketsRemaining = 14;
                currentTicketNo = (15-14)+1 = 2; ticketsRemaining = 13;
                currentTicketNo = (15-13)+1 = 3; ticketsRemaining = 12;
            */
        }

        if(ticketsRemaining==0){
            _int_c++;
            uint8 ticketNo=uint8(_int(1,ticketsPerRound));
            if(ticketNo<1 || ticketNo>ticketsPerRound) ticketNo=ticketsPerRound/2; // should never be possible, but is here for certainty
            require(tickets[ticketNo].ticketRoundNo==roundNo,"Ticket is not for current round."); // should never be possible, but is here for certainty
            address winner=tickets[ticketNo].ticketOwner;
            winnerOf[roundNo]=winner; // record winner for this round
            winningTicketOf[roundNo]=ticketNo; // record winning ticketNo for this round
            players[winner].totalWins=add(players[winner].totalWins,1); // record win stats for the player

            // prizePool
            uint256 _prizePool=prizePool;
            require(prizePool!=0,"Re-entrancy guard.");
            prizePool=0;
            
            if(mode==0){
                // prize funds are forwarded to teamWallet, to be converted to tokens as a prize
                winningPrizeOf[roundNo]=0; // tokens will be given
                totalPrizePoolTeam=add(totalPrizePoolTeam,_prizePool);
                payable(teamWallet).transfer(_prizePool); // withdraw the prize funds
            }
            if(mode==1){
                winningPrizeOf[roundNo]=_prizePool;
                players[winner].totalWinnings=add(players[winner].totalWinnings,_prizePool); // record winnings stats for the player
                payable(winner).transfer(_prizePool); // send the prize to winner
            }

            // round end, start the next
            if(mode==0){
                lastPreLaunchRound=roundNo;
            }
            
            ticketsRemaining=ticketsPerRound; // reset ticketsRemaining
            roundNo=add(roundNo,1); // next round is now active
        }

        return true;
    }

    // setters (admin)

    function setTokenAddress(address _tokenAddress) external adminOnly returns (bool success){
        tokenAddress=_tokenAddress;
        _token=IERC20(tokenAddress);
        return true;
    }

    function enablePostLaunchMode() external adminOnly returns (bool success){
        mode=1;
        return true;
    }

    function setStatus(uint8 _status) external adminOnly returns (bool success){
        require(status!=2,"Contract is locked by owner. Deploy a new contract to restart game.");
        require(_status<2,"Invalid status no.");
        status=_status;
        return true;
    }

    function setTeamSharePct(uint8 _teamSharePct) external adminOnly returns (bool success){
        require(_teamSharePct<=100,"Enter a value from 0 to 100");
        teamSharePct=_teamSharePct;
        return true;
    }

    function setTicketPrice(uint256 _ticketPriceWei) external adminOnly returns (bool success){
        require(_ticketPriceWei>0,"Must be greater than zero.");
        ticketPrice=_ticketPriceWei;
        return true;
    }

    function setTicketsPerRound(uint8 _ticketsPerRound) external adminOnly returns (bool success){
        require(status==0,"Contract must be paused.");
        require(ticketsRemaining==ticketsPerRound,"Can't change while there are live tickets.");
        require(_ticketsPerRound>=5,"Minimum 5 tickets.");
        require(_ticketsPerRound<=255,"Max 255 tickets (uint8).");
        require(_ticketsPerRound!=ticketsPerRound,"No change");
        if(_ticketsPerRound>ticketsPerRound){
            uint8 diff=_ticketsPerRound-ticketsPerRound;
            ticketsRemaining=ticketsRemaining+diff;
        }
        else{
            uint8 diff=ticketsPerRound-_ticketsPerRound;
            ticketsRemaining=ticketsRemaining-diff;
        }
        ticketsPerRound=_ticketsPerRound;        
        return true;
    }

    function setMinTokenBalance(uint256 _minTokenBalance) external adminOnly returns (bool success){
        require(tokenAddress!=address(0x0),"Set tokenAddress first");
        minTokenBalance=_minTokenBalance;
        return true;
    }

    // owner only functions

    function setAdmin(address _newAdmin) external ownerOnly returns (bool success){
        isAdmin[_newAdmin]=true;
        return true;
    }

    function unsetAdmin(address _oldAdmin) external ownerOnly returns (bool success){
        isAdmin[_oldAdmin]=false;
        return true;
    }

    function setOwner(address _newOwner) external ownerOnly returns (bool success){
        require(_newOwner!=deployer,"Not allowed.");
        owner=_newOwner;
        return true;
    }

    function setTeamWallet(address _teamWallet) external ownerOnly returns (bool success){
        teamWallet=_teamWallet;
        return true;
    }

    function endGame() external ownerOnly returns (bool success){
        require(status!=2,"Game already ended.");
        status=2;
        // withdraw all remaining balance to team wallet
        if(address(this).balance>0){
            payable(teamWallet).transfer(address(this).balance);
        }
        return true;
    }

    function withdraw() external ownerOnly returns (bool success){
        require(status==2,"Call endGame() first before using this function");
        require(address(this).balance>0,"Contract has no balance.");
        payable(teamWallet).transfer(address(this).balance);
        return true;
    }

    // getters

    function getWinner(uint256 _roundNo) external view returns (
        address _address,
        uint8 _ticketNo,
        uint256 prizeWon
    ){
        return (
            winnerOf[_roundNo],
            winningTicketOf[_roundNo],
            winningPrizeOf[_roundNo]
        );
    }

    function getPlayerStats(address _address) external view returns (
        uint256 _totalWins,
        uint256 _totalWinnings,
        uint8 _ticketCountThisRound,
        uint256 _totalTicketsBought,
        uint256 _totalSpent
    ){
        return (
            players[_address].totalWins,
            players[_address].totalWinnings,
            ticketCount[_address][roundNo],
            players[_address].totalTicketsBought,
            players[_address].totalSpent
        );
    }

    function getGameStats() external view returns (
        uint8 _mode,
        uint8 _status,
        uint256 _roundNo,
        uint8 _ticketsPerRound,
        uint8 _ticketsRemaining,
        uint256 _ticketPrice,
        uint8 _teamSharePct,
        uint256 _lastPreLaunchRound,
        address _lastWinner,
        uint256 _lastWinningTicket,
        uint256 _minTokenBalance,
        address _tokenAddress
    ){
        return (
            mode,
            status,
            roundNo,
            ticketsPerRound,
            ticketsRemaining,
            ticketPrice,
            teamSharePct,
            lastPreLaunchRound,
            winnerOf[roundNo-1],
            winningTicketOf[roundNo-1],
            minTokenBalance,
            tokenAddress
        );
    }

}