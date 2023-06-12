// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "../../external/Functions.sol";
import "../../interfaces/ICrossChainPoolModule.sol";
import "../../interfaces/ICrossChainUpkeepModule.sol";
import "../../interfaces/IPoolModule.sol";
import "../../interfaces/IMulticallModule.sol";
import "../../storage/Config.sol";
import "../../storage/CrossChain.sol";
import "../../storage/Pool.sol";

import "@synthetixio/core-modules/contracts/storage/FeatureFlag.sol";

contract CrossChainUpkeepModule is ICrossChainUpkeepModule {
    using Functions for Functions.Request;
    using CrossChain for CrossChain.Data;
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using SafeCastU128 for uint128;
    using Distribution for Distribution.Data;
    using Pool for Pool.Data;

    error PoolAlreadyExists(uint128, uint256);

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    bytes32 internal constant _CREATE_CROSS_CHAIN_POOL_FEATURE_FLAG = "createCrossChainPool";
    bytes32 internal constant _SET_CROSS_CHAIN_POOL_CONFIGURATION_FEATURE_FLAG =
        "setCrossChainPoolConfiguration";

    string internal constant _CONFIG_CHAINLINK_FUNCTIONS_ADDRESS = "chainlinkFunctionsAddr";

    string internal constant _REQUEST_TOTAL_DEBT_CODE =
        "const maxFail = 1;"
        "const chainMapping = { '11155111': [`https://sepolia.infura.io/${secrets.INFURA_API_KEY}`], '80001': ['https://polygon-mumbai.infura.io/${secrets.INFURA_API_KEY}'] };"
        "let responses = [];"
        "for (let i = 0;i < args.length;i += 2) {"
        "    const chainId = Functions.decodeUint256(args[i]);"
        "    const callHex = args[i + 1];"
        "    const urls = chainMapping[chainId];"
        "    const params = { method: 'eth_call', params: [{ to: '0xffffffaeff0b96ea8e4f94b2253f31abdd875847', data: callHex }] };"
        "    const results = await Promise.allSettled(urls.map(u => Functions.makeHttpRequest({ url, params })));"
        "    let ress = 0;"
        "    for (const result of results) {"
        "        ress.push(Functions.decodeInt256(res.data.result));"
        "    }"
        "    ress.sort();"
        "    responses.push(ress[ress.length / 2].slice(2));"
        "}"
        "return Buffer.from(responses.join(''));";
    bytes internal constant _REQUEST_TOTAL_DEBT_SECRETS = "0xwhatever";

    /**
     * @notice Callback that is invoked once the DON has resolved the request or hit an error
     *
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external override {
        // TODO: check that chainlink functions oracle is the one sending this call

        if (err.length > 0) {
            return;
        }

        // TODO: be a real pool id
        Pool.Data storage pool = Pool.load(
            uint128(uint256(CrossChain.load().chainlinkFunctionsRequestInfo[requestId]))
        );

        uint256 chainsCount = pool.crossChain[0].pairedChains.length;

        uint256[] memory liquidityAmounts = new uint256[](chainsCount);

        PoolCrossChainSync.Data memory sync;

        sync.dataTimestamp = uint64(block.timestamp);

        for (uint i = 0; i < chainsCount; i++) {
            (
                uint256 chainLiquidity,
                int256 chainCumulativeMarketDebt,
                int256 chainTotalDebt,
                uint256 chainSyncTime,
                uint256 chainLastPoolConfigTime
            ) = abi.decode(response, (uint256, int256, int256, uint256, uint256));

            liquidityAmounts[i] = chainLiquidity;
            sync.liquidity += chainLiquidity.to128();
            sync.cumulativeMarketDebt += chainCumulativeMarketDebt.to128();
            sync.totalDebt += chainTotalDebt.to128();

            sync.oldestDataTimestamp = sync.oldestDataTimestamp < chainSyncTime
                ? sync.oldestDataTimestamp
                : uint64(chainSyncTime);
            sync.oldestPoolConfigTimestamp = sync.oldestPoolConfigTimestamp <
                chainLastPoolConfigTime
                ? sync.oldestPoolConfigTimestamp
                : uint64(chainLastPoolConfigTime);
        }

        int256 marketDebtChange = sync.cumulativeMarketDebt -
            pool.crossChain[0].latestSync.cumulativeMarketDebt;
        int256 remainingDebt = marketDebtChange;

        // send sync message
        for (uint i = 1; i < chainsCount; i++) {
            uint64[] memory targetChainIds = new uint64[](1);
            targetChainIds[0] = pool.crossChain[0].pairedChains[i];

            int256 chainAssignedDebt = (marketDebtChange * liquidityAmounts[i].toInt()) /
                sync.liquidity.toInt();
            remainingDebt -= chainAssignedDebt;

            // TODO: gas limit should be based on number of markets assigned to pool
            // TODO: broadcast will be paid in LINK
            CrossChain.load().broadcast(
                targetChainIds,
                abi.encodeWithSelector(
                    this._recvPoolHeartbeat.selector,
                    pool.crossChain[0].pairedPoolIds[targetChainIds[0]],
                    sync,
                    chainAssignedDebt
                ),
                3000000
            );
        }

        _receivePoolHeartbeat(pool.id, sync, remainingDebt);
    }

    function _recvPoolHeartbeat(
        uint128 poolId,
        PoolCrossChainSync.Data memory syncData,
        int256 assignedDebt
    ) external override {
        _receivePoolHeartbeat(poolId, syncData, assignedDebt);
    }

    function _receivePoolHeartbeat(
        uint128 poolId,
        PoolCrossChainSync.Data memory syncData,
        int256 assignedDebt
    ) internal {
        Pool.Data storage pool = Pool.loadExisting(poolId);

        // record sync data
        pool.setCrossChainSyncData(syncData);

        // assign accumulated debt
        pool.distributeDebtToVaults(assignedDebt);

        // make sure the markets limits are set as expect
        pool.recalculateAllCollaterals();

        emit PoolHeartbeat(poolId, syncData);
    }

    /**
     * @notice Used by Automation to check if performUpkeep should be called.
     *
     * The function's argument is unused in this example, but there is an option to have Automation pass custom data
     * that can be used by the checkUpkeep function.
     *
     * Returns a tuple where the first element is a boolean which determines if upkeep is needed and the
     * second element contains custom bytes data which is passed to performUpkeep when it is called by Automation.
     */
    function checkUpkeep(
        bytes memory data
    ) public view override returns (bool upkeepNeeded, bytes memory) {
        uint poolId = abi.decode(data, (uint));
        Pool.Data storage pool = Pool.loadExisting(abi.decode(data, (uint128)));

        upkeepNeeded =
            (block.timestamp - pool.crossChain[0].latestSync.dataTimestamp) >
            pool.crossChain[0].chainlinkSubscriptionInterval;
    }

    /**
     * @notice Called by Automation to trigger a Functions request
     *
     * The function's argument is unused in this example, but there is an option to have Automation pass custom data
     * returned by checkUpkeep (See Chainlink Automation documentation)
     */
    function performUpkeep(bytes calldata data) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        uint128 poolId = abi.decode(data, (uint128));
        Pool.Data storage pool = Pool.loadExisting(poolId);

        // take this opporitunity to rebalance the markets in this pool
        // we do it here instaed of fulfill because there is no reason for this to fail if for some reason the function fails

        string[] memory args = new string[](pool.crossChain[0].pairedChains.length * 2);
        args[0] = string(abi.encode(block.chainid));
        args[1] = string(_encodeCrossChainPoolCall(poolId));

        for (uint i = 0; i < args.length; i += 2) {
            uint64 chainId = pool.crossChain[0].pairedChains[i / 2];
            args[i] = string(abi.encode(chainId));

            args[i + 1] = string(
                _encodeCrossChainPoolCall(pool.crossChain[0].pairedPoolIds[chainId])
            );
        }

        Functions.Request memory req = Functions.Request({
            codeLocation: Functions.Location.Inline,
            secretsLocation: Functions.Location.Inline,
            language: Functions.CodeLanguage.JavaScript,
            source: _REQUEST_TOTAL_DEBT_CODE,
            secrets: _REQUEST_TOTAL_DEBT_SECRETS,
            args: args
        });
        bytes32 requestId = CrossChain.load().chainlinkFunctionsOracle.sendRequest(
            pool.crossChain[0].chainlinkSubscriptionId,
            abi.encode(req),
            100000
        );

        CrossChain.load().chainlinkFunctionsRequestInfo[requestId] = bytes32(uint256(pool.id));
    }

    function _encodeCrossChainPoolCall(uint128 poolId) internal pure returns (bytes memory) {
        bytes[] memory calls = new bytes[](4);
        calls[0] = abi.encodeWithSelector(
            ICrossChainPoolModule.getThisChainPoolLiquidity.selector,
            poolId
        );
        calls[1] = abi.encodeWithSelector(
            ICrossChainPoolModule.getThisChainPoolCumulativeMarketDebt.selector,
            poolId
        );
        calls[2] = abi.encodeWithSelector(
            ICrossChainPoolModule.getThisChainPoolTotalDebt.selector,
            poolId
        );
        calls[3] = abi.encodeWithSelector(
            ICrossChainPoolModule.getPoolLastHeartbeat.selector,
            poolId
        );
        calls[4] = abi.encodeWithSelector(
            IPoolModule.getPoolLastConfigurationTime.selector,
            poolId
        );

        return abi.encodeWithSelector(IMulticallModule.multicall.selector, abi.encode(calls));
    }

    function getDONPublicKey() external view returns (bytes memory) {
        return "";
    }
}

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

// Eth Heap
// Author: Zac Mitton
// License: MIT

