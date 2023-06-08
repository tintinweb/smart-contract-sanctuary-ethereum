// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./BaseTreasury.sol";
import "./interfaces/IMainTreasury.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/MerkleProof.sol";
import "./libraries/MiMC.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MainTreasury is IMainTreasury, BaseTreasury, Initializable {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public override verifier;

    uint64 public override zkpId;

    mapping(address => uint256) public override getBalanceRoot;
    mapping(address => uint256) public override getWithdrawRoot;
    mapping(address => uint256) public override getTotalBalance;
    mapping(address => uint256) public override getTotalWithdraw;
    mapping(address => uint256) public override getWithdrawn;

    mapping(address => bool) public override getWithdrawFinished;
    
    uint256 public override lastUpdateTime;
    uint256 public override forceTimeWindow;

    bool public override forceWithdrawOpened;

    struct WithdrawnInfo {
        mapping(uint256 => uint256) generalWithdrawnBitMap;
        mapping(uint256 => uint256) forceWithdrawnBitMap;
        uint256[] allGeneralWithdrawnIndex;
        uint256[] allForceWithdrawnIndex;
    }
    mapping(address => WithdrawnInfo) private getWithdrawnInfo;

    modifier onlyVerifierSet {
        require(verifier != address(0), "verifier not set");
        _;
    }

    function initialize(uint256 forceTimeWindow_) external initializer {
        owner = msg.sender;
        forceTimeWindow = forceTimeWindow_;
    }

    function setVerifier(address verifier_) external override onlyOwner {
        require(verifier == address(0), "verifier already set");
        verifier = verifier_;
        emit VerifierSet(verifier);
    }

    function updateZKP(
        uint64 newZkpId,
        address[] calldata tokens,
        uint256[] calldata newBalanceRoots,
        uint256[] calldata newWithdrawRoots,
        uint256[] calldata newTotalBalances,
        uint256[] calldata newTotalWithdraws
    ) external override onlyVerifierSet {
        require(msg.sender == verifier, "forbidden");
        require(!forceWithdrawOpened, "force withdraw opened");
        require(
            tokens.length == newBalanceRoots.length &&
            newBalanceRoots.length == newWithdrawRoots.length &&
            newWithdrawRoots.length == newTotalBalances.length &&
            newTotalBalances.length == newTotalWithdraws.length,
            "length not the same"
        );

        uint256 balanceOfThis;
        address token;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(getWithdrawFinished[token], "last withdraw not finish yet");
            getWithdrawFinished[token] = false;

            balanceOfThis = IERC20(token).balanceOf(address(this));
            require(balanceOfThis >= newTotalBalances[i] + newTotalWithdraws[i], "not enough balance");
            
            getBalanceRoot[token] = newBalanceRoots[i];
            getWithdrawRoot[token] = newWithdrawRoots[i];
            getTotalBalance[token] = newTotalBalances[i];
            getTotalWithdraw[token] = newTotalWithdraws[i];

            WithdrawnInfo storage withdrawnInfo = getWithdrawnInfo[token];
            // clear claimed records
            for (uint256 j = 0; j < withdrawnInfo.allGeneralWithdrawnIndex.length; j++) {
                delete withdrawnInfo.generalWithdrawnBitMap[withdrawnInfo.allGeneralWithdrawnIndex[j]];
            }
            delete withdrawnInfo.allGeneralWithdrawnIndex;
        }

        require(newZkpId > zkpId, "old zkp");
        zkpId = newZkpId;
        lastUpdateTime = block.timestamp;

        emit ZKPUpdated(newZkpId, tokens, newBalanceRoots, newWithdrawRoots, newTotalBalances, newTotalWithdraws);
    }

    function generalWithdraw(
        uint256[] calldata proof,
        uint256 index,
        uint256 withdrawId,
        uint256 accountId,
        address account,
        address to,
        address token,
        uint8 withdrawType,
        uint256 amount
    ) external override onlyVerifierSet {
        require(!isWithdrawn(token, index, true), "Drop already withdrawn");
        uint64 zkpId_ = zkpId;
        // Verify the merkle proof.
        uint256[] memory msgs = new uint256[](9);
        msgs[0] = zkpId_;
        msgs[1] = index;
        msgs[2] = withdrawId;
        msgs[3] = accountId;
        msgs[4] = uint256(uint160(account));
        msgs[5] = uint256(uint160(to));
        msgs[6] = uint256(uint160(token));
        msgs[7] = withdrawType;
        msgs[8] = amount;
        uint256 node = MiMC.Hash(msgs);
        require(MerkleProof.verify(proof, getWithdrawRoot[token], node), "Invalid proof");
        // Mark it withdrawn and send the token.
        _setWithdrawn(token, index, true);
        if (token == ETH) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }

        getWithdrawn[token] += amount;
        require(getWithdrawn[token] <= getTotalWithdraw[token], "over totalWithdraw");
        if (getWithdrawn[token] == getTotalWithdraw[token]) getWithdrawFinished[token] = true;

        emit GeneralWithdrawn(token, account, to, zkpId_, index, amount);
    }

    function forceWithdraw(
        uint256[] calldata proof,
        uint256 index,
        uint256 accountId,
        uint256 equity,
        address token
    ) external override onlyVerifierSet {
        require(block.timestamp > lastUpdateTime + forceTimeWindow, "not over forceTimeWindow");
        require(!isWithdrawn(token, index, false), "Drop already withdrawn");
        uint64 zkpId_ = zkpId;
        // Verify the merkle proof.
        uint256[] memory msgs = new uint256[](5);
        msgs[0] = index;
        msgs[1] = accountId;
        msgs[2] = uint256(uint160(msg.sender));
        msgs[3] = uint256(uint160(token));
        msgs[4] = equity;
        uint256 node = MiMC.Hash(msgs);
        require(MerkleProof.verify(proof, getBalanceRoot[token], node), "Invalid proof");
        // Mark it withdrawn and send the token.
        _setWithdrawn(token, index, false);
        if (token == ETH) {
            TransferHelper.safeTransferETH(msg.sender, equity);
        } else {
            TransferHelper.safeTransfer(token, msg.sender, equity);
        }

        if (!forceWithdrawOpened) forceWithdrawOpened = true;
        emit ForceWithdrawn(token, msg.sender, zkpId_, index, equity); 
    }

    function isWithdrawn(address token, uint256 index, bool isGeneral) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word;
        if (isGeneral) {
            word = getWithdrawnInfo[token].generalWithdrawnBitMap[wordIndex];
        } else {
            word = getWithdrawnInfo[token].forceWithdrawnBitMap[wordIndex];
        }
        uint256 mask = (1 << bitIndex);
        return word & mask == mask;
    }

    function _setWithdrawn(address token, uint256 index, bool isGeneral) internal {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        WithdrawnInfo storage withdrawnInfo = getWithdrawnInfo[token];
        if (isGeneral) {
            withdrawnInfo.generalWithdrawnBitMap[wordIndex] = withdrawnInfo.generalWithdrawnBitMap[wordIndex] | (1 << bitIndex);
            withdrawnInfo.allGeneralWithdrawnIndex.push(wordIndex);
        } else {
            withdrawnInfo.forceWithdrawnBitMap[wordIndex] = withdrawnInfo.forceWithdrawnBitMap[wordIndex] | (1 << bitIndex);
            withdrawnInfo.allForceWithdrawnIndex.push(wordIndex);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
                require(isContract(target), "Address: call to non-contract");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./libraries/TransferHelper.sol";
import "./Ownable.sol";

abstract contract BaseTreasury is ITreasury, Ownable {
    mapping(address => bool) public isOperator;

    modifier onlyOperator() {
        require(isOperator[msg.sender], "only operator");
        _;
    }

    receive() external payable {}

    function addOperator(address operator) external override onlyOwner {
        require(!isOperator[operator], "already added");
        isOperator[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external override onlyOwner {
        require(isOperator[operator], "operator not found");
        isOperator[operator] = false;
        emit OperatorRemoved(operator);
    }

    function depositETH() external payable override {
        require(msg.value > 0, "deposit amount is zero");
        emit EthDeposited(msg.sender, msg.value);
    }

    function depositToken(address token, uint256 amount) external override {
        require(token != address(0), "zero address");
        require(amount > 0, "deposit amount is zero");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        emit TokenDeposited(token, msg.sender, amount);
    }

    function withdrawETH(address recipient, uint256 amount, string calldata requestId) external override onlyOperator {
        _withdrawETH(recipient, amount, requestId);
    }

    function withdrawToken(address token, address recipient, uint256 amount, string calldata requestId) external override onlyOperator {
        _withdrawToken(token, recipient, amount, requestId);
    }

    function batchWithdrawETH(
        address[] calldata recipients, 
        uint256[] calldata amounts, 
        string[] calldata requestIds
    ) external override onlyOperator {
        require(
            recipients.length == amounts.length && 
            recipients.length == requestIds.length, "length not the same");
        for (uint256 i = 0; i < recipients.length; i++) {
            _withdrawETH(recipients[i], amounts[i], requestIds[i]);
        }
    }

    function batchWithdrawToken(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts,
        string[] calldata requestIds
    ) external override onlyOperator {
        require(
            tokens.length == recipients.length &&
            recipients.length == amounts.length && 
            recipients.length == requestIds.length, "length not the same");
        for (uint256 i = 0; i < recipients.length; i++) {
            _withdrawToken(tokens[i], recipients[i], amounts[i], requestIds[i]);
        }
    }

    function _withdrawETH(address recipient, uint256 amount, string calldata requestId) internal {
        require(recipient != address(0), "recipient is zero address");
        require(amount > 0, "zero amount");
        TransferHelper.safeTransferETH(recipient, amount);
        emit EthWithdrawn(msg.sender, recipient, amount, requestId);
    }

    function _withdrawToken(address token, address recipient, uint256 amount, string calldata requestId) internal {
        require(token != address(0), "token is zero address");
        require(recipient != address(0), "recipient is zero address");
        require(amount > 0, "zero amount");
        require(IERC20(token).balanceOf(address(this)) >= amount, "balance not enough");
        TransferHelper.safeTransfer(token, recipient, amount);
        emit TokenWithdrawn(token, msg.sender, recipient, amount, requestId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./ITreasury.sol";

interface IMainTreasury is ITreasury {
    event VerifierSet(address verifier);
    event ZKPUpdated(uint64 zkpId, address[] tokens, uint256[] balanceRoots, uint256[] withdrawRoots, uint256[] totalBalances, uint256[] totalWithdraws);
    event GeneralWithdrawn(address token, address indexed account, address indexed to, uint64 zkpId, uint256 index, uint256 amount);
    event ForceWithdrawn(address token, address indexed account, uint64 zkpId, uint256 index, uint256 amount);

    function ETH() external view returns (address);
    function verifier() external view returns (address);
    function zkpId() external view returns (uint64);
    function getBalanceRoot(address token) external view returns (uint256);
    function getWithdrawRoot(address token) external view returns (uint256);
    function getTotalBalance(address token) external view returns (uint256);
    function getTotalWithdraw(address token) external view returns (uint256);
    function getWithdrawn(address token) external view returns (uint256);
    function getWithdrawFinished(address token) external view returns (bool);
    function lastUpdateTime() external view returns (uint256);
    function forceTimeWindow() external view returns (uint256);
    function forceWithdrawOpened() external view returns (bool);

    function setVerifier(address verifier_) external;

    function updateZKP(
        uint64 newZkpId,
        address[] calldata tokens,
        uint256[] calldata newBalanceRoots,
        uint256[] calldata newWithdrawRoots,
        uint256[] calldata newTotalBalances,
        uint256[] calldata newTotalWithdraws
    ) external;

    function generalWithdraw(
        uint256[] calldata proof,
        uint256 index,
        uint256 withdrawId,
        uint256 accountId,
        address account,
        address to,
        address token,
        uint8 withdrawType,
        uint256 amount
    ) external;

    function forceWithdraw(
        uint256[] calldata proof,
        uint256 index,
        uint256 accountId,
        uint256 equity,
        address token
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface ITreasury {
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event EthDeposited(address indexed sender, uint256 amount);
    event TokenDeposited(address indexed token, address indexed sender, uint256 amount);
    event EthWithdrawn(address indexed operator, address indexed recipient, uint256 amount, string requestId);
    event TokenWithdrawn(address indexed token, address indexed operator, address indexed recipient, uint256 amount, string requestId);

    function isOperator(address) external view returns (bool);

    function addOperator(address operator) external;

    function removeOperator(address operator) external;

    function depositETH() external payable;

    function depositToken(address token, uint256 amount) external;

    function withdrawETH(address recipient, uint256 amount, string memory requestId) external;

    function withdrawToken(address token, address recipient, uint256 amount, string memory requestId) external;

    function batchWithdrawETH(address[] calldata recipients, uint256[] calldata amounts, string[] calldata requestIds) external;

    function batchWithdrawToken(address[] calldata tokens, address[] calldata recipients, uint256[] calldata amounts, string[] calldata requestIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./MiMC.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(uint256[] memory proof, uint256 root, uint256 leaf) internal pure returns (bool) {
        uint256 computedHash = leaf;
        uint256[] memory msgs = new uint256[](2);
        for (uint256 i = 0; i < proof.length; i++) {
            uint256 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                // computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
                msgs[0] = computedHash;
                msgs[1] = proofElement;
            } else {
                // Hash(current element of the proof + current computed hash)
                // computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                msgs[0] = proofElement;
                msgs[1] = computedHash;
            }
            computedHash = MiMC.Hash(msgs);
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
* Implements MiMC-p/p over the altBN scalar field used by zkSNARKs
*
* See: https://eprint.iacr.org/2016/492.pdf
*
* Round constants are generated in sequence from a seed
*/
library MiMC {
    function GetScalarField () internal pure returns (uint256) {
        return 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    }

    function Encipher( uint256 in_x, uint256 in_k ) internal pure returns(uint256 out_x) {
        return MiMCpe7( in_x, in_k, uint256(keccak256("mimc")), 91 );
    }

    /**
    * MiMC-p/p with exponent of 7
    * 
    * Recommended at least 46 rounds, for a polynomial degree of 2^126
    */
    function MiMCpe7( uint256 in_x, uint256 in_k, uint256 in_seed, uint256 round_count ) internal pure returns(uint256 out_x) {
        assembly {
            if lt(round_count, 1) { revert(0, 0) }

            // Initialise round constants, k will be hashed 
            let c := mload(0x40)
            mstore(0x40, add(c, 32))
            mstore(c, in_seed)

            let localQ := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            let t
            let a

            // Further n-2 subsequent rounds include a round constant
            for { let i := round_count } gt(i, 0) { i := sub(i, 1) } {
                // c = H(c)
                mstore(c, keccak256(c, 32))

                // x = pow(x + c_i, 7, p) + k
                t := addmod(addmod(in_x, mload(c), localQ), in_k, localQ)              // t = x + c_i + k
                a := mulmod(t, t, localQ)                                              // t^2
                in_x := mulmod(mulmod(a, a, localQ), t, localQ)     // t^5
            }

            // Result adds key again as blinding factor
            out_x := addmod(in_x, in_k, localQ)
        }
    }
       
    function MiMCpe7_mp( uint256[] memory in_x, uint256 in_k, uint256 in_seed, uint256 round_count ) internal pure returns (uint256) {
        uint256 r = in_k;
        uint256 localQ = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

        for( uint256 i = 0; i < in_x.length; i++ )
        {
            r = (r + in_x[i] + MiMCpe7(in_x[i], r, in_seed, round_count)) % localQ;
        }
        
        return r;
    }

    function Hash( uint256[] memory in_msgs, uint256 in_key ) internal pure returns (uint256) {
        return MiMCpe7_mp( in_msgs, in_key, uint256(keccak256("seed")), 91 );
    }

    function Hash( uint256[] memory in_msgs ) internal pure returns (uint256) {
        return Hash( in_msgs, 0 );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}