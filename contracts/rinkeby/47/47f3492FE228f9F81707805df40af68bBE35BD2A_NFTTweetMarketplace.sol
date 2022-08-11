// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**

 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄       ▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░▌     ▐░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀█░█▀▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀      ▐░▌░▌   ▐░▐░▌▐░█▀▀▀▀▀▀▀█░▌
     ▐░▌     ▐░▌       ▐░▌▐░▌          ▐░▌               ▐░▌          ▐░▌▐░▌ ▐░▌▐░▌▐░▌       ▐░▌
     ▐░▌     ▐░▌   ▄   ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌          ▐░▌ ▐░▐░▌ ▐░▌▐░█▄▄▄▄▄▄▄█░▌
     ▐░▌     ▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌          ▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌
     ▐░▌     ▐░▌ ▐░▌░▌ ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀      ▐░▌          ▐░▌   ▀   ▐░▌▐░█▀▀▀▀▀▀▀▀▀ 
     ▐░▌     ▐░▌▐░▌ ▐░▌▐░▌▐░▌          ▐░▌               ▐░▌          ▐░▌       ▐░▌▐░▌          
     ▐░▌     ▐░▌░▌   ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌          ▐░▌       ▐░▌▐░▌          
     ▐░▌     ▐░░▌     ▐░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌          ▐░▌       ▐░▌▐░▌          
      ▀       ▀▀       ▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀            ▀         ▀  ▀           
                                                                                                                                                                                                                                                                                                                                                    
 Launched via metapad.dev                                 
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBlocksportNFTTweet {
    function lockTweetRequest(uint256 tokenId) external;

    function setTweetStatus(
        uint256 tokenId,
        bool request,
        bool lock
    ) external;

    function getTokenTweetLockStatus(uint256 _tokenId)
        external
        view
        returns (bool);

    function getTokenTweetRequestStatus(uint256 _tokenId)
        external
        view
        returns (bool);
}

contract NFTTweetMarketplace is Ownable, Pausable, ReentrancyGuard {
    struct EscrowListing {
        address nftContract;
        uint256 nftID;
        address seller;
        address buyer;
        uint256 dueAmount;
        bool settled;
    }

    struct SellListing {
        address seller;
        uint256 nftID;
        address nftContract;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool sold;
    }

    uint256 public escrowCount = 0; // escrow listing counter id
    uint256 public escrowFunds = 0;
    uint256 public marketFee = 300; // 3% fee by default
    uint256 public minSalePrice = 0.01 ether;
    uint256 public minSaleTime = 2 minutes;
    uint256 public maxSaleTime = 2592000; // 30 days
    uint256 public sellsCount = 0; // sells listing counter id
    mapping(uint256 => EscrowListing) public escrowListings; // track escrow id => escrow listing
    mapping(uint256 => SellListing) public sellListings; // track sale id => sale listing
    mapping(address => bool) public whitelistedNFTContracts; // track whitelisted nft contracts allowed to interact to this contract

    mapping(address => mapping(uint256 => uint256)) private _escrowContracts; // track contract add => nft id => escrow id
    mapping(address => mapping(uint256 => bool)) private _escrowContractsState; // track contract add => nft id => bool

    event ListEscrow(
        address indexed nftContract,
        uint256 nftID,
        uint256 escrowID,
        address seller,
        address buyer,
        uint256 dueAmount
    );
    event SettleEscrow(
        address indexed nftContract,
        uint256 nftID,
        uint256 escrowID,
        address seller,
        address buyer,
        uint256 amount
    );
    event RejectEscrow(
        address indexed nftContract,
        uint256 nftID,
        uint256 escrowID,
        address seller,
        address buyer,
        uint256 amount
    );
    event OnSale(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        uint256 endTime,
        address seller
    );
    event ListingSold(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        address buyer
    );
    event RemovedFromSale(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        address seller
    );

    constructor() {
        minSaleTime = 157680000;
        maxSaleTime = 157680000;
        escrowCount = 0;
        sellsCount = 0;
    }

    modifier notContract() {
        require(
            !_isContract(msg.sender),
            "BlocsportNFTERC721: Contract not allowed"
        );
        require(
            msg.sender == tx.origin,
            "BlocsportNFTERC721: Proxy contract not allowed"
        );
        _;
    }

    /**
     * Buy listed item
     * @param saleID the ID of the sale
     */
    function buyItem(uint256 saleID)
        external
        payable
        notContract
        whenNotPaused
        nonReentrant
    {
        SellListing storage sl = sellListings[saleID];
        require(block.timestamp <= sl.endTime, "NFTM: sale period expired");
        require(sl.sold == false, "NFTM: can't buy a sold item");
        require(msg.value == sl.price, "NFTM: msg.value == listing price");

        // calculate fees
        uint256 _marketFee = _calcPercentage(msg.value, marketFee);
        uint256 _sellerFee = msg.value - _marketFee;

        // check if primary sale (escrowed sale) - meaning no tweet request yet ever
        // also check if escrow state is already active
        if (
            !IBlocksportNFTTweet(sl.nftContract).getTokenTweetRequestStatus(
                sl.nftID
            ) &&
            !IBlocksportNFTTweet(sl.nftContract).getTokenTweetLockStatus(
                sl.nftID
            ) &&
            !_escrowContractsState[sl.nftContract][sl.nftID]
        ) {
            // list for escrow
            EscrowListing memory el = EscrowListing(
                sl.nftContract,
                sl.nftID,
                sl.seller,
                msg.sender,
                _sellerFee,
                false
            );

            escrowListings[escrowCount] = el;
            _escrowContracts[sl.nftContract][sl.nftID] = escrowCount;
            _escrowContractsState[sl.nftContract][sl.nftID] = true;

            // track escrow funds
            escrowFunds += _sellerFee;

            emit ListEscrow(
                sl.nftContract,
                sl.nftID,
                escrowCount, // escrow id
                sl.seller,
                msg.sender,
                _sellerFee
            );

            escrowCount++;
        } else {
            payable(sl.seller).transfer(_sellerFee);
        }

        // transfer the tokens
        if (_isERC721(sl.nftContract)) {
            IERC721 nftToken = IERC721(sl.nftContract);

            nftToken.safeTransferFrom(address(this), msg.sender, sl.nftID);
        } else if (_isERC1155(sl.nftContract)) {
            IERC1155 nftToken = IERC1155(sl.nftContract);

            nftToken.safeTransferFrom(
                address(this),
                msg.sender,
                sl.nftID,
                1,
                ""
            );
        } else {
            revert(
                "NFTM: only ERC721 and ERC1155 types of tokens are supported for sale"
            );
        }

        // no need to transfer the market fee, the amount is in the contract
        sl.sold = true;

        emit ListingSold(
            sl.nftContract,
            saleID,
            sl.nftID,
            sl.price,
            msg.sender
        );
    }

    /**
     * List NFT for sale
     * @param nftContract nft contract address
     * @param nftID token id of nft
     * @param price sale price
     * @param saleDurationInSeconds if you go over it, the sale is canceled and the nft must be removeFromSale
     */
    function putForSale(
        address nftContract,
        uint256 nftID,
        uint256 price,
        uint256 saleDurationInSeconds
    ) external notContract whenNotPaused nonReentrant {
        require(whitelistedNFTContracts[nftContract], "NFTM: blacklisted contract");
        require(price >= minSalePrice, "NFTM: price must be >= minSalePrice");
        require(
            saleDurationInSeconds >= minSaleTime,
            "NFTM: sale time < minSaleTime"
        );
        require(
            saleDurationInSeconds <= maxSaleTime,
            "NFTM: sale time > maxSaleTime"
        );
        require(nftContract != address(0));

        // check if tweet request is set
        if (
            IBlocksportNFTTweet(nftContract).getTokenTweetRequestStatus(
                nftID
            ) &&
            !IBlocksportNFTTweet(nftContract).getTokenTweetLockStatus(nftID)
        ) {
            revert("NFTM: tweet request on process");
        }

        // transfer the tokens
        if (_isERC721(nftContract)) {
            IERC721 nftToken = IERC721(nftContract);

            nftToken.safeTransferFrom(msg.sender, address(this), nftID);
        } else if (_isERC1155(nftContract)) {
            IERC1155 nftToken = IERC1155(nftContract);

            // transfer
            nftToken.safeTransferFrom(msg.sender, address(this), nftID, 1, "");
        } else {
            revert(
                "NFTM: only ERC721 and ERC1155 types of tokens are supported for sale"
            );
        }

        // update the storage
        SellListing memory sl = SellListing(
            msg.sender,
            nftID,
            nftContract,
            block.timestamp,
            block.timestamp + saleDurationInSeconds,
            price,
            false //sold
        );

        sellListings[sellsCount] = sl;

        emit OnSale(
            nftContract,
            sellsCount, // saleID
            nftID,
            price,
            block.timestamp + saleDurationInSeconds,
            msg.sender
        );

        sellsCount = sellsCount + 1;
    }

    /**
     * Remove from listing
     * @param saleID sale id
     */
    function removeFromSale(uint256 saleID)
        external
        whenNotPaused
        nonReentrant
    {
        SellListing storage sl = sellListings[saleID];
        require(sl.sold == false, "NFTM: can't claim a sold item");
        require(msg.sender == sl.seller, "NFTM: only the seller can remove it");

        //Release the item back to the auctioneer
        if (_isERC721(sl.nftContract)) {
            IERC721 auctionToken = IERC721(sl.nftContract);
            auctionToken.safeTransferFrom(address(this), msg.sender, sl.nftID);
        } else if (_isERC1155(sl.nftContract)) {
            IERC1155 auctionToken = IERC1155(sl.nftContract);
            auctionToken.safeTransferFrom(
                address(this),
                msg.sender,
                sl.nftID,
                1,
                ""
            );
        }

        emit RemovedFromSale(
            sl.nftContract,
            saleID,
            sl.nftID,
            sl.price,
            msg.sender
        );
    }

    /// Restricted Functions

    /**
     * Blacklist an NFT contract
     * @param _nftContract nft contract address
     */
    function blacklistNFTContract(address _nftContract) external onlyOwner {
        whitelistedNFTContracts[_nftContract] = false;
    }

    /**
     * Update market fee
     * @param _marketFee new market fee
     */
    function changeMarketFee(uint256 _marketFee) external onlyOwner {
        marketFee = _marketFee;
    }

    /**
     * Update minimum sale price
     * @param _minSalePrice new minimum sale price
     */
    function changeMinSalePrice(uint256 _minSalePrice) external onlyOwner {
        minSalePrice = _minSalePrice;
    }

    /**
     * Update minimum sale time
     * @param _minSaleTime new minimum sale time
     */
    function changeMinSaleTime(uint256 _minSaleTime) external onlyOwner {
        minSaleTime = _minSaleTime;
    }

    /**
     * Update maximum sale time
     * @param _maxSaleTime new maximum sale time
     */
    function changeMaxSaleTime(uint256 _maxSaleTime) external onlyOwner {
        maxSaleTime = _maxSaleTime;
    }

    /**
     * Reclaim accidentally transferred erc20 tokens
     * @param _tokenContract contract address of erc20 token
     */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "NFTM: Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "NFTM: Transfer failed");
    }

    /**
     * Reject escrow payments
     * @param _nftContract nft contract
     * @param _tokenID token id
     */
    function rejectEscrow(address _nftContract, uint256 _tokenID)
        external
        onlyOwner
    {
        require(
            _escrowContractsState[_nftContract][_tokenID],
            "NFTM: no escrow"
        );
        EscrowListing storage el = escrowListings[
            _escrowContracts[_nftContract][_tokenID]
        ];
        require(!el.settled, "NFTM: already settled");

        // refund the buyer .. but buyer still owns the token (like free)
        // note that the nft is owned by buyer, not by this contract .. hence we can't transfer it back to seller
        payable(el.buyer).transfer(el.dueAmount);
        // lock this tweet nft .. buyer is refunded, seller didnt respond
        IBlocksportNFTTweet(el.nftContract).setTweetStatus(
            el.nftID,
            true,
            true
        );
        el.settled = true; // settled but a rejection
        delete _escrowContractsState[_nftContract][_tokenID];
        delete _escrowContracts[_nftContract][_tokenID];

        // track escrow funds
        if (escrowFunds >= el.dueAmount) {
            escrowFunds -= el.dueAmount;
        }

        emit RejectEscrow(
            el.nftContract,
            el.nftID,
            _escrowContracts[_nftContract][_tokenID],
            el.seller,
            el.buyer,
            el.dueAmount
        );
    }

    /**
     * Settle escrow payments
     * @param _nftContract nft contract
     * @param _tokenID token id
     */
    function settleEscrow(address _nftContract, uint256 _tokenID)
        external
        onlyOwner
    {
        require(
            _escrowContractsState[_nftContract][_tokenID],
            "NFTM: no escrow"
        );
        EscrowListing storage el = escrowListings[
            _escrowContracts[_nftContract][_tokenID]
        ];
        require(!el.settled, "NFTM: already settled");

        // pay the seller
        payable(el.seller).transfer(el.dueAmount);
        IBlocksportNFTTweet(el.nftContract).lockTweetRequest(el.nftID);
        el.settled = true;
        delete _escrowContractsState[_nftContract][_tokenID];
        delete _escrowContracts[_nftContract][_tokenID];

        // track escrow funds
        if (escrowFunds >= el.dueAmount) {
            escrowFunds -= el.dueAmount;
        }

        emit SettleEscrow(
            el.nftContract,
            el.nftID,
            _escrowContracts[_nftContract][_tokenID],
            el.seller,
            el.buyer,
            el.dueAmount
        );
    }

    /***
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) external onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    // Withdraw contract funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 feesAccumulated = 0;

        if (balance >= escrowFunds) {
            feesAccumulated = balance - escrowFunds;
        }

        payable(msg.sender).transfer(feesAccumulated);
    }

    /**
     * Whitelist an nft contract
     * @param _nftContract nft contract address
     */
    function whitelistNFTContract(address _nftContract) external onlyOwner {
        whitelistedNFTContracts[_nftContract] = true;
    }

    // Get contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// Helper Functions

    function _isERC721(address contractAddr) internal view returns (bool) {
        if (ERC165(contractAddr).supportsInterface(0x80ac58cd)) {
            return true;
        }
        return false;
    }

    function _isERC1155(address contractAddr) internal view returns (bool) {
        if (ERC165(contractAddr).supportsInterface(0xd9b67a26)) {
            return true;
        }
        return false;
    }

    /**
     * Calculate market fee percentage
     * @param amount total amount
     * @param basisPoints basis points in hundreds (3% = 300, 2% = 200, etc.)
     */
    function _calcPercentage(uint256 amount, uint256 basisPoints)
        internal
        pure
        returns (uint256)
    {
        require(basisPoints >= 0);
        return (amount * basisPoints) / 10000;
    }

    function _delBuildNumber3() internal pure {} // etherscan trick

    function _isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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