//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error NotOwner(); 
error DoubleBet();  
error InvalidBet();  
error NotPlayer();
error SameBlock();
error AboveLimit();
error GamesLive();

contract SimpleGame {

    struct Player {
        uint256 bet;
        uint256 blockNumber;
    }
    
    /* State Variables */
    uint256 private s_devFee;
    uint256 private s_latestBetBlock;
    uint256[] private s_betSizes;
    address payable private immutable i_owner;
    mapping (address => Player) public players;

    /* Events */
    event DiceRolled(address player, uint256 random, uint256 bet, uint256 win, uint256 time);

    constructor(uint256 devFee, uint256[] memory betSizes) payable {
        s_devFee = devFee; 
        s_betSizes = betSizes; 
        i_owner = payable(msg.sender);
    }

    function placeBet(uint256 betIdx) public payable {
        if(players[msg.sender].bet != 0) { revert DoubleBet(); }
        if(betIdx >= s_betSizes.length || s_betSizes[betIdx] != msg.value) { revert InvalidBet(); }
        players[msg.sender] = Player(msg.value, block.number);
        s_latestBetBlock = block.number;
        (bool success, ) = i_owner.call{value: msg.value * (s_devFee / 1000)}("");
        require(success);
    }

    function rollDice() public {
        Player memory p = players[msg.sender];
        if(p.bet == 0) { revert NotPlayer(); }
        if(p.blockNumber == block.number) { revert SameBlock(); }
        delete players[msg.sender]; // prevents reentrancy attacks + receive gas refund for clearing storage
        bytes32 blockHash = blockhash(p.blockNumber);
        if(blockHash == 0) { // blockHash is 0 for p.blockNumber < block.number - 256
            emit DiceRolled(msg.sender, 100, p.bet, 0, block.timestamp);
            return;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(blockHash, msg.sender))) % 100; // http://www.ijcee.org/papers/439-JE503.pdf
        uint256 payout = getPayout(random, p.bet);
        emit DiceRolled(msg.sender, random, p.bet, payout, block.timestamp);
        if (payout > 0) {
            (bool success, ) = msg.sender.call{ value: payout }("");
            require(success);
        }     
    }

    function endGame() public onlyOwner {
        if (s_latestBetBlock > block.number - 256) { revert GamesLive(); }
        setBetSizes(new uint256[](0)); // new bets throw InvalidBet error because betIdx >= s_betSizes.length = 0
        if (address(this).balance > 0) {
            (bool success, ) = i_owner.call{ value: address(this).balance }("");
            require(success);
        }
    }
    
    // Payout strategy based on empirical experiment
    function getPayout(uint256 random, uint256 bet) public view returns(uint256) {
        uint256 payout = 0;
        if (random < 25) {
            payout = 2 * bet;
        } else if (random == 25 && address(this).balance > 20 * s_betSizes[2]){
            payout = 10 * bet;
        }
        if (payout > address(this).balance) {
            payout = address(this).balance;
        }
        return payout;
    }

    function getDevFee() public view returns(uint256) {
        return s_devFee;
    }

    function getBetSizes() public view returns(uint256[] memory) {
        return s_betSizes;
    }

    function getLatestBetBlock() public view returns(uint256) {
        return s_latestBetBlock;
    }

    function getPlayer(address addr) public view returns(Player memory) {
        return players[addr];
    }

    // do we keep this?
    function getOwner() public view returns(address payable) {
        return i_owner;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function setDevFee(uint256 devFee) public onlyOwner {
        if(devFee > 1000) { revert AboveLimit(); } 
        s_devFee = devFee;
    }

    function setBetSizes(uint256[] memory betSizes) public onlyOwner {
        s_betSizes = betSizes;
    }

    modifier onlyOwner {
        if(msg.sender != i_owner) { revert NotOwner(); } // saves gas over require
        _; // implies "do the rest of the code"
    }

    // Fallback function to receive Ether when msg.data is empty
    receive() external payable {}
    
    // Fallback function to receive Ether when msg.data is NOT empty
    fallback() external payable {}
}