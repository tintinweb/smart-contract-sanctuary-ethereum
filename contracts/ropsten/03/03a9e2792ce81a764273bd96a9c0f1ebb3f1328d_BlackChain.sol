pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BlackChain {
    using SafeMath for uint256;

    uint256 public costPerTicket = 5000000000000000;    // Init with 0.005 ETH per bet
    uint256 public maxCost = 30000000000000000;         // Price increase every 7 days until 0.03 ETH
    // test 2.0
    // uint256 constant public expireDate = 1543622400;    // Contract refused to get any more bets after Dec 1, 2018
    uint256 constant public expireDate = 1533027600;

    bool public confirmed;
    bool public announced;
    bool public readyToPay;
    bool public gameOver;
    bool public locked;
    bool private developmentPaid;
    uint private i;

    uint256 public startDate;
    address public owner;
    address public leader;
    address public leader_2;
    address public leader_3;
    uint256 public announcedTimeStamp;
    uint256 public rewardPool;
    uint256 public confirmreward;               // Help us confirm when the man die and get a total of 5% ETH reward
    uint256 public init_fund;

    uint256 public countConfirmed = 0;
    uint256 public countPlayer = 0;
    uint256 public countBet = 0 ;
    uint256 public countWinners = 0;
    uint256 public countSecondWinners = 0;

    uint256 public averageTimestamp;

    uint256 public numOfConfirmationNeeded;
    uint256 private tmp_error;
    uint256 private min_error_2 = 86400000;
    uint256 private min_error = 86400000;
    uint256 private share = 0;

    uint256 public winnerTimestamp = 0;
    uint256 public secondWinnerTimestamp =0;
    uint256 countWeek;


    constructor() payable public {
        owner = msg.sender;
        leader = msg.sender;
        leader_2 = msg.sender;
        leader_3 = msg.sender;
        countWeek = 1;
        numOfConfirmationNeeded =3;
        startDate = now;
        rewardPool = msg.value;
        init_fund = msg.value;
        announced = false;
        confirmed = false;
        readyToPay = false;
        gameOver = false;
        locked = false;
    }

    mapping(uint256 => address[]) mirrors ;

    uint256[] public timestampList;


    mapping(address => bool) public isPlayer;
    mapping(address => bool) public hasConfirmed;
    mapping(address => uint256[]) public betHistory;
    mapping(address => uint256) public playerBets;
    mapping(address => address) public referral;
    mapping(address => uint256) public countReferral;


    event Bet(uint256 bets, address indexed player);
    event Confirm(address player);
    event Payreward(address indexed player, uint256 reward);

    function bet(uint256[] _timestamps, address _referral) payable public{
        require(msg.value>=costPerTicket.mul(_timestamps.length));
        require(!announced);

        if(now < expireDate){
            for(i=0; i<_timestamps.length;i++){
                timestampList.push(_timestamps[i]);
                mirrors[_timestamps[i]].push(msg.sender);

                betHistory[msg.sender].push(_timestamps[i]);

                averageTimestamp = averageTimestamp.mul(countBet) + _timestamps[i];
                averageTimestamp = averageTimestamp.div(countBet+1);
                countBet ++;
                playerBets[msg.sender]++;
            }

            if(isPlayer[msg.sender]!=true){
                countPlayer++;
                isPlayer[msg.sender]=true;
                referral[msg.sender]=_referral;
                countReferral[_referral]+=1;
            }

            if(playerBets[msg.sender]>playerBets[leader]){
                leader_3 = leader_2;
                leader_2 = leader;
                leader = msg.sender;
            }else if(playerBets[msg.sender]>playerBets[leader_2]){
                leader_3 = leader_2;
                leader_2 = msg.sender;
            }else if(playerBets[msg.sender]>playerBets[leader_3]){
                leader_3 = msg.sender;
            }

            rewardPool=rewardPool.add(msg.value);
            owner.transfer(msg.value.mul(12).div(100)); // Developement Team get 12% on every transfer
            emit Bet(_timestamps.length, msg.sender);
        }else{
            if(!locked){
                locked=true;
            }
            owner.transfer(msg.value);
        }
        // Increase Ticket Price every week
        // if(startDate.add(countWeek.mul(604800)) < now ){
        if(startDate.add(countWeek.mul(3600)) < now ){
            countWeek++;
            if(costPerTicket < maxCost){
                costPerTicket=costPerTicket.add(5000000000000000);
            }
        }
    }

    function payLeaderAndDev() public {
        require(locked || announced);
        require(!developmentPaid);
        // Send 12% of the original fund back to owner
        owner.transfer(init_fund.mul(12).div(100));

        // Send 8% of all rewardPool to Leaderboard winners
        leader.transfer(rewardPool.mul(4).div(100));
        leader_2.transfer(rewardPool.mul(25).div(1000));
        leader_3.transfer(rewardPool.mul(15).div(1000));
        developmentPaid = true;
    }


    function getBetsOnTimestamp(uint256 _timestamp)public view returns (uint256){
        return mirrors[_timestamp].length;
    }

    function announce(uint256 _timestamp) public {
        require(msg.sender == owner);
        announced = true;
        announcedTimeStamp = _timestamp;
        //5% of total rewardPool goes as confirmreward
        confirmreward = rewardPool.mul(5).div(100).div(numOfConfirmationNeeded);
    }

    function confirm() public{
        require(announced==true);
        require(confirmed==false);
        require(isPlayer[msg.sender]==true);
        require(hasConfirmed[msg.sender]!=true);

        countConfirmed += 1;
        hasConfirmed[msg.sender] = true;

        msg.sender.transfer(confirmreward);
        emit Confirm(msg.sender);
        emit Payreward(msg.sender, confirmreward);

        if(countConfirmed>=numOfConfirmationNeeded){
            confirmed=true;
        }
    }

    function defineWinner() public{
        require(confirmed);
        for(i=0; i<timestampList.length; i++ ){

            if(timestampList[i]==winnerTimestamp || timestampList[i]==secondWinnerTimestamp){
                continue;
            }

            if(timestampList[i] >= announcedTimeStamp){
                tmp_error = timestampList[i].sub(announcedTimeStamp);
            }
            else{
                tmp_error = announcedTimeStamp.sub(timestampList[i]);
            }

            if( tmp_error < min_error){
                min_error_2 = min_error;
                min_error = tmp_error;
                secondWinnerTimestamp = winnerTimestamp;
                winnerTimestamp = timestampList[i];
            }
            else if(tmp_error < min_error_2){
                min_error_2 = tmp_error;
                secondWinnerTimestamp = timestampList[i];
            }
        }
        countWinners = mirrors[winnerTimestamp].length;
        countSecondWinners = mirrors[secondWinnerTimestamp].length;
        readyToPay = true;
    }

    function payWinners() public{
        require(readyToPay);
        require(!gameOver);
        // Send ETH(50%) to first prize winners
        share = rewardPool.div(2);
        share = share.div(countWinners);
        for(i=0; i<countWinners; i++){
            mirrors[winnerTimestamp][i].transfer(share.mul(9).div(10));
            referral[mirrors[winnerTimestamp][i]].transfer(share.mul(1).div(10));
            emit Payreward(mirrors[winnerTimestamp][i], share);
        }

        // Send ETH(25%) to second Winners
        share = rewardPool.div(4);
        share = share.div(countSecondWinners);
        for(i=0; i<countSecondWinners; i++){
            mirrors[secondWinnerTimestamp][i].transfer(share.mul(9).div(10));
            referral[mirrors[secondWinnerTimestamp][i]].transfer(share.mul(1).div(10));
            emit Payreward(mirrors[secondWinnerTimestamp][i], share);
        }

        // Bye Guys
        gameOver = true;
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function () public payable {
         owner.transfer(msg.value);
     }
}