/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Game {
    address payable owner;
    mapping(address => uint) playerBalances;
    mapping(address => bool) isPlayer;
    mapping(address => bool) isBlackListed;
    mapping(address => uint) sessionPot;
    mapping(address => address) playerToSession;
    uint fee;
    uint maxTx;
    uint maxWallet;
    bool isFeeSet;
    bool isMaxTxSet;
    bool isMaxWalletSet;

    bool tradable;

    //openTrading realated Variables and events
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public orders;

    event Deposit(address indexed _from, uint256 _value);
    event Withdrawal(address indexed _to, uint256 _value);
    event Order(address indexed _from, address indexed _to, uint256 _value);
    event Trade(address indexed _from, address indexed _to, uint256 _value);

    //end
   
    constructor() {
        owner = payable(msg.sender);
        tradable = true;
    }

    //Function to initiate once a player joins a session from the host player
    function joinSession(address session) public payable {
        require(tradable, "Trades not opened");
        require(isFeeSet, "Fee is not set");
        require(isMaxTxSet, "Max Tx is not set");
        require(isMaxWalletSet, "Max Wallet is not set");
        require(msg.value > 0, "Must deposit more than 0 wei");
        require(!isPlayer[msg.sender], "Player already in a session");
        require(msg.value <= maxWallet, "Deposit value must be less than max wallet limit");
        require(gasleft() <= maxTx, "Gas used for transaction must be less than max Tx limit");
        require(msg.value >= fee, "Deposit must be greater than the set fee");
        require(!isBlackListed[msg.sender], "Player is blacklisted");

        playerBalances[msg.sender] = msg.value;
        isPlayer[msg.sender] = true;
        playerToSession[msg.sender] = session;
        sessionPot[session] += msg.value;
    }

    //Function that invokes once the winner redeems the cash prize
    function payWinner(address session) public {
        require(isPlayer[msg.sender], "Player not in a session");
        require(playerToSession[msg.sender] == session, "Player not in this session");
        require(sessionPot[session] >= 2, "Not enough players for this session");

        address payable winner = determineWinner();
        uint commission = (sessionPot[session] * 10) / 100;
        uint winnerPrize = (sessionPot[session] - commission);

        winner.transfer(winnerPrize);
        payable(owner).transfer(commission);
        sessionPot[session] = 0;
    }

    //Function to determine the winner of the game (varies with game logic)
    function determineWinner() private view returns (address payable) {
        // Placeholder function to determine the winner of the session
        // Can be replaced with a game specific algorithm
        return payable(msg.sender);
    }

    //Function to clear the session per each player after play
    function leaveSession(address session) public {
        require(isPlayer[msg.sender], "Player not in a session");
        require(playerToSession[msg.sender] == session, "Player not in this session");

        sessionPot[session] -= playerBalances[msg.sender];
        playerBalances[msg.sender] = 0;
        isPlayer[msg.sender] = false;
        delete playerToSession[msg.sender];
    }

    function setFee(uint _fee) public {
        require(msg.sender == owner, "Only owner can set the fee");
        fee = _fee;
        isFeeSet = true;
    }

    function setMaxTx(uint _maxTx) public {
        require(msg.sender == owner, "Only owner can set the max Tx");
        maxTx = _maxTx;
        isMaxTxSet = true;
    }

    function setMaxWallet(uint _maxWallet) public {
        require(msg.sender == owner, "Only owner can set the max wallet");
        maxWallet = _maxWallet;
        isMaxWalletSet = true;
    }

    function addBot(address _bot) public {
        require(msg.sender == owner, "Only owner can blacklist a bot");
        isBlackListed[_bot] = true;
    }

    //Open Trading related
    function enableTrades() public {
        tradable = true;
    }

    function disableTrades() public{
        tradable = false;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _value) public {
        require(balances[msg.sender] >= _value, "Insufficient funds.");
        require(_value > 0, "Withdrawal amount must be greater than 0.");
        balances[msg.sender] -= _value;
        payable(msg.sender).transfer(_value);
        emit Withdrawal(msg.sender, _value);
    }

    function buy(address _from, uint256 _value) public {
        require(balances[msg.sender] >= _value, "Insufficient funds.");
        require(_value > 0, "Trade amount must be greater than 0.");
        orders[msg.sender][_from] += _value;
        emit Order(msg.sender, _from, _value);
    }

    function sell(address _to, uint256 _value) public {
        require(orders[_to][msg.sender] >= _value, "Insufficient sell order.");
        require(_value > 0, "Trade amount must be greater than 0.");
        orders[_to][msg.sender] -= _value;
        balances[msg.sender] += _value;
        balances[_to] -= _value;
        emit Trade(msg.sender, _to, _value);
    }

    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function getOrders(address _buyer, address _seller) public view returns (uint256) {
        return orders[_buyer][_seller];
    }
}