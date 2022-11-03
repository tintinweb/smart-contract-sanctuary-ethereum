// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface ILockAddressRegistry {
    function initialize(
        address admin,
        address tokenVault,
        address fnft,
        address emissionor
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getFNFT() external view returns (address);

    function setFNFT(address fnft) external;

    function getEmissionor() external view returns (address);

    function setEmissionor(address emissionor) external;

    function getFarm(uint256 index) external view returns (address);

    function addFarm(address farm) external;

    function setIsFarm(address farm, bool value) external;

    function isFarm(address farm) external view returns (bool);

    function getAddress(bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface ILockFarm {
    struct FNFTInfo {
        uint256 id;
        uint256 amount;
        uint256 startTime;
        uint256 secs;
        uint256 multiplier;
        uint256 rewardDebt;
        uint256 pendingReward;
    }

    event Stake(
        address indexed account,
        uint256 indexed fnftId,
        uint256 amount,
        uint256 secs
    );
    event Withdraw(
        address indexed account,
        uint256 indexed fnftId,
        uint256 amount
    );
    event Claim(
        address indexed account,
        uint256 indexed fnftId,
        uint256 amount
    );
    event MultipliersUpdated(
        uint256 lockedStakeMaxMultiplier,
        uint256 lockedStakeTimeForMaxMultiplier
    );

    function claimAll(address owner) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/ILockAddressRegistry.sol';
import './interfaces/ILockFarm.sol';

contract LockAddressRegistry is Ownable, ReentrancyGuard, ILockAddressRegistry {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN = 'ADMIN';
    bytes32 public constant TOKEN_VAULT = 'TOKEN_VAULT';
    bytes32 public constant FNFT = 'FNFT';
    bytes32 public constant EMISSIONOR = 'EMISSIONOR';

    mapping(bytes32 => address) private _addresses;

    Counters.Counter private _farmIndexTracker;
    mapping(uint256 => address) private _farms;
    mapping(address => bool) private _isFarm;

    constructor() Ownable() {}

    // Set up all addresses for the registry.
    function initialize(
        address admin,
        address tokenVault,
        address fnft,
        address emissionor
    ) external override onlyOwner {
        _addresses[ADMIN] = admin;
        _addresses[TOKEN_VAULT] = tokenVault;
        _addresses[FNFT] = fnft;
        _addresses[EMISSIONOR] = emissionor;
    }

    function getAdmin() external view override returns (address) {
        return _addresses[ADMIN];
    }

    function setAdmin(address admin) external override onlyOwner {
        _addresses[ADMIN] = admin;
    }

    function getTokenVault() external view override returns (address) {
        return getAddress(TOKEN_VAULT);
    }

    function setTokenVault(address vault) external override onlyOwner {
        _addresses[TOKEN_VAULT] = vault;
    }

    function getFNFT() external view override returns (address) {
        return _addresses[FNFT];
    }

    function setFNFT(address fnft) external override onlyOwner {
        _addresses[FNFT] = fnft;
    }

    function getEmissionor() external view override returns (address) {
        return _addresses[EMISSIONOR];
    }

    function setEmissionor(address emissionor) external override onlyOwner {
        _addresses[EMISSIONOR] = emissionor;
    }

    function getFarm(uint256 index) external view override returns (address) {
        return _farms[index];
    }

    function addFarm(address farm) external override onlyOwner {
        _farms[_farmIndexTracker.current()] = farm;
        _farmIndexTracker.increment();
        _isFarm[farm] = true;
    }

    function setIsFarm(address farm, bool value) external override onlyOwner {
        _isFarm[farm] = value;
    }

    function isFarm(address farm) external view override returns (bool) {
        return _isFarm[farm];
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    ///////////////////////////////////////////////////////
    //               USER CALLED FUNCTIONS               //
    ///////////////////////////////////////////////////////

    function claimAll() external nonReentrant {
        for (uint256 i = 0; i < _farmIndexTracker.current(); i++) {
            address farm = _farms[i];
            if (_isFarm[farm]) {
                ILockFarm(farm).claimAll(msg.sender);
            }
        }
    }
}