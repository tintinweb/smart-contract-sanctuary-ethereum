/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity >=0.4.21 <0.7.0;

// * poker2win - Fair and freedom games that pay Ether, No banker
//
// * @author poker2win <[email protected]>
//
// * @license Apache2.0

contract Battle {
    // Bet ether limitation
    uint constant betUnitMinEther = 0.15 ether;
    uint constant betUnitMaxEther = 135 ether;

    // Pokers total count
    uint constant pokerCountTotal = 2;

    // Game status
    bool private gameIsRunning = false;
    uint private startTime;

    // Bet ether statics and transfer
    uint private currentRoundBet = 0; // wei
    address private betPoolAddress = address(this);

    // Take part players, for loop addresses
    address[] private players;
    mapping (address => uint) private playersMapIndex;

    uint[] private pokerIndexes;
    mapping (uint => bool) private pokerIndexesExistence;

    uint private highestPokerValue;
    address[] private highestPlayersAddress;

    uint[] private prePokerValues;

    // Service charge address
    address payable private serviceChargeAddress = 0xe019736Cdf46CEb46D06dc41A798f830b26a0dFB;

    address public owner;

    // When deploy contract
    constructor() public {
        owner = msg.sender;
    }

    function getBetUnitMinEther () external pure returns (uint) {
        return betUnitMinEther;
    }

    function getBetUnitMaxEther () external pure returns (uint) {
        return betUnitMaxEther;
    }

    function getGameIsRunning() external view returns (bool) {
        return gameIsRunning;
    }

    function getStartTime() external view returns (uint) {
        return startTime;
    }

    // If gt 0 ether, later player can only bet currentRoundBetWei
    function getCurrentRoundBetWei() external view returns (uint) {
        return currentRoundBet;
    }

    function getMyPokerIndex() external view returns (uint) {
        return playersMapIndex[msg.sender];
    }

    function getAllPokerIndex() external view returns (uint[] memory) {
        return pokerIndexes;
    }

    function getPrePokerValues() external view returns (uint[] memory) {
        return prePokerValues;
    }

    function getPokersCountLeft() public view returns (uint) {
        return pokerCountTotal - players.length;
    }

    function betOn(uint _pokerIndex) external payable onlyBalanceValid onlyHasPokerLeft {

        require(playersMapIndex[msg.sender] == 0, 'You have already bet on yet');
        require(pokerIndexesExistence[_pokerIndex] == false, 'This poker was bet on by others yet');
        if (gameIsRunning) {
            require(msg.value == currentRoundBet, 'Your bet ether is not equals to the first player');
        }

        if (! gameIsRunning) {
            // new round should clear pre data
            delete prePokerValues;

            gameIsRunning = true;
            currentRoundBet = msg.value;
        }
        startTime = block.timestamp;

        // Give poker to the player
        uint v = random(_pokerIndex);

        players.push(msg.sender);
        playersMapIndex[msg.sender] = _pokerIndex;
        pokerIndexesExistence[_pokerIndex] = true;
        pokerIndexes.push(_pokerIndex);

        prePokerValues.push(v);

        if (players.length == 1) {
            highestPokerValue = v;
        } else {
            if (v > highestPokerValue) {
                highestPokerValue = v;
                highestPlayersAddress.push(msg.sender);
            } else if (v == highestPokerValue) {
                highestPlayersAddress.push(players[0]);
                highestPlayersAddress.push(msg.sender);
            } else {
                highestPlayersAddress.push(players[0]);
            }
            allocateFunds();
        }
    }

    modifier onlyBalanceValid() {
        require(msg.value >= betUnitMinEther, 'Your bet ETH is lower than the minimum');
        require(msg.value <= betUnitMaxEther, 'Your bet ETH is largger than the maximum');
        _;
    }

    modifier onlyHasPokerLeft() {
        require(getPokersCountLeft() > 0, 'No poker left, please wait next round start');
        _;
    }

    modifier onlyMultiPlayersHasJoined() {
        require(gameIsRunning == true, 'Current round is not running');
        require(players.length >= 2, 'Joined player count less than 2');
        _;
    }

    function random(uint i) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(
            block.difficulty, block.coinbase, block.timestamp, block.number, i
        ))) % 10);
    }

    // We need a backend to pay this action. Even more backend can count down.
    function allocateFunds() internal {
        require(players.length >= 2, 'No player joined');

        // 2% service charge
        uint serviceCharge = betPoolAddress.balance / 50;
        serviceChargeAddress.transfer(serviceCharge);

        // Amount assign
        uint winnerNumber = highestPlayersAddress.length;
        uint winnerAverageAmount = betPoolAddress.balance / winnerNumber;
        for (uint i = 0; i < winnerNumber; i++) {
            address payable addr = address(uint160(highestPlayersAddress[i]));
            addr.transfer(winnerAverageAmount);
        }

        // If others
        uint otherAmount = betPoolAddress.balance;
        if (otherAmount > 0) {
            serviceChargeAddress.transfer(otherAmount);
        }

        refresh();
    }

    function refresh() internal {
        gameIsRunning = false;
        currentRoundBet = 0;
        delete startTime;

        uint playerLength = players.length;
        for (uint i = 0; i < playerLength; i++) {
            delete playersMapIndex[players[i]];
            delete pokerIndexesExistence[pokerIndexes[i]];
        }

        delete players;
        delete pokerIndexes;

        delete highestPokerValue;
        delete highestPlayersAddress;
    }

    function setServiceChargeAddress(address payable _addr) external onlyOwner {
        serviceChargeAddress = _addr;
    }

    // Maybe for exception situations, platform promise
    function withdrawIfOccurUnknowProblem() external onlyOwner {
        uint amount = betPoolAddress.balance;
        serviceChargeAddress.transfer(amount);

        refresh();
    }

    function destroyContract() external onlyOwner {
        selfdestruct(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'You are not owner');
        _;
    }
}