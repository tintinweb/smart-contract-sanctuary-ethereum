// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/OwnableEpochContract.sol";

error OverShielded();
error Ineffective();
error NotSoQ00t();
error InvalidConsumer();
error CallerNotOwner();
error CornNotReady();
error NoContracts();
error InvalidCaller();

interface IERC721 {
    function ownerOf(uint256) external returns (address);
    function balanceOf(address) external returns (uint256);
    function transferFrom(address, address, uint256) external;
}

contract Plunk is OwnableEpochContract {
    constructor(address findWeakness) {
        FIND_WEAKNESS_ADDRESS = findWeakness;
    }

    event Consumed(address q00t, uint256 tokenId);
    event Victory(address q00t);

    address constant Q00TANT_CONTRACT_ADDRESS = 0x9F7C5D43063e3ECEb6aE43A22b669BB01fD1039A;
    address constant Q00NICORN_CONTRACT_ADDRESS = 0xc8Dc0f7B8Ca4c502756421C23425212CaA6f0f8A;
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant CONSUMER = 0x9f13A3c1820942b691e5c9Cfd7e4944c9a03d3d9;
    address immutable FIND_WEAKNESS_ADDRESS;
    address glitterHarvester;

    uint256 public hp = 100_000;
    uint256 public shield = 100;

    bool completed;

    mapping(uint256 => uint256) public tantLastAttacked;
    mapping(uint256 => uint256) public cornLastAttacked;

    function consume(address q00t, uint256 tokenId) external {
        if (msg.sender != CONSUMER) revert InvalidConsumer();

        IERC721(Q00NICORN_CONTRACT_ADDRESS).transferFrom(msg.sender, DEAD_ADDRESS, tokenId);
        emit Consumed(q00t, tokenId);
    }

    function replenishShield(uint256 tokenId) public {
        if (IERC721(Q00NICORN_CONTRACT_ADDRESS).ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
        IERC721(Q00TANT_CONTRACT_ADDRESS).transferFrom(msg.sender, address(this), tokenId);
        
        if (shield > 90) revert OverShielded();
        shield += 10;
    }

    function strengthen() public {
        if (msg.sender != glitterHarvester) revert InvalidCaller();
        uint256 power = _generateRandom(25);
        hp += power;
    }

    function weaken(uint256 tokenId) public {
        if (IERC721(Q00NICORN_CONTRACT_ADDRESS).ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
        uint256 attackStrength = _generateRandom(15);
        if (block.timestamp - cornLastAttacked[tokenId] < 24 hours) revert CornNotReady();

        unchecked {
            if (shield > 0) {
                if (attackStrength > shield) {
                    attackStrength -= shield;
                    shield = 0;
                } else {
                    uint256 diff = attackStrength - shield;
                    shield -= attackStrength;
                    attackStrength -= diff;
                }
            }
        }
        (bool canAttack, ) = FIND_WEAKNESS_ADDRESS.call(abi.encodeWithSelector(0x9c4419a2));
        if (!canAttack) revert Ineffective();
        hp -= attackStrength;

        if (hp < 10_000) {
            uint256 size = _getCodeSize(msg.sender);
            if (size != 0) revert NoContracts();
        }

        if (hp < 100) revert Ineffective();

        cornLastAttacked[tokenId] = block.timestamp;
    }

    function attack(uint256 tokenId) public {
        if (IERC721(Q00NICORN_CONTRACT_ADDRESS).ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
        if (msg.sender != tx.origin) revert NoContracts();

        uint256 attackStrength = _generateRandom(7);
        
        if (attackStrength < 3) {
            IERC721(Q00NICORN_CONTRACT_ADDRESS).transferFrom(msg.sender, DEAD_ADDRESS, tokenId);
            emit Consumed(Q00NICORN_CONTRACT_ADDRESS, tokenId);
        } else if (attackStrength == 7) {
            attackStrength = 13;
        }

        hp -= attackStrength;

        if (hp < 10) revert Ineffective();
    }

    function finisher(uint256 tokenId) public {
        if (IERC721(Q00NICORN_CONTRACT_ADDRESS).ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
        if (msg.sender != tx.origin) revert NoContracts();
        
        uint256 attackStrength = _generateRandom(10);

        if (attackStrength < 10) {
            IERC721(Q00NICORN_CONTRACT_ADDRESS).transferFrom(msg.sender, DEAD_ADDRESS, tokenId);
            emit Consumed(Q00NICORN_CONTRACT_ADDRESS, tokenId);
        }
        
        --hp;

        if (hp == 0) {
            completed = true;
            emit Victory(Q00NICORN_CONTRACT_ADDRESS);
        }
    }

    function declareVictory() external {
        if (hp > 0) {
            if (IERC721(Q00NICORN_CONTRACT_ADDRESS).balanceOf(DEAD_ADDRESS) > 2700) {
                completed = true;
                emit Victory(Q00TANT_CONTRACT_ADDRESS);
            }
        }
    }

    function batch(bytes4 selector, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length;) {
            (bool success, ) = address(this).call(abi.encodeWithSelector(selector, tokenIds[i]));
            if (!success) revert NotSoQ00t();
            unchecked { ++i; }
        }
    }

    function _generateRandom(uint256 maxValue) private view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(msg.sender, block.difficulty, block.timestamp)));
        return randomHash % maxValue;
    }

    function _getCodeSize(address _address) private view returns (uint256 size) {
        assembly {
            size := extcodesize(_address)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

pragma solidity 0.8.17;

error OnlyEpoch();

interface IEpochRegistry {
  function isApprovedAddress(address _address) external view returns (bool);
  function setEpochContract(address _contract, bool _approved) external;
}

contract OwnableEpochContract is Ownable {
  IEpochRegistry internal immutable epochRegistry;

  constructor() {
    epochRegistry = IEpochRegistry(0x3b3E84457442c5c2C671d9528Ea730258c7ccfF7);
  }

  modifier onlyEpoch {
    if (!epochRegistry.isApprovedAddress(msg.sender)) revert OnlyEpoch();
    _;
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