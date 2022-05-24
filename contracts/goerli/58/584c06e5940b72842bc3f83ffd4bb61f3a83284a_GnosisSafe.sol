// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "./base/ModuleManager.sol";
import "./base/FallbackManager.sol";
import "./common/MasterCopy.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./interfaces/ISignatureValidator.sol";
import "./base/PaymentManager.sol";
import "./base/OwnerManager.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
/// @author Ricardo Guilherme Schmidt - (Status Research & Development GmbH) - Gas Token Payment
contract GnosisSafe is
    MasterCopy,
    ModuleManager,
    SignatureDecoder,
    FallbackManager,
    PaymentManager,
    OwnerManager
{

    string public constant NAME = "IAMO Safe";
    string public constant VERSION = "0.0.1";

    //keccak256(
    //    "SafeMessage(bytes message)"
    //);
    bytes32 private constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;
    mapping(bytes32 => uint256) public signedMessages;

    event ApproveHash(
        bytes32 indexed approvedHash,
        address indexed owner
    );

    event SignMsg(
        bytes32 indexed msgHash
    );

    // Mapping to keep track of all message hashes that have been approve by ALL REQUIRED owners
    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor()
    {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the mastercopy
        threshold = 1;
    }

    ///@dev Check whether the provided signatures would be valid
    ///@notice calling this function won't change any state on purpose
    ///@param dataHash Hash of the data (could be either a message hash or transaction hash)
    ///@param originalDataHash That should be signed (this is passed to an external validator contract)
    ///@param signatures Signature data that should be verified. 
    ///       Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    function checkForValidSignatures(
        bytes32 dataHash,
        bytes32 originalDataHash,
        bytes calldata signatures
    )
        external
    {

        InternalSignatureStruct memory sigStruct = InternalSignatureStruct(
            OwnerManager(address(this)),
            dataHash,
            originalDataHash,
            signatures,
            false,    // consumeHash needs to be false, as the state should not be changed
            threshold
            );
        checkSignatures(sigStruct);
        
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _rolesList List of roles for the owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256[] calldata _rolesList,
        uint32 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    )
        external
    {
        setupInternal(
            _owners,
            _rolesList,
            _threshold,
            to,
            data,
            fallbackHandler,
            paymentToken,
            payment,
            paymentReceiver);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners
    ///      and then pays the account that submitted the transaction.
    ///      Note: The fees are always transfered, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs for that are indipendent of the transaction execution
    ///        (e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    // solhint-disable-next-line function-max-lines
    function execTransaction( 
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    )
        external
        payable
        returns (bool)
    {
        return execTransactionInternal(
            InternalTxStruct(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                signatures,
                false,
                OwnerManager(address(this))
            ),
            threshold
        );

    }

    ///      This method is only meant for estimation purpose,
    ///      therefore two different protection mechanism against execution in a transaction have been made:
    ///      1.) The method can only be called from the safe itself
    ///      2.) The response is returned with a revert
    ///      When estimating set `from` to the address of the safe.
    ///      Since the `estimateGas` function includes refunds,
    ///      call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        external
        returns (uint256)
    {
        requireAuthorized();
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }


    /// @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
    /// @param hashToApprove The hash that should be marked as approved
    ///        for signatures that are verified by this contract.
    function approveHash(bytes32 hashToApprove)
        external
    {
        require(
            owners[msg.sender] != address(0),
            "Only owners can approve a hash"
        );
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /**
     * @dev Marks a message as signed
     * @param _dataHash bytes 32 data that should be marked as signed on the behalf of address(this)
     */
    function signMessage(
        bytes32 _dataHash
    )
        external
    {
        requireAuthorized();
        bytes32 msgHash = getMessageHash(abi.encodePacked(_dataHash));
        signedMessages[msgHash] = 1;
        emit SignMsg(msgHash);
    }

    /**
     * Implementation of ISignatureValidator (see `interfaces/ISignatureValidator.sol`)
     * @dev Should return whether the signature provided is valid for the provided data.
     *       The save does not implement the interface since `checkSignatures` is not a view method.
     *       The method will not perform any state changes (see parameters of `checkSignatures`)
     * @param _dataHash byte32 data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     * @return a bool upon valid or invalid signature with corresponding _data
     */
    function isValidSignature(
        bytes32 _dataHash,
        bytes calldata _signature
    )
        external
        returns (bytes4)
    {
        bytes32 messageHash = getMessageHash(abi.encodePacked(_dataHash));
        if (_signature.length == 0) {
            require(signedMessages[messageHash] != 0, "Hash not approved");
        } else {
            checkSignatures(InternalSignatureStruct(
                OwnerManager(address(this)),
                messageHash,
                _dataHash,
                _signature,
                false,    // consumeHash needs to be false, as the state should not be changed
                threshold
            ));
        }
        return EIP1271_MAGIC_VALUE;
    }

    /// @dev Returns hash of a message that can be signed by owners.
    /// @param message Message that should be hashed
    /// @return Message hash.
    function getMessageHash(
        bytes memory message
    )
        public
        view
        returns (bytes32)
    {
        bytes32 safeMessageHash = keccak256(
            abi.encode(SAFE_MSG_TYPEHASH, keccak256(message))
        );
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0x01),
                    domainSeparator,
                    safeMessageHash
                )
            );
    }

    /// @dev helper function for the setup of the gnosis-safe
    /// @param _owners List of Safe owners.
    /// @param _rolesList List of roles for the owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setupInternal(
        address[] memory _owners,
        uint256[] memory _rolesList,
        uint32 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    )
        internal
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this)
        );
        setupOwners(_owners, _threshold, _rolesList);
        if (fallbackHandler != address(0)) {
            internalSetFallbackHandler(fallbackHandler);
        }
        // As setupOwners can only be called if the contract has not been initialized
        // we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function
            // (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";
