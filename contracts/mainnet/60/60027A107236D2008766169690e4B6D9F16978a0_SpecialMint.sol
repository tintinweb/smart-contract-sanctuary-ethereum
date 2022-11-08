// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IEggShop.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IHenHouseAdvantage.sol';
import './interfaces/IRandomizer.sol';
import './interfaces/IImperialEggs.sol';
import './interfaces/ISpecialMint.sol';
import './interfaces/ITheFarmGameMint.sol';

contract SpecialMint is Ownable, ISpecialMint, ReentrancyGuard, Pausable {
  // Events
  event Add(uint256 indexed typeId, uint256 maxSupply, uint256 mintFee);
  event Update(uint256 indexed typeId, uint256 maxSupply, uint256 mintFee);
  event MintedSpecial(address indexed owner, uint256 indexed typeId);
  event InitializedContract(address thisContract);

  // address => can call allowedToCallFunctions
  mapping(address => bool) private controllers;
  struct SpecialMints {
    uint256 typeId;
    uint256[] eggShopTypeIds;
    uint16[] eggShopTypeQtys;
    uint16[] farmAnimalTypeIds;
    uint16[] farmAnimalTypeQtys;
    uint256 imperialEggQtys;
    uint256 bonusEGGDuration;
    uint16 bonusEGGPercentage;
    uint256 bonusEGGAmount;
    uint256 specialMintFee;
    uint256 maxSupply;
    uint256 minted;
  }

  SpecialMints[] public specialMints;

  // Interfaces
  IEggShop public eggShop; // ref to eggShop collection
  IEGGToken public eggToken; // ref of egg token
  IFarmAnimals public farmAnimalsNFT; // ref to FarmAnimals collection
  IHenHouseAdvantage public henHouseAdvantage; // ref to the Hen House for choosing random Coyote thieves
  IImperialEggs public imperialEggs; // ref to Imperial Eggs collection
  ITheFarmGameMint public theFarmGameMint; // ref to TheFarmGameMint contract
  IRandomizer public randomizer; // ref to randomizer

  /** MODIFIERS */

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */

  modifier requireContractsSet() {
    require(
      address(farmAnimalsNFT) != address(0) &&
        address(henHouseAdvantage) != address(0) &&
        address(eggShop) != address(0) &&
        address(theFarmGameMint) != address(0) &&
        address(randomizer) != address(0),
      'Contracts not set'
    );
    _;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  /**
   * Instantiates contract
   * Emits InitilizeContracts event to kickstart subgraph
   */

  constructor(
    IEGGToken _eggToken,
    IEggShop _eggShop,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouseAdvantage _henHouseAdvantage,
    IRandomizer _randomizer,
    IImperialEggs _imperialEggs
  ) {
    eggToken = _eggToken;
    eggShop = _eggShop;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouseAdvantage = _henHouseAdvantage;
    randomizer = _randomizer;
    imperialEggs = _imperialEggs;
    controllers[_msgSender()] = true;
    _pause();
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   * This section has everything to do with Character minting and burning
   */

  /**
   * @notice mint function for the special mint
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function mint(uint256 _typeId, address _recipient) external payable whenNotPaused nonReentrant {
    require(theFarmGameMint.canMint() && theFarmGameMint.allowListTime() <= block.timestamp, 'TFG Mint not miting');
    _mint(_typeId, _recipient);
  }

  /**
   * @notice mint function for the special mint
   * @dev internal function
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function _mint(uint256 _typeId, address _recipient) internal {
    uint256 typeId = _typeId - 1;

    SpecialMints memory _specialMint = specialMints[typeId];

    require(typeId < specialMints.length, "SpecialMint TypeId doesn't exist");
    if (!controllers[_msgSender()]) {
      require(msg.value >= _specialMint.specialMintFee, 'Payment is not enough');
    }
    require(_specialMint.maxSupply > _specialMint.minted, 'Max supply exceed');
    for (uint8 i = 0; i < _specialMint.eggShopTypeIds.length; i++) {
      IEggShop.TypeInfo memory eggShopInfo = eggShop.getInfoForType(_specialMint.eggShopTypeIds[i]);
      if ((eggShopInfo.mints + eggShopInfo.burns) < eggShopInfo.maxSupply) {
        eggShop.mint(_specialMint.eggShopTypeIds[i], _specialMint.eggShopTypeQtys[i], _recipient, uint256(0));
      }
    }
    uint256 minted = farmAnimalsNFT.minted();

    for (uint8 j = 0; j < _specialMint.farmAnimalTypeIds.length; j++) {
      uint256 seed = randomizer.randomToken(minted);

      if (_specialMint.farmAnimalTypeIds[j] == 4) {
        // mint twin hens
        farmAnimalsNFT.mintTwins(seed, _recipient, _recipient);
        // farmAnimalsNFT.specialMint(recipient, seed, 0, true, _specialMint.farmAnimalTypeQtys[j]);

        if (_specialMint.bonusEGGDuration > 0 && _specialMint.bonusEGGPercentage > 0) {
          henHouseAdvantage.addAdvantageBonus(
            minted + 1,
            _specialMint.bonusEGGDuration,
            _specialMint.bonusEGGPercentage
          );
          henHouseAdvantage.addAdvantageBonus(
            minted + 2,
            _specialMint.bonusEGGDuration,
            _specialMint.bonusEGGPercentage
          );
          minted += 2;
        }
      } else if (_specialMint.farmAnimalTypeIds[j] == 5) {
        // special random
        uint256 mintChance = seed % 100;

        // default mint hen
        uint16 mintType = 0;

        if (mintChance < 30) {
          // mint rooster
          mintType = 2;
        } else if (mintChance < 70) {
          // mint coyote
          mintType = 1;
        }
        minted++;
        farmAnimalsNFT.specialMint(_recipient, seed, mintType, false, _specialMint.farmAnimalTypeQtys[j]);
        if (_specialMint.bonusEGGDuration > 0 && _specialMint.bonusEGGPercentage > 0 && mintType == 0) {
          uint256 tokenId = minted;
          for (uint8 a = 0; a < _specialMint.farmAnimalTypeQtys[j]; a++) {
            henHouseAdvantage.addAdvantageBonus(
              tokenId,
              _specialMint.bonusEGGDuration,
              _specialMint.bonusEGGPercentage
            );
            tokenId++;
          }
        }
      } else {
        minted++;
        farmAnimalsNFT.specialMint(
          _recipient,
          seed,
          _specialMint.farmAnimalTypeIds[j],
          false,
          _specialMint.farmAnimalTypeQtys[j]
        );
        if (
          _specialMint.bonusEGGDuration > 0 &&
          _specialMint.bonusEGGPercentage > 0 &&
          _specialMint.farmAnimalTypeIds[j] == 0
        ) {
          uint256 tokenId = minted;
          for (uint8 a = 0; a < _specialMint.farmAnimalTypeQtys[j]; a++) {
            henHouseAdvantage.addAdvantageBonus(
              tokenId,
              _specialMint.bonusEGGDuration,
              _specialMint.bonusEGGPercentage
            );
            tokenId++;
          }
        }
      }
    }

    if (_specialMint.imperialEggQtys > 0) {
      imperialEggs.mint(_recipient, _specialMint.imperialEggQtys);
    }

    if (_specialMint.bonusEGGAmount > 0) {
      eggToken.mint(_recipient, _specialMint.bonusEGGAmount * 10**18);
    }

    specialMints[typeId] = SpecialMints(
      _specialMint.typeId,
      _specialMint.eggShopTypeIds,
      _specialMint.eggShopTypeQtys,
      _specialMint.farmAnimalTypeIds,
      _specialMint.farmAnimalTypeQtys,
      _specialMint.imperialEggQtys,
      _specialMint.bonusEGGDuration,
      _specialMint.bonusEGGPercentage,
      _specialMint.bonusEGGAmount,
      _specialMint.specialMintFee,
      _specialMint.maxSupply,
      ++_specialMint.minted
    );
    emit MintedSpecial(_recipient, _typeId);
  }

  /**
   * @notice mint function for the special mint
   * @dev only Owner can mint this
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function mintFree(uint256 _typeId, address _recipient) external onlyOwner {
    _mint(_typeId, _recipient);
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Get the Special Mint Info Data regarding typeId
   * @param _typeId The type id to get the Special Mint Info Data
   */

  function getSpecialMintInfo(uint256 _typeId) public view returns (SpecialMints memory) {
    uint256 typeId = _typeId - 1;
    return specialMints[typeId];
  }

  /**
   * @notice Get the count of number Special Mint types
   */

  function getSpecialMintCount() external view returns (uint256) {
    return specialMints.length;
  }

  /**
   * @notice get the speical mint nft count to reserve
   */

  function getSpecialMintReserve() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < specialMints.length; i++) {
      SpecialMints memory _specialMint = specialMints[i];
      uint256 mintQty = 0;
      if (_specialMint.minted < _specialMint.minted) {
        for (uint256 j = 0; j < _specialMint.farmAnimalTypeQtys.length; j++) {
          if (_specialMint.farmAnimalTypeIds[j] == 4) {
            // twin hens
            mintQty += _specialMint.farmAnimalTypeQtys[j] + 1;
          } else {
            mintQty += _specialMint.farmAnimalTypeQtys[j];
          }
        }
      }
      total += (_specialMint.maxSupply - _specialMint.minted) * mintQty;
    }
    return total;
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   * @param to Address for ETH to be send to
   * @param value Amount of ETH to send
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  /**
   * @notice Allows owner to withdraw ETH funds to an address
   * @dev wraps _user in payable to fix address -> address payable
   * @param to Address for ETH to be send to
   */
  function withdraw(address payable to) public onlyOwner {
    uint256 amount = address(this).balance;
    require(_safeTransferETH(to, amount));
  }

  /**
   * @notice Allows owner to withdraw any accident tokens transferred to contract
   * @param _tokenContract Address for the token
   * @param to Address for token to be send to
   * @param amount Amount of token to send
   */
  function withdrawToken(
    address _tokenContract,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(to, amount);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggShop Address of eggShop contract
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _imperialEggs Address of imperialEggs contract
   * @param _theFarmGameMint Address of theFarmGameMint contract
   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggShop,
    address _eggToken,
    address _farmAnimalsNFT,
    address _imperialEggs,
    address _theFarmGameMint,
    address _randomizer
  ) external onlyController {
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    imperialEggs = IImperialEggs(_imperialEggs);
    theFarmGameMint = ITheFarmGameMint(_theFarmGameMint);
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * @notice Set the FarmGameMint contract address
   * @dev Only callable by the owner
   * @param _address Address of FarmGameMint contract
   */
  function setFarmGameMint(address _address) external onlyController {
    theFarmGameMint = ITheFarmGameMint(_address);
  }

  /**
   * @notice Enables owner to pause / unpause contract
   * @dev Only callable by an existing controller
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice add the special reward info regarding the special mint typeId
   * @dev Only callable by an existing controller
   * @param _typeId typeId of specialMint info
   * @param _eggShopTypeIds the array of eggShop typeIds to mint eggShop eggs
   * @param _eggShopTypeQtys the array of quantity to mint eggShop eggs
   * @param _farmAnimalTypeIds the array of farmAnimals special mint typeIds (0 => hen, 1 => coyote, 2 => rooster, 3 => random, 4 => twin hens, 5 special random)
   * @param _farmAnimalTypeQtys the array of farmAnimals special mint quantities
   * @param _imperialEggsQtys the count to mint Imperial Eggs
   * @param _bonusEGGDuration the duration of EGG bonus production in mins
   * @param _bonusEGGPercentage the percentage of EGG bonus production
   * @param _bonusEGGAmount the amount to mint EGG token directly
   * @param _specialMintFee the price of special mint reward
   * @param _maxSupply the max supply of special mint reward by specialTokenId
   */

  function addSpecialMint(
    uint256 _typeId,
    uint256[] memory _eggShopTypeIds,
    uint16[] memory _eggShopTypeQtys,
    uint16[] memory _farmAnimalTypeIds,
    uint16[] memory _farmAnimalTypeQtys,
    uint256 _imperialEggsQtys,
    uint256 _bonusEGGDuration,
    uint16 _bonusEGGPercentage,
    uint256 _bonusEGGAmount,
    uint256 _specialMintFee,
    uint256 _maxSupply
  ) external onlyController {
    require(_eggShopTypeIds.length == _eggShopTypeQtys.length, 'SpecialInfo length is not equal');
    require(_farmAnimalTypeIds.length == _farmAnimalTypeQtys.length, 'SpecialInfo length is not equal');
    require(_maxSupply > 0, 'Max Supply should be greater than zero');
    require(_specialMintFee > 0, 'Special Mint Reward price should be greater than zero');
    specialMints.push(
      SpecialMints(
        _typeId,
        _eggShopTypeIds,
        _eggShopTypeQtys,
        _farmAnimalTypeIds,
        _farmAnimalTypeQtys,
        _imperialEggsQtys,
        _bonusEGGDuration,
        _bonusEGGPercentage,
        _bonusEGGAmount,
        _specialMintFee,
        _maxSupply,
        0
      )
    );
    emit Add(_typeId, _maxSupply, _specialMintFee);
  }

  /**
   * @notice update the special reward info regarding the special mint typeId
   * @dev Only callable by an existing controller
   * @param _typeId typeId of specialMint info
   * @param _eggShopTypeIds the array of eggShop typeIds to mint eggShop eggs
   * @param _eggShopTypeQtys the array of quantity to mint eggShop eggs
   * @param _farmAnimalTypeIds the array of farmAnimals special mint typeIds (0 => hen, 1 => coyote, 2 => rooster, 3 => random, 4 => twin hens, 5 special random)
   * @param _farmAnimalTypeQtys the array of farmAnimals special mint quantities
   * @param _imperialEggsQtys the count to mint Imperial Eggs
   * @param _bonusEGGDuration the duration of EGG bonus production in mins
   * @param _bonusEGGPercentage the percentage of EGG bonus production
   * @param _bonusEGGAmount the amount to mint EGG token directly
   * @param _specialMintFee the price of special mint reward
   * @param _maxSupply the max supply of special mint reward by specialTokenId
   */

  function updateSpecialMint(
    uint256 _typeId,
    uint256[] memory _eggShopTypeIds,
    uint16[] memory _eggShopTypeQtys,
    uint16[] memory _farmAnimalTypeIds,
    uint16[] memory _farmAnimalTypeQtys,
    uint256 _imperialEggsQtys,
    uint256 _bonusEGGDuration,
    uint16 _bonusEGGPercentage,
    uint256 _bonusEGGAmount,
    uint256 _specialMintFee,
    uint256 _maxSupply
  ) external onlyController {
    require(_typeId < specialMints.length, "Special Mint Reward TypeId doesn't exist");
    require(_eggShopTypeIds.length == _eggShopTypeQtys.length, 'SpecialInfo length is not equal');
    require(_farmAnimalTypeIds.length == _farmAnimalTypeQtys.length, 'SpecialInfo length is not equal');
    require(_maxSupply > 0, 'Max Supply should be greater than zero');
    require(_specialMintFee > 0, 'Special Mint Reward price should be greater than zero');

    uint256 typeId = _typeId - 1;

    SpecialMints memory _specialMint = specialMints[typeId];
    specialMints[typeId] = SpecialMints(
      _typeId,
      _eggShopTypeIds,
      _eggShopTypeQtys,
      _farmAnimalTypeIds,
      _farmAnimalTypeQtys,
      _imperialEggsQtys,
      _bonusEGGDuration,
      _bonusEGGPercentage,
      _bonusEGGAmount,
      _specialMintFee,
      _maxSupply,
      _specialMint.minted
    );
    emit Update(_typeId, _maxSupply, _specialMintFee);
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';

pragma solidity ^0.8.17;

interface IEggShop is IERC1155Upgradeable {
  struct TypeInfo {
    uint16 mints;
    uint16 burns;
    uint256 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
  }

  struct DetailedTypeInfo {
    uint16 mints;
    uint16 burns;
    uint256 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
    string name;
  }

  function mint(
    uint256 typeId,
    uint16 qty,
    address recipient,
    uint256 eggAmt
  ) external;

  function mintFree(
    uint256 typeId,
    uint16 quantity,
    address recipient
  ) external;

  function burn(
    uint256 typeId,
    uint16 qty,
    address burnFrom,
    uint256 eggAmt
  ) external;

  // function balanceOf(address account, uint256 id) external returns (uint256);

  function getInfoForType(uint256 typeId) external view returns (TypeInfo memory);

  function getInfoForTypeName(uint256 typeId) external view returns (DetailedTypeInfo memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol';

interface IFarmAnimals is IERC721AQueryableUpgradeable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint256 tokenId) external;

  function maxGen0Supply() external view returns (uint256);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint256 tokenId) external view returns (Traits memory);

  function mintSeeds(address recipient, uint256[] calldata seeds) external;

  function mintTwins(
    uint256 seed,
    address recipient1,
    address recipient2
  ) external;

  function minted() external view returns (uint256);

  function mintedRoosters() external returns (uint256);

  function pickKind(uint256 seed, uint16 specificKind) external view returns (Kind k);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function updateAdvantage(
    uint256 tokenId,
    uint8 score,
    bool decrement
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouseAdvantage {
  // struct to store the production bonus info of all nfts
  struct AdvantageBonus {
    uint256 tokenId;
    uint256 bonusPercentage;
    uint256 bonusDurationMins;
    uint256 startTime;
  }

  function addAdvantageBonus(
    uint256 tokenId,
    uint256 _durationMins,
    uint256 _percentage
  ) external;

  function removeAdvantageBonus(uint256 tokenId) external;

  function getAdvantageBonus(uint256 tokenId) external view returns (AdvantageBonus memory);

  function updateAdvantageBonus(uint256 tokenId) external;

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import 'erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol';

interface IImperialEggs {
  function mint(address receipt, uint256 _mintAmount) external;

  function maxSupply() external view returns (uint256);

  function minted() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IRandomizer {
  function random() external view returns (uint256);

  function randomToken(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface ISpecialMint {
  function getSpecialMintReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface ITheFarmGameMint {
  function addCommitRandom(uint256 seed) external;

  function canMint() external view returns (bool);

  function commitRandomNeeded() external returns (bool);

  function getPendingMintQty() external returns (uint16);

  function getSaleStatus() external view returns (string memory);

  function mint(uint256 quantity, bool stake) external payable;

  function mintCommitGen0(uint16 quantity, bool stake) external payable;

  function mintCommitGen1(uint256 quantity, bool stake) external;

  function allowListTime() external returns (uint256);

  function mintCostEGG(uint256 tokenId) external view returns (uint256);

  function mintReveal() external;

  function paused() external view returns (bool);

  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof,
    uint256 maxQuantity,
    uint256 priceInWei
  ) external payable;

  function preSaleTokens() external view returns (uint256);

  function preSalePrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721AUpgradeable.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryableUpgradeable is IERC721AUpgradeable {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}