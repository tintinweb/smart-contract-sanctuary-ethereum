/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.14;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.14;

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function mint(
        address _to,
        uint256 no_of_tokens_to_create,
        string calldata _uri
    ) external;

    function tokensOwned(address holder) external returns (uint256[] memory);

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

    function contractSafeTransferFrom(
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IDataStorage {
    struct Affiliate {
        uint16 feePercent;
        address affiliateAddr;
    }

    function getSellerCommission(address _artist)
        external
        view
        returns (Affiliate[3] memory);

    function setRoyaltyData(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external;

    function nftRoyalty(address _nftContractAddress, uint256 _tokenId) external;

    function activateRoyalty(address _nftContractAddress, uint _tokenId)
        external;

    function getRoyaltyPercentage(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (uint);

    function getRoyaltyOwner(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (address);

    function isActivated(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (bool);

    function setRoyaltyPercentage(
        address _nftContractAddress,
        uint _tokenId,
        uint256 _newPercentage
    ) external;

    function platformCommission() external view returns (uint16);

    function nftCommission() external view returns (uint16);
}

contract ClubVirtualMarketplaceERC721 is Ownable, ReentrancyGuard {
    address public platformNormalNFT;
    address public platformLazyNFT;
    IDataStorage public dataStorage; // stores royalty data

    event SaleCreated(
        uint indexed tokenID,
        address nftContract,
        address seller,
        uint256 buyNowPrice
    );

    event CreateAuction(
        uint indexed tokenID,
        address nftContract,
        address seller,
        uint256 minPrice
    );

    event SettleAuction(
        address nftContract,
        uint indexed tokenID,
        address _nftSeller,
        address _nftBuyer,
        uint256 _price
    );

    // keeps account of all auctions
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    // keeps account of all sales
    mapping(address => mapping(uint256 => Sale)) public nftContractSale;
    // keeps account of all proposals
    mapping(address => mapping(uint256 => Proposal)) public buyProposal;
    // Keeps account of all withdraw amounts
    mapping(address => mapping(uint256 => mapping(address => Bids)))
        public auctionBids;
    mapping(address => uint256) public failedCredits;

    struct Auction {
        // minimum price at which auction will start
        uint256 minPrice;
        // timestamp at which auction starts
        uint256 auctionStartTime;
        // timestamp at which auction ends
        uint256 auctionEnd;
        // current highest bid
        uint256 nftHighestBid;
        // how much each next bid should increase
        uint32 bidIncreasePercentage;
        // current highest bidder
        address nftHighestBidder;
        // NFT seller
        address nftSeller;
        // ERC20 token in which payment is intended
        address ERC20Token;
    }

    struct Sale {
        // NFT seller
        address nftSeller;
        // ERC20 token in which payment is intended
        address ERC20Token;
        // Selling price of NFT
        uint256 buyNowPrice;
    }

    struct Proposal {
        address buyer;
        uint256 price;
    }

    struct Bids {
        uint256 bidAmount; // Bid Amount
        uint256 depositedAmt; // Actual deposited = (Bid + platform fees)
        address ERC20Token; // Token used
    }

    modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isMinimumBidMade(_nftContractAddress, _tokenId),
            "Bid is present"
        );
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction not over"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount
    ) {
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            ),
            "Payment invalid"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Given zero address");
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender !=
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only Seller Function"
        );
        _;
    }

    // Set own NFT addresses
    function setInitData(
        address _platformNormalNFT,
        address _platformLazyNFT,
        IDataStorage _dataStorage
    ) external onlyOwner {
        platformNormalNFT = _platformNormalNFT;
        platformLazyNFT = _platformLazyNFT;
        dataStorage = _dataStorage;
    }

    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint256 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            return
                msg.value == 0 &&
                auctionERC20Token == _bidERC20Token &&
                _tokenAmount > 0;
        } else {
            return
                msg.value != 0 &&
                _bidERC20Token == address(0) &&
                _tokenAmount > 0;
        }
    }

    function _isERC20Auction(address _auctionERC20Token)
        internal
        pure
        returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 bidIncreasePercentage = nftContractAuctions[
            _nftContractAddress
        ][_tokenId].bidIncreasePercentage;
        return bidIncreasePercentage;
    }

    /*
     * NFTs in a batch must contain between 2 and 100 NFTs
     */
    modifier batchWithinLimits(uint256 _batchTokenIdsLength) {
        require(
            _batchTokenIdsLength > 1 && _batchTokenIdsLength <= 10000,
            "Number of NFTs not applicable"
        );
        _;
    }

    function setRoyaltyData(
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external {
        require(msg.sender == platformLazyNFT, "Only run on redeem");
        dataStorage.setRoyaltyData(
            platformLazyNFT,
            _tokenId,
            _royaltyPercentage,
            _royaltyOwner
        );
    }

    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    function createBatchNftAuction(
        address _nftContractAddress,
        uint256[] memory _batchTokenIds,
        uint256[] memory _batchTokenPrices,
        uint32[] memory _royaltyPercentage,
        address _erc20Token,
        uint256 _auctionStartTime,
        uint256 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        string[] memory _uri
    ) external batchWithinLimits(_batchTokenIds.length) {
        require(
            (_batchTokenIds.length == _batchTokenPrices.length) &&
                (_batchTokenIds.length == _royaltyPercentage.length)
        );
        for (uint i = 0; i < _batchTokenIds.length; i++) {
            createNewNFTAuction(
                _nftContractAddress,
                _batchTokenIds[i],
                _erc20Token,
                _batchTokenPrices[i],
                _royaltyPercentage[i],
                _auctionBidPeriod,
                _bidIncreasePercentage,
                _auctionStartTime,
                _uri[i]
            );
        }
    }

    function createNewNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint32 _royaltyPercentage,
        uint256 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        uint256 _auctionStartTime,
        string memory _uri
    ) public {
        require(_auctionBidPeriod >= 600, "Min is 10 min");
        require(_minPrice > 0, "Price can't be 0");

        if (_nftContractAddress == address(0) && _tokenId == 0) {
            IERC721(platformNormalNFT).mint(address(this), 1, _uri); // mint to this contract
            uint[] memory tokens = IERC721(platformNormalNFT).tokensOwned(
                address(this)
            );
            uint tokenId = tokens[tokens.length - 1];

            Auction storage auction = nftContractAuctions[platformNormalNFT][
                tokenId
            ];

            auction.bidIncreasePercentage = _bidIncreasePercentage;
            // set royalty data
            dataStorage.setRoyaltyData(
                platformNormalNFT,
                tokenId,
                _royaltyPercentage,
                msg.sender
            );

            _setupAuction(
                platformNormalNFT,
                tokenId,
                _erc20Token,
                _minPrice,
                _auctionStartTime,
                _auctionBidPeriod
            );
            emit CreateAuction(
                tokenId,
                platformNormalNFT,
                msg.sender,
                _minPrice
            );
        } else {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .bidIncreasePercentage = _bidIncreasePercentage;
            if (
                dataStorage.getRoyaltyOwner(_nftContractAddress, _tokenId) ==
                address(0)
            ) {
                dataStorage.setRoyaltyData(
                    _nftContractAddress,
                    _tokenId,
                    _royaltyPercentage,
                    msg.sender
                );
            }
            _createNewNftAuction(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _minPrice,
                _auctionStartTime,
                _auctionBidPeriod
            );
            emit CreateAuction(
                _tokenId,
                _nftContractAddress,
                msg.sender,
                _minPrice
            );
        }
    }

    function _setupAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint256 _auctionStartTime,
        uint256 _auctionBidPeriod
    ) internal {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd =
            _auctionBidPeriod +
            (block.timestamp);
        nftContractAuctions[_nftContractAddress][_tokenId].auctionStartTime =
            _auctionStartTime +
            block.timestamp;
    }

    function _createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint256 _auctionStartTime,
        uint256 _auctionBidPeriod
    ) internal {
        if (
            _nftContractAddress == platformNormalNFT ||
            _nftContractAddress == platformLazyNFT
        ) {
            // Sending the NFT to this contract
            IERC721(_nftContractAddress).contractSafeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        }
        // If NFT not one of ours then it needs approval
        else {
            IERC721(_nftContractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        }
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _auctionStartTime,
            _auctionBidPeriod
        );
    }

    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) internal {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = msg.sender;

        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid = _tokenAmount;
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) internal {
        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        auctionBids[_nftContractAddress][_tokenId][msg.sender]
            .bidAmount = _tokenAmount;

        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);
        // Let bidder remove his previous bid
        if (prevNftHighestBid > 0) {}
    }

    function withdrawFailedBids(address _nftContractAddress, uint256 _tokenId)
        public
    {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd <
                block.timestamp
        );
        require(
            msg.sender !=
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBidder,
            "HIGHEST_BIDDER_NOT_ALLOWED"
        );
        uint256 withdrawalAmt = auctionBids[_nftContractAddress][_tokenId][
            msg.sender
        ].depositedAmt;

        require(withdrawalAmt > 0, "NOT_ENOUGH_WITHDRAWAL");
        // Add the platform commission to the bid amount to withdraw

        address erc20Token = auctionBids[_nftContractAddress][_tokenId][
            msg.sender
        ].ERC20Token;

        delete auctionBids[_nftContractAddress][_tokenId][msg.sender];

        // Transfer
        if (_isERC20Auction(erc20Token)) {
            IERC20(erc20Token).transfer(msg.sender, withdrawalAmt);
        } else {
            (bool success, ) = payable(msg.sender).call{value: withdrawalAmt}(
                ""
            );
            if (!success) {
                revert();
            }
        }
    }

    function withdrawFailedCredits() public {
        require(failedCredits[msg.sender] > 0, "ZERO_CREDITS");
        (bool success, ) = payable(msg.sender).call{
            value: failedCredits[msg.sender]
        }("");
        if (!success) {
            revert();
        }
    }

    function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice;
        return
            minPrice > 0 &&
            (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >=
                minPrice);
    }

    function _setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        uint32 _royaltyPercentage
    ) internal {
        if (_erc20Token != address(0)) {
            nftContractSale[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        nftContractSale[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftContractSale[_nftContractAddress][_tokenId].nftSeller = msg.sender;

        if (
            dataStorage.getRoyaltyOwner(_nftContractAddress, _tokenId) ==
            address(0)
        ) {
            dataStorage.setRoyaltyData(
                _nftContractAddress,
                _tokenId,
                _royaltyPercentage,
                msg.sender
            );
        }
    }

    function createResale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        uint32 _royaltyPercentage
    ) external priceGreaterThanZero(_buyNowPrice) {
        // If it's our own platform NFT
        if (
            _nftContractAddress == platformNormalNFT ||
            _nftContractAddress == platformLazyNFT
        ) {
            IERC721(_nftContractAddress).contractSafeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            _setupSale(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _buyNowPrice,
                _royaltyPercentage
            );
        }
        // if it's not our own platform NFT
        else {
            IERC721(_nftContractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            _setupSale(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _buyNowPrice,
                _royaltyPercentage
            );
        }
    }

    function createBatchResale(
        address _nftContractAddress,
        address _erc20Token,
        uint256[] memory _tokenId,
        uint256[] memory _buyNowPrice,
        uint32 _royaltyPercentage
    ) external batchWithinLimits(_tokenId.length) {
        require(_tokenId.length == _buyNowPrice.length);
        for (uint i = 0; i < _tokenId.length; i++) {
            IERC721(_nftContractAddress).contractSafeTransferFrom(
                msg.sender,
                address(this),
                _tokenId[i]
            );
            _setupSale(
                _nftContractAddress,
                _tokenId[i],
                _erc20Token,
                _buyNowPrice[i],
                _royaltyPercentage
            );
        }
    }

    function createSale(
        address _erc20Token,
        uint256 _buyNowPrice,
        uint32 _royaltyPercentage,
        string memory _uri
    ) external priceGreaterThanZero(_buyNowPrice) returns (uint256) {
        IERC721(platformNormalNFT).mint(address(this), 1, _uri); // mint to this contract
        // last token minted
        uint[] memory tokens = IERC721(platformNormalNFT).tokensOwned(
            address(this)
        );
        uint _tokenId = tokens[tokens.length - 1];

        _setupSale(
            address(platformNormalNFT),
            _tokenId,
            _erc20Token,
            _buyNowPrice,
            _royaltyPercentage
        );

        emit SaleCreated(_tokenId, platformNormalNFT, msg.sender, _buyNowPrice);
        return _tokenId;
    }

    function createBatchSale(
        uint256[] memory _batchTokenPrice,
        address _erc20Token,
        uint32 _royaltyPercentage,
        string[] memory _uri
    ) external batchWithinLimits(_batchTokenPrice.length) {
        for (uint i = 0; i < _batchTokenPrice.length; i++) {
            require(_batchTokenPrice[i] > 0, "price invalid");
            IERC721(platformNormalNFT).mint(address(this), 1, _uri[i]); // mint to this contract
            // last token minted
            uint[] memory tokens = IERC721(platformNormalNFT).tokensOwned(
                address(this)
            );
            uint _tokenId = tokens[tokens.length - 1];

            _setupSale(
                address(platformNormalNFT),
                _tokenId,
                _erc20Token,
                _batchTokenPrice[i],
                _royaltyPercentage
            );
        }
    }

    function buyNFT(address _nftContractAddress, uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId];
        address seller = sale.nftSeller;
        require(msg.sender != seller, "Seller cannot buy own NFT");
        uint256 buyNowPrice = sale.buyNowPrice;
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);
        uint256 totalPayable = buyNowPrice + platformFees;

        address erc20Token = sale.ERC20Token;
        if (_isERC20Auction(erc20Token)) {
            _buyNFTWithERC20(
                _nftContractAddress,
                _tokenId,
                seller,
                erc20Token,
                buyNowPrice
            );
            IERC721(_nftContractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
            return;
        } else {
            require(msg.value >= totalPayable, "Must be greater than NFT cost");
        }
        _buyNFTWithEth(_nftContractAddress, _tokenId);

        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function _buyNFTWithERC20(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller,
        address _erc20Token,
        uint256 _buyNowPrice
    ) internal {
        uint totalAmount = _buyNowPrice;

        // 1. Cut platform fees from the buyer
        uint256 platformFees = (_buyNowPrice *
            (dataStorage.platformCommission())) / (10000);
        // 2. Cut ownerAmount from Seller
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(_seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (_buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                totalAmount -= ownerAmount;
                IERC20(_erc20Token).transferFrom(
                    msg.sender,
                    sellerCommission[i].affiliateAddr,
                    ownerAmount
                );
            }
        }
        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (_buyNowPrice * (dataStorage.nftCommission())) /
            (10000);

        // Reset Sale Data
        _resetSale(_nftContractAddress, _tokenId);
        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royaltypercentage
            uint royaltyAmount = (_buyNowPrice * (_royaltyPercentage)) /
                (10000);
            totalAmount -= royaltyAmount;
            IERC20(_erc20Token).transferFrom(
                msg.sender,
                royaltyOwner,
                royaltyAmount
            );
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        totalAmount -= nftFee;
        address owner = owner();
        uint256 adminFees = platformFees + nftFee;
        IERC20(_erc20Token).transferFrom(msg.sender, owner, adminFees);
        IERC20(_erc20Token).transferFrom(msg.sender, _seller, totalAmount);
    }

    /// @notice Buy the NFT with ETH/BNB/MATIC
    function _buyNFTWithEth(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId];
        address seller = sale.nftSeller;
        uint totalAmount = msg.value;
        uint buyNowPrice = sale.buyNowPrice;
        // 1. Cut platform fees from the buyer
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);
        totalAmount -= platformFees;
        // 2. Cut ownerAmount from Seller
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                totalAmount -= ownerAmount;
                (bool _success, ) = payable(sellerCommission[i].affiliateAddr)
                    .call{value: ownerAmount}("");
                require(_success, "TRANSFER_FAILED");
            }
        }

        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (buyNowPrice * (dataStorage.nftCommission())) /
            (10000);
        totalAmount -= nftFee;
        // Reset Sale Data
        _resetSale(_nftContractAddress, _tokenId);
        // Check Royalty Applicable
        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royalty Percentage
            uint royaltyAmount = (buyNowPrice * (_royaltyPercentage)) / (10000);
            totalAmount -= royaltyAmount;
            (bool _success, ) = payable(royaltyOwner).call{
                value: royaltyAmount
            }("");
            require(_success);
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        address owner = owner();
        uint256 adminFees = platformFees + nftFee;
        payable(owner).transfer(adminFees);
        (bool success, ) = payable(seller).call{value: totalAmount}("");
        if (!success) {
            revert();
        }
    }

    /// @notice NFT Seller can accept the proposal
    function acceptBuyProposal(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _proposedPrice,
        address _proposingBuyer
    ) public {
        require(
            (msg.sender ==
                nftContractSale[_nftContractAddress][_tokenId].nftSeller),
            "Only Seller function"
        );
        buyProposal[_nftContractAddress][_tokenId].buyer = _proposingBuyer;
        buyProposal[_nftContractAddress][_tokenId].price = _proposedPrice;
    }

    /// @notice Buyer will run this and buy the NFT from the proposal that he send and was accepted
    // by the seller.
    function buyFromProposal(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        nonReentrant
    {
        address seller = nftContractSale[_nftContractAddress][_tokenId]
            .nftSeller;
        require(
            msg.sender == buyProposal[_nftContractAddress][_tokenId].buyer,
            "Invalid Buyer"
        );
        require(msg.sender != seller, "Seller cannot buy own NFT");
        uint256 buyNowPrice = buyProposal[_nftContractAddress][_tokenId].price;
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);
        uint256 totalPayable = buyNowPrice + platformFees;
        uint royaltyAmount;

        require(msg.value >= totalPayable, "Must be greater than NFT cost");

        // 2. Cut ownerAmount from Seller
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                buyNowPrice -= ownerAmount;
                (bool _success, ) = payable(sellerCommission[i].affiliateAddr)
                    .call{value: ownerAmount}("");
                require(_success, "TRANSFER_FAILED");
            }
        }
        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (buyNowPrice * (dataStorage.nftCommission())) /
            (10000);

        // update total payable to seller
        totalPayable = totalPayable - (platformFees + buyNowPrice + nftFee);

        // Reset Sale Data
        _resetSale(_nftContractAddress, _tokenId);
        if (dataStorage.isActivated(_nftContractAddress, _tokenId) == true) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royaltypercentage
            royaltyAmount = (buyNowPrice * (_royaltyPercentage)) / (10000);
            totalPayable -= royaltyAmount;
            (bool _success, ) = payable(royaltyOwner).call{
                value: royaltyAmount
            }("");
            require(_success);
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        address owner = owner();
        uint256 adminFees = platformFees + nftFee;
        payable(owner).transfer(adminFees);
        (bool success, ) = payable(seller).call{value: totalPayable}("");
        if (!success) {
            revert();
        }
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function _resetSale(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        delete nftContractSale[_nftContractAddress][_tokenId];
    }

    /**
        @dev Gives the next minimum bidding amount by calculating how much amount bidder 
        already has in the contract and how much more needs to be added based on bid increase percentage
        @return Gives the next min extra bid.
     */
    function getNextMinBid(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (uint)
    {
        uint256 currentHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        uint256 bidIncreasePercentage = nftContractAuctions[
            _nftContractAddress
        ][_tokenId].bidIncreasePercentage;

        // Min Valid Bid Amount
        uint256 minBidAmount = (currentHighestBid *
            (100 + bidIncreasePercentage)) / 100;

        return minBidAmount;
    }

    /// @dev make bid and update the data
    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        paymentAccepted(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _tokenAmount
        )
    {
        // Total Bid Amount
        uint256 bidAmount = _tokenAmount +
            auctionBids[_nftContractAddress][_tokenId][msg.sender].bidAmount;

        // Min Valid Bid Amount
        uint256 minBidAmount = getNextMinBid(_nftContractAddress, _tokenId);
        require(bidAmount >= minBidAmount, "BID_NOT_ENOUGH");

        // final amount = extra bid amount + platform commission
        uint256 finalAmt = _tokenAmount +
            ((dataStorage.platformCommission() * _tokenAmount) / 10000);

        // Take platform commission from the bidder
        if (!_isERC20Auction(_erc20Token)) {
            require(msg.value == finalAmt, "PLATFORM_COMMISSION_ESCAPE");
        } else {
            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                finalAmt
            );
        }
        _reversePreviousBidAndUpdateHighestBid(
            _nftContractAddress,
            _tokenId,
            bidAmount
        );
        auctionBids[_nftContractAddress][_tokenId][msg.sender]
            .depositedAmt += finalAmt;
    }

    /**
        @notice Make a bid of _tokenAmount for the auction
        @dev Actual amount to transfer should be +platform fee greater than the _tokenAmount
        E.g. Bid Amount= 100 ETH, Actual Amt to deposit = 110 (if platform fee= 10%)
        Each next bid is added to the previous bid amount
        @param _nftContractAddress Contract address of NFT Token
        @param _tokenId TokenID of the NFT
        @param _tokenAmount Bidding Amount
     */
    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    )
        external
        payable
        nonReentrant
        auctionOngoing(_nftContractAddress, _tokenId)
    {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId]
                .nftHighestBidder != msg.sender,
            "Cannot bid again"
        );
        require(
            nftContractAuctions[_nftContractAddress][_tokenId]
                .auctionStartTime < block.timestamp,
            "Auction hasn't begun yet"
        );
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd != 0,
            "Auction Invalid"
        );
        uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice;
        address _erc20Token = nftContractAuctions[_nftContractAddress][_tokenId]
            .ERC20Token;
        // bid more than minimum price
        if (
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid ==
            0
        ) {
            require(
                (_tokenAmount >= minPrice) || (msg.value >= minPrice),
                "Must be greater than minimum amount"
            );
        }

        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
        // Save Bidding Data
        auctionBids[_nftContractAddress][_tokenId][msg.sender]
            .ERC20Token = _erc20Token;
    }

    /*
     * Reset all auction related parameters for an NFT.
     * This effectively removes an EFT as an item up for auction
     */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        delete nftContractAuctions[_nftContractAddress][_tokenId];
    }

    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            if (!success) {
                revert();
            }
        }
    }

    /**
        @notice Sends NFT and Amount to Buyer and Seller respectively
        @dev The admin fees is cut extra platform fee is cut from buyer, rest from seller
     */
    function _purchaseAndTransfer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) internal {
        address erc20Token = nftContractAuctions[_nftContractAddress][_tokenId]
            .ERC20Token;
        address _nftRecipient = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        uint totalAmount = _highestBid;
        // 1. Cut platform fees from the buyer
        uint256 platformFees = (_highestBid *
            (dataStorage.platformCommission())) / (10000);

        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (_highestBid * (dataStorage.nftCommission())) /
            (10000);

        // Reset Sale Data and Bidding data of the Winner
        _resetAuction(_nftContractAddress, _tokenId);
        delete auctionBids[_nftContractAddress][_tokenId][_nftRecipient];

        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royaltypercentage
            uint royaltyAmount = (_highestBid * (_royaltyPercentage)) / (10000);
            totalAmount -= royaltyAmount;
            if (_isERC20Auction(erc20Token)) {
                IERC20(erc20Token).transfer(royaltyOwner, royaltyAmount);
            } else {
                (bool success, ) = payable(royaltyOwner).call{
                    value: royaltyAmount
                }("");
                require(success);
            }
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }

        uint256 adminFees = platformFees + nftFee;
        totalAmount -= nftFee;

        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(_nftSeller);
        if (_isERC20Auction(erc20Token)) {
            // Seller Commission to Affiliates
            for (uint8 i = 0; i < sellerCommission.length; i++) {
                if (sellerCommission[i].feePercent > 0) {
                    uint256 ownerAmount = (_highestBid *
                        (sellerCommission[i].feePercent)) / (10000);
                    totalAmount -= ownerAmount;
                    IERC20(erc20Token).transfer(
                        sellerCommission[i].affiliateAddr,
                        ownerAmount
                    );
                }
            }
            // Admin's Fee
            if (adminFees > 0) {
                IERC20(erc20Token).transfer(owner(), adminFees);
            }
            // Seller's Amount
            IERC20(erc20Token).transfer(_nftSeller, totalAmount);
        } else {
            for (uint8 i = 0; i < sellerCommission.length; i++) {
                if (sellerCommission[i].feePercent > 0) {
                    uint256 ownerAmount = (_highestBid *
                        (sellerCommission[i].feePercent)) / (10000);
                    totalAmount -= ownerAmount;
                    (bool _success, ) = payable(
                        sellerCommission[i].affiliateAddr
                    ).call{value: ownerAmount}("");
                    require(_success, "TRANSFER_FAILED");
                }
            }

            // Admin Fees
            if (adminFees > 0) {
                payable(owner()).transfer(adminFees);
            }
            // Seller's Amount
            (bool success, ) = payable(_nftSeller).call{value: totalAmount}("");
            if (!success) {
                failedCredits[_nftSeller] += totalAmount;
            }
        }
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
        emit SettleAuction(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftRecipient,
            _highestBid
        );
    }

    /// @notice Settles the auction and pays the seller
    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        // payable
        nonReentrant
        isAuctionOver(_nftContractAddress, _tokenId)
    {
        uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice;
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        require(_nftHighestBid >= minPrice, "No bid has been made");
        _purchaseAndTransfer(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid
        );
    }

    /**
        @notice switch auction to sale
        @param _nftContractAddress Address of NFT token
        @param _erc20Token ERC20 token used in purchase
        @param _buyNowPrice Buy now price of NFT
        @param _royaltyPercentage Royalty percent
     */
    function switchAuctionToSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _buyNowPrice,
        uint32 _royaltyPercentage
    )
        public
        minimumBidNotMade(_nftContractAddress, _tokenId)
        auctionOngoing(_nftContractAddress, _tokenId)
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        // reset auction
        _resetAuction(_nftContractAddress, _tokenId);
        // setupResale
        _setupSale(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _buyNowPrice,
            _royaltyPercentage
        );
    }

    /**
        @notice Switch Sale to Auction
        @param _minPrice Minimum bidding price
        @param _royaltyPercentage royalty percentage for NFT
        @param _auctionBidPeriod Auction duration
        @param _bidIncreasePercentage Percentage that next bid should increase
        @param _auctionStartTime Seconds after which auction will start
     */
    function switchSaleToAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint256 _minPrice,
        uint32 _royaltyPercentage,
        uint256 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        uint256 _auctionStartTime
    ) public {
        address nftSeller = nftContractSale[_nftContractAddress][_tokenId]
            .nftSeller;
        require(msg.sender == nftSeller, "Unauthorized seller");
        // Reset Sale
        _resetSale(_nftContractAddress, _tokenId);

        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = _bidIncreasePercentage;

        if (
            dataStorage.getRoyaltyOwner(_nftContractAddress, _tokenId) ==
            address(0)
        ) {
            dataStorage.setRoyaltyData(
                _nftContractAddress,
                _tokenId,
                _royaltyPercentage,
                msg.sender
            );
        }
        _setupAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _auctionStartTime,
            _auctionBidPeriod
        );
    }

    /**
        @notice Seller can withdraw his NFT sale
     */
    function withdrawSale(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        address nftSeller = nftContractSale[_nftContractAddress][_tokenId]
            .nftSeller;
        require(
            nftSeller == msg.sender,
            "Only the owner can call this function"
        );
        // reset sale
        _resetSale(_nftContractAddress, _tokenId);
        // transfer the NFT back to the Seller
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            nftSeller,
            _tokenId
        );
    }

    /**
        @notice Admin can remove the specified NFT from sale
     */
    function removeFromSale(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        address nftSeller = nftContractSale[_nftContractAddress][_tokenId]
            .nftSeller;
        // reset sale
        _resetSale(_nftContractAddress, _tokenId);
        // transfer the NFT back to the Seller
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            nftSeller,
            _tokenId
        );
    }

    /**
        @notice Seller can withdraw his NFT auction anytime, any bidder will get back the bid amt
    */
    function withdrawAuction(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyNftSeller(_nftContractAddress, _tokenId)
    {
        address _nftRecipient = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftSeller;

        // Reset values of this Auction
        _resetAuction(_nftContractAddress, _tokenId);
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
    }

    /**
        @notice Seller can withdraw his NFT auction anytime, any bidder will get back the bid amt
    */
    function removeFromAuction(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        address _nftRecipient = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftSeller;

        // Reset values of this Auction
        _resetAuction(_nftContractAddress, _tokenId);
        IERC721(_nftContractAddress).safeTransferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );
    }

    /**
        @notice Seller able to change min price, auction duration and royalty percentage
        @dev Royalty percentage is changeable iff it's not active    
    */
    function changeAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint _minPrice,
        int _duration,
        uint _royaltyPercentage
    ) public {
        require(
            msg.sender ==
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only Seller allowed"
        );
        uint bid = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid;
        if (bid < _minPrice) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .minPrice = _minPrice;
        }
        uint _newTime = uint(
            int(nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd) +
                _duration
        );
        if (_newTime > block.timestamp) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .auctionEnd = _newTime;
        }
        if (!dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            dataStorage.setRoyaltyPercentage(
                _nftContractAddress,
                _tokenId,
                _royaltyPercentage
            );
        }
    }

    /**
        @notice Seller able to change price and royalty his NFT sale
    */
    function changeSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint _buyNowPrice,
        uint _royaltyPercentage
    ) public {
        require(
            msg.sender ==
                nftContractSale[_nftContractAddress][_tokenId].nftSeller,
            "Only Seller allowed"
        );
        nftContractSale[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        if (!dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            dataStorage.setRoyaltyPercentage(
                _nftContractAddress,
                _tokenId,
                _royaltyPercentage
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}