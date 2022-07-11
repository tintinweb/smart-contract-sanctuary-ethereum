/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

    interface IERC20 {
        function transferFrom(address _from, address _to, uint256 _value)
            external returns (bool);
        function approve(address _spender, uint256 _value) external returns (bool);
        function transfer(address _to, uint256 _value) external returns (bool);
        function balanceOf(address _who) external view returns (uint256);
    }

    contract MyLottery {

        enum LOTTERY_STATE {
            OPEN,
            PAUSE,
            FINISH,
            DISABLE
        }
        // variables for players
        struct Player {
            address playerAddress;
            uint256 amount;
            uint256 entryTime;
            uint256 index;
        }
        address public manager;
        address public owner;
        LOTTERY_STATE public lotteryState;
        LOTTERY_STATE public preLotteryState;
        uint256 public minAmount;
        address public token;
        address public winner;
        address[] public playerAddresses;
        string public name;
        mapping(address => Player) internal players;
        uint256 public totalAmount;
        uint256 public startTime;
        uint256 public stopTime;
        uint private unlocked = 1;

        constructor(string memory _name, address _manager, address _token, uint256 _minAmount, uint256 _startTime, uint256 _stopTime){  
        require(_minAmount > 0, "_minAmount not set yet");
        require(_token != address(0), "_token not set yet!");
        require(_manager != address(0), "_manager not set yet");
        require(_stopTime > _startTime, "_stopTime must bigger than _startTime");
        require(_stopTime > block.timestamp, "_stopTime is less than the current time");
        name = _name;
        manager = _manager;
        minAmount = _minAmount;
        token = _token;
        lotteryState = LOTTERY_STATE.OPEN;
        startTime = _startTime;
        stopTime = _stopTime;
        owner = msg.sender;
        }

        modifier lock() {
            require(unlocked == 1, "Lottery: LOCKED");
            unlocked = 0;
            _;
            unlocked = 1;
        }


        modifier restricted() {
        require(
            msg.sender == manager || msg.sender == owner,
            "This function is restricted to the contract's manager"
        );
        _;
        }

        function pause() public restricted{
        require(lotteryState == LOTTERY_STATE.OPEN, "lottery is not opened");
        lotteryState = LOTTERY_STATE.PAUSE;
        emit LotteryPause();
        }

        function resume() public restricted{
        require(lotteryState == LOTTERY_STATE.PAUSE, "lottery is not paused");
        lotteryState = LOTTERY_STATE.OPEN;
        emit LotteryResume();
        }

        function disable() public restricted{
        require(lotteryState != LOTTERY_STATE.DISABLE, "lottery is disabled");
        preLotteryState = lotteryState;
        lotteryState = LOTTERY_STATE.DISABLE;
        emit LotteryDisable();
        }

        function enable() public restricted{
        require(lotteryState == LOTTERY_STATE.DISABLE, "lottery is enabled");
        lotteryState = preLotteryState;
        emit LotteryEnable();
        }

        function isOpen() public view returns(bool){
        return lotteryState == LOTTERY_STATE.OPEN;
        }

        function participate(uint256 amount) public lock{
        require(msg.sender != owner, "owner can not participate");
        require(msg.sender != LotteryFactory(owner).owner(), "fac owner can not participate");
        require(msg.sender != manager, "manager can not participate");
        require(lotteryState == LOTTERY_STATE.OPEN,"lottery is not opened");
        require(startTime < block.timestamp, "the lottery has not started yet");
        require(stopTime > block.timestamp, "the lottery has reached end time");
        uint256 preAmount = players[msg.sender].amount;
        require(amount > 0, "amount should bigger than 0");
        require(amount + preAmount >= minAmount,"amount is too small");
        uint256 originBalance = IERC20(token).balanceOf(address(this));
        for(uint i = 0; i < LotteryFactory(owner).getAllManagersLength(); i++){
            if(LotteryFactory(owner).managers(i) == msg.sender){
                revert("fac manager can not participate");
            }
        }
        if(LotteryFactory(owner).transferFrom(token, msg.sender, amount)){
            uint256 nowBalance = IERC20(token).balanceOf(address(this));
            uint256 receivedAmount = nowBalance - originBalance;
            require(receivedAmount >= minAmount, "received amount is too small");
            require(receivedAmount <= amount, "received amount error");
            players[msg.sender].amount = preAmount + receivedAmount;
            if(players[msg.sender].entryTime == 0){
            players[msg.sender].entryTime = block.timestamp;
            }
            if(preAmount == 0){
            playerAddresses.push(msg.sender);
            players[msg.sender].index = playerAddresses.length - 1;
            }
            emit LotteryParticipate(msg.sender, amount);
        }
        else{
            revert("transfer failed");
        }
        }

        function luckyDraw() public restricted lock{
        require(lotteryState == LOTTERY_STATE.OPEN || lotteryState == LOTTERY_STATE.PAUSE, "the lottery is finished");
        if(playerAddresses.length == 0){
            lotteryState = LOTTERY_STATE.FINISH;
        }
        else{
            uint256 num = random(playerAddresses.length, uint256(lotteryState));
            winner = playerAddresses[num%playerAddresses.length];
            totalAmount = IERC20(token).balanceOf(address(this));
            if(IERC20(token).transfer(winner, totalAmount)){
            lotteryState = LOTTERY_STATE.FINISH;
            emit LotteryPickWinner(winner, totalAmount);
            }
            else{
            revert("transfer failed");
            }
        }
        }

        function getPlayersCount() public view returns (uint256){
            return playerAddresses.length;
        }

        function getPlayerInfoByAddress(address player) public view returns (address, uint256, uint256, uint256){
        return (player, players[player].amount, players[player].entryTime, players[player].index);
        }

        function getPlayerInfoByIndex(uint256 index) public view returns (address, uint256, uint256, uint256){
        if(index >= playerAddresses.length){
            return (address(0), 0,0,0);
        }
        return (playerAddresses[index], players[playerAddresses[index]].amount, players[playerAddresses[index]].entryTime, index);
        }


        function random(
            uint256 seed,
            uint256 salt
        ) private view returns (uint256) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,block.coinbase,block.gaslimit,msg.sender,block.number, seed, salt)));
            return randomNumber;
        }

        event LotteryParticipate(
            address indexed player, uint256 amount
        );

        event LotteryPickWinner(
            address indexed winner, uint256 amount
        );

        event LotteryPause(
        );
        
        event LotteryResume(
        );

        event LotteryDisable(
        );

        event LotteryEnable(
        );
    }


    contract LotteryFactory {

        struct lottery{
            address lotteryAddress;
            string name;
            uint256 createTime;
            address managerAddress;
            uint256 startTime;
            uint256 stopTime;
        }

        address public owner;
        address[] public managers;
        lottery[] public lotteries;

        constructor() {
            owner = msg.sender;
        }

        function compareStr (string memory _str1, string memory _str2) public pure returns(bool) {
            if(bytes(_str1).length == bytes(_str2).length){
                if(keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))) {
                    return true;
                }
            }
            return false;
        }

        modifier restricted() {
            require(msg.sender == owner, "This function is restricted to the contract's manager");
            _;
        }

        modifier isManager() {
            uint flag = msg.sender == owner ? 1 : 0;
            if(flag == 0){
                if(managers.length > 0){
                    for(uint i = 0; i < managers.length; i++){
                        address manager = managers[i];
                        if(manager == msg.sender){
                            flag = 1;
                            break;
                        }
                    }
                }
            }
            require(flag == 1, "This function is restricted to the contract's manager");
            _;
        }

        modifier isLottery() {
            uint flag = 0;
            if(flag == 0){
                if(lotteries.length > 0){
                    for(uint i = 0; i < lotteries.length; i++){
                        lottery memory l = lotteries[i];
                        if(l.lotteryAddress == msg.sender){
                            flag = 1;
                            break;
                        }
                    }
                }
            }
            require(flag == 1, "This function is restricted to the lottery");
            _;
        }

        function createLottery(string memory _name, address _manager, address _token, uint256 _minAmount, uint256 _startTime, uint256 _stopTime) public isManager {
            require(bytes(_name).length > 0);
            if(lotteries.length > 0){
                for(uint i = 0; i < lotteries.length; i++){
                    lottery memory l = lotteries[i];
                    if(compareStr(l.name, _name)){
                        revert("this lottery name is exist");
                    }
                }
            }
            address newLottery = address(new MyLottery(_name, _manager, _token, _minAmount, _startTime, _stopTime));
            lottery memory info;
            info.createTime = block.timestamp;
            info.name = _name;
            info.managerAddress =_manager;
            info.lotteryAddress = newLottery;
            info.startTime = _startTime;
            info.stopTime = _stopTime;
            lotteries.push(info);
            emit LotteryCreated(newLottery, lotteries.length);
        }

        function addManager(address _manager) public restricted{
            require(_manager != owner, "owner can not be manager");
            if(managers.length > 0){
                for(uint i = 0; i < managers.length; i++){
                    address manager = managers[i];
                    if(manager == _manager){
                        revert("this manager has added");
                    }
                }
            }
            managers.push(_manager);
        }

        function removeManager(address _manager) public restricted{
            uint flag = 0;
            if(managers.length > 0){
                for(uint i = 0; i < managers.length; i++){
                    address manager = managers[i];
                    if(manager == _manager){
                        if(i != managers.length - 1){
                            managers[i] = managers[managers.length - 1];
                        }
                        managers.pop();
                        flag = 1;
                        break;
                    }
                }
            }
            if(flag == 0){
                revert("this address is not exist");
            }
        }

        function clearManagers() public restricted{
            require(managers.length > 0, "manager is empty");
            delete managers;
        }

        function getAllManagersLength() public view returns(uint256) {
            return managers.length;
        }

        function getAllLotteriesLength() public view returns(uint256) {
            return lotteries.length;
        }

        function getLastActiveLottery() public view returns (address){
            if(lotteries.length > 0){
                for(uint i = lotteries.length - 1; i >= 0; i--){
                    lottery memory info = lotteries[i];
                    if(MyLottery(info.lotteryAddress).isOpen()){
                        return info.lotteryAddress;
                    }
                    if(i == 0){
                        break;
                    }
                }
                return lotteries[lotteries.length - 1].lotteryAddress;
            }
            else{
                return address(0);
            }
        }

        function pause(address _lotteryAddress) public isManager{
            MyLottery(_lotteryAddress).pause();
        }

        function resume(address _lotteryAddress) public isManager{
            MyLottery(_lotteryAddress).resume();
        }

        function disable(address _lotteryAddress) public isManager{
            MyLottery(_lotteryAddress).disable();
        }

        function enable(address _lotteryAddress) public isManager{
            MyLottery(_lotteryAddress).enable();
        }

        function luckyDraw(address _lotteryAddress) public isManager{
            MyLottery(_lotteryAddress).luckyDraw();
        }

        function transferFrom(address _token, address _spender, uint256 _amount) public isLottery returns (bool){
            return IERC20(_token).transferFrom(_spender, msg.sender, _amount);
        }

        // Events
        event LotteryCreated(
            address indexed lotteryAddress, uint256 length
        );
    }