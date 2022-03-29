// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

contract RandomNumberBettingContract {
    
    struct PlayerData {
        address user;
        uint256 total;
        uint256[8] bettedAmount;
    }

    PlayerData[] internal players;

    mapping(address => uint256) internal userId;
    mapping(address => uint256) internal _balance;
    mapping(address => uint256) private _allowance;

    address private owner;
    address[] private args;

    uint bettingState = 0;

    uint256 durationOfBetting = 10 minutes;
    uint256 durationOfDelay = 3 minutes;

    uint256 totalBettedAmount;
    uint256 historicalNumberOfUser;

    uint256 startTimeOfBetting;
    uint256 endTimeOfBetting;
    uint256[8] bettedAmountForEachNumber;

    IBEP20 tokenContract;
    address tokenAddress = address(0x46e3d7122B956Ac546bA297E408a5Db0AD8912f8);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        historicalNumberOfUser = 0;
        tokenContract = IBEP20(tokenAddress);
    }

    function setBettingTime(uint256 _timeOfBetting) public onlyOwner {
        durationOfBetting = _timeOfBetting;
    }

    function setDelayTime(uint256 _timeOfDelay) public onlyOwner {
        durationOfDelay = _timeOfDelay;
    }

    function setTokenAddress(address _newAddress) public onlyOwner {
        tokenAddress = _newAddress;
        tokenContract = IBEP20(tokenAddress);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function getOwner() public  view returns(address) {
        return owner;
    }

    function getEndTime() public view returns(uint256) {
        return endTimeOfBetting;
    }

    function getTotalAmount() public view returns (uint256) {
        return address(this).balance;    
    }

    function getBettingData() public view returns (uint256, uint256, uint256) {
        uint256 countOfPlayer;
        countOfPlayer = players.length - 1;
        if(countOfPlayer < 0) {
            countOfPlayer = 0;
        }
        return ( countOfPlayer, historicalNumberOfUser, totalBettedAmount );
    }

    function getDurationOfBetting() public view returns (uint256) {
        return durationOfBetting;
    }

    function getBettingState() public view returns (uint) {
        return bettingState;
    }
	
	// This function init all state
    function initState() internal {
        totalBettedAmount = 0;

        for(uint256 i = 1; i < players.length; i ++) {
            delete userId[players[i].user];
        }
        for(uint256 i = 0; i < 8; i ++) {
            bettedAmountForEachNumber[i] = 0;
        }

        delete players;
        delete args;
        players.push();
    }

    function _startBetting() internal {
        initState();
        bettingState = 1;
        startTimeOfBetting = block.timestamp;
        endTimeOfBetting = startTimeOfBetting + durationOfBetting;
    }

    function startBetting() public onlyOwner {
        require(bettingState != 1, "Betting is already started");

        if(bettingState == 2) {
            require(block.timestamp > endTimeOfBetting, "Can't start now");
        }

        _startBetting();
    }

    function _stopBetting() internal {
        bettingState = 2;
        endTimeOfBetting = block.timestamp + durationOfDelay;
        payout();
    }
	
    function stopBetting() public onlyOwner{
        require(bettingState == 1, "Betting has not started yet");
        require(block.timestamp > endTimeOfBetting,"Can't stop now.");

        _stopBetting();
    }

    // User can bet for 6 days. After 6 days, bet is stopped.
    function bet(uint256 number, uint256 amount) public {
        require(bettingState == 1, "Betting isn't started yet.");
        require(block.timestamp < endTimeOfBetting, "Can't bet now.");

        tokenContract.transferFrom(msg.sender, address(this), amount);

        uint256 _userId;
        _userId = userId[msg.sender];

        if(_userId == 0) {
            _userId = players.length;
            players.push();

            PlayerData memory newplayer;
            newplayer.user = msg.sender;

            players[_userId] = newplayer;
            args.push(msg.sender);
            historicalNumberOfUser += 1;
        }

        players[_userId].bettedAmount[number] += amount;
        players[_userId].total += amount;
        bettedAmountForEachNumber[number] += amount;
        userId[msg.sender] = _userId;
        totalBettedAmount += amount;
    }

    function balanceOf() public view returns(uint256) {
        return _balance[msg.sender];
    }

    function claimToken() public returns(uint256) {
        require(_balance[msg.sender] != 0, "Your balance is zero");
        require(_allowance[msg.sender] != 0, "You are not allowed");

        _allowance[msg.sender] = 0;
        tokenContract.transfer(msg.sender, _balance[msg.sender]);

        uint256 balance_;
        balance_ = _balance[msg.sender];
        _balance[msg.sender] = 0;

        return balance_;
    }

    function random() internal view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, args)));
    }
    
    function pickWinner() internal view returns (uint){
        uint index = random() % 8;
        return index;
    }

    function payout() internal {
        uint winNumber;
        winNumber = pickWinner();

        // pay to owner
        uint256 twentyPercent;
        twentyPercent = totalBettedAmount * 2 / 10;
        tokenContract.transfer(owner, twentyPercent);
        totalBettedAmount -= twentyPercent;

        // pay to winner
        uint256 countOfPlayer;
        countOfPlayer = players.length;
        for(uint256 i = 1; i < countOfPlayer; i ++) {
            if(players[i].bettedAmount[winNumber] > 0) {
                uint256 rewardAmount;
                rewardAmount = players[i].bettedAmount[winNumber] * totalBettedAmount;
                _balance[players[i].user] += rewardAmount / bettedAmountForEachNumber[winNumber];
                _balance[players[i].user] += rewardAmount % bettedAmountForEachNumber[winNumber];
                _allowance[players[i].user] += rewardAmount / bettedAmountForEachNumber[winNumber];
                _allowance[players[i].user] += rewardAmount % bettedAmountForEachNumber[winNumber];
            }
        }

        tokenContract.transfer(owner, totalBettedAmount);
    }
}