//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LLCTier is Ownable, ILLCTier {
    uint256 public constant override LEGENDARY_RARITY = 1;
    uint256 public constant override SUPER_RARE_RARITY = 2;
    uint256 public constant override RARE_RARITY = 3;

    uint256 public legendaryLLCs;
    uint256 public superRareLLCs;
    uint256 public rareLLCs;

    mapping(uint256 => uint256) public override LLCRarities;

    function _registerLLCRarity(uint256[] memory _tokenIds, uint256 _rarity)
        private
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            LLCRarities[_tokenIds[i]] = _rarity;
        }
    }

    function registerLegendaryLLCs(uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        _registerLLCRarity(_tokenIds, LEGENDARY_RARITY);
        legendaryLLCs += _tokenIds.length;
    }

    function registerSuperRareLLCs(uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        _registerLLCRarity(_tokenIds, SUPER_RARE_RARITY);
        superRareLLCs += _tokenIds.length;
    }

    function registerRareLLCs(uint256[] memory _tokenIds) external onlyOwner {
        _registerLLCRarity(_tokenIds, RARE_RARITY);
        rareLLCs += _tokenIds.length;
    }

    function resetRarity(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i=0; i<_tokenIds.length; i++) {
            uint256 prevRarity = LLCRarities[_tokenIds[i]];
            if (prevRarity == LEGENDARY_RARITY) {
                legendaryLLCs --;
            } else if (prevRarity == SUPER_RARE_RARITY) {
                superRareLLCs --;
            } else if (prevRarity == RARE_RARITY) {
                rareLLCs --;
            }

            LLCRarities[_tokenIds[i]] = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILLCTier {
    function LEGENDARY_RARITY() external returns (uint256);

    function SUPER_RARE_RARITY() external returns (uint256);

    function RARE_RARITY() external returns (uint256);

    function LLCRarities(uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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