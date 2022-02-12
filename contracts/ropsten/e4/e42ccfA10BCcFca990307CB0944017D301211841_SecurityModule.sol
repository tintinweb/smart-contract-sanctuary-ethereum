// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./BaseModule.sol";
import "./IWallet.sol";
import "./IModuleRegistry.sol";

contract SecurityModule is BaseModule, Initializable {

    uint public lockedSecurityPeriod;
    uint public recoverySecurityPeriod;

    struct Recovery {
        uint activeAt; // timestamp for activation of escape mode, 0 otherwise
        address recovery;
    }
    mapping (address => Recovery) public recoveries;

    struct SignerConfInfo {
        address[] signers;
        bool exist;
        uint lockedPeriod;
        uint recoveryPeriod;
    }

    mapping (address => SignerConfInfo) public signerConfInfos;
    constructor() {}

    function initialize(
        IModuleRegistry _registry,
        uint _lockedSecurityPeriod,
        uint _recoverySecurityPeriod
    ) public initializer {
        registry = _registry;
        lockedSecurityPeriod = _lockedSecurityPeriod;
        recoverySecurityPeriod = _recoverySecurityPeriod;
    }

    function init(address _wallet, bytes memory data)  public override onlyWallet(_wallet) {
        require(!isRegisteredWallet(_wallet), "SM: should not add same module to wallet twice");
        require(!signerConfInfos[_wallet].exist, "SM: wallet exists in signerConfInfos");

        addWallet(_wallet);
        // decode signer info from data
        (address[] memory signers) = abi.decode(data, (address[]));
        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        // TODO make sure signers is emptry
        for (uint i = 0; i < signers.length; i++) {
            signerConfInfo.signers.push(signers[i]);
            require(signers[i] != IWallet(_wallet).owner(), "SM: signer cann't be owner");
        }
        signerConfInfo.exist = true;
        signerConfInfo.lockedPeriod = lockedSecurityPeriod;
        signerConfInfo.recoveryPeriod = recoverySecurityPeriod;
    }

    /**
     * add new module to wallet
     * @param _wallet attach module to new module
     * @param _module attach module
     */
    function addModule(address _wallet, address _module, bytes calldata data) external virtual override onlyWallet(_wallet) onlyWhenUnlocked(_wallet) {
        require(registry.isRegisteredModule(_module), "SM: module is not registered");
        IWallet(_wallet).authoriseModule(_module, true, data);
    }

    function setSecurityPeriod(address _wallet, uint _lockedSecurityPeriod, uint _recoverySecurityPeriod) public onlyOwner(_wallet) {
        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: Invalid wallet");
        require(signerConfInfo.lockedPeriod != _lockedSecurityPeriod || signerConfInfo.recoveryPeriod != _recoverySecurityPeriod, "SM:Must change at least one period");
        if (signerConfInfo.lockedPeriod != _lockedSecurityPeriod) {
            signerConfInfo.lockedPeriod = _lockedSecurityPeriod;
        }
        if (signerConfInfo.recoveryPeriod != _recoverySecurityPeriod) {
            signerConfInfo.recoveryPeriod = _recoverySecurityPeriod;
        }
    }

    function getLockedSecurityPeriod(address _wallet) public view returns (uint) {
        SignerConfInfo memory signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: Invalid wallet");
        return signerConfInfo.lockedPeriod;
    }

    function getRecoverySecurityPeriod(address _wallet) public view returns (uint) {
        SignerConfInfo memory signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: Invalid wallet");
        return signerConfInfo.recoveryPeriod;
    }

    function isSigner(address _wallet, address _signer) public view returns (bool) {
        SignerConfInfo memory signerConfInfo = signerConfInfos[_wallet];
        return findSigner(signerConfInfo.signers, _signer);
    }

    function getSigners(address _wallet) public view returns(address[] memory) {
        return signerConfInfos[_wallet].signers;
    }

    /**
     * @notice Helper method to check if a wallet is locked.
     * @param _wallet The target wallet.
     */
    function isLocked(address _wallet) public view returns (bool) {
        return _isLocked(_wallet);
    }

    function findSigner(address[] memory _signers, address _signer) public pure returns (bool) {
        for (uint i = 0; i < _signers.length; i ++) {
            if (_signers[i] == _signer) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Throws if the recovery is not a guardian for the wallet or the module itself.
     */
    modifier onlyOwnerOrSigner(address _wallet) {
        require(
            IWallet(_wallet).owner() == msg.sender || isSigner(_wallet, msg.sender),
            "SM: must be signer/wallet"
        );
        _;
    }

    // signer managerment
    function addSigner(address _wallet, address signer) external onlyOwner(_wallet) onlyWhenUnlocked(_wallet) {
        require(isRegisteredWallet(_wallet), "SM: wallet should be registered before adding signers");
        require(signer != address(0) && !isSigner(_wallet, signer), "SM: invalid newSigner or invalid oldSigner");

        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: wallet signer info not consistent");
        signerConfInfo.signers.push(signer);
        signerConfInfos[_wallet] = signerConfInfo;
        // calm-down period
        _setLock(_wallet, block.timestamp + signerConfInfo.lockedPeriod, SecurityModule.addSigner.selector);
    }

    function replaceSigner(address _wallet, address _newSigner, address _oldSigner) public onlyOwner(_wallet) {
        require(isRegisteredWallet(_wallet), "SM: wallet should be registered before adding signers");
        require(_newSigner != address(0) && isSigner(_wallet, _oldSigner), "SM: invalid newSigner or invalid oldSigner");

        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: Invalid wallet");

        uint endIndex = signerConfInfo.signers.length - 1;
        for (uint i = 0; i < signerConfInfo.signers.length - 1; i ++) {
            if (_oldSigner == signerConfInfo.signers[i]) {
                signerConfInfo.signers[i] = _newSigner;
                i = endIndex;
            }
        }
        // emit event
    }

    function removeSigner(address _wallet, address _oldSigner) public onlyOwner(_wallet) {
        require(isRegisteredWallet(_wallet), "SM: wallet should be registered before adding signers");
        require(isSigner(_wallet, _oldSigner), "SM: invalid oldSigner");

        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: Invalid wallet");

        uint endIndex = signerConfInfo.signers.length - 1;
        address lastSigner = signerConfInfo.signers[endIndex];
        for (uint i = 0; i < signerConfInfo.signers.length - 1; i ++) {
            if (_oldSigner == signerConfInfo.signers[i]) {
                signerConfInfo.signers[i] = lastSigner;
                i = endIndex;
            }
        }
        signerConfInfo.signers.pop();
        // emit event
    }

    // social recovery
    function isInRecovery(address _wallet) public view returns (bool) {
        Recovery memory config = recoveries[_wallet];
        return config.activeAt != 0 && config.activeAt > uint64(block.timestamp);
    }

    /**
     * Declare a recovery, executed by contract itself, called by sendMultiSig.
     * @param _recovery: lost signer
     */
    function triggerRecovery(address _wallet, address _recovery) external onlyWallet(_wallet) {
        require(_recovery != address(0), "SM: Invalid new signer");
        require(_recovery != IWallet(_wallet).owner(), "SM: owner can not trigger a recovery");
        require(!isSigner(_wallet, _recovery), "SM: newOwner can't be an existing signer");
        require(
            !isInRecovery(_wallet),
            "SM: should not trigger twice"
        );
        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        _setLock(_wallet, block.timestamp + signerConfInfo.lockedPeriod, SecurityModule.triggerRecovery.selector);
        uint expiry = block.timestamp + signerConfInfo.recoveryPeriod;

        recoveries[_wallet] = Recovery({
            activeAt: expiry,
            recovery: _recovery
        });
    }

    function cancelRecovery(address _wallet) external onlyWallet(_wallet) {
        //require(recovery.activeAt != 0 && recovery.recovery != address(0), "not recovering");
        require(isInRecovery(_wallet), "SM: not recovering");
        delete recoveries[_wallet];
        _setLock(_wallet, 0, bytes4(0));
    }

    function executeRecovery(address _wallet) public {
        require(
            isInRecovery(_wallet),
            "SM: No valid recovery found"
        );
        Recovery memory recovery_ = recoveries[_wallet];

        IWallet(_wallet).replaceOwner(recovery_.recovery);

        delete recoveries[_wallet];
        _setLock(_wallet, 0, bytes4(0));
    }

    /**
     * @notice Lets a guardian lock a wallet. FIXME owner can also lock
     * @param _wallet The target wallet.
     */
    function lock(address _wallet) external onlyOwnerOrSigner(_wallet) onlyWhenUnlocked(_wallet) {
        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        _setLock(_wallet, block.timestamp + signerConfInfo.lockedPeriod, SecurityModule.lock.selector);
    }

    /**
     * @notice Lets a guardian unlock a locked wallet. FIXME owner can also unlock
     * @param _wallet The target wallet.
     */
    function unlock(address _wallet) external onlyOwnerOrSigner(_wallet) onlyWhenLocked(_wallet) {
        require(locks[_wallet].locker == SecurityModule.lock.selector, "SM: cannot unlock");
        _setLock(_wallet, 0, bytes4(0));
    }

    function _setLock(address _wallet, uint256 _releaseAfter, bytes4 _locker) internal {
        locks[_wallet] = Lock(uint64(_releaseAfter), _locker);
    }

    /**
     * @notice Only entry point of the multisig. The method will execute any transaction provided that it
     * receieved enough signatures from the wallet owners.
     * @param _wallet The destination address for the transaction to execute.
     * @param _args The value parameter for the transaction to execute.
     * @param _signatures Concatenated signatures ordered based on increasing signer's address.
     */
    function multicall(address _wallet, CallArgs memory _args, bytes memory _signatures) public onlyOwnerOrSigner(_wallet) {
        SignerConfInfo storage signerConfInfo = signerConfInfos[_wallet];
        require(signerConfInfo.exist, "SM: invalid wallet");
        uint threshold = (signerConfInfo.signers.length + 1) / 2;
        uint256 count = _signatures.length / 65;
        require(count >= threshold, "SM: Not enough signatures");
        bytes32 txHash = getHash(_args);
        uint256 valid = 0;
        address lastSigner = address(0);
        for (uint256 i = 0; i < count; i++) {
            address recovered = recoverSigner(txHash, _signatures, i);
            require(recovered > lastSigner, "SM: Badly ordered signatures"); // make sure signers are different
            lastSigner = recovered;
            if (findSigner(signerConfInfo.signers, recovered)) {
                valid += 1;
                if (valid >= threshold) {
                    execute(_wallet, _args);
                    return;
                }
            }
        }
        // If not enough signatures for threshold, then the transaction is not executed
        revert("SM: Not enough valid signatures");
    }

    function getHash(CallArgs memory _args) internal pure returns(bytes32) {
        address to = _args.to;
        uint value = _args.value;
        bytes memory data = _args.data;
        uint sequenceId = _args.sequenceId;

        //TODO encode expire time
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), to, value, data, sequenceId));
    }

    function recoverSigner(bytes32 txHash, bytes memory _signatures, uint256 _i) internal pure returns (address){
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = splitSignature(_signatures, _i);
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",txHash)), v, r, s);
    }

    /**
     * @notice Parses the signatures and extract (r, s, v) for a signature at a given index.
     * A signature is {bytes32 r}{bytes32 s}{uint8 v} in compact form where the signatures are concatenated.
     * @param _signatures concatenated signatures
     * @param _index which signature to read (0, 1, 2, ...)
     */
    function splitSignature(bytes memory _signatures, uint256 _index) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) tehn apply a mask
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "SM: Invalid v");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IModule.sol";
import "./IWallet.sol";
import "./IModuleRegistry.sol";