import "./Module.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {

    address internal constant SENTINEL_MODULES = address(0x1);
    mapping (address => address) internal modules;

    event EnabledModule(
        Module indexed module
    );

    event DisabledModule(
        Module indexed module
    );

    event ExecutionFromModuleSuccess(
        address indexed module
    );

    event ExecutionFromModuleFailure(
        address indexed module
    );

    /// @dev Allows to add a module to the list of allowed modules.
    ///      This can only be done via a Safe transaction.
    /// @param module Module to be added to the allowed modules.
    function enableModule(
        Module module
    )
        public
        
    {
        requireAuthorized();

        // Module address cannot be null or sentinel.
        require(
            address(module) != address(0) && address(module) != SENTINEL_MODULES,
            "Invalid module address provided"
        );
        // Module cannot be added twice.
        require(modules[address(module)] == address(0), "Module has already been added");
        modules[address(module)] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = address(module);
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the list of allowed modules.
    ///      This can only be done via a Safe transaction.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(
        Module prevModule,
        Module module
    )
        public
    {
        requireAuthorized();
        // Validate module address and check that it corresponds to module index.
        require(
            address(module) != address(0) && address(module) != SENTINEL_MODULES,
            "Invalid module address provided"
        );
        require(modules[address(prevModule)] == address(module), "Invalid prevModule, module pair provided");
        modules[address(prevModule)] = modules[address(module)];
        modules[address(module)] = address(0);
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
    )
        public
        returns (bool success)
    {
        // Only enabled modules are allowed.
        require(
            msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0),
            "Method can only be called from an enabled module"
        );
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) {
            if (value > 0) {
                emit EthTransferred("", to, value); // safe tx hash will not appeared.
            }
            emit ExecutionFromModuleSuccess(msg.sender);
        } else {
            emit ExecutionFromModuleFailure(msg.sender);
        }
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
    )
        public
        returns (bool success, bytes memory returnData)
    {
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
    function isModuleEnabled(
        Module module
    )
        public
        view
        returns (bool)
    {
        return SENTINEL_MODULES != address(module) && modules[address(module)] != address(0);
    }

    /// @dev Returns array of first 10 modules.
    function getModules()
        public
        view
        returns (address[] memory)
    {
        (address[] memory array,) = getModulesPaginated(SENTINEL_MODULES, 10);
        return array;
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    function getModulesPaginated(
        address start,
        uint256 pageSize
    )
        public
        view
        returns (address[] memory array, address next)
    {
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

    function setupModules(
        address to,
        bytes memory data
    )
        internal
    {
        require(modules[SENTINEL_MODULES] == address(0), "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0)) {
            // Setup has to complete successfully or transaction fails.
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/SelfAuthorized.sol";


/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;
    
    /* solhint-disable */
    fallback()
    external
    {
        // Only calls without value and with data will be forwarded
        if (msg.data.length == 0) {
            return;
        }
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        address handler;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            handler := sload(slot)
        }

        if (handler != address(0)) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                calldatacopy(0, 0, calldatasize())
                let success := call(gas(), handler, 0, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(success, 0) { revert(0, returndatasize()) }
                return(0, returndatasize())
            }
        }
    }
    /* solhint-endable */

    receive()
    external
    payable
    {
        assembly {
            log0(0x0, 0x00)
        }
        
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallbacks calls.
    function setFallbackHandler(
        address handler
    )
        public
    {
        requireAuthorized();
        internalSetFallbackHandler(handler);
    }

    function internalSetFallbackHandler(
        address handler
    )
        internal
    {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "./SelfAuthorized.sol";


/// @title MasterCopy - Base for master copy contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract MasterCopy is SelfAuthorized {

    // masterCopy always needs to be first declared variable,
    // to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;

    event ChangedMasterCopy(
        address masterCopy
    );

    /// @dev Allows to upgrade the contract. This can only be done via a Safe transaction.
    /// @param _masterCopy New contract address.
    function changeMasterCopy(
        address _masterCopy
    )
        public
    {
        requireAuthorized();
        // Master copy address cannot be null.
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
        emit ChangedMasterCopy(_masterCopy);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {

    /// @dev Recovers address who signed the message
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey (
        bytes32 messageHash,
        bytes memory messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read.
    ///        A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    )
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {

    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken (
        address token,
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
       // 0xa9059cbb - keccack("transfer(address,uint256)")
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x1626ba7e;
}


abstract contract ISignatureValidator is ISignatureValidatorConstants {

    /**
    * @dev Should return whether the signature provided is valid for the provided data
    * @param _hash Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    *
    * MUST return the bytes4 magic value 0x1626ba7e when function passes.
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    )
        virtual
        public
        view
        returns (bytes4);

    /**
    * @dev Returns hash of a message that can be signed by owners.
    * @param message Message that should be hashed
    * @return Message hash.
    *
    * This function is not mandatory for EIP-1271 but currently in discussion.
    * https://github.com/ethereum/EIPs/issues/1271#issuecomment-703470820
    */
    function getMessageHash(
        bytes memory message
    )
        virtual
        public
        view
        returns (bytes32);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/SignatureDecoder.sol";
import "../base/OwnerManager.sol";
import "../interfaces/ISignatureValidator.sol";
import "../common/SecuredTokenTransfer.sol";


/// @title Contract that handles the execution and the payment
contract PaymentManager is
    Executor,
    SignatureDecoder,
    ISignatureValidatorConstants,
    SecuredTokenTransfer
{
    struct InternalTxStruct {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        bytes signature;
        bool isModuleTransaction;
        OwnerManager manager;
    }

    struct InternalSignatureStruct{
        OwnerManager manager;
        bytes32 dataHash;
        bytes32 originalDataHash;
        bytes signatures;
        bool consumeHash;
        uint256 threshold;
    }

    //keccak256(
    //    "EIP712Domain(address verifyingContract)"
    //);
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH =
        0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    //keccak256(
    //    "SafeTx(
    //      address to,
    //      uint256 value,
    //      bytes data,
    //      uint8 operation,
    //      uint256 safeTxGas,
    //      uint256 baseGas,
    //      uint256 gasPrice,
    //      address gasToken,
    //      address refundReceiver,
    //      uint256 nonce
    //    )"
    //);
    bytes32 private constant SAFE_TX_TYPEHASH =
        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;
    
    // Mapping to keep track of all hashes (message or transaction) that have been approve by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;
    uint256 public nonce;
    bytes32 public domainSeparator;
    
    event ExecutionFailure(
        bytes32 indexed txHash,
        uint256 payment
    );

    event ExecutionSuccess(
        bytes32 indexed txHash,
        uint256 payment
    );


    /// @dev triggeres a payment-handling for a module
    /// @param gasUsed the amount of gasUsed
    /// @param baseGas Gas costs for that are indipendent of the transaction execution
    ///        (e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @return payment the paid costs   
    function handlePaymentModule(        
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        external
        returns (uint256 payment)
    {
        require(ModuleManager(address(this)).isModuleEnabled(Module(msg.sender)), "not a module");
        return handlePayment(
            gasUsed,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver
        );
    }

    /// @dev handles the token-transfer-functionality for module-transaction
    /// @param token the token to send
    /// @param receiver the reciver of the token-transfer
    /// @param amount the amount of tokens to send
    function transferTokenModule(
        address token,
        address receiver,
        uint256 amount
    )
    external returns (bool)
    {
        require(ModuleManager(address(this)).isModuleEnabled(Module(msg.sender)), "not a module");
        return transferToken(token, receiver, amount);
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param transactionData Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory transactionData,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes memory)
    {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                to,
                value,
                keccak256(transactionData),
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                _nonce
            )
        );
        return abi.encodePacked(
            bytes1(0x19),
            bytes1(0x01),
            domainSeparator,
            safeTxHash
        );
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param transactionData Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory transactionData,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            encodeTransactionData(
                to,
                value,
                transactionData,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                _nonce
            )
        );
    }

    /// @dev executes a transaction
    /// @param txData struct with all the needed transaction-information
    /// @param threshold the thresold of the multisig or module
    // solhint-disable-next-line function-max-lines
    function execTransactionInternal(
        InternalTxStruct memory txData,
        uint256 threshold
    )
        internal
        returns (bool success)
    {

        bytes32 txHash = checkSignatureHelper(
            txData,
            threshold

        );

        uint256 gasUsed = gasleft();
        // If the gasPrice is 0 we assume that nearly all available gas can be used 
        //      (it is always more than safeTxGas)
        // We only substract 2500 (compared to the 3000 before) to ensure that the amount 
        //      passed is still higher than safeTxGas
            success = execute(
                txData.to,
                txData.value,
                txData.data,
                txData.operation,
                txData.gasPrice == 0 ? (gasleft() - 2500) : txData.safeTxGas
            );


        gasUsed = gasUsed - gasleft();
        // We transfer the calculated tx costs to the tx.origin to avoid sending it
        //      to intermediate contracts that have made calls
        uint256 payment = paymentHelper(
            txData,
            gasUsed
        );
        if (success) {
            if (txData.value > 0) {
                emit EthTransferred(txHash, txData.to, txData.value);
            }
            emit ExecutionSuccess(txHash, payment);
        } else {
            emit ExecutionFailure(txHash, payment);
        }
    }

    /// @dev verifies the provided signatures
    /// @param sigStruct InternalSignatureStruct with the needed information
    // solhint-disable-next-line function-max-lines
    function checkSignatures( 
        InternalSignatureStruct memory sigStruct
    )
        internal
    {
        // Load threshold to avoid multiple storage loads
        // Check that a threshold is set
        require(sigStruct.threshold > 0, "Threshold needs to be defined!");

        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;

        require(sigStruct.signatures.length >= (sigStruct.threshold) * 65, "Signatures data too short");

        (v, r, s) = signatureSplit(sigStruct.signatures, 0);

        currentOwner = verifyAndGetOwnerFromSignature(
            v,
            r,
            s,
            sigStruct.dataHash,
            sigStruct.originalDataHash,
            sigStruct.signatures,
            true,
            sigStruct.threshold
        );

        require(sigStruct.manager.checkRole(currentOwner, Enum.Role.Initiator), "initiator must sign first");

        // we are also checking whether the initiator is also an approver
        // if it's an approver his signature will also counts towards the threshold
        // if it's not an approver we have to increase the threshold by one, as the provided signature
        // does not count towards the threshold
        if (!sigStruct.manager.checkRole(currentOwner, Enum.Role.Approver)) {
            sigStruct.threshold++;
        }

        // we have to check again whether the length of the signature matches with the updated threshold
        require(sigStruct.signatures.length >= (sigStruct.threshold) * 65, "missing one signature");

        address initiator = currentOwner;

        for (uint256 i = 1; i < sigStruct.threshold; i++) {
            (v, r, s) = signatureSplit(sigStruct.signatures, i);

            currentOwner = verifyAndGetOwnerFromSignature(
                v,
                r,
                s,
                sigStruct.dataHash,
                sigStruct.originalDataHash,
                sigStruct.signatures,
                sigStruct.consumeHash,
                sigStruct.threshold
            );
            
            require(sigStruct.manager.checkRole(currentOwner, Enum.Role.Approver), "not an approver");
            require(currentOwner > lastOwner, "Signatures order invalid");
            require(currentOwner != initiator, "cannot sign twice as initiator");
            lastOwner = currentOwner;
        }
    }

    /// @dev verifies a signature and calculates the address of an owner based on the provided signature
    /// @param v the v parameter of the signature
    /// @param r the r parameter of the signature
    /// @param s the s parameter of the signature
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash)
    /// @param originalDataHash That should be signed (this is passed to an external validator contract)
    /// @param signatures Signature data that should be verified. 
    //              Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
    /// @param consumeHash Indicates that in case of an approved hash the storage can be freed to save gas
    /// @param _threshold the threshold of the contract
    // solhint-disable-next-line function-max-lines
    function verifyAndGetOwnerFromSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 dataHash,
        bytes32 originalDataHash,
        bytes memory signatures,
        bool consumeHash,
        uint _threshold
    )
        internal
        returns (address currentOwner)
    {

        // If v is 0 then it is a contract signature
        if (v == 0) {
            // When handling contract signatures the address of the contract is encoded into r
            currentOwner = address(uint160(uint256(r)));

            // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
            // This check is not completely accurate, 
            //      since it is possible that more signatures than the threshold are send.
            // Here we only check that the pointer is not pointing inside the part that is being processed
            require(
                uint256(s) >= _threshold * 65, "Invalid contract signature location: inside static part"
            );

            // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
            require(
                uint256(s) + 32 <= signatures.length, "Invalid contract signature location: length not present"
            );

            // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
            uint256 contractSignatureLen;
            // solhint-disable-next-line no-inline-assembly
            assembly {  
                contractSignatureLen := mload(add(add(signatures, s), 0x20))
            }
            require(
                uint256(s) + 32 + contractSignatureLen <= signatures.length,
                "Invalid contract signature location: data not complete"
            );

            // Check signature
            bytes memory contractSignature;
            // solhint-disable-next-line no-inline-assembly
            assembly { 
                // The signature data for contract signatures is appended to the concatenated signatures 
                //      and the offset is stored in s
                contractSignature := add(add(signatures, s), 0x20)
            }
            require(
                ISignatureValidator(currentOwner).isValidSignature(
                    originalDataHash,
                    contractSignature
                    ) == EIP1271_MAGIC_VALUE,
                "Invalid contract signature provided"
            );
            // If v is 1 then it is an approved hash
        } else if (v == 1) {
            // When handling approved hashes the address of the approver is encoded into r
            currentOwner = address(uint160(uint256(r)));
            // Hashes are automatically approved by the sender of the message 
            //      or when they have been pre-approved via a separate transaction
            require(
                msg.sender == currentOwner ||
                    approvedHashes[currentOwner][dataHash] != 0,
                "Hash has not been approved"
            );
                // Hash has been marked for consumption. If this hash was pre-approved free storage
            if (consumeHash && msg.sender != currentOwner) {
                approvedHashes[currentOwner][dataHash] = 0;
            }
        } else if (v > 30) {
            // To support eth_sign and similar we adjust v
            // and hash the messageHash with the Ethereum message prefix before applying ecrecover
            // This line is to support eth_sign method in wallets like metamask 
            //      that don't allow you to sign an arbitrary hash
            // To difference from a regular eth recover you need to add 4 to v and then this method will find an invalid
            // value for v and will know that it should be decoded as a eth_sign
            currentOwner = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)),
                v - 4,
                r,
                s);
        } else {
            // Use ecrecover with the messageHash for EOA signatures
            currentOwner = ecrecover(dataHash, v, r, s);
        }
    }

    /// @dev handles the payment of for a mastercopy
    /// @param gasUsed the amount of gasUsed
    /// @param baseGas Gas costs for that are indipendent of the transaction execution
    ///        (e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        internal
        returns (uint256 payment)
    {   
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
           
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = (gasUsed + baseGas) * (
                gasPrice < tx.gasprice ? gasPrice : tx.gasprice
            );
            // Known issue: https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
            require(
                // solhint-disable-next-line check-send-result
                receiver.send(payment), "Could not pay gas costs with ether");
        } else {
            payment = (gasUsed + baseGas) * gasPrice;
            require(transferToken(gasToken, receiver, payment), "Could not pay gas costs with token");
        }
    }

    /// @dev helper-function for checking the signatures
    /// @param txData the struct with the transaction data
    /// @param threshold the threshold
    function checkSignatureHelper(
         InternalTxStruct memory txData,
        uint256 threshold
    )
        internal 
        returns (bytes32 txHash)
    {
        txHash = getTransactionHash(
            txData.to,
            txData.value,
            txData.data,
            txData.operation,
            txData.safeTxGas,
            txData.baseGas,
            txData.gasPrice,
            txData.gasToken,
            txData.refundReceiver,
            nonce
        );

         // Increase nonce 
        nonce++;
        if(!txData.isModuleTransaction){
            checkSignatures(InternalSignatureStruct(
                txData.manager,
                txHash,
                txHash,
                txData.signature,
                true,
                threshold
            ));
        }     

        // We require some gas to emit the events (at least 2500) after the execution 
        //      and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call 
        //      to counteract potential shortings because of EIP-150
        require(
            gasleft() >= max((txData.safeTxGas * 64 / 63),(txData.safeTxGas + 2500) + 500),
            "Not enough gas to execute safe transaction"
        );
    }

    /// @dev helper-function for the payment
    /// @param txData the transaction-data
    /// @param gasUsed the amount of gas used
    /// @return payment the payment
    function paymentHelper(
        InternalTxStruct memory txData,
        uint256 gasUsed
    )
        internal 
        returns (uint256 payment)
    {
        if (txData.gasPrice > 0) {
            payment = txData.isModuleTransaction ? 
                handlePayment(
                    PaymentManager(address(txData.manager)),
                    gasUsed,
                    txData.baseGas,
                    txData.gasPrice,
                    txData.gasToken,
                    txData.refundReceiver
                )
            : 
                handlePayment(
                    gasUsed,
                    txData.baseGas,
                    txData.gasPrice,
                    txData.gasToken,
                    txData.refundReceiver
                );
        }
    }

    /// @dev returns the maximum of 2 values
    /// @param a the first value
    /// @param b the second value
   function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /// @dev handles the payment of for a module
    /// @param manager the ModuleManager of the Module
    /// @param gasUsed the amount of gasUsed
    /// @param baseGas Gas costs for that are indipendent of the transaction execution
    ///        (e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @return payment the paid costs   
    function handlePayment(
        PaymentManager manager,
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    )
        private
        returns (uint256 payment)
    {

        return manager.handlePaymentModule(gasUsed, baseGas,gasPrice,gasToken,refundReceiver);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ModuleManager.sol";
import "./Module.sol";
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - Manages a set of owners with roles and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
/// @author David Nicholas - <[email protected]>

contract OwnerManager is SelfAuthorized {

    struct ChallengeSettings {
        uint256 challengeInterval;
        uint256 reductionValue;
        uint256 minimumChallangeTime;
    }
    struct Challenge {
        address challenger;
        address nextOwner;
        uint256 interval; // unit: seconds
        uint256 startOfChallenge; // unix epoch
    }
    /// @dev roles will be represent by a bit vector. where the bit for 2^Role-1 being 1 represents
    /// the address having that role and 0 meaning the address does not have that role.

    uint256 internal constant NUMBER_OF_ROLES = 4;
    address internal constant SENTINEL_OWNERS = address(0x1);
    uint256 public constant DEFAULT_CHALLENGE_INTERVAL = 7776000; // seconds == 90 days
    uint256 public constant DEFAULT_REDUCTION_VALUE = 66; // percentage
    uint256 public constant DEFAULT_MINIMUM_CHALLENGE_TIME = 771200; // seconds = 8 days, 
    
    /// @dev the number 128 is pretty close to the limit on how much owners you can add directly 
    /// during deployment / creation of the wallet while still being below the current gasLimit (12.5Mio gas).
    uint256 public constant MAX_THRESHOLD = 128;
    uint256 public constant MAX_CHALLENGES = 128;

    mapping(address => address) public owners;
    uint256 public ownerCount;
    uint256 public threshold;

    mapping(address => uint256) internal ownerRoles;
    mapping(uint256 => uint256) internal roleCount;
    // mapping with joined challenges
    mapping (bytes32 => bool) internal joinedChallengers;

    // owner address => challenge
    mapping(address => Challenge) public challenges;

    // challenger address => challenge settings in seconds
    mapping(address => ChallengeSettings) internal challengeSettings;

    // address => is a successor
    mapping(address => bool) public successors;

    // challenger => challenged owners
    mapping(address => address[]) internal startedChallenges;

    event AddedOwner(
        address owner
    );

    event RemovedOwner(
        address owner
    );

    event ChangedThreshold(
        uint256 threshold
    );

    event AddedRoles(
        address owner,
        uint256 roles
    );

    event RemovedRoles(
        address owner,
        uint256 roles
    ); 

    event RemovedOwnerDuringChallenge(
        address owner
    );

    /// @dev initiate a challenge from a module
    ///      will revert when the sender is not an enabled module
    /// @param sender the address that initiated the challenge
    /// @param owner the owner being challenged
    /// @param nextOwner the designated replacement for the owner
    function initiateChallengeModule(
        address sender,
        address owner,
        address nextOwner
    ) external {
        requireTxFromModule();
        require(startedChallenges[sender].length < MAX_CHALLENGES, "sender challenged too many owners");
        require(!successors[nextOwner], "successor already set");
        (uint256 challengeInterval, ,) = getChallengeSettings(owner);
        // solhint-disable-next-line not-rely-on-time
        challenges[owner] = OwnerManager.Challenge(sender, nextOwner, challengeInterval, block.timestamp);
        successors[nextOwner] = true;

        // keeping track of what challenges have been started
        startedChallenges[sender].push(owner);
    }

    /// @dev joins a challenge as owner
    ///      will revert when the sender is not an enabled module
    /// @param challengedOwner the challenged owner
    /// @param challenger the address that challenged the owner 
    ///        calculation: (keccak256(abi.encodePacked(challenger, startOfChallenge))
    /// @param newInterval the reduced interval
    function joinChallengeModule(
        address challengedOwner,
        bytes32 challenger,
        uint256 newInterval
    )
        external
    {
        requireTxFromModule();
        joinedChallengers[challenger] = true;
        challenges[challengedOwner].interval = newInterval;
    }

    /// @dev removes a challenge from the list
    ///      will revert when the sender is not an enabled module
    /// @param owner the challenged owner
    function removeChallengeFromListModule(
        address owner
    ) external {
        requireTxFromModule();
        removeChallengeFromList(owner);
    }
    
    /// @dev returns whether a challenger has already joined a challenge
    /// @param challengerIdent the identifier of the challenger 
    function hasChallengerJoined(
        bytes32 challengerIdent
    ) 
        external
        view
        returns (bool)
    {
        return joinedChallengers[challengerIdent];
    }

    /// @dev Changes the challenge interval of a challenger
    /// @param challenger The challenger who will get the new interval
    /// @param newInterval The new interval to set
    function changeInterval(
        address challenger,
        uint256 newInterval
    )
        public
    {        
        requireAuthorized();
        require(
            checkRole(challenger, Enum.Role.Challenger),
            "Account is not a challenger"
        );

       setChallengerIntervalInternal(challenger, newInterval);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(
        address prevOwner,
        address owner,
        uint32 _threshold
    )
        public
    {
        requireAuthorized();
        if (checkRole(owner, Enum.Role.Approver)) {
            // Only allow to remove an approver, if threshold can still be reached.
            require(
                roleCount[uint256(Enum.Role.Approver)] - 1 >= _threshold,
                "New approver count needs to be larger than new threshold"
            );
        }

        if (checkRole(owner, Enum.Role.Initiator)) {
            // Only allow to remove an approver, if threshold can still be reached.
            require(
                roleCount[uint256(Enum.Role.Initiator)] - 1 > 0,
                "There must always be at least one initiator"
            );
        }

        // Validate owner address and check that it corresponds to owner index.
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "Invalid owner address provided"
        );

        require(
            owners[prevOwner] == owner,
            "Invalid prevOwner, owner pair provided"
        );

        if (hasRole(ownerRoles[owner], Enum.Role.Challenger)) {
            removeChallenger(owner);
        }
        
        subtractFromRolesCount(ownerRoles[owner]);
        delete ownerRoles[owner];
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);

        assert(ownerCount > 1);
        ownerCount--;

        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) {
            changeThreshold(_threshold);
        }
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    )
        public
    {
        requireAuthorized();
        requireValidOwner(newOwner);
        swapInternal(prevOwner, oldOwner, newOwner);
    }

    /// @dev Removes roles from an owner. This can only be done via safe transaction
    /// @param owner The owner to remove the roles from
    /// @param roles The roles to remove
    function removeRoles(
        address owner,
        uint256 roles
    )
        public
    {
        requireAuthorized();
        requireAsOwner(owner);
        // Only allow to remove an approver if we have more than the threshold
        if (roleCount[uint256(Enum.Role.Approver)] == threshold) {
            require(
                !checkRole(owner, Enum.Role.Approver) || !hasRole(roles, Enum.Role.Approver),
                "The number of approvers must be greater than or equal to the threshold"
            );
        }

        // Don't allow to remove the last initiator
        if (roleCount[uint256(Enum.Role.Initiator)] == 1) {
            require(
                !checkRole(owner, Enum.Role.Initiator) || !hasRole(roles, Enum.Role.Initiator),
                "There must always be an initiator"
            );
        }

        uint256 currentRoles = ownerRoles[owner];
        uint256 newRoles = currentRoles & ~roles;


        if (hasRole(currentRoles, Enum.Role.Challenger)) {
            removeChallenger(owner);
        }
        
        require(newRoles > 0, "Cannot remove all roles from an address");
        ownerRoles[owner] = newRoles;
        subtractFromRolesCount(currentRoles & roles);

        emit RemovedRoles(owner, roles);
    }

    /// @dev Adds roles to an owner. This can only be done via safe transaction.
    /// @param owner The owner to add the roles to
    /// @param roles The roles to add
    function addRoles(
        address owner,
        uint256 roles
    )
        public
    {
        requireAuthorized();

        (uint256 existingInterval, ,) = getChallengeSettings(owner);

        addRolesInternal(owner, roles, existingInterval == 0 ? DEFAULT_CHALLENGE_INTERVAL : existingInterval);
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    /// @param roles New owner's roles
    function addOwnerWithThreshold(
        address owner,
        uint32 _threshold,
        uint256 roles
    )
        public
    {
        requireAuthorized();
        requireValidOwner(owner);
        addOwnerWithThresholdInternal(
            owner,
            _threshold,
            roles,
            DEFAULT_CHALLENGE_INTERVAL
        );
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction
    /// @param owner New owner address
    /// @param _threshold New threshold
    /// @param roles New owner's roles
    /// @param interval The challenge interval to add
    function addChallengerAndOtherRolesWithThreshold(
        address owner,
        uint32 _threshold,
        uint256 roles,
        uint256 interval
    )
        public
    {
        requireAuthorized();
        requireValidOwner(owner);
        require(hasRole(roles, Enum.Role.Challenger), "New owner must be a challenger");
        addOwnerWithThresholdInternal(
            owner,
            _threshold,
            roles,
            interval);
    }
 
    /// @dev Adds a challenge role and other roles to an owner. This can only be done via safe transaction.
    /// @param challenger The owner to add a role to
    /// @param roles The roles to add. The challenge role bit must be set.
    /// @param interval The challenge interval to add
    function addChallengeRoleAndOtherRoles(
        address challenger,
        uint256 roles,
        uint256 interval
    )
        public
    {
        requireAuthorized();
        // Validate that owner is a challenger
        require(hasRole(roles, Enum.Role.Challenger), "role provided must be a challenger");
        addRolesInternal(challenger, roles, interval);
    }
    
    /// @dev chalnges the challenge settings for an owner
    /// @param owner an owner of the multisig-wallet
    /// @param newReductionValue the new reduction-value in percent. Has to be below 100
    /// @param newMinChallengeTime the new minimal challenge time in seconds
    function changeChallengeSettings(
        address owner,
        uint256 newReductionValue,
        uint256 newMinChallengeTime
    )
    public 
    {
        requireAuthorized();
        requireValidOwner(owner);

        ChallengeSettings storage s = challengeSettings[owner];
        require(newReductionValue < 100, "value too high");

        s.reductionValue = newReductionValue;
        s.minimumChallangeTime = newMinChallengeTime;
    }
   
    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @param _threshold New threshold.
    function changeThreshold(
        uint32 _threshold
    )
        public
    {
        requireAuthorized();

        require(
            _threshold <= roleCount[uint256(Enum.Role.Approver)],
            "Threshold cannot exceed owner count"
        );
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        require(_threshold < MAX_THRESHOLD, "Max threshold reached");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    /// @dev Returns if the challenge interval has expired
    /// @param owner The owner who is being challenged
    /// @return Returns if the challenge interval has expired
    function challengeIsActive(
        address owner
    )
        public
        view
        returns (bool)
    {
        uint256 startOfChallenge = challenges[owner].startOfChallenge;
        // solhint-disable-next-line not-rely-on-time
        return startOfChallenge != 0 && block.timestamp - startOfChallenge <= challenges[owner].interval;
    }

    /// @dev Returns whether the given owner has a role
    /// @param owner The owner
    /// @param role The role to check for
    function checkRole(
        address owner,
        Enum.Role role
    )
        public
        view
        returns (bool)
    {
        return hasRole(ownerRoles[owner], role);
    }
    
    /// @dev returns the settings for a challenge
    /// @param owner an owner of the multisig-wallet
    function getChallengeSettings(address owner) 
        public view 
        returns (
            uint256 challengeInterval,
            uint256 reductionValue,
            uint256 minimumChallangeTime
        )
    {

        if(ownerRoles[owner]== 0) {
            return (0,0,0);
        }

        ChallengeSettings memory s = challengeSettings[owner];
            
        challengeInterval = s.challengeInterval != 0 ? s.challengeInterval : DEFAULT_CHALLENGE_INTERVAL;
            
        reductionValue = s.reductionValue != 0 ? s.reductionValue: DEFAULT_REDUCTION_VALUE;

        minimumChallangeTime = s.minimumChallangeTime != 0 ? s.minimumChallangeTime : DEFAULT_MINIMUM_CHALLENGE_TIME;
    }
    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }

    /// @dev Returns the owners who have the provided role
    /// @param role The role to check
    function getOwnersWithRole(
        Enum.Role role
    )
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](roleCount[uint256(role)]);
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];

        while (currentOwner != SENTINEL_OWNERS) {
            if (checkRole(currentOwner, role)) {
                array[index] = currentOwner;
                index++;
            }
            currentOwner = owners[currentOwner];
        }
        return array;
    }

    /// @dev Returns the number of owners who hold the role
    /// @param role The role to select
    /// @return Number role assignements
    function getNumberOfRole(
        Enum.Role role
    )
        public
        view
        returns (uint256)
    {
        return roleCount[uint256(role)];
    }

    /// @dev Gets the roles of the owner
    /// @param owner The account address of the selected owner
    /// @return Roles variable
    function getRoles(
        address owner
    )
        public
        view
        returns (uint256)
    {
        return ownerRoles[owner];
    }
    
    /// @dev Checks if the provided address is an owner
    /// @param owner the potential owner-address
    /// @return true when the address is an owner
    function isOwner(
        address owner
    )
        public
     //   override
        view
        returns (bool)
    {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev calculates the roles-value of a certain role
    /// @param role the role
    /// @return the calculates roles-value
    function calculateRolesValueFromRoleEnum(
        Enum.Role role
    )
        public
        pure
        returns (uint256)
    {
        if (role == Enum.Role.NoRole) {
            return 0;
        }
        uint256 calculatedRole = 2 ** (uint(role)-1);
        assert(calculatedRole < 256);
        return uint256(calculatedRole);
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param _roles The roles given to the owners
    function setupOwners(
        address[] memory _owners,
        uint32 _threshold,
        uint256[] memory _roles
    )
        internal
    {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        assert(threshold == 0);

        // All owners must have a role
        require(_roles.length == _owners.length, "All owners must have a role");

        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;

        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            uint256 roles = _roles[i];
            require(
                owner != address(0) && owner != SENTINEL_OWNERS,
                "Invalid owner address provided"
            );
            // No duplicate owners allowed.
            require(
                ownerRoles[owner] == uint256(0),
                "Duplicate owner address provided"
            );
            // Owner must have at least one role
            require(roles > 0, "Owner does not have a role");

            
            if (hasRole(roles, Enum.Role.Challenger)) {
                setChallengerIntervalInternal(owner, DEFAULT_CHALLENGE_INTERVAL);
            }

            ownerRoles[owner] = roles;
            addToRolesCount(roles);
            owners[currentOwner] = owner;
            currentOwner = owner;
        }

        // Validate the numbers of approvers and threshold
        require(
            _threshold <= roleCount[uint256(Enum.Role.Approver)],
            "Threshold cannot exceed approver count"
        );

        require(
            roleCount[uint256(Enum.Role.Initiator)] > 0,
            "There must be at least one initiator"
        );
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = uint32(_owners.length);
        threshold = _threshold;
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced
    /// @param newOwner New owner address
  function swapInternal(
        address prevOwner,
        address oldOwner,
        address newOwner
    )
        internal
    {
        require(!successors[newOwner], "newOwner is already a successor");

        // No duplicate owners allowed.
        require(ownerRoles[newOwner] == uint256(0), "Address is already an owner");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(
            oldOwner != address(0) && oldOwner != SENTINEL_OWNERS,
            "Invalid owner address provided"
        );
        require(
            owners[prevOwner] == oldOwner,
            "Invalid prevOwner, owner pair provided"
        );

        if (checkRole(oldOwner, Enum.Role.Challenger)) {

            challengeSettings[newOwner] = challengeSettings[oldOwner];
        }
        removeChallenger(oldOwner);

        ownerRoles[newOwner] = ownerRoles[oldOwner];
        ownerRoles[oldOwner] = uint256(Enum.Role.NoRole);

        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);

        // there should never be any challenge for the new owner
        assert(challenges[newOwner].challenger == address(0));

        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev internal add owner
    /// @param owner New owner address
    /// @param _threshold New threshold
    /// @param roles New owner's roles
    /// @param interval The challenge interval to add
    function addOwnerWithThresholdInternal(
        address owner,
        uint32 _threshold,
        uint256 roles,
        uint256 interval
    )
        internal
    {
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "Address is already an owner");
        require(roles > 0, "Owner must have a role");
        require(!successors[owner], "Owner cannot be a successor to an active challenge");

        ownerRoles[owner] = roles;
        addToRolesCount(roles);
   
        if (hasRole(roles, Enum.Role.Challenger)) {
            setChallengerIntervalInternal(owner, interval);
        }

        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) {
            changeThreshold(_threshold);
        }
    }

    /// @dev Adds roles to an owner. This can only be done via safe transaction.
    /// @param owner The owner to add the roles to
    /// @param roles The roles to add
    /// @param interval The challenge interval to add
    function addRolesInternal(
        address owner,
        uint256 roles,
        uint256 interval
    )
        internal
    {   
        requireAsOwner(owner);
        require(roles > 0, "Must provide roles");
        require(roles < 2 ** uint(NUMBER_OF_ROLES - 1), "invalid roles provided");

        uint256 currentRoles = ownerRoles[owner];
        require(currentRoles != roles, "Address has already the required roles");
        ownerRoles[owner] = (roles) | currentRoles;
        addToRolesCount(roles & ~currentRoles);

        if (hasRole(roles, Enum.Role.Challenger)) {
            require(challenges[owner].startOfChallenge == 0, "owner has been challenged");
            setChallengerIntervalInternal(owner, interval);
        }
        
        emit AddedRoles(owner, roles);
    }

    /// @dev Removes a challenge from the challenges mapping
    /// @param owner The owner who is being challenged
    function removeChallengeFromList(
        address owner
    )
        internal
    {

        Challenge storage c = challenges[owner];
        assert(c.startOfChallenge != 0);
        delete successors[c.nextOwner];

        // deleting all challenges
        address[] storage challengedOwners = startedChallenges[c.challenger];
        uint256 ownersLength = challengedOwners.length;
           
        while(ownersLength > 0){
            address ownerToRemove = challengedOwners[ownersLength-1];

            // searching for the challenge
            if(ownerToRemove == owner){
                challengedOwners[ownersLength-1] = challengedOwners[challengedOwners.length-1];
                delete challengedOwners[challengedOwners.length-1];
                challengedOwners.pop();
                break;
            }
            ownersLength--;
        }
        
        delete challenges[owner];

    }

    /// @dev Removes a challenger
    /// @param challenger The address to remove
    function removeChallenger(
        address challenger
    )
        internal
    {
  
        // deleting challenge interval
        delete challengeSettings[challenger];

        // deleting all challenges
        address[] storage challengedOwners = startedChallenges[challenger];
        uint256 ownersLength = challengedOwners.length;

        while(ownersLength > 0){
            address ownerToRemove = challengedOwners[ownersLength-1];
            if (challengeIsActive(ownerToRemove)) {
                emit RemovedOwnerDuringChallenge(ownerToRemove);
            }        
            removeChallengeFromList(ownerToRemove); 
            ownersLength--;
        }
    }

    /// @dev Changes the interval of a challenger
    /// @param challenger The challenger who will get the new interval
    /// @param interval The new interval to set
    function setChallengerIntervalInternal(
        address challenger,
        uint256 interval
    )
        internal
    {
        require(interval > 0, "Invalid challenge interval");
        //challengeIntervals[challenger] = interval;
     //   challengeSettings[challenger].challgenInterval = interval;
        ChallengeSettings storage s = challengeSettings[challenger];
        s.challengeInterval = interval;
    }

    /// @dev checks whether the provided address is an owner
    ///      will revert if not
    /// @notice has to be done as function instead of a modifier to reduce the bytecode
    /// @param owner the address to check
    function requireAsOwner(
        address owner
    )
        internal
        view 
    {
        require(isOwner(owner), "Address must be an owner");
    }

    /// @dev checks whether call came from an enabled module
    ///      will revert if not
    /// @notice has to be done as function instead of a modifier to reduce the bytecode
    function requireTxFromModule() internal view
    {
        require(ModuleManager(address(this)).isModuleEnabled(Module(msg.sender)), "not a module");
    }

    /// @dev Returns if the role combination includes the provided Role right
    function hasRole(
        uint256 roles,
        Enum.Role role
    )
        internal
        pure
        returns (bool)
    {

        // we have to treat NoRole special (role = 0)
        if (role == Enum.Role.NoRole) {
            // non-associated account has no role, so it should return true
            return roles == 0;
        }

        return roles & (uint256(2)**(uint256((role)) - 1)) != 0;
    }
    
    /// @dev checks whether the provided address is a valid address
    ///      will revert if not
    /// @notice has to be done as function instead of a modifier to reduce the bytecode
    /// @param owner the address to check
    function requireValidOwner(
        address owner
    )
        internal
        pure
    {
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "Invalid owner address provided"
        );
    }

    /// @dev Adds to the rolesCount
    /// @param roles the roles to count
    function addToRolesCount(
        uint256 roles
    )
        private
    {
        for (uint256 i = 1; i < NUMBER_OF_ROLES; i++) {
            if ((roles & (2 ** (i - 1)) != 0)) {

                roleCount[i]++;
            }
        }
    }

    /// @dev Subtracts from the rolesCount
    /// @param roles The roles to count
    function subtractFromRolesCount(uint256 roles) private {
        for (uint256 i = 1; i < NUMBER_OF_ROLES; i++) {
            if ((roles & (2 ** (i - 1)) != 0)) {

                roleCount[i]--;
            }
        }
    }


        
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }

    enum Role {
        NoRole,
        Challenger,
        Initiator,
        Approver
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {

    /// @dev checks whether the sender is authorized
    ///      will revert if not
    /// @notice has to be done as function instead of a modifier to reduce the bytecode
    function requireAuthorized()
        public
        view
    {
        require(msg.sender == address(this), "Method can only be called from manager");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/Enum.sol";


/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {

    // Event for Eth value transaction
    // This event is additionally emitted with ExecutionSuccess when value transaction succeeded.
    event EthTransferred(
        bytes32 indexed txHash,
        address indexed to,
        uint256 value
    );

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "../common/MasterCopy.sol";
import "./ModuleManager.sol";


/// @title Module - Base class for modules.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract Module is MasterCopy {

    ModuleManager public manager;
    
    function requireAuthorizedByManager()
        public
        view
    {
        require(msg.sender == address(manager), "Method can only be called from manager");
    
    }
    
    function setManager()
        internal
    {
        // manager can only be 0 at initalization of contract.
        // Check ensures that setup function can only be called once.
        require(address(manager) == address(0), "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}