/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity 0.6.12;

contract RumblioJackpot {
    
    uint feePercentage = 5; // %
    uint roundDuration = 3; // Defines the duration of the round in blocks
    uint16 gameIntegrityBlocks = 3;
    uint totalRoundsPlayed = 0; // Holds the number of rounds finished
    address payable owner; // Holds the contract owner address
    
    uint endBlock = 0; // Block that will end the current round
    uint winnerBlock = 0; // Holds the block number that will be used to calculate the winner
    uint totalBets = 0; // Holds the total betted value of the current round
    uint numEntries = 0; //Holds the number of entries
    
    mapping(uint256 => Entry) public entries;
    
    struct Entry {
        address payable addr;
        uint amount;
    }

    event NewEntry (
        address addr,
        uint amount
    );
    
    event JackpotEnd (
        address winner,
        uint amount,
        uint seed
    );
    
    constructor() public {
        owner = msg.sender;
    }

    receive() external payable hasValue() canBet() {
        addBet(msg.sender, msg.value);
        
        if(numEntries >= 2 && endBlock == 0 && winnerBlock == 0) {
            endBlock = block.number + roundDuration;
            winnerBlock = endBlock + gameIntegrityBlocks;
        }
    }
    
    function resetContract() private {
        numEntries = 0;
        totalBets = 0;
        endBlock = 0;
        winnerBlock = 0;
    }
    
    function addBet(address payable addr, uint256 value) private
    {
        totalBets += value;
        entries[numEntries] = Entry(addr, value);
        numEntries += 1;
        
        emit NewEntry(addr, value);
    }
    
    // !!!!!!!!!!!!!!!!!!!!!!!! DELETE
    address history_winner;
    uint history_funds;
    // !!!!!!!!!!!!!!!!!!!!!!!! DELETE
    
    
    function endJackpot() public payable canEnd {
        (uint seed, bytes32 winningHash) = generateRandomHash(gameIntegrityBlocks, winnerBlock);
        
        uint sum = 0;
        uint winningTicket = uint256(winningHash) % totalBets;
        uint winningIndex = 0;

        for (uint256 i = 0; i < numEntries; i++) {
            sum += entries[i].amount;

            if (sum >= winningTicket) {
                winningIndex = i;
                break;
            }
        }
        
        uint winningFunds = (totalBets * (100 - feePercentage)) / 100;
        uint feeFunds = totalBets - winningFunds;
        
        history_funds = winningFunds;
        history_winner = entries[winningIndex].addr;
        
        entries[winningIndex].addr.transfer(winningFunds);
        owner.transfer(feeFunds);
        emit JackpotEnd(entries[winningIndex].addr, winningFunds, seed);
        totalRoundsPlayed++;
        resetContract();
    }
    
    function getEntries() public view returns (address[] memory) {
        address[] memory entriesArr = new address[](numEntries);
        
        for(uint i = 0; i < numEntries; i++) {
            entriesArr[i] = entries[i].addr;
        }
        
        return entriesArr;
    }
    
    function getEntriesValue() public view returns (uint[] memory) {
        uint[] memory entriesValueArray = new uint[](numEntries);
        
        for(uint i = 0; i < numEntries; i++) {
            entriesValueArray[i] = entries[i].amount;
        }
        
        return entriesValueArray;
    }
    
    function getHistory() public view returns (address, uint) {
        return (history_winner, history_funds);
    }    
    
    function getTotalBets() public view returns (uint) {
        return totalBets;
    }    
    
    function getEndBlock() public view returns (uint) {
        return endBlock;
    }    

    function getWinnerBlock() public view returns (uint) {
        return winnerBlock;
    }
    
    modifier canBet() {
        require(block.number < endBlock || endBlock == 0, "This round has already ended.");
        _;
    }
    
    
    modifier hasValue() {
        require(msg.value >= 10000000000000000, "Not enough ethereum."); // min: 0.01 ETH
        _;
    }
    
    modifier canEnd() {
        require(block.number >= winnerBlock, "Winner block not reached yet.");
        _;
    }
    
    function generateRandomHash(uint16 blocksToCount, uint256 endBlockA)
        public
        view
        returns (uint256, bytes32)
    {
        require(
            blocksToCount > 0,
            "Blocks to count needs to be higher than zero."
        );
        require(
            blocksToCount < 256,
            "Can only use the most recent 256 blocks to process a random hash. Please enter a number below 256."
        );
        require(
            blocksToCount < block.number,
            "You can't use unprocessed blocks to generate a random hash."
        );
        require(
            endBlockA < block.number,
            "End block cannot be higher than the current block number."
        );
        require(endBlockA > 0, "End block must be higher than zero.");
        require(
            endBlockA - blocksToCount > 0,
            "Difference between end block and blocks to count must be higher than zero."
        );

        uint256 seed = 0;

        for (uint8 i = 0; i < blocksToCount; i++) {
            seed += uint256(sha256(abi.encodePacked(blockhash(endBlockA - i))));
        }

        return (seed, keccak256(abi.encodePacked(seed)));
    }
}