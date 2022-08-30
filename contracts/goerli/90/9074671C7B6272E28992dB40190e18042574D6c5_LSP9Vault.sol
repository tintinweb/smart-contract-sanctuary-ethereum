// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

// modules
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";
import {ERC725} from "@erc725/smart-contracts/contracts/ERC725.sol";
import {LSP9VaultCore, ClaimOwnership} from "./LSP9VaultCore.sol";

// constants
import {_INTERFACEID_LSP1} from "../LSP1UniversalReceiver/LSP1Constants.sol";
import {
    _INTERFACEID_LSP9,
    _LSP9_SUPPORTED_STANDARDS_KEY,
    _LSP9_SUPPORTED_STANDARDS_VALUE
} from "../LSP9Vault/LSP9Constants.sol";

/**
 * @title Implementation of LSP9Vault built on top of ERC725, LSP1UniversalReceiver
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Could be owned by a UniversalProfile and able to register received asset with UniversalReceiverDelegateVault
 */
contract LSP9Vault is LSP9VaultCore {
    /**
     * @notice Sets the owner of the contract and sets the SupportedStandards:LSP9Vault key
     * @param newOwner the owner of the contract
     */
    constructor(address newOwner) {
        OwnableUnset._setOwner(newOwner);

        // set key SupportedStandards:LSP9Vault
        _setData(_LSP9_SUPPORTED_STANDARDS_KEY, _LSP9_SUPPORTED_STANDARDS_VALUE);

        _notifyVaultReceiver(newOwner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The interface for ERC725Y General data key/value store
 * @dev ERC725Y provides the ability to set arbitrary data key/value pairs that can be changed over time
 * It is intended to standardise certain data key/value pairs to allow automated read and writes
 * from/to the contract storage
 */
interface IERC725Y is IERC165 {
    /**
     * @notice Emitted when data at a key is changed
     * @param dataKey The data key which value is set
     */
    event DataChanged(bytes32 indexed dataKey);

    /**
     * @notice Gets singular data at a given `dataKey`
     * @param dataKey The key which value to retrieve
     * @return dataValue The data stored at the key
     */
    function getData(bytes32 dataKey) external view returns (bytes memory dataValue);

    /**
     * @notice Gets array of data for multiple given keys
     * @param dataKeys The array of keys which values to retrieve
     * @return dataValues The array of data stored at multiple keys
     */
    function getData(bytes32[] memory dataKeys) external view returns (bytes[] memory dataValues);

    /**
     * @notice Sets singular data for a given `dataKey`
     * @param dataKey The key to retrieve stored value
     * @param dataValue The value to set
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32 dataKey, bytes memory dataValue) external;

    /**
     * @param dataKeys The array of data keys for values to set
     * @param dataValues The array of values to set
     * @dev Sets array of data for multiple given `dataKeys`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory dataKeys, bytes[] memory dataValues) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OwnableUnset
 * @dev modified version of OpenZeppelin implementation, where:
 * - _setOwner(address) function is internal, so this function can be used in constructor
 * of contracts implementation (instead of using transferOwnership(address)
 * - the contract does not inherit from Context contract
 */
abstract contract OwnableUnset {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Changes the owner if `newOwner` and oldOwner are different
     * This pattern is useful in inheritance.
     */
    function _setOwner(address newOwner) internal virtual {
        if (newOwner != owner()) {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// modules
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {OwnableUnset} from "./custom/OwnableUnset.sol";
import {ERC725XCore} from "./ERC725XCore.sol";
import {ERC725YCore} from "./ERC725YCore.sol";

// constants
import {_INTERFACEID_ERC725X, _INTERFACEID_ERC725Y} from "./constants.sol";

/**
 * @title ERC725 bundle
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Bundles ERC725X and ERC725Y together into one smart contract
 */
contract ERC725 is ERC725XCore, ERC725YCore {
    /**
     * @notice Sets the owner of the contract
     * @param newOwner the owner of the contract
     */
    constructor(address newOwner) {
        OwnableUnset._setOwner(newOwner);
    }

    // NOTE this implementation has not by default: receive() external payable {}

    /* Overrides functions */

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC725XCore, ERC725YCore)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_ERC725X ||
            interfaceId == _INTERFACEID_ERC725Y ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {ILSP1UniversalReceiver} from "../LSP1UniversalReceiver/ILSP1UniversalReceiver.sol";
import {
    ILSP1UniversalReceiverDelegate
} from "../LSP1UniversalReceiver/ILSP1UniversalReceiverDelegate.sol";

// libraries
import {ERC165Checker} from "../Custom/ERC165Checker.sol";

// modules
import {ERC725XCore} from "@erc725/smart-contracts/contracts/ERC725XCore.sol";
import {ERC725YCore} from "@erc725/smart-contracts/contracts/ERC725YCore.sol";
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";
import {ClaimOwnership} from "../Custom/ClaimOwnership.sol";

// constants
import {_INTERFACEID_CLAIM_OWNERSHIP} from "../Custom/IClaimOwnership.sol";
import {
    _INTERFACEID_LSP1,
    _INTERFACEID_LSP1_DELEGATE,
    _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
} from "../LSP1UniversalReceiver/LSP1Constants.sol";
import {
    _INTERFACEID_LSP9,
    _TYPEID_LSP9_VAULTRECIPIENT,
    _TYPEID_LSP9_VAULTSENDER
} from "./LSP9Constants.sol";

/**
 * @title Core Implementation of LSP9Vault built on top of ERC725, LSP1UniversalReceiver
 * @author Fabian Vogelsteller, Yamen Merhi, Jean Cavallera
 * @dev Could be owned by a UniversalProfile and able to register received asset with UniversalReceiverDelegateVault
 */
contract LSP9VaultCore is ERC725XCore, ERC725YCore, ClaimOwnership, ILSP1UniversalReceiver {
    /**
     * @notice Emitted when receiving native tokens
     * @param sender The address of the sender
     * @param value The amount of value sent
     */
    event ValueReceived(address indexed sender, uint256 indexed value);

    // modifiers

    /**
     * @dev Modifier restricting the call to the owner of the contract and the UniversalReceiverDelegate
     */
    modifier onlyAllowed() {
        if (msg.sender != owner()) {
            address universalReceiverAddress = address(
                bytes20(_getData(_LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY))
            );
            require(
                ERC165Checker.supportsERC165Interface(msg.sender, _INTERFACEID_LSP1_DELEGATE) &&
                    msg.sender == universalReceiverAddress,
                "Only Owner or Universal Receiver Delegate allowed"
            );
        }
        _;
    }

    // public functions

    /**
     * @dev Emits an event when receiving native tokens
     */
    fallback() external payable virtual {
        if (msg.value != 0) emit ValueReceived(msg.sender, msg.value);
    }

    // ERC165

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC725XCore, ERC725YCore)
        returns (bool)
    {
        return
            interfaceId == _INTERFACEID_LSP9 ||
            interfaceId == _INTERFACEID_LSP1 ||
            interfaceId == _INTERFACEID_CLAIM_OWNERSHIP ||
            super.supportsInterface(interfaceId);
    }

    // ERC173 - Modified ClaimOwnership

    /**
     * @dev Sets the pending owner
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override(ClaimOwnership, OwnableUnset)
        onlyOwner
    {
        ClaimOwnership._transferOwnership(newOwner);
    }

    /**
     * @dev Transfer the ownership and notify the vault sender and vault receiver
     */
    function claimOwnership() public virtual override {
        address previousOwner = owner();

        _claimOwnership();

        _notifyVaultSender(previousOwner);
        _notifyVaultReceiver(msg.sender);
    }

    // ERC725

    /**
     * @inheritdoc IERC725Y
     * @dev Sets data as bytes in the vault storage for a single key.
     * SHOULD only be callable by the owner of the contract set via ERC173
     * and the UniversalReceiverDelegate
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32 dataKey, bytes memory dataValue) public virtual override onlyAllowed {
        _setData(dataKey, dataValue);
    }

    /**
     * @inheritdoc IERC725Y
     * @dev Sets array of data at multiple given `key`
     * SHOULD only be callable by the owner of the contract set via ERC173
     * and the UniversalReceiverDelegate
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory dataKeys, bytes[] memory dataValues)
        public
        virtual
        override
        onlyAllowed
    {
        require(dataKeys.length == dataValues.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            _setData(dataKeys[i], dataValues[i]);
        }
    }

    // LSP1

    /**
     * @notice Triggers the UniversalReceiver event when this function gets executed successfully.
     * @dev Forwards the call to the UniversalReceiverDelegate if set.
     * @param typeId The type of call received.
     * @param data The data received.
     */
    function universalReceiver(bytes32 typeId, bytes calldata data)
        public
        payable
        virtual
        override
        returns (bytes memory returnValue)
    {
        bytes memory lsp1DelegateValue = _getData(_LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY);

        if (lsp1DelegateValue.length >= 20) {
            address universalReceiverDelegate = address(bytes20(lsp1DelegateValue));

            if (
                ERC165Checker.supportsERC165Interface(
                    universalReceiverDelegate,
                    _INTERFACEID_LSP1_DELEGATE
                )
            ) {
                returnValue = ILSP1UniversalReceiverDelegate(universalReceiverDelegate)
                    .universalReceiverDelegate(msg.sender, msg.value, typeId, data);
            }
        }
        emit UniversalReceiver(msg.sender, msg.value, typeId, returnValue, data);
    }

    // internal functions

    /**
     * @dev Calls the universalReceiver function of the sender if supports LSP1 InterfaceId
     */
    function _notifyVaultSender(address sender) internal virtual {
        if (ERC165Checker.supportsERC165Interface(sender, _INTERFACEID_LSP1)) {
            ILSP1UniversalReceiver(sender).universalReceiver(_TYPEID_LSP9_VAULTSENDER, "");
        }
    }

    /**
     * @dev Calls the universalReceiver function of the recipient if supports LSP1 InterfaceId
     */
    function _notifyVaultReceiver(address receiver) internal virtual {
        if (ERC165Checker.supportsERC165Interface(receiver, _INTERFACEID_LSP1)) {
            ILSP1UniversalReceiver(receiver).universalReceiver(_TYPEID_LSP9_VAULTRECIPIENT, "");
        }
    }

    /**
     * @dev Will return unchecked incremented uint256
     *      can be used to save gas when iterating over loops
     */
    function _uncheckedIncrement(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP1 = 0x6bb56a14;
bytes4 constant _INTERFACEID_LSP1_DELEGATE = 0xa245bbda;

// --- ERC725Y Keys

// keccak256('LSP1UniversalReceiverDelegate')
bytes32 constant _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY = 0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP9 = 0x8c1d44f6;

// --- ERC725Y Keys

// bytes10(keccak256('SupportedStandards')) + bytes2(0) + bytes20(keccak256('LSP9Vault'))
bytes32 constant _LSP9_SUPPORTED_STANDARDS_KEY = 0xeafec4d89fa9619884b600007c0334a14085fefa8b51ae5a40895018882bdb90;

// bytes4(keccak256('LSP9Vault'))
bytes constant _LSP9_SUPPORTED_STANDARDS_VALUE = hex"7c0334a1";

// --- Vault Hooks

// keccak256("LSP9VaultSender")
bytes32 constant _TYPEID_LSP9_VAULTSENDER = 0x3ca9f769340018257ac15b3a00e502e8fb730d66086f774210f84d0205af31e7;

// keccak256("LSP9VaultRecipient")
bytes32 constant _TYPEID_LSP9_VAULTRECIPIENT = 0x09aaf55960715d8d86b57af40be36b0bfd469c9a3643445d8c65d39e27b4c56f;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC725X} from "./interfaces/IERC725X.sol";

// libraries
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// modules
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {OwnableUnset} from "./custom/OwnableUnset.sol";

// constants
// prettier-ignore
import {
    _INTERFACEID_ERC725X,
    OPERATION_CALL, 
    OPERATION_DELEGATECALL, 
    OPERATION_STATICCALL, 
    OPERATION_CREATE, 
    OPERATION_CREATE2
} from "./constants.sol";

/**
 * @title Core implementation of ERC725 X executor
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Implementation of a contract module which provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall` as well creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
abstract contract ERC725XCore is OwnableUnset, ERC165, IERC725X {
    /* Public functions */

    /**
     * @inheritdoc IERC725X
     */
    function execute(
        uint256 operation,
        address to,
        uint256 value,
        bytes calldata data
    ) public payable virtual override onlyOwner returns (bytes memory result) {
        uint256 txGas = gasleft();

        // CALL
        if (operation == OPERATION_CALL) {
            require(address(this).balance >= value, "ERC725X: insufficient balance for call");

            result = executeCall(to, value, data, txGas);

            emit Executed(operation, to, value, bytes4(data));

            // STATICCALL
        } else if (operation == OPERATION_STATICCALL) {
            require(value == 0, "ERC725X: cannot transfer value with operation STATICCALL");

            result = executeStaticCall(to, data, txGas);

            emit Executed(operation, to, value, bytes4(data));

            // DELEGATECALL
            // WARNING!
            // delegatecall is a dangerous operation type!
            //
            // delegate allows to call another deployed contract and use its functions
            // to update the state of the current calling contract
            //
            // this can lead to unexpected behaviour on the contract storage, such as:
            //
            // - updating any state variables (even if these are protected)
            // - update the contract owner
            // - run selfdestruct in the context of this contract
            //
            // use with EXTRA CAUTION
        } else if (operation == OPERATION_DELEGATECALL) {
            require(value == 0, "ERC725X: cannot transfer value with operation DELEGATECALL");

            result = executeDelegateCall(to, data, txGas);

            emit Executed(operation, to, value, bytes4(data));

            // CREATE
        } else if (operation == OPERATION_CREATE) {
            require(
                to == address(0),
                "ERC725X: CREATE operations require the receiver address to be empty"
            );
            require(address(this).balance >= value, "ERC725X: insufficient balance for call");

            address contractAddress = performCreate(value, data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(operation, contractAddress, value);

            // CREATE2
        } else if (operation == OPERATION_CREATE2) {
            require(
                to == address(0),
                "ERC725X: CREATE operations require the receiver address to be empty"
            );
            require(address(this).balance >= value, "ERC725X: insufficient balance for call");

            bytes32 salt = BytesLib.toBytes32(data, data.length - 32);
            bytes memory bytecode = BytesLib.slice(data, 0, data.length - 32);

            address contractAddress = Create2.deploy(value, salt, bytecode);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(operation, contractAddress, value);
        } else {
            revert("Wrong operation type");
        }
    }

    /* Internal functions */

    /**
     * @dev perform call using operation 0
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which call is executed
     * @param value The value to be sent with the call
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing call
     * @return result The data from the call
     */
    function executeCall(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory result) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = to.call{gas: txGas, value: value}(data);

        result = Address.verifyCallResult(success, returnData, "ERC725X: Unknow Error");
    }

    /**
     * @dev perform staticcall using operation 3
     * @param to The address on which staticcall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing staticcall
     * @return result The data from the call
     */
    function executeStaticCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bytes memory result) {
        (bool success, bytes memory returnData) = to.staticcall{gas: txGas}(data);

        result = Address.verifyCallResult(success, returnData, "ERC725X: Unknow Error");
    }

    /**
     * @dev perform delegatecall using operation 4
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/base/Executor.sol
     *
     * @param to The address on which delegatecall is executed
     * @param data The data to be sent with the call
     * @param txGas The amount of gas for performing delegatecall
     * @return result The data from the call
     */
    function executeDelegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bytes memory result) {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = to.delegatecall{gas: txGas}(data);

        result = Address.verifyCallResult(success, returnData, "ERC725X: Unknow Error");
    }

    /**
     * @dev perform contract creation using operation 1
     * Taken from GnosisSafe: https://github.com/gnosis/safe-contracts/blob/main/contracts/libraries/CreateCall.sol
     *
     * @param value The value to be sent to the contract created
     * @param deploymentData The contract bytecode to deploy
     * @return newContract The address of the contract created
     */
    function performCreate(uint256 value, bytes memory deploymentData)
        internal
        returns (address newContract)
    {
        require(deploymentData.length != 0, "no contract bytecode provided");

        // solhint-disable no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }

        require(newContract != address(0), "Could not deploy contract");
    }

    /* Overrides functions */

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == _INTERFACEID_ERC725X || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC725Y} from "./interfaces/IERC725Y.sol";

// libraries
import {GasLib} from "./utils/GasLib.sol";

// modules
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {OwnableUnset} from "./custom/OwnableUnset.sol";

// constants
import {_INTERFACEID_ERC725Y} from "./constants.sol";

/**
 * @title Core implementation of ERC725Y General data key/value store
 * @author Fabian Vogelsteller <[email protected]>
 * @dev Contract module which provides the ability to set arbitrary data key/value pairs that can be changed over time
 * It is intended to standardise certain data key/value pairs to allow automated read and writes
 * from/to the contract storage
 */
abstract contract ERC725YCore is OwnableUnset, ERC165, IERC725Y {
    /**
     * @dev Map the dataKeys to their dataValues
     */
    mapping(bytes32 => bytes) internal store;

    /* Public functions */
    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32 dataKey)
        public
        view
        virtual
        override
        returns (bytes memory dataValue)
    {
        dataValue = _getData(dataKey);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function getData(bytes32[] memory dataKeys)
        public
        view
        virtual
        override
        returns (bytes[] memory dataValues)
    {
        dataValues = new bytes[](dataKeys.length);

        for (uint256 i = 0; i < dataKeys.length; i = GasLib.uncheckedIncrement(i)) {
            dataValues[i] = _getData(dataKeys[i]);
        }

        return dataValues;
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32 dataKey, bytes memory dataValue) public virtual override onlyOwner {
        _setData(dataKey, dataValue);
    }

    /**
     * @inheritdoc IERC725Y
     */
    function setData(bytes32[] memory dataKeys, bytes[] memory dataValues)
        public
        virtual
        override
        onlyOwner
    {
        require(dataKeys.length == dataValues.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < dataKeys.length; i = GasLib.uncheckedIncrement(i)) {
            _setData(dataKeys[i], dataValues[i]);
        }
    }

    /* Internal functions */

    function _getData(bytes32 dataKey) internal view virtual returns (bytes memory dataValue) {
        return store[dataKey];
    }

    function _setData(bytes32 dataKey, bytes memory dataValue) internal virtual {
        store[dataKey] = dataValue;
        emit DataChanged(dataKey);
    }

    /* Overrides functions */

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == _INTERFACEID_ERC725Y || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// >> ERC165 INTERFACE IDs

// ERC725 - Smart Contract based Account
bytes4 constant _INTERFACEID_ERC725X = 0x44c028fe;
bytes4 constant _INTERFACEID_ERC725Y = 0x714df77c;

// >> ERC725X OPERATIONS TYPES
uint256 constant OPERATION_CALL = 0;
uint256 constant OPERATION_CREATE = 1;
uint256 constant OPERATION_CREATE2 = 2;
uint256 constant OPERATION_STATICCALL = 3;
uint256 constant OPERATION_DELEGATECALL = 4;

// ERC725Y overloaded function selectors
bytes4 constant SETDATA_SELECTOR = bytes4(keccak256("setData(bytes32,bytes)"));
bytes4 constant SETDATA_ARRAY_SELECTOR = bytes4(keccak256("setData(bytes32[],bytes[])"));

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title The interface for ERC725X General executor
 * @dev ERC725X provides the ability to call arbitrary functions at any other smart contract and itself,
 * including using `delegatecall`, `staticcall`, as well as creating contracts using `create` and `create2`
 * This is the basis for a smart contract based account system, but could also be used as a proxy account system
 */
interface IERC725X is IERC165 {
    /**
     * @notice Emitted when a contract is created
     * @param operation The operation used to create a contract
     * @param contractAddress The created contract address
     * @param value The amount of native tokens (in Wei) sent to the created contract address
     */
    event ContractCreated(
        uint256 indexed operation,
        address indexed contractAddress,
        uint256 indexed value
    );

    /**
     * @notice Emitted when a contract executed.
     * @param operation The operation used to execute a contract
     * @param to The address where the call is executed
     * @param value The amount of native tokens transferred with the call (in Wei).
     * @param selector The first 4 bytes (= function selector) of the data sent with the call
     */
    event Executed(
        uint256 indexed operation,
        address indexed to,
        uint256 indexed value,
        bytes4 selector
    );

    /**
     * @param operationType The operation to execute: CALL = 0 CREATE = 1 CREATE2 = 2 STATICCALL = 3 DELEGATECALL = 4
     * @param to The smart contract or address to interact with, `to` will be unused if a contract is created (operation 1 and 2)
     * @param value The amount of native tokens to transfer (in Wei).
     * @param data The call data, or the bytecode of the contract to deploy
     * @dev Executes any other smart contract.
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {Executed} event, when a call is executed under `operationType` 0, 3 and 4
     * Emits a {ContractCreated} event, when a contract is created under `operationType` 1 and 2
     */
    function execute(
        uint256 operationType,
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Library to add all efficient functions that could get repeated.
 */
library GasLib {
    /**
     * @dev Will return unchecked incremented uint256
     */
    function uncheckedIncrement(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for LSP1UniversalReceiver
 * @dev LSP1UniversalReceiver allows to receive arbitrary messages and to be informed when assets are sent or received
 */
interface ILSP1UniversalReceiver {
    /**
     * @notice Emitted when the universalReceiver function is succesfully executed
     * @param from The address calling the universalReceiver function
     * @param value The amount sent to the universalReceiver function
     * @param typeId The hash of a specific standard or a hook
     * @param returnedValue The return value of universalReceiver function
     * @param receivedData The arbitrary data passed to universalReceiver function
     */
    event UniversalReceiver(
        address indexed from,
        uint256 value,
        bytes32 indexed typeId,
        bytes indexed returnedValue,
        bytes receivedData
    );

    /**
     * @param typeId The hash of a specific standard or a hook
     * @param data The arbitrary data received with the call
     * @dev Emits an event when it's succesfully executed
     *
     * Call the universalReceiverDelegate function in the UniversalReceiverDelegate (URD) contract, if the address of the URD
     * was set as a value for the `_UniversalReceiverKey` in the account key/value value store of the same contract implementing
     * the universalReceiver function and if the URD contract has the LSP1UniversalReceiverDelegate Interface Id registred using ERC165
     *
     * Emits a {UniversalReceiver} event
     */
    function universalReceiver(bytes32 typeId, bytes calldata data)
        external
        payable
        returns (bytes memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for LSP1UniversalReceiverDelegate
 * @dev LSP1UniversalReceiverDelegate allows for an external universal receiver smart contract,
 * that is the delegate of the initial universal receiver
 */
interface ILSP1UniversalReceiverDelegate {
    /**
     * @dev Get called by the universalReceiver function, can be customized to have a specific logic
     * @param caller The address calling the universalReceiver function
     * @param value The amount sent to the universalReceiver function
     * @param typeId The hash of a specific standard or a hook
     * @param data The arbitrary data received with the call
     * @return result Any useful data could be returned
     */
    function universalReceiverDelegate(
        address caller,
        uint256 value,
        bytes32 typeId,
        bytes memory data
    ) external returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

// This contract is a modified version of OpenZeppelin implementation, where we modify the visibility of
// `supportsERC165Interface`, which check the given interfaceId, to internal and to be used in contract implementations,
// instead of `supportsInterface` to save gas, as the latter check for 3 interfaceIds; InterfaceId of ERC165, 0xffffffff
// and the given interfaceId.

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool)
    {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165Interface(address account, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(
            IERC165.supportsInterface.selector,
            interfaceId
        );
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (uint256)) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract is a modified version of the OwnableUnset implementation, where we transfer Ownership as a 2 step
// process, this allows to prevent for mistakes during ownership transfer,and so prevent control of a contract from
// potentially being lost forever.

// interfaces
import {IClaimOwnership} from "./IClaimOwnership.sol";

// modules
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";

abstract contract ClaimOwnership is IClaimOwnership, OwnableUnset {
    address public override pendingOwner;

    function claimOwnership() public virtual override {
        _claimOwnership();
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _transferOwnership(newOwner);
    }

    function _claimOwnership() internal virtual {
        require(msg.sender == pendingOwner, "OwnableClaim: caller is not the pendingOwner");
        _setOwner(pendingOwner);
        pendingOwner = address(0);
    }

    function _transferOwnership(address newOwner) internal virtual {
        pendingOwner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes4 constant _INTERFACEID_CLAIM_OWNERSHIP = 0xd225f160;

interface IClaimOwnership {
    function pendingOwner() external view returns (address);

    function claimOwnership() external;
}