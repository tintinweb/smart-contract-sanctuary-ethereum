/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//Begin
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

//import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

//https://kovan.etherscan.io/token/0xa766631087e45d8e3061dd05e40a7aa39e52d712#balances
interface TokenMinterInterface {
    function mint(address account, uint256 amount) external returns (bool);
}

contract KeeperMinter is KeeperCompatibleInterface {
    uint256 public counter; // Public counter variable
    TokenMinterInterface public minter;
    address to; // who is going to receive the tokens

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor(
        uint256 updateInterval,
        address tokenMinter,
        address _to
    ) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        counter = 0;
        minter = TokenMinterInterface(tokenMinter);
        to = _to;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(counter<=10,"can't do this more than 10 times");
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        minter.mint(to, 1);
        performData;
    }
}
//End