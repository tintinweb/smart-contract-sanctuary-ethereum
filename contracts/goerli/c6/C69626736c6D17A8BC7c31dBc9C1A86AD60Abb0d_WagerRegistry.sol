// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./wagers/IWagerModule.sol";

interface IWagerRegistry {
    // -- events --
    event WagerCreated(
        address indexed partyAddr,
        uint256 partyWagerAmount,
        bytes partyWager,
        uint256 createdBlock,
        uint256 enterLimitBlock,
        uint256 expirationBlock,
        address wagerModule,
        address oracleModule,
        uint256 indexed wagerId
    );
    event WagerEntered(
        address indexed partyAddr,
        bytes partyWager,
        uint256 indexed wagerId
    );
    event WagerSettled(
        address indexed winner,
        uint256 amount,
        bytes result,
        uint256 indexed wagerId
    );
    event WagerVoided(uint256 indexed wagerId);

    // -- methods --
    function settleWager(uint256 wagerId) external;

    function executeBlockRange(uint256 startBlock, uint256 endBlock) external;

    function enterWager(
        uint256 wagerId,
        bytes memory partyTwoWager
    ) external payable;

    function createWager(Wager memory wager) external payable returns (uint256);

    function voidWager(uint256 wagerId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../wagers/IWagerModule.sol";

interface IWagerOracle {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracle.sol";

// -- structs --
struct Wager {
    bytes parties; // party data; |partyOne|partyTwo|
    bytes partyOneWagerData; // wager data; e.g |wagerStart|wagerValue|
    bytes partyTwoWagerData;
    uint256 wagerAmount;
    bytes blockData; // blocktime data; |created|expiration|enterLimit|
    bytes wagerOracleData; // ancillary wager data
    bytes supplumentalWagerOracleData; // supplumental wager data
    bytes result; // wager outcome
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleModule; // oracle module semantics
    address oracleSource; // oracle source
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

interface IWagerModule {
    // -- methods --
    function settle(
        Wager memory wager
    ) external returns (Wager memory, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/wagers/IWagerModule.sol";
import "./interfaces/IWagerRegistry.sol";

/**
 @title WagerRegistry
 @author Henry Wrightman

 @notice registry contract for wager management
 */

contract WagerRegistry is IWagerRegistry {
    uint256 private _id;

    mapping(uint256 => Wager) public wagers;
    mapping(uint256 => uint256[]) public executionSchedule; // blockNumber -> [wagerIds]

    constructor() {}

    /// @notice createWager
    /// @dev
    /// @param wager wager to be created
    /// @return uint256 wager id
    function createWager(
        Wager memory wager
    ) external payable override returns (uint256) {
        uint256 id = _id;
        (address partyOne, ) = decodeParties(wager.parties);
        (, uint80 expirationBlock, uint80 enterBlockLimit) = decodeBlocks(
            wager.blockData
        );
        require(expirationBlock >= block.number + 15, "W12");
        require(partyOne != address(0), "W13");
        require(wager.partyOneWagerData.length > 0, "W14");
        require(msg.value >= wager.wagerAmount, "W9");

        wager.blockData = abi.encode(
            block.number,
            expirationBlock,
            enterBlockLimit
        );
        wagers[id] = wager;
        _id++;
        emit WagerCreated(
            msg.sender,
            msg.value,
            wager.partyOneWagerData,
            block.number,
            enterBlockLimit,
            expirationBlock,
            address(wager.wagerModule),
            address(wager.oracleSource),
            id
        );
        return id;
    }

    /// @notice enterWager
    /// @dev
    /// @param wagerId id of wager to be entered by second party
    /// @param partyTwoWagerData second party's supplemental data for their specific wager
    function enterWager(
        uint256 wagerId,
        bytes memory partyTwoWagerData
    ) external payable override {
        require(wagerId <= _id, "W1");

        Wager memory wager = wagers[wagerId];
        (address partyOne, address partyTwo) = decodeParties(wager.parties);
        (, uint80 expirationBlock, uint80 enterLimitBlock) = decodeBlocks(
            wager.blockData
        );
        require(wager.state == WagerState.created, "W2");

        if (enterLimitBlock != 0) {
            require(block.number <= enterLimitBlock, "W15");
        }
        require(expirationBlock >= block.number + 15, "W7");
        require(msg.sender != partyOne, "W8");
        require(msg.value >= wager.wagerAmount, "W9");
        require(
            (wager.partyTwoWagerData.length == 0 &&
                partyTwoWagerData.length > 0) ||
                ((wager.partyTwoWagerData.length > 0 &&
                    partyTwoWagerData.length > 0) &&
                    bytes32(wager.partyTwoWagerData) ==
                    bytes32(partyTwoWagerData)),
            "W10"
        );
        require(
            bytes32(wager.partyOneWagerData) != bytes32(partyTwoWagerData) &&
                bytes32(wager.partyOneWagerData) !=
                bytes32(wager.partyTwoWagerData),
            "W18"
        );

        wager.parties = abi.encode(partyOne, msg.sender);
        wager.partyTwoWagerData = partyTwoWagerData;
        wager.state = WagerState.active;
        executionSchedule[expirationBlock].push(wagerId);
        wagers[wagerId] = wager;

        emit WagerEntered(msg.sender, partyTwoWagerData, wagerId);
    }

    /// @notice settleWager
    /// @dev
    /// @param wagerId id of wager to be settled
    function settleWager(uint256 wagerId) external override {
        require(wagerId <= _id, "W1");
        Wager memory wager = wagers[wagerId];
        (, uint80 expirationBlock, uint80 enterLimitBlock) = decodeBlocks(
            wager.blockData
        );

        require(wager.state == WagerState.active, "W2");
        require(block.number >= expirationBlock, "W3");

        (Wager memory settledWager, address winner) = IWagerModule(
            wager.wagerModule
        ).settle(wager);
        settledWager.state = WagerState.completed;
        wagers[wagerId] = settledWager;

        (bool sent, ) = winner.call{value: (wager.wagerAmount * 2), gas: 3600}(
            ""
        );
        require(sent, "W11");

        emit WagerSettled(
            winner,
            settledWager.wagerAmount * 2,
            settledWager.result,
            wagerId
        );
    }

    function executeBlockRange(
        uint256 startBlock,
        uint256 endBlock
    ) external override {
        for (uint256 block_ = startBlock; block_ <= endBlock; block_++) {
            uint256[] memory ids = executionSchedule[block_];
            for (uint256 j = 0; j < ids.length; j++) {
                if (wagers[ids[j]].state == WagerState.active) {
                    this.settleWager(ids[j]);
                }
            }
        }
    }

    /// @notice voidWager
    /// @dev
    /// @param wagerId id of wager to be voided & respective parties refunded
    function voidWager(uint256 wagerId) external override {
        require(wagerId <= _id, "W1");

        Wager memory wager = wagers[wagerId];
        (address partyOne, address partyTwo) = decodeParties(wager.parties);
        (
            uint80 createdBlock,
            uint80 expirationBlock,
            uint80 enterLimitBlock
        ) = decodeBlocks(wager.blockData);
        if (enterLimitBlock != 0 && partyTwo != address(0)) {
            require(block.number <= enterLimitBlock, "W16");
        } else if (enterLimitBlock == 0 && partyTwo != address(0)) {
            // more than half of wager time elapsed
            require(
                block.number <=
                    createdBlock + (expirationBlock - createdBlock / 2),
                "W16"
            );
        }
        require(
            wager.state == WagerState.active ||
                wager.state == WagerState.created,
            "W2"
        );

        wager.state = WagerState.voided;
        wagers[wagerId] = wager;
        require(msg.sender == partyOne, "W4");

        (bool sent, ) = partyOne.call{value: wager.wagerAmount}("");
        require(sent, "W6");
        if (partyTwo != address(0)) {
            (bool sentTwo, ) = partyTwo.call{value: wager.wagerAmount}("");
            require(sentTwo, "W6");
        }

        emit WagerVoided(wagerId);
    }

    /// @notice decodeParties
    /// @dev Wager's party data consists of <partyOne> (address) and <partyTwo> address
    /// @param data wager address data be decoded
    /// @return partyOne address
    /// @return partyTwo address
    function decodeParties(
        bytes memory data
    ) public pure returns (address partyOne, address partyTwo) {
        (partyOne, partyTwo) = abi.decode(data, (address, address));
    }

    /// @notice decodeBlocks
    /// @dev Wager's block data consists of <createdBlock> (uint80) <expirationBlock> settlement date (uint80) <enterLimitBlock> entrance gating limit block (uint80)
    /// @param data wager block data be decoded
    /// @return createdBlock block wager was created
    /// @return expirationBlock block wager expires
    /// @return enterLimitBlock block wager entrance expiration.
    /// @notice if enterLimitBlock not provided (default 0), entrance expiration is the half way between created/expiration
    function decodeBlocks(
        bytes memory data
    )
        public
        pure
        returns (
            uint80 createdBlock,
            uint80 expirationBlock,
            uint80 enterLimitBlock
        )
    {
        (createdBlock, expirationBlock, enterLimitBlock) = abi.decode(
            data,
            (uint80, uint80, uint80)
        );
    }
}