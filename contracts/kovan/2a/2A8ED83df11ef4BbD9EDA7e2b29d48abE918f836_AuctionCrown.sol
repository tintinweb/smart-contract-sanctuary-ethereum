// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../NFT/ICrownNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuctionCrown is Ownable {
    address wdaToken;
    address daoTreasuryAddress; // Dao Treasury address

    struct Auction {
        uint256 highestBid;
        uint256 withBnb;
        uint256 closingTime;
        address highestBidder;
        address originalOwner;
        bool isActive;
        uint256 totalBid;
    }

    // NFT id => Auction data
    mapping(uint256 => Auction) public auctions;

    // CrownNFT contract interface
    ICrownNFT private sNft_;

    // BNB balance
    uint256 public balances;

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    // initialize Time
    uint256 private initTime;

    // period days
    uint256 public periodDays; //days

    // BNB price
    uint256 public priceBnb;

    // BNB plus by periodDays
    uint256 public decimalPlusBnb;

    //avaibale currently Auction
    bool public isAuction;

    //id NFT is auctioning
    uint256 public lastNftId;

    //duration Time
    uint256 public durationTime = 2 * 60 * 60;

    //mapping of admin
    mapping(address => bool) private adminHandle;

    /**
     * @dev New Auction Opened Event
     * @param nftId Auction NFT Id
     * @param startingBid NFT starting bid price
     * @param withBnb Bnb with bid price
     * @param closingTime Auction close time
     * @param originalOwner Auction creator address
     */
    event NewAuctionOpened(
        uint256 nftId,
        uint256 startingBid,
        uint256 withBnb,
        uint256 closingTime,
        address originalOwner
    );

    /**
     * @dev Auction Closed Event
     * @param nftId Auction NFT id
     * @param highestBid Auction highest bid
     * @param withBnb Bnb with bid price
     * @param highestBidder Auction highest bidder
     */
    event AuctionClosed(
        uint256 nftId,
        uint256 highestBid,
        uint256 withBnb,
        address highestBidder,
        uint256 totalBid
    );

    /**
     * @dev Bid Placed Event
     * @param nftId Auction NFT id
     * @param bidPrice Bid price
     * @param withBnb with Bnb price
     * @param bidder Bidder address
     */
    event BidPlaced(
        uint256 nftId,
        uint256 bidPrice,
        uint256 withBnb,
        address bidder
    );

    /**
     * @dev Receive BNB. msg.data is empty
     */
    receive() external payable {
        balances += msg.value;
    }

    /**
     * @dev Receive BNB. msg.data is not empty
     */
    fallback() external payable {
        balances += msg.value;
    }

    /**
     * @dev Contructor Smart contract
     * @param token_ address token
     */
    constructor(address token_, address daoTreasuryAddress_) {
        wdaToken = token_;
        daoTreasuryAddress = daoTreasuryAddress_;
        adminHandle[msg.sender] = true;
    }

    /**
     * @dev Initialize states
     * @param _sNft CrownNFT contract address
     */
    function initialize(address _sNft) external onlyAdmin {
        require(_sNft != address(0), "Invalid address");
        sNft_ = ICrownNFT(_sNft);
        balances = 0;
        periodDays = 30;
        priceBnb = 0.00001 * 10**18;
        initTime = block.timestamp;
        isAuction = false;
        decimalPlusBnb = 10;
    }

    /**
     * @dev Open Auction
     */
    function openAuction() external onlyAdmin{
        require(isAuction == false, "One Auction is opening");
        //Mint Nft for Auction
        uint256 _nftId = sNft_.mintValidTarget(1);

        require(auctions[_nftId].isActive == false, "Ongoing auction detected");
        lastNftId = _nftId;
        isAuction = true;

        uint256 _withBnb = priceBnb + augmentBnb();
        // Opening new auction
        auctions[_nftId].highestBid = 0;
        auctions[_nftId].withBnb = _withBnb;
        auctions[_nftId].closingTime = block.timestamp + durationTime;
        auctions[_nftId].highestBidder = msg.sender;
        auctions[_nftId].originalOwner = msg.sender;
        auctions[_nftId].isActive = true;
        auctions[_nftId].totalBid = 0;

        emit NewAuctionOpened(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].withBnb,
            auctions[_nftId].closingTime,
            auctions[_nftId].highestBidder
        );
    }

    /**
     * @dev Place Bid
     */
    function placeBid(uint256 _priceBid) external payable {
        require(isAuction == true, "Not found Auction is opening");
        require(auctions[lastNftId].isActive == true, "Not active auction");
        require(
            auctions[lastNftId].closingTime > block.timestamp,
            "Auction is closed"
        );
        require(msg.value >= auctions[lastNftId].withBnb, "With Bnb not enough");

        require(_priceBid > auctions[lastNftId].highestBid, "Bid is too low");

        // check allowance of msg.sender
        uint256 allowance = IERC20(wdaToken).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= _priceBid, "Over allowance");
        // Holding : Transfer Amount of price Bid to SM Wallet
        bool holding = IERC20(wdaToken).transferFrom(
            msg.sender,
            address(this),
            _priceBid
        );
        require(holding, "Token can't hold");

        if (auctions[lastNftId].originalOwner != auctions[lastNftId].highestBidder) {
            //Transfer WDA token to Previous Highest Bidder
            bool backWDA = IERC20(wdaToken).transfer(
                auctions[lastNftId].highestBidder,
                auctions[lastNftId].highestBid
            );
            require(backWDA, "transfer WDA Token failed");

            // Transfer BNB to Previous Highest Bidder
            (bool sent, ) = payable(auctions[lastNftId].highestBidder).call{
                value: auctions[lastNftId].withBnb
            }("");

            require(sent, "Transfer BNB failed");
        }

        auctions[lastNftId].highestBid = _priceBid;
        auctions[lastNftId].withBnb = msg.value;
        auctions[lastNftId].highestBidder = msg.sender;
        auctions[lastNftId].totalBid = auctions[lastNftId].totalBid + 1;

        emit BidPlaced(
            lastNftId,
            auctions[lastNftId].highestBid,
            auctions[lastNftId].withBnb,
            auctions[lastNftId].highestBidder
        );
    }

    /**
     * @dev Close Auction
     */
    function closeAuction() external onlyAdmin {
        require(isAuction == true, "Not found Auction is opening");
        require(auctions[lastNftId].isActive == true, "Not active auction");
        require(
            auctions[lastNftId].closingTime <= block.timestamp,
            "Lastest Auction is not closed"
        );

        if (auctions[lastNftId].highestBid == 0) {
            //Bids is empty, NFT will be burn
            sNft_.burn(lastNftId);
        } else {
            // Transfer BNB to Dao Treasury
            (bool sent, ) = payable(daoTreasuryAddress).call{
                    value: auctions[lastNftId].withBnb
                }("");

            require(sent, "Transfer BNB failed");

            // Transfer NFT to Highest Bidder
            sNft_.transferFrom(
                address(this),
                auctions[lastNftId].highestBidder,
                lastNftId
            );
        }
        // Close Auction
        auctions[lastNftId].isActive = false;
        isAuction = false;

        emit AuctionClosed(
            lastNftId,
            auctions[lastNftId].highestBid,
            auctions[lastNftId].withBnb,
            auctions[lastNftId].highestBidder,
            auctions[lastNftId].totalBid
        );
    }

    /**
     * if owner want to force close a Auction
     */
    function forceCloseAuction() external onlyAdmin {
        require(isAuction == true, "Not found Auction is opening");
        require(auctions[lastNftId].isActive == true, "Not active auction");
        
        if(auctions[lastNftId].highestBid > 0) {
            //Transfer WDA token to Previous Highest Bidder
            bool backWDA = IERC20(wdaToken).transfer(
                auctions[lastNftId].highestBidder,
                auctions[lastNftId].highestBid
            );
            require(backWDA, "transfer WDA Token failed");

            // Transfer BNB to Previous Highest Bidder
            (bool sent, ) = payable(auctions[lastNftId].highestBidder).call{
                value: auctions[lastNftId].withBnb
            }("");

            require(sent, "Transfer BNB failed");
        }

        //burn NFT
        sNft_.burn(lastNftId);
        // Close Auction
        auctions[lastNftId].isActive = false;
        isAuction = false;

        emit AuctionClosed(
            lastNftId,
            auctions[lastNftId].highestBid,
            auctions[lastNftId].withBnb,
            auctions[lastNftId].highestBidder,
            auctions[lastNftId].totalBid
        );
    }
    /**
     * @dev Withdraw BNB
     * @param _target Spender address
     * @param _amount Transfer amount
     */
    function withdraw(address _target, uint256 _amount) external onlyAdmin {
        require(isAuction == false, "A auction is opening");
        require(_target != address(0), "Invalid address");
        require(_amount > 0 && _amount < balances, "Invalid amount");

        payable(_target).transfer(_amount);

        balances = balances - _amount;
    }

    /**
     * @dev Withdraw WDA token
     * @param _target Spender address
     * @param _amount Transfer amount
     */
    function withdrawWDA(address _target, uint256 _amount) external onlyAdmin {
        require(isAuction == false, "A auction is opening");
        require(_target != address(0), "Invalid address");
        require(
            _amount > 0 && _amount < IERC20(wdaToken).balanceOf(address(this)),
            "Invalid amount"
        );
        IERC20(wdaToken).transferFrom(address(this), _target, _amount);
    }

    /*
     * @dev Set Dao Treasury Address
     * @param daoTreasuryAdress_ address
     */
    function setDaoTreasuryAddress(address daoTreasuryAddress_)
        external
        onlyAdmin
    {
        daoTreasuryAddress = daoTreasuryAddress_;
    }

    /*
     * Different beetween 2 timestamps
     */
    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    /**
     * calculate Augement Bnb by time
     */
    function augmentBnb() internal view returns (uint256 _bnb) {
        uint256 _time = diffDays(initTime, block.timestamp) / periodDays;
        return ((_time * 2) / decimalPlusBnb) * 10**18;
    }

    /**
     * Set Period days
     */
    function setAugmentBnb(uint256 days_, uint256 decimalPlusBnb_) public onlyAdmin {
        periodDays = days_;
        decimalPlusBnb = decimalPlusBnb_;
    }

    function setDurationTime(uint256 duration_) public onlyAdmin {
        durationTime = duration_;
    }
    /**
      * set admin
      * target: target address
      * permission : true/false
     */
    function setAdmin(address target, bool permission)
        external
        onlyOwner
    {
        adminHandle[target] = permission;
    }

    modifier onlyAdmin() {
         require(adminHandle[msg.sender]);
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICrownNFT is IERC721, IERC721Enumerable {
    struct CrownTraits {
        uint256 reduce;
        uint256 aprBonus;
        uint256 lockDeadline;
        bool staked;
    }

    function getTraits(uint256) external view returns (CrownTraits memory);

    function mintValidTarget(uint256 number) external returns(uint256);

    function burn(uint256 tokenId) external;

    function stakeOrUnstake(uint256, bool) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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