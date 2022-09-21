// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/access/Ownable.sol";
import "../base/Singleton.sol";
import "../base/StacktGuardManager.sol";

contract StacktOperatorGuard is Singleton, BaseGuard, Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error Unauthorized();
    error AlreadyInitialized();
    error AlreadyAnOperator();
    error StacktWalletAddressAlreadySet();
    error InvalidStacktWalletAddress();
    error InvalidOperatorAddress(address);
    error InvalidPreviosOperatorAddress();
    error NotAnOperator();
    error MustHaveOperators();
    error NotMasterCopy();

    /* -------------------------------------------------------------------------- */
    /*                                global states                               */
    /* -------------------------------------------------------------------------- */
    bool public allowZeroOperators = false;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    address internal stacktAddress;
    mapping(address => address) internal operators;
    address internal constant SENTINEL_OPERATOR = address(0x1);
    uint256 public operatorsCount;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier authorized() {
        if (msg.sender != stacktAddress) { revert Unauthorized(); }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    // Constructor ensures that this contract can only be used as a master copy
    // for proxy contracts
    constructor() {
        singleton = address(this);

        // Ensure `setup` can't be called anymore
        operators[SENTINEL_OPERATOR] = address(0);

        // Ensure `stacktWalletAddress` can't be called anymore
        stacktAddress = address(1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setup(address operator, address[] memory _additionalOperators) external {

        // Ensure setup can only be called once
        if (operators[SENTINEL_OPERATOR] != address(0)) { revert AlreadyInitialized(); }

        // first operator
        address currentOperator = SENTINEL_OPERATOR;
        operators[currentOperator] = operator;
        currentOperator = operator;

        // additional operators
        for (uint256 i = 0; i < _additionalOperators.length; i++) {
            // operator
            address c = _additionalOperators[i];

            // check address
            if (
                c == address(0) || 
                c == SENTINEL_OPERATOR || 
                c == address(this) || 
                currentOperator == c
            ) {
                revert InvalidOperatorAddress(c);
            }

            // No duplicate operators allowed.
            if (operators[c] != address(0)) { revert AlreadyAnOperator(); }
            operators[currentOperator] = c;
            currentOperator = c;
        }

        operatorsCount = 1 + _additionalOperators.length;
        operators[currentOperator] = SENTINEL_OPERATOR;
    }

    function setStacktWalletAddress(address _s) external {
        if (stacktAddress != address(0)) { revert StacktWalletAddressAlreadySet(); }
        if (_s == address(0)) { revert InvalidStacktWalletAddress(); }
        stacktAddress = _s;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    function addOperator(address operator) external authorized {
        // address cannot be null or sentinel.
        if (operator == address(0) || operator == SENTINEL_OPERATOR) { 
            revert InvalidOperatorAddress(operator);
        }

        // operator cannot be added twice
        if (operators[operator] != address(0)) { revert AlreadyAnOperator(); }
        
        operatorsCount += 1;
        operators[operator] = operators[SENTINEL_OPERATOR];
        operators[SENTINEL_OPERATOR] = operator;
    }

    function removeOperator(address prevOperator, address operator) external authorized {

        bool _allowZeroOperators = StacktOperatorGuard(singleton).allowZeroOperators();

        // validate operator count
        if (!_allowZeroOperators) {
            if (operatorsCount == 1) { revert MustHaveOperators(); }
        }

        // validate operator address and check that it corresponds to operator index.
        if (operator == address(0) || operator == SENTINEL_OPERATOR) {
            revert InvalidOperatorAddress(operator);
        }
        if (operators[prevOperator] != operator) {
            revert InvalidPreviosOperatorAddress();
        }
        operators[prevOperator] = operators[operator];
        operators[operator] = address(0);
        operatorsCount -= 1;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function getOperators() public view returns (address[] memory) {
        address[] memory array = new address[](operatorsCount);

        // populate return array
        uint256 index = 0;
        address currentOperator = operators[SENTINEL_OPERATOR];

        while (currentOperator != SENTINEL_OPERATOR) {
            array[index] = currentOperator;
            currentOperator = operators[currentOperator];
            index++;
        }
        return array;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    guard                                   */
    /* -------------------------------------------------------------------------- */
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external view {
        if (operatorsCount > 0) {
            if (operators[tx.origin] == address(0)) {
                revert NotAnOperator();
            }
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {
        // do nothing
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setAllowZeroOperators(bool b) external onlyOwner {
        if (address(this) != singleton) { revert NotMasterCopy(); }
        allowZeroOperators = b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// must be the first inherited contract
contract Singleton {
    address internal singleton;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../common/SelfAuthorized.sol";
import "openzeppelin-contracts/utils/introspection/IERC165.sol";

enum Operation { Call, DelegateCall }

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

contract StacktGuardManager is SelfAuthorized {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error AlreadySetup();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event ChangedGuard(address guard);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // keccak256("guard_manager.setup.address")
    bytes32 internal constant SETUP_STORAGE_SLOT = 0xac6b4b4c91b961f50b5cda5ba75b03d57713b69c71326dc577aa2ff0b32e0286;

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setupGuard(address guard) internal {
        bool hasSetup;
        assembly {
            hasSetup := sload(SETUP_STORAGE_SLOT)
        }
        if (hasSetup) { revert AlreadySetup(); }
        assembly {
            sstore(SETUP_STORAGE_SLOT, true)
        }
        if (guard != address(0)) {
            _setGuard(guard);
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                             getters and setters                            */
    /* -------------------------------------------------------------------------- */
    function getGuard() public view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            guard := sload(slot)
        }
    }

    function _setGuard(address guard) private {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SelfAuthorized {

    error NotSelfAuthorized();

    function requireSelfCall() private view {
        if (msg.sender != address(this)) { revert NotSelfAuthorized(); }
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

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