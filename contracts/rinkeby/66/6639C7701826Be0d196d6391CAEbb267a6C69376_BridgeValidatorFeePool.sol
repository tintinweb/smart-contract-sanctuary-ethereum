// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignerOwnable.sol";
import "./Bridge.sol";
import "./Globals.sol";

contract BridgeValidatorFeePool is Initializable, SignerOwnable {
    Bridge public bridge;

    mapping(address => uint256) public limitPerToken;

    address public validatorFeeReceiver;

    event ValidatorFeeReceiverUpdated(address validatorFeeReceiver);
    event LimitPerTokenUpdated(address token, uint256 limit);
    event BridgeUpdated(address bridge);
    event Collected(address token, uint256 amount);

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        address _signerStorage,
        address _bridge,
        address _validatorFeeReceiver
    ) external initializer {
        _setSignerStorage(_signerStorage);
        setBridge(_bridge);
        setValidatorFeeReceiver(_validatorFeeReceiver);
    }

    function setValidatorFeeReceiver(address _validatorFeeReceiver) public onlySigner {
        validatorFeeReceiver = _validatorFeeReceiver;
        emit ValidatorFeeReceiverUpdated(_validatorFeeReceiver);
    }

    function setLimitPerToken(address _token, uint256 _limit) public onlySigner {
        limitPerToken[_token] = _limit;
        emit LimitPerTokenUpdated(_token, _limit);
    }

    function setBridge(address _bridge) public onlySigner {
        bridge = Bridge(_bridge);
        emit BridgeUpdated(_bridge);
    }

    function collect(address _token) public {
        require(limitPerToken[_token] > 0, "BridgeValidatorFeePool: no limit for this token");

        uint256 balanceAmount;

        if (_token == NATIVE_TOKEN) {
            balanceAmount = address(this).balance;

            require(limitPerToken[_token] < balanceAmount, "BridgeValidatorFeePool: insufficient funds");
            bridge.depositNative{value: balanceAmount}(block.chainid, validatorFeeReceiver);
        } else {
            balanceAmount = IERC20(_token).balanceOf(address(this));

            require(limitPerToken[_token] < balanceAmount, "BridgeValidatorFeePool: insufficient funds");

            IERC20(_token).approve(address(bridge), balanceAmount);

            bridge.deposit(_token, block.chainid, validatorFeeReceiver, balanceAmount);
        }

        emit Collected(_token, balanceAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignerStorage.sol";

abstract contract SignerOwnable {
    SignerStorage public signerStorage;

    modifier onlySigner() {
        require(signerStorage.getAddress() == msg.sender, "SignerOwnable: only signer");
        _;
    }

    function _setSignerStorage(address _signerStorage) internal virtual {
        signerStorage = SignerStorage(_signerStorage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignerOwnable.sol";
import "./TokenManager.sol";
import "./LiquidityPools.sol";
import "./FeeManager.sol";
import "./Globals.sol";
import "../interfaces/IERC20MintableBurnable.sol";
import "./RelayBridge.sol";
import "../interfaces/IBridgeApp.sol";

contract Bridge is Initializable, SignerOwnable, IBridgeApp {
    mapping(bytes32 => bool) public executed;

    address public bridgeAppAddress;

    TokenManager public tokenManager;
    LiquidityPools public liquidityPools;
    FeeManager public feeManager;
    RelayBridge public relayBridge;

    event Deposited(
        address sender,
        address token,
        address destinationToken,
        uint256 destinationChainId,
        address receiver,
        uint256 fee,
        uint256 transferAmount
    );
    event DepositedNative(
        address sender,
        address token,
        uint256 destinationChainId,
        address receiver,
        uint256 fee,
        uint256 transferAmount
    );
    event Transferred(address sender, address token, uint256 sourceChainId, address receiver, uint256 amount);
    event TokenManagerUpdated(address _tokenManager);
    event ValidatorAddressUpdated(address _validatorAddress);
    event LiquidityPoolsUpdated(address _liquidityPools);
    event FeeManagerUpdated(address _feeManager);
    event Reverted(address sender, address token, uint256 sourceChainId, address receiver, uint256 amount);

    modifier onlyRelayBridge() {
        require(msg.sender == address(relayBridge), "Bridge: only RelayBridge");
        _;
    }

    function initialize(
        address _relayBridgeAddress,
        address _signerStorage,
        address _tokenManager,
        address payable _liquidityPools,
        address payable _feeManager,
        address _bridgeAppAddress
    ) external initializer {
        _setSignerStorage(_signerStorage);
        setTokenManager(_tokenManager);
        setLiquidityPools(_liquidityPools);
        setFeeManager(_feeManager);
        relayBridge = RelayBridge(_relayBridgeAddress);
        bridgeAppAddress = _bridgeAppAddress;
    }

    function deposit(
        address _token,
        uint256 _chainId,
        address _receiver,
        uint256 _amount
    ) external {
        require(_amount != 0, "Bridge: amount cannot be equal to 0.");
        require(tokenManager.isTokenEnabled(_token), "TokenManager: token is not enabled");

        uint256 fee = feeManager.calculateFee(_token, _amount);
        require(IERC20(_token).transferFrom(msg.sender, address(feeManager), fee), "IERC20: transfer failed");

        uint256 transferAmount = _amount - fee;

        if (tokenManager.isTokenMintable(_token)) {
            IERC20MintableBurnable(_token).burnFrom(msg.sender, transferAmount);
        } else {
            require(
                IERC20(_token).transferFrom(msg.sender, address(liquidityPools), transferAmount),
                "IERC20: transfer failed"
            );
        }

        address destinationToken = tokenManager.getDestinationToken(_token, _chainId);

        emit Deposited(msg.sender, _token, destinationToken, _chainId, _receiver, fee, transferAmount);

        bytes memory data = abi.encode(msg.sender, _token, _chainId, _receiver, transferAmount);

        // solhint-disable-next-line check-send-result
        relayBridge.send(_chainId, block.gaslimit, data);
    }

    function execute(uint256, bytes memory data) external onlyRelayBridge {
        (address _sender, address _token, uint256 _chainId, address _receiver, uint256 transferAmount) = abi.decode(
            data,
            (address, address, uint256, address, uint256)
        );

        address destinationToken = tokenManager.getDestinationToken(_token, _chainId);

        _executeTransfer(_sender, data, destinationToken, _chainId, _receiver, transferAmount);
    }

    function revertSend(uint256, bytes memory data) external onlyRelayBridge {
        (address _sender, address _token, uint256 _chainId, address _receiver, uint256 _amount) = abi.decode(
            data,
            (address, address, uint256, address, uint256)
        );

        require(tokenManager.isTokenEnabled(_token), "TokenManager: token is not enabled");

        if (tokenManager.isTokenMintable(_token)) {
            IERC20MintableBurnable(_token).mint(_sender, _amount);
        } else if (_token == NATIVE_TOKEN) {
            liquidityPools.transferNative(_sender, _amount);
        } else {
            liquidityPools.transfer(_token, _sender, _amount);
        }

        emit Reverted(_sender, _token, _chainId, _receiver, _amount);
    }

    function setTokenManager(address _tokenManager) public onlySigner {
        tokenManager = TokenManager(_tokenManager);
        emit TokenManagerUpdated(_tokenManager);
    }

    function setLiquidityPools(address payable _liquidityPools) public onlySigner {
        liquidityPools = LiquidityPools(_liquidityPools);
        emit LiquidityPoolsUpdated(_liquidityPools);
    }

    function setFeeManager(address payable _feeManager) public onlySigner {
        feeManager = FeeManager(_feeManager);
        emit FeeManagerUpdated(_feeManager);
    }

    function depositNative(uint256 _chainId, address _receiver) public payable {
        uint256 _amount = msg.value;
        require(_amount != 0, "Bridge: amount cannot be equal to 0.");
        require(tokenManager.isTokenEnabled(NATIVE_TOKEN), "TokenManager: token is not enabled");

        uint256 fee = feeManager.calculateFee(NATIVE_TOKEN, _amount);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(feeManager).call{value: fee, gas: 21000}("");
        require(success, "Bridge: transfer native token failed");

        uint256 transferAmount = _amount - fee;

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = address(liquidityPools).call{value: transferAmount, gas: 21000}("");
        require(success, "Bridge: transfer native token failed");

        emit DepositedNative(msg.sender, NATIVE_TOKEN, _chainId, _receiver, fee, transferAmount);

        bytes memory data = abi.encode(msg.sender, NATIVE_TOKEN, _chainId, _receiver, transferAmount);

        // solhint-disable-next-line check-send-result
        relayBridge.send(_chainId, block.gaslimit, data);
    }

    function isExecuted(
        address _sender,
        bytes calldata _txHash,
        address _token,
        address _receiver,
        uint256 _amount
    ) public view returns (bool) {
        bytes32 id = keccak256(abi.encodePacked(_sender, _txHash, _token, _receiver, _amount));
        return executed[id];
    }

    function _executeTransfer(
        address _sender,
        bytes memory _txHash,
        address _token,
        uint256 _sourceChainId,
        address _receiver,
        uint256 _amount
    ) private {
        require(tokenManager.isTokenEnabled(_token), "TokenManager: token is not enabled");
        bytes32 id = keccak256(abi.encodePacked(_sender, _txHash, _token, _receiver, _amount));

        executed[id] = true;

        if (tokenManager.isTokenMintable(_token)) {
            IERC20MintableBurnable(_token).mint(_receiver, _amount);
        } else if (_token == NATIVE_TOKEN) {
            liquidityPools.transferNative(_receiver, _amount);
        } else {
            liquidityPools.transfer(_token, _receiver, _amount);
        }

        emit Transferred(_sender, _token, _sourceChainId, _receiver, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant BASE_DIVISOR = 1 ether;
address constant NATIVE_TOKEN = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SignerStorage is Initializable {
    address public signer;

    event SignerUpdated(address _signer);

    function initialize(address _signer) external initializer {
        signer = _signer;
    }

    function setAddress(address _newSigner) public payable {
        require(signer == msg.sender, "SignerStorage: only signer");
        signer = _newSigner;

        uint256 _value = msg.value;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _newSigner.call{value: _value, gas: 21000}("");
        require(success, "SignerStorage: transfer value failed");

        emit SignerUpdated(_newSigner);
    }

    function getAddress() public view returns (address) {
        return signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SignerOwnable.sol";

contract TokenManager is Initializable, SignerOwnable {
    struct TokenInfo {
        mapping(uint256 => address) chainToToken;
        bool isEnabled;
        bool isMintable;
    }

    mapping(address => TokenInfo) public supportedTokens;

    function initialize(address _signerStorage) external initializer {
        _setSignerStorage(_signerStorage);
    }

    function setDestinationToken(
        uint256 _chainId,
        address _token,
        address _destinationToken
    ) external onlySigner {
        supportedTokens[_token].chainToToken[_chainId] = _destinationToken;
    }

    function setMintable(address _token, bool _isMintable) public {
        supportedTokens[_token].isMintable = _isMintable;
    }

    function setEnabled(address _token, bool _isEnabled) public {
        supportedTokens[_token].isEnabled = _isEnabled;
    }

    function isTokenEnabled(address _token) public view returns (bool) {
        return supportedTokens[_token].isEnabled;
    }

    function isTokenMintable(address _token) public view returns (bool) {
        return supportedTokens[_token].isMintable;
    }

    function getDestinationToken(address _token, uint256 _chainId) public view returns (address) {
        return supportedTokens[_token].chainToToken[_chainId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SignerOwnable.sol";
import "./TokenManager.sol";
import "./Bridge.sol";
import "./FeeManager.sol";
import "./Globals.sol";

contract LiquidityPools is Initializable, SignerOwnable {
    struct LiquidityPosition {
        uint256 balance;
        uint256 lastRewardPoints;
    }

    TokenManager public tokenManager;
    Bridge public bridge;
    FeeManager public feeManager;

    uint256 public feePercentage;

    mapping(address => uint256) public providedLiquidity;
    mapping(address => uint256) public availableLiquidity;
    mapping(address => mapping(address => LiquidityPosition)) public liquidityPositions;
    mapping(address => uint256) public collectedFees;
    mapping(address => uint256) public totalRewardPoints;

    event TokenManagerUpdated(address tokenManager);
    event BridgeUpdated(address bridge);
    event FeeManagerUpdated(address feeManager);
    event FeePercentageUpdated(uint256 feePercentage);

    event LiquidityAdded(address token, address account, uint256 amount);
    event LiquidityRemoved(address token, address account, uint256 amount);

    modifier onlyBridge() {
        require(msg.sender == address(bridge), "LiquidityPools: only bridge");
        _;
    }

    modifier onlyFeeManager() {
        require(msg.sender == address(feeManager), "LiquidityPools: only feeManager");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        address _signerStorage,
        address _tokenManager,
        address _bridge,
        address payable _feeManager,
        uint256 _feePercentage
    ) external initializer {
        _setSignerStorage(_signerStorage);
        setTokenManager(_tokenManager);
        setBridge(_bridge);
        setFeeManager(_feeManager);
        setFeePercentage(_feePercentage);
    }

    function transfer(
        address _token,
        address _receiver,
        uint256 _transferAmount
    ) external onlyBridge {
        require(
            IERC20(_token).balanceOf(address(this)) >= _transferAmount,
            "IERC20: amount more than contract balance"
        );
        require(ERC20(_token).transfer(_receiver, _transferAmount), "ERC20: transfer failed");
    }

    function transferNative(address _receiver, uint256 _amount) external onlyBridge {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _receiver.call{value: _amount, gas: 21000}("");
        require(success, "LiquidityPools: transfer native token failed");
    }

    function distributeFee(address _token, uint256 _amount) external onlyFeeManager {
        require(_amount > 0, "LiquidityPools: amount must be greater than zero");
        totalRewardPoints[_token] += (_amount * BASE_DIVISOR) / providedLiquidity[_token];
        providedLiquidity[_token] += _amount;
        collectedFees[_token] += _amount;
        availableLiquidity[_token] += _amount;
    }

    function setTokenManager(address _tokenManager) public onlySigner {
        tokenManager = TokenManager(_tokenManager);
        emit TokenManagerUpdated(_tokenManager);
    }

    function setBridge(address _bridge) public onlySigner {
        bridge = Bridge(_bridge);
        emit BridgeUpdated(_bridge);
    }

    function setFeeManager(address payable _feeManager) public onlySigner {
        feeManager = FeeManager(_feeManager);
        emit FeeManagerUpdated(_feeManager);
    }

    function setFeePercentage(uint256 _feePercentage) public onlySigner {
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
    }

    function addLiquidity(address _token, uint256 _amount) public {
        claimRewards(_token);

        require(tokenManager.isTokenEnabled(_token), "TokenManager: token is not supported");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "IERC20: transfer failed");

        _addLiquidity(_token, _amount);
    }

    function removeLiquidity(address _token, uint256 _amount) public payable {
        claimRewards(_token);

        require(tokenManager.isTokenEnabled(_token), "TokenManager: token is not supported");
        require(liquidityPositions[_token][msg.sender].balance >= _amount, "LiquidityPools: too much amount");

        _removeLiquidity(_token, _amount);

        if (_token == NATIVE_TOKEN) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: _amount, gas: 21000}("");
            require(success, "LiquidityPools: transfer native token failed");
        } else {
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "IERC20: amount more than contract balance");
            require(IERC20(_token).transfer(msg.sender, _amount), "IERC20: transfer failed");
        }
    }

    function claimRewards(address _token) public {
        uint256 rewardsOwingAmount = rewardsOwing(_token);
        if (rewardsOwingAmount > 0) {
            collectedFees[_token] -= rewardsOwingAmount;
            liquidityPositions[_token][msg.sender].balance += rewardsOwingAmount;
            liquidityPositions[_token][msg.sender].lastRewardPoints = totalRewardPoints[_token];
        }
    }

    function addNativeLiquidity() public payable {
        claimRewards(NATIVE_TOKEN);

        _addLiquidity(NATIVE_TOKEN, msg.value);
    }

    function rewardsOwing(address _token) public view returns (uint256) {
        uint256 newRewardPoints = totalRewardPoints[_token] - liquidityPositions[_token][msg.sender].lastRewardPoints;
        return (liquidityPositions[_token][msg.sender].balance * newRewardPoints) / BASE_DIVISOR;
    }

    function _addLiquidity(address _token, uint256 _amount) private {
        providedLiquidity[_token] += _amount;
        availableLiquidity[_token] += _amount;
        liquidityPositions[_token][msg.sender].balance += _amount;
        liquidityPositions[_token][msg.sender].lastRewardPoints = totalRewardPoints[_token];

        emit LiquidityAdded(_token, msg.sender, _amount);
    }

    function _removeLiquidity(address _token, uint256 _amount) private {
        providedLiquidity[_token] -= _amount;
        availableLiquidity[_token] -= _amount;
        liquidityPositions[_token][msg.sender].balance -= _amount;

        emit LiquidityRemoved(_token, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignerOwnable.sol";
import "./BridgeValidatorFeePool.sol";
import "./LiquidityPools.sol";
import "./Globals.sol";

contract FeeManager is Initializable, SignerOwnable {
    LiquidityPools public liquidityPools;
    BridgeValidatorFeePool public validatorFeePool;
    address public foundationAddress;

    uint256 public validatorRefundFee;
    mapping(address => uint256) public tokenFeePercentage;
    mapping(address => uint256) public validatorRewardPercentage;
    mapping(address => uint256) public liquidityRewardPercentage;

    event LiquidityPoolsUpdated(address _liquidityPools);
    event FoundationAddressUpdated(address _foundationAddress);
    event ValidatorRefundFeeUpdated(uint256 _validatorRefundFee);
    event ValidatorFeeUpdated(address _validatorFee);

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        address _signerStorage,
        address payable _liquidityPools,
        address _foundationAddress,
        address payable _validatorFeePool,
        uint256 _validatorRefundFee
    ) external initializer {
        _setSignerStorage(_signerStorage);
        setLiquidityPools(_liquidityPools);
        setFoundationAddress(_foundationAddress);
        setValidatorFeePool(_validatorFeePool);
        setValidatorRefundFee(_validatorRefundFee);
    }

    function setLiquidityPools(address payable _liquidityPools) public onlySigner {
        liquidityPools = LiquidityPools(_liquidityPools);
        emit LiquidityPoolsUpdated(_liquidityPools);
    }

    function setFoundationAddress(address _foundationAddress) public onlySigner {
        foundationAddress = _foundationAddress;
        emit FoundationAddressUpdated(_foundationAddress);
    }

    function setValidatorFeePool(address payable _validatorFee) public onlySigner {
        validatorFeePool = BridgeValidatorFeePool(_validatorFee);
        emit ValidatorFeeUpdated(_validatorFee);
    }

    function setValidatorRefundFee(uint256 _validatorRefundFee) public onlySigner {
        validatorRefundFee = _validatorRefundFee;
        emit ValidatorRefundFeeUpdated(_validatorRefundFee);
    }

    function setTokenFee(
        address token,
        uint256 tokenFee,
        uint256 validatorReward,
        uint256 liquidityReward
    ) public {
        tokenFeePercentage[token] = tokenFee;
        validatorRewardPercentage[token] = validatorReward;
        liquidityRewardPercentage[token] = liquidityReward;
    }

    function distributeRewards(address token) public {
        uint256 totalRewards;
        uint256 validatorRewards;
        uint256 liquidityRewards;
        uint256 foundationRewards;

        if (token == NATIVE_TOKEN) {
            totalRewards = address(this).balance;

            (validatorRewards, liquidityRewards, foundationRewards) = _calculateRewards(token, totalRewards);

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(validatorFeePool).call{value: validatorRewards, gas: 21000}("");
            require(success, "FeeManager: transfer native token failed");

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = address(liquidityPools).call{value: liquidityRewards, gas: 21000}("");
            require(success, "FeeManager: transfer native token failed");

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = foundationAddress.call{value: foundationRewards, gas: 21000}("");
            require(success, "FeeManager: transfer native token failed");
        } else {
            totalRewards = IERC20(token).balanceOf(address(this));
            (validatorRewards, liquidityRewards, foundationRewards) = _calculateRewards(token, totalRewards);

            require(IERC20(token).transfer(address(validatorFeePool), validatorRewards), "IERC20: transfer failed");
            require(IERC20(token).transfer(address(liquidityPools), liquidityRewards), "IERC20: transfer failed");
            require(IERC20(token).transfer(foundationAddress, foundationRewards), "IERC20: transfer failed");
        }

        liquidityPools.distributeFee(token, liquidityRewards);
    }

    function calculateFee(address token, uint256 amount) public view returns (uint256 fee) {
        fee = validatorRefundFee + (tokenFeePercentage[token] * amount) / BASE_DIVISOR;

        require(fee <= amount, "FeeManager: fee to be less than or equal to amount");

        return fee;
    }

    function _calculateRewards(address token, uint256 totalRewards)
        private
        view
        returns (
            uint256 validatorRewards,
            uint256 liquidityRewards,
            uint256 foundationRewards
        )
    {
        validatorRewards = (validatorRewardPercentage[token] * totalRewards) / BASE_DIVISOR;
        liquidityRewards = (liquidityRewardPercentage[token] * totalRewards) / BASE_DIVISOR;
        foundationRewards = totalRewards - validatorRewards - liquidityRewards;

        return (validatorRewards, liquidityRewards, foundationRewards);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20MintableBurnable {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SignerOwnable.sol";
import "./TokenManager.sol";
import "./Bridge.sol";
import "./FeeManager.sol";
import "./Globals.sol";
import "./BridgeValidatorFeePool.sol";
import "../interfaces/IBridgeApp.sol";
import "../interfaces/IBridgeMediator.sol";

contract RelayBridge is Initializable, SignerOwnable {
    mapping(bytes32 => bytes) public sentData;

    mapping(bytes32 => bool) public sent;
    mapping(bytes32 => bool) public executed;
    mapping(bytes32 => bool) public reverted;

    address[] public leaderHistory;

    BridgeValidatorFeePool public bridgeValidatorFeePool;

    uint256 public nonce;

    event Sent(bytes32 hash, uint256 sourceChain, uint256 destinationChain, uint256 value);
    event Reverted(bytes32 hash, uint256 sourceChain, uint256 destinationChain);
    event Executed(bytes32 hash, uint256 sourceChain, uint256 destinationChain);

    function initialize(address _signerStorage, address payable _bridgeValidatorFeePool) external initializer {
        _setSignerStorage(_signerStorage);
        bridgeValidatorFeePool = BridgeValidatorFeePool(_bridgeValidatorFeePool);
    }

    function send(
        uint256 destinationChain,
        uint256 gasLimit,
        bytes memory data
    ) external payable {
        bytes32 hash = dataHash(msg.sender, block.chainid, destinationChain, gasLimit, data, nonce);
        require(sentData[hash].length == 0, "RelayBridge: data already send");

        sent[hash] = true;
        sentData[hash] = data;
        nonce++;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(bridgeValidatorFeePool).call{value: msg.value, gas: 21000}("");
        require(success, "RelayBridge: transfer value failed");

        emit Sent(hash, block.chainid, destinationChain, msg.value);
    }

    function revertSend(
        address appContract,
        uint256 destinationChain,
        uint256 gasLimit,
        bytes memory data,
        uint256 _nonce,
        address leader
    ) external onlySigner {
        bytes32 hash = dataHash(appContract, block.chainid, destinationChain, gasLimit, data, _nonce);
        require(sent[hash], "RelayBridge: data never sent");
        require(!reverted[hash], "RelayBridge: data already reverted");

        reverted[hash] = true;
        leaderHistory.push(leader);

        IBridgeApp(appContract).revertSend(destinationChain, data);

        emit Reverted(hash, block.chainid, destinationChain);
    }

    function execute(
        address appContract,
        uint256 sourceChain,
        uint256 gasLimit,
        bytes memory data,
        uint256 _nonce,
        address leader
    ) external onlySigner {
        bytes32 hash = dataHash(appContract, sourceChain, block.chainid, gasLimit, data, _nonce);
        require(!executed[hash], "RelayBridge: data already executed");

        executed[hash] = true;
        leaderHistory.push(leader);

        IBridgeApp(appContract).execute(sourceChain, data);

        emit Executed(hash, sourceChain, block.chainid);
    }

    function leaderHistoryLength() external view returns (uint256) {
        return leaderHistory.length;
    }

    function dataHash(
        address appContract,
        uint256 sourceChain,
        uint256 destinationChain,
        uint256 gasLimit,
        bytes memory data,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(appContract, sourceChain, destinationChain, gasLimit, data, _nonce));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeApp {
    function execute(uint256 sourceChain, bytes memory data) external;

    function revertSend(uint256 destinationChain, bytes memory data) external;

    function bridgeAppAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeMediator {
    function mediate(
        uint256 sourceChain,
        uint256 destinationChain,
        bytes memory data
    ) external view returns (bytes memory);
}