// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

error BetFootBall__NotOwner();
error BetFootBall__NotEnoughMoney();
error BetFootBall__TooMuchMoney();
error BetFootBall__IDPairAlreadyCreated();
error BetFootBall__IDPairNotFound();
error BetFootBall__SendPrizeToWinnerError();
error BetFootball__WithdrawFailed();

contract BetFootball {
    enum BET_OPTIONS {
        WIN,
        DRAW,
        LOSE
    }

    address private immutable i_owner;
    uint256 private constant MaximumBet = 5e17; // 1 ETH
    // If they bet in large amount, I gonna be bankrupt :v
    uint256 private constant MinimumBet = 1e16; // 0.01 ETH
    address[] private s_players;

    mapping(address => mapping(uint256 => mapping(BET_OPTIONS => uint))) s_playerBetList;
    mapping(address => mapping(uint256 => mapping(BET_OPTIONS => uint))) s_playerBetRatio;
    mapping(uint256 => string) s_betPairList;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert BetFootBall__NotOwner();
        _;
    }

    modifier requireMiniumBet() {
        if (msg.value <= MinimumBet) revert BetFootBall__NotEnoughMoney();
        _;
    }

    modifier requiredMaximumBet() {
        if (msg.value > MaximumBet) revert BetFootBall__TooMuchMoney();
        _;
    }

    function addFundToContract() public payable onlyOwner requireMiniumBet {}

    // Player section
    function betToAPair(
        uint256 pairId,
        uint256 ratio,
        BET_OPTIONS option
    ) public payable requireMiniumBet requiredMaximumBet {
        if (bytes(s_betPairList[pairId]).length == 0)
            revert BetFootBall__IDPairNotFound();
        s_playerBetList[msg.sender][pairId][option] = msg.value;
        s_playerBetRatio[msg.sender][pairId][option] = ratio;
        s_players.push(msg.sender);
    }

    // Only Owner Section
    function sendPrizeToWinner(
        uint256 pairId,
        // uint256 ratio,
        BET_OPTIONS result
    ) public onlyOwner {
        address[] memory players = s_players;
        for (uint256 i = 0; i < players.length; i++) {
            uint256 betAmount = s_playerBetList[players[i]][pairId][result];
            uint256 ratio = s_playerBetRatio[players[i]][pairId][result];
            (bool callSuccess, ) = payable(players[i]).call{
                value: (betAmount * ratio) / 1e18
            }("");
            // 500000000000000000 * 1.1 =
            if (!callSuccess) revert BetFootBall__SendPrizeToWinnerError();
        }
    }

    function addNewBetPair(
        uint256 pairId,
        string memory name
    ) public onlyOwner {
        if (bytes(s_betPairList[pairId]).length != 0)
            revert BetFootBall__IDPairAlreadyCreated();
        s_betPairList[pairId] = name;
    }

    function removeBetPair(uint256 pairId) public onlyOwner {
        if (bytes(s_betPairList[pairId]).length == 0)
            revert BetFootBall__IDPairNotFound();
        delete s_betPairList[pairId];
    }

    function getPairIdName(uint256 pairId) public view returns (string memory) {
        return s_betPairList[pairId];
    }

    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert BetFootball__WithdrawFailed();
    }
}