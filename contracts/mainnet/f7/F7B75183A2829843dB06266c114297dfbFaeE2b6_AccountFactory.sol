// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {AccountGuard} from "./AccountGuard.sol";
import {AccountImplementation} from "./AccountImplementation.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract AccountFactory {
    address public immutable proxyTemplate;
    AccountGuard public immutable guard;
    uint256 public accountsGlobalCounter;

    //mapping(uint256 => address) public accounts;

    constructor(address _guard) {
        guard = AccountGuard(_guard);
        guard.initializeFactory();
        address adr = address(new AccountImplementation(guard));
        proxyTemplate = adr;
    }

    function createAccount() external returns (address clone) {
        clone = this.createAccount(msg.sender);
        return clone;
    }

    function createAccount(address user) external returns (address) {
        require(user != address(0), "account-factory/zero-address");
        uint256 globalCounter = ++accountsGlobalCounter;
        address clone = Clones.clone(proxyTemplate);
        guard.permit(user, clone, true);
        emit AccountCreated(clone, user, globalCounter);
        return clone;
    }

    event AccountCreated(
        address indexed proxy,
        address indexed user,
        uint256 indexed vaultId
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./AccountGuard.sol";

contract AccountImplementation {
    AccountGuard public immutable guard;

    modifier authAndWhitelisted(address target, bool asDelegateCall) {
        (bool canCall, bool isWhitelisted) = guard.canCallAndWhitelisted(
            address(this),
            msg.sender,
            target,
            asDelegateCall
        );
        require(
            canCall,
            "account-guard/no-permit"
        );
        require(
            isWhitelisted,
            "account-guard/illegal-target"
        );
        _;
    }

    constructor(AccountGuard _guard) {
        require(
            address(_guard) != address(0x0),
            "account-guard/wrong-guard-address"
        );
        guard = _guard;
    }

    function send(address _target, bytes calldata _data)
        external
        payable
        authAndWhitelisted(_target, false)
    {
        (bool status, ) = (_target).call{value: msg.value}(_data);
        require(status, "account-guard/call-failed");
    }

    function execute(address _target, bytes memory /* code do not compile with calldata */ _data)
        external
        payable
        authAndWhitelisted(_target, true)

        returns (bytes32)
    {
        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                32
            )
            returndatacopy(0, 0, returndatasize())
            switch succeeded
            case 0 {
                // throw if delegatecall failed
                revert(0, returndatasize())
            }
            default {
                return(0, 0x20)
            }
        }
    }
 
    receive() external payable {
        emit FundsRecived(msg.sender, msg.value);
    }

    function owner() external view returns (address) {
        return guard.owners(address(this));
    }

    event FundsRecived(address sender, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccountGuard is Ownable {
    address factory;
    uint8 constant WHITELISTED_EXECUTE_MASK = 1;
    uint8 constant WHITELISTED_SEND_MASK = 2;
    mapping(address => mapping(address => bool)) private allowed;
    mapping(address => uint8) private whitelisted;
    mapping(address => address) public owners;

    function isWhitelisted(address target) public view returns (bool) {
        return (whitelisted[target] & WHITELISTED_EXECUTE_MASK) > 0;
    }

    function setWhitelist(address target, bool status) external onlyOwner {
        whitelisted[target] = status
            ? whitelisted[target] | WHITELISTED_EXECUTE_MASK
            : whitelisted[target] & ~WHITELISTED_EXECUTE_MASK;
    }

    function isWhitelistedSend(address target) public view returns (bool) {
        return (whitelisted[target] & WHITELISTED_SEND_MASK) > 0;
    }

    function setWhitelistSend(address target, bool status) external onlyOwner {
        whitelisted[target] = status
            ? whitelisted[target] | WHITELISTED_SEND_MASK
            : whitelisted[target] & ~WHITELISTED_SEND_MASK;
    }

    function canCallAndWhitelisted(
        address proxy,
        address operator,
        address callTarget,
        bool asDelegateCall
    ) external view returns (bool, bool) {
        return (
            allowed[operator][proxy],
            asDelegateCall
                ? isWhitelisted(callTarget)
                : isWhitelistedSend(callTarget)
        );
    }

    function canCall(address target, address operator)
        external
        view
        returns (bool)
    {
        return owners[target] == operator || allowed[operator][target];
    }

    function initializeFactory() external {
        require(factory == address(0), "account-guard/factory-set");
        factory = msg.sender;
    }

    function permit(
        address caller,
        address target,
        bool allowance
    ) external {
        require(
            allowed[msg.sender][target] || msg.sender == factory,
            "account-guard/no-permit"
        );
        if (msg.sender == factory) {
            owners[target] = caller;
            allowed[target][target] = true;
        } else {
            require(owners[target] != caller, "account-guard/cant-deny-owner");
        }
        allowed[caller][target] = allowance;

        if (allowance) {
            emit PermissionGranted(caller, target);
        } else {
            emit PermissionRevoked(caller, target);
        }
    }

    function changeOwner(address newOwner, address target) external {
        require(newOwner != address(0), "account-guard/zero-address");
        require(owners[target] == msg.sender, "account-guard/only-proxy-owner");
        owners[target] = newOwner;
        allowed[msg.sender][target] = false;
        allowed[newOwner][target] = true;
        emit ProxyOwnershipTransferred(newOwner, msg.sender, target);
    }

    event ProxyOwnershipTransferred(
        address indexed newOwner,
        address indexed oldAddress,
        address indexed proxy
    );
    event PermissionGranted(address indexed caller, address indexed proxy);
    event PermissionRevoked(address indexed caller, address indexed proxy);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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