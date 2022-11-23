// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

library NativeClaimer {
    struct State {
        uint256 _valueClaimed;
    }

    function claimed(NativeClaimer.State memory claimer_) internal pure returns (uint256) {
        return claimer_._valueClaimed;
    }

    function unclaimed(NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return msg.value - claimer_._valueClaimed;
    }

    function claim(NativeClaimer.State memory claimer_, uint256 value_) internal view {
        require(unclaimed(claimer_) >= value_, "NC: insufficient msg value");
        claimer_._valueClaimed += value_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

abstract contract NativeReceiver {
    receive() external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeClaimer} from "./NativeClaimer.sol";
import {TokenHelper} from "./TokenHelper.sol";

abstract contract NativeReturnMods {
    using NativeClaimer for NativeClaimer.State;

    modifier returnUnclaimedNative(NativeClaimer.State memory claimer_) {
        require(claimer_.claimed() == 0, "NR: claimer already in use");
        _;
        TokenHelper.transferFromThis(TokenHelper.NATIVE_TOKEN, msg.sender, claimer_.unclaimed());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Math} from "../../lib/Math.sol";

import {TokenCheck} from "../swap/Swap.sol";

library TokenChecker {
    function checkMin(TokenCheck calldata check_, uint256 amount_) internal pure returns (uint256) {
        orderMinMax(check_);
        limitMin(check_, amount_);
        return capByMax(check_, amount_);
    }

    function checkMinMax(TokenCheck calldata check_, uint256 amount_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
    }

    function checkMinMaxToken(TokenCheck calldata check_, uint256 amount_, address token_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
        limitToken(check_, token_);
    }

    function orderMinMax(TokenCheck calldata check_) private pure {
        require(check_.minAmount <= check_.maxAmount, "TC: unordered min/max amounts");
    }

    function limitMin(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ >= check_.minAmount, "TC: insufficient token amount");
    }

    function limitMax(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ <= check_.maxAmount, "TC: excessive token amount");
    }

    function limitToken(TokenCheck calldata check_, address token_) private pure {
        require(token_ == check_.token, "TC: wrong token address");
    }

    function capByMax(TokenCheck calldata check_, uint256 amount_) private pure returns (uint256) {
        return Math.min(amount_, check_.maxAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IERC20} from "../../lib/IERC20.sol";
import {IERC20Permit} from "../../lib/draft-IERC20Permit.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol";
import {Address} from "../../lib/Address.sol";
import {ECDSA} from "../../lib/ECDSA.sol";

import {NativeClaimer} from "./NativeClaimer.sol";

library TokenHelper {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using Address for address;
    using Address for address payable;
    using NativeClaimer for NativeClaimer.State;

    /**
     * @dev xSwap's native coin representation.
     */
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier whenNonZero(uint256 amount_) {
        if (amount_ == 0) {
            return;
        }
        _;
    }

    function isNative(address token_) internal pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    function balanceOf(
        address token_,
        address owner_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        if (isNative(token_)) {
            balance = _nativeBalanceOf(owner_, claimer_);
        } else {
            balance = IERC20(token_).balanceOf(owner_);
        }
    }

    function balanceOfThis(
        address token_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        balance = balanceOf(token_, _this(), claimer_);
    }

    function transferToThis(
        address token_,
        address from_,
        uint256 amount_,
        NativeClaimer.State memory claimer_
    ) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            // We cannot claim native coins of an arbitrary "from_" address
            // like we do with ERC-20 allowance. So the only way to use native
            // is to pass via "value" with the contract call. The "from_" address
            // does not participate in such a scenario. The only thing we can do
            // is to restrict caller to be "from_" address only.
            require(from_ == _sender(), "TH: native allows sender only");
            claimer_.claim(amount_);
        } else {
            IERC20(token_).safeTransferFrom(from_, _this(), amount_);
        }
    }

    function transferFromThis(address token_, address to_, uint256 amount_) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            _nativeTransferFromThis(to_, amount_);
        } else {
            IERC20(token_).safeTransfer(to_, amount_);
        }
    }

    function approveOfThis(
        address token_,
        address spender_,
        uint256 amount_
    ) internal whenNonZero(amount_) returns (uint256 sendValue) {
        if (isNative(token_)) {
            sendValue = amount_;
        } else {
            sendValue = 0;
            IERC20(token_).safeApprove(spender_, amount_);
        }
    }

    function revokeOfThis(address token_, address spender_) internal {
        if (!isNative(token_)) {
            IERC20(token_).safeApprove(spender_, 0);
        }
    }

    function _nativeBalanceOf(
        address owner_,
        NativeClaimer.State memory claimer_
    ) private view returns (uint256 balance) {
        if (owner_ == _sender()) {
            balance = claimer_.unclaimed();
        } else {
            balance = owner_.balance;
            if (owner_ == _this()) {
                balance -= claimer_.unclaimed();
            }
        }
    }

    function _nativeTransferFromThis(address to_, uint256 amount_) private whenNonZero(amount_) {
        payable(to_).sendValue(amount_);
    }

    function _this() private view returns (address) {
        return address(this);
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IDelegateDeployer {
    function predictDelegateDeploy(address account) external view returns (address);

    function deployDelegate(address account) external returns (address);

    function isDelegateDeployed(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {IDelegateDeployer} from "./IDelegateDeployer.sol";

interface IDelegateManager is IDelegateDeployer {
    function withdraw(address account, Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IInitializable {
    function initialized() external view returns (bool);

    function initializer() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializable, InitializableStorage {
    // prettier-ignore
    constructor(bytes32 initializerSlot_)
        InitializableStorage(initializerSlot_)
    {} // solhint-disable-line no-empty-blocks

    modifier whenInitialized() {
        _ensureInitialized();
        _;
    }

    modifier whenNotInitialized() {
        _ensureNotInitialized();
        _;
    }

    modifier init() {
        _ensureNotInitialized();
        _initializeWithSender();
        _;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer(), "IN: sender not initializer");
        _;
    }

    function initialized() public view returns (bool) {
        return initializer() != address(0);
    }

    function initializer() public view returns (address) {
        return _initializer();
    }

    function _ensureInitialized() internal view {
        require(initialized(), "IN: not initialized");
    }

    function _ensureNotInitialized() internal view {
        require(!initialized(), "IN: already initialized");
    }

    function _initializeWithSender() internal {
        _setInitializer(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

abstract contract InitializableStorage {
    bytes32 private immutable _initializerSlot;

    constructor(bytes32 initializerSlot_) {
        _initializerSlot = initializerSlot_;
    }

    function _initializerStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_initializerSlot);
    }

    function _initializer() internal view returns (address) {
        return _initializerStorage().value;
    }

    function _setInitializer(address initializer_) internal {
        _initializerStorage().value = initializer_;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IPausable} from "../../lib/IPausable.sol";

/**
 * @dev Contract logic responsible for xSwap protocol live control.
 */
interface ILifeControl is IPausable {
    /**
     * @dev Emitted when the termination is triggered by `account`.
     */
    event Terminated(address account);

    /**
     * @dev Pauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must not be in paused state
     */
    function pause() external;

    /**
     * @dev Unpauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function unpause() external;

    /**
     * @dev Terminates xSwap protocol.
     *
     * Puts xSwap protocol into the paused state with no further ability to unpause.
     * This action essentially stops protocol so is expected to be called in
     * extraordinary scenarios only.
     *
     * Requires contract to be put into the paused state prior the call.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function terminate() external;

    /**
     * @dev Returns whether protocol is terminated ot not.
     *
     * Terminated protocol is guaranteed to be in paused state forever.
     *
     * @return _ `true` if protocol is terminated, `false` otherwise.
     */
    function terminated() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

/**
 * @dev In-memory implementation of 'mapping(address => uint256)'.
 *
 * The implementation is based on two once-allocated arrays and has sequential lookups.
 * Thus the worst case complexity must be expected to be O(N). The best case is O(1) though,
 * the operations required depend on number of unique elements, when an element was inserted, etc.
 */
library AccountCounter {
    uint256 private constant _ACCOUNT_MIXIN = 0xacc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0;
    uint256 private constant _NULL_INDEX = type(uint256).max;

    struct State {
        uint256[] _accounts;
        uint256[] _counts;
        uint256 _size;
    }

    using AccountCounter for State;

    function create(uint256 maxSize_) internal pure returns (AccountCounter.State memory accountCounter) {
        accountCounter._accounts = new uint256[](maxSize_);
        accountCounter._counts = new uint256[](maxSize_);
    }

    function size(AccountCounter.State memory accountCounter_) internal pure returns (uint256) {
        return accountCounter_._size;
    }

    function indexOf(
        AccountCounter.State memory accountCounter_,
        address account_,
        bool insert_
    ) internal pure returns (uint256) {
        uint256 targetAccount = uint160(account_) ^ _ACCOUNT_MIXIN;
        for (uint256 i = 0; i < accountCounter_._accounts.length; i++) {
            uint256 iAccount = accountCounter_._accounts[i];
            if (iAccount == targetAccount) {
                return i;
            }
            if (iAccount == 0) {
                if (!insert_) {
                    return _NULL_INDEX;
                }
                accountCounter_._accounts[i] = targetAccount;
                accountCounter_._size = i + 1;
                return i;
            }
        }
        if (!insert_) {
            return _NULL_INDEX;
        }
        revert("AC: insufficient size");
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return indexOf(accountCounter_, account_, true);
    }

    function isNullIndex(uint256 index_) internal pure returns (bool) {
        return index_ == _NULL_INDEX;
    }

    function accountAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (address) {
        return address(uint160(accountCounter_._accounts[index_] ^ _ACCOUNT_MIXIN));
    }

    function get(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return getAt(accountCounter_, indexOf(accountCounter_, account_));
    }

    function getAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (uint256) {
        return accountCounter_._counts[index_];
    }

    function set(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure {
        setAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function setAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure {
        accountCounter_._counts[index_] = count_;
    }

    function add(
        AccountCounter.State memory accountCounter_,
        address account_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        return addAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function addAt(
        AccountCounter.State memory accountCounter_,
        uint256 index_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) + count_;
        setAt(accountCounter_, index_, newCount);
    }

    function sub(
        AccountCounter.State memory accountCounter_,
        address account_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        return subAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function subAt(
        AccountCounter.State memory accountCounter_,
        uint256 index_,
        uint256 count_
    ) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) - count_;
        setAt(accountCounter_, index_, newCount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IPermitResolver {
    /**
     * @dev Converts specified permit into allowance for the caller.
     */
    function resolvePermit(
        address token,
        address from,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, StealthSwap, SwapStep} from "./Swap.sol";

/**
 * @dev Correlation with EIP-2612 permit:
 *
 * > address token -> Permit.token
 * > address owner -> SwapStep.account
 * > address spender -> xSwap contract
 * > uint256 value -> Permit.amount
 * > uint256 deadline -> Permit.deadline
 * > uint8 v -> Permit.signature
 * > bytes32 r -> Permit.signature
 * > bytes32 s -> Permit.signature
 *
 * The Permit.resolver is address of a contract responsible
 * for applying permit ({IPermitResolver}-compatible)
 */
struct Permit {
    address resolver;
    address token;
    uint256 amount;
    uint256 deadline;
    bytes signature;
}

struct Call {
    address target;
    bytes data;
}

struct SwapParams {
    Swap swap;
    bytes swapSignature;
    uint256 stepIndex;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

struct StealthSwapParams {
    StealthSwap swap;
    bytes swapSignature;
    SwapStep step;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

interface ISwapper {
    function swap(SwapParams calldata params) external payable;

    function swapStealth(StealthSwapParams calldata params) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, SwapStep, StealthSwap} from "./Swap.sol";

interface ISwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap, bytes calldata swapSignature) external view;

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap,
        bytes calldata stealthSwapSignature
    ) external view returns (uint256 stepIndex);

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap
    ) external view returns (uint256 stepIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

struct TokenCheck {
    address token;
    uint256 minAmount;
    uint256 maxAmount;
}

struct TokenUse {
    address protocol;
    uint256 chain;
    address account;
    uint256[] inIndices;
    TokenCheck[] outs;
    bytes args; // Example of reserved value: 0x44796E616D6963 ("Dynamic")
}

struct SwapStep {
    uint256 chain;
    address swapper;
    address account;
    bool useDelegate;
    uint256 nonce;
    uint256 deadline;
    TokenCheck[] ins;
    TokenCheck[] outs;
    TokenUse[] uses;
}

struct Swap {
    SwapStep[] steps;
}

struct StealthSwap {
    uint256 chain;
    address swapper;
    address account;
    bytes32[] stepHashes;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Address} from "../../lib/Address.sol";
import {Math} from "../../lib/Math.sol";

import {NativeClaimer} from "../asset/NativeClaimer.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {NativeReturnMods} from "../asset/NativeReturnMods.sol";
import {TokenChecker} from "../asset/TokenChecker.sol";
import {TokenHelper} from "../asset/TokenHelper.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {AccountCounter} from "../misc/AccountCounter.sol";

import {IPermitResolver} from "../permit/IPermitResolver.sol";

import {IUseProtocol, UseParams} from "../use/IUseProtocol.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {ISwapper, SwapParams, StealthSwapParams, Permit, Call} from "./ISwapper.sol";
import {Swap, SwapStep, TokenUse, StealthSwap, TokenCheck} from "./Swap.sol";
import {SwapperStorage} from "./SwapperStorage.sol";

struct SwapperConstructorParams {
    /**
     * @dev {ISwapSignatureValidator}-compatible contract address
     */
    address swapSignatureValidator;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address permitResolverWhitelist;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address useProtocolWhitelist;
    /**
     * @dev {IDelegateManager}-compatible contract address
     */
    address delegateManager;
}

contract Swapper is ISwapper, NativeReceiver, NativeReturnMods, SwapperStorage {
    using AccountCounter for AccountCounter.State;

    constructor(SwapperConstructorParams memory params_) {
        _initialize(params_);
    }

    function initializeSwapper(SwapperConstructorParams memory params_) internal {
        _initialize(params_);
    }

    function _initialize(SwapperConstructorParams memory params_) private {
        require(params_.swapSignatureValidator != address(0), "SW: zero swap sign validator");
        _setSwapSignatureValidator(params_.swapSignatureValidator);

        require(params_.permitResolverWhitelist != address(0), "SW: zero permit resolver list");
        _setPermitResolverWhitelist(params_.permitResolverWhitelist);

        require(params_.useProtocolWhitelist != address(0), "SW: zero use protocol list");
        _setUseProtocolWhitelist(params_.useProtocolWhitelist);

        require(params_.delegateManager != address(0), "SW: zero delegate manager");
        _setDelegateManager(params_.delegateManager);
    }

    function swap(SwapParams calldata params_) external payable {
        _checkSwapEnabled();
        require(params_.stepIndex < params_.swap.steps.length, "SW: no step with provided index");
        SwapStep calldata step = params_.swap.steps[params_.stepIndex];
        _validateSwapSignature(params_.swap, params_.swapSignature, step);
        _performSwapStep(step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function swapStealth(StealthSwapParams calldata params_) external payable {
        _checkSwapEnabled();
        _validateStealthSwapSignature(params_.swap, params_.swapSignature, params_.step);
        _performSwapStep(params_.step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function _checkSwapEnabled() internal view virtual {
        return; // Nothing is hindering by default
    }

    function _validateSwapSignature(
        Swap calldata swap_,
        bytes calldata swapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(swapSignature_)) {
            _swapSignatureValidator().validateSwapSignature(swap_, swapSignature_);
        } else {
            _validateStepManualCaller(step_);
        }
    }

    function _validateStealthSwapSignature(
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(stealthSwapSignature_)) {
            _swapSignatureValidator().validateStealthSwapStepSignature(step_, stealthSwap_, stealthSwapSignature_);
        } else {
            _validateStepManualCaller(step_);
            _swapSignatureValidator().findStealthSwapStepIndex(step_, stealthSwap_); // Ensure presented
        }
    }

    function _isSignaturePresented(bytes calldata signature_) private pure returns (bool) {
        return signature_.length > 0;
    }

    function _validateStepManualCaller(SwapStep calldata step_) private view {
        require(msg.sender == step_.account, "SW: caller must be step account");
    }

    function _performSwapStep(
        SwapStep calldata step_,
        Permit[] calldata permits_,
        uint256[] calldata inAmounts_,
        Call calldata call_,
        bytes[] calldata useArgs_
    ) private {
        // solhint-disable-next-line not-rely-on-time
        require(step_.deadline > block.timestamp, "SW: swap step expired");
        require(step_.chain == block.chainid, "SW: wrong swap step chain");
        require(step_.swapper == address(this), "SW: wrong swap step swapper");
        require(step_.ins.length == inAmounts_.length, "SW: in amounts length mismatch");

        _useNonce(step_.account, step_.nonce);
        _usePermits(step_.account, permits_);

        uint256[] memory outAmounts = _performCall(
            step_.account,
            step_.useDelegate,
            step_.ins,
            inAmounts_,
            step_.outs,
            call_
        );
        _performUses(step_.uses, useArgs_, step_.outs, outAmounts);
    }

    function _useNonce(address account_, uint256 nonce_) private {
        require(!_nonceUsed(account_, nonce_), "SW: invalid nonce");
        _setNonceUsed(account_, nonce_, true);
    }

    function _usePermits(address account_, Permit[] calldata permits_) private {
        for (uint256 i = 0; i < permits_.length; i++) {
            _usePermit(account_, permits_[i]);
        }
    }

    function _usePermit(address account_, Permit calldata permit_) private {
        require(_permitResolverWhitelist().isAccountWhitelisted(permit_.resolver), "SW: permitter not whitelisted");
        IPermitResolver(permit_.resolver).resolvePermit(
            permit_.token,
            account_,
            permit_.amount,
            permit_.deadline,
            permit_.signature
        );
    }

    function _performCall(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_
    ) private returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        // prettier-ignore
        return _performCallWithReturn(
            account_,
            useDelegate_,
            ins_,
            inAmounts_,
            outs_,
            call_,
            nativeClaimer
        );
    }

    function _performCallWithReturn(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        // Ensure input amounts are within the min-max range
        for (uint256 i = 0; i < ins_.length; i++) {
            TokenChecker.checkMinMax(ins_[i], inAmounts_[i]);
        }

        // Calc input amounts to claim (per token)
        AccountCounter.State memory inAmountsByToken = AccountCounter.create(ins_.length);
        for (uint256 i = 0; i < ins_.length; i++) {
            inAmountsByToken.add(ins_[i].token, inAmounts_[i]);
        }

        // Claim inputs
        if (useDelegate_) {
            _claimAccountDelegateCallIns(account_, inAmountsByToken);
        } else {
            _claimAccountCallIns(account_, inAmountsByToken, nativeClaimer_);
        }

        // Snapshot output balances before call
        AccountCounter.State memory outBalances = AccountCounter.create(outs_.length);
        for (uint256 i = 0; i < outs_.length; i++) {
            address token = outs_[i].token;
            uint256 sizeBefore = outBalances.size();
            uint256 tokenIndex = outBalances.indexOf(token);
            if (sizeBefore != outBalances.size()) {
                outBalances.setAt(tokenIndex, TokenHelper.balanceOfThis(token, nativeClaimer_));
            }
        }
        uint256 totalOutTokens = outBalances.size();

        // Approve call assets
        uint256 sendValue = _approveAssets(inAmountsByToken, call_.target);

        // Do the call
        bytes memory result = Address.functionCallWithValue(call_.target, call_.data, sendValue);

        // Revoke call assets
        _revokeAssets(inAmountsByToken, call_.target);

        // Decrease output balances by (presumably) spent inputs
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 tokenInIndex = inAmountsByToken.indexOf(token, false);
            if (!AccountCounter.isNullIndex(tokenInIndex)) {
                uint256 inAmount = inAmountsByToken.getAt(tokenInIndex);
                outBalances.subAt(i, inAmount);
            }
        }

        // Replace balances before with remaining balances to "spend" on amount checks
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 balanceNow = TokenHelper.balanceOfThis(token, nativeClaimer_);
            outBalances.setAt(i, balanceNow - outBalances.getAt(i));
        }

        // Parse outputs from result
        outAmounts = abi.decode(result, (uint256[]));
        require(outAmounts.length == outs_.length, "SW: out amounts length mismatch");

        // Validate output amounts
        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = TokenChecker.checkMin(outs_[i], outAmounts[i]);
            outAmounts[i] = amount;
            uint256 tokenIndex = outBalances.indexOf(outs_[i].token, false);
            require(outBalances.getAt(tokenIndex) >= amount, "SW: insufficient out amount");
            outBalances.subAt(tokenIndex, amount);
        }
    }

    function _claimAccountDelegateCallIns(address account_, AccountCounter.State memory inAmountsByToken_) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        Withdraw[] memory withdraws = new Withdraw[](totalInTokens);
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            withdraws[i] = Withdraw({token: token, amount: amount, to: address(this)});
        }

        IDelegateManager delegateManager = _delegateManager();
        if (!delegateManager.isDelegateDeployed(account_)) {
            delegateManager.deployDelegate(account_);
        }
        delegateManager.withdraw(account_, withdraws);
    }

    function _claimAccountCallIns(
        address account_,
        AccountCounter.State memory inAmountsByToken_,
        NativeClaimer.State memory nativeClaimer_
    ) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            TokenHelper.transferToThis(token, account_, amount, nativeClaimer_);
        }
    }

    function _approveAssets(
        AccountCounter.State memory amountsByToken_,
        address spender_
    ) private returns (uint256 sendValue) {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            uint256 amount = amountsByToken_.getAt(i);
            sendValue += TokenHelper.approveOfThis(token, spender_, amount);
        }
    }

    function _revokeAssets(AccountCounter.State memory amountsByToken_, address spender_) private {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            TokenHelper.revokeOfThis(token, spender_);
        }
    }

    function _performUses(
        TokenUse[] calldata uses_,
        bytes[] calldata useArgs_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        uint256 dynamicArgsCursor = 0;
        for (uint256 i = 0; i < uses_.length; i++) {
            bytes calldata args = uses_[i].args;
            if (_shouldUseDynamicArgs(args)) {
                require(dynamicArgsCursor < useArgs_.length, "SW: not enough dynamic use args");
                args = useArgs_[dynamicArgsCursor];
                dynamicArgsCursor++;
            }
            _performUse(uses_[i], args, useIns_, useInAmounts_);
        }
        require(dynamicArgsCursor == useArgs_.length, "SW: too many dynamic use args");
    }

    function _shouldUseDynamicArgs(bytes calldata args_) private pure returns (bool) {
        if (args_.length != 7) {
            return false;
        }
        return bytes7(args_) == 0x44796E616D6963; // "Dynamic" in ASCII
    }

    function _performUse(
        TokenUse calldata use_,
        bytes calldata args_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        require(_useProtocolWhitelist().isAccountWhitelisted(use_.protocol), "SW: use protocol not whitelisted");

        TokenCheck[] memory ins = new TokenCheck[](use_.inIndices.length);
        uint256[] memory inAmounts = new uint256[](use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            uint256 inIndex = use_.inIndices[i];
            _ensureUseInputUnspent(useInAmounts_, inIndex);
            ins[i] = useIns_[inIndex];
            inAmounts[i] = useInAmounts_[inIndex];
            _spendUseInput(useInAmounts_, inIndex);
        }

        AccountCounter.State memory useInAmounts = AccountCounter.create(use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            useInAmounts.add(ins[i].token, inAmounts[i]);
        }

        uint256 sendValue = _approveAssets(useInAmounts, use_.protocol);
        IUseProtocol(use_.protocol).use{value: sendValue}(
            UseParams({
                chain: use_.chain,
                account: use_.account,
                ins: ins,
                inAmounts: inAmounts,
                outs: use_.outs,
                args: args_,
                msgSender: msg.sender,
                msgData: msg.data
            })
        );
        _revokeAssets(useInAmounts, use_.protocol);
    }

    uint256 private constant _SPENT_USE_INPUT = type(uint256).max;

    function _spendUseInput(uint256[] memory inAmounts_, uint256 index_) private pure {
        inAmounts_[index_] = _SPENT_USE_INPUT;
    }

    function _ensureUseInputUnspent(uint256[] memory inAmounts_, uint256 index_) private pure {
        require(inAmounts_[index_] != _SPENT_USE_INPUT, "SW: input already spent");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";

abstract contract SwapperStorage {
    // prettier-ignore
    // bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._swapSignatureValidator")) - 1);
    bytes32 private constant _SWAP_SIGNATURE_VALIDATOR_SLOT = 0x572889db8ac91f4b1f7f11b2b1ed6b16c6eeea367a78b3975c5d6ec0ae5187b4;

    function _swapSignatureValidatorStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_SWAP_SIGNATURE_VALIDATOR_SLOT);
    }

    function _swapSignatureValidator() internal view returns (ISwapSignatureValidator) {
        return ISwapSignatureValidator(_swapSignatureValidatorStorage().value);
    }

    function _setSwapSignatureValidator(address swapSignatureValidator_) internal {
        _swapSignatureValidatorStorage().value = swapSignatureValidator_;
    }

    // prettier-ignore
    // bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._permitResolverWhitelist")) - 1);
    bytes32 private constant _PERMIT_RESOLVER_WHITELIST_SLOT = 0x927ff1d8cfc45c529c885de54239c33280cdded1681dc287ec13e0c279fab4fd;

    function _permitResolverWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_PERMIT_RESOLVER_WHITELIST_SLOT);
    }

    function _permitResolverWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_permitResolverWhitelistStorage().value);
    }

    function _setPermitResolverWhitelist(address permitResolverWhitelist_) internal {
        _permitResolverWhitelistStorage().value = permitResolverWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._useProtocolWhitelist")) - 1);
    bytes32 private constant _USE_PROTOCOL_WHITELIST_SLOT = 0xd4123124af6bd6de635253002be397fccc55549d14ec64e12254e1dc473a8989;

    function _useProtocolWhitelistStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_USE_PROTOCOL_WHITELIST_SLOT);
    }

    function _useProtocolWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_useProtocolWhitelistStorage().value);
    }

    function _setUseProtocolWhitelist(address useProtocolWhitelist_) internal {
        _useProtocolWhitelistStorage().value = useProtocolWhitelist_;
    }

    // prettier-ignore
    // bytes32 private constant _DELEGATE_MANAGER_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._delegateManager")) - 1);
    bytes32 private constant _DELEGATE_MANAGER_SLOT = 0xb9ce0614dc8c6b0ba4f1c391d809ad23817a3153e0effd15d0c78e880ecdbbb2;

    function _delegateManagerStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_DELEGATE_MANAGER_SLOT);
    }

    function _delegateManager() internal view returns (IDelegateManager) {
        return IDelegateManager(_delegateManagerStorage().value);
    }

    function _setDelegateManager(address delegateManager_) internal {
        _delegateManagerStorage().value = delegateManager_;
    }

    // bytes32 private constant _NONCES_SLOT = bytes32(uint256(keccak256("xSwap.v2.Swapper._nonces")) - 1);
    bytes32 private constant _NONCES_SLOT = 0x791d4fc0c3c60e2f2f4fc8a10cb89d9841dbac52dccccc663ba39d8dccd7113e;

    function _nonceUsedStorage(
        address account_,
        uint256 nonce_
    ) private pure returns (StorageSlot.BooleanSlot storage) {
        bytes32 slot = _NONCES_SLOT ^ keccak256(abi.encode(nonce_, account_));
        return StorageSlot.getBooleanSlot(slot);
    }

    function _nonceUsed(address account_, uint256 nonce_) internal view returns (bool) {
        return _nonceUsedStorage(account_, nonce_).value;
    }

    function _setNonceUsed(address account_, uint256 nonce_, bool used_) internal {
        _nonceUsedStorage(account_, nonce_).value = used_;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {TokenCheck} from "../swap/Swap.sol";

struct UseParams {
    uint256 chain;
    address account;
    TokenCheck[] ins;
    uint256[] inAmounts;
    TokenCheck[] outs;
    bytes args;
    address msgSender;
    bytes msgData;
}

interface IUseProtocol {
    function use(UseParams calldata params) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IAccountWhitelist {
    event AccountAdded(address account);
    event AccountRemoved(address account);

    function getWhitelistedAccounts() external view returns (address[] memory);

    function isAccountWhitelisted(address account) external view returns (bool);

    function addAccountToWhitelist(address account) external;

    function removeAccountFromWhitelist(address account) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

interface IWithdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Withdrawable} from "./Withdrawable.sol";

import {WhitelistWithdrawableStorage} from "./WhitelistWithdrawableStorage.sol";

abstract contract WhitelistWithdrawable is Withdrawable, WhitelistWithdrawableStorage {
    constructor(
        bytes32 withdrawWhitelistSlot_,
        address withdrawWhitelist_
    ) WhitelistWithdrawableStorage(withdrawWhitelistSlot_) {
        _initialize(withdrawWhitelist_);
    }

    function initializeWhitelistWithdrawable(address withdrawWhitelist_) internal {
        _initialize(withdrawWhitelist_);
    }

    function _initialize(address withdrawWhitelist_) private {
        require(withdrawWhitelist_ != address(0), "WW: zero withdraw whitelist");
        _setWithdrawWhitelist(withdrawWhitelist_);
    }

    function _checkWithdraw() internal view override {
        _checkWithdrawerWhitelisted();
    }

    function _checkWithdrawerWhitelisted() private view {
        require(_withdrawWhitelist().isAccountWhitelisted(msg.sender), "WW: withdrawer not whitelisted");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {TokenHelper} from "../asset/TokenHelper.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdrawable} from "./Withdrawable.sol";

abstract contract WhitelistWithdrawableStorage {
    bytes32 private immutable _withdrawWhitelistSlot;

    constructor(bytes32 withdrawWhitelistSlot_) {
        _withdrawWhitelistSlot = withdrawWhitelistSlot_;
    }

    function _withdrawWhitelistStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_withdrawWhitelistSlot);
    }

    function _withdrawWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_withdrawWhitelistStorage().value);
    }

    function _setWithdrawWhitelist(address withdrawWhitelist_) internal {
        _withdrawWhitelistStorage().value = withdrawWhitelist_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../asset/TokenHelper.sol";

import {IWithdrawable, Withdraw} from "./IWithdrawable.sol";

abstract contract Withdrawable is IWithdrawable {
    function withdraw(Withdraw[] calldata withdraws_) external virtual {
        _checkWithdraw();

        for (uint256 i = 0; i < withdraws_.length; i++) {
            Withdraw calldata w = withdraws_[i];
            TokenHelper.transferFromThis(w.token, w.to, w.amount);
            emit Withdrawn(w.token, w.amount, w.to);
        }
    }

    function _checkWithdraw() internal view virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Address} implementation:
 * - bump `pragma solidity` (`^0.8.1` -> `^0.8.16`)
 * - shortify `require` messages (`Address:` -> `AD:` + others to avoid length warnings)
 * - disable some `solhint` rules for the file
 */

/* solhint-disable avoid-low-level-calls */

pragma solidity ^0.8.16;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(address(this).balance >= amount, "AD: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AD: unable to send value");
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
        return functionCallWithValue(target, data, 0, "AD: low-level call fail");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AD: low-level value call fail");
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
        require(address(this).balance >= value, "AD: not enough balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "AD: low-level static call fail");
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "AD: low-level delegate call fail");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "AD: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {IERC20Permit} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {ECDSA} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Strings} import (use `library` implementation)
 * - shortify `require` messages (`ECDSA:` -> `EC:`)
 * - extract `decompress(bytes32 vs)` private function from `tryRecover(bytes32 hash, bytes32 r, bytes32 vs)`
 * - extract `tryDecompose(bytes memory signature)` private function from `tryRecover(bytes32 hash, bytes memory signature)`
 */

pragma solidity ^0.8.16;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("EC: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("EC: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("EC: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("EC: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address signer, RecoverError err) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v, err) = tryDecompose(signature);
        if (err == RecoverError.NoError) {
            (signer, err) = tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes memory signature) for xSwap needs
     */
    function tryDecompose(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v, RecoverError err) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            (s, v) = decompress(vs);
        } else {
            err = RecoverError.InvalidSignatureLength;
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        (bytes32 s, uint8 v) = decompress(vs);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes32 r, bytes32 vs) for xSwap needs
     */
    function decompress(bytes32 vs) private pure returns (bytes32 s, uint8 v) {
        s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        v = uint8((uint256(vs) >> 255) + 27);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {IERC20} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @dev Public interface of OpenZeppelin's {Pausable}.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Math} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {SafeERC20} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {IERC20}, {IERC20Permit}, {Address} imports (use `library` implementation)
 * - shortify `require` messages (`SafeERC20:` -> `SE:` + others to avoid length warnings)
 */

pragma solidity ^0.8.16;

import {IERC20} from "./IERC20.sol";
import {IERC20Permit} from "./draft-IERC20Permit.sol";
import {Address} from "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SE: approve from non-0 to non-0");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SE: decreased allowance below 0");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SE: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SE: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SE: ERC20 operation failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {StorageSlot} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Strings} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Initializable} from "./core/init/Initializable.sol";

import {Swapper, SwapperConstructorParams} from "./core/swap/Swapper.sol";

import {WhitelistWithdrawable} from "./core/withdraw/WhitelistWithdrawable.sol";

import {XSwapStorage} from "./XSwapStorage.sol";

struct XSwapConstructorParams {
    /**
     * @dev {ISwapSignatureValidator}-compatible contract address
     */
    address swapSignatureValidator;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address permitResolverWhitelist;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address useProtocolWhitelist;
    /**
     * @dev {IDelegateManager}-compatible contract address
     */
    address delegateManager;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
    /**
     * @dev {ILifeControl}-compatible contract address
     */
    address lifeControl;
}

contract XSwap is Initializable, Swapper, WhitelistWithdrawable, XSwapStorage {
    // prettier-ignore
    constructor(XSwapConstructorParams memory params_)
        Initializable(INITIALIZER_SLOT)
        WhitelistWithdrawable(WITHDRAW_WHITELIST_SLOT, _whitelistWithdrawableParams(params_))
        Swapper(_swapperParams(params_))
    {
        _initialize(params_, false);
    }

    function initialize(XSwapConstructorParams memory params_) external {
        _initialize(params_, true);
    }

    function _initialize(XSwapConstructorParams memory params_, bool initBase_) private init {
        if (initBase_) {
            initializeSwapper(_swapperParams(params_));
            initializeWhitelistWithdrawable(_whitelistWithdrawableParams(params_));
        }

        require(params_.lifeControl != address(0), "XS: zero life control");
        _setLifeControl(params_.lifeControl);
    }

    function _swapperParams(
        XSwapConstructorParams memory params_
    ) private pure returns (SwapperConstructorParams memory) {
        // prettier-ignore
        return SwapperConstructorParams({
            swapSignatureValidator: params_.swapSignatureValidator,
            permitResolverWhitelist: params_.permitResolverWhitelist,
            useProtocolWhitelist: params_.useProtocolWhitelist,
            delegateManager: params_.delegateManager
        });
    }

    function _whitelistWithdrawableParams(XSwapConstructorParams memory params_) private pure returns (address) {
        return params_.withdrawWhitelist;
    }

    function _checkSwapEnabled() internal view override {
        require(!_lifeControl().paused(), "XS: swapping paused");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "./lib/StorageSlot.sol";

import {ILifeControl} from "./core/life/ILifeControl.sol";

abstract contract XSwapStorage {
    // bytes32 internal constant INITIALIZER_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._initializer")) - 1);
    bytes32 internal constant INITIALIZER_SLOT = 0x3623293b0ffb92d90ed57651d3642673495a0188d7e022c09c543c9969626c44;

    // prettier-ignore
    // bytes32 internal constant WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._withdrawWhitelist")) - 1);
    bytes32 internal constant WITHDRAW_WHITELIST_SLOT = 0x4bd3e4129f347789784c66e779a32160b856695506e147fcaa130ce576c4cb1b;

    // bytes32 internal constant _LIFE_CONTROL_SLOT = bytes32(uint256(keccak256("xSwap.v2.XSwap._lifeControl")) - 1);
    bytes32 private constant _LIFE_CONTROL_SLOT = 0x871cbad836638a5df48f5f4cd4da62b7497b7b8a763c0aa30ded7ca399e95121;

    function _lifeControlStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_LIFE_CONTROL_SLOT);
    }

    function _lifeControl() internal view returns (ILifeControl) {
        return ILifeControl(_lifeControlStorage().value);
    }

    function _setLifeControl(address lifeControl_) internal {
        _lifeControlStorage().value = lifeControl_;
    }
}