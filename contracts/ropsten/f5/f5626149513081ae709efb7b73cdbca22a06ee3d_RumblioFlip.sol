/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity 0.6.12;

contract RumblioFlip {
    
    constructor() public {
        owner = msg.sender;
        feePercentage = 5;
    }
    
    uint feePercentage; // %
    address payable owner; // Holds the contract owner address
    uint numEntries = 0; // Holds the entries counter
    address payable[] entries = new address payable[](2); // Holds the addresses of the players that joined the flip
    uint flipValue = 0; // Holds the amount of ether each user should deposit
    uint totalBets = 0; // Holds the exact amount of ethereum deposited
    uint endBlock = 0; // Holds the block number in where no more bets are accepted
    uint winnerBlock = 0; // Holds the block number that will be used to calculate the winner
    uint16 gameIntegrityBlocks = 3;
    uint flipsCount = 0; // Holds how many flips this contract has processed

    event FlipUpdated(
        address payable[] entries,
        uint flipValue,
        address _this,
        uint winnerBlock,
        uint seed
    );
    
    receive() external payable canJoin() {
        if(numEntries == 0) {
            flipValue = msg.value;
        } else if(numEntries == 1) {
            endBlock = block.number + 1;
            winnerBlock = endBlock + gameIntegrityBlocks;
        }

        newEntry(msg.sender, msg.value);
    }
    
    function newEntry(address payable addr, uint amount) private {
        entries[numEntries] = addr;
        totalBets += amount;
        emit FlipUpdated(entries, amount, address(0), winnerBlock, 0);
        numEntries++;
    }
    
    function endFlip() public payable canEnd {
        (uint seed, bytes32 winningHash) = generateRandomHash(gameIntegrityBlocks, winnerBlock);
        uint winningIndex = uint(winningHash) % 2;
        uint winningFunds = (totalBets * (100 - feePercentage)) / 100;
        uint feeFunds = totalBets - winningFunds;
        entries[winningIndex].transfer(winningFunds);
        owner.transfer(feeFunds);
        emit FlipUpdated(entries, flipValue, entries[winningIndex], 0, seed);
        flipsCount++;
        resetContract();
    }
    
    function resetContract() private {
        numEntries = 0;
        entries = new address payable[](2);
        flipValue = 0;
        totalBets = 0;
        endBlock = 0;
        winnerBlock = 0;
    }
    
    modifier canJoin() {
        require((flipValue == 0 || msg.value == flipValue) && endBlock == 0 && numEntries < 2 && msg.value >= 10000000000000000); // min: 0.01 ETH 
        _;
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier canEnd() {
        require(block.number >= winnerBlock);
        _;
    }
    
    function getFlipsCount() public view returns (uint) {
        return flipsCount;
    }    
    
    function getEndBlock() public view returns (uint) {
        return endBlock;
    }    

    function getWinnerBlock() public view returns (uint) {
        return winnerBlock;
    }
    
    function getTotalBets() public view returns (uint) {
        return totalBets;
    }
    
    function getEntries() public view returns (address payable[] memory) {
        return entries;
    }
    
    function getFlipValue() public view returns (uint) {
        return flipValue;
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