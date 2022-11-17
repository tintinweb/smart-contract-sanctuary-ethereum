//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";

contract Settings is OwnableUpgradeable {
    struct GovernorSetting {
        address governor;
        uint256 delayBlock;
        uint256 periodBlock;
    }
    /// @notice the shortest an auction can ever be
    address public weth;
    /// @notice the % bid increase required for a new bid
    uint256 public minBidIncrease;
    ///
    uint256 public auctionLength;
    ///
    uint256 public auctionExtendLength;
    ///
    uint256 public reduceStep;
    /// @notice the % of tokens required to be voting for an auction to start
    uint256 public minVotePercentage;
    /// @notice the max % increase over the initial
    uint256 public maxExitFactor;
    /// @notice the max % decrease from the initial
    uint256 public minExitFactor;
    /// @notice the address who receives auction fees
    address payable public feeReceiver;
    /// @notice fee
    uint256 public feePercentage;
    /// @notice exitFeeForCuratorPercentage
    uint256 public exitFeeForCuratorPercentage;
    /// @notice exitFeeForPlatformPercentage
    uint256 public exitFeeForPlatformPercentage;
    /// @notice exitFeeForPlatformPercentage
    uint256 public presaleFeePercentage;
    //
    uint256 public votingQuorumPercent;
    //
    uint256 public votingMinTokenPercent;
    //
    uint256 public votingDelayBlock;
    //
    uint256 public votingPeriodBlock;
    //
    uint256 public term1Duration;
    //
    uint256 public term2Duration;
    //
    uint256 public epochDuration;
    ///
    address public flashLoanAdmin;
    /// @notice logic for factory
    address public vaultImpl;
    address public vaultTpl;
    /// @notice logic for treasury
    address public treasuryImpl;
    address public treasuryTpl;
    /// @notice logic for staking
    address public stakingImpl;
    address public stakingTpl;
    /// @notice logic for gover
    address public governmentImpl;
    address public governmentTpl;
    /// @notice logic for exchange
    address public exchangeImpl;
    address public exchangeTpl;
    /// @notice logic for bnftImpl
    address public bnftImpl;
    address public bnftTpl;
    //
    string public bnftURI;
    /// @notice the address for reseve oracle price
    address public nftOracle;
    // map voting config
    mapping(address => GovernorSetting) public governorSettings;

    /// @notice for gap, minus 1 if use
    uint256[25] public __number;
    address[25] public __gapAddress;

    constructor() {}

    function initialize(address _weth) external initializer {
        __Ownable_init();
        // store data
        require(_weth != address(0), "no zero address");
        weth = _weth;
        auctionLength = 7 days;
        auctionExtendLength = 30 minutes;
        feeReceiver = payable(msg.sender);
        feePercentage = 8000; //80%
        minExitFactor = 2000; // 20%
        maxExitFactor = 50000; // 500%
        minBidIncrease = 100; // 1%
        minVotePercentage = 2500; // 25%
        reduceStep = 500; //5%
        exitFeeForCuratorPercentage = 125; //1.25%
        exitFeeForPlatformPercentage = 125; //1.25%
        presaleFeePercentage = 90;
        votingQuorumPercent = 5;
        votingMinTokenPercent = 100;
        votingDelayBlock = 14400; // 2 days
        votingPeriodBlock = 36000; // 5 days
        term1Duration = 26 * 7 * 1 days;
        term2Duration = 52 * 7 * 1 days;
        epochDuration = 1 days;
        flashLoanAdmin = msg.sender;
        bnftURI = "https://www.nftdaos.wtf/bnft/";
    }

    function getGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        address governor = address(0);
        address nftAddrs = address(0);
        uint256 delayBlock = votingDelayBlock;
        uint256 periodBlock = votingPeriodBlock;
        for (uint i = 0; i < nftAddrslist.length; i++) {
            GovernorSetting memory conf = governorSettings[nftAddrslist[i]];
            if (conf.delayBlock > 0) {
                delayBlock = conf.delayBlock;
            }
            if (conf.periodBlock > 0) {
                periodBlock = conf.periodBlock;
            }
            if (conf.governor != address(0)) {
                governor = conf.governor;
                nftAddrs = nftAddrslist[i];
                return (nftAddrs, governor, delayBlock, periodBlock);
            }
        }
        return (nftAddrs, governor, delayBlock, periodBlock);
    }

    function checkGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (bool)
    {
        if (nftAddrslist.length == 1) {
            return true;
        }
        for (uint i = 0; i < nftAddrslist.length - 1; i++) {
            // check if has 2 config
            GovernorSetting memory conf = governorSettings[nftAddrslist[i]];
            GovernorSetting memory confNext = governorSettings[
                nftAddrslist[i + 1]
            ];
            if (conf.governor != confNext.governor) {
                return false;
            }
        }
        return true;
    }

    event GovernorSettingSet(
        address nftAddr,
        address governor,
        uint256 delayBlock,
        uint256 periodBlock
    );

    function setGovernorSetting(
        address nftAddr,
        address governor,
        uint256 delayBlock,
        uint256 periodBlock
    ) external onlyOwner {
        GovernorSetting storage conf = governorSettings[nftAddr];
        conf.governor = governor;
        conf.delayBlock = delayBlock;
        conf.periodBlock = periodBlock;
        emit GovernorSettingSet(nftAddr, governor, delayBlock, periodBlock);
    }

    event PresaleFeePercentageSet(uint256 _presaleFeePercentage);

    function setPresaleFeePercentage(uint256 _presaleFeePercentage)
        external
        onlyOwner
    {
        require(_presaleFeePercentage <= 10000, "too high");
        presaleFeePercentage = _presaleFeePercentage;
        emit PresaleFeePercentageSet(_presaleFeePercentage);
    }

    event FeePercentageSet(uint256 _feePercentage);

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "too high");
        feePercentage = _feePercentage;
        emit FeePercentageSet(_feePercentage);
    }

    event ExitFeeForCuratorPercentageSet(uint256 _exitFeeForCuratorPercentage);

    function setExitFeeForCuratorPercentage(
        uint256 _exitFeeForCuratorPercentage
    ) external onlyOwner {
        require(_exitFeeForCuratorPercentage <= 5000, "too high");
        exitFeeForCuratorPercentage = _exitFeeForCuratorPercentage;
        emit ExitFeeForCuratorPercentageSet(_exitFeeForCuratorPercentage);
    }

    event ExitFeeForPlatformPercentageSet(
        uint256 _exitFeeForPlatformPercentage
    );

    function setExitFeeForPlatformPercentage(
        uint256 _exitFeeForPlatformPercentage
    ) external onlyOwner {
        require(_exitFeeForPlatformPercentage <= 5000, "too high");
        exitFeeForPlatformPercentage = _exitFeeForPlatformPercentage;
        emit ExitFeeForPlatformPercentageSet(_exitFeeForPlatformPercentage);
    }

    event ReduceStepSet(uint256 _reduceStep);

    function setReduceStep(uint256 _reduceStep) external onlyOwner {
        require(reduceStep <= 10000, "too high");
        reduceStep = _reduceStep;
        emit ReduceStepSet(_reduceStep);
    }

    event AuctionLengthSet(uint256 _auctionLength);

    function setAuctionLength(uint256 _auctionLength) external onlyOwner {
        auctionLength = _auctionLength;
        emit AuctionLengthSet(_auctionLength);
    }

    event AuctionExtendLengthSet(uint256 _auctionExtendLength);

    function setAuctionExtendLength(uint256 _auctionExtendLength)
        external
        onlyOwner
    {
        auctionExtendLength = _auctionExtendLength;
        emit AuctionExtendLengthSet(_auctionExtendLength);
    }

    event MinBidIncreaseSet(uint256 _min);

    function setMinBidIncrease(uint256 _min) external onlyOwner {
        require(_min <= 10000, "min bid increase too high");
        require(_min >= 10, "min bid increase too low");
        minBidIncrease = _min;
        emit MinBidIncreaseSet(_min);
    }

    event MinVotePercentageSet(uint256 _min);

    function setMinVotePercentage(uint256 _min) external onlyOwner {
        require(_min <= 10000, "min vote percentage too high");
        minVotePercentage = _min;
        emit MinVotePercentageSet(_min);
    }

    event MaxExitFactorSet(uint256 _factor);

    function setMaxExitFactor(uint256 _factor) external onlyOwner {
        require(_factor > minExitFactor, "max exit factor too low");
        maxExitFactor = _factor;
        emit MaxExitFactorSet(_factor);
    }

    event MinExitFactorSet(uint256 _factor);

    function setMinExitFactor(uint256 _factor) external onlyOwner {
        require(_factor < maxExitFactor, "min exit factor too high");
        minExitFactor = _factor;
        emit MinExitFactorSet(_factor);
    }

    event FeeReceiverSet(address payable _receiver);

    function setFeeReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");
        feeReceiver = _receiver;
        emit FeeReceiverSet(_receiver);
    }

    event VotingQuorumPercentSet(uint256 _votingQuorumPercent);

    function setVotingQuorumPercent(uint256 _votingQuorumPercent)
        external
        onlyOwner
    {
        votingQuorumPercent = _votingQuorumPercent;
        emit VotingQuorumPercentSet(_votingQuorumPercent);
    }

    event VotingMinTokenPercentSet(uint256 _votingMinTokenPercent);

    function setVotingMinTokenPercent(uint256 _votingMinTokenPercent)
        external
        onlyOwner
    {
        votingMinTokenPercent = _votingMinTokenPercent;
        emit VotingMinTokenPercentSet(_votingMinTokenPercent);
    }

    event VotingDelayBlockSet(uint256 _votingDelayBlock);

    function setVotingDelayBlock(uint256 _votingDelayBlock) external onlyOwner {
        votingDelayBlock = _votingDelayBlock;
        emit VotingDelayBlockSet(_votingDelayBlock);
    }

    event VotingPeriodBlockSet(uint256 _votingPeriodBlock);

    function setVotingPeriodBlock(uint256 _votingPeriodBlock)
        external
        onlyOwner
    {
        votingPeriodBlock = _votingPeriodBlock;
        emit VotingPeriodBlockSet(_votingPeriodBlock);
    }

    event Term1DurationSet(uint256 _term1Duration);

    function setTerm1Duration(uint256 _term1Duration) external onlyOwner {
        term1Duration = _term1Duration;
        emit Term1DurationSet(_term1Duration);
    }

    event Term2DurationSet(uint256 _term2Duration);

    function setTerm2Duration(uint256 _term2Duration) external onlyOwner {
        term2Duration = _term2Duration;
        emit Term1DurationSet(_term2Duration);
    }

    event EpochDurationSet(uint256 _epochDuration);

    function setEpochDuration(uint256 _epochDuration) external onlyOwner {
        epochDuration = _epochDuration;
        emit EpochDurationSet(_epochDuration);
    }

    event FlashLoanAdminSet(address _flashLoanAdmin);

    function setFlashLoanAdmin(address _flashLoanAdmin) external onlyOwner {
        require(_flashLoanAdmin != address(0), "cannot go to 0 address");
        flashLoanAdmin = _flashLoanAdmin;
        emit FlashLoanAdminSet(_flashLoanAdmin);
    }

    event VaultImplSet(address _vaultImpl);

    function setVaultImpl(address _vaultImpl) external onlyOwner {
        require(_vaultImpl != address(0), "cannot go to 0 address");
        vaultImpl = _vaultImpl;
        emit VaultImplSet(_vaultImpl);
    }

    function setStakingImpl(address _stakingImpl) external onlyOwner {
        require(_stakingImpl != address(0), "cannot go to 0 address");
        stakingImpl = _stakingImpl;
    }

    event TreasuryImplSet(address _treasuryImpl);

    function setTreasuryImpl(address _treasuryImpl) external onlyOwner {
        require(_treasuryImpl != address(0), "cannot go to 0 address");
        treasuryImpl = _treasuryImpl;
        emit TreasuryImplSet(_treasuryImpl);
    }

    event GovernmentImplSet(address _governmentImpl);

    function setGovernmentImpl(address _governmentImpl) external onlyOwner {
        require(_governmentImpl != address(0), "cannot go to 0 address");
        governmentImpl = _governmentImpl;
        emit GovernmentImplSet(_governmentImpl);
    }

    event ExchangeImplSet(address _exchangeImpl);

    function setExchangeImpl(address _exchangeImpl) external onlyOwner {
        require(_exchangeImpl != address(0), "cannot go to 0 address");
        exchangeImpl = _exchangeImpl;
        emit ExchangeImplSet(_exchangeImpl);
    }

    event BnftImplSet(address _bnftImpl);

    function setBnftImpl(address _bnftImpl) external onlyOwner {
        require(_bnftImpl != address(0), "cannot go to 0 address");
        bnftImpl = _bnftImpl;
        emit BnftImplSet(_bnftImpl);
    }

    event VaultTplSet(address _vaultTpl);

    function setVaultTpl(address _vaultTpl) external onlyOwner {
        require(_vaultTpl != address(0), "cannot go to 0 address");
        vaultTpl = _vaultTpl;
        emit VaultTplSet(_vaultTpl);
    }

    function setStakingTpl(address _stakingTpl) external onlyOwner {
        require(_stakingTpl != address(0), "cannot go to 0 address");
        stakingTpl = _stakingTpl;
    }

    event TreasuryTplSet(address _treasuryTpl);

    function setTreasuryTpl(address _treasuryTpl) external onlyOwner {
        require(_treasuryTpl != address(0), "cannot go to 0 address");
        treasuryTpl = _treasuryTpl;
        emit TreasuryTplSet(_treasuryTpl);
    }

    event GovernmentTplSet(address _governmentTpl);

    function setGovernmentTpl(address _governmentTpl) external onlyOwner {
        require(_governmentTpl != address(0), "cannot go to 0 address");
        governmentTpl = _governmentTpl;
        emit GovernmentTplSet(_governmentTpl);
    }

    event ExchangeTplSet(address _exchangeTpl);

    function setExchangeTpl(address _exchangeTpl) external onlyOwner {
        require(_exchangeTpl != address(0), "cannot go to 0 address");
        exchangeTpl = _exchangeTpl;
        emit ExchangeTplSet(_exchangeTpl);
    }

    event BnftTplSet(address _bnftTpl);

    function setBnftTpl(address _bnftTpl) external onlyOwner {
        require(_bnftTpl != address(0), "cannot go to 0 address");
        bnftTpl = _bnftTpl;
        emit BnftTplSet(_bnftTpl);
    }

    event BnftURISet(string _bnftURI);

    function setBnftURI(string memory _bnftURI) external onlyOwner {
        bnftURI = _bnftURI;
        emit BnftURISet(_bnftURI);
    }

    event NftOracleSet(address _nftOracle);

    function setNftOracle(address _nftOracle) external onlyOwner {
        require(_nftOracle != address(0), "cannot go to 0 address");
        nftOracle = _nftOracle;
        emit NftOracleSet(_nftOracle);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}