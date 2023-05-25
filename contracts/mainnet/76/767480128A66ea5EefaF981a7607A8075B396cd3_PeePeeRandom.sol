// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeePeeRandom is Ownable {

    struct Raffle {
        uint256 winners;
        uint256 slots;
        uint256 rng;
    }

    uint256 currentId = 0;

    mapping(uint256 => Raffle) public idToRaffle;

    function startRaffle(uint winners, uint slots) public onlyOwner {
        uint256 rng = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.number, msg.sender)));
        
        idToRaffle[currentId++] = Raffle(winners, slots, rng);
    }

    function showResult(uint256 id) public view returns (uint256[] memory) {
        Raffle memory raffle = idToRaffle[id];

        uint256 slots = raffle.slots;
        uint256 winners = raffle.winners;
        uint256 winnerCount = 0;
        uint256 attempts = 0;

        bool[] memory winnerArray = new bool[](slots);

        while (winnerCount < winners) {
            uint256 extraRandomness = uint256(keccak256(abi.encodePacked(raffle.rng, attempts)));

            uint256 winnerPos = (extraRandomness % slots);

            attempts++;

            if (winnerArray[winnerPos])
                continue;

            winnerArray[winnerPos] = true;

            winnerCount++;
        }

        uint256[] memory winnerIds = new uint256[](winners);

        uint256 j = 0;

        for (uint i = 0; i < winnerArray.length; i++) {
            if (winnerArray[i]) {
                winnerIds[j] = i;
                j++;
            }
        }

        return winnerIds;
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