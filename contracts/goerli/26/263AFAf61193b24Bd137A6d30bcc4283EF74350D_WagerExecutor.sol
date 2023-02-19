// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./wagers/IWagerModule.sol";

/**
 @title IWagerRegistry
 @author Henry Wrightman

 @notice Interface for wager registry
 */

interface IWagerRegistry {
    // -- events --
    event WagerCreated(
        address indexed partyAddr,
        uint256 partyWagerAmount,
        bytes partyWager,
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
        bytes memory partyTwoEquityData,
        bytes memory partyTwoWager
    ) external payable;

    function createWager(Wager memory wager) external payable;

    function voidWager(uint256 wagerId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../wagers/IWagerModule.sol";

/**
 @title IWagerOracleModule
 @author Henry Wrightman

 @notice interface for wager's oracle module (e.g ChainLinkOracleModule)
 */

interface IWagerOracleModule {
    // -- methods --
    function getResult(Wager memory wager) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../oracles/IWagerOracleModule.sol";

/**
 @title IWagerModule
 @author Henry Wrightman

 @notice Interface for wagers
 */

interface IWagerModule {
    // -- methods --
    function settle(
        Wager memory wager
    ) external returns (Wager memory, address);
}

// -- structs --
struct Wager {
    bytes parties; // party data; |partyOne|partyTwo|
    bytes partyOneWagerData; // wager data for wager module to discern; e.g |wagerStart|wagerValue|
    bytes partyTwoWagerData;
    bytes equityData; // wager equity data; |WagerType|ercContractAddr(s)|amount(s)|tokenId(s)|
    bytes blockData; // blocktime data; |created|expiration|enterLimit|
    bytes result; // wager outcome
    WagerState state;
    IWagerModule wagerModule; // wager semantics
    IWagerOracleModule oracleModule; // oracle module semantics
    address oracleSource; // oracle source
    bytes supplementalOracleData; // supplemental wager oracle data
}

// -- wager type
enum WagerType {
    oneSided,
    twoSided
}

// -- wager states
enum WagerState {
    active,
    created,
    completed,
    voided
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "../interfaces/IWagerRegistry.sol";

/**
 @title WagerExecutor
 @author Henry Wrightman

 ChainLink-compatible automation contract
 @notice upkeep scheduler for wager executions
 */

contract WagerExecutor is AutomationCompatibleInterface {
    address public registry;

    uint256 public lastBlock;
    uint public executions;

    constructor(address registryAddress) {
        lastBlock = block.number;
        executions = 0;
        registry = registryAddress;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.number - lastBlock) > 0;
        if (upkeepNeeded) {
            IWagerRegistry(registry).executeBlockRange(lastBlock, block.number);
            executions++;
        }
        lastBlock = block.number;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {}
}