/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0

/*
    Requirements
    - Only the team can deposit rewards.
    - Deposited rewards go to the pool of users, not to individual users.
    - Users should be able to withdraw their deposits along with their share of rewards considering the time when they deposited.
*/

pragma solidity >=0.7.0 <0.9.0;

contract ETHpool {
    //team auth
    mapping (address => uint) private teams;
    mapping (address => bool) private inTeam;

    //deposit by users pointerRewards => total deposits
    mapping (uint => int) public totalDepositsByIndex;
    mapping (uint => int) public totalWhitdrawByIndex;
    //manage with pointerRewards
    depositHistory[] public poolRewardsHistory;
    int public balanceRewards;
    int public balancePool;

    address owner;
    //control deposit user => value.
    mapping (address => depositUserHistory[]) public depositUsersHistory;
    //show actually balance by user account user => balance
    mapping (address => int) public depositUserBalance;
    //show last pointerRewards has claimed
    mapping (address => uint) public lastIndexClaimUser;

    struct depositHistory{
        int cantRewards;
        int totalPool;
    }

    struct depositUserHistory{
        uint index;
        int balance;
    }

    //the pointer save last position rewards
    uint public pointerRewards;

    constructor(){
        pointerRewards = 0;
        balanceRewards = 0;
        inTeam[msg.sender] = true;
        owner = msg.sender;
    }
    //event NewEvent(uint id, string name , uint cantTokenMax, uint price, uint dateOff, uint dateEvent);
    
    function getCantBalanceByIndex(address _user, uint _index) view public returns(int,bool,uint) {
        int balance = 0;
        bool findIt = false; 
        uint iRet=0;
        if (_index<=depositUsersHistory[_user].length){
            for(uint i = 0; i<depositUsersHistory[_user].length && !findIt; i++){
                if (depositUsersHistory[_user][i].index == _index){
                    balance = depositUsersHistory[_user][i].balance;
                    findIt = true; 
                } 
            }
        }
        return (balance,findIt,iRet);
    }
    function getCantRewardsAvailable(address _user) view public returns(int) {
        require(depositUsersHistory[_user].length>0,"not deposit for this user");
        int cantRewards = 0;
        uint lastIndexClaim = lastIndexClaimUser[_user];
        int balance = 0;
        int balanceGen = 0;
        int balanceDeposits = 0;
        for(uint i=0; i<pointerRewards; i++){
            (balanceGen,,) = getCantBalanceByIndex(_user,i);
            balanceDeposits += totalDepositsByIndex[i]-totalWhitdrawByIndex[i];
        
            balance += balanceGen;
            if (lastIndexClaim <=i){
                cantRewards += (balance*poolRewardsHistory[i].cantRewards)/balanceDeposits; 
            }
            
        }

        return cantRewards;
    }
    
    function reStake() public{
        int pendingRewards = getCantRewardsAvailable(msg.sender);
        if(pendingRewards > 0){
            lastIndexClaimUser[msg.sender] = pointerRewards;
            balanceRewards -= pendingRewards;
            
            (bool ok) = addDeposit(uint(pendingRewards),msg.sender);
            require(ok,"error reStake deposit");
            emit claimedRewards(msg.sender, pendingRewards); 
        }
    }
    function claimRewards() public  {
       //require(pools[msg.sender].amaunt>0);
        int pendingRewards = getCantRewardsAvailable(msg.sender);
        if(pendingRewards > 0){
            lastIndexClaimUser[msg.sender] = pointerRewards;
            balanceRewards -= pendingRewards;
            (bool success, ) = msg.sender.call{value:uint(pendingRewards)}("");
            require(success, "Transfer failed.");

            emit claimedRewards(msg.sender, pendingRewards);
        }
    }

    function whitdrawDeposit(int _amaunt) payable external{
        require(depositUserBalance[msg.sender] >= _amaunt,"not have funds");
        claimRewards();
        balancePool -= _amaunt;
        depositUserBalance[msg.sender] -= _amaunt;
        totalWhitdrawByIndex[pointerRewards] += _amaunt;
        (, bool findIt, uint i) = getCantBalanceByIndex(msg.sender,pointerRewards);
        if (findIt){
            depositUsersHistory[msg.sender][i].balance -= _amaunt;
        }else{
            depositUsersHistory[msg.sender].push(depositUserHistory({balance:(-1*_amaunt), index:pointerRewards}));
        }
        (bool success, ) = msg.sender.call{value:uint(_amaunt)}("");
        require(success, "Transfer failed.");

        emit userWhitdraw(msg.sender,_amaunt);
    }

    function addDeposit(uint _amaunt, address _sender) private returns(bool) {
        require(_amaunt > 0,"Deposit amount error");
        balancePool += int(_amaunt);
        totalDepositsByIndex[pointerRewards] += int(_amaunt);
        (, bool findIt, uint i) = getCantBalanceByIndex(_sender,pointerRewards);
        if (findIt){
            depositUsersHistory[_sender][i].balance += int(_amaunt);
        }else{
            depositUsersHistory[_sender].push(depositUserHistory({balance:int(_amaunt), index:pointerRewards}));
        }
        
        depositUserBalance[_sender] += int(_amaunt); 
        emit userDeposit(_sender,int(_amaunt),pointerRewards);

        return true;
    }
    function addDepositInPool() payable external{
        addDeposit(msg.value,msg.sender);
    }

    function addRewards() public payable isInTeam{
       require(msg.value > 0,"Deposit amount error");
       poolRewardsHistory.push(depositHistory({cantRewards: int(msg.value),totalPool:totalDepositsByIndex[pointerRewards]}));
       pointerRewards +=1;
       balanceRewards += int(msg.value);
       emit newRewards(int(msg.value));
    }

    //team set
    function addToTeam(address newInTeam) isInTeam public {
        inTeam[newInTeam] = true;
    }

    function removeToTeam(address _user) onlyOwner public {
        inTeam[_user] = false;
    }

    modifier isInTeam() {
        require(inTeam[msg.sender]);
        _;
    }
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    

    event userDeposit(address,int,uint);
    event newRewards(int);
    event claimedRewards(address, int);
    event userWhitdraw(address, int);
}