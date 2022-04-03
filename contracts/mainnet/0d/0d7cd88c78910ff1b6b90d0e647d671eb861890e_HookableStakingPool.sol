// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './StakingPool.sol';

contract HookableStakingPool is StakingPool {
  address public hookAddress;

  constructor(address tokenAddress) StakingPool(tokenAddress) {}

  function setHookAddress(address hookAddress_) external onlyOwner {
    hookAddress = hookAddress_;
  }

  function _beforeStake(uint256 tokenId, address owner)
    internal
    virtual
    override
  {
    if (hookAddress != address(0)) {
      StakingHook(hookAddress).onStake(tokenId, owner);
    }
  }

  function _beforeUnstake(uint256 tokenId, address owner)
    internal
    virtual
    override
  {
    if (hookAddress != address(0)) {
      StakingHook(hookAddress).onUnstake(tokenId, owner);
    }
  }
}

interface StakingHook {
  function onStake(uint256 tokenId, address owner) external;

  function onUnstake(uint256 tokenId, address owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract StakingPool is Ownable, IERC721Receiver {
  event Stake(address indexed owner, uint256 indexed tokenId);
  event Unstake(address indexed owner, uint256 indexed tokenId);

  IERC721 public tokenContract;

  mapping(address => uint16[]) private _staked;

  constructor(address tokenAddress) {
    tokenContract = IERC721(tokenAddress);
  }

  function stakedTokens(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint16[] memory staked = _staked[owner];
    uint256 numTokens = staked.length;

    uint256[] memory tokenIds = new uint256[](numTokens);
    for (uint256 i; i < numTokens; ++i) {
      tokenIds[i] = staked[i];
    }

    return tokenIds;
  }

  function stake(uint256 tokenId) external {
    tokenContract.safeTransferFrom(_msgSender(), address(this), tokenId);
  }

  function batchStake(uint256[] calldata tokenIds) external {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      tokenContract.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
    }
  }

  function _stake(uint256 tokenId, address owner) internal {
    _beforeStake(tokenId, owner);

    _staked[owner].push(uint16(tokenId));
    emit Stake(owner, tokenId);
  }

  function _beforeStake(uint256 tokenId, address owner) internal virtual {}

  function unstake(uint256 tokenId) external {
    _unstake(tokenId, _msgSender());
  }

  function batchUnstake(uint256[] calldata tokenIds) external {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      _unstake(tokenIds[i], _msgSender());
    }
  }

  function unstakeAll() external {
    _unstakeAll(_msgSender());
  }

  function _unstakeAll(address owner) internal {
    uint256 stakedCount = _staked[owner].length;
    for (uint256 i = stakedCount; i > 0; --i) {
      _unstakeIndex(i - 1, owner);
    }
  }

  function _unstake(uint256 tokenId, address owner) internal {
    uint256 stakedCount = _staked[owner].length;
    for (uint256 i; i < stakedCount; ++i) {
      if (_staked[owner][i] == tokenId) {
        _unstakeIndex(i, owner);
        break;
      }
    }
  }

  function unstakeIndex(uint256 index) external {
    _unstakeIndex(index, _msgSender());
  }

  function batchUnstakeIndex(uint256[] memory indices) external {
    _sort(indices, _staked[_msgSender()].length);

    // iterate in reverse order
    for (uint256 i = indices.length; i > 0; --i) {
      _unstakeIndex(indices[i - 1], _msgSender());
    }
  }

  function _unstakeIndex(uint256 index, address owner) internal {
    uint16 tokenId = _staked[owner][index];
    _beforeUnstake(tokenId, owner);

    uint256 lastIndex = _staked[owner].length - 1;
    if (index != lastIndex) {
      _staked[owner][index] = _staked[owner][lastIndex]; // swap with last item
    }
    _staked[owner].pop();

    tokenContract.safeTransferFrom(address(this), owner, tokenId);
    emit Unstake(owner, tokenId);
  }

  function _beforeUnstake(uint256 tokenId, address owner) internal virtual {}

  function forceUnstake(address owner) external onlyOwner {
    _unstakeAll(owner);
  }

  // unique counting sort
  function _sort(uint256[] memory data, uint256 setSize) internal pure {
    uint256 length = data.length;
    bool[] memory set = new bool[](setSize);
    for (uint256 i = 0; i < length; ++i) {
      set[data[i]] = true;
    }
    uint256 n = 0;
    for (uint256 i = 0; i < setSize; ++i) {
      if (set[i]) {
        data[n] = i;
        if (++n >= length) break;
      }
    }
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _staked[owner].length;
  }

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public virtual override returns (bytes4) {
    require(_msgSender() == address(tokenContract), 'Unknown token contract');

    address owner = data.length > 0 ? abi.decode(data, (address)) : from;
    _stake(tokenId, owner);
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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