library HeapUtil {
    // default max-heap

    uint private constant _ROOT_INDEX = 1;

    struct Data {
        uint128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(uint128 => uint) indices; // unique id => node index
    }
    struct Node {
        uint128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(Data storage self, uint128 id, int128 priority) internal returns (Node memory) {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init

        Node memory n;

        // MODIFIED: support updates
        extractById(self, id);

        self.idCount++;
        self.nodes.push();
        n = Node(id, priority);
        _bubbleUp(self, n, self.nodes.length - 1);

        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, _ROOT_INDEX);
    }

    function extractById(Data storage self, uint128 id) internal returns (Node memory) {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, uint128 id) internal view returns (Node memory) {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint i) internal view returns (Node memory) {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, _ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint i) private returns (Node memory) {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        self.nodes.pop();

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(Data storage self, Node memory n, uint i) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(Data storage self, Node memory n, uint i) private {
        //
        uint length = self.nodes.length;
        uint cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (length > cIndex + 1 && self.nodes[cIndex + 1].priority > largestChild.priority) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(Data storage self, Node memory n, uint i) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint value, uint newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        delete set._positions[value];

        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable(bytes32 which);

    struct Data {
        bytes32 name;
        bool allowAll;
        bool denyAll;
        SetUtil.AddressSet permissionedAddresses;
        address[] deniers;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, msg.sender)) {
            revert FeatureUnavailable(feature);
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        if (store.denyAll) {
            return false;
        }

        return store.allowAll || store.permissionedAddresses.contains(value);
    }

    function isDenier(Data storage self, address possibleDenier) internal view returns (bool) {
        for (uint i = 0; i < self.deniers.length; i++) {
            if (self.deniers[i] == possibleDenier) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return nodeId The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return nodeId The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return node The node's definition data
     */
    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory node);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return node The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory node);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER,
        CONSTANT
    }

    struct Data {
        /**
         * @dev Oracle node type enum
         */
        NodeType nodeType;
        /**
         * @dev Node parameters, specific to each node type
         */
        bytes parameters;
        /**
         * @dev Parent node IDs, if any
         */
        bytes32[] parents;
    }

    /**
     * @dev Returns the node stored at the specified node ID.
     */
    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    /**
     * @dev Register a new node for a given node definition. The resulting node is a function of the definition.
     */
    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    /**
     * @dev Returns a node ID based on its definition
     */
    function getId(Data memory nodeDefinition) internal pure returns (bytes32 id) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        /**
         * @dev Price returned from the oracle node, expressed with 18 decimals of precision
         */
        int256 price;
        /**
         * @dev Timestamp associated with the price
         */
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.4;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for appending to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library Buffer {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            let fpm := add(32, add(ptr, capacity))
            if lt(fpm, ptr) {
                revert(0, 0)
            }
            mstore(0x40, fpm)
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
     * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= data.length);

        uint256 off = buf.buf.length;
        uint256 newCapacity = off + len;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(newCapacity, buflen) {
                mstore(bufptr, newCapacity)
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return append(buf, data, data.length);
    }

    /**
     * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 offPlusOne = off + 1;
        if (off >= buf.capacity) {
            resize(buf, offPlusOne * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if gt(offPlusOne, mload(bufptr)) {
                mstore(bufptr, offPlusOne)
            }
        }

        return buf;
    }

    /**
     * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (left-aligned).
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes32 data,
        uint256 len
    ) private pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        unchecked {
            uint256 mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + newCapacity
                let dest := add(bufptr, newCapacity)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(newCapacity, mload(bufptr)) {
                    mstore(bufptr, newCapacity)
                }
            }
        }
        return buf;
    }

    /**
     * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chhaining.
     */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return append(buf, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return append(buf, data, 32);
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer.
     */
    function appendInt(
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        uint256 off = buf.buf.length;
        uint256 newCapacity = len + off;
        if (newCapacity > buf.capacity) {
            resize(buf, newCapacity * 2);
        }

        uint256 mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + newCapacity
            let dest := add(bufptr, newCapacity)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(newCapacity, mload(bufptr)) {
                mstore(bufptr, newCapacity)
            }
        }
        return buf;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Buffer.sol";

/**
 * @dev A library for populating CBOR encoded payload in Solidity.
 *
 * https://datatracker.ietf.org/doc/html/rfc7049
 *
 * The library offers various write* and start* methods to encode values of different types.
 * The resulted buffer can be obtained with data() method.
 * Encoding of primitive types is staightforward, whereas encoding of sequences can result
 * in an invalid CBOR if start/write/end flow is violated.
 * For the purpose of gas saving, the library does not verify start/write/end flow internally,
 * except for nested start/end pairs.
 */

library CBOR {
    using Buffer for Buffer.buffer;

    struct CBORBuffer {
        Buffer.buffer buf;
        uint256 depth;
    }

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    uint8 private constant CBOR_FALSE = 20;
    uint8 private constant CBOR_TRUE = 21;
    uint8 private constant CBOR_NULL = 22;
    uint8 private constant CBOR_UNDEFINED = 23;

    function create(uint256 capacity) internal pure returns (CBORBuffer memory cbor) {
        Buffer.init(cbor.buf, capacity);
        cbor.depth = 0;
        return cbor;
    }

    function data(CBORBuffer memory buf) internal pure returns (bytes memory) {
        require(buf.depth == 0, "Invalid CBOR");
        return buf.buf.buf;
    }

    function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        writeBytes(buf, abi.encode(value));
    }

    function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
        if (value < 0) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
            writeBytes(buf, abi.encode(uint256(-1 - value)));
        } else {
            writeUInt256(buf, uint256(value));
        }
    }

    function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
    }

    function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
        if (value >= 0) {
            writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        } else {
            writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
        }
    }

    function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.buf.append(value);
    }

    function writeString(CBORBuffer memory buf, string memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.buf.append(bytes(value));
    }

    function writeBool(CBORBuffer memory buf, bool value) internal pure {
        writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
    }

    function writeNull(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_NULL);
    }

    function writeUndefined(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_UNDEFINED);
    }

    function startArray(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
        buf.depth += 1;
    }

    function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
    }

    function startMap(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
        buf.depth += 1;
    }

    function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
    }

    function endSequence(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
        buf.depth -= 1;
    }

    function writeKVString(
        CBORBuffer memory buf,
        string memory key,
        string memory value
    ) internal pure {
        writeString(buf, key);
        writeString(buf, value);
    }

    function writeKVBytes(
        CBORBuffer memory buf,
        string memory key,
        bytes memory value
    ) internal pure {
        writeString(buf, key);
        writeBytes(buf, value);
    }

    function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
        writeString(buf, key);
        writeUInt256(buf, value);
    }

    function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
        writeString(buf, key);
        writeInt256(buf, value);
    }

    function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
        writeString(buf, key);
        writeUInt64(buf, value);
    }

    function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
        writeString(buf, key);
        writeInt64(buf, value);
    }

    function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
        writeString(buf, key);
        writeBool(buf, value);
    }

    function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeNull(buf);
    }

    function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeUndefined(buf);
    }

    function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startMap(buf);
    }

    function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startArray(buf);
    }

    function writeFixedNumeric(CBORBuffer memory buf, uint8 major, uint64 value) private pure {
        if (value <= 23) {
            buf.buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.buf.appendUint8(uint8((major << 5) | 24));
            buf.buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 25));
            buf.buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 26));
            buf.buf.appendInt(value, 4);
        } else {
            buf.buf.appendUint8(uint8((major << 5) | 27));
            buf.buf.appendInt(value, 8);
        }
    }

    function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major) private pure {
        buf.buf.appendUint8(uint8((major << 5) | 31));
    }

    function writeDefiniteLengthType(
        CBORBuffer memory buf,
        uint8 major,
        uint64 length
    ) private pure {
        writeFixedNumeric(buf, major, length);
    }

    function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {CBOR, Buffer} from "./CBOR.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
    uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

    using CBOR for Buffer.buffer;

    enum Location {
        Inline,
        Remote
    }

    enum CodeLanguage {
        JavaScript
        // In future version we may add other languages
    }

    struct Request {
        Location codeLocation;
        Location secretsLocation;
        CodeLanguage language;
        string source; // Source code for Location.Inline or url for Location.Remote
        bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
        string[] args;
    }

    error EmptySource();
    error EmptyUrl();
    error EmptySecrets();
    error EmptyArgs();
    error NoInlineSecrets();

    /**
     * @notice Encodes a Request to CBOR encoded bytes
     * @param self The request to encode
     * @return CBOR encoded bytes
     */
    function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buffer;
        Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

        CBOR.writeString(buffer, "codeLocation");
        CBOR.writeUInt256(buffer, uint256(self.codeLocation));

        CBOR.writeString(buffer, "language");
        CBOR.writeUInt256(buffer, uint256(self.language));

        CBOR.writeString(buffer, "source");
        CBOR.writeString(buffer, self.source);

        if (self.args.length > 0) {
            CBOR.writeString(buffer, "args");
            CBOR.startArray(buffer);
            for (uint256 i = 0; i < self.args.length; i++) {
                CBOR.writeString(buffer, self.args[i]);
            }
            CBOR.endSequence(buffer);
        }

        if (self.secrets.length > 0) {
            if (self.secretsLocation == Location.Inline) {
                revert NoInlineSecrets();
            }
            CBOR.writeString(buffer, "secretsLocation");
            CBOR.writeUInt256(buffer, uint256(self.secretsLocation));
            CBOR.writeString(buffer, "secrets");
            CBOR.writeBytes(buffer, self.secrets);
        }

        return buffer.buf.buf;
    }

    /**
     * @notice Initializes a Chainlink Functions Request
     * @dev Sets the codeLocation and code on the request
     * @param self The uninitialized request
     * @param location The user provided source code location
     * @param language The programming language of the user code
     * @param source The user provided source code or a url
     */
    function initializeRequest(
        Request memory self,
        Location location,
        CodeLanguage language,
        string memory source
    ) internal pure {
        if (bytes(source).length == 0) revert EmptySource();

        self.codeLocation = location;
        self.language = language;
        self.source = source;
    }

    /**
     * @notice Initializes a Chainlink Functions Request
     * @dev Simplified version of initializeRequest for PoC
     * @param self The uninitialized request
     * @param javaScriptSource The user provided JS code (must not be empty)
     */
    function initializeRequestForInlineJavaScript(
        Request memory self,
        string memory javaScriptSource
    ) internal pure {
        initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
    }

    /**
     * @notice Adds Remote user encrypted secrets to a Request
     * @param self The initialized request
     * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
     */
    function addRemoteSecrets(
        Request memory self,
        bytes memory encryptedSecretsURLs
    ) internal pure {
        if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

        self.secretsLocation = Location.Remote;
        self.secrets = encryptedSecretsURLs;
    }

    /**
     * @notice Adds args for the user run function
     * @param self The initialized request
     * @param args The array of args (must not be empty)
     */
    function addArgs(Request memory self, string[] memory args) internal pure {
        if (args.length == 0) revert EmptyArgs();

        self.args = args;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface FunctionsBillingRegistryInterface {
    struct RequestBilling {
        // a unique subscription ID allocated by billing system,
        uint64 subscriptionId;
        // the client contract that initiated the request to the DON
        // to use the subscription it must be added as a consumer on the subscription
        address client;
        // customer specified gas limit for the fulfillment callback
        uint32 gasLimit;
        // the expected gas price used to execute the transaction
        uint256 gasPrice;
    }

    enum FulfillResult {
        USER_SUCCESS,
        USER_ERROR,
        INVALID_REQUEST_ID
    }

    /**
     * @notice Get configuration relevant for making requests
     * @return uint32 global max for request gas limit
     * @return address[] list of registered DONs
     */
    function getRequestConfig() external view returns (uint32, address[] memory);

    /**
     * @notice Determine the charged fee that will be paid to the Registry owner
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(
        bytes calldata data,
        FunctionsBillingRegistryInterface.RequestBilling memory billing
    ) external view returns (uint96);

    /**
     * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasPrice The request's billing configuration
     * @param donFee Fee charged by the DON that is paid to Oracle Node
     * @param registryFee Fee charged by the DON that is paid to Oracle Node
     * @return costEstimate Cost in Juels (1e18) of LINK
     */
    function estimateCost(
        uint32 gasLimit,
        uint256 gasPrice,
        uint96 donFee,
        uint96 registryFee
    ) external view returns (uint96);

    /**
     * @notice Initiate the billing process for an Functions request
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing Billing configuration for the request
     * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
     * @dev Only callable by a node that has been approved on the Registry
     */
    function startBilling(
        bytes calldata data,
        RequestBilling calldata billing
    ) external returns (bytes32);

    /**
     * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
     * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
     * @param response response data from DON consensus
     * @param err error from DON consensus
     * @param transmitter the Oracle who sent the report
     * @param signers the Oracles who had a part in generating the report
     * @param signerCount the number of signers on the report
     * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
     * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
     * @return result fulfillment result
     * @dev Only callable by a node that has been approved on the Registry
     * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
     */
    function fulfillAndBill(
        bytes32 requestId,
        bytes calldata response,
        bytes calldata err,
        address transmitter,
        address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
        uint8 signerCount,
        uint256 reportValidationGas,
        uint256 initialGas
    ) external returns (FulfillResult);

    /**
     * @notice Gets subscription owner.
     * @param subscriptionId - ID of the subscription
     * @return owner - owner of the subscription.
     */
    function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions client interface.
 */
interface FunctionsClientInterface {
    /**
     * @notice Returns the DON's secp256k1 public key used to encrypt secrets
     * @dev All Oracles nodes have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
     * @param requestId The requestId returned by FunctionsClient.sendRequest().
     * @param response Aggregated response from the user code.
     * @param err Aggregated error either from the user code or from the execution pipeline.
     * Either response or error parameter will be set, but never both.
     */
    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FunctionsBillingRegistryInterface.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
    /**
     * @notice Gets the stored billing registry address
     * @return registryAddress The address of Chainlink Functions billing registry contract
     */
    function getRegistry() external view returns (address);

    /**
     * @notice Sets the stored billing registry address
     * @param registryAddress The new address of Chainlink Functions billing registry contract
     */
    function setRegistry(address registryAddress) external;

    /**
     * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
     * @dev All nodes on the DON have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey the DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice Sets DON's secp256k1 public key used to encrypt secrets
     * @dev Used to rotate the key
     * @param donPublicKey The new public key
     */
    function setDONPublicKey(bytes calldata donPublicKey) external;

    /**
     * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
     * @dev Callable only by contract owner and DON members
     * @param node node's address
     * @param publicKey node's public key
     */
    function setNodePublicKey(address node, bytes calldata publicKey) external;

    /**
     * @notice Deletes node's public key
     * @dev Callable only by contract owner or the node itself
     * @param node node's address
     */
    function deleteNodePublicKey(address node) external;

    /**
     * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
     * public keys (or empty byte arrays if per-node key is not defined)
     */
    function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

    /**
     * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(
        bytes calldata data,
        FunctionsBillingRegistryInterface.RequestBilling calldata billing
    ) external view returns (uint96);

    /**
     * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return billedCost Cost in Juels (1e18) of LINK
     */
    function estimateCost(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit,
        uint256 gasPrice
    ) external view returns (uint96);

    /**
     * @notice Sends a request (encoded as data) using the provided subscriptionId
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return requestId A unique request identifier (unique per DON)
     */
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../utils/CcipClient.sol";

interface ICcipRouterClient {
    error UnsupportedDestinationChain(uint64 destinationChainId);
    /// @dev Sender is not whitelisted
    error SenderNotAllowed(address sender);
    error InsufficientFeeTokenAmount();
    /// @dev Sent msg.value with a non-empty feeToken
    error InvalidMsgValue();

    /// @notice Checks if the given chain ID is supported for sending/receiving.
    /// @param chainId The chain to check
    /// @return supported is true if it is supported, false if not
    function isChainSupported(uint64 chainId) external view returns (bool supported);

    /// @notice Gets a list of all supported tokens which can be sent or received
    /// to/from a given chain id.
    /// @param chainId The chainId.
    /// @return tokens The addresses of all tokens that are supported.
    function getSupportedTokens(uint64 chainId) external view returns (address[] memory tokens);

    /// @param destinationChainId The destination chain ID
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return fee returns execution fee for the specified message
    /// delivery to destination chain
    /// @dev returns 0 fee on invalid message.
    function getFee(
        uint64 destinationChainId,
        CcipClient.EVM2AnyMessage memory message
    ) external view returns (uint256 fee);

    /// @notice Request a message to be sent to the destination chain
    /// @param destinationChainId The destination chain ID
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return messageId The message ID
    /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
    /// the overpayment with no refund.
    function ccipSend(
        uint64 destinationChainId,
        CcipClient.EVM2AnyMessage calldata message
    ) external payable returns (bytes32 messageId);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface for markets integrated with Synthetix
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint256 if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint256);

    /// @notice prevents reduction of available credit capacity by specifying this amount, for which withdrawals will be disallowed
    function minimumCredit(uint128 marketId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a reward distributor.
interface IRewardDistributor is IERC165 {
    /// @notice Returns a human-readable name for the reward distributor
    function name() external returns (string memory);

    /// @notice This function should revert if msg.sender is not the Synthetix CoreProxy address.
    /// @return whether or not the payout was executed
    function payout(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address sender,
        uint256 amount
    ) external returns (bool);

    /// @notice This function is called by the Synthetix Core Proxy whenever
    /// a position is updated on a pool which this distributor is registered
    function onPositionUpdated(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newShares
    ) external;

    /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
    /// @dev Return address(0) if providing non ERC-20 rewards
    function token() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./external/FunctionsClientInterface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "../storage/MarketConfiguration.sol";
import "../storage/PoolCrossChainInfo.sol";

/**
 * @title Module for management of pools which are cross chain capable
 */
interface ICrossChainPoolModule {
    event PoolHeartbeat(uint128 poolId, PoolCrossChainSync.Data syncData);

    event CrossChainSecondaryPoolCreated(
        uint64 srcChainId,
        uint128 srcPoolId,
        uint128 thisChainPoolId
    );

    function createCrossChainPool(
        uint128 sourcePoolId,
        uint64 targetChainId
    ) external payable returns (uint128 crossChainPoolId, uint256 gasTokenUsed);

    function _recvCreateCrossChainPool(uint64 srcChainId, uint128 srcPoolId) external;

    function setCrossChainPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[][] memory newMarketConfigurations
    ) external payable returns (uint256 gasTokenUsed);

    function _recvSetCrossChainPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[] memory newMarketConfigurations,
        uint256 newTotalWeight,
        uint64 configTimestamp
    ) external;

    function getPoolCrossChainInfo(
        uint128 poolId
    )
        external
        view
        returns (uint64[] memory pairedChainIds, uint128 primaryPoolId, uint128 secondaryPoolId);

    function getThisChainPoolLiquidity(uint128 poolId) external view returns (uint256 liquidityD18);

    function getThisChainPoolCumulativeMarketDebt(
        uint128 poolId
    ) external returns (int256 cumulativeDebtD18);

    function getThisChainPoolTotalDebt(uint128 poolId) external view returns (int256 totalDebtD18);

    function getPoolLastHeartbeat(uint128 poolId) external view returns (uint64);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./external/FunctionsClientInterface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "../storage/MarketConfiguration.sol";
import "../storage/PoolCrossChainInfo.sol";

/**
 * @title Module for management of pools which are cross chain capable
 */
interface ICrossChainUpkeepModule is FunctionsClientInterface, AutomationCompatibleInterface {
    event PoolHeartbeat(uint128 poolId, PoolCrossChainSync.Data syncData);

    function _recvPoolHeartbeat(
        uint128 poolId,
        PoolCrossChainSync.Data memory syncData,
        int256 assignedDebt
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 */
interface IMulticallModule {
    /**
     * @notice Executes multiple transaction payloads in a single transaction.
     * @dev Each transaction is executed using `delegatecall`, and targets the system address.
     * @param data Array of calldata objects, one for each function that is to be called in the system.
     * @return results Array of each `delegatecall`'s response corresponding to the incoming calldata array.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Similar to `multicall`, but allows for transactions to be executed
     * @dev If the address specified in `to` iteration is not the core system, it will call the contract with a regular "call". If it is the core system, it will be delegatecall.
     * @dev Target `to` contracts will need to support calling the below `getMessageSender` rather than regular `msg.sender` in order to allow for usage of permissioned calls with this function
     * @dev It is not possible to call this function recursively.
     * @dev Fails immediately on revert of any call.
     * @return results Array of each call's response corresponding
     */
    /*function multicallThrough(
        address[] calldata to,
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    function getMessageSender() external view returns (address);*/
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/MarketConfiguration.sol";

/**
 * @title Module for the creation and management of pools.
 * @dev The pool owner can be specified during creation, can be transferred, and has credentials for configuring the pool.
 */
interface IPoolModule {
    /**
     * @notice Thrown when the requested pool ID is greater or equal to type(uint128).max / 2
     */
    error InvalidPoolId(uint128 poolId);

    /**
     * @notice Gets fired when pool will be created.
     * @param poolId The id of the newly created pool.
     * @param owner The owner of the newly created pool.
     * @param sender The address that triggered the creation of the pool.
     */
    event PoolCreated(uint128 indexed poolId, address indexed owner, address indexed sender);

    /**
     * @notice Gets fired when pool owner proposes a new owner.
     * @param poolId The id of the pool for which the nomination ocurred.
     * @param nominatedOwner The address that was nominated as the new owner of the pool.
     * @param owner The address of the current owner of the pool.
     */
    event PoolOwnerNominated(
        uint128 indexed poolId,
        address indexed nominatedOwner,
        address indexed owner
    );

    /**
     * @notice Gets fired when pool nominee accepts nomination.
     * @param poolId The id of the pool for which the owner nomination was accepted.
     * @param owner The address of the new owner of the pool, which accepted the nomination.
     */
    event PoolOwnershipAccepted(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool owner revokes nomination.
     * @param poolId The id of the pool in which the nomination was revoked.
     * @param owner The current owner of the pool.
     */
    event PoolNominationRevoked(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool nominee renounces nomination.
     * @param poolId The id of the pool for which the owner nomination was renounced.
     * @param owner The current owner of the pool.
     */
    event PoolNominationRenounced(uint128 indexed poolId, address indexed owner);

    /**
     * @notice Gets fired when pool name changes.
     * @param poolId The id of the pool whose name was updated.
     * @param name The new name of the pool.
     * @param sender The address that triggered the rename of the pool.
     */
    event PoolNameUpdated(uint128 indexed poolId, string name, address indexed sender);

    /**
     * @notice Gets fired when pool gets configured.
     * @param poolId The id of the pool whose configuration was set.
     * @param markets Array of configuration data of the markets that were connected to the pool.
     * @param sender The address that triggered the pool configuration.
     */
    event PoolConfigurationSet(
        uint128 indexed poolId,
        MarketConfiguration.Data[] markets,
        address indexed sender
    );

    /**
     * @notice Emitted when a system-wide minimum liquidity ratio is set
     * @param minLiquidityRatio The new system-wide minimum liquidity ratio
     */
    event SetMinLiquidityRatio(uint256 minLiquidityRatio);

    /**
     * @notice Creates a pool with the requested pool id.
     * @param requestedPoolId The requested id for the new pool. Reverts if the id is not available.
     * @param owner The address that will own the newly created pool.
     */
    function createPool(uint128 requestedPoolId, address owner) external;

    /**
     * @notice Allows the pool owner to configure the pool.
     * @dev The pool's configuration is composed of an array of MarketConfiguration objects, which describe which markets the pool provides liquidity to, in what proportion, and to what extent.
     * @dev Incoming market ids need to be provided in ascending order.
     * @param poolId The id of the pool whose configuration is being set.
     * @param marketDistribution The array of market configuration objects that define the list of markets that are connected to the system.
     */
    function setPoolConfiguration(
        uint128 poolId,
        MarketConfiguration.Data[] memory marketDistribution
    ) external;

    /**
     * @notice Retrieves the MarketConfiguration of the specified pool.
     * @param poolId The id of the pool whose configuration is being queried.
     * @return markets The array of MarketConfiguration objects that describe the pool's configuration.
     */
    function getPoolConfiguration(
        uint128 poolId
    ) external view returns (MarketConfiguration.Data[] memory markets);

    /**
     * @notice Retrieves the unix timestamp of the last time this pool configuration was updated.
     * @dev If the pool is cross chain, this value will be the timestamp reported by the primary chain
     * @return the configuration timestamp
     */
    function getPoolLastConfigurationTime(uint128 poolId) external view returns (uint64);

    /**
     * @notice Allows the owner of the pool to set the pool's name.
     * @param poolId The id of the pool whose name is being set.
     * @param name The new name to give to the pool.
     */
    function setPoolName(uint128 poolId, string memory name) external;

    /**
     * @notice Returns the pool's name.
     * @param poolId The id of the pool whose name is being queried.
     * @return poolName The current name of the pool.
     */
    function getPoolName(uint128 poolId) external view returns (string memory poolName);

    /**
     * @notice Allows the current pool owner to nominate a new owner.
     * @param nominatedOwner The address to nominate os the new pool owner.
     * @param poolId The id whose ownership is being transferred.
     */
    function nominatePoolOwner(address nominatedOwner, uint128 poolId) external;

    /**
     * @notice After a new pool owner has been nominated, allows it to accept the nomination and thus ownership of the pool.
     * @param poolId The id of the pool for which the caller is to accept ownership.
     */
    function acceptPoolOwnership(uint128 poolId) external;

    /**
     * @notice After a new pool owner has been nominated, allows it to reject the nomination.
     * @param poolId The id of the pool for which the new owner nomination is to be revoked.
     */
    function revokePoolNomination(uint128 poolId) external;

    /**
     * @notice Allows the current nominated owner to renounce the nomination.
     * @param poolId The id of the pool for which the caller is renouncing ownership nomination.
     */
    function renouncePoolNomination(uint128 poolId) external;

    /**
     * @notice Returns the current pool owner.
     * @param poolId The id of the pool whose ownership is being queried.
     * @return owner The current owner of the pool.
     */
    function getPoolOwner(uint128 poolId) external view returns (address owner);

    /**
     * @notice Returns the current nominated pool owner.
     * @param poolId The id of the pool whose nominated owner is being queried.
     * @return nominatedOwner The current nominated owner of the pool.
     */
    function getNominatedPoolOwner(uint128 poolId) external view returns (address nominatedOwner);

    /**
     * @notice Allows the system owner (not the pool owner) to set the system-wide minimum liquidity ratio.
     * @param minLiquidityRatio The new system-wide minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function setMinLiquidityRatio(uint256 minLiquidityRatio) external;

    /**
     * @notice Retrieves the system-wide minimum liquidity ratio.
     * @return minRatioD18 The current system-wide minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function getMinLiquidityRatio() external view returns (uint256 minRatioD18);

    /**
     * @notice Distributes cached debt in a pool to its vaults and updates market credit capacities.
     */
    function rebalancePool(uint128 poolId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/NodeOutput.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./OracleManager.sol";

/**
 * @title Tracks system-wide settings for each collateral type, as well as helper functions for it, such as retrieving its current price from the oracle manager.
 */
library CollateralConfiguration {
    bytes32 private constant _SLOT_AVAILABLE_COLLATERALS =
        keccak256(
            abi.encode("io.synthetix.synthetix.CollateralConfiguration_availableCollaterals")
        );

    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the token address of a collateral cannot be found.
     */
    error CollateralNotFound();

    /**
     * @dev Thrown when deposits are disabled for the given collateral type.
     * @param collateralType The address of the collateral type for which depositing was disabled.
     */
    error CollateralDepositDisabled(address collateralType);

    /**
     * @dev Thrown when collateral ratio is not sufficient in a given operation in the system.
     * @param collateralValue The net USD value of the position.
     * @param debt The net USD debt of the position.
     * @param ratio The collateralization ratio of the position.
     * @param minRatio The minimum c-ratio which was not met. Could be issuance ratio or liquidation ratio, depending on the case.
     */
    error InsufficientCollateralRatio(
        uint256 collateralValue,
        uint256 debt,
        uint256 ratio,
        uint256 minRatio
    );

    /**
     * @dev Thrown when the amount being delegated is less than the minimum expected amount.
     * @param minDelegation The current minimum for deposits and delegation set to this collateral type.
     */
    error InsufficientDelegation(uint256 minDelegation);

    /**
     * @dev Thrown when attempting to convert a token to the system amount and the conversion results in a loss of precision.
     * @param tokenAmount The amount of tokens that were attempted to be converted.
     * @param decimals The number of decimals of the token that was attempted to be converted.
     */
    error PrecisionLost(uint256 tokenAmount, uint8 decimals);

    struct Data {
        /**
         * @dev Allows the owner to control deposits and delegation of collateral types.
         */
        bool depositingEnabled;
        /**
         * @dev System-wide collateralization ratio for issuance of snxUSD.
         * Accounts will not be able to mint snxUSD if they are below this issuance c-ratio.
         */
        uint256 issuanceRatioD18;
        /**
         * @dev System-wide collateralization ratio for liquidations of this collateral type.
         * Accounts below this c-ratio can be immediately liquidated.
         */
        uint256 liquidationRatioD18;
        /**
         * @dev Amount of tokens to award when an account is liquidated.
         */
        uint256 liquidationRewardD18;
        /**
         * @dev The oracle manager node id which reports the current price for this collateral type.
         */
        bytes32 oracleNodeId;
        /**
         * @dev The token address for this collateral type.
         */
        address tokenAddress;
        /**
         * @dev Minimum amount that accounts can delegate to pools.
         * Helps prevent spamming on the system.
         * Note: If zero, liquidationRewardD18 will be used.
         */
        uint256 minDelegationD18;
    }

    /**
     * @dev Loads the CollateralConfiguration object for the given collateral type.
     * @param token The address of the collateral type.
     * @return collateralConfiguration The CollateralConfiguration object.
     */
    function load(address token) internal pure returns (Data storage collateralConfiguration) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.CollateralConfiguration", token));
        assembly {
            collateralConfiguration.slot := s
        }
    }

    /**
     * @dev Loads all available collateral types configured in the system.
     * @return availableCollaterals An array of addresses, one for each collateral type supported by the system.
     */
    function loadAvailableCollaterals()
        internal
        pure
        returns (SetUtil.AddressSet storage availableCollaterals)
    {
        bytes32 s = _SLOT_AVAILABLE_COLLATERALS;
        assembly {
            availableCollaterals.slot := s
        }
    }

    /**
     * @dev Configures a collateral type.
     * @param config The CollateralConfiguration object with all the settings for the collateral type being configured.
     */
    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter(
                "minDelegation",
                "must be greater than liquidationReward"
            );
        }

        Data storage storedConfig = load(config.tokenAddress);

        storedConfig.tokenAddress = config.tokenAddress;
        storedConfig.issuanceRatioD18 = config.issuanceRatioD18;
        storedConfig.liquidationRatioD18 = config.liquidationRatioD18;
        storedConfig.oracleNodeId = config.oracleNodeId;
        storedConfig.liquidationRewardD18 = config.liquidationRewardD18;
        storedConfig.minDelegationD18 = config.minDelegationD18;
        storedConfig.depositingEnabled = config.depositingEnabled;
    }

    /**
     * @dev Shows if a given collateral type is enabled for deposits and delegation.
     * @param token The address of the collateral being queried.
     */
    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    /**
     * @dev Reverts if the amount being delegated is insufficient for the system.
     * @param token The address of the collateral type.
     * @param amountD18 The amount being checked for sufficient delegation.
     */
    function requireSufficientDelegation(address token, uint256 amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint256 minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    /**
     * @dev Returns the price of this collateral configuration object.
     * @param self The CollateralConfiguration object.
     * @return The price of the collateral with 18 decimals of precision.
     */
    function getCollateralPrice(Data storage self) internal view returns (uint256) {
        OracleManager.Data memory oracleManager = OracleManager.load();
        NodeOutput.Data memory node = INodeModule(oracleManager.oracleManagerAddress).process(
            self.oracleNodeId
        );

        return node.price.toUint();
    }

    /**
     * @dev Reverts if the specified collateral and debt values produce a collateralization ratio which is below the amount required for new issuance of snxUSD.
     * @param self The CollateralConfiguration object whose collateral and settings are being queried.
     * @param debtD18 The debt component of the ratio.
     * @param collateralValueD18 The collateral component of the ratio.
     */
    function verifyIssuanceRatio(
        Data storage self,
        uint256 debtD18,
        uint256 collateralValueD18
    ) internal view {
        if (
            debtD18 != 0 &&
            (collateralValueD18 == 0 ||
                collateralValueD18.divDecimal(debtD18) < self.issuanceRatioD18)
        ) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                self.issuanceRatioD18
            );
        }
    }

    /**
     * @dev Converts token amounts with non-system decimal precisions, to 18 decimals of precision.
     * E.g: $TOKEN_A uses 6 decimals of precision, so this would upscale it by 12 decimals.
     * E.g: $TOKEN_B uses 20 decimals of precision, so this would downscale it by 2 decimals.
     * @param self The CollateralConfiguration object corresponding to the collateral type being converted.
     * @param tokenAmount The token amount, denominated in its native decimal precision.
     * @return amountD18 The converted amount, denominated in the system's 18 decimal precision.
     */
    function convertTokenToSystemAmount(
        Data storage self,
        uint256 tokenAmount
    ) internal view returns (uint256 amountD18) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        /// @dev this try-catch block assumes there is no malicious code in the token's fallback function
        try IERC20(self.tokenAddress).decimals() returns (uint8 decimals) {
            if (decimals == 18) {
                amountD18 = tokenAmount;
            } else if (decimals < 18) {
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            } else {
                // ensure no precision is lost when converting to 18 decimals
                if (tokenAmount % (10 ** (decimals - 18)) != 0) {
                    revert PrecisionLost(tokenAmount, decimals);
                }

                // this will scale down the amount by the difference between the token's decimals and 18
                amountD18 = (tokenAmount * DecimalMath.UNIT) / (10 ** decimals);
            }
        } catch {
            // if the token doesn't have a decimals function, assume it's 18 decimals
            amountD18 = tokenAmount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents a given amount of collateral locked until a given date.
 */
library CollateralLock {
    struct Data {
        /**
         * @dev The amount of collateral that has been locked.
         */
        uint128 amountD18;
        /**
         * @dev The date when the locked amount becomes unlocked.
         */
        uint64 lockExpirationTime;
        /**
         * @dev In addition to the condition imposed by `lockExpirationTime`, the specified pool (by pool id) must be synced after `lockExpirationTime`
         */
        uint128 lockExpirationPoolSync;
        address lockExpirationPoolSyncVault;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System wide configuration for anything
 */
library Config {
    struct Data {
        uint256 __unused;
    }

    /**
     * @dev Returns a config value
     */
    function read(bytes32 k, bytes32 zeroValue) internal view returns (bytes32 v) {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            v := sload(s)
        }

        if (v == bytes32(0)) {
            v = zeroValue;
        }
    }

    function readUint(bytes32 k, uint256 zeroValue) internal view returns (uint256 v) {
        // solhint-disable-next-line numcast/safe-cast
        return uint(read(k, bytes32(zeroValue)));
    }

    function readAddress(bytes32 k, address zeroValue) internal view returns (address v) {
        // solhint-disable-next-line numcast/safe-cast
        return address(uint160(readUint(k, uint160(zeroValue))));
    }

    function put(bytes32 k, bytes32 v) internal {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            sstore(s, v)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {AccessError} from "@synthetixio/core-contracts/contracts/errors/AccessError.sol";

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "../interfaces/external/ICcipRouterClient.sol";
import "../interfaces/external/FunctionsOracleInterface.sol";

/**
 * @title System wide configuration for anything
 */
library CrossChain {
    using SetUtil for SetUtil.UintSet;

    event ProcessedCcipMessage(bytes payload, bytes result);

    error NotCcipRouter(address);
    error UnsupportedNetwork(uint64);
    error InsufficientCcipFee(uint256 requiredAmount, uint256 availableAmount);

    bytes32 private constant _SLOT_CROSS_CHAIN =
        keccak256(abi.encode("io.synthetix.synthetix.CrossChain"));

    struct Data {
        ICcipRouterClient ccipRouter;
        FunctionsOracleInterface chainlinkFunctionsOracle;
        SetUtil.UintSet supportedNetworks;
        mapping(uint64 => uint64) ccipChainIdToSelector;
        mapping(uint64 => uint64) ccipSelectorToChainId;
        mapping(bytes32 => bytes32) chainlinkFunctionsRequestInfo;
    }

    function load() internal pure returns (Data storage crossChain) {
        bytes32 s = _SLOT_CROSS_CHAIN;
        assembly {
            crossChain.slot := s
        }
    }

    function processCcipReceive(Data storage self, CcipClient.Any2EVMMessage memory data) internal {
        if (address(self.ccipRouter) == address(0) || msg.sender != address(self.ccipRouter)) {
            revert NotCcipRouter(msg.sender);
        }

        uint64 sourceChainId = self.ccipSelectorToChainId[data.sourceChainId];

        if (!self.supportedNetworks.contains(sourceChainId)) {
            revert UnsupportedNetwork(sourceChainId);
        }

        address sender = abi.decode(data.sender, (address));
        if (sender != address(this)) {
            revert AccessError.Unauthorized(sender);
        }

        bytes memory payload;
        if (data.tokenAmounts.length > 0) {
            (address to, uint256 amount) = abi.decode(data.data, (address, uint256));
            payload = abi.encodeWithSelector(
                IERC20(data.tokenAmounts[0].token).transfer.selector,
                to,
                amount
            );
        } else {
            payload = data.data;
        }

        // at this point, everything should be good to send the message to ourselves.
        // the below `onlyCrossChain` function will verify that the caller is self
        (bool success, bytes memory result) = address(this).call(payload);

        if (!success) {
            uint len = result.length;
            assembly {
                revert(add(result, 0x20), len)
            }
        }

        emit ProcessedCcipMessage(payload, result);
    }

    function onlyCrossChain() internal view {
        if (msg.sender != address(this)) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function transmit(
        Data storage self,
        uint64 chainId,
        bytes memory data,
        uint256 gasLimit
    ) internal returns (uint256 gasTokenUsed) {
        uint64[] memory chains = new uint64[](1);
        chains[0] = chainId;
        return broadcast(self, chains, data, gasLimit);
    }

    /**
     * @dev Sends a message to one or more chains
     */
    function broadcast(
        Data storage self,
        uint64[] memory chains,
        bytes memory data,
        uint256 gasLimit
    ) internal returns (uint256 gasTokenUsed) {
        ICcipRouterClient router = self.ccipRouter;

        CcipClient.EVM2AnyMessage memory sentMsg = CcipClient.EVM2AnyMessage(
            abi.encode(address(this)), // abi.encode(receiver address) for dest EVM chains
            data, // Data payload
            new CcipClient.EVMTokenAmount[](0), // Token transfers
            address(0), // Address of feeToken. address(0) means you will send msg.value.
            CcipClient._argsToBytes(CcipClient.EVMExtraArgsV1(gasLimit, false))
        );

        for (uint i = 0; i < chains.length; i++) {
            if (chains[i] == block.chainid) {
                (bool success, bytes memory result) = address(this).call(data);

                if (!success) {
                    uint256 len = result.length;
                    assembly {
                        revert(result, len)
                    }
                }
            } else {
                uint64 chainSelector = self.ccipChainIdToSelector[chains[i]];
                uint256 fee = router.getFee(chainSelector, sentMsg);

                // need to check sufficient fee here or else the error is very confusing
                if (address(this).balance < fee) {
                    revert InsufficientCcipFee(fee, address(this).balance);
                }

                router.ccipSend{value: fee}(chainSelector, sentMsg);

                gasTokenUsed += fee;
            }
        }
    }

    /**
     * @dev Transfers tokens to a destination chain.
     */
    function teleport(
        Data storage self,
        uint64 destChainId,
        address token,
        uint256 amount,
        uint256 gasLimit
    ) internal returns (uint256 gasTokenUsed) {
        ICcipRouterClient router = self.ccipRouter;

        CcipClient.EVMTokenAmount[] memory tokenAmounts = new CcipClient.EVMTokenAmount[](1);
        tokenAmounts[0] = CcipClient.EVMTokenAmount(token, amount);

        bytes memory data = abi.encode(msg.sender, amount);
        CcipClient.EVM2AnyMessage memory sentMsg = CcipClient.EVM2AnyMessage(
            abi.encode(address(this)), // abi.encode(receiver address) for dest EVM chains
            data,
            tokenAmounts,
            address(0), // Address of feeToken. address(0) means you will send msg.value.
            CcipClient._argsToBytes(CcipClient.EVMExtraArgsV1(gasLimit, false))
        );

        uint64 chainSelector = self.ccipChainIdToSelector[destChainId];
        uint256 fee = router.getFee(chainSelector, sentMsg);

        // need to check sufficient fee here or else the error is very confusing
        if (address(this).balance < fee) {
            revert InsufficientCcipFee(fee, address(this).balance);
        }

        router.ccipSend{value: fee}(chainSelector, sentMsg);

        return fee;
    }

    function refundLeftoverGas(uint256 gasTokenUsed) internal returns (uint256 amountRefunded) {
        amountRefunded = msg.value - gasTokenUsed;

        (bool success, bytes memory result) = msg.sender.call{value: amountRefunded}("");

        if (!success) {
            uint256 len = result.length;
            assembly {
                revert(result, len)
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that allows you to track some global value, distributed amongst a set of actors.
 *
 * The total value can be scaled with a valuePerShare multiplier, and individual actor shares can be calculated as their amount of shares times this multiplier.
 *
 * Furthermore, changes in the value of individual actors can be tracked since their last update, by keeping track of the value of the multiplier, per user, upon each interaction. See DistributionActor.lastValuePerShare.
 *
 * A distribution is similar to a ScalableMapping, but it has the added functionality of being able to remember the previous value of the scalar multiplier for each actor.
 *
 * Whenever the shares of an actor of the distribution is updated, you get information about how the actor's total value changed since it was last updated.
 */
library Distribution {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    /**
     * @dev Thrown when an attempt is made to distribute value to a distribution
     * with no shares.
     */
    error EmptyDistribution();

    struct Data {
        /**
         * @dev The total number of shares in the distribution.
         */
        uint128 totalSharesD18;
        /**
         * @dev The value per share of the distribution, represented as a high precision decimal.
         */
        int128 valuePerShareD27;
        /**
         * @dev Tracks individual actor information, such as how many shares an actor has, their lastValuePerShare, etc.
         */
        mapping(bytes32 => DistributionActor.Data) actorInfo;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's valuePerShare.
     */
    function distributeValue(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        self.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage self,
        bytes32 actorId,
        uint256 newActorSharesD18
    ) internal returns (int256 valueChangeD18) {
        valueChangeD18 = getActorValueChange(self, actorId);

        DistributionActor.Data storage actor = self.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        self.totalSharesD18 = self.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;
        _updateLastValuePerShare(self, actor, newActorSharesD18);
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(
        Data storage self,
        bytes32 actorId
    ) internal returns (int256 valueChangeD18) {
        DistributionActor.Data storage actor = self.actorInfo[actorId];
        return _updateLastValuePerShare(self, actor, actor.sharesD18);
    }

    /**
     * @dev Calculates how much an actor's value has changed since its shares were last updated.
     *
     * This change is calculated as:
     * Since `value = valuePerShare * shares`,
     * then `delta_value = valuePerShare_now * shares - valuePerShare_then * shares`,
     * which is `(valuePerShare_now - valuePerShare_then) * shares`,
     * or just `delta_valuePerShare * shares`.
     */
    function getActorValueChange(
        Data storage self,
        bytes32 actorId
    ) internal view returns (int256 valueChangeD18) {
        return _getActorValueChange(self, self.actorInfo[actorId]);
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(
        Data storage self,
        bytes32 actorId
    ) internal view returns (uint256 sharesD18) {
        return self.actorInfo[actorId].sharesD18;
    }

    /**
     * @dev Returns the distribution's value per share in normal precision (18 decimals).
     * @param self The distribution whose value per share is being queried.
     * @return The value per share in 18 decimal precision.
     */
    function getValuePerShare(Data storage self) internal view returns (int256) {
        return self.valuePerShareD27.to256().downscale(DecimalMath.PRECISION_FACTOR);
    }

    function _updateLastValuePerShare(
        Data storage self,
        DistributionActor.Data storage actor,
        uint256 newActorShares
    ) private returns (int256 valueChangeD18) {
        valueChangeD18 = _getActorValueChange(self, actor);

        actor.lastValuePerShareD27 = newActorShares == 0
            ? SafeCastI128.zero()
            : self.valuePerShareD27;
    }

    function _getActorValueChange(
        Data storage self,
        DistributionActor.Data storage actor
    ) private view returns (int256 valueChangeD18) {
        int256 deltaValuePerShareD27 = self.valuePerShareD27 - actor.lastValuePerShareD27;

        int256 changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library DistributionActor {
    struct Data {
        /**
         * @dev The actor's current number of shares in the associated distribution.
         */
        uint128 sharesD18;
        /**
         * @dev The value per share that the associated distribution had at the time that the actor's number of shares was last modified.
         *
         * Note: This is also a high precision decimal. See Distribution.valuePerShare.
         */
        int128 lastValuePerShareD27;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/HeapUtil.sol";

import "./Distribution.sol";
import "./CollateralConfiguration.sol";
import "./MarketPoolInfo.sol";

import "../interfaces/external/IMarket.sol";

/**
 * @title Connects external contracts that implement the `IMarket` interface to the system.
 *
 * Pools provide credit capacity (collateral) to the markets, and are reciprocally exposed to the associated market's debt.
 *
 * The Market object's main responsibility is to track collateral provided by the pools that support it, and to trace their debt back to such pools.
 */
library Market {
    using Distribution for Distribution.Data;
    using HeapUtil for HeapUtil.Data;
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;

    /**
     * @dev Thrown when a specified market is not found.
     */
    error MarketNotFound(uint128 marketId);

    struct Data {
        /**
         * @dev Numeric identifier for the market. Must be unique.
         * @dev There cannot be a market with id zero (See MarketCreator.create()). Id zero is used as a null market reference.
         */
        uint128 id;
        /**
         * @dev Address for the external contract that implements the `IMarket` interface, which this Market objects connects to.
         *
         * Note: This object is how the system tracks the market. The actual market is external to the system, i.e. its own contract.
         */
        address marketAddress;
        /**
         * @dev Issuance can be seen as how much USD the Market "has issued", printed, or has asked the system to mint on its behalf.
         *
         * More precisely it can be seen as the net difference between the USD burnt and the USD minted by the market.
         *
         * More issuance means that the market owes more USD to the system.
         *
         * A market burns USD when users deposit it in exchange for some asset that the market offers.
         * The Market object calls `MarketManager.depositUSD()`, which burns the USD, and decreases its issuance.
         *
         * A market mints USD when users return the asset that the market offered and thus withdraw their USD.
         * The Market object calls `MarketManager.withdrawUSD()`, which mints the USD, and increases its issuance.
         *
         * Instead of burning, the Market object could transfer USD to and from the MarketManager, but minting and burning takes the USD out of circulation, which doesn't affect `totalSupply`, thus simplifying accounting.
         *
         * How much USD a market can mint depends on how much credit capacity is given to the market by the pools that support it, and reflected in `Market.capacity`.
         *
         */
        int128 netIssuanceD18;
        /**
         * @dev The total amount of USD that the market could withdraw if it were to immediately unwrap all its positions.
         *
         * The Market's credit capacity increases when the market burns USD, i.e. when it deposits USD in the MarketManager.
         *
         * It decreases when the market mints USD, i.e. when it withdraws USD from the MarketManager.
         *
         * The Market's credit capacity also depends on how much credit is given to it by the pools that support it.
         *
         * The Market's credit capacity also has a dependency on the external market reported debt as it will respond to that debt (and hence change the credit capacity if it increases or decreases)
         *
         * The credit capacity can go negative if all of the collateral provided by pools is exhausted, and there is market provided collateral available to consume. in this case, the debt is still being
         * appropriately assigned, but the market has a dynamic cap based on deposited collateral types.
         *
         */
        int128 creditCapacityD18;
        /**
         * @dev The total balance that the market had the last time that its debt was distributed.
         *
         * A Market's debt is distributed when the reported debt of its associated external market is rolled into the pools that provide credit capacity to it.
         */
        int128 lastDistributedMarketBalanceD18;
        /**
         * @dev A heap of pools for which the market has not yet hit its maximum credit capacity.
         *
         * The heap is ordered according to this market's max value per share setting in the pools that provide credit capacity to it. See `MarketConfiguration.maxDebtShareValue`.
         *
         * The heap's getMax() and extractMax() functions allow us to retrieve the pool with the lowest `maxDebtShareValue`, since its elements are inserted and prioritized by negating their `maxDebtShareValue`.
         *
         * Lower max values per share are on the top of the heap. I.e. the heap could look like this:
         *  .    -1
         *      / \
         *     /   \
         *    -2    \
         *   / \    -3
         * -4   -5
         *
         * TL;DR: This data structure allows us to easily find the pool with the lowest or "most vulnerable" max value per share and process it if its actual value per share goes beyond this limit.
         */
        HeapUtil.Data inRangePools;
        /**
         * @dev A heap of pools for which the market has hit its maximum credit capacity.
         *
         * Used to reconnect pools to the market, when it falls back below its maximum credit capacity.
         *
         * See inRangePools for why a heap is used here.
         */
        HeapUtil.Data outRangePools;
        /**
         * @dev A market's debt distribution connects markets to the debt distribution chain, in this case pools. Pools are actors in the market's debt distribution, where the amount of shares they possess depends on the amount of collateral they provide to the market. The value per share of this distribution depends on the total debt or balance of the market (netIssuance + reportedDebt).
         *
         * The debt distribution chain will move debt from the market into its connected pools.
         *
         * Actors: Pools.
         * Shares: The USD denominated credit capacity that the pool provides to the market.
         * Value per share: Debt per dollar of credit that the associated external market accrues.
         *
         */
        Distribution.Data poolsDebtDistribution;
        /**
         * @dev Additional info needed to remember pools when they are removed from the distribution (or subsequently re-added).
         */
        mapping(uint128 => MarketPoolInfo.Data) pools;
        /**
         * @dev Array of entries of market provided collateral.
         *
         * Markets may obtain additional liquidity, beyond that coming from depositors, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint256) maximumDepositableD18;
        uint32 minDelegateTime;
        uint32 __reservedForLater1;
        uint64 __reservedForLater2;
        uint64 __reservedForLater3;
        uint64 __reservedForLater4;
        /**
         * @dev Market-specific override of the minimum liquidity ratio
         */
        uint256 minLiquidityRatioD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint256 amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage market) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Market", id));
        assembly {
            market.slot := s
        }
    }

    /**
     * @dev Queries the external market contract for the amount of debt it has issued.
     *
     * The reported debt of a market represents the amount of USD that the market would ask the system to mint, if all of its positions were to be immediately closed.
     *
     * The reported debt of a market is collateralized by the assets in the pools which back it.
     *
     * See the `IMarket` interface.
     */
    function getReportedDebt(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint256) {
        return IMarket(self.marketAddress).minimumCredit(self.id);
    }

    /**
     * @dev Returns the total debt of the market.
     *
     * A market's total debt represents its debt plus its issuance, and thus represents the total outstanding debt of the market.
     *
     * Note: it also takes into account the deposited collateral value. See note in  getDepositedCollateralValue()
     *
     * Example:
     * (1 EUR = 1.11 USD)
     * If an Euro market has received 100 USD to mint 90 EUR, its reported debt is 90 EUR or 100 USD, and its issuance is -100 USD.
     * Thus, its total balance is 100 USD of reported debt minus 100 USD of issuance, which is 0 USD.
     *
     * Additionally, the market's totalDebt might be affected by price fluctuations via reportedDebt, or fees.
     *
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return
            getReportedDebt(self).toInt() +
            self.netIssuanceD18 -
            getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by depositors through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint256) {
        uint256 totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint256 i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration
                .load(entry.collateralType);

            if (entry.amountD18 == 0) {
                continue;
            }

            uint256 priceD18 = CollateralConfiguration.getCollateralPrice(collateralConfiguration);

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(
        Data storage self,
        uint128 poolId
    ) internal view returns (uint256) {
        return self.poolsDebtDistribution.getActorShares(poolId.toBytes32());
    }

    /**
     * @dev Given an amount of shares that represent USD credit capacity from a pool, and a maximum value per share, returns the potential contribution to credit capacity that these shares could accrue, if their value per share was to hit the maximum.
     *
     * The resulting value is calculated multiplying the amount of creditCapacity provided by the pool by the delta between the maxValue per share vs current value.
     *
     * This function is used when the Pools are rebalanced to adjust each pool credit capacity based on a change in the amount of shares provided and/or a new maxValue per share
     *
     */
    function getCreditCapacityContribution(
        Data storage self,
        uint256 creditCapacitySharesD18,
        int256 maxShareValueD18
    ) internal view returns (int256 contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint256 deltaValuePerShareD18 = (maxShareValueD18 -
            self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18).toInt();
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self).toInt();
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(
        Data storage self,
        uint128 poolId
    ) internal returns (int256 debtChangeD18) {
        return
            self.pools[poolId].pendingDebtD18.toInt() +
            self.poolsDebtDistribution.accumulateActor(poolId.toBytes32());
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_inRangePools(Data storage self) internal view returns (uint256) {
        return self.inRangePools.size();
    }

    /**
     * Returns the number of pools currently active in the market
     *
     * Note: this is test only
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_outRangePools(Data storage self) internal view returns (uint256) {
        return self.outRangePools.size();
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int256 debtPerShareD18) {
        return self.poolsDebtDistribution.getValuePerShare();
    }

    /**
     * @dev Wrapper that adjusts a pool's shares in the market's credit capacity, making sure that the market's outstanding debt is first passed on to its connected pools.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function rebalancePools(
        uint128 marketId,
        uint128 poolId,
        int256 maxDebtShareValueD18, // (in USD)
        uint256 newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int256 debtChangeD18) {
        Data storage self = load(marketId);

        if (self.marketAddress == address(0)) {
            revert MarketNotFound(marketId);
        }

        // Iter avoids griefing - MarketManager can call this with user specified iters and thus clean up a grieved market.
        distributeDebtToPools(self, 9999999999);

        return adjustPoolShares(self, poolId, newCreditCapacityD18, maxDebtShareValueD18);
    }

    /**
     * @dev Called by pools when they modify the credit capacity provided to the market, as well as the maximum value per share they tolerate for the market.
     *
     * These two settings affect the market in the following ways:
     * - Updates the pool's shares in `poolsDebtDistribution`.
     * - Moves the pool in and out of inRangePools/outRangePools.
     * - Updates the market credit capacity property.
     */
    function adjustPoolShares(
        Data storage self,
        uint128 poolId,
        uint256 newCreditCapacityD18,
        int256 newPoolMaxShareValueD18
    ) internal returns (int256 debtChangeD18) {
        uint256 oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int256 oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newCreditCapacityD18 == 0) {
            self.inRangePools.extractById(poolId);
            self.outRangePools.extractById(poolId);
        } else if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int256 changedValueD18 = self.poolsDebtDistribution.setActorShares(
            poolId.toBytes32(),
            newCreditCapacityD18
        );
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(
                self,
                newCreditCapacityD18,
                newPoolMaxShareValueD18
            ).to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(
                self,
                oldCreditCapacityD18,
                oldPoolMaxShareValueD18
            ).to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(
        Data storage self,
        uint256 maxIter
    ) internal returns (bool fullyDistributed) {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(
                targetBalanceD18 - self.lastDistributedMarketBalanceD18
            );
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }

        return !exhausted;
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function getTargetValuePerShare(
        Market.Data storage self,
        int256 valueToDistributeD18
    ) internal view returns (int256 targetValuePerShareD18) {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            (
                self.poolsDebtDistribution.totalSharesD18 > 0
                    ? valueToDistributeD18.divDecimal(
                        self.poolsDebtDistribution.totalSharesD18.toInt()
                    ) // solhint-disable-next-line numcast/safe-cast
                    : int256(0)
            );
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function bumpPools(
        Data storage self,
        int256 maxDistributedD18,
        uint256 maxIter
    ) internal returns (int256 actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0) {
            return (0, false);
        }

        // Determine the direction based on the amount to be distributed.
        int128 k;
        HeapUtil.Data storage fromHeap;
        HeapUtil.Data storage toHeap;
        if (maxDistributedD18 > 0) {
            k = 1;
            fromHeap = self.inRangePools;
            toHeap = self.outRangePools;
        } else {
            k = -1;
            fromHeap = self.outRangePools;
            toHeap = self.inRangePools;
        }

        // Note: This loop should rarely execute its main body. When it does, it only executes once for each pool that exceeds the limit since `distributeValue` is not run for most pools. Thus, market users are not hit with any overhead as a result of this.
        uint256 iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no pools that can be moved
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // 2 cases where we want to break out of this loop
            if (
                // If there is no pool in range, and we are going down
                (maxDistributedD18 - actuallyDistributedD18 > 0 &&
                    self.poolsDebtDistribution.totalSharesD18 == 0) ||
                // If there is a pool in ragne, and the lowest max value per share does not hit the limit, exit
                // Note: `-edgePool.priority` is actually the max value per share limit of the pool
                (self.poolsDebtDistribution.totalSharesD18 > 0 &&
                    -edgePool.priority >=
                    k * getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18)))
            ) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            if (self.poolsDebtDistribution.totalSharesD18 > 0) {
                int256 debtToLimitD18 = self
                    .poolsDebtDistribution
                    .totalSharesD18
                    .toInt()
                    .mulDecimal(
                        -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
                    );
                self.poolsDebtDistribution.distributeValue(debtToLimitD18);

                // Update the global distributed and outstanding balances with the debt that was just distributed.
                actuallyDistributedD18 += debtToLimitD18;
            } else {
                self.poolsDebtDistribution.valuePerShareD27 = (-k * edgePool.priority)
                    .to256()
                    .upscale(DecimalMath.PRECISION_FACTOR)
                    .to128();
            }

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                // the below requires are only for sanity
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) > 0,
                    "no shares before actor removal"
                );

                uint256 newPoolDebtD18 = self
                    .poolsDebtDistribution
                    .setActorShares(edgePool.id.toBytes32(), 0)
                    .toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(edgePool.id.toBytes32()) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    edgePool.id.toBytes32(),
                    self.pools[edgePool.id].creditCapacityAmountD18
                );
            }
        }

        // Record the accumulated distributed balance.
        self.lastDistributedMarketBalanceD18 += actuallyDistributedD18.to128();

        exhausted = iters == maxIter;
    }

    /**
     * @dev Moves a pool from one heap into another.
     */
    function togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) internal {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks a market's weight within a Pool, and its maximum debt.
 *
 * Each pool has an array of these, with one entry per market managed by the pool.
 *
 * A market's weight determines how much liquidity the pool provides to the market, and how much debt exposure the market gives the pool.
 *
 * Weights are used to calculate percentages by adding all the weights in the pool and dividing the market's weight by the total weights.
 *
 * A market's maximum debt in a pool is indicated with a maximum debt value per share.
 */
library MarketConfiguration {
    struct Data {
        /**
         * @dev Numeric identifier for the market.
         *
         * Must be unique, and in a list of `MarketConfiguration[]`, must be increasing.
         */
        uint128 marketId;
        /**
         * @dev The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         */
        uint128 weightD18;
        /**
         * @dev Maximum value per share that a pool will tolerate for this market.
         *
         * If the the limit is met, the markets exceeding debt will be distributed, and it will be disconnected from the pool that no longer provides credit to it.
         *
         * Note: This value will have no effect if the system wide limit is hit first. See `PoolConfiguration.minLiquidityRatioD18`.
         */
        int128 maxDebtShareValueD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Stores information regarding a pool's relationship to a market, such that it can be added or removed from a distribution
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev The credit capacity that this pool is providing to the relevant market. Needed to re-add the pool to the distribution when going back in range.
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet.
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    bytes32 private constant _SLOT_ORACLE_MANAGER =
        keccak256(abi.encode("io.synthetix.synthetix.OracleManager"));

    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    /**
     * @dev Loads the singleton storage info about the oracle manager.
     */
    function load() internal pure returns (Data storage oracleManager) {
        bytes32 s = _SLOT_ORACLE_MANAGER;
        assembly {
            oracleManager.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Config.sol";
import "./Distribution.sol";
import "./MarketConfiguration.sol";
import "./Vault.sol";
import "./Market.sol";
import "./PoolCrossChainInfo.sol";
import "./SystemPoolConfiguration.sol";

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Aggregates collateral from multiple users in order to provide liquidity to a configurable set of markets.
 *
 * The set of markets is configured as an array of MarketConfiguration objects, where the weight of the market can be specified. This weight, and the aggregated total weight of all the configured markets, determines how much collateral from the pool each market has, as well as in what proportion the market passes on debt to the pool and thus to all its users.
 *
 * The pool tracks the collateral provided by users using an array of Vaults objects, for which there will be one per collateral type. Each vault tracks how much collateral each user has delegated to this pool, how much debt the user has because of minting USD, as well as how much corresponding debt the pool has passed on to the user.
 */
library Pool {
    using CollateralConfiguration for CollateralConfiguration.Data;
    using Market for Market.Data;
    using Vault for Vault.Data;
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using DecimalMath for int128;
    using SetUtil for SetUtil.AddressSet;
    using SafeCastAddress for address;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @dev Thrown when the specified pool is not found.
     */
    error PoolNotFound(uint128 poolId);

    /**
     * @dev Thrown when attempting to create a pool that already exists.
     */
    error PoolAlreadyExists(uint128 poolId);

    /**
     * @dev Thrown when trying to create a cross chain pool from a non-primary pool (aka a pool that wasn't itself created by another pool)
     */
    error PoolIsNotPrimary(uint128 poolId);

    /**
     * @dev Thrown when min delegation time for a market connected to the pool has not elapsed
     */
    error MinDelegationTimeoutPending(uint128 poolId, uint32 timeRemaining);

    /**
     * @notice Thrown when attempting to disconnect a market whose capacity is locked, and whose removal would cause a decrease in its associated pool's credit delegation proportion.
     */
    error CapacityLocked(uint256 marketId);

    bytes32 private constant _CONFIG_SET_MARKET_MIN_DELEGATE_MAX = "setMarketMinDelegateTime_max";

    struct Data {
        /**
         * @dev Numeric identifier for the pool. Must be unique.
         * @dev A pool with id zero exists! (See Pool.loadExisting()). Users can delegate to this pool to be able to mint USD without being exposed to fluctuating debt.
         */
        uint128 id;
        /**
         * @dev Text identifier for the pool.
         *
         * Not required to be unique.
         */
        string name;
        /**
         * @dev Creator of the pool, which has configuration access rights for the pool.
         *
         * See onlyPoolOwner.
         */
        address owner;
        /**
         * @dev Allows the current pool owner to nominate a new owner, and thus transfer pool configuration credentials.
         */
        address nominatedOwner;
        /**
         * @dev Sum of all market weights.
         *
         * Market weights are tracked in `MarketConfiguration.weight`, one for each market. The ratio of each market's `weight` to the pool's `totalWeights` determines the pro-rata share of the market to the pool's total liquidity.
         *
         * Reciprocally, this pro-rata share also determines how much the pool is exposed to each market's debt.
         */
        uint128 totalWeightsD18;
        /**
         * @dev Accumulated cache value of all vault collateral debts
         */
        int128 totalVaultDebtsD18;
        /**
         * @dev Array of markets connected to this pool, and their configurations. I.e. weight, etc.
         *
         * See totalWeights.
         */
        MarketConfiguration.Data[] marketConfigurations;
        /**
         * @dev A pool's debt distribution connects pools to the debt distribution chain, i.e. vaults and markets. Vaults are actors in the pool's debt distribution, where the amount of shares they possess depends on the amount of collateral each vault delegates to the pool.
         *
         * The debt distribution chain will move debt from markets into this pools, and then from pools to vaults.
         *
         * Actors: Vaults.
         * Shares: USD value, proportional to the amount of collateral that the vault delegates to the pool.
         * Value per share: Debt per dollar of collateral. Depends on aggregated debt of connected markets.
         *
         */
        Distribution.Data vaultsDebtDistribution;
        /**
         * @dev Reference to all the vaults that provide liquidity to this pool.
         *
         * Each collateral type will have its own vault, specific to this pool. I.e. if two pools both use SNX collateral, each will have its own SNX vault.
         *
         * Vaults track user collateral and debt using a debt distribution, which is connected to the debt distribution chain.
         */
        mapping(address => Vault.Data) vaults;
        uint64 lastConfigurationTime;
        uint64 __reserved1;
        uint64 __reserved2;
        uint64 __reserved3;
        uint128 totalCapacityD18;
        int128 cumulativeDebtD18;
        mapping(uint256 => uint256) heldMarketConfigurationWeights;
        mapping(uint256 => PoolCrossChainInfo.Data) crossChain;
    }

    /**
     * @dev Returns the pool stored at the specified pool id.
     */
    function load(uint128 id) internal pure returns (Data storage pool) {
        bytes32 s = keccak256(abi.encode("io.synthetix.synthetix.Pool", id));
        assembly {
            pool.slot := s
        }
    }

    /**
     * @dev Creates a pool for the given pool id, and assigns the caller as its owner.
     *
     * Reverts if the specified pool already exists.
     */
    function create(uint128 id, address owner) internal returns (Pool.Data storage pool) {
        if (id == 0 || load(id).id == id) {
            revert PoolAlreadyExists(id);
        }

        pool = load(id);

        pool.id = id;
        pool.owner = owner;
    }

    function isCrossChainEnabled(Data storage self) internal view returns (bool) {
        return self.crossChain[0].pairedChains.length > 0;
    }

    function getCreditCapacity(Data storage self) internal view returns (uint256) {
        return
            isCrossChainEnabled(self)
                ? self.crossChain[0].latestSync.liquidity
                : self.totalCapacityD18;
    }

    function getTotalDebts(Data storage self) internal view returns (int256) {
        return
            isCrossChainEnabled(self)
                ? self.crossChain[0].latestSync.totalDebt
                : self.totalVaultDebtsD18;
    }

    function getTotalWeight(Data storage self) internal view returns (uint256) {
        return
            isCrossChainEnabled(self)
                ? self.crossChain[0].latestTotalWeights
                : self.totalWeightsD18;
    }

    function getOldestSync(Data storage self) internal view returns (uint64) {
        return
            isCrossChainEnabled(self)
                ? self.crossChain[0].latestSync.oldestDataTimestamp
                : uint64(block.timestamp);
    }

    function rebalanceMarketsInPool(
        Data storage self
    ) internal returns (int256 cumulativeDebtChangeD18, int256 cumulativeDebtD18) {
        uint256 totalWeightsD18 = getTotalWeight(self);

        if (totalWeightsD18 == 0) {
            return (0, 0); // Nothing to rebalance.
        }

        // Read from storage once, before entering the loop below.
        // These values should not change while iterating through each market.
        uint256 totalCreditCapacityD18 = getCreditCapacity(self);
        int128 debtPerShareD18 = totalCreditCapacityD18 > 0 // solhint-disable-next-line numcast/safe-cast
            ? getTotalDebts(self).divDecimal(totalCreditCapacityD18.toInt()).to128() // solhint-disable-next-line numcast/safe-cast
            : int128(0);

        //uint256 systemMinLiquidityRatioD18 = ;

        // Loop through the pool's markets, applying market weights, and tracking how this changes the amount of debt that this pool is responsible for.
        // This debt extracted from markets is then applied to the pool's vault debt distribution, which thus exposes debt to the pool's vaults.
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            MarketConfiguration.Data storage marketConfiguration = self.marketConfigurations[i];

            uint256 weightD18 = marketConfiguration.weightD18;

            // Calculate each market's pro-rata USD liquidity.
            // Note: the factor `(weight / totalWeights)` is not deduped in the operations below to maintain numeric precision.

            uint256 marketCreditCapacityD18 = (totalCreditCapacityD18 * weightD18) /
                totalWeightsD18;

            // do we have a delayed weight application for cross chain?
            if (
                isCrossChainEnabled(self) &&
                self.crossChain[0].latestSync.oldestPoolConfigTimestamp < self.lastConfigurationTime
            ) {
                uint256 heldWeight = self.heldMarketConfigurationWeights[
                    marketConfiguration.marketId
                ];
                marketCreditCapacityD18 = totalCreditCapacityD18.mulDecimal(
                    heldWeight == 1 ? 0 : heldWeight
                );
            }

            Market.Data storage marketData = Market.load(marketConfiguration.marketId);

            // Use market-specific minimum liquidity ratio if set, otherwise use system default.
            uint256 minLiquidityRatioD18 = marketData.minLiquidityRatioD18 > 0
                ? marketData.minLiquidityRatioD18
                : SystemPoolConfiguration.load().minLiquidityRatioD18;

            // Contain the pool imposed market's maximum debt share value.
            // Imposed by system.
            int256 effectiveMaxShareValueD18 = getSystemMaxValuePerShare(
                marketData.id,
                minLiquidityRatioD18,
                debtPerShareD18
            );
            // Imposed by pool.
            int256 configuredMaxShareValueD18 = marketConfiguration.maxDebtShareValueD18;
            effectiveMaxShareValueD18 = effectiveMaxShareValueD18 < configuredMaxShareValueD18
                ? effectiveMaxShareValueD18
                : configuredMaxShareValueD18;

            // Update each market's corresponding credit capacity.
            // The returned value represents how much the market's debt changed after changing the shares of this pool actor, which is aggregated to later be passed on the pools debt distribution.
            cumulativeDebtChangeD18 += Market.rebalancePools(
                marketConfiguration.marketId,
                self.id,
                effectiveMaxShareValueD18,
                marketCreditCapacityD18
            );
        }

        cumulativeDebtD18 = self.cumulativeDebtD18;
        // TODO: should this be removed from the rebalancePool? if the caller does not perform potentially necessary actions after
        // this, it could cause accumulated debt to go out of sync with downstream accounts
        self.cumulativeDebtD18 = (cumulativeDebtD18 + cumulativeDebtChangeD18).to128();
    }

    /**
     * @dev Ticker function that updates the debt distribution chain downwards, from markets into the pool, according to each market's weight.
     *
     * It updates the chain by performing these actions:
     * - Splits the pool's total liquidity of the pool into each market, pro-rata. The amount of shares that the pool has on each market depends on how much liquidity the pool provides to the market.
     * - Accumulates the change in debt value from each market into the pools own vault debt distribution's value per share.
     */
    function distributeDebtToVaults(Data storage self, int256 debtAmount) internal {
        // Passes on the accumulated debt changes from the markets, into the pool, so that vaults can later access this debt.
        self.vaultsDebtDistribution.distributeValue(debtAmount);
    }

    /**
     * @dev Determines the resulting maximum value per share for a market, according to a system-wide minimum liquidity ratio. This prevents markets from assigning more debt to pools than they have collateral to cover.
     *
     * Note: There is a market-wide fail safe for each market at `MarketConfiguration.maxDebtShareValue`. The lower of the two values should be used.
     *
     * See `SystemPoolConfiguration.minLiquidityRatio`.
     */
    function getSystemMaxValuePerShare(
        uint128 marketId,
        uint256 minLiquidityRatioD18,
        int256 debtPerShareD18
    ) internal view returns (int256) {
        // Retrieve the current value per share of the market.
        Market.Data storage marketData = Market.load(marketId);
        int256 valuePerShareD18 = marketData.poolsDebtDistribution.getValuePerShare();

        // Calculate the margin of debt that the market would incur if it hit the system wide limit.
        uint256 marginD18 = minLiquidityRatioD18 == 0
            ? DecimalMath.UNIT
            : DecimalMath.UNIT.divDecimal(minLiquidityRatioD18);

        // The resulting maximum value per share is the distribution's value per share,
        // plus the margin to hit the limit, minus the current debt per share.
        return valuePerShareD18 + marginD18.toInt() - debtPerShareD18;
    }

    /**
     * @dev Reverts if the pool does not exist with appropriate error. Otherwise, returns the pool.
     */
    function loadExisting(uint128 id) internal view returns (Data storage) {
        Data storage p = load(id);
        if (id != 0 && p.id != id) {
            revert PoolNotFound(id);
        }

        return p;
    }

    /**
     * @dev Returns true if the pool is exposed to the specified market.
     */
    function hasMarket(Data storage self, uint128 marketId) internal view returns (bool) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            if (self.marketConfigurations[i].marketId == marketId) {
                return true;
            }
        }

        return false;
    }

    function recalculateAllCollaterals(Data storage self) internal {
        SetUtil.AddressSet storage availableCollaterals = CollateralConfiguration
            .loadAvailableCollaterals();

        int256 deltaDebtD18;

        for (uint i = 0; i < availableCollaterals.length(); i++) {
            address collateralType = availableCollaterals.valueAt(i);

            // Transfer the debt change from the pool into the vault.
            bytes32 actorId = collateralType.toBytes32();
            self.vaults[collateralType].distributeDebtToAccounts(
                self.vaultsDebtDistribution.accumulateActor(actorId)
            );

            // Get the latest collateral price.
            uint256 collateralPriceD18 = CollateralConfiguration
                .load(collateralType)
                .getCollateralPrice();

            // Changes in price update the corresponding vault's total collateral value as well as its liquidity (collateral - debt).
            (
                uint256 usdWeightD18,
                ,
                int256 deltaCapacityD18,
                ,
                int256 collateralDeltaDebtD18
            ) = self.vaults[collateralType].updateCreditCapacity(collateralPriceD18);

            // Update the vault's shares in the pool's debt distribution, according to the value of its collateral.
            self.vaultsDebtDistribution.setActorShares(actorId, usdWeightD18);

            self.totalCapacityD18 = (self.totalCapacityD18.toInt() + deltaCapacityD18)
                .toUint()
                .to128();

            // Accumulate the change in total liquidity, from the vault, into the pool.
            deltaDebtD18 += collateralDeltaDebtD18;
        }

        // Accumulate the change in total liquidity, from the vault, into the pool.
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + deltaDebtD18.to128();

        // Distribute debt again because the market credit capacity may have changed, so we should ensure the vaults have the most up to date capacities
        rebalanceMarketsInPool(self);
    }

    /**
     * @dev Ticker function that updates the debt distribution chain for a specific collateral type downwards, from the pool into the corresponding the vault, according to changes in the collateral's price.
     *
     * It updates the chain by performing these actions:
     * - Collects the latest price of the corresponding collateral and updates the vault's liquidity.
     * - Updates the vaults shares in the pool's debt distribution, according to the collateral provided by the vault.
     * - Updates the value per share of the vault's debt distribution.
     */
    function recalculateVaultCollateral(
        Data storage self,
        address collateralType
    ) internal returns (uint256 collateralPriceD18) {
        if (!isCrossChainEnabled(self)) {
            (int256 cumulativeDebtChange, ) = rebalanceMarketsInPool(self);

            distributeDebtToVaults(self, cumulativeDebtChange);
        }

        // Transfer the debt change from the pool into the vault.
        bytes32 actorId = collateralType.toBytes32();
        self.vaults[collateralType].distributeDebtToAccounts(
            self.vaultsDebtDistribution.accumulateActor(actorId)
        );

        // Get the latest collateral price.
        collateralPriceD18 = CollateralConfiguration.load(collateralType).getCollateralPrice();

        // Changes in price update the corresponding vault's total collateral value as well as its liquidity (collateral - debt).
        (uint256 usdWeightD18, , int256 deltaCapacityD18, , int256 deltaDebtD18) = self
            .vaults[collateralType]
            .updateCreditCapacity(collateralPriceD18);

        // Update the vault's shares in the pool's debt distribution, according to the value of its collateral.
        self.vaultsDebtDistribution.setActorShares(actorId, usdWeightD18);

        self.totalCapacityD18 = (self.totalCapacityD18.toInt() + deltaCapacityD18).toUint().to128();

        // Accumulate the change in total liquidity, from the vault, into the pool.
        self.totalVaultDebtsD18 = self.totalVaultDebtsD18 + deltaDebtD18.to128();

        // Distribute debt again because the market credit capacity may have changed, so we should ensure the vaults have the most up to date capacities
        rebalanceMarketsInPool(self);
    }

    /**
     * @dev Updates the debt distribution chain for this pool, and consolidates the given account's debt.
     */
    function updateAccountDebt(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (int256 debtD18) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].consolidateAccountDebt(accountId);
    }

    /**
     * @dev Clears all vault data for the specified collateral type.
     */
    function resetVault(Data storage self, address collateralType) internal {
        // Creates a new epoch in the vault, effectively zeroing out all values.
        self.vaults[collateralType].reset();

        // Ensure that the vault's values update the debt distribution chain.
        recalculateVaultCollateral(self, collateralType);
    }

    /**
     * @dev Calculates the collateralization ratio of the vault that tracks the given collateral type.
     *
     * The c-ratio is the vault's share of the total debt of the pool, divided by the collateral it delegates to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultCollateralRatio(
        Data storage self,
        address collateralType
    ) internal returns (uint256) {
        int256 vaultDebtD18 = currentVaultDebt(self, collateralType);
        (, uint256 collateralValueD18) = currentVaultCollateral(self, collateralType);

        return vaultDebtD18 > 0 ? collateralValueD18.divDecimal(vaultDebtD18.toUint()) : 0;
    }

    /**
     * @dev Finds a connected market whose credit capacity has reached its locked limit.
     *
     * Note: Returns market zero (null market) if none is found.
     */
    function findMarketWithCapacityLocked(
        Data storage self
    ) internal view returns (Market.Data storage lockedMarket) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            Market.Data storage market = Market.load(self.marketConfigurations[i].marketId);

            if (market.isCapacityLocked()) {
                return market;
            }
        }

        // Market zero = null market.
        return Market.load(0);
    }

    function getRequiredMinDelegationTime(
        Data storage self
    ) internal view returns (uint32 requiredMinDelegateTime) {
        for (uint256 i = 0; i < self.marketConfigurations.length; i++) {
            uint32 marketMinDelegateTime = Market
                .load(self.marketConfigurations[i].marketId)
                .minDelegateTime;

            if (marketMinDelegateTime > requiredMinDelegateTime) {
                requiredMinDelegateTime = marketMinDelegateTime;
            }
        }

        // solhint-disable-next-line numcast/safe-cast
        uint32 maxMinDelegateTime = uint32(
            Config.readUint(_CONFIG_SET_MARKET_MIN_DELEGATE_MAX, 86400 * 30)
        );
        return
            maxMinDelegateTime < requiredMinDelegateTime
                ? maxMinDelegateTime
                : requiredMinDelegateTime;
    }

    function addCrossChain(Data storage self, uint64 chainId) internal returns (uint128 ccPoolId) {
        if (self.id > type(uint128).max / 2) {
            revert PoolIsNotPrimary(self.id);
        }

        if (self.crossChain[0].pairedPoolIds[chainId] != 0) {
            revert PoolAlreadyExists(self.crossChain[0].pairedPoolIds[chainId]);
        }

        if (self.crossChain[0].pairedChains.length == 0) {
            // kind of redundant but good for consistency to ensure that the primary is always the first pool listed in paired chains
            self.crossChain[0].pairedChains.push(uint64(block.chainid));
            self.crossChain[0].pairedPoolIds[chainId] = self.id;
        }

        ccPoolId = getCrossChainPoolId(uint64(block.chainid), self.id);

        self.crossChain[0].pairedPoolIds[chainId] = ccPoolId;
        self.crossChain[0].pairedChains.push(chainId);
    }

    function getCrossChainPoolId(
        uint64 srcChainId,
        uint128 srcPoolId
    ) internal returns (uint128 ccPoolId) {
        return
            uint128(uint256(keccak256(abi.encode("SNXV3CC", srcChainId, srcPoolId))) | (1 << 127));
    }

    function setCrossChainSyncData(
        Data storage self,
        PoolCrossChainSync.Data memory syncData
    ) internal {
        self.crossChain[0].latestSync = syncData;
    }

    /**
     * @dev Returns the debt of the vault that tracks the given collateral type.
     *
     * The vault's debt is the vault's share of the total debt of the pool, or its share of the total debt of the markets connected to the pool. The size of this share depends on how much collateral the pool provides to the pool.
     *
     * Note: This is not a view function. It updates the debt distribution chain before performing any calculations.
     */
    function currentVaultDebt(Data storage self, address collateralType) internal returns (int256) {
        recalculateVaultCollateral(self, collateralType);

        return self.vaults[collateralType].currentDebt();
    }

    /**
     * @dev Returns the total amount and value of the specified collateral delegated to this pool.
     */
    function currentVaultCollateral(
        Data storage self,
        address collateralType
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentCollateral();
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the amount and value of collateral that the specified account has delegated to this pool.
     */
    function currentAccountCollateral(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal view returns (uint256 collateralAmountD18, uint256 collateralValueD18) {
        uint256 collateralPriceD18 = CollateralConfiguration
            .load(collateralType)
            .getCollateralPrice();

        collateralAmountD18 = self.vaults[collateralType].currentAccountCollateral(accountId);
        collateralValueD18 = collateralPriceD18.mulDecimal(collateralAmountD18);
    }

    /**
     * @dev Returns the specified account's collateralization ratio (collateral / debt).
     * @dev If the account's debt is negative or zero, returns an "infinite" c-ratio.
     */
    function currentAccountCollateralRatio(
        Data storage self,
        address collateralType,
        uint128 accountId
    ) internal returns (uint256) {
        int256 positionDebtD18 = updateAccountDebt(self, collateralType, accountId);
        if (positionDebtD18 <= 0) {
            return type(uint256).max;
        }

        (, uint256 positionCollateralValueD18) = currentAccountCollateral(
            self,
            collateralType,
            accountId
        );

        return positionCollateralValueD18.divDecimal(positionDebtD18.toUint());
    }

    /**
     * @dev Reverts if the caller is not the owner of the specified pool.
     */
    function onlyPoolOwner(uint128 poolId, address caller) internal view {
        if (Pool.load(poolId).owner != caller) {
            revert AccessError.Unauthorized(caller);
        }
    }

    function requireMinDelegationTimeElapsed(
        Data storage self,
        uint64 lastDelegationTime
    ) internal view {
        uint32 requiredMinDelegationTime = getRequiredMinDelegationTime(self);
        if (block.timestamp < lastDelegationTime + requiredMinDelegationTime) {
            revert MinDelegationTimeoutPending(
                self.id,
                // solhint-disable-next-line numcast/safe-cast
                uint32(lastDelegationTime + requiredMinDelegationTime - block.timestamp)
            );
        }
    }

    function setDelayedMarketWeights(Data storage self, uint128[] memory delayedMarkets) internal {
        uint256 lastDelayedMarket;

        uint256 totalWeight = getTotalWeight(self);

        for (uint i = 0; i < self.marketConfigurations.length; i++) {
            uint128 marketId = self.marketConfigurations[i].marketId;

            while (delayedMarkets[lastDelayedMarket] < marketId) {
                // set it to an infitesimly small value
                self.heldMarketConfigurationWeights[marketId] = 1;
                lastDelayedMarket++;
            }

            if (delayedMarkets[lastDelayedMarket] == marketId) {
                self.heldMarketConfigurationWeights[marketId] =
                    self.marketConfigurations[i].weightD18 /
                    totalWeight;
                lastDelayedMarket++;
            } else {
                // market does not need to be held
                self.heldMarketConfigurationWeights[marketId] = 0;
            }
        }
    }

    function setMarketConfiguration(
        Data storage self,
        MarketConfiguration.Data[] memory newMarketConfigurations
    ) internal {
        // Identify markets that need to be removed or verified later for being locked.
        (
            ,
            uint128[] memory potentiallyLockedMarkets,
            uint128[] memory potentiallyDelayedMarkets,
            uint128[] memory removedMarkets
        ) = _analyzePoolConfigurationChange(self, newMarketConfigurations);

        if (isCrossChainEnabled(self)) {
            setDelayedMarketWeights(self, potentiallyDelayedMarkets);
        }

        // Replace existing market configurations with the new ones.
        // (May leave old configurations at the end of the array if the new array is shorter).
        uint256 i = 0;
        uint256 totalWeight = 0;
        // Iterate up to the shorter length.
        uint256 len = newMarketConfigurations.length < self.marketConfigurations.length
            ? newMarketConfigurations.length
            : self.marketConfigurations.length;
        for (; i < len; i++) {
            self.marketConfigurations[i] = newMarketConfigurations[i];
            totalWeight += newMarketConfigurations[i].weightD18;
        }

        // If the old array was shorter, push the new elements in.
        for (; i < newMarketConfigurations.length; i++) {
            self.marketConfigurations.push(newMarketConfigurations[i]);
            totalWeight += newMarketConfigurations[i].weightD18;
        }

        // If the old array was longer, truncate it.
        uint256 popped = self.marketConfigurations.length - i;
        for (i = 0; i < popped; i++) {
            self.marketConfigurations.pop();
        }

        // Rebalance all markets that need to be removed.
        for (i = 0; i < removedMarkets.length && removedMarkets[i] != 0; i++) {
            Market.rebalancePools(removedMarkets[i], self.id, 0, 0);
        }

        self.totalWeightsD18 = totalWeight.to128();

        // Credit capacity has been updated--rebalance pools.
        rebalanceMarketsInPool(self);

        // The credit delegation proportion of the pool can only stay the same, or increase,
        // so prevent the removal of markets whose capacity is locked.
        // Note: This check is done here because it needs to happen after removed markets are rebalanced.
        for (i = 0; i < potentiallyLockedMarkets.length && potentiallyLockedMarkets[i] != 0; i++) {
            if (Market.load(potentiallyLockedMarkets[i]).isCapacityLocked()) {
                revert CapacityLocked(potentiallyLockedMarkets[i]);
            }
        }
    }

    struct AnalyzePoolConfigRuntime {
        uint256 oldIdx;
        uint256 potentiallyLockedMarketsIdx;
        uint256 potentiallyDelayedMarketsIdx;
        uint256 removedMarketsIdx;
        uint128 lastMarketId;
    }

    /**
     * @dev Compares a new pool configuration with the existing one,
     * and returns information about markets that need to be removed, or whose capacity might be locked.
     *
     * Note: Stack too deep errors prevent the use of local variables to improve code readability here.
     */
    function _analyzePoolConfigurationChange(
        Pool.Data storage pool,
        MarketConfiguration.Data[] memory newMarketConfigurations
    )
        internal
        view
        returns (
            uint256 totalWeightD18,
            uint128[] memory potentiallyLockedMarkets,
            uint128[] memory potentiallyDelayedMarkets,
            uint128[] memory removedMarkets
        )
    {
        AnalyzePoolConfigRuntime memory rt;

        potentiallyLockedMarkets = new uint128[](pool.marketConfigurations.length);
        potentiallyDelayedMarkets = new uint128[](pool.marketConfigurations.length);
        removedMarkets = new uint128[](pool.marketConfigurations.length);

        // First we need the current total weight
        for (uint256 i = 0; i < newMarketConfigurations.length; i++) {
            totalWeightD18 += newMarketConfigurations[i].weightD18;
        }

        if (isCrossChainEnabled(pool)) {
            // we need to consider the cross chain weight as well
            totalWeightD18 =
                pool.crossChain[0].latestTotalWeights +
                totalWeightD18 -
                pool.totalWeightsD18;
        }

        // Now, iterate through the incoming market configurations, and compare with them with the existing ones.
        for (uint256 newIdx = 0; newIdx < newMarketConfigurations.length; newIdx++) {
            // Reject duplicate market ids,
            // AND ensure that they are provided in ascending order.
            if (newMarketConfigurations[newIdx].marketId <= rt.lastMarketId) {
                revert ParameterError.InvalidParameter(
                    "markets",
                    "must be supplied in strictly ascending order"
                );
            }
            rt.lastMarketId = newMarketConfigurations[newIdx].marketId;

            // Reject markets with no weight.
            if (newMarketConfigurations[newIdx].weightD18 == 0) {
                revert ParameterError.InvalidParameter("weights", "weight must be non-zero");
            }

            // Note: The following blocks of code compare the incoming market (at newIdx) to an existing market (at oldIdx).
            // newIdx increases once per iteration in the for loop, but oldIdx may increase multiple times if certain conditions are met.

            // If the market id of newIdx is greater than any of the old market ids,
            // consider all the old ones removed and mark them for post verification (increases oldIdx for each).
            while (
                rt.oldIdx < pool.marketConfigurations.length &&
                pool.marketConfigurations[rt.oldIdx].marketId <
                newMarketConfigurations[newIdx].marketId
            ) {
                potentiallyLockedMarkets[rt.potentiallyLockedMarketsIdx++] = pool
                    .marketConfigurations[rt.oldIdx]
                    .marketId;
                removedMarkets[rt.removedMarketsIdx++] = potentiallyLockedMarkets[
                    rt.potentiallyLockedMarketsIdx - 1
                ];

                rt.oldIdx++;
            }

            // If the market id of newIdx is equal to any of the old market ids,
            // consider it updated (increases oldIdx once).
            if (
                rt.oldIdx < pool.marketConfigurations.length &&
                pool.marketConfigurations[rt.oldIdx].marketId ==
                newMarketConfigurations[newIdx].marketId
            ) {
                // Get weight ratios for comparison below.
                // Upscale them to make sure that we have compatible precision in case of very small values.
                // If the market's new maximum share value or weight ratio decreased,
                // mark it for later verification.
                if (
                    newMarketConfigurations[newIdx].maxDebtShareValueD18 <
                    pool.marketConfigurations[rt.oldIdx].maxDebtShareValueD18 ||
                    newMarketConfigurations[newIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(totalWeightD18) < // newWeightRatioD27
                    pool
                        .marketConfigurations[rt.oldIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(pool.totalWeightsD18) // oldWeightRatioD27
                ) {
                    potentiallyLockedMarkets[
                        rt.potentiallyLockedMarketsIdx++
                    ] = newMarketConfigurations[newIdx].marketId;
                }

                // Get "delayed" markets aka markets with increasing weight
                // this is necessary for cross chain pools, which should wait until pools with reduced weight to acknowledge the change before increasing weight
                if (
                    newMarketConfigurations[newIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(totalWeightD18) > // newWeightRatioD27
                    pool
                        .marketConfigurations[rt.oldIdx]
                        .weightD18
                        .to256()
                        .upscale(DecimalMath.PRECISION_FACTOR)
                        .divDecimal(pool.totalWeightsD18) // oldWeightRatioD27
                ) {
                    potentiallyDelayedMarkets[
                        rt.potentiallyDelayedMarketsIdx++
                    ] = newMarketConfigurations[newIdx].marketId;
                }

                rt.oldIdx++;
            }

            // Note: processing or checks for added markets is not necessary.
        } // for end

        // If any of the old markets was not processed up to this point,
        // it means that it is not present in the new array, so mark it for removal.
        while (rt.oldIdx < pool.marketConfigurations.length) {
            removedMarkets[rt.removedMarketsIdx++] = pool.marketConfigurations[rt.oldIdx].marketId;
            rt.oldIdx++;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./PoolCrossChainSync.sol";

library PoolCrossChainInfo {
    struct Data {
        PoolCrossChainSync.Data latestSync;
        uint128 latestTotalWeights;
        uint64[] pairedChains;
        mapping(uint64 => uint128) pairedPoolIds;
        uint64 chainlinkSubscriptionId;
        uint32 chainlinkSubscriptionInterval;
        bytes32 latestRequestId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library PoolCrossChainSync {
    struct Data {
        uint128 liquidity;
        int128 cumulativeMarketDebt;
        int128 totalDebt;
        uint64 dataTimestamp;
        uint64 oldestDataTimestamp;
        uint64 oldestPoolConfigTimestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import "../interfaces/external/IRewardDistributor.sol";

import "./Distribution.sol";
import "./RewardDistributionClaimStatus.sol";

/**
 * @title Used by vaults to track rewards for its participants. There will be one of these for each pool, collateral type, and distributor combination.
 */
library RewardDistribution {
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SafeCastU64 for uint64;
    using SafeCastU32 for uint32;
    using SafeCastI32 for int32;

    struct Data {
        /**
         * @dev The 3rd party smart contract which holds/mints tokens for distributing rewards to vault participants.
         */
        IRewardDistributor distributor;
        /**
         * @dev Available slot.
         */
        uint128 __slotAvailableForFutureUse;
        /**
         * @dev The value of the rewards in this entry.
         */
        uint128 rewardPerShareD18;
        /**
         * @dev The status for each actor, regarding this distribution's entry.
         */
        mapping(uint256 => RewardDistributionClaimStatus.Data) claimStatus;
        /**
         * @dev Value to be distributed as rewards in a scheduled form.
         */
        int128 scheduledValueD18;
        /**
         * @dev Date at which the entry's rewards will begin to be claimable.
         *
         * Note: Set to <= block.timestamp to distribute immediately to currently participating users.
         */
        uint64 start;
        /**
         * @dev Time span after the start date, in which the whole of the entry's rewards will become claimable.
         */
        uint32 duration;
        /**
         * @dev Date on which this distribution entry was last updated.
         */
        uint32 lastUpdate;
    }

    /**
     * @dev Distributes rewards into a new rewards distribution entry.
     *
     * Note: this function allows for more special cases such as distributing at a future date or distributing over time.
     * If you want to apply the distribution to the pool, call `distribute` with the return value. Otherwise, you can
     * record this independently as well.
     */
    function distribute(
        Data storage self,
        Distribution.Data storage dist,
        int256 amountD18,
        uint64 start,
        uint32 duration
    ) internal returns (int256 diffD18) {
        uint256 totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert ParameterError.InvalidParameter(
                "amount",
                "can't distribute to empty distribution"
            );
        }

        uint256 curTime = block.timestamp;

        // Unlocks the entry's distributed amount into its value per share.
        diffD18 += updateEntry(self, totalSharesD18);

        // If the current time is past the end of the entry's duration,
        // update any rewards which may have accrued since last run.
        // (instant distribution--immediately disperse amount).
        if (start + duration <= curTime) {
            diffD18 += amountD18.divDecimal(totalSharesD18.toInt());

            self.lastUpdate = 0;
            self.start = 0;
            self.duration = 0;
            self.scheduledValueD18 = 0;
            // Else, schedule the amount to distribute.
        } else {
            self.scheduledValueD18 = amountD18.to128();

            self.start = start;
            self.duration = duration;

            // The amount is actually the amount distributed already *plus* whatever has been specified now.
            self.lastUpdate = 0;

            diffD18 += updateEntry(self, totalSharesD18);
        }
    }

    /**
     * @dev Updates the total shares of a reward distribution entry, and releases its unlocked value into its value per share, depending on the time elapsed since the start of the distribution's entry.
     *
     * Note: call every time before `totalShares` changes.
     */
    function updateEntry(
        Data storage self,
        uint256 totalSharesAmountD18
    ) internal returns (int256) {
        // Cannot process distributed rewards if a pool is empty or if it has no rewards.
        if (self.scheduledValueD18 == 0 || totalSharesAmountD18 == 0) {
            return 0;
        }

        uint256 curTime = block.timestamp;

        int256 valuePerShareChangeD18 = 0;

        // Cannot update an entry whose start date has not being reached.
        if (curTime < self.start) {
            return 0;
        }

        // If the entry's duration is zero and the its last update is zero,
        // consider the entry to be an instant distribution.
        if (self.duration == 0 && self.lastUpdate < self.start) {
            // Simply update the value per share to the total value divided by the total shares.
            valuePerShareChangeD18 = self.scheduledValueD18.to256().divDecimal(
                totalSharesAmountD18.toInt()
            );
            // Else, if the last update was before the end of the duration.
        } else if (self.lastUpdate < self.start + self.duration) {
            // Determine how much was previously distributed.
            // If the last update is zero, then nothing was distributed,
            // otherwise the amount is proportional to the time elapsed since the start.
            int256 lastUpdateDistributedD18 = self.lastUpdate < self.start
                ? SafeCastI128.zero()
                : (self.scheduledValueD18 * (self.lastUpdate - self.start).toInt()) /
                    self.duration.toInt();

            // If the current time is beyond the duration, then consider all scheduled value to be distributed.
            // Else, the amount distributed is proportional to the elapsed time.
            int256 curUpdateDistributedD18 = self.scheduledValueD18;
            if (curTime < self.start + self.duration) {
                // Note: Not using an intermediate time ratio variable
                // in the following calculation to maintain precision.
                curUpdateDistributedD18 =
                    (curUpdateDistributedD18 * (curTime - self.start).toInt()) /
                    self.duration.toInt();
            }

            // The final value per share change is the difference between what is to be distributed and what was distributed.
            valuePerShareChangeD18 = (curUpdateDistributedD18 - lastUpdateDistributedD18)
                .divDecimal(totalSharesAmountD18.toInt());
        }

        self.lastUpdate = curTime.to32();

        return valuePerShareChangeD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Tracks information per actor within a RewardDistribution.
 */
library RewardDistributionClaimStatus {
    struct Data {
        /**
         * @dev The last known reward per share for this actor.
         */
        uint128 lastRewardPerShareD18;
        /**
         * @dev The amount of rewards pending to be claimed by this actor.
         */
        uint128 pendingSendD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Data structure that wraps a mapping with a scalar multiplier.
 *
 * If you wanted to modify all the values in a mapping by the same amount, you would normally have to loop through each entry in the mapping. This object allows you to modify all of them at once, by simply modifying the scalar multiplier.
 *
 * I.e. a regular mapping represents values like this:
 * value = mapping[id]
 *
 * And a scalable mapping represents values like this:
 * value = mapping[id] * scalar
 *
 * This reduces the number of computations needed for modifying the balances of N users from O(n) to O(1).

 * Note: Notice how users are tracked by a generic bytes32 id instead of an address. This allows the actors of the mapping not just to be addresses. They can be anything, for example a pool id, an account id, etc.
 *
 * *********************
 * Conceptual Examples
 * *********************
 *
 * 1) Socialization of collateral during a liquidation.
 *
 * Scalable mappings are very useful for "socialization" of collateral, that is, the re-distribution of collateral when an account is liquidated. Suppose 1000 ETH are liquidated, and would need to be distributed amongst 1000 depositors. With a regular mapping, every depositor's balance would have to be modified in a loop that iterates through every single one of them. With a scalable mapping, the scalar would simply need to be incremented so that the total value of the mapping increases by 1000 ETH.
 *
 * 2) Socialization of debt during a liquidation.
 *
 * Similar to the socialization of collateral during a liquidation, the debt of the position that is being liquidated can be re-allocated using a scalable mapping with a single action. Supposing a scalable mapping tracks each user's debt in the system, and that 1000 sUSD has to be distributed amongst 1000 depositors, the debt data structure's scalar would simply need to be incremented so that the total value or debt of the distribution increments by 1000 sUSD.
 *
 */
library ScalableMapping {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;
    using DecimalMath for uint256;

    /**
     * @dev Thrown when attempting to scale a mapping with an amount that is lower than its resolution.
     */
    error InsufficientMappedAmount();

    /**
     * @dev Thrown when attempting to scale a mapping with no shares.
     */
    error CannotScaleEmptyMapping();

    struct Data {
        uint128 totalSharesD18;
        int128 scaleModifierD27;
        mapping(bytes32 => uint256) sharesD18;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     * @dev The incoming value is split per share, and used as a delta that is *added* to the existing scale modifier. The resulting scale modifier must be in the range [-1, type(int128).max).
     */
    function scale(Data storage self, int256 valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            revert CannotScaleEmptyMapping();
        }

        int256 valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int256 deltaScaleModifierD27 = valueD45 / totalSharesD18.toInt();

        self.scaleModifierD27 += deltaScaleModifierD27.to128();

        if (self.scaleModifierD27 < -DecimalMath.UNIT_PRECISE_INT) {
            revert InsufficientMappedAmount();
        }
    }

    /**
     * @dev Updates an actor's individual value in the distribution to the specified amount.
     *
     * The change in value is manifested in the distribution by changing the actor's number of shares in it, and thus the distribution's total number of shares.
     *
     * Returns the resulting amount of shares that the actor has after this change in value.
     */
    function set(
        Data storage self,
        bytes32 actorId,
        uint256 newActorValueD18
    ) internal returns (uint256 resultingSharesD18) {
        // Represent the actor's change in value by changing the actor's number of shares,
        // and keeping the distribution's scaleModifier constant.

        resultingSharesD18 = getSharesForAmount(self, newActorValueD18);

        // Modify the total shares with the actor's change in shares.
        self.totalSharesD18 = (self.totalSharesD18 + resultingSharesD18 - self.sharesD18[actorId])
            .to128();

        self.sharesD18[actorId] = resultingSharesD18.to128();
    }

    /**
     * @dev Returns the value owned by the actor in the distribution.
     *
     * i.e. actor.shares * scaleModifier
     */
    function get(Data storage self, bytes32 actorId) internal view returns (uint256 valueD18) {
        uint256 totalSharesD18 = self.totalSharesD18;
        if (totalSharesD18 == 0) {
            return 0;
        }

        return (self.sharesD18[actorId] * totalAmount(self)) / totalSharesD18;
    }

    /**
     * @dev Returns the total value held in the distribution.
     *
     * i.e. totalShares * scaleModifier
     */
    function totalAmount(Data storage self) internal view returns (uint256 valueD18) {
        return
            ((self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT).toUint() *
                self.totalSharesD18) / DecimalMath.UNIT_PRECISE;
    }

    function getSharesForAmount(
        Data storage self,
        uint256 amountD18
    ) internal view returns (uint256 sharesD18) {
        sharesD18 =
            (amountD18 * DecimalMath.UNIT_PRECISE) /
            (self.scaleModifierD27 + DecimalMath.UNIT_PRECISE_INT128).toUint();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

/**
 * @title System wide configuration for pools.
 */
library SystemPoolConfiguration {
    bytes32 private constant _SLOT_SYSTEM_POOL_CONFIGURATION =
        keccak256(abi.encode("io.synthetix.synthetix.SystemPoolConfiguration"));

    struct Data {
        /**
         * @dev Owner specified system-wide limiting factor that prevents markets from minting too much debt, similar to the issuance ratio to a collateral type.
         *
         * Note: If zero, then this value defaults to 100%.
         */
        uint256 minLiquidityRatioD18;
        uint128 __reservedForFutureUse;
        /**
         * @dev Id of the main pool set by the system owner.
         */
        uint128 preferredPool;
        /**
         * @dev List of pools approved by the system owner.
         */
        SetUtil.UintSet approvedPools;
        uint128 lastPoolId;
    }

    /**
     * @dev Returns the configuration singleton.
     */
    function load() internal pure returns (Data storage systemPoolConfiguration) {
        bytes32 s = _SLOT_SYSTEM_POOL_CONFIGURATION;
        assembly {
            systemPoolConfiguration.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./VaultEpoch.sol";
import "./RewardDistribution.sol";

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type.
 *
 * I.e. if a pool supports SNX and ETH collaterals, it will have an SNX Vault, and an ETH Vault.
 *
 * The Vault data structure is itself split into VaultEpoch sub-structures. This facilitates liquidations,
 * so that whenever one occurs, a clean state of all data is achieved by simply incrementing the epoch index.
 *
 * It is recommended to understand VaultEpoch before understanding this object.
 */
library Vault {
    using VaultEpoch for VaultEpoch.Data;
    using Distribution for Distribution.Data;
    using RewardDistribution for RewardDistribution.Data;
    using ScalableMapping for ScalableMapping.Data;
    using DecimalMath for uint256;
    using DecimalMath for int128;
    using DecimalMath for int256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using SetUtil for SetUtil.Bytes32Set;

    /**
     * @dev Thrown when a non-existent reward distributor is referenced
     */
    error RewardDistributorNotFound();

    struct Data {
        /**
         * @dev The vault's current epoch number.
         *
         * Vault data is divided into epochs. An epoch changes when an entire vault is liquidated.
         */
        uint256 epoch;
        /**
         * @dev Unused property, maintained for backwards compatibility in storage layout.
         */
        // solhint-disable-next-line private-vars-leading-underscore
        bytes32 __slotAvailableForFutureUse;
        /**
         * @dev The previous capacity of the vault, which is basically the actual available USD capacity, not including debt
         * TODO: check this storage addition, I think its OK? we forgot to "reserve" it earlier :( but this is the most efficient place
         */
        uint128 prevCapacityD18;
        /**
         * @dev The previous debt of the vault, when `updateCreditCapacity` was last called by the Pool.
         */
        int128 prevTotalDebtD18;
        /**
         * @dev Vault data for all the liquidation cycles divided into epochs.
         */
        mapping(uint256 => VaultEpoch.Data) epochData;
        /**
         * @dev Tracks available rewards, per user, for this vault.
         */
        mapping(bytes32 => RewardDistribution.Data) rewards;
        /**
         * @dev Tracks reward ids, for this vault.
         */
        SetUtil.Bytes32Set rewardIds;
    }

    /**
     * @dev Return's the VaultEpoch data for the current epoch.
     */
    function currentEpoch(Data storage self) internal view returns (VaultEpoch.Data storage) {
        return self.epochData[self.epoch];
    }

    /**
     * @dev Updates the vault's credit capacity as the value of its collateral minus its debt.
     *
     * Called as a ticker when users interact with pools, allowing pools to set
     * vaults' credit capacity shares within them.
     *
     * Returns the amount of collateral that this vault is providing in net USD terms.
     */
    function updateCreditCapacity(
        Data storage self,
        uint256 collateralPriceD18
    )
        internal
        returns (
            uint256 usdWeightD18,
            uint256 usdCapacityD18,
            int256 deltaCapacityD18,
            int256 totalDebtD18,
            int256 deltaDebtD18
        )
    {
        VaultEpoch.Data storage epochData = currentEpoch(self);

        usdWeightD18 = (epochData.collateralAmounts.totalAmount() +
            epochData.totalExitingCollateralD18).mulDecimal(collateralPriceD18);
        usdCapacityD18 = (epochData.collateralAmounts.totalAmount()).mulDecimal(collateralPriceD18);

        totalDebtD18 = epochData.totalDebt();

        deltaDebtD18 = totalDebtD18 - self.prevTotalDebtD18;
        deltaCapacityD18 = usdCapacityD18.toInt() - self.prevCapacityD18.toInt();

        self.prevTotalDebtD18 = totalDebtD18.to128();
        self.prevCapacityD18 = usdCapacityD18.to128();
    }

    /**
     * @dev Updated the value per share of the current epoch's incoming debt distribution.
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        currentEpoch(self).distributeDebtToAccounts(debtChangeD18);
    }

    /**
     * @dev Consolidates an accounts debt.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256) {
        return currentEpoch(self).consolidateAccountDebt(accountId);
    }

    /**
     * @dev Traverses available rewards for this vault, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateRewards(
        Data storage self,
        uint128 accountId,
        uint128 poolId,
        address collateralType
    ) internal returns (uint256[] memory rewards, address[] memory distributors) {
        rewards = new uint256[](self.rewardIds.length());
        distributors = new address[](self.rewardIds.length());

        uint256 numRewards = self.rewardIds.length();
        for (uint256 i = 0; i < numRewards; i++) {
            RewardDistribution.Data storage dist = self.rewards[self.rewardIds.valueAt(i + 1)];

            if (address(dist.distributor) == address(0)) {
                continue;
            }

            distributors[i] = address(dist.distributor);
            rewards[i] = updateReward(
                self,
                accountId,
                poolId,
                collateralType,
                self.rewardIds.valueAt(i + 1)
            );
        }
    }

    /**
     * @dev Traverses available rewards for this vault and the reward id, and updates an accounts
     * claim on them according to the amount of debt shares they have.
     */
    function updateReward(
        Data storage self,
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        bytes32 rewardId
    ) internal returns (uint256) {
        uint256 totalSharesD18 = currentEpoch(self).accountsDebtDistribution.totalSharesD18;
        uint256 actorSharesD18 = currentEpoch(self).accountsDebtDistribution.getActorShares(
            accountId.toBytes32()
        );

        RewardDistribution.Data storage dist = self.rewards[rewardId];

        if (address(dist.distributor) == address(0)) {
            revert RewardDistributorNotFound();
        }

        dist.distributor.onPositionUpdated(accountId, poolId, collateralType, actorSharesD18);

        dist.rewardPerShareD18 += dist.updateEntry(totalSharesD18).toUint().to128();

        dist.claimStatus[accountId].pendingSendD18 += actorSharesD18
            .mulDecimal(dist.rewardPerShareD18 - dist.claimStatus[accountId].lastRewardPerShareD18)
            .to128();

        dist.claimStatus[accountId].lastRewardPerShareD18 = dist.rewardPerShareD18;

        return dist.claimStatus[accountId].pendingSendD18;
    }

    /**
     * @dev Increments the current epoch index, effectively producing a
     * completely blank new VaultEpoch data structure in the vault.
     */
    function reset(Data storage self) internal {
        self.epoch++;
    }

    /**
     * @dev Returns the vault's combined debt (consolidated and unconsolidated),
     * for the current epoch.
     */
    function currentDebt(Data storage self) internal view returns (int256) {
        return currentEpoch(self).totalDebt();
    }

    /**
     * @dev Returns the total value in the Vault's collateral distribution, for the current epoch.
     */
    function currentCollateral(Data storage self) internal view returns (uint256) {
        return currentEpoch(self).collateralAmounts.totalAmount();
    }

    /**
     * @dev Returns an account's collateral value in this vault's current epoch.
     */
    function currentAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256) {
        return currentEpoch(self).getAccountCollateral(accountId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./Distribution.sol";
import "./ScalableMapping.sol";
import "./CollateralLock.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Tracks collateral and debt distributions in a pool, for a specific collateral type, in a given epoch.
 *
 * Collateral is tracked with a distribution as opposed to a regular mapping because liquidations cause collateral to be socialized. If collateral was tracked using a regular mapping, such socialization would be difficult and require looping through individual balances, or some other sort of complex and expensive mechanism. Distributions make socialization easy.
 *
 * Debt is also tracked in a distribution for the same reason, but it is additionally split in two distributions: incoming and consolidated debt.
 *
 * Incoming debt is modified when a liquidations occurs.
 * Consolidated debt is updated when users interact with the system.
 */
library VaultEpoch {
    using Distribution for Distribution.Data;
    using DecimalMath for uint256;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using ScalableMapping for ScalableMapping.Data;

    struct Data {
        /**
         * @dev Amount of debt in this Vault that is yet to be consolidated.
         *
         * E.g. when a given amount of debt is socialized during a liquidation, but it yet hasn't been rolled into
         * the consolidated debt distribution.
         */
        int128 unconsolidatedDebtD18;
        /**
         * @dev Amount of debt in this Vault that has been consolidated.
         */
        int128 totalConsolidatedDebtD18;
        /**
         * @dev Tracks incoming debt for each user.
         *
         * The value of shares in this distribution change as the associate market changes, i.e. price changes in an asset in
         * a spot market.
         *
         * Also, when debt is socialized in a liquidation, it is done onto this distribution. As users
         * interact with the system, their independent debt is consolidated or rolled into consolidatedDebtDist.
         */
        Distribution.Data accountsDebtDistribution;
        /**
         * @dev Tracks collateral delegated to this vault, for each user.
         *
         * Uses a distribution instead of a regular market because of the way collateral is socialized during liquidations.
         *
         * A regular mapping would require looping over the mapping of each account's collateral, or moving the liquidated
         * collateral into a place where it could later be claimed. With a distribution, liquidated collateral can be
         * socialized very easily.
         */
        ScalableMapping.Data collateralAmounts;
        /**
         * @dev Tracks consolidated debt for each user.
         *
         * Updated when users interact with the system, consolidating changes from the fluctuating accountsDebtDistribution,
         * and directly when users mint or burn USD, or repay debt.
         */
        mapping(uint256 => int256) consolidatedDebtAmountsD18;
        /**
         * @dev Tracks last time a user delegated to this vault.
         *
         * Needed to validate min delegation time compliance to prevent small scale debt pool frontrunning
         */
        mapping(uint128 => uint64) lastDelegationTime;
        uint128 totalExitingCollateralD18;
        uint128 _reserved;
        /**
         * @dev When collateral is removed from a pool, it must first go into "exiting" collateral. This allows
         * for any debt which is accumulated asynchronously from the pool to be accounted before completely
         * closing the position.
         */
        mapping(bytes32 => CollateralLock.Data) exitingCollateral;
    }

    /**
     * @dev Updates the value per share of the incoming debt distribution.
     * Used for socialization during liquidations, and to bake in market changes.
     *
     * Called from:
     * - LiquidationModule.liquidate
     * - Pool.recalculateVaultCollateral (ticker)
     */
    function distributeDebtToAccounts(Data storage self, int256 debtChangeD18) internal {
        self.accountsDebtDistribution.distributeValue(debtChangeD18);

        // Cache total debt here.
        // Will roll over to individual users as they interact with the system.
        self.unconsolidatedDebtD18 += debtChangeD18.to128();
    }

    /**
     * @dev Adjusts the debt associated with `accountId` by `amountD18`.
     * Used to add or remove debt from/to a specific account, instead of all accounts at once (use distributeDebtToAccounts for that)
     */
    function assignDebtToAccount(
        Data storage self,
        uint128 accountId,
        int256 amountD18
    ) internal returns (int256 newDebtD18) {
        int256 currentDebtD18 = self.consolidatedDebtAmountsD18[accountId];
        self.consolidatedDebtAmountsD18[accountId] += amountD18;
        self.totalConsolidatedDebtD18 += amountD18.to128();
        return currentDebtD18 + amountD18;
    }

    /**
     * @dev Consolidates user debt as they interact with the system.
     *
     * Fluctuating debt is moved from incoming to consolidated debt.
     *
     * Called as a ticker from various parts of the system, usually whenever the
     * real debt of a user needs to be known.
     */
    function consolidateAccountDebt(
        Data storage self,
        uint128 accountId
    ) internal returns (int256 currentDebtD18) {
        int256 newDebtD18 = self.accountsDebtDistribution.accumulateActor(accountId.toBytes32());

        currentDebtD18 = assignDebtToAccount(self, accountId, newDebtD18);
        self.unconsolidatedDebtD18 -= newDebtD18.to128();
    }

    /**
     * @dev Updates a user's collateral value, and sets their exposure to debt
     * according to the collateral they delegated and the leverage used.
     *
     * Called whenever a user's collateral increases.
     */
    function increaseAccountPosition(
        Data storage self,
        uint128 accountId,
        uint256 collateralIncreaseD18,
        uint256 leverageD18
    ) internal {
        bytes32 actorId = accountId.toBytes32();

        // Ensure account debt is consolidated before we do next things.
        consolidateAccountDebt(self, accountId);

        uint256 newCollateralAmountD18 = self.collateralAmounts.get(actorId) +
            collateralIncreaseD18;

        self.collateralAmounts.set(actorId, newCollateralAmountD18);
        self.accountsDebtDistribution.setActorShares(
            actorId,
            self.collateralAmounts.sharesD18[actorId].mulDecimal(leverageD18)
        );
    }

    /**
     * @dev Updates a user's collateral value, but leaves their exposure to debt the same. This is
     * to ensure debt responsibility has a chance to propagate.
     *
     * Called whenever a user's collateral decreases.
     */
    function decreaseAccountPosition(
        Data storage self,
        uint128 accountId,
        uint256 collateralReductionD18
    ) internal {
        bytes32 actorId = accountId.toBytes32();
        self.collateralAmounts.set(
            actorId,
            self.collateralAmounts.get(actorId) - collateralReductionD18
        );
        self.exitingCollateral[actorId] = CollateralLock.Data(
            self.exitingCollateral[actorId].amountD18 + collateralReductionD18.to128(),
            uint64(block.timestamp),
            0,
            address(0)
        );
        self.totalExitingCollateralD18 += collateralReductionD18.to128();
    }

    /**
     * @dev Returns the vault's total debt in this epoch, including the debt
     * that hasn't yet been consolidated into individual accounts.
     */
    function totalDebt(Data storage self) internal view returns (int256) {
        return self.unconsolidatedDebtD18 + self.totalConsolidatedDebtD18;
    }

    /**
     * @dev Returns an account's value in the Vault's collateral distribution.
     */
    function getAccountCollateral(
        Data storage self,
        uint128 accountId
    ) internal view returns (uint256 amountD18) {
        return self.collateralAmounts.get(accountId.toBytes32());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library CcipClient {
    struct EVMTokenAmount {
        address token; // token address on the local chain
        uint256 amount;
    }

    struct Any2EVMMessage {
        bytes32 messageId; // MessageId corresponding to ccipSend on source
        uint64 sourceChainId;
        bytes sender; // abi.decode(sender) if coming from an EVM chain
        bytes data; // payload sent in original message
        EVMTokenAmount[] tokenAmounts;
    }

    // If extraArgs is empty bytes, the default is
    // 200k gas limit and strict = false.
    struct EVM2AnyMessage {
        bytes receiver; // abi.encode(receiver address) for dest EVM chains
        bytes data; // Data payload
        EVMTokenAmount[] tokenAmounts; // Token transfers
        address feeToken; // Address of feeToken. address(0) means you will send msg.value.
        bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
    }

    // extraArgs will evolve to support new features
    // bytes4(keccak256("CCIP EVMExtraArgsV1"));
    bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    struct EVMExtraArgsV1 {
        uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR ALPHA TESTING
        bool strict; // See strict sequencing details below.
    }

    function _argsToBytes(
        EVMExtraArgsV1 memory extraArgs
    ) internal pure returns (bytes memory bts) {
        return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
    }
}