abstract contract BaseModule is IModule {

    event MultiCalled(address to, uint value, bytes data);
    IModuleRegistry internal registry;
    address[] internal wallets;
    struct Lock {
        // the lock's release timestamp
        uint64 release;
        // the signature of the method that set the last lock
        bytes4 locker;
    }

    // Wallet specific lock storage
    mapping (address => Lock) internal locks;

    struct CallArgs {
        address to;
        uint value;
        bytes data;
        uint sequenceId;
        uint expireTime;
    }

    /**
     * Modifier that will check if sender is owner
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "only self");
        _;
    }

    function _isSelf(address _self) internal view returns (bool) {
        return _self == address(this);
    }

     /**
     * @notice Throws if the wallet is not locked.
     */
    modifier onlyWhenLocked(address _wallet) {
        require(_isLocked(_wallet), "BM: wallet must be locked");
        _;
    }

    /**
     * @dev Throws if the sender is not the target wallet of the call.
     */
    modifier onlyWallet(address _wallet) {
        require(msg.sender == _wallet, "BM: caller must be wallet");
        _;
    }

    /**
     * @notice Helper method to check if a wallet is locked.
     * @param _wallet The target wallet.
     */
    function _isLocked(address _wallet) internal view returns (bool) {
        return locks[_wallet].release > uint64(block.timestamp);
    }

    /**
     * @notice Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(address _wallet) {
        require(!_isLocked(_wallet), "BM: wallet locked");
        _;
    }

    function isRegisteredWallet(address _wallet) internal view returns (bool){
        for (uint i = 0; i < wallets.length; i ++) {
            if ( wallets[i] == _wallet ) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function _isOwner(address _wallet, address _addr) internal view returns (bool) {
        return IWallet(_wallet).owner() == _addr;
    }

    modifier onlyOwner(address _wallet) {
        require(IWallet(_wallet).owner() == msg.sender, "BM: must be owner");
        _;
    }

    function addWallet(address _wallet) internal {
        wallets.push(_wallet);
    }

    function removeWallet(address _wallet) internal {
        uint endIndex = wallets.length - 1;
        for (uint i = 0; i < endIndex; i ++) {
            if ( wallets[i] == _wallet ) {
                wallets[i] = wallets[endIndex];
                i = endIndex;
            }
        }
        wallets.pop();
    }

    function execute(address _wallet, CallArgs memory _args) internal {
        address to = _args.to;
        uint value = _args.value;
        bytes memory data = _args.data;
        uint sequenceId = _args.sequenceId;
        uint expireTime = _args.expireTime;
        IWallet(_wallet).invoke(to, value, data, expireTime, sequenceId);
        emit MultiCalled(to, value, data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWallet {

    /**
     * @notice Return the owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);

    /**
     * @notice replace the wallet owner.
     * @param _newOwner The new signer.
     */
    function replaceOwner(address _newOwner) external;

    /**
     * @notice Checks if a module is authorised on the wallet.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes memory data) external;


    function createForwarder() external returns (address);

    function invoke(
        address toAddress,
        uint value,
        bytes calldata data,
        uint expireTime,
        uint sequenceId
    ) external returns (bytes memory);

    function raw_invoke(
        address toAddress,
        uint value,
        bytes calldata data
    ) external returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;

    function deregisterModule(address _module) external;

    function moduleName(address _module) external view returns (bytes32);

    function isRegisteredModule(address _module) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModule {
    function init(address _wallet, bytes memory _data) external;
    function addModule(address _wallet, address _module, bytes calldata _data) external;
}