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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IGlitter.sol";
import "./interfaces/IQ00tantSquad.sol";
import "./interfaces/IQ00nicornSquad.sol";
import "./OwnableEpochContract.sol";


error NotASquadContract();
error NotOwner();
error AlreadyRegistered();
error RecentlyMined();
error GlitterIsGuarded();
error SquadIsDefeated();
error CannotReplaceActiveSquad();
error UnderpoweredSquad();
error UnregisteredSquad();

contract Frontlines is OwnableEpochContract {
  //  https://gist.github.com/ea7cf379950154f31b4fb7b51b2b3895 // yes with 200 runs.

  bytes32 private constant q00tantSquadCodeHash = 0x7446750a89f01b0df07d957745cb5d1a49aa38c9a776062cde73245a098bb614;
  // 0xfa8372cca93e074af18617a088d38b97ae6f138dbcb1d957e9d679c9ff6d1463
  bytes32 private constant cornSquadCodeHash = 0x5987bb8bdd050e9b1b27079d47b3271c8fd4ac0f001772221bcded2ff238fba5;
  // 0x8b351bf9c14707f7af4d38de2e2c2e2163a2e373f2aa7c0dfe2f26fa5f77e182

  event Q00tantsDefeated(address attackingSquad, address defendingSquad, uint256 timestamp);
  event Q00nicornsDefeated(address attackingSquad, address defendingSquad, uint256 timestamp);

  mapping(address => bool) public q00tantSquads;
  mapping(address => bool) public cornSquads;

  mapping(address => bool) public deployers;

  mapping(uint256 => uint256) miners;
  mapping(uint256 => uint256) cornMiners;

  address public activeQ00tantSquad;
  uint256 public unguardedAt;

  uint256 public q00tantPoints;
  uint256 public q00nicornPoints;

  IERC721 q00tants = IERC721(0x9F7C5D43063e3ECEb6aE43A22b669BB01fD1039A);
  IGlitter glitter = IGlitter(0xB4849f82E4449f539314059842173db32509f022);
  IERC721 q00nicorns = IERC721(0xc8Dc0f7B8Ca4c502756421C23425212CaA6f0f8A);

  // Q00TANT FUNCTIONS //

  constructor() {
    unguardedAt = block.timestamp + 12 hours;
  }

  function registerQ00tantSquad(address _squadContract) external {
    address owner = IQ00tantSquad(_squadContract).owner();
    if (q00tantSquads[_squadContract] || deployers[owner]) revert AlreadyRegistered();

    bytes32 codeHash;
    assembly { codeHash := extcodehash(_squadContract) }
    if (codeHash != q00tantSquadCodeHash) revert NotASquadContract();

    q00tantSquads[_squadContract] = true;
    deployers[owner] = true;
    epochRegistry.setEpochContract(_squadContract, true);
  }


  function mine(uint256 _tokenId) external {
    if (q00tants.ownerOf(_tokenId) != msg.sender) revert NotOwner();
    if (miners[_tokenId] > block.timestamp) revert RecentlyMined();
    miners[_tokenId] = block.timestamp + 24 hours;

    glitter.mint(msg.sender, 25_000000000000000000);
    q00tantPoints += 25;
  }

  // Q00NICORN FUNCTIONS //

  function registerCornSquad(address _squadContract) external {
    address owner = IQ00nicornSquad(_squadContract).owner();
    if (cornSquads[_squadContract] || deployers[owner]) revert AlreadyRegistered();

    bytes32 codeHash;
    assembly { codeHash := extcodehash(_squadContract) }
    if (codeHash != cornSquadCodeHash) revert NotASquadContract();

    deployers[owner] = true;
    cornSquads[_squadContract] = true;
    epochRegistry.setEpochContract(_squadContract, true);
  }

  function setDefendingQ00tantSquad(address _q00tantSquad) external {
    IQ00tantSquad q00tantSquad = IQ00tantSquad(_q00tantSquad);
    if (q00tantSquad.isDefeated()) revert SquadIsDefeated();
    if (activeQ00tantSquad != address(0)) revert CannotReplaceActiveSquad();
    if (q00tants.balanceOf(_q00tantSquad) < 5) revert UnderpoweredSquad();
    if (!q00tantSquads[_q00tantSquad]) revert UnregisteredSquad();

    activeQ00tantSquad = _q00tantSquad;
  }

  function conductHeist(uint256 _tokenId) external {
    if (q00nicorns.ownerOf(_tokenId) != msg.sender) revert NotOwner();
    if (cornMiners[_tokenId] > block.timestamp) revert RecentlyMined();
    if (unguardedAt > block.timestamp || activeQ00tantSquad != address(0)) revert GlitterIsGuarded();
    cornMiners[_tokenId] = block.timestamp + 2 hours;

    glitter.mint(msg.sender, 50_000000000000000000);
    q00nicornPoints += 50;
  }

  function attack(address _cornSquad) external {
    if (!cornSquads[_cornSquad]) revert UnregisteredSquad();
    IQ00nicornSquad cornSquad = IQ00nicornSquad(_cornSquad);
    bool success = cornSquad.attack(activeQ00tantSquad);

    if (success) {
      uint256 balance = glitter.balanceOf(activeQ00tantSquad);

      if (balance > 0) {
        glitter.transferFrom(activeQ00tantSquad, msg.sender, balance);
      }

      IQ00tantSquad q00tantSquad = IQ00tantSquad(activeQ00tantSquad);
      q00tantSquad.setAsDefeated();
      emit Q00tantsDefeated(_cornSquad, activeQ00tantSquad, block.timestamp);

      activeQ00tantSquad = address(0);
      unguardedAt = block.timestamp + 6 hours;
      q00nicornPoints += balance / 1e18;
    } else {
      cornSquad.setAsDefeated();
      emit Q00nicornsDefeated(_cornSquad, activeQ00tantSquad, block.timestamp);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IGlitter {
  function burn(address from, uint256 amount) external;
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IQ00nicornSquad {
  function attack(address _q00tantSquadAddress) external returns (bool);
  function isDefeated() external view returns (bool);
  function setAsDefeated() external;
  function depositCorns(uint256[] calldata tokenIds) external;
  function owner() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IQ00tantSquad {
  function isDefeated() external view returns (bool);
  function setAsDefeated() external;
  function defend() external view returns (uint16);
  function depositQ00tants(uint256[] calldata tokenIds) external;
  function owner() external returns (address);
}