/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

contract MergeSandwich {
    address immutable public sandwicher = msg.sender;

    uint256 internal constant TERMINAL_TOTAL_DIFFICULTY = 58750000000000000000000;
    uint256 public terminalPowBlock;

    event PowGone();
    event PosHere();

    function byePow(uint256 observedBestBlock, uint256 bestBlockTotalDifficulty) external payable {
        require(block.number == observedBestBlock + 1, "poorly observed");
        require(bestBlockTotalDifficulty + block.difficulty >= TERMINAL_TOTAL_DIFFICULTY, "mine harder");
        require(msg.sender == sandwicher, "who r u");

        terminalPowBlock = block.number;

        emit PowGone();

        if (msg.value > 0) block.coinbase.transfer(msg.value);
    }

    function hiPos() external payable {
        require(block.number == terminalPowBlock + 1, "bad block");

        emit PosHere();

        if (msg.value > 0) block.coinbase.transfer(msg.value);
    }
}