/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.4;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

contract InitialCoinOffering is Ownable, ReentrancyGuard, ERC721Holder, Pausable {    
    enum Sale { preSale, publicSale, crowdSale}

    address public collarQuest;
    uint128 public maxBuy = 2;
    uint128 constant DIVISOR = 10000;
    uint public currentSaleId = 0;
    uint[3] public discount = [5000,2500,0];   
    
    struct Timestamp {
        uint64 startTime;
        uint64 endTime;
    }

    struct NFTList {
        address nftAddress;
        uint price;
        bool isActive;
    }

    struct WhitelistInfo {
        mapping(uint => uint8) buyCount;
        bool isWhitelisted;
    }

    Timestamp[2] public timestamp;
    
    mapping(uint => NFTList) public listedOnSale;
    mapping(address => WhitelistInfo) public whiteList;

    event Buy(
        address indexed account,
        uint indexed nftId,
        uint price,
        uint64 timestamp,
        uint8 saleType
    );

    event AddedNFTs(
        address indexed nftAddress,
        uint indexed nftId,
        uint64 timestamp
    );

    event RemovedNFTs(
        address indexed nftAddress,
        uint indexed nftId,
        uint64 timestamp
    );

    constructor(address collarQuest_) {
        collarQuest = collarQuest_;
    }

    modifier onlyWhitelister() {
        require(whiteList[_msgSender()].isWhitelisted, "Only whitelist");
        _;
    }

    /**
     * @dev setting presale duration.
     */
    function setPresaleTimestamp( Timestamp calldata timestamp_) external onlyOwner {
        require(timestamp[uint(Sale.publicSale)].endTime == 0, "InitialCoinOffering :: setPresaleTimestamp : public sale end time == 0");
        require((timestamp_.startTime > 0) && (timestamp_.startTime > getBlockTimestamp()), "InitialCoinOffering :: setPresaleTimestamp : start time > block.timestamp");
        require(timestamp_.endTime > timestamp_.startTime, "InitialCoinOffering :: setPresaleTimestamp : end time > start time");

        timestamp[uint(Sale.preSale)] = timestamp_;
    }

    /**
     * @dev setting public sale duration.
     */
    function setPublicSaleTimestamp( Timestamp calldata timestamp_) external onlyOwner {
        require(timestamp[uint(Sale.preSale)].endTime > 0, "InitialCoinOffering :: setPublicSaleTimestamp : presale end time > 0");
        require((timestamp_.startTime > 0) && (timestamp_.startTime > timestamp[uint(Sale.preSale)].endTime), "InitialCoinOffering :: setPublicSaleTimestamp : start time > presale end time");
        require(timestamp_.endTime > timestamp_.startTime, "InitialCoinOffering :: setPublicSaleTimestamp : end time > start time");

        currentSaleId++;
        timestamp[uint(Sale.publicSale)] = timestamp_;
    }

    /**
     * @dev reset both public and presale.
     */
    function resetSale() external onlyOwner {
        require(timestamp[uint(Sale.publicSale)].endTime < getBlockTimestamp(),"InitialCoinOffering :: resetSale : wait till public sale end");
        timestamp[uint(Sale.publicSale)] = Timestamp(0,0);
        timestamp[uint(Sale.preSale)] = Timestamp(0,0);
    }

    /**
     * @dev setting maximum buy count for whitelisters in presale.
     */
    function updateMaxBuy( uint128 maxBuy_) external onlyOwner {
        require(maxBuy_ != 0, "InitialCoinOffering :: updateMaxBuy : maxBuy != 0");
        maxBuy = maxBuy_;
    }

    /**
     * @dev update collar quest nft address.
     */
    function updateCollarQuest( address collarQuest_) external onlyOwner {
        require(collarQuest_ != address(0),"InitialCoinOffering :: updateCollarQuest : collarQuest_ != zero address");
        collarQuest = collarQuest_;
    }    

    /**
     * @dev add nft to the sale list.
     */
    function addNftToList( uint[] memory nftId, uint[] memory price) external onlyOwner {
        require(nftId.length == price.length, "invalid length");

        for(uint i=0;i<nftId.length;i++) {
            require(price[i] > 0,"InitialCoinOffering :: addNftToList : price > 0");
            require(!listedOnSale[nftId[i]].isActive,"InitialCoinOffering :: addNftToList : not active");

            listedOnSale[nftId[i]] = NFTList(
            address(collarQuest),
            price[i],
            true
            );

            IERC721(collarQuest).safeTransferFrom(
                owner(),
                address(this),
                nftId[i]
            );

            emit AddedNFTs(
                collarQuest,
                nftId[i],
                uint64(block.timestamp)
            );
        }
    }

    /**
     * @dev update price of NFT added to the sale list.
     */
    function updateNftPrice( uint[] memory nftId, uint[] memory price) external onlyOwner {
        require(nftId.length == price.length, "InitialCoinOffering :: updateNftPrice : invalid length");
        for(uint i=0;i<nftId.length;i++) {
            require(price[i] > 0,"InitialCoinOffering :: updateNftPrice : price > 0");
            require(listedOnSale[nftId[i]].isActive,"InitialCoinOffering :: updateNftPrice : not active");

            listedOnSale[nftId[i]].price = price[i];
        }
    }

    /**
     * @dev update discount of NFT added to the sale list.
     */
    function updateNftDiscount(uint sale, uint16 newDiscount) external onlyOwner {
        require((newDiscount > 0) && (newDiscount < DIVISOR),"InitialCoinOffering :: updateNftDiscount : price > 0");
        require(sale < discount.length,"InitialCoinOffering :: updateNftDiscount : price > 0");
        discount[sale] = newDiscount;
    }

    /**
     * @dev remove NFT from the sale list
     */
    function removeNftToList( uint[] memory nftId) external onlyOwner {
        require(nftId.length > 0, "InitialCoinOffering :: removeNftToList : length must be higher than zero");
        for(uint i=0;i<nftId.length;i++) {
            require(listedOnSale[nftId[i]].isActive,"InitialCoinOffering :: removeNftToList : nft should be active on sale");

            listedOnSale[nftId[i]].isActive = false;
            IERC721(collarQuest).safeTransferFrom(
                address(this),
                owner(),
                nftId[i]
            );

            emit RemovedNFTs(
                collarQuest,
                nftId[i],
                uint64(block.timestamp)
            );
        }
    }

    /**
     * @dev add whitelist address.
     */
    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        require(addresses.length > 0,"InitialCoinOffering :: addToWhitelist : addresses length");

        for(uint8 i=0; i<addresses.length; i++) {
            if(!whiteList[addresses[i]].isWhitelisted) {
                whiteList[addresses[i]].isWhitelisted = true;
            }
        }
    }

    /**
     * @dev remove whitelist address.
     */
    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        require(addresses.length > 0,"InitialCoinOffering :: removeFromWhitelist : addresses length");

        for(uint8 i=0; i<addresses.length; i++) {
            if(whiteList[addresses[i]].isWhitelisted) {
                whiteList[addresses[i]].isWhitelisted = false;
            }
        }
    }

    /**
     * @dev whitelist addresses can buy NFTs on presale at discount price.
     */
    function preSale( uint nftId) external payable onlyWhitelister whenNotPaused nonReentrant {
        require(!_isContract(_msgSender()),"InitialCoinOffering :: preSale : not a contract ");
        require(
            (timestamp[uint(Sale.preSale)].startTime > 0) &&
            (timestamp[uint(Sale.preSale)].startTime <= getBlockTimestamp()) &&
            (timestamp[uint(Sale.preSale)].endTime >= getBlockTimestamp()),
            "InitialCoinOffering :: preSale : presale sale not yet started or sale ended"
        );
        require(listedOnSale[nftId].isActive,"InitialCoinOffering :: preSale : nft is not active");
        require(getBuyerCount(_msgSender(),currentSaleId) < maxBuy,"InitialCoinOffering :: preSale : buyCount < maxBuy");
        require(IERC721(listedOnSale[nftId].nftAddress).ownerOf(nftId) == address(this),"InitialCoinOffering :: preSale : NFT is not owned by contract");
        
        whiteList[_msgSender()].buyCount[currentSaleId]++;
        listedOnSale[nftId].isActive = false;

        uint value = getDiscountPrice( nftId, uint8(Sale.preSale));
        require(msg.value == value,"InitialCoinOffering :: preSale : invalid price value");

        _buy(_msgSender(), nftId, value, uint8(Sale.preSale));
    }

    /**
     * @dev both public and whitelisted address can buy NFTs at discount price.
     */
    function publicSale( uint nftId) external payable whenNotPaused nonReentrant {
        require(!_isContract(_msgSender()),"InitialCoinOffering :: publicSale : address should not be a contract address");
        require(
            (timestamp[uint(Sale.publicSale)].startTime > 0) &&
            (timestamp[uint(Sale.publicSale)].startTime <= getBlockTimestamp()) &&
            (timestamp[uint(Sale.publicSale)].endTime >= getBlockTimestamp()),
            "InitialCoinOffering :: publicSale : public sale not yet started or sale ended"
        );
        require(listedOnSale[nftId].isActive,"InitialCoinOffering :: publicSale : nft is not active");
        require(IERC721(listedOnSale[nftId].nftAddress).ownerOf(nftId) == address(this),"InitialCoinOffering :: publicSale : NFT is not owned by contract");
        
        uint value = getDiscountPrice(nftId,uint8(Sale.publicSale));
        require(msg.value == value,"InitialCoinOffering :: publicSale : invalid price value");

        listedOnSale[nftId].isActive = false;
        _buy(_msgSender(), nftId, value, uint8(Sale.publicSale));
    }

    /**
     * @dev Can only buy nft token without any discount offer.
     */
    function crowdSale( uint nftId) external payable whenNotPaused nonReentrant {
        require(!_isContract(_msgSender()),"InitialCoinOffering :: crowdSale : address should not be a contract address");
        require(
            (timestamp[uint(Sale.publicSale)].endTime > 0) &&
            (timestamp[uint(Sale.publicSale)].endTime <= getBlockTimestamp()),
            "InitialCoinOffering :: crowdSale : public sale is not ended"
        );
        require(listedOnSale[nftId].isActive,"InitialCoinOffering :: crowdSale : nft is not active");
        require(IERC721(listedOnSale[nftId].nftAddress).ownerOf(nftId) == address(this),"InitialCoinOffering :: crowdSale : NFT is not owned by contract");
        
        uint value = getDiscountPrice(nftId,uint8(Sale.crowdSale));
        require(msg.value == value,"InitialCoinOffering :: crowdSale : invalid price value");

        listedOnSale[nftId].isActive = false;
        _buy(_msgSender(), nftId, value, uint8(Sale.crowdSale));
    }

    /**
     * @dev Allow owner to claim locked ETH on the contract.
     */
    function emergencyRelease( uint amount) public onlyOwner {
        address self = address(this);
        require(self.balance >= amount, "InitialCoinOffering :: emergencyRelease : insufficient balance");

        _send(payable(owner()),amount);        
    }

    /**
     * @dev Pauses the sale.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the sale.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfers offer token to owner.
     */
    function _buy( address buyer, uint nftId, uint value, uint8 saleType) private {
        _send(payable(owner()),value);

        IERC721(listedOnSale[nftId].nftAddress).safeTransferFrom(
            address(this),
            buyer,
            nftId
        );

        emit Buy(
            buyer,
            nftId,
            value,
            uint64(block.timestamp),
            saleType
        );
    }

    /**
     * @dev Send ether to the recipient address.
     */
    function _send(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Returns discount price.
     */
    function getDiscountPrice(uint nftId, uint sale) public view returns (uint discountPrice) {
        discountPrice = listedOnSale[nftId].price * (DIVISOR - discount[sale]) / DIVISOR;
    }

    /**
     * @dev Returns buyer count.
     */
    function getBuyerCount(address buyer, uint saleId) public view returns (uint256) {
        return whiteList[buyer].buyCount[saleId];
    }

    /**
     * @dev Returns current block time.
     */
    function getBlockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }
    
    /**
     * @dev Returns true if caller is an contract.
     */
    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }    
}