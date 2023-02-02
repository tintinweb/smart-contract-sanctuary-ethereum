// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./wagers/IWagerModule.sol";

interface IWagerRegistry {
    // -- events --
    event WagerCreated(
        address indexed partyAddr,
        uint256 indexed partyWagerAmount,
        bytes partyWager,
        uint256 createdBlock,
        uint256 expirationBlock,
        address wagerModule,
        address oracleModule,
        uint256 wagerId
    );
    event WagerEntered(
        address indexed partyAddr,
        bytes partyWager,
        uint256 wagerId
    );
    event WagerCompleted(
        address indexed winner,
        uint256 amount,
        bytes result,
        uint256 indexed wagerId
    );
    event WagerWithdraw(
        address recipient,
        uint256 amount,
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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 @title WagerRegistry
 @author Henry Wrightman

 @notice registry contract for wager management
 */

contract WagerRegistry is IWagerRegistry {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _idCounter;

    mapping(uint256 => Wager) public wagers;
    mapping(uint256 => uint256[]) public executionSchedule; // blockNumber -> [1, 2, 3]

    constructor() {}

    /// @notice createWager
    /// @dev
    /// @param wager wager to be created
    /// @return uint256 wager id
    function createWager(
        Wager memory wager
    ) external payable override returns (uint256) {
        uint256 id = _idCounter.current();
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
        _idCounter.increment();
        emit WagerCreated(
            msg.sender,
            msg.value,
            wager.partyOneWagerData,
            block.number,
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
        require(wagerId <= _idCounter.current(), "W1");

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
        require(wagerId <= _idCounter.current(), "W1");
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

        (bool sent, ) = payable(winner).call{
            value: uint256(wager.wagerAmount * 2)
        }("");
        require(sent, "W11");

        emit WagerCompleted(
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
                this.settleWager(ids[j]);
            }
        }
    }

    /// @notice voidWager
    /// @dev
    /// @param wagerId id of wager to be voided & respective parties refunded
    function voidWager(uint256 wagerId) external override {
        require(wagerId <= _idCounter.current(), "W1");

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

        (bool sent, ) = payable(partyOne).call{value: wager.wagerAmount}("");
        require(sent, "W6");
        if (partyTwo != address(0)) {
            (bool sentTwo, ) = payable(partyTwo).call{value: wager.wagerAmount}(
                ""
            );
            require(sentTwo, "W6");
        }

        emit WagerVoided(wagerId);
    }

    function decodeParties(
        bytes memory data
    ) public pure returns (address partyOne, address partyTwo) {
        (partyOne, partyTwo) = abi.decode(data, (address, address));
    }

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