// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zeemtrade is Ownable, IERC721Receiver {

  uint256 private _swapsCounter;
  uint256 private _etherLocked;

  uint256 public fee;

  mapping (uint256 => Swap) private _swaps;

  struct Swap {
    address payable initiator;
    address[] initiatorNftAddresses;
    uint256[] initiatorNftIds;
    uint256 initiatorEtherValue;
    address payable secondUser;
    address[] secondUserNftAddresses;
    uint256[] secondUserNftIds;
    uint256 secondUserEtherValue;
  }

  event SwapExecuted(address indexed from, address indexed to, uint256 indexed swapId);
  event SwapCanceled(address indexed canceledBy, uint256 indexed swapId);
  event SwapProposed(
    address indexed from,
    address indexed to,
    uint256 indexed swapId,
    address[] nftAddresses,
    uint256[] nftIds,
    uint256 etherValue
  );
  event SwapInitiated(
    address indexed from,
    address indexed to,
    uint256 indexed swapId,
    address[] nftAddresses,
    uint256[] nftIds,
    uint256 etherValue
  );
  event AppFeeChanged(
    uint256 fee
  );

  modifier onlyInitiator(uint256 swapId) {
    require(msg.sender == _swaps[swapId].initiator,
      "Zeem.trade: caller is not swap initiator");
    _;
  }

  modifier requireSameLength(address[] memory nftAddresses, uint256[] memory nftIds) {
    require(nftAddresses.length == nftIds.length, "Zeem.trade: NFT and ID arrays have to be same length");
    _;
  }

  modifier chargeAppFee() {
    require(msg.value >= fee, "Zeem.trade: Sent ETH amount needs to be more or equal application fee");
    _;
  }

  constructor(uint256 initalAppFee, address contractOwnerAddress) {
    fee = initalAppFee;
    super.transferOwnership(contractOwnerAddress);
  }

  function setAppFee(uint newFee) external onlyOwner {
    fee = newFee;
    emit AppFeeChanged(newFee);
  }

  /**
    * @dev First user proposes a swap to the second user with the NFTs that he deposits and wants to trade.
    *      Proposed NFTs are transfered to the Zeem.trade contract and
    *      kept there until the swap is accepted or canceled/rejected.
    *
    * @param secondUser address of the user that the first user wants to trade NFTs with
    * @param nftAddresses array of NFT addressed that want to be traded
    * @param nftIds array of IDs belonging to NFTs that want to be traded
    */
  function proposeSwap(address secondUser, address[] memory nftAddresses, uint256[] memory nftIds)
    external payable chargeAppFee requireSameLength(nftAddresses, nftIds) {
      _swapsCounter += 1;

      safeMultipleTransfersFrom(
        msg.sender,
        address(this),
        nftAddresses,
        nftIds
    );

      Swap storage swap = _swaps[_swapsCounter];
      swap.initiator = payable(msg.sender);
      swap.initiatorNftAddresses = nftAddresses;
      swap.initiatorNftIds = nftIds;
      if (msg.value > fee) {
        swap.initiatorEtherValue = msg.value - fee;
        _etherLocked += swap.initiatorEtherValue;
      }
      swap.secondUser = payable(secondUser);


      emit SwapProposed(msg.sender, secondUser, _swapsCounter, nftAddresses, nftIds, swap.initiatorEtherValue);
  }

  /**
    * @dev Second user accepts the swap (with proposed NFTs) from swap initiator and
    *      deposits his NFTs into the Zeem.trade contract.
    *      Callable only by second user that is invited by swap initiator.
    *
    * @param swapId ID of the swap that the second user is invited to participate in
    * @param nftAddresses array of NFT addressed that want to be traded
    * @param nftIds array of IDs belonging to NFTs that want to be traded
    */
  function initiateSwap(uint256 swapId, address[] memory nftAddresses, uint256[] memory nftIds)
    external payable chargeAppFee requireSameLength(nftAddresses, nftIds) {
      require(_swaps[swapId].secondUser == msg.sender, "Zeem.trade: caller is not swap participator");
      require(
        _swaps[swapId].secondUserEtherValue == 0 &&
        ( _swaps[swapId].secondUserNftAddresses.length == 0 && _swaps[swapId].secondUserNftIds.length == 0),
        "Zeem.trade: swap already initiated"
      );

      safeMultipleTransfersFrom(
        msg.sender,
        address(this),
        nftAddresses,
        nftIds
    );

      _swaps[swapId].secondUserNftAddresses = nftAddresses;
      _swaps[swapId].secondUserNftIds = nftIds;
      if (msg.value > fee) {
        _swaps[swapId].secondUserEtherValue = msg.value - fee;
        _etherLocked += _swaps[swapId].secondUserEtherValue;
      }

      emit SwapInitiated(
        msg.sender,
        _swaps[swapId].initiator,
        swapId,
        nftAddresses,
        nftIds,
        _swaps[swapId].secondUserEtherValue
      );
  }

  /**
    * @dev Swap initiator accepts the swap (NFTs proposed by the second user).
    *      Executeds the swap - transfers NFTs from Zeem.trade to the participating users.
    *      Callable only by swap initiator.
    *
    * @param swapId ID of the swap that the initator wants to execute
    */
  function acceptSwap(uint256 swapId) external onlyInitiator(swapId) {
    require(
      (_swaps[swapId].secondUserNftAddresses.length != 0 || _swaps[swapId].secondUserEtherValue > 0) &&
      (_swaps[swapId].initiatorNftAddresses.length != 0 || _swaps[swapId].initiatorEtherValue > 0),
       "Zeem.trade: Can't accept swap, both participants didn't add NFTs"
    );

    // transfer NFTs from escrow to initiator
    safeMultipleTransfersFrom(
      address(this),
      _swaps[swapId].initiator,
      _swaps[swapId].secondUserNftAddresses,
      _swaps[swapId].secondUserNftIds
    );

    // transfer NFTs from escrow to second user
    safeMultipleTransfersFrom(
      address(this),
      _swaps[swapId].secondUser,
      _swaps[swapId].initiatorNftAddresses,
      _swaps[swapId].initiatorNftIds
    );

    if (_swaps[swapId].initiatorEtherValue != 0) {
      _etherLocked -= _swaps[swapId].initiatorEtherValue;
      uint amountToTransfer = _swaps[swapId].initiatorEtherValue;
      _swaps[swapId].initiatorEtherValue = 0;
      _swaps[swapId].secondUser.transfer(amountToTransfer);
    }
    if (_swaps[swapId].secondUserEtherValue != 0) {
      _etherLocked -= _swaps[swapId].secondUserEtherValue;
      uint amountToTransfer = _swaps[swapId].secondUserEtherValue;
      _swaps[swapId].secondUserEtherValue = 0;
      _swaps[swapId].initiator.transfer(amountToTransfer);
    }

    emit SwapExecuted(_swaps[swapId].initiator, _swaps[swapId].secondUser, swapId);

    delete _swaps[swapId];
  }

  /**
    * @dev Returns NFTs from Zeem.trade to swap initator.
    *      Callable only if second user hasn't yet added NFTs.
    *
    * @param swapId ID of the swap that the swap participants want to cancel
    */
  function cancelSwap(uint256 swapId) external {
    require(
      _swaps[swapId].initiator == msg.sender || _swaps[swapId].secondUser == msg.sender,
      "Zeem.trade: Can't cancel swap, must be swap participant"
    );
      // return initiator NFTs
      safeMultipleTransfersFrom(
        address(this),
        _swaps[swapId].initiator,
        _swaps[swapId].initiatorNftAddresses,
        _swaps[swapId].initiatorNftIds
      );

    if(_swaps[swapId].secondUserNftAddresses.length != 0) {
      // return second user NFTs
      safeMultipleTransfersFrom(
        address(this),
        _swaps[swapId].secondUser,
        _swaps[swapId].secondUserNftAddresses,
        _swaps[swapId].secondUserNftIds
      );
    }

    if (_swaps[swapId].initiatorEtherValue != 0) {
      _etherLocked -= _swaps[swapId].initiatorEtherValue;
      uint amountToTransfer = _swaps[swapId].initiatorEtherValue;
      _swaps[swapId].initiatorEtherValue = 0;
      _swaps[swapId].initiator.transfer(amountToTransfer);
    }
    if (_swaps[swapId].secondUserEtherValue != 0) {
      _etherLocked -= _swaps[swapId].secondUserEtherValue;
      uint amountToTransfer = _swaps[swapId].secondUserEtherValue;
      _swaps[swapId].secondUserEtherValue = 0;
      _swaps[swapId].secondUser.transfer(amountToTransfer);
    }

    emit SwapCanceled(msg.sender, swapId);

    delete _swaps[swapId];
  }

  function safeMultipleTransfersFrom(
      address from,
      address to,
      address[] memory nftAddresses,
      uint256[] memory nftIds
    ) internal virtual {
    for (uint256 i=0; i < nftIds.length; i++){
      safeTransferFrom(from, to, nftAddresses[i], nftIds[i], "");
    }
  }

  function safeTransferFrom(
      address from,
      address to,
      address tokenAddress,
      uint256 tokenId,
      bytes memory _data
    ) internal virtual {
    IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, _data);
  }

  function withdrawEther(address payable recipient) external onlyOwner {
    require(recipient != address(0), "zeem.trade transfer to the zero address");

    recipient.transfer((address(this).balance - _etherLocked));
  }

  function onERC721Received(
    /* solhint-disable */
      address operator,
      address from,
      uint256 tokenId,
      bytes calldata data
    /* solhint-enable */
    ) external pure override returns (bytes4) {
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}

pragma solidity ^0.8.7;

interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);

}
pragma solidity ^0.8.7;

interface DividendPayingTokenInterface {
  function dividendOf(address _owner) external view returns(uint256);
  function withdrawDividend() external;
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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