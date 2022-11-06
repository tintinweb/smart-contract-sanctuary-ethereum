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
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../scw/base/ModuleManager.sol";
import "./SignatureDecoder.sol";
import "../../scw/common/Enum.sol";
// import "hardhat/console.sol";

contract SessionKeyModule is SignatureDecoder {
    string public constant NAME = "Session Key Module";
    string public constant VERSION = "0.1.0";

    struct TokenApproval {
        bool enable;
        uint256 amount;
    }

    struct TransferParams {
        bytes4 methodSignature;
        address to;
        uint256 amount;
    }

    // PermissionParam struct to be used as parameter in createSession method
    struct PermissionParam {
        address whitelistDestination;
        bytes4[] whitelistMethods;
        uint256 tokenAmount;
    }

    // SessionParam struct to be used as parameter in createSession method
    struct SessionParam {
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool enable;
    }

    struct SessionResponse {
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool enable;
        uint256 nonce;
    }

    struct PermissionStorage {
        address[] whitelistDestinations;
        mapping(address => bool) whitelistDestinationMap;
        mapping(address => bytes4[]) whitelistMethods;
        mapping(address => mapping(bytes4 => bool)) whitelistMethodsMap;
        mapping(address => TokenApproval) tokenApprovals;
    }

    struct Session {
        address smartAccount;
        address sessionKey;
        uint256 startTimestamp;
        uint256 nonce;
        uint256 endTimestamp;
        bool enable;
        PermissionStorage permission;
    }

    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    bytes32 public constant ALLOWANCE_TRANSFER_TYPEHASH =
        keccak256(
            "SessionTransaction(address to,uint256 amount,bytes data,uint256 nonce)"
        );

    mapping(address => Session) internal sessionMap;

    function createSession(
        address sessionKey,
        PermissionParam[] calldata permissions,
        SessionParam calldata sessionParam
    ) external {
        require(
            !sessionMap[sessionKey].enable,
            "Session for key is already enabled"
        );
        Session storage _session = sessionMap[sessionKey];
        _session.enable = true;
        _session.nonce = 0;
        _session.startTimestamp = sessionParam.startTimestamp;
        _session.endTimestamp = sessionParam.endTimestamp;
        _session.sessionKey = sessionKey;
        _session.smartAccount = msg.sender;

        address[] memory whitelistAddresses = new address[](permissions.length);
        for (uint256 index = 0; index < permissions.length; index++) {
            PermissionParam memory permission = permissions[index];
            address whitelistedDestination = permission.whitelistDestination;
            whitelistAddresses[index] = whitelistedDestination;
            _session.permission.whitelistDestinationMap[
                whitelistedDestination
            ] = true;

            _session.permission.whitelistMethods[
                whitelistedDestination
            ] = permission.whitelistMethods;

            for (
                uint256 methodIndex = 0;
                methodIndex < permission.whitelistMethods.length;
                methodIndex++
            ) {
                _session.permission.whitelistMethodsMap[whitelistedDestination][
                        permission.whitelistMethods[methodIndex]
                    ] = true;
            }

            if (permission.tokenAmount > 0) {
                _session.permission.tokenApprovals[
                    whitelistedDestination
                ] = TokenApproval({
                    enable: true,
                    amount: permission.tokenAmount
                });
            }
        }
        _session.permission.whitelistDestinations = whitelistAddresses;
    }

    function getSessionInfo(address sessionKey)
        public
        view
        returns (SessionResponse memory sessionInfo)
    {
        Session storage session = sessionMap[sessionKey];
        sessionInfo = SessionResponse({
            startTimestamp: session.startTimestamp,
            endTimestamp: session.endTimestamp,
            enable: session.enable,
            nonce: session.nonce
        });
    }

    function getWhitelistDestinations(address sessionKey)
        public
        view
        returns (address[] memory)
    {
        Session storage session = sessionMap[sessionKey];
        return session.permission.whitelistDestinations;
    }

    function getWhitelistMethods(
        address sessionKey,
        address whitelistDestination
    ) public view returns (bytes4[] memory) {
        Session storage session = sessionMap[sessionKey];
        return session.permission.whitelistMethods[whitelistDestination];
    }

    function getTokenPermissions(address sessionKey, address token)
        public
        view
        returns (TokenApproval memory tokenApproval)
    {
        Session storage session = sessionMap[sessionKey];
        return session.permission.tokenApprovals[token];
    }

    function getSelector(bytes calldata _data) public pure returns (bytes4) {
        bytes4 selector = bytes4(_data[0 : 4]);
        return selector;
    }

    function executeTransaction(
        address _sessionKey,
        address payable _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata signature
    ) external returns (bool success) {
        Session storage session = sessionMap[_sessionKey];
        require(session.enable, "Session is not active");
        require(
            session.startTimestamp <= block.timestamp,
            "Session has not yet started"
        );
        require(session.endTimestamp >= block.timestamp, "Session has expired");

        bytes memory transactionDataHash = generateTransactionHashData(
            _to,
            _value,
            _data,
            session.nonce
        );
        checkSignature(_sessionKey, signature, transactionDataHash);
        session.nonce += 1;

        require(
            session.permission.whitelistDestinationMap[_to],
            "Destination addres is not whitelisted"
        );

        bytes4 functionSelector = getSelector(_data);
        // console.log("function selector %s", functionSelector);

        require(
            session.permission.whitelistMethodsMap[_to][functionSelector],
            "Target method is not whitelisted"
        );

        // Check if function selector is of ERC20 transfer method
        if (functionSelector == bytes4(0xa9059cbb)) {
            (, uint256 amount) = decodeTransferData(_data);
            TokenApproval memory tokenApproval = session
                .permission
                .tokenApprovals[_to];
            require(
                tokenApproval.enable && tokenApproval.amount >= amount,
                "Approved amount less than current amount"
            );
        }

        // TODO: Check native value amount
        ModuleManager moduleManager = ModuleManager(session.smartAccount);
        return
            moduleManager.execTransactionFromModule(
                _to,
                _value,
                _data,
                Enum.Operation.Call
            );
    }

    function decodeTransferData(bytes calldata data)
        public
        pure
        returns (address to, uint256 amount)
    {
        (to, amount) = abi.decode(data[4:], (address, uint256));
    }

    function generateTransactionHashData(
        address payable _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _nonce
    ) private view returns (bytes memory) {
        uint256 chainId = getChainId();
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, this)
        );
        bytes32 transferHash = keccak256(
            abi.encode(
                ALLOWANCE_TRANSFER_TYPEHASH,
                _to,
                _amount,
                keccak256(_data),
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                transferHash
            );
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function recoverSignature(
        bytes memory signature,
        bytes memory transferHashData
    ) private view returns (address owner) {
        // If there is no signature data msg.sender should be used
        if (signature.length == 0) return msg.sender;
        // Check that the provided signature data is as long as 1 encoded ecsda signature
        require(signature.length == 65, "signatures.length == 65");
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(signature, 0);
        // If v is 0 then it is a contract signature
        if (v == 0) {
            revert("Contract signatures are not supported by this module");
        } else if (v == 1) {
            // If v is 1 we also use msg.sender, this is so that we are compatible to the GnosisSafe signature scheme
            owner = msg.sender;
        } else if (v > 30) {
            // To support eth_sign and similar we adjust v and hash the transferHashData with the Ethereum message prefix before applying ecrecover
            owner = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(transferHashData)
                    )
                ),
                v - 4,
                r,
                s
            );
        } else {
            // Use ecrecover with the messageHash for EOA signatures
            owner = ecrecover(keccak256(transferHashData), v, r, s);
        }
        // 0 for the recovered owner indicates that an error happened.
        require(owner != address(0), "owner != address(0)");
    }

    function checkSignature(
        address sessionKey,
        bytes memory signature,
        bytes memory transactionDataHash
    ) private view {
        address signer = recoverSignature(signature, transactionDataHash);
        require(signer == sessionKey, "Signature mismatch");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev Recovers address who signed the message
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey(
        bytes32 messageHash,
        bytes memory messageSignature,
        uint256 pos
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
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
        // solium-disable-next-line security/no-inline-assembly
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

import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
contract Executor {
    // Could add a flag fromEntryPoint for AA txn
    event ExecutionFailure(address to, uint256 value, bytes data, Enum.Operation operation, uint256 txGas);
    event ExecutionSuccess(address to, uint256 value, bytes data, Enum.Operation operation, uint256 txGas);

    // Could add a flag fromEntryPoint for AA txn
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
        // Emit events here..
        if (success) emit ExecutionSuccess(to, value, data, operation, txGas);
        else emit ExecutionFailure(to, value, data, operation, txGas);
    }
    
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