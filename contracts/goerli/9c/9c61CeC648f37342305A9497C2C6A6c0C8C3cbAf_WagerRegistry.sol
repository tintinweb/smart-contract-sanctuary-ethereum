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
        uint256 wagerId
    );
    event WagerEntered(
        address indexed partyAddr,
        uint256 indexed partyWagerAmount,
        bytes partyWager,
        uint256 expirationBlock,
        address wagerModule,
        uint256 wagerId
    );
    event WagerCompleted(
        address indexed winner,
        uint256 indexed amount,
        uint256 indexed wagerId
    );
    event WagerWithdraw(
        address recipient,
        uint256 amount,
        uint256 indexed wagerId
    );
    event WagerVoided(uint256 indexed wagerId);

    // -- methods --
    function executeWinner(uint256 wagerId) external;

    function executeBlockRange(uint256 startBlock, uint256 endBlock) external;

    function enterWager(
        uint256 wagerId,
        bytes memory partyTwoWager
    ) external payable;

    function createWager(Wager memory wager) external payable returns (uint256);

    function voidWager(uint256 wagerId) external;

    function withdraw(uint256 wagerId) external;
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
    address partyOne;
    bytes partyOneWager;
    address partyTwo;
    bytes partyTwoWager;
    uint256 partyWagerAmount;
    uint256 createdBlock;
    uint80 expirationBlock;
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracle oracleImpl; // oracle impl
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
    function calculateWinner(Wager memory wager) external returns (address);
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
    mapping(uint256 => uint256[]) public executionSchedule;

    constructor() {}

    /// @notice createWager
    /// @dev
    /// @param wager wager to be created
    /// @return uint256 wager id
    function createWager(
        Wager memory wager
    ) external payable override returns (uint256) {
        uint256 id = _idCounter.current();

        require(wager.expirationBlock >= block.number + 15, "W12");
        require(wager.partyOne != address(0), "W13");
        require(wager.partyOneWager.length > 0, "W14");
        require(msg.value >= wager.partyWagerAmount, "W9");

        wagers[id] = wager;
        _idCounter.increment();
        emit WagerCreated(
            msg.sender,
            msg.value,
            wager.partyOneWager,
            wager.createdBlock,
            wager.expirationBlock,
            address(wager.wagerModule),
            id
        );
        return id;
    }

    /// @notice enterWager
    /// @dev
    /// @param wagerId id of wager to be entered by second party
    /// @param partyTwoWager second party's supplemental data for their specific wager
    function enterWager(
        uint256 wagerId,
        bytes memory partyTwoWager
    ) external payable override {
        require(wagerId <= _idCounter.current(), "W1");

        Wager memory wager = wagers[wagerId];
        require(
            wager.state == WagerState.created &&
                wager.state != WagerState.completed,
            "W2"
        );

        require(wager.expirationBlock >= block.number + 15, "W7");
        require(msg.sender != wager.partyOne, "W8");
        require(msg.value >= wager.partyWagerAmount, "W9");
        require(
            (wager.partyTwoWager.length == 0 && wager.partyTwo == address(0)) ||
                ((wager.partyTwoWager.length > 0 && partyTwoWager.length > 0) &&
                    bytes32(wager.partyTwoWager) == bytes32(partyTwoWager)),
            "W10"
        );

        wager.partyTwo = msg.sender;
        wager.partyTwoWager = partyTwoWager;
        wager.state = WagerState.active;
        executionSchedule[wager.expirationBlock].push(wagerId);
        wagers[wagerId] = wager;

        emit WagerEntered(
            msg.sender,
            msg.value,
            partyTwoWager,
            block.number,
            address(wager.wagerModule),
            wagerId
        );
    }

    /// @notice executeWinner
    /// @dev
    /// @param wagerId id of wager to be settled
    function executeWinner(uint256 wagerId) external override {
        require(wagerId <= _idCounter.current(), "W1");

        Wager memory wager = wagers[wagerId];
        require(
            wager.state == WagerState.active &&
                wager.state != WagerState.completed,
            "W2"
        );
        require(block.number >= wager.expirationBlock, "W3");

        address winner = IWagerModule(wager.wagerModule).calculateWinner(wager);
        wager.state = WagerState.completed;
        wagers[wagerId] = wager;

        (bool sent, ) = winner.call{value: uint256(wager.partyWagerAmount * 2)}(
            ""
        );
        require(sent, "W11");

        emit WagerCompleted(winner, wager.partyWagerAmount * 2, wagerId);
    }

    function executeBlockRange(
        uint256 startBlock,
        uint256 endBlock
    ) external override {
        for (uint256 block_ = startBlock; block_ <= endBlock; block_++) {
            uint256[] memory ids = executionSchedule[block_];
            for (uint256 j = 0; j < ids.length; j++) {
                this.executeWinner(ids[j]);
            }
        }
    }

    /// @notice voidWager
    /// @dev
    /// @param wagerId id of wager to be voided & respective parties refunded
    function voidWager(uint256 wagerId) external override {
        require(wagerId <= _idCounter.current(), "W1");

        Wager memory wager = wagers[wagerId];
        wager.state = WagerState.voided;
        require(
            msg.sender == wager.partyOne || msg.sender == wager.partyTwo,
            "W4"
        );

        (bool sent, ) = wager.partyOne.call{
            value: uint256(wager.partyWagerAmount)
        }("");
        require(sent, "W6");
        (bool sentTwo, ) = wager.partyTwo.call{
            value: uint256(wager.partyWagerAmount)
        }("");
        require(sentTwo, "W6");

        emit WagerVoided(wagerId);
    }

    /// @notice withdraw
    /// @dev
    /// @param wagerId id of wager who's funds are to be withdrawn by one of the parties
    function withdraw(uint256 wagerId) external override {
        require(wagerId <= _idCounter.current(), "W1");

        Wager memory wager = wagers[wagerId];
        require(
            msg.sender == wager.partyOne || msg.sender == wager.partyTwo,
            "W4"
        );

        uint256 value = wager.partyWagerAmount;
        require(uint256(value) >= address(this).balance, "W5");

        emit WagerWithdraw(msg.sender, value, wagerId);
        (bool sent, ) = msg.sender.call{value: uint256(value)}("");
        require(sent, "W6");

        this.voidWager(wagerId);
    }
}