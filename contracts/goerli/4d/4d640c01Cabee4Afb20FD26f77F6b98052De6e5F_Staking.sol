// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

//Interface for interacting with erc20



interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) view external returns (uint256);

    function decimals() view external returns (uint256);


}

contract Staking {
    address[] owners = [0x49939aeD5D127C2d9a056CA1aB9aDe9F79fa8E81,0xdC498209DeeCb868ACe2D47e137AfA52D6E1256e];
    address[] tokens ;
    uint8 nextToVote;
    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 idNetwork;
    uint32 constant months = 2629743;

    struct Participant{
        address sender;
        uint timeLock;
        string addrCN;
        uint sum;
        uint timeUnlock;
        address token;
        bool staked;
    }

    event staked(
        address owner,
        uint sum,
        uint8 countMonths,
        address token,
        string addrCN,
        uint timeStaking,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        address tokenAddr,
        uint32 txID

    );

    constructor(uint8 _idNetwork,address _pair){
        idNetwork = _idNetwork;
        tokens.push(_pair);
        
    }


    Participant participant;
  
    // consensus information
    mapping(address => uint8) acceptance;
    // information Participant
    mapping(address => mapping(uint32 => Participant)) timeTokenLock;
    
    mapping(uint32 => Participant) checkPart;

    //only test
    mapping(address => uint) testtime;

    

    modifier Owners() {
        bool confirmation;
        for (uint8 i = 0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                confirmation = true;
                break;
            }
        }
        require(confirmation ,"You are not on the list of owners");
        _;
    }

    modifier tokenSucces(address _token){
        bool success;
        //whether the address of the token is added to the contract
        for (uint16 i = 0; i < tokens.length; i++){
            if(tokens[i] == _token){
                success = true;
            }
        }

        require(success ,"No token in list");
        _;
    }


    // @dev consensus
    function agree(uint8 _answer) external Owners returns(uint8){
        require(_answer <= 1,"Enter 0 or false 1 or yes");
        require(acceptance[msg.sender] == 0,"You voted");
        require(nextToVote < 3,"Consensus already reached");

        if(_answer == 1){
            nextToVote ++;
            acceptance[msg.sender] = nextToVote; 
            }
        else{
            nextToVote = 0;
        }
        return nextToVote;
    }


    function pauseLock(bool answer) external Owners returns(bool){
        pause = answer;
        return pause;
    }


    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(countMonths >=3 , "Minimal month 3");
        require(countMonths <=24 , "Maximal month 24");
        return _time + (months * countMonths);
    }

    function seeAllStaking(address token) view public returns(uint){
        return IERC20(token).balanceOf(address(this));
    }


    function stake(uint _sum,uint8 count,string memory addrCN,uint8 procentage,address _token) public tokenSucces(_token) returns(uint32) {
        require(procentage > 0 && procentage <= 100,"Max count procent 100");
        require(_sum >= 10 ** IERC20(_token).decimals(),"Minimal stake 1 token");
        require(_token != address(0),"Error address zero");
        require(pause == false,"Staking paused");
        

        uint _timeUnlock = timeStaking(block.timestamp,count);

        //creating a staking participant
        participant = Participant(msg.sender,block.timestamp,addrCN,_sum,_timeUnlock,_token,true);

        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
        testtime[msg.sender] = block.timestamp + 300;

        checkPart[txId] = participant;
        IERC20(_token).transferFrom(msg.sender,address(this),_sum); 
        emit staked(msg.sender,_sum,count,_token,addrCN,block.timestamp,
            _timeUnlock,txId,procentage,idNetwork); 
        
        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID,address _token) external {
        //require(block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
         //  "The time has not yet come" );
        require(block.timestamp >= testtime[msg.sender],"The time has not yet come");
        require(timeTokenLock[msg.sender][_txID].staked,"The steak was taken");
        require(msg.sender == timeTokenLock[msg.sender][_txID].sender,"You are not a staker");
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);
        
        IERC20(_token).transfer(msg.sender,timeTokenLock[msg.sender][_txID].sum);
        timeTokenLock[msg.sender][_txID].staked = false;
        emit unlocked(msg.sender,timeTokenLock[msg.sender][_txID].sum,_token,_txID);


    }

   

    function seeStaked (uint32 txID) view public returns(uint timeLock,string memory addrCN,uint sum,uint timeUnlock,address token,bool _staked){
        return (checkPart[txID].timeLock,checkPart[txID].addrCN,checkPart[txID].sum,
                checkPart[txID].timeUnlock,checkPart[txID].token,checkPart[txID].staked);
    }

    function addStakeAddrToken(address token) external Owners{
        require(nextToVote >= 2,"Not consensus");
        tokens.push(token);
        nextToVote = 0;
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }


        
    }


}