//SPDX-License-Identifier: GPL-3-or-later
pragma solidity ^0.8.0;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequester.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../utils/Ownable.sol";

import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IStrategy.sol";

import "../libraries/KassandraConstants.sol";

/**
 * @title $aHYPE strategy
 *
 * @notice There's still some centralization to remove, the worst case scenario though is that bad
 *         weights will be put, but they'll take 24h to take total effect, and by then pretty much
 *         everybody will be able to withdraw their funds from the pool.
 *
 * @dev If you have ideas on how to make this truly decentralised get in contact with us on our GitHub
 *      We are looking for truly cryptoeconomically sound ways to fix this, so hundreds of people instead
 *      of a few dozen and that make people have a reason to maintain and secure the strategy without trolling
 */
contract StrategyAHYPE is IStrategy, Ownable, Pausable, RrpRequester {
    // this prevents a possible problem that while weights change their sum could potentially go beyond maximum
    uint256 private constant _MAX_TOTAL_WEIGHT = 40; // KassandraConstants.MAX_WEIGHT - 10
    uint256 private constant _MAX_TOTAL_WEIGHT_ONE = _MAX_TOTAL_WEIGHT * 10 ** 18; // KassandraConstants.ONE
    // Exactly like _DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD from ConfigurableRightsPool.sol
    uint256 private constant _CHANGE_BLOCK_PERIOD = 5700;
    // API3 requests limiter
    uint8 private constant _NONE = 1;
    uint8 private constant _ONGOING = 2;
    uint8 private constant _SUSPEND = 3;

    uint8 private _requestStatus = _NONE;
    bool private _hasAPIData;

    /// How much the new normalized weight must change to trigger an automatic suspension
    int64 public suspectDiff;
    /// The social scores from the previous call
    uint24[16] private _lastScores;
    /// The social scores that are pending a review, if any
    uint24[16] private _pendingScores;
    // The pending weights already calculated by the strategy
    uint256[] private _pendingWeights;

    /// Amount of blocks weights will update linearly
    uint256 public weightUpdateBlockPeriod;

    /// API3 data provider id (Heimdall)
    address public airnodeId;
    /// API3 endpoint id for the data provider (30d scores)
    bytes32 public endpointId;
    /// API3 template id where request is already cached
    bytes32 public templateId;
    /// Sponsor that allows this client to use the funds in its designated wallet (governance)
    address public sponsorAddress;
    /// Wallet the governance funds and has designated for this contract to use
    address public sponsorWallet;

    /// Responsible for pinging this contract to start the weight update
    address public updaterRole;
    /**
     * @notice Responsible for watching this contract from misbehaviour and stopping API3 or Heimdall from manipulation.
     *         Not ideal, but works for now, plans to rewrite this in a truly decentralised way are on going.
     *         More information on the contract explanation.
     *
     * @dev If you have ideas on how to make this truly decentralised get in contact with us on our GitHub
     *      We are looking for truly cryptoeconomically sound ways to fix this, so hundreds of people instead
     *      of a few dozen and that make people have a reason to maintain and secure the strategy without trolling
     */
    address public watcherRole;
    /// List of token symbols to be requested to Heimdall
    string[] private _tokensListHeimdall;

    /// CRP this contract is a strategy of
    IConfigurableRightsPool public crpPool;
    /// Core Factory contract to get $KACY enforcement details
    IFactory public coreFactory;

    /// List of incoming responses that have been queued
    mapping(bytes32 => bool) public incomingFulfillments;

    /**
     * @notice Emitted when receiving API3 data completes
     *
     * @param requestId - What request failed
     */
    event RequestCompleted(
        bytes32 indexed requestId
    );

    /**
     * @notice Emitted when the strategy has been paused
     *
     * @param caller - Who paused the strategy
     * @param reason - The reason it was paused
     */
    event StrategyPaused(
        address indexed caller,
        bytes32 indexed reason
    );

    /**
     * @notice Emitted when the strategy has been resumed/unpaused
     *
     * @param caller - Who resumed the strategy
     * @param reason - The reason it was resumed
     */
    event StrategyResumed(
        address indexed caller,
        bytes32 indexed reason
    );

    /**
     * @notice Emitted when the suspectDiff is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewSuspectDiff(
        address indexed caller,
        int64           oldValue,
        int64           newValue
    );

    /**
     * @notice Emitted when the API3 parameters have changed
     *
     * @param caller - Who made the change
     * @param oldAirnode - Previous provider address
     * @param newAirnode - New provider address
     * @param oldEndpoint - Previous endpoint ID
     * @param newEndpoint - New endpoint ID
     * @param oldSponsor - Previous sponsor address
     * @param newSponsor - New sponsor address
     * @param oldWallet - Previous designated wallet
     * @param newWallet - New designated wallet
     */
    event NewAPI3(
        address indexed caller,
        address         oldAirnode,
        address         newAirnode,
        bytes32         oldEndpoint,
        bytes32         newEndpoint,
        address         oldSponsor,
        address         newSponsor,
        address         oldWallet,
        address         newWallet
    );

    /**
     * @notice Emitted when the CRP Pool is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewCRP(
        address indexed caller,
        address         oldValue,
        address         newValue
    );

    /**
     * @notice Emitted when the coreFactory is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewFactory(
        address indexed caller,
        address         oldValue,
        address         newValue
    );

    /**
     * @notice Emitted when the updater role is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewUpdater(
        address indexed caller,
        address         oldValue,
        address         newValue
    );

    /**
     * @notice Emitted when the watcher role is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewWatcher(
        address indexed caller,
        address         oldValue,
        address         newValue
    );

    /**
     * @notice Emitted when the block period for weight update is changed
     *
     * @param caller - Who made the change
     * @param oldValue - Previous value
     * @param newValue - New value
     */
    event NewBlockPeriod(
        address indexed caller,
        uint256         oldValue,
        uint256         newValue
    );

    /**
     * @notice Construct the $aHYPE Strategy
     *
     * @dev The token list is used to more easily add and remove tokens,
     *      the real parameter argument is already ABI encoded to save gas later.
     *
     * @param airnodeAddress - the address of the Airnode contract in the network
     * @param tokensList - the list of tokens, at the same order as in the pool, that will be requested to Heimdall
     */
    constructor(
        address airnodeAddress,
        uint weightBlockPeriod,
        string[] memory tokensList
        )
        RrpRequester(airnodeAddress)
    {
        require(weightBlockPeriod >= _CHANGE_BLOCK_PERIOD, "ERR_BELOW_MINIMUM");
        require(tokensList.length >= KassandraConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(tokensList.length <= KassandraConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        weightUpdateBlockPeriod = weightBlockPeriod;
        _tokensListHeimdall = tokensList;
        suspectDiff = int64(int256(KassandraConstants.ONE));
    }

    /**
     * @notice Set how much the normalized weight must change from the previous one to automatically suspend the update
     *         The watcher is then responsible for manually checking if the request looks normal
     *         Setting a value of 100% or above effectively disables the check
     *
     * @dev This is an absolute change in basic arithmetic subtraction, e.g. from 35% to 30% it'll be 5 diff.
     *
     * @param percentage - where 10^18 is 100%
     */
    function setSuspectDiff(int64 percentage)
        external
        onlyOwner
    {
        require(percentage > 0, "ERR_NOT_POSITIVE");
        emit NewSuspectDiff(msg.sender, suspectDiff, percentage);
        suspectDiff = percentage;
    }

    /**
     * @notice Update API3 request info
     *
     * @param airnodeId_ - Address of the data provider
     * @param endpointId_ - ID of the endpoint for that provider
     * @param sponsorAddress_ - Address of the sponsor (governance)
     * @param sponsorWallet_ - Wallet the governance allowed to use
     */
    function setApi3(
        address airnodeId_,
        bytes32 endpointId_,
        address sponsorAddress_,
        address sponsorWallet_
        )
        external
        onlyOwner
    {
        require(
            airnodeId_ != address(0) && sponsorAddress_ != address(0) && sponsorWallet_ != address(0),
            "ERR_ZERO_ADDRESS"
        );
        require(endpointId_ != 0, "ERR_ZERO_ARGUMENT");
        emit NewAPI3(
            msg.sender,
            airnodeId, airnodeId_,
            endpointId, endpointId_,
            sponsorAddress, sponsorAddress_,
            sponsorWallet, sponsorWallet_
        );
        airnodeId = airnodeId_;
        endpointId = endpointId_;
        sponsorAddress = sponsorAddress_;
        sponsorWallet = sponsorWallet_;
        _encodeParameters();
    }

    /**
     * @notice Update pool address
     *
     * @param newAddress - Address of new crpPool
     */
    function setCrpPool(address newAddress)
        external
        onlyOwner
    {
        emit NewCRP(msg.sender, address(crpPool), newAddress);
        crpPool = IConfigurableRightsPool(newAddress);
        // reverts if functions does not exist
        crpPool.corePool();
    }

    /**
     * @notice Update block period for weight updates
     *
     * @param newPeriod - Period in blocks the weights will update
     */
    function setWeightUpdateBlockPeriod(uint newPeriod)
        external
        onlyOwner
    {
        require(newPeriod >= _CHANGE_BLOCK_PERIOD, "ERR_BELOW_MINIMUM");
        emit NewBlockPeriod(msg.sender, weightUpdateBlockPeriod, newPeriod);
        weightUpdateBlockPeriod = newPeriod;
    }

    /**
     * @notice Update core factory address
     *
     * @param newAddress - Address of new factory
     */
    function setCoreFactory(address newAddress)
        external
        onlyOwner
    {
        emit NewFactory(msg.sender, address(coreFactory), newAddress);
        coreFactory = IFactory(newAddress);
        // reverts if functions does not exist
        coreFactory.kacyToken();
    }

    /**
     * @notice The responsible to update the contract
     *
     * @param newAddress - Address of new updater
     */
    function setUpdater(address newAddress)
        external
        onlyOwner
    {
        require(newAddress != address(0), "ERR_ZERO_ADDRESS");
        emit NewUpdater(msg.sender, updaterRole, newAddress);
        updaterRole = newAddress;
    }

    /**
     * @notice The responsible to keep an eye on the requests
     *
     * @param newAddress - Address of new updater
     */
    function setWatcher(address newAddress)
        external
        onlyOwner
    {
        require(newAddress != address(0), "ERR_ZERO_ADDRESS");
        emit NewWatcher(msg.sender, watcherRole, newAddress);
        watcherRole = newAddress;
    }

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     *
     * @dev Wraps the crpPool function to prevent the strategy updating weights while adding
     *      a token and to also update the strategy with the new token. Tokens for filling the
     *      balance should be sent to this contract so that applying the token can happen.
     *
     * @param tokenSymbol - Token symbol for Heimdall  
     *                      The token symbol can be different from the symbol in the contract  
     *                      e.g. wETH needs to be checked as ETH
     * @param token - Address of the token to be added
     * @param balance - How much to be added
     * @param denormalizedWeight - The desired token weight
     */
    function commitAddToken(
        string calldata tokenSymbol,
        address token,
        uint balance,
        uint denormalizedWeight
        )
        external
        onlyOwner
        whenNotPaused
    {
        require(_tokensListHeimdall.length < 16, "ERR_MAX_16_TOKENS");
        emit StrategyPaused(msg.sender, "NEW_TOKEN_COMMITTED");
        _pause();
        crpPool.commitAddToken(token, balance, denormalizedWeight);
        _tokensListHeimdall.push(tokenSymbol);
        _encodeParameters();
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     *         The governance must have the tokens in its wallet, it will also receive the extra pool shares
     *
     * @dev This will apply adding the token, anyone can call it so that the governance doesn't need to
     *      create two proposals to do the same thing. Adding the token has already been accepted.
     *
     *      This will also allow calling API3 again
     *
     *      applyAddToken on crpPool locks
     */
    function applyAddToken()
        external
        whenPaused
    {
        crpPool.applyAddToken();
        emit StrategyResumed(msg.sender, "NEW_TOKEN_APPLIED");
        _unpause();
    }

    /**
     * @notice Remove a token from the pool
     *
     * @dev corePool is a contract interface; function calls on it are external
     *
     * @param tokenSymbol - Token symbol for Heimdall  
     *                      The token symbol can be different from the symbol in the contract
     * @param token - token to remove
     */
    function removeToken(
        string calldata tokenSymbol,
        address token
        )
        external
        onlyOwner
        whenNotPaused
    {
        _pause();
        emit StrategyPaused(msg.sender, "REMOVING_TOKEN");
        crpPool.removeToken(token);

        // similar logic to `corePool.unbind()` so the token locations match
        uint index = 200;
        uint last = _tokensListHeimdall.length;
        bytes32 tknSymbol = keccak256(abi.encodePacked(tokenSymbol));

        for (uint i = 0; i < last; i++) {
            if (keccak256(abi.encodePacked(_tokensListHeimdall[i])) == tknSymbol) {
                index = i;
            }
        }

        require(index < 200, "ERR_TOKEN_SYMBOL_NOT_FOUND");

        last -= 1;
        _tokensListHeimdall[index] = _tokensListHeimdall[last];
        _lastScores[index] = _lastScores[last];
        _tokensListHeimdall.pop();
        _lastScores[last] = 0;
        _pendingScores[last] = 0;

        // encode the new paramaters
        _encodeParameters();
        _unpause();
        emit StrategyResumed(msg.sender, "REMOVED_TOKEN");
    }

    /**
     * @notice Pause the strategy from updating weights
     *         If API3/Airnode or Heimdall send dubious data the watcher can pause that
     */
    function pause()
        external
    {
        require(msg.sender == watcherRole, "ERR_NOT_WATCHER");
        emit StrategyPaused(msg.sender, "WATCHER_PAUSED");
        _pause();
    }

    /**
     * @notice Allow the updater and airnode to once again start updating weights
     *         Only the watcher can do this
     */
    function resume()
        external
    {
        require(msg.sender == watcherRole, "ERR_NOT_WATCHER");
        require(_requestStatus != _SUSPEND, "ERR_RESOLVE_SUSPENSION_FIRST");
        emit StrategyResumed(msg.sender, "WATCHER_RESUMED");
        _requestStatus = _NONE;
        _unpause();
    }

    /**
     * @notice A soft version of `resume`, allows the updater and airnode to
     *         once again start updating weights. This version only resolves
     *         the case where an API call failed and the contracts remains
     *         waiting for the call to return.
     *
     *         Only the watcher can do this
     *
     *         This is a security measure to prevent the Airnode from creating
     *         a rogue request in the future using an old failed ID.
     *
     * @param requestId - ID for the request that failed but is still saved
     */
    function clearFailedRequest(bytes32 requestId)
        external
    {
        require(msg.sender == watcherRole, "ERR_NOT_WATCHER");
        require(_requestStatus != _SUSPEND, "ERR_RESOLVE_SUSPENSION_FIRST");
        delete incomingFulfillments[requestId];
        _requestStatus = _NONE;
        _hasAPIData = false;
        emit StrategyResumed(msg.sender, "WATCHER_CLEARED_FAILED_REQUEST");
    }

    /**
     * @notice When the strategy has automatically suspended the watcher is responsible for manually checking the data
     *         If everything looks fine they accept the new weights or reject them.
     *
     * @dev Accepting the request will trigger the updateWeightsGradually on the pool
     *
     * @param acceptRequest - Boolean indicating if the suspended data should be accepted
     */
    function resolveSuspension(bool acceptRequest)
        external
    {
        require(msg.sender == watcherRole, "ERR_NOT_WATCHER");
        require(_requestStatus == _SUSPEND, "ERR_NO_SUSPENDED_REQUEST");

        if (acceptRequest) {
            _lastScores = _pendingScores;
            // adjust weights before new update
            crpPool.pokeWeights();
            crpPool.updateWeightsGradually(_pendingWeights, block.number, block.number + weightUpdateBlockPeriod);
            emit StrategyResumed(msg.sender, "ACCEPTED_SUSPENDED_REQUEST");
        } else {
            emit StrategyResumed(msg.sender, "REJECTED_SUSPENDED_REQUEST");
        }

        delete _pendingScores;
        _requestStatus = _NONE;
        _unpause();
    }

    /**
     * @notice Calculates the allocations and updates the weights in the pool
     *         Anyone can call this, but only once
     *         The strategy may pause itself if the allocations go beyond what's expected
     */
    function updateWeightsGradually()
        external whenNotPaused
    {
        require(_hasAPIData, "ERR_NO_PENDING_DATA");
        _hasAPIData = false;
        address[] memory tokenAddresses = IPool(crpPool.corePool()).getCurrentTokens();
        uint tokensLen = tokenAddresses.length;
        uint totalPendingScore; // the total social score will be needed for transforming them to denorm weights
        uint totalLastScore; // the total social score will be needed for transforming them to denorm weights
        uint[] memory tokenWeights = new uint[](tokensLen);
        // we need to make sure the amount of $KACY meets the criteria specified by the protocol
        address kacyToken = coreFactory.kacyToken();
        uint kacyIdx;
        bool suspectRequest = false;

        // get social scores
        for (uint i = 0; i < tokensLen; i++) {
            if (kacyToken == tokenAddresses[i]) {
                kacyIdx = i;
                continue; // $KACY is fixed
            }

            require(_pendingScores[i] != 0, "ERR_SCORE_ZERO");
            totalPendingScore += _pendingScores[i];
            totalLastScore += uint256(_lastScores[i]);
        }

        if (totalLastScore == 0) {totalLastScore = 1;}

        uint minimumKacy = coreFactory.minimumKacy();
        uint totalWeight = _MAX_TOTAL_WEIGHT_ONE;
        // doesn't overflow because this is always below 10^37
        uint minimumWeight = _MAX_TOTAL_WEIGHT * minimumKacy; // totalWeight * minimumKacy / KassandraConstants.ONE
        totalWeight -= minimumWeight;

        for (uint i = 0; i < tokensLen; i++) {
            uint percentage95 = 95 * KassandraConstants.ONE / 100;
            uint normalizedPending = (_pendingScores[i] * percentage95) / totalPendingScore;
            uint normalizedLast = (_lastScores[i] * percentage95) / totalLastScore;
            // these are normalised to 10^18, so definitely won't overflow
            int64 diff = int64(int256(normalizedPending) - int256(normalizedLast));
            suspectRequest = suspectRequest || diff >= suspectDiff || diff <= -suspectDiff;
            // transform social scores to de-normalized weights for CRP pool
            tokenWeights[i] = (_pendingScores[i] * totalWeight) / totalPendingScore;
        }

        tokenWeights[kacyIdx] = minimumWeight;

        if (!suspectRequest) {
            _lastScores = _pendingScores;
            delete _pendingScores;
            // adjust weights before new update
            crpPool.pokeWeights();
            crpPool.updateWeightsGradually(tokenWeights, block.number, block.number + weightUpdateBlockPeriod);
            return;
        }

        _pendingWeights = tokenWeights;
        _requestStatus = _SUSPEND;
        super._pause();
        emit StrategyPaused(msg.sender, "ERR_SUSPECT_REQUEST");
    }

    /**
     * @notice Starts a request for Heimdall data through API3
     *         Only the allowed updater can call it
     */
    function makeRequest()
        external
        override
        whenNotPaused
    {
        require(msg.sender == updaterRole, "ERR_NOT_UPDATER");
        require(_requestStatus == _NONE, "ERR_ONLY_ONE_REQUEST_AT_TIME");
        _requestStatus = _ONGOING;
        // GradualUpdateParams gradualUpdate = crpPool.gradualUpdate();
        // require(block.number + 1 > gradualUpdate.endBlock, "ERR_GRADUAL_STILL_ONGOING");
        bytes32 requestId = airnodeRrp.makeTemplateRequest(
            templateId,             // Address of the data provider
            sponsorAddress,         // Sponsor that allows this client to use the funds in the designated wallet
            sponsorWallet,          // The designated wallet the sponsor allowed this client to use
            address(this),          // address contacted when request finishes
            this.strategy.selector, // function in this contract called when request finishes
            ""                      // extra parameters, that we don't need
        );
        incomingFulfillments[requestId] = true;
    }

    /**
     * @notice Fullfill an API3 request and update the weights of the crpPool
     *
     * @dev Only Airnode itself can call this function
     *
     * @param requestId - Request ID, to ensure it's the request we sent
     * @param response - The response data from Heimdall
     */
    function strategy(
        bytes32 requestId,
        bytes calldata response
        )
        external
        override
        whenNotPaused
        onlyAirnodeRrp()
    {
        require(incomingFulfillments[requestId], "ERR_NO_SUCH_REQUEST_MADE");
        delete incomingFulfillments[requestId];

        _hasAPIData = true;
        _requestStatus = _NONE; // allow requests again

        uint24[] memory data = abi.decode(response, (uint24[]));

        for (uint i = 0; i < data.length - 1; i++) {
            _pendingScores[i] = data[i];
        }

        emit RequestCompleted(requestId);
    }

    /**
     * @notice The last social scores obtained from the previous call
     *
     * @return 16 numbers; anything above the number of tokens is ignored
     */
    function lastScores() external view returns(uint24[16] memory) {
        return _lastScores;
    }

    /**
     * @notice The pending suspect social score from a suspicious call, if any
     *
     * @return 16 numbers; anything above the number of tokens is ignored
     */
    function pendingScores() external view returns(uint24[16] memory) {
        return _pendingScores;
    }

    /**
     * @notice The list of tokens to be called from Heimdall
     *
     * @return A list of token symbols to be checked against Heimdall
     */
    function tokensSymbols() external view returns(string[] memory) {
        return _tokensListHeimdall;
    }

    /**
     * @dev Pauses the UpdateWeightsGradually and prevents API3 requests from being made
     */
    function _pause()
        override
        internal
    {
        // update weights to current block
        crpPool.pokeWeights();
        // get current weights
        IPool corePool = crpPool.corePool();
        address[] memory tokens = corePool.getCurrentTokens();
        uint[] memory weights = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            weights[i] = corePool.getDenormalizedWeight(tokens[i]);
        }

        // pause the gradual weights update
        crpPool.updateWeightsGradually(weights, block.number, block.number + _CHANGE_BLOCK_PERIOD);
        // block API3 requests
        super._pause();
    }

    /**
     * @dev Encode the symbol lists to save gas later when doing the API3 requests
     */
    function _encodeParameters()
        internal
    {
        bytes memory symbols;

        uint tokensLen = _tokensListHeimdall.length - 1;

        for (uint i = 0; i < tokensLen; i++) {
            symbols = abi.encodePacked(symbols, _tokensListHeimdall[i], ",");
        }

        symbols = abi.encodePacked(symbols, _tokensListHeimdall[tokensLen]);

        templateId = airnodeRrp.createTemplate(
            airnodeId,
            endpointId,
            abi.encode(
                bytes32("1sS"),
                bytes32("period"), bytes32("30d"),
                bytes32("symbols"), symbols
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is IOwnable {
    // owner of the contract
    address private _owner;

    /**
     * @notice Emitted when the owner is changed
     *
     * @param previousOwner - The previous owner of the contract
     * @param newOwner - The new owner of the contract
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     *
     * @dev external for gas optimization
     *
     * @param newOwner - Address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     *
     * @dev external for gas optimization
     *
     * @return address - of the owner (AKA controller)
     */
    function getController() external view override returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Ownable.sol interface
 *
 * @dev Other interfaces might inherit this one so it may be unnecessary to use it
 */
interface IOwnable {
    function getController() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./IOwnable.sol";
import "./IERC20.sol";

/**
 * @title CRPool definition interface
 *
 * @dev Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
 *      Removing circularity allows flattener tools to work, which enables Etherscan verification
 *      Only contains the definitions of the ConfigurableRigthsPool.sol contract and no parent classes
 */
interface IConfigurableRightsPoolDef {
    function updateWeight(address token, uint newWeight) external;
    function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external;
    function pokeWeights() external;
    function commitAddToken(address token, uint balance, uint denormalizedWeight) external;
    function applyAddToken() external;
    function removeToken(address token) external;
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;

    function corePool() external view returns(IPool);
}

/**
 * @title CRPool interface for external contracts
 *
 * @dev Joins the CRPool definition and the token and ownable interfaces
 */
interface IConfigurableRightsPool is IConfigurableRightsPoolDef, IOwnable, IERC20 {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMath.sol";

/**
 * @title Core pool definition
 *
 * @dev Only contains the definitions of the Pool.sol contract and no parent classes
 */
interface IPoolDef {
    function setSwapFee(uint swapFee) external;
    function setExitFee(uint exitFee) external;
    function setPublicSwap(bool publicSwap) external;
    function setExitFeeCollector(address feeCollector) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function rebind(address token, uint balance, uint denorm) external;

    function getExitFeeCollector() external view returns (address);
    function isPublicSwap() external view returns (bool);
    function isBound(address token) external view returns(bool);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getExitFee() external view returns (uint);
}

/**
 * @title Core pool interface for external contracts
 *
 * @dev Joins the Core pool definition and the Math abstract contract
 */
interface IPool is IPoolDef, IMath {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Interface for the pure math functions
 *
 * @dev IPool inherits this, so it's only needed if you only want to interact with the Math functions
 */
interface IMath {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint poolAmountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/* solhint-disable ordering */

/**
 * @title An ERC20 compatible token interface
 */
interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./IOwnable.sol";

/**
 * @title Core factory definition interface
 */
interface IFactoryDef {
    function kacyToken() external view returns (address);
    function minimumKacy() external view returns (uint);
}

/**
 * @title Core factory interface with `newPool` as `IPool`
 *
 * @dev If `newPool` must be called and an interface must be returned this interface does that
 */
interface IFactory is IFactoryDef, IOwnable {
    function newPool() external returns (IPool pool);
}

//SPDX-License-Identifier: GPL-3-or-later
pragma solidity ^0.8.0;

/**
 * @title The minimum a strategy needs
 */
interface IStrategy {
    function makeRequest() external;
    function strategy(bytes32 requestId, bytes calldata response) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @author Kassandra (from Balancer Labs)
 *
 * @title Put all the constants in one place
 */
library KassandraConstants {
    // State variables (must be constant in a library)

    /// "ONE" - all math is in the "realm" of 10 ** 18; where numeric 1 = 10 ** 18
    uint public constant ONE               = 10**18;

    /// Minimum denormalized weight one token can have
    uint public constant MIN_WEIGHT        = ONE / 10;
    /// Maximum denormalized weight one token can have
    uint public constant MAX_WEIGHT        = ONE * 50;
    /// Maximum denormalized weight the entire pool can have
    uint public constant MAX_TOTAL_WEIGHT  = ONE * 50;

    /// Minimum token balance inside the pool
    uint public constant MIN_BALANCE       = ONE / 10**6;
    // Maximum token balance inside the pool
    // uint public constant MAX_BALANCE       = ONE * 10**12;

    /// Minimum supply of pool tokens
    uint public constant MIN_POOL_SUPPLY   = ONE * 100;
    /// Maximum supply of pool tokens
    uint public constant MAX_POOL_SUPPLY   = ONE * 10**9;

    /// Default fee for exiting a pool
    uint public constant EXIT_FEE          = ONE * 3 / 100;
    /// Minimum swap fee possible
    uint public constant MIN_FEE           = ONE / 10**6;
    /// Maximum swap fee possible
    uint public constant MAX_FEE           = ONE / 10;

    /// Maximum ratio of the token balance that can be sent to the pool for a swap
    uint public constant MAX_IN_RATIO      = ONE / 2;
    /// Maximum ratio of the token balance that can be taken out of the pool for a swap
    uint public constant MAX_OUT_RATIO     = (ONE / 3) + 1 wei;

    /// Minimum amount of tokens in a pool
    uint public constant MIN_ASSET_LIMIT   = 2;
    /// Maximum amount of tokens in a pool
    uint public constant MAX_ASSET_LIMIT   = 16;

    /// Maximum representable number in uint256
    uint public constant MAX_UINT          = type(uint).max;

    // Core Pools
    /// Minimum token balance inside the core pool
    uint public constant MIN_CORE_BALANCE  = ONE / 10**12;

    // Core Num
    /// Minimum base for doing a power of operation
    uint public constant MIN_BPOW_BASE     = 1 wei;
    /// Maximum base for doing a power of operation
    uint public constant MAX_BPOW_BASE     = (2 * ONE) - 1 wei;
    /// Precision of the approximate power function with fractional exponents
    uint public constant BPOW_PRECISION    = ONE / 10**10;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IAirnodeRrp.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequester {
    IAirnodeRrp public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrp(_airnodeRrp);
        IAirnodeRrp(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAuthorizationUtils.sol";
import "./ITemplateUtils.sol";
import "./IWithdrawalUtils.sol";

interface IAirnodeRrp is IAuthorizationUtils, ITemplateUtils, IWithdrawalUtils {
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAuthorizationUtils {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITemplateUtils {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWithdrawalUtils {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}