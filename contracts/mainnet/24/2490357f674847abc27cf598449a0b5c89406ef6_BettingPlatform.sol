/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

//SPDX-License-Identifier: Copyright Grobat
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract BettingPlatform {
    struct Bet{
        address betterWallet;
        uint amount;
        uint amountPaid;
        uint gameID;
        bool hasBeenPaid;
    }

    struct Sportsmatch{
        string team1Name;
        string team2Name;
        uint winnerNumber;
        uint starttime;
        uint taxPercent;
        uint totalPool;
        uint totalAbets;
        uint totalBBets;
        bool isresolved;
        bool canCollect;
        uint ratio;
    }

    struct UserBet {
        uint id;
        string teamName;
        bool wasWinner;
        bool isPaid;
    }

    mapping(uint => Sportsmatch) public games;
    mapping(address => mapping(uint => Bet))public userBets;
    mapping(address => mapping(uint => bool))public userBetOnMatch;
    mapping(address => uint[]) public userMatchBets;
    mapping(address => Bet[]) public userWinningBets;
    mapping(address => Bet[]) public userLosingBets;
    mapping(uint => Bet[])public teamABets;
    mapping(uint => Bet[])public teamBBets;
    mapping(address => uint)public balances;
    mapping(address => uint)public totalUserBet;
    mapping(address => uint)public totalUserWin;
    mapping(address => bool) public admins;

    address public owner;
    address public feeReciever;
    uint public amountOfGames = 0;

    event userDepositted(address indexed user, uint amount);
    event userWithdrew(address indexed user, uint amount);

    modifier onlyAdmin(){
        require(admins[msg.sender], "Sorry guys, only the admins can call this function");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Sorry guys, only the owner can call this function");
        _;
    }

    constructor(address[] memory _admins){
        for(uint i = 0; i < _admins.length; i++){
            admins[_admins[i]] = true;
        }
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addGame(string calldata team1Name, string calldata team2Name, uint startTime, uint taxpercent)external onlyAdmin{
        require(taxpercent <= 10, "Max tax is 10%");
        Sportsmatch memory game = Sportsmatch(
            team1Name,
            team2Name,
            0,
            startTime,
            taxpercent,
            0,
            0,
            0,
            false,
            false,
            0
        );
        
        games[amountOfGames] = game;
        amountOfGames++;
    }

    function makeABet(uint gameID, uint team, uint amount)public{
        require(games[gameID].starttime >= block.timestamp,"cant make a bet after the match starts");
        require(balances[msg.sender] >= amount, "Your balance is too low");
        require(!userBetOnMatch[msg.sender][gameID], "CanOnly bet once sir");

        userBetOnMatch[msg.sender][gameID] = true;
        userMatchBets[msg.sender].push(gameID);
        balances[msg.sender] -= amount;
        totalUserBet[msg.sender] += amount;
        if(games[gameID].taxPercent > 0){
            uint taxamount = amount * games[gameID].taxPercent /100;
            balances[feeReciever] += taxamount;
            amount -= taxamount;
        }
        games[gameID].totalPool += amount;
        Bet memory bet;
        bet.betterWallet = msg.sender;
        bet.amount = amount;
        bet.gameID = gameID;
        string memory teamname;
        if(team == 1){
            games[gameID].totalAbets += amount;
            teamABets[gameID].push(bet);
            teamname = games[gameID].team1Name;
        }else{
            games[gameID].totalBBets += amount;
            teamBBets[gameID].push(bet);
            teamname = games[gameID].team2Name;
        }
        userBets[msg.sender][gameID]=bet;
    }

    function deposit()public payable{
        balances[msg.sender] += msg.value;
        emit userDepositted(msg.sender, msg.value);
    }

    function withdraw(uint amount)public{
        require(balances[msg.sender] >= amount, "you cannot withdraw more than you have");
        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
        emit userWithdrew(msg.sender, amount);
    }

    function getBetsLength(address user)public view returns (uint BetLength){
        return userMatchBets[user].length;
    }

    function getUserMatchBets(address user)public view returns(uint[] memory matchBets){
        return userMatchBets[user];
    }

    function addAdmin(address newAdmin)external onlyOwner() {
        admins[newAdmin] = true;
    }

    function removeAdmin(address admin)external onlyOwner() {
        admins[admin] = false;
    }

    function setFeeReciever(address reciever)external onlyOwner(){
        feeReciever = reciever;
    }

    function distributeBalance()external onlyAdmin {
        uint amount = balances[feeReciever];
        payable(feeReciever).transfer(amount);
        balances[feeReciever] -= amount;
    }

    function getGameBetStats(uint gameID)public view returns(uint length_team_A, uint length_Team_B){
        return(teamABets[gameID].length, teamBBets[gameID].length);
    }

    function getGameBets(uint gameID)public view returns(Bet[] memory _teamABets, Bet[] memory _teamBBets){
        return(teamABets[gameID], teamBBets[gameID]);
    }

    function getPercentage(uint numerator, uint denominator) internal pure returns (uint){
        uint _numerator  = numerator * 1000;
        return _numerator/denominator + 1000;
    }

    function resolveGame(uint game, uint team, bool isdraw)external onlyAdmin {
        // here we get the team and set its stats final
         require(team == 1 || team == 2, "must give a valid team number");
         require(!games[game].isresolved, "Cannot process the same number twice");
         if(!isdraw){
            games[game].winnerNumber = team;
            Bet[] memory winningTeamBets;
            
            Bet[] memory losingTeamBets;
            uint percentage = 0;       
            if(team == 1){
                winningTeamBets = teamABets[game];
                losingTeamBets = teamBBets[game];
                percentage = getPercentage(games[game].totalBBets , games[game].totalAbets );
            }else{
                losingTeamBets = teamABets[game];
                winningTeamBets = teamBBets[game];
                percentage = getPercentage(games[game].totalAbets , games[game].totalBBets );
            }
            uint amountToPay;
            for(uint i = 0; i < winningTeamBets.length; i++){
                amountToPay = (winningTeamBets[i].amount * percentage)/1000;
                balances[winningTeamBets[i].betterWallet] += amountToPay;
                winningTeamBets[i].hasBeenPaid = true;
                winningTeamBets[i].amountPaid = amountToPay;
                //winningTeamBets[i].gameID = game;
                userWinningBets[winningTeamBets[i].betterWallet].push(winningTeamBets[i]);
                totalUserWin[winningTeamBets[i].betterWallet] += amountToPay;
                userBets[winningTeamBets[i].betterWallet][game] = winningTeamBets[i];
            }
            for(uint i = 0; i < losingTeamBets.length; i++){
                losingTeamBets[i].hasBeenPaid = true;
                losingTeamBets[i].amountPaid = 0;
                losingTeamBets[i].gameID = game;
                userLosingBets[losingTeamBets[i].betterWallet].push(losingTeamBets[i]);
                userBets[losingTeamBets[i].betterWallet][game] = losingTeamBets[i];
            }
         }else{
             games[game].winnerNumber == 0;
             for(uint i = 0; i < teamABets[game].length; i++){
                balances[teamABets[game][i].betterWallet] += teamABets[game][i].amount;
                teamABets[game][i].hasBeenPaid = true;
                teamABets[game][i].amountPaid = teamABets[game][i].amount;
                userWinningBets[teamABets[game][i].betterWallet].push(teamABets[game][i]);
                totalUserWin[teamABets[game][i].betterWallet] += teamABets[game][i].amount;
                userBets[teamABets[game][i].betterWallet][game] = teamABets[game][i];
             }
             for(uint i = 0; i < teamBBets[game].length; i++){
                balances[teamBBets[game][i].betterWallet] += teamBBets[game][i].amount;
                teamBBets[game][i].hasBeenPaid = true;
                teamBBets[game][i].amountPaid = teamBBets[game][i].amount;
                userWinningBets[teamBBets[game][i].betterWallet].push(teamBBets[game][i]);
                totalUserWin[teamBBets[game][i].betterWallet] += teamBBets[game][i].amount;
                userBets[teamBBets[game][i].betterWallet][game] = teamBBets[game][i];
             }
         }
         games[game].isresolved = true;
    }

    function getCurrentOdds(uint game)external view returns(uint teamAPercentage, uint teamBPercentage){
        uint toatalAbets = games[game].totalAbets;
        uint totalBBets = games[game].totalBBets;
        return(getPercentage(totalBBets, toatalAbets), getPercentage(toatalAbets, totalBBets));
    }

}