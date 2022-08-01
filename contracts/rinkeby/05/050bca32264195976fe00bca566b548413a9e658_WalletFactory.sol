// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Proxy.sol";
import "./SmartWallet.sol"; 
//@review
//possibly IWallet.sol

contract WalletFactory {
    address internal _defaultImpl; 

    //states : registry
    mapping (address => bool) public isWalletExist;

    constructor(address _baseImpl) {
        require(_baseImpl != address(0), "base wallet address can not be zero");
        _defaultImpl = _baseImpl;
    }

    event WalletCreated(address indexed _proxy, address indexed _implementation, address indexed _owner);

    /**
     * @notice Deploys wallet using create2 and points it to _defaultImpl
     * @param _owner EOA signatory of the wallet
     * @param _entryPoint AA 4337 entry point address
     * @param _handler fallback handler address
     * @param _index extra salt that allows to deploy more wallets if needed for same EOA (default 0)
     */
    function deployCounterFactualWallet(address _owner, address _entryPoint, address _handler, uint _index) public returns(address proxy){
        bytes32 salt = keccak256(abi.encodePacked(_owner, address(uint160(_index))));
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
        emit WalletCreated(proxy,_defaultImpl,_owner);
        SmartWallet(proxy).init(_owner, _entryPoint, _handler);
        isWalletExist[proxy] = true;
    }

    /**
     * @notice Deploys wallet using create and points it to _defaultImpl
     * @param _owner EOA signatory of the wallet
     * @param _entryPoint AA 4337 entry point address
     * @param _handler fallback handler address
    */ 
    function deployWallet(address _owner, address _entryPoint, address _handler) public returns(address proxy){ 
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create(0x0, add(0x20, deploymentData), mload(deploymentData))
        }
        emit WalletCreated(proxy,_defaultImpl,_owner);
        SmartWallet(proxy).init(_owner, _entryPoint, _handler);
        isWalletExist[proxy] = true;
    }

    /**
     * @notice Allows to find out wallet address prior to deployment
     * @param _owner EOA signatory of the wallet
     * @param _index extra salt that allows to deploy more wallets if needed for same EOA (default 0)
    */
    function getAddressForCounterfactualWallet(address _owner, uint _index) external view returns (address _wallet) {
       bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
       bytes32 salt = keccak256(abi.encodePacked(_owner, address(uint160(_index))));
       bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)));
        _wallet = address(uint160(uint(hash)));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Proxy // This is the user's wallet
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 */
contract Proxy {

    /* This is the keccak-256 hash of "biconomy.scw.proxy.implementation" subtracted by 1, and is validated in the constructor */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x37722d148fb373b961a84120b6c8d209709b45377878a466db32bbc40d95af26;

    event Received(uint indexed value, address indexed sender, bytes data);

    constructor(address _implementation) {
         assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("biconomy.scw.proxy.implementation")) - 1));
         assembly {
             sstore(_IMPLEMENTATION_SLOT,_implementation) 
         }
    }

    fallback() external payable {
        address target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            target := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//TODO
//review Base licensing
//https://spdx.org/licenses/

import "./libs/LibAddress.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IWallet.sol";
import "./common/Singleton.sol";
import "./storage/WalletStorage.sol";
import "./base/ModuleManager.sol";
import "./base/FallbackManager.sol";
import "./common/SignatureDecoder.sol";
// import "./common/Hooks.sol";
import "./common/SecuredTokenTransfer.sol";
import "./interfaces/ISignatureValidator.sol";
import "./interfaces/IERC165.sol";
import "./libs/ECDSA.sol";

// Hooks not made a base yet
contract SmartWallet is 
     Singleton,
     IWallet,
     IERC165,
     WalletStorage,
     ModuleManager,
     SignatureDecoder,
     SecuredTokenTransfer,
     ISignatureValidatorConstants,
     FallbackManager,
     Initializable     
    {
    using ECDSA for bytes32;
    using LibAddress for address;

    event ImplementationUpdated(address newImplementation);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);
    event EntryPointChanged(address oldEntryPoint, address newEntryPoint);
    event EOAChanged(address indexed _scw, address indexed _oldEOA, address indexed _newEOA);

    // modifiers
    // onlyOwner
    /**
     * @notice Throws if the sender is not an the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Smart Account:: Sender is not authorized");
        _;
    }

    // onlyOwner OR self
    modifier mixedAuth {
    require(msg.sender == owner || msg.sender == address(this),"Only owner or self");
    _;
   }

    // @notice authorized modifier (onlySelf) is already inherited

    // Setters

    function setOwner(address _newOwner) external mixedAuth {
        require(_newOwner != address(0), "Smart Account:: new Signatory address cannot be zero");
        owner = _newOwner;
        emit EOAChanged(address(this),owner,_newOwner);
    }

    /**
     * @notice Updates the implementation of the base wallet
     * @param _implementation New wallet implementation
     */
    function updateImplementation(address _implementation) external mixedAuth {
        require(_implementation.isContract(), "INVALID_IMPLEMENTATION");
        _setImplementation(_implementation);
        emit ImplementationUpdated(_implementation);
    }

    function updateEntryPoint(address _entryPoint) external mixedAuth {
        require(_entryPoint != address(0), "Smart Account:: new entry point address cannot be zero");
        emit EntryPointChanged(entryPoint, _entryPoint);
        entryPoint = _entryPoint;
    }

    // Getters

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev returns a value from the nonces 2d mapping
     * @param batchId : the key of the user's batch being queried
     * @return nonce : the number of transaction made within said batch
     */
    function getNonce(uint256 batchId)
    public view
    returns (uint256) {
        return nonces[batchId];
    }
    
    // Initialize / Setup
    // Used to setup
    // i. owner ii. entry point iii. handlers
    function init(address _owner, address _entryPoint, address _handler) public initializer { 
        require(owner == address(0), "Already initialized");
        require(entryPoint == address(0), "Already initialized");
        require(_owner != address(0),"Invalid owner");
        require(_entryPoint != address(0), "Invalid Entrypoint");
        owner = _owner;
        entryPoint = _entryPoint;
        if (_handler != address(0)) internalSetFallbackHandler(_handler);
        setupModules(address(0), bytes(""));
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    // @review 2D nonces and args as default batchId 0 is always used
    // TODO : Update description
    // TODO : Add batchId and update in test cases, utils etc
    // Gnosis style transaction with optional repay in native tokens OR ERC20 
    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    /// Note: The fees are always transferred, even if the user transaction fails.
    /// @param _tx Wallet transaction 
    /// @param batchId batchId key for 2D nonces
    /// @param refundInfo Required information for gas refunds
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        Transaction memory _tx,
        uint256 batchId,
        FeeRefund memory refundInfo,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    _tx,
                    // Payment info
                    refundInfo,
                    // Signature info
                    nonces[batchId]
                );
            // Increase nonce and execute transaction.
            // Default space aka batchId is 0
            nonces[batchId]++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }


        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= max((_tx.targetTxGas * 64) / 63,_tx.targetTxGas + 2500) + 500, "BSA010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than targetTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than targetTxGas
            success = execute(_tx.to, _tx.value, _tx.data, _tx.operation, refundInfo.gasPrice == 0 ? (gasleft() - 2500) : _tx.targetTxGas);
            gasUsed = gasUsed - gasleft();
            // If no targetTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || _tx.targetTxGas != 0 || refundInfo.gasPrice != 0, "BSA013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (refundInfo.gasPrice > 0) {
                payment = handlePayment(gasUsed, refundInfo.baseGas, refundInfo.gasPrice, refundInfo.gasToken, refundInfo.refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = (gasUsed + baseGas) * (gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            // Review: low level call value vs transfer
            (bool success,) = receiver.call{value: payment}("");
            require(success, "BSA011");
        } else {
            payment = (gasUsed + baseGas) * (gasPrice);
            require(transferToken(gasToken, receiver, payment), "BSA012");
        }
    }

    // @review
    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i = 0;
        address _signer;
        (v, r, s) = signatureSplit(signatures, i);
        // review if necessary v = 1
        // review sig verification from other wallets
        if(v == 0) {
            // If v is 0 then it is a contract signature
            // When handling contract signatures the address of the contract is encoded into r
            _signer = address(uint160(uint256(r)));

            // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= uint256(1) * 65, "BSA021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s) + 32 <= signatures.length, "BSA022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s) + 32 + contractSignatureLen <= signatures.length, "BSA023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(_signer).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "BSA024");
        }
        else if(v > 30) {
            // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
            // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
            _signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            require(_signer == owner, "INVALID_SIGNATURE");
        } else {
            _signer = ecrecover(dataHash, v, r, s);
            require(_signer == owner, "INVALID_SIGNATURE");
        }
    }

    /// review necessity for this method for estimating execute call
    /// @dev Allows to estimate a transaction.
    ///      This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of transaction.
    /// @param data Data payload of transaction.
    /// @param operation Operation type of transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }


    /// @dev Returns hash to be signed by owner.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param targetTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 targetTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        Transaction memory _tx = Transaction({
            to: to,
            value: value,
            data: data,
            operation: operation,
            targetTxGas: targetTxGas
        });
        FeeRefund memory refundInfo = FeeRefund({
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: gasToken,
            refundReceiver: refundReceiver
        });
        return keccak256(encodeTransactionData(_tx, refundInfo, _nonce));
    }


    /// @dev Returns the bytes that are hashed to be signed by owner.
    /// @param _tx Wallet transaction 
    /// @param refundInfo Required information for gas refunds
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        Transaction memory _tx,
        FeeRefund memory refundInfo,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    WALLET_TX_TYPEHASH,
                    _tx.to,
                    _tx.value,
                    keccak256(_tx.data),
                    _tx.operation,
                    _tx.targetTxGas,
                    refundInfo.baseGas,
                    refundInfo.gasPrice,
                    refundInfo.gasToken,
                    refundInfo.refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    // Extra Utils
    
    // Review: low level call value vs transfer // dest.transfer(amount);
    function transfer(address payable dest, uint amount) external onlyOwner {
        require(dest != address(0), "this action will burn your funds");
        (bool success,) = dest.call{value:amount}("");
        require(success,"transfer failed");
    }

    function pullTokens(address token, address dest, uint256 amount) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        SafeERC20.safeTransfer(tokenContract, dest, amount);
    }

    function exec(address dest, uint value, bytes calldata func) external onlyOwner{
        _call(dest, value, func);
    }

    function execBatch(address[] calldata dest, bytes[] calldata func) external onlyOwner{
        require(dest.length == func.length, "wrong array lengths");
        for (uint i = 0; i < dest.length;) {
            _call(dest[i], 0, func[i]);
            unchecked {
                ++i;
            }
        }
    }

    // AA implementation
    function _call(address sender, uint value, bytes memory data) internal {
        // @review linter
        (bool success, bytes memory result) = sender.call{value : value}(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(result,32), mload(result))
            }
        }
    }

    function _requireFromEntryPoint() internal view {
        require(msg.sender == address(entryPoint), "wallet: not from EntryPoint");
    }

    //called by entryPoint, only after validateUserOp succeeded.
    function execFromEntryPoint(address dest, uint value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, uint requiredPrefund) external override {
        _requireFromEntryPoint();
        _validateSignature(userOp, requestId);
        //during construction, the "nonce" field hold the salt.
        // if we assert it is zero, then we allow only a single wallet per owner.
        if (userOp.initCode.length == 0) {
            _validateAndUpdateNonce(userOp);
        }
        _payPrefund(requiredPrefund);
    }

    // review nonce conflict with AA userOp nonce
    // userOp can omit nonce or have batchId as well!
    function _validateAndUpdateNonce(UserOperation calldata userOp) internal {
        require(nonces[0]++ == userOp.nonce, "wallet: invalid nonce");
    }

    function _payPrefund(uint requiredPrefund) internal {
        if (requiredPrefund != 0) {
            //pay required prefund. make sure NOT to use the "gas" opcode, which is banned during validateUserOp
            // (and used by default by the "call")
            // @review linter
            (bool success,) = payable(msg.sender).call{value : requiredPrefund, gas : type(uint).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not wallet.)
        }
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 requestId) internal view {
        bytes32 hash = requestId.toEthSignedMessageHash();
        require(owner == hash.recover(userOp.signature), "wallet: wrong signature");
    }

    
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC165
     * @return `true` if the contract implements `_interfaceID`
    */
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    // Review
    // withdrawDepositTo
    // addDeposit
    // getDeposit
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAddress {
  /**
   * @notice Will return true if provided address is a contract
   * @param account Address to verify if contract or not
   * @dev This contract will return false if called within the constructor of
   *      a contract's deployment, as the code is not yet stored on-chain.
   */
  function isContract(address account) internal view returns (bool) {
    uint256 csize;
    // solhint-disable-next-line no-inline-assembly
    assembly { csize := extcodesize(account) }
    return csize != 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !Address.isContract(address(this)),
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./libs/UserOperation.sol";

interface IWallet {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfuly.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param requiredPrefund the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, uint requiredPrefund) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to the proxy contract
contract Singleton {
    // singleton slot always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.

    /* This is the keccak-256 hash of "biconomy.scw.proxy.implementation" subtracted by 1 */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x37722d148fb373b961a84120b6c8d209709b45377878a466db32bbc40d95af26;

    function _setImplementation(address _imp) internal {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("biconomy.scw.proxy.implementation")) - 1));
        // solhint-disable-next-line no-inline-assembly
        assembly {
          sstore(_IMPLEMENTATION_SLOT, _imp)
         }
    }

    function _getImplementation() internal view returns (address _imp) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
         _imp := sload(_IMPLEMENTATION_SLOT)
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Enum.sol";

contract WalletStorage {
    // Version
    string public constant VERSION = "0.0.1";

    // Domain Seperators
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // @review for any modifications
    // keccak256(
    //     "WalletTx(address to,uint256 value,bytes data,uint8 operation,uint256 targetTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 internal constant WALLET_TX_TYPEHASH = 0xeedfef42e81fe8cd0e4185e4320e9f8d52fd97eb890b85fa9bd7ad97c9a18de2;

    // Owner storage
    address public owner;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 targetTxGas;
        // uint256 batchId;
    }

    struct FeeRefund {
        uint256 baseGas;
        uint256 gasPrice; //gasPrice or tokenGasPrice
        address gasToken;
        address payable refundReceiver;
    }

    // @review
    // uint256 public nonce; //changed to 2D nonce
    mapping(uint256 => uint256) public nonces;

    // AA storage
    address public entryPoint;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
contract ModuleManager is SelfAuthorized, Executor {    
    // Events
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "BSA100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "BSA000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "BSA101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "BSA102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "BSA101");
        require(modules[prevModule] == module, "BSA103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "BSA104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules. Useful for a widget
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title SecuredTokenTransfer - Secure token transfer
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        // Review for sig collision and HAL-04
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// a copy of import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol", with tiny modification:
// ecrecover should not use the "GAS" opcode.
// (its a precompile, and uses fixed gas anyway)
// instead, ecrecover2 uses assembly.
// Had to change "pure" to "view", since the compiler can't tell this "staticcall" is pure

pragma solidity ^0.8.0;

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
            return;
            // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
    function tryRecover(bytes32 hash, bytes memory signature) internal view returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
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
    function recover(bytes32 hash, bytes memory signature) internal view returns (address) {
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address, RecoverError) {
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
        // address signer = ecrecover(hash,v,r,s);
        address signer = ecrecover2(hash, v, r, s);

        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function ecrecover2(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (address signer) {
        uint status;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let pointer := mload(0x40)

            mstore(pointer, hash)
            mstore(add(pointer, 0x20), v)
            mstore(add(pointer, 0x40), r)
            mstore(add(pointer, 0x60), s)


            status := staticcall(not(0), 0x01, pointer, 0x80, pointer, 0x20)
            signer := mload(pointer)
        // not required by this code, but other solidity code assumes unused data is zero...
            mstore(pointer, 0)
            mstore(add(pointer, 0x20), 0)
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint callGas;
        uint verificationGas;
        uint preVerificationGas;
        uint maxFeePerGas;
        uint maxPriorityFeePerGas;
        address paymaster;
        bytes paymasterData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address ret) {
        // solhint-disable-next-line no-inline-assembly
        assembly {ret := calldataload(userOp)}
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint) {
    unchecked {
        uint maxFeePerGas = userOp.maxFeePerGas;
        uint maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return min(tx.gasprice, maxFeePerGas);
        }
        return min(tx.gasprice, min(maxFeePerGas, maxPriorityFeePerGas + block.basefee));
    }
    }

    function requiredGas(UserOperation calldata userOp) internal pure returns (uint) {
    unchecked {
        //when using a Paymaster, the verificationGas is used also to cover the postOp call.
        // our security model might call postOp eventually twice
        uint mul = userOp.paymaster != address(0) ? 1 : 3;
        return userOp.callGas + userOp.verificationGas * mul + userOp.preVerificationGas;
    }
    }

    function requiredPreFund(UserOperation calldata userOp) internal view returns (uint prefund) {
    unchecked {
        return requiredGas(userOp) * gasPrice(userOp);
    }
    }

    function hasPaymaster(UserOperation calldata userOp) internal pure returns (bool) {
        return userOp.paymaster != address(0);
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
        return ret;
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Enum - Collection of enums
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "BSA031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}