//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./rainstorms/IRainstorm.sol";
import "./utils/OwnableSafe.sol";

contract RainstormRegistry is OwnableSafe {
    address public worker;
    address[] public rainstorms;
    mapping(address => bool) public isRegistered;

    modifier onlyWorker() {
        require(
            _msgSender() == worker,
            "Caller is not worker"
        );
        _;
    }

    constructor(
        address _worker
    ) {
        worker = _worker;
    }

    function collectAll(
        uint256[] calldata _rainstormIDs,
        uint256[][] calldata _raindropIDs,
        bytes[][] calldata _payloads
    )
        external
    {
        unchecked {
            for (uint i; i < _rainstormIDs.length; i += 1) {
                collectRainstorm(
                    _rainstormIDs[i],
                    _raindropIDs[i],
                    _payloads[i]
                );
            }
        }
    }

    function collectRainstorm(
        uint256 _rainstormID,
        uint256[] calldata _raindropIDs,
        bytes[] calldata _payloads
    )
        public
    {
        IRainstorm(rainstorms[_rainstormID]).userClaimBatch(
            _msgSender(),
            _raindropIDs,
            _payloads
        );
    }

    function collectRaindrop(
        uint256 _rainstormID,
        uint256 _raindropID,
        bytes calldata _payload
    )
        external
    {
        IRainstorm(rainstorms[_rainstormID]).userClaim(
            _msgSender(),
            _raindropID,
            _payload
        );
    }

    function createRaindrop(
        uint256 _rainstormID,
        address _asset,
        uint96 _totalTokens,
        address _source,
        uint48 _startTime,
        uint48 _endTime,
        bytes calldata _payload
    )
        external
        onlyWorker
    {
        IRainstorm(rainstorms[_rainstormID]).createRaindrop(
            _asset,
            _totalTokens,
            _source,
            _startTime,
            _endTime,
            _payload
        );
    }

    function setWorker(
        address _newWorker
    )
        external
        onlyOwner
    {
        worker = _newWorker;
    }

    function registerRainstorm(
        address _rainstorm
    )
        external
        onlyWorker
    {
        require(
            _rainstorm != address(0),
            "Rainstorm address is zero"
        );
        require(
            isRegistered[_rainstorm] == false,
            "Rainstorm is already registered"
        );

        rainstorms.push(_rainstorm);
        isRegistered[_rainstorm] = true;
    }

    function deregisterRainstorm(
        uint256 _rainstormID
    )
        external
        onlyWorker
    {
        require(
            _rainstormID < rainstorms.length,
            "Rainstorm does not exist"
        );

        isRegistered[rainstorms[_rainstormID]] = false;
        if (rainstorms.length > 1) {
            unchecked {
                rainstorms[_rainstormID] = rainstorms[rainstorms.length - 1];
            }
        }
        rainstorms.pop();
    }

    function rainstormCount()
        external
        view
        returns (uint256)
    {
        return rainstorms.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IRainstorm {
    function createRaindrop(
        address _asset,
        uint96 _totalTokens, // allows up to 79,228,162,514 tokens (at 18 decimals)
        address _source,
        uint48 _startTime,
        uint48 _endTime,
        bytes calldata _payload
    ) external;

    function userClaim(
        address _user,
        uint256 _raindropID,
        bytes calldata _payload
    ) external;

    function userClaimBatch(
        address _user,
        uint256[] calldata _raindropIDs,
        bytes[] calldata _payloads
    ) external;

    function raindropCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
// With renounceOwnership() removed

pragma solidity ^0.8.9;

import "./ContextSimple.sol";

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
abstract contract OwnableSafe is ContextSimple {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
// Based on OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
// With _msgData() removed

pragma solidity ^0.8.9;

/**
 * @dev Provides the msg.sender in the current execution context.
 */
abstract contract ContextSimple {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}