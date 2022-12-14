/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

/// @author: knownorigin.io

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
        return msg.data;
    }
}

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
        _setOwner(_msgSender());
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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IKODAV2 {
    function editionOfTokenId(uint256 _tokenId) external view returns (uint256 _editionNumber);

    function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

    function editionOptionalCommission(uint256 _editionNumber) external view returns (uint256 _rate, address _recipient);
}

interface IKODAV2Override {

    /// @notice Emitted when the royalties fee changes
    event CreatorRoyaltiesFeeUpdated(uint256 _oldCreatorRoyaltiesFee, uint256 _newCreatorRoyaltiesFee);

    /// @notice For the given KO NFT and token ID, return the addresses and the amounts to pay
    function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
    external
    view
    returns (address payable[] memory, uint256[] memory);

    /// @notice Allows the owner() to update the creator royalties
    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external;
}

/**
 * @dev Implementation of KODA V2 override
 * @notice KnownOrigin V2 (KODAV2) records expected commissions in simplistic single digit commission i.e. 100 = 10.0%, we dont store
 *         a primary vs secondary expected commission amount so we need work this out proportionally
 */
contract KODAV2Override is IKODAV2Override, ERC165Storage, Ownable {

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage) returns (bool) {
    return interfaceId == type(IKODAV2Override).interfaceId || super.supportsInterface(interfaceId);
  }

  /// @notice precision 100.00000%
  uint256 public modulo = 100_00000;

  /// @notice Secondary sale royalty fee
  uint256 public creatorRoyaltiesFee = 10_00000; // 10% by default

  function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
  external
  override
  view
  returns (address payable[] memory receivers, uint256[] memory amounts) {

    // Get the edition the token is part of
    uint256 _editionNumber = IKODAV2(_tokenAddress).editionOfTokenId(_id);
    require(_editionNumber > 0, "Edition not found for token ID");

    // Get existing artist commission
    (address artistAccount, uint256 artistCommissionRate) = IKODAV2(_tokenAddress).artistCommission(_editionNumber);

    // work out the expected royalty payment
    uint256 totalRoyaltyToPay = (_amount / modulo) * creatorRoyaltiesFee;

    // Get optional commission set against the edition and work out the expected commission
    (uint256 optionalCommissionRate, address optionalCommissionRecipient) = IKODAV2(_tokenAddress).editionOptionalCommission(_editionNumber);
    if (optionalCommissionRate > 0) {

      receivers = new address payable[](2);
      amounts = new uint256[](2);

      uint256 totalCommission = artistCommissionRate + optionalCommissionRate;

      // Add the artist and commission
      receivers[0] = payable(artistAccount);
      amounts[0] = (totalRoyaltyToPay / totalCommission) * artistCommissionRate;

      // Add optional splits
      receivers[1] = payable(optionalCommissionRecipient);
      amounts[1] = (totalRoyaltyToPay / totalCommission) * optionalCommissionRate;
    } else {
      receivers = new address payable[](1);
      amounts = new uint256[](1);

      // Add the artist and commission
      receivers[0] = payable(artistAccount);
      amounts[0] = totalRoyaltyToPay;
    }

    return (receivers, amounts);
  }

  function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external override onlyOwner {
    emit CreatorRoyaltiesFeeUpdated(creatorRoyaltiesFee, _creatorRoyaltiesFee);
    creatorRoyaltiesFee = _creatorRoyaltiesFee;
  }

}