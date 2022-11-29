// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CosmeticERC721A/ICosmeticERC721A.sol";

contract CosmeticsRegistry is Ownable {

  /**
   * @notice the current cosmetic ID.
   * 
   * @dev incremented when a new cosmetic is added to the registry.
   */
  uint256 currentCosmeticId;

  /**
   * @notice constructor sets the { currentCosmeticId } to 1.
   */
  constructor() {
    currentCosmeticId = 1;
  }

  /**
   * @notice mapping from a cosmetic ID to a cosmetic name.
   * 
   * @dev used in { addCosmetic } when adding a new cosmetic to the registry.
   */
  mapping (uint256 => string) public cosmetics;

  /**
   * @notice mapping from an address to a list of the cosmetic IDs they own.
   * 
   * @dev used in the front-end to allow a user to select a cosmetic to use.
   */
  mapping (address => uint256[]) public ownedCosmetics;

  /**
   * @notice mapping from a cosmetic ID to its { CosmeticERC721A } contract address.
   * 
   * @dev used in { claimCosmetic } to see if the user is eligible for the ERC721,
   * and so that they can claim it.
   */
  mapping (uint256 => address) public cosmeticContractOf;

  /**
   * @notice function to claim a new cosmetic.
   * 
   * @dev calls the contract of the { _cosmeticId } to check for elibility and claim.
   * @param _cosmeticId the cosmetic to claim.
   */
  function claimCosmetic(uint256 _cosmeticId) public {
    // instantiate the cosmetic contract using { ICosmeticERC721A } //
    ICosmeticERC721A cosmetic = ICosmeticERC721A(cosmeticContractOf[_cosmeticId]);

    // check for elibility //
    require(cosmetic.isEligible(msg.sender), "You are not eligible for this cosmetic.");

    // if eligible call { claim } on the cosmetic contract and push the ID to their { ownedCosmetics }.
    ownedCosmetics[msg.sender].push(_cosmeticId);
    cosmetic.claim(msg.sender);
  }

  /**
   * @notice function allowing the owner to add new cosmetics to the registry.
   * 
   * @dev updates the { cosmetics } and { cosmeticContractOf } mappings to be used
   * in { claimCosmetic } in future.
   * @param _cosmetic the name of the new cosmetic.
   * @param _cosmeticContract the contract address of the new cosmetic ERC721A.
   */
  function addCosmetic(string memory _cosmetic, address _cosmeticContract) public onlyOwner {
    cosmetics[currentCosmeticId] = _cosmetic;
    cosmeticContractOf[currentCosmeticId] == _cosmeticContract;
    currentCosmeticId += 1;
  }
}

// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

/**
 * @title ICosmeticERC721A
 * @dev Interface for the CosmeticERC721A contract.
 */

interface ICosmeticERC721A {
  function isEligible (address _address) external returns (bool);
  function claim (address _to) external;
  function setCosmeticRegistry(address _cosmeticRegistry) external;
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