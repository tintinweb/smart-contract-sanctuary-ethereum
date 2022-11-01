// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// UpkeepIDConsumerExample.sol imports functions from both ./AutomationRegistryInterface1_2.sol and
// ./interfaces/LinkTokenInterface.sol
import {AutomationRegistryInterface, State, Config} from '@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

// Just a simple contracts that keep counts of how many times it's called
import '@openzeppelin/contracts/utils/Counters.sol';

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

contract SelfAutomatingContract {
    using Counters for Counters.Counter;

    Counters.Counter private _counterIDCounter; // Counter ID

    mapping(uint256 => uint256) public counterToValue;
    mapping(uint256 => uint256) public counterToLastTimeStamp;
    mapping(uint256 => uint256) public counterToUpkeepID;

    uint256 public interval = 60 * 3;

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    // -- ERRORS --
    error UpkeepNotNeeded(uint timePassed);

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        // GOERLI: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        i_link = _link;
        // GOERLI: 0x9806cf6fBc89aBF286e8140C42174B94836e36F2
        registrar = _registrar;
        // GOERLI: 0x02777053d6764996e594c3E88AF1D58D5363a2e6
        i_registry = _registry;
    }

    function createNewCounter() public returns (uint256) {
        uint256 counterID = _counterIDCounter.current();

        _counterIDCounter.increment();

        counterToValue[counterID] = 0;

        counterToLastTimeStamp[counterID] = block.timestamp;

        return counterID;
    }

    function registerAndPredictID(
        string memory name,
        uint32 gasLimit,
        uint96 amount
    ) public {
        (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
        uint256 oldNonce = state.nonce;

        // Create a new counter and pass in as the checkData
        uint256 counterID = createNewCounter();
        bytes memory checkData = abi.encodePacked(counterID);
        bytes memory payload = abi.encode(
            name,
            '0x', // bytes calldata encryptedEmail
            address(this), // address upkeepContract
            gasLimit,
            address(msg.sender), // address adminAddress
            checkData,
            amount,
            0, // uint8 source
            address(this)
        );

        // Transfer Link and call the registrar
        i_link.transferAndCall(registrar, amount, bytes.concat(registerSig, payload));
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;

        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), address(i_registry), uint32(oldNonce)))
            );
            // Set the upkeepID
            counterToUpkeepID[counterID] = upkeepID;
        } else {
            revert('auto-approve disabled');
        }
    }

    function checkConditions(uint256 counterID) internal view returns (bool upkeepNeeded) {
        upkeepNeeded = (block.timestamp - counterToLastTimeStamp[counterID]) > interval;
    }

    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        // decode the checkData
        uint256 counterID = abi.decode(checkData, (uint256));

        upkeepNeeded = checkConditions(counterID);

        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external {
        // decode the checkData
        uint256 counterID = abi.decode(performData, (uint256));

        // Check if this function is called by the checkUpKeep function or a possible attacker by re-checking the Conditions
        if (!checkConditions(counterID)) {
            revert UpkeepNotNeeded(block.timestamp - counterToLastTimeStamp[counterID]);
        }

        counterToLastTimeStamp[counterID] = block.timestamp;

        counterToValue[counterID] = counterToValue[counterID] + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
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
library Counters {
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}