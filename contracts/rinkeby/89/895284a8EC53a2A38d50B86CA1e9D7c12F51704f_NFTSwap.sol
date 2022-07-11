pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTSwap is 
  ReentrancyGuard,
  Ownable
{
    address payable public swapOwner;

    using Counters for Counters.Counter;
    Counters.Counter private _itemCounter;
    Counters.Counter private _itemSoldCounter;

    uint256 public swapFee = 10000000000000000; // 0.01 ETH

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint256[] ids;
    }

    enum State { Created, Release, Cancel }
    
    struct SwapItem {
        uint256 id;
        ERC721Details[] erc721Tokens;
        ERC20Details erc20Tokens;
        address payable seller;
        address payable buyer;
        uint256 offerCount;
        State state;
    }

    struct SwapOffer {
        uint256 id;
        uint256 swapItemId;
        ERC721Details[] erc721Tokens;
        ERC20Details erc20Tokens;
        address payable buyer;
        uint256 offerEndTime;
        uint256 creationTime;
    }

    mapping(uint256 => SwapItem) private swapItems;
    mapping(uint256 => mapping(uint256 => SwapOffer)) private swapOffers;
    
    bool openSwap = false;

    event SwapItemCreated (
        uint256 swapItemID,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens,
        address seller,
        address buyer,
        State state
    );

    event SwapItemSold (
        uint256 swapItemID,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens,
        address seller,
        address buyer,
        State state
    );

    event SwapOfferCreated (
        uint256 swapItemID,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens,
        address buyer,
        uint256 creationTime
    );

    constructor() {
        swapOwner = payable(msg.sender);
    }
    
    /**
     * Manage the Swap
     */
    function setOpenOffer(bool _new) external onlyOwner {
        openSwap = _new;
    }

    /**
     * Set the Swap Owner Address
     */
    function setSwapOwner(address swapper) external onlyOwner {
        swapOwner = payable(swapper);
    }

    /**
     * Checking the assets
     */
    function _checkAssets(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address offer
    ) internal view {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                require(IERC721(erc721Details[i].tokenAddr).getApproved(erc721Details[i].ids[j]) == address(this), "ERC721 tokens must be approved to swap contract");
            }
        }

        // check duplicated token address
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            uint256 tokenCount = 0;
            for (uint256 j = 0; j < erc20Details.tokenAddrs.length; j++) {
                if (erc20Details.tokenAddrs[i] == erc20Details.tokenAddrs[j]) {
                    tokenCount ++;
                }
            }

            require(tokenCount == 1, "Invalid ERC20 tokens");
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            require(IERC20(erc20Details.tokenAddrs[i]).allowance(offer, address(this)) >= erc20Details.amounts[i], "ERC20 tokens must be approved to swap contract");
        }
    }

    /**
     * Transfer assets to Swap Contract
     */
    function _transferAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transferFrom(from, to, erc20Details.amounts[i]);
        }
    }

    /**
     * Return assets to holders
     * ERC20 requires approve from contract to holder
     */
    function _returnAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transfer(to, erc20Details.amounts[i]);
        }
    }

    /**
     * create a SwapItem for ERC721 + ERC20 on the Swap List
     * List an NFT
     * 
     * Warning User needs to approve assets before list
     */
    function createSwapItem (
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details
    ) public payable nonReentrant {
        require(openSwap, "Swap is not opended");
        require(msg.value == swapFee, "Fee must be equal to listing fee");
        require(erc721Details.length > 0, "SwapItems must include ERC721");
        
        _checkAssets(erc721Details, erc20Details, msg.sender);

        _transferAssetsHelper(erc721Details, erc20Details, msg.sender, address(this));
        
        _itemCounter.increment();

        uint256 id = _itemCounter.current();
        SwapItem storage newItem = swapItems[id];
        newItem.id = id;
        newItem.erc20Tokens = erc20Details;
        newItem.seller = payable(msg.sender);
        newItem.buyer = payable(address(0));
        newItem.offerCount = 0;
        newItem.state = State.Created;
        for (uint256 i = 0; i < erc721Details.length; i++) {
            newItem.erc721Tokens.push(erc721Details[i]);
        }

        emit SwapItemCreated(
            id,
            erc721Details,
            erc20Details,
            msg.sender,
            address(0),
            State.Created
        );
    }

    /**
     * create the SwapOfferItem
     */
    function createSwapOffer(
        uint256 itemNumber,
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        uint256 timeInterval
    ) public nonReentrant {
        require(erc721Details.length > 0, "SwapItems must include ERC721");
        require(swapItems[itemNumber].state == State.Created, "This Swap is finished");

        _checkAssets(erc721Details, erc20Details, msg.sender);

        _transferAssetsHelper(erc721Details, erc20Details, msg.sender, address(this));

        SwapOffer storage offer =  swapOffers[itemNumber][swapItems[itemNumber].offerCount];
        offer.id = swapItems[itemNumber].offerCount;
        offer.swapItemId = itemNumber;
        offer.erc20Tokens = erc20Details;
        offer.buyer = payable(msg.sender);
        offer.offerEndTime = block.timestamp + timeInterval;
        offer.creationTime = block.timestamp;
        for (uint256 i = 0; i < erc721Details.length; i++) {
            offer.erc721Tokens.push(erc721Details[i]);
        }
        
        swapItems[itemNumber].offerCount++;

        emit SwapOfferCreated(
            itemNumber,
            erc721Details,
            erc20Details,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * Confirm & Release the offer
     * Release Swap
     */
    function ConfirmSwap(
        uint256 itemNumber,
        uint256 offerNumber
    ) public nonReentrant {
        require(itemNumber <= _itemCounter.current(), "Non exist SwapItem");
        require(swapItems[itemNumber].seller == payable(msg.sender), "Allowed to only Owner of Assets");
        require(swapItems[itemNumber].state == State.Created, "SwapItem is released or canceled");
        require(swapOffers[itemNumber][offerNumber].offerEndTime > block.timestamp, "Offer time is up");

        _returnAssetsHelper(
            swapItems[itemNumber].erc721Tokens,
            swapItems[itemNumber].erc20Tokens,
            address(this),
            swapOffers[itemNumber][offerNumber].buyer
        );

        _returnAssetsHelper(
            swapOffers[itemNumber][offerNumber].erc721Tokens,
            swapOffers[itemNumber][offerNumber].erc20Tokens,
            address(this),
            msg.sender
        );

        swapItems[itemNumber].buyer = swapOffers[itemNumber][offerNumber].buyer;
        swapItems[itemNumber].state = State.Release;
        
        _itemSoldCounter.increment();

        delete swapOffers[itemNumber][offerNumber];

        swapOwner.transfer(swapFee);

        emit SwapItemSold (
            itemNumber,
            swapItems[itemNumber].erc721Tokens,
            swapItems[itemNumber].erc20Tokens,
            swapItems[itemNumber].seller,
            swapItems[itemNumber].buyer,
            State.Release
        );
    }

    /**
     * Cancel the SwapItem
     */
    function CancelSwapItem(
        uint256 itemNumber
    ) public nonReentrant {
        require(itemNumber <= _itemCounter.current(), "Non exist SwapItem");
        require(swapItems[itemNumber].seller == payable(msg.sender), "Allowed to only Owner of Assets");

        _returnAssetsHelper(
            swapItems[itemNumber].erc721Tokens,
            swapItems[itemNumber].erc20Tokens,
            address(this),
            msg.sender
        );

        swapItems[itemNumber].state = State.Cancel;
        
        payable(msg.sender).transfer(swapFee);

        emit SwapItemSold (
            itemNumber,
            swapItems[itemNumber].erc721Tokens,
            swapItems[itemNumber].erc20Tokens,
            swapItems[itemNumber].seller,
            swapItems[itemNumber].buyer,
            State.Cancel
        );
    }

    /**
     * Release & cancel the offer
     */
    function CancelOffer(
        uint256 itemNumber,
        uint256 offerNumber
    ) public nonReentrant {
        require(itemNumber <= _itemCounter.current(), "Non exist SwapItem");
        require(swapOffers[itemNumber][offerNumber].buyer == payable(msg.sender), "This offer is not your offer");

        _returnAssetsHelper(
            swapOffers[itemNumber][offerNumber].erc721Tokens,
            swapOffers[itemNumber][offerNumber].erc20Tokens,
            address(this),
            msg.sender
        );

        delete swapOffers[itemNumber][offerNumber];
    }

    enum FetchOperator { AllSwapItems, MySwapItems}

    /**
     * Fetch Condition
     */
    function SwapItemCondition(
        SwapItem memory item,
        FetchOperator _op,
        address seller
    ) private pure returns (bool) {
        if (_op == FetchOperator.AllSwapItems) {
            return (item.state == State.Created)
                ? true : false;
        } else {
            return (item.seller == payable(seller))
                ? true : false;
        }
    }
    
    /**
     * Fetch helper
     */
    function  fetchHelper(
        address seller,
        FetchOperator _op
    ) private view returns (SwapItem[] memory) {
        uint total = _itemCounter.current();
        uint itemCount = 0;
        for (uint i = 1; i <= total; i++) {
            if (SwapItemCondition(swapItems[i], _op, seller)) {
                itemCount ++;
            }
        }

        uint index = 0;
        SwapItem[] memory items = new SwapItem[](itemCount);
        for (uint i = 1; i <= total; i++) {
            if (SwapItemCondition(swapItems[i], _op, seller)) {
                items[index] = swapItems[i];
                index ++;
            }
        }

        return items;
    }
    
    /**
     * Fetch all created SwapItems
     */
    function GetSwapItems() public view returns (SwapItem[] memory) {
        return fetchHelper(address(this), FetchOperator.AllSwapItems);
    }

    /**
     * Fetch My SwapItems
     */
    function GetOwnedSwapItems(
        address seller
    ) public view returns (SwapItem[] memory) {
        return fetchHelper(seller, FetchOperator.MySwapItems);
    }

    /**
     * Get SwapItem by Index
     */
    function GetSwapItembyIndex(
        uint256 itemNumber
    ) public view returns (SwapItem memory) {
        return swapItems[itemNumber];
    }

    /**
     * Fetch My SwapOffers
     */
    function GetSwapOffers(
        address offer
    ) public view returns (SwapOffer[] memory) {
        uint total = _itemCounter.current();
        uint itemCount = 0;
        for (uint i = 1; i <= total; i++) {
            for (uint j = 0; j < swapItems[i].offerCount; j++) {
                if (swapOffers[i][j].buyer == offer) {
                    itemCount ++;
                }
            }
        }

        uint index = 0;
        SwapOffer[] memory items = new SwapOffer[](itemCount);
        for (uint i = 1; i <= total; i++) {
            for (uint j = 0; j < swapItems[i].offerCount; j++) {
                if (swapOffers[i][j].buyer == offer) {
                    items[index] = swapOffers[i][j];
                    index ++;
                }
            }
        }

        return items;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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