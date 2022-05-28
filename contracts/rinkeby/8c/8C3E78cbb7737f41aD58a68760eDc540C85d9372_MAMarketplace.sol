//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Mintable.sol";
import "./MAAuction.sol";

contract MAMarketplace is MAAuction {
    function createItem(uint256 tokenId, address owner) external whenNotPaused {
        Mintable(_nft721Address).mint(owner, tokenId);
    }

    function createItemWithAmount(
        uint256 tokenId,
        address owner,
        uint256 amount
    ) external whenNotPaused {
        Mintable(_nft1155Address).mint(owner, tokenId, amount);
    }

    function listItem(uint256 tokenId, uint256 price) external whenNotPaused {
        _checkIfNotExists(tokenId, _nft721Address);
        _listItemWithAmount(tokenId, _nft721Address, price, 1);
        _getNft721().safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function listItemWithAmount(
        uint256 tokenId,
        uint256 pricePerOne,
        uint256 amount
    ) external whenNotPaused {
        Lot storage item = _getLot(tokenId, _nft1155Address);
        _listItemWithAmount(
            tokenId,
            _nft1155Address,
            pricePerOne, //use new price for all
            item.amount + amount //increase amount
        );
        _getNft1155().safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
    }

    function buyItem(uint256 tokenId) external whenNotPaused {
        _buyItemWithAmount(tokenId, _nft721Address, 1);
        _getNft721().transferFrom(address(this), msg.sender, tokenId);
    }

    function buyItemWithAmount(uint256 tokenId, uint256 amount)
        external
        whenNotPaused
    {
        _buyItemWithAmount(tokenId, _nft1155Address, amount);
        _getNft1155().safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    function cancelItem(uint256 tokenId) external whenNotPaused {
        (address recipient, ) = _cancel(tokenId, _nft721Address);
        _getNft721().transferFrom(address(this), recipient, tokenId);
    }

    function cancelItemWithAmount(uint256 tokenId) external whenNotPaused {
        (address recipient, uint256 amount) = _cancel(tokenId, _nft1155Address);
        _getNft1155().safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
    }

    //########################### Private #####################################

    function _listItemWithAmount(
        uint256 tokenId,
        address token,
        uint256 pricePerOne,
        uint256 amount
    ) private {
        _setLotWithAmount(tokenId, token, msg.sender, pricePerOne, amount);
    }

    function _buyItemWithAmount(
        uint256 tokenId,
        address token,
        uint256 amount
    ) private {
        Lot memory item = _checkIfExists(tokenId, token);
        if (item.amount == amount) {
            _resetLot(tokenId, token);
        } else if (item.amount > amount) {
            _setLotWithAmount(
                tokenId,
                token,
                item.seller,
                item.startPrice,
                item.amount - amount
            );
        } else {
            revert("MAMarketplace: wrong amount");
        }

        IERC20(_exchangeToken).transferFrom(
            msg.sender,
            item.seller,
            item.startPrice * amount
        );
    }

    function _cancel(uint256 tokenId, address token)
        private
        returns (address nftRecipient, uint256 amount)
    {
        Lot memory item = _checkIfExists(tokenId, token);
        require(msg.sender == item.seller, "MAMarketplace: no access");
        _resetLot(tokenId, token);
        return (item.seller, item.amount);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Mintable is Ownable {
    address private _minter;

    modifier onlyMinter() {
        require(
            msg.sender == _minter,
            "Mintable: No Access"
        );
        _;
    }

    function setMinter(address newMinter) public onlyOwner {
        _minter = newMinter;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function mint(address to, uint256 tokenId) public onlyMinter {
        _internalMint(to, tokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public onlyMinter {
        _internalMint(to, tokenId, amount);
    }

    function _internalMint(
        address to,
        uint256 tokenId
    ) internal virtual {
        _internalMint(to, tokenId, 1);
    }

    function _internalMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MAStorage.sol";

contract MAAuction is MAStorage {
    struct Bid {
        address bidder;
        uint256 value;
        uint256 no;
    }

    uint256 public auctionDuration = 3 days;
    //LotHash => Bid info
    mapping(uint256 => Bid) private _bids;

    function getDetailsForItem(uint256 tokenId)
        public
        view
        returns (Lot memory lot, Bid memory bid)
    {
        return (
            _getLot(tokenId, _nft721Address),
            _getLastBid(tokenId, _nft721Address)
        );
    }

    function getDetailsForItemWithAmount(uint256 tokenId)
        public
        view
        returns (Lot memory lot, Bid memory bid)
    {
        return (
            _getLot(tokenId, _nft1155Address),
            _getLastBid(tokenId, _nft1155Address)
        );
    }

    function listItemOnAuction(uint256 tokenId, uint256 startPrice)
        public
        whenNotPaused
    {
        _listItemOnAuction(tokenId, _nft721Address, startPrice, 1);
        _getNft721().safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function listItemWithAmountOnAuction(
        uint256 tokenId,
        uint256 startPrice,
        uint256 amount
    ) public whenNotPaused {
        _listItemOnAuction(tokenId, _nft1155Address, startPrice, amount);
        _getNft1155().safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
    }

    function makeBid(uint256 tokenId, uint256 price) public whenNotPaused {
        _makeBid(tokenId, _nft721Address, price);
    }

    function makeBidForItemWithAmount(uint256 tokenId, uint256 price)
        public
        whenNotPaused
    {
        _makeBid(tokenId, _nft1155Address, price);
    }

    function finishAuction(uint256 tokenId) public whenNotPaused {
        (address recipient, ) = _finishAuction(tokenId, _nft721Address);

        _getNft721().transferFrom(address(this), recipient, tokenId);
    }

    function finishAuctionForItemWithAmount(uint256 tokenId)
        public
        whenNotPaused
    {
        (address recipient, uint256 amount) = _finishAuction(
            tokenId,
            _nft1155Address
        );

        _getNft1155().safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
    }

    //###################### Internal Overriden ###############################

    function _resetLot(uint256 tokenId, address token)
        internal
        virtual
        override
    {
        Bid storage bid = _updateBid(tokenId, token, address(0), 0);
        bid.no = 0;
        super._resetLot(tokenId, token);
    }

    //########################### Private #####################################

    function _listItemOnAuction(
        uint256 tokenId,
        address token,
        uint256 startPrice,
        uint256 amount
    ) private {
        _checkIfNotExists(tokenId, token);
        _setLotWithAmount(tokenId, token, msg.sender, startPrice, amount);
    }

    function _makeBid(
        uint256 tokenId,
        address token,
        uint256 price
    ) private {
        Lot memory lot = _checkIfExists(tokenId, token);
        require(
            block.timestamp < lot.startDate + auctionDuration,
            "MAAuction: auction has ended"
        );
        Bid memory lastBid = _getLastBid(tokenId, token);
        require(
            price >= lot.startPrice && price > lastBid.value, 
            "MAAuction: incorrect bid price"
        );

        _updateBid(tokenId, token, msg.sender, price);

        uint256 exchangeValue = msg.sender == lastBid.bidder
            ? price - lastBid.value
            : price;
        IERC20(_exchangeToken).transferFrom(
            msg.sender,
            address(this),
            exchangeValue
        );

        if (msg.sender == lastBid.bidder) return;
        if (lastBid.bidder == address(0)) return;

        IERC20(_exchangeToken).transfer(lastBid.bidder, lastBid.value);
    }

    function _finishAuction(uint256 tokenId, address token)
        private
        returns (address nftRecipient, uint256 amount)
    {
        Lot memory lot = _checkIfExists(tokenId, token);
        require(
            block.timestamp > lot.startDate + auctionDuration,
            "MAAuction: auction is not ended"
        );
        Bid memory lastBid = _getLastBid(tokenId, token);
        _resetLot(tokenId, token);

        address priceRecipient;
        if (lastBid.no >= 2) {
            //successful auction: exchange erc20 and NFT
            priceRecipient = lot.seller;
            nftRecipient = lastBid.bidder;
        } else {
            //cancelled auction: return tokens to owners
            priceRecipient = lastBid.bidder;
            nftRecipient = lot.seller;
        }
        IERC20(_exchangeToken).transfer(priceRecipient, lastBid.value);

        return (nftRecipient, lot.amount);
    }

    function _updateBid(
        uint256 tokenId,
        address token,
        address bidder,
        uint256 value
    ) private returns (Bid storage bid) {
        bid = _getLastBid(tokenId, token);
        bid.bidder = bidder;
        bid.value = value;
        bid.no++;

        return bid;
    }

    // todo: refatoring: should return both lot and bid
    function _getLastBid(uint256 tokenId, address token)
        private
        view
        returns (Bid storage)
    {
        Lot storage lot = _getLot(tokenId, token);
        uint256 lotHash = _getLotHash(
            _getTokenHash(tokenId, token),
            lot.startDate,
            lot.seller
        );
        return _bids[lotHash];
    }

    function _getLotHash(
        uint256 tokenHash,
        uint256 startDate,
        address seller
    ) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(tokenHash, startDate, seller)));
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./MAMAdmin.sol";

contract MAStorage is MAMAdmin {
    struct Lot {
        address seller;
        uint256 startPrice;
        uint256 startDate;
        uint256 amount;
    }

    //TokenHash => Lot info
    mapping(uint256 => Lot) private _lots;

    function _checkIfNotExists(uint256 tokenId, address token) internal view {
        require(
            _lots[_getTokenHash(tokenId, token)].amount == 0,
            "MAStorage: nft already listed"
        );
    }

    function _checkIfExists(uint256 tokenId, address token)
        internal
        view
        returns (Lot storage lot)
    {
        lot = _getLot(tokenId, token);
        require(lot.amount > 0, "MAStorage: no such nft");
        return lot;
    }
    
    function _setLotWithAmount(
        uint256 tokenId,
        address token,
        address seller,
        uint256 startPrice,
        uint256 amount
    ) internal returns (Lot storage lot) {
        lot = _getLot(tokenId, token);
        lot.seller = seller;
        lot.startPrice = startPrice;
        lot.startDate = block.timestamp;
        lot.amount = amount;
        return lot;
    }

    function _resetLot(uint256 tokenId, address token) internal virtual {
        Lot storage startBid = _setLotWithAmount(
            tokenId,
            token,
            address(0),
            0,
            0
        );
        startBid.startDate = 0;
    }

    function _getLot(uint256 tokenId, address token)
        internal
        view
        returns (Lot storage)
    {
        return _lots[_getTokenHash(tokenId, token)];
    }

    function _getTokenHash(uint256 tokenId, address token)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(tokenId, token)));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MAMAdmin is Ownable, Pausable, ERC721Holder, ERC1155Holder {
    address internal _exchangeToken;
    address internal _nft721Address;
    string internal _nft721uri;
    address internal _nft1155Address;
    string internal _nft1155uri;

    function setExchangeToken(address newExchangeToken)
        external
        onlyOwner
        whenPaused
    {
        _exchangeToken = newExchangeToken;
    }

    function setNft721(address nft721) external onlyOwner whenPaused {
        IERC721(nft721).supportsInterface(type(IERC721).interfaceId);
        _nft721Address = nft721;
    }

    function setNft1155(address nft1155) external onlyOwner whenPaused {
        IERC1155(nft1155).supportsInterface(type(IERC1155).interfaceId);
        _nft1155Address = nft1155;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _getNft721() internal view returns (IERC721) {
        return IERC721(_nft721Address);
    }

    function _getNft1155() internal view returns (IERC1155) {
        return IERC1155(_nft1155Address);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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