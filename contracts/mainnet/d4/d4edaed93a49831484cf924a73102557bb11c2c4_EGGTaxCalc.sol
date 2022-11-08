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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/IRandomizer.sol';
import './interfaces/IEGGTaxCalc.sol';

contract EGGTaxCalc is IEGGTaxCalc, Ownable {
  event InitializedContract(address thisContract);

  struct ExtNFTBenefits {
    address contractAddress; // Contract that holds an NFT
    bool isERC1155; // If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
    // If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
    uint256 typeId; // TypeId of token in ERC1155
    uint256 taxChance; // The percentage that a tax rate will be applied 0-100%. 10000 = 100%, 500 = 5%
    uint256 splitTaxRateFrom; // If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
    uint256 splitTaxRateTo; // If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
  }

  ExtNFTBenefits[] private extNFTBenefits;

  IRandomizer public randomizer; // Reference to Randomizer

  uint256 private _splitTaxRateFrom = 500; // Default Start tax rate to split the tax amount. 500 = 5%
  uint256 private _splitTaxRateTo = 1000; // Default End tax rate to split the tax amount. 1000 = 10%
  uint256 private TAX_CHANCE = 5000; // Default tax chance rate. 5000 = 50%

  mapping(address => bool) private controllers;

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

  constructor(IRandomizer _randomizer) {
    randomizer = _randomizer;
    controllers[_msgSender()] = true;
    emit InitializedContract(address(this));
  }

  /**
   * @notice Return taxRate and taxChance values regarding ExtNFTBenefits logic
   * @param sender Sender address when the tokens transfer
   * returns (taxRate, taxChance)
   */

  function getTaxRate(address sender) external view override returns (uint256, uint256) {
    uint256 taxChance = 1;
    uint256 splitTaxRateFrom = 1;
    uint256 splitTaxRateTo = 1;
    for (uint8 i = 0; i < extNFTBenefits.length; i++) {
      uint256 balance = 0;
      ExtNFTBenefits memory _extNFTBenefit = extNFTBenefits[i];

      if (_extNFTBenefit.isERC1155) {
        balance = IERC1155(_extNFTBenefit.contractAddress).balanceOf(sender, _extNFTBenefit.typeId);
      } else {
        balance = IERC721(_extNFTBenefit.contractAddress).balanceOf(sender);
      }

      if (balance > 0) {
        if ((taxChance == 0 && _extNFTBenefit.taxChance > 0) || taxChance > _extNFTBenefit.taxChance) {
          taxChance = _extNFTBenefit.taxChance;
        }

        if (
          (splitTaxRateFrom == 0 && _extNFTBenefit.splitTaxRateFrom > 0) ||
          splitTaxRateFrom > _extNFTBenefit.splitTaxRateFrom
        ) {
          splitTaxRateFrom = _extNFTBenefit.splitTaxRateFrom;
        }

        if (
          (splitTaxRateTo == 0 && _extNFTBenefit.splitTaxRateTo > 0) || splitTaxRateTo > _extNFTBenefit.splitTaxRateTo
        ) {
          splitTaxRateTo = _extNFTBenefit.splitTaxRateTo;
        }
      }
    }

    if (taxChance == 0) {
      taxChance = TAX_CHANCE;
    }

    if (splitTaxRateFrom == 0) {
      splitTaxRateFrom = _splitTaxRateFrom;
    }

    if (splitTaxRateTo == 0) {
      splitTaxRateTo = _splitTaxRateTo;
    }

    uint256 randomTaxRate = (randomizer.random() % (splitTaxRateTo - (splitTaxRateFrom + 1))) + splitTaxRateFrom;

    return (randomTaxRate, taxChance);
  }

  /**
   * @notice Set the default from percentage number to apply tax amount
   * @dev Only callable by an existing controller
   * @param splitTaxRateFrom Number of the start percentage to split tax
   */

  function setSplitTaxRateFrom(uint256 splitTaxRateFrom) external onlyController {
    _splitTaxRateFrom = splitTaxRateFrom;
  }

  /**
   * @notice Set the default to percentage number to apply tax amount
   * @dev Only callable by an existing controller
   * @param splitTaxRateTo Number of the end percentage to split tax
   */

  function setSplitTaxRateTo(uint256 splitTaxRateTo) external onlyController {
    _splitTaxRateTo = splitTaxRateTo;
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
   * @notice Add new ExtNFTBenefit data for calculating taxChance and taxRate of EGGToken contract
   * @param _contractAddress Contract that holds an NFT
   * @param _isERC1155  If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
   *                    If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
   * @param _taxChance The percentage that a tax rate will be applied 0-100% (10000 = 100%, 100 = 1%)
   * @param splitTaxRateFrom If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
   * @param splitTaxRateTo If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
   */

  function addExtNFTBenefits(
    address _contractAddress,
    bool _isERC1155,
    uint256 _typeId,
    uint256 _taxChance,
    uint256 splitTaxRateFrom,
    uint256 splitTaxRateTo
  ) external onlyController {
    require(_contractAddress != address(0), "Contract address can't be zero.");
    extNFTBenefits.push(
      ExtNFTBenefits(_contractAddress, _isERC1155, _typeId, _taxChance, splitTaxRateFrom, splitTaxRateTo)
    );
  }

  /**
   * @notice Get ExtNFTBenefits data regarding id
   */

  function getExtNFTBenefits(uint8 id) external view returns (ExtNFTBenefits memory) {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    return extNFTBenefits[id];
  }

  /**
   * @notice Update new ExtNFTBenefit data for calculating taxChance and taxRate of EGGToken contract regarding id
   * @param _contractAddress Contract that holds an NFT
   * @param _isERC1155  If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
   *                    If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
   * @param _taxChance The percentage that a tax rate will be applied 0-100%
   * @param splitTaxRateFrom If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
   * @param splitTaxRateTo If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
   */

  function updateExtNFTBenefits(
    uint8 id,
    address _contractAddress,
    bool _isERC1155,
    uint256 _typeId,
    uint256 _taxChance,
    uint256 splitTaxRateFrom,
    uint256 splitTaxRateTo
  ) external onlyController {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    require(_contractAddress != address(0), "Contract address can't be zero.");

    extNFTBenefits[id] = ExtNFTBenefits(
      _contractAddress,
      _isERC1155,
      _typeId,
      _taxChance,
      splitTaxRateFrom,
      splitTaxRateTo
    );
  }

  /**
   * @notice Set contract address
   * @dev Only callable by an existing controller
   * @param _address Address of randomizer contract
   */

  function setRandomizer(address _address) external onlyController {
    randomizer = IRandomizer(_address);
  }

  /**
   * @notice Remove ExtNFTBenefits data regarding id
   */

  function removeExtNFTBenefits(uint8 id) external onlyController {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    ExtNFTBenefits memory lastExtNFTBenefits = extNFTBenefits[extNFTBenefits.length - 1];
    extNFTBenefits[id] = lastExtNFTBenefits; //  Shuffle last ExtNFTBenefits to current position
    extNFTBenefits.pop();
  }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for EGGTaxCalc

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

interface IEGGTaxCalc {
  function getTaxRate(address sender) external view returns (uint256, uint256);
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