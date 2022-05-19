// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../libraries/AdministratedUpgradeable.sol";
import "../marketplace/ISplitterContract.sol";
import "./IRKMarket.sol";

contract EnglishAuctionETH is
    AdministratedUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice Status of lot
    enum LotStatus {
        live,
        canceled,
        sold,
        returned
    }

    /// @notice Status of bid
    enum BidStatus {
        confirmed,
        rejected,
        wins
    }

    /// @notice Lot object
    struct Lot {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 price;
        uint256 start;
        uint256 duration;
        LotStatus status;
    }

    /// @notice Bid object
    struct Bid {
        address bidder;
        uint256 value;
        BidStatus status;
    }

    /// @notice Array of a lots
    Lot[] public lots;

    /// @notice Denominator for a fractional part
    /// @dev 100 == 1%
    uint256 public constant DENOMINATOR = 10000;

    /// @notice Ten minutes in seconds
    uint256 public constant TEN_MINUTES = 10 * 60;

    /// @notice Next bid should be more than previous one for this percent
    uint256 public minBidPercent;

    /// @dev Array of bids for each lot
    mapping(uint256 => Bid[]) public lotsBids;

    /// @notice Acceptable durations
    mapping(uint256 => uint256) public availableDurations;

    /// @notice Address of the Splitter Contract
    address public splitter;

    /// @notice Address of the RKMarket Contract
    address public market;

    /// @notice Is extend auction duration after last bid?
    /// @dev If less than 10 minutes remain before the end of the auction and someone makes a new bid
    bool public extendDuration;

    /// @notice On new bid made
    event NewBid(uint256 indexed lotId, address indexed bidder, uint256 value);

    /// @notice On new lot created
    event NewLot(
        uint256 indexed lotId,
        address indexed seller,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        uint256 startsAt,
        uint256 duration
    );

    /// @notice When lot sold successfully
    event Sold(
        address indexed buyer,
        address indexed seller,
        address indexed nft,
        uint256 tokenId,
        uint256 lotId,
        uint256 value
    );

    /// @notice If lot doesn't sold
    event Returned(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 lotId
    );

    /// @notice When seller cancels the lot
    event Canceled(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 lotId
    );

    /// @notice When duration updated
    event DurationUpdated(uint256 indexed durationId, uint256 duration);

    /// @notice When minimal bid percent value changed
    event MinBidPercentChanged(uint256 oldPercent, uint256 newPercent);

    /// @notice When extendDuration option changed
    event ExtendDuration(bool isExtend);

    /// @notice When Splitter contract address changed
    event SplitterChanged(address oldSplitter, address newSplitter);

    /// @notice When RKMarket address changed
    event MarketChanged(address oldMarket, address newMarket);

    /**
     * @notice Restrict if splitter address is not set yet
     */
    modifier splitterExist() {
        require(splitter != address(0), "set splitter contract first");
        _;
    }

    /**
     * Getters
     */

    /// @notice Count all lots
    function totalLots() external view returns (uint256 _totalLots) {
        _totalLots = lots.length;
    }

    /**
     * @notice Get all bids of specified lot
     * @param lotId - ID of the lot
     * @return Array of bids
     */
    function bidsOfLot(uint256 lotId) external view returns (Bid[] memory) {
        return lotsBids[lotId];
    }

    /**
     * Setters
     */

    /**
     * @notice Change available durations
     * @dev Restricted to owner
     * @param durationId - Duration days
     * @param duration - Duration in seconds
     */
    function setDuration(uint256 durationId, uint256 duration)
        external
        onlyAdmin
    {
        availableDurations[durationId] = duration;
        emit DurationUpdated(durationId, duration);
    }

    /**
     * @notice Change minBidPercent value
     * @dev Restricted to owner, 1 == 0.01%
     * @param newMinBidPercent - New percent
     */
    function setMinBidPercent(uint256 newMinBidPercent) external onlyAdmin {
        uint256 _oldPercent = minBidPercent;
        minBidPercent = newMinBidPercent;
        emit MinBidPercentChanged(_oldPercent, newMinBidPercent);
    }

    /**
     * @notice Turn on/off duration extender
     * @dev Restricted to owner
     * @param isExtend - True to turn on
     */
    function setExtendDuration(bool isExtend) external onlyAdmin {
        require(isExtend != extendDuration, "same value");
        extendDuration = isExtend;
        emit ExtendDuration(isExtend);
    }

    /**
     * @notice Set splitter address
     * @param newSplitter - Address of the Splitter Contract
     */
    function setSplitter(address newSplitter) external onlyOwner {
        require(newSplitter != address(0), "zero address");
        require(newSplitter != splitter, "same address");
        emit SplitterChanged(splitter, newSplitter);
        splitter = newSplitter;
    }

    /**
     * @notice Set market address
     * @param newMarket - Address of the market Contract
     */
    function setRKMarket(address newMarket) external onlyOwner {
        require(newMarket != address(0), "zero address");
        require(newMarket != market, "same address");
        emit MarketChanged(market, newMarket);
        market = newMarket;
    }

    /**
     * Auction
     */

    /**
     * @notice Add new lot to the auction
     * @dev Lots from the admin account doesn't requires moderation
     * @param nft - Address of the NFT
     * @param tokenId - Id of NFT
     * @param price - Start price
     * @param duration - Duration of the auction in days
     */
    function addLot(
        address nft,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    ) external nonReentrant {
        require(availableDurations[duration] > 0, "wrong duration");
        require(nft != address(0), "zero address");
        require(price > DENOMINATOR, "price too low");
        IERC721Upgradeable(nft).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        LotStatus _lotStatus = LotStatus.live;
        uint256 _start = block.timestamp;
        Lot memory _lot = Lot(
            msg.sender,
            nft,
            tokenId,
            price,
            _start,
            availableDurations[duration],
            _lotStatus
        );
        uint256 _lotId = lots.length;
        lots.push(_lot);
        emit NewLot(
            _lotId,
            msg.sender,
            nft,
            tokenId,
            price / 1e9,
            _start,
            availableDurations[duration]
        );
    }

    /**
     * @notice Cancel lot
     * @param lotId - ID of the lot instance (index)
     */
    function cancel(uint256 lotId) external {
        Lot storage _lot = lots[lotId];
        require(_lot.status == LotStatus.live, "not live");
        require(msg.sender == _lot.seller, "restricted");
        _lot.status = LotStatus.canceled;
        Bid[] storage _bids = lotsBids[lotId];
        if (_bids.length > 0) {
            for (uint256 _i = 0; _i < _bids.length; _i++) {
                if (_bids[_i].status == BidStatus.confirmed) {
                    _bids[_i].status = BidStatus.rejected;
                    (bool success, ) = _bids[_i].bidder.call{
                        value: _bids[_i].value
                    }("");
                    require(success, "_returnFundsForLastBid: transfer failed");
                }
            }
        }
        IERC721Upgradeable(_lot.nft).safeTransferFrom(
            address(this),
            _lot.seller,
            _lot.tokenId
        );
        emit Canceled(_lot.seller, _lot.nft, _lot.tokenId, lotId);
    }

    /**
     * @notice Make a bid for a lot
     * @param lotId - ID of the lot instance (index)
     * @param amount - amount in wei
     */
    function bid(uint256 lotId, uint256 amount) external payable nonReentrant {
        Lot storage _lot = lots[lotId];
        require(_lot.status == LotStatus.live, "inactive lot");
        require(_lot.start + _lot.duration >= block.timestamp, "auction ended");
        Bid[] storage _bids = lotsBids[lotId];
        if (_bids.length > 0) {
            uint256 _lastBidAmount = _bids[_bids.length - 1].value;
            uint256 _minBidAmount = _lastBidAmount +
                ((_lastBidAmount * minBidPercent) / DENOMINATOR);
            require(msg.value > _minBidAmount, "bid too low");
            _returnFundsForLastBid(lotId);
        }
        if (
            extendDuration &&
            _lot.start + _lot.duration - block.timestamp <= TEN_MINUTES
        ) {
            _lot.duration += TEN_MINUTES;
        }
        Bid memory _newBid = Bid(msg.sender, amount, BidStatus.confirmed);
        _bids.push(_newBid);
        emit NewBid(lotId, msg.sender, amount / 1e9);
    }

    /**
     * @notice Finish auction. Can be executed by anybody.
     * @param lotId - ID of the lot instance (index)
     */
    function finalize(uint256 lotId) external nonReentrant splitterExist {
        Lot storage _lot = lots[lotId];
        require(_lot.status == LotStatus.live, "inactive lot");
        require(
            _lot.start + _lot.duration < block.timestamp,
            "auction doesn't ended"
        );
        require(
            IRKMarket(market).getArtistOfTokenId(_lot.nft, _lot.tokenId) !=
                address(0) ||
                IRKMarket(market).getArtistForCollection(_lot.nft) !=
                address(0),
            "add artist first"
        );
        Bid[] storage _bids = lotsBids[lotId];
        if (_bids.length > 0) {
            _lot.status = LotStatus.sold;
            Bid storage _winner = _bids[_bids.length - 1];
            _winner.status = BidStatus.wins;

            address _artist;
            if (
                IRKMarket(market).getArtistOfTokenId(_lot.nft, _lot.tokenId) !=
                address(0)
            ) {
                _artist = IRKMarket(market).getArtistOfTokenId(
                    _lot.nft,
                    _lot.tokenId
                );
            } else {
                _artist = IRKMarket(market).getArtistForCollection(_lot.nft);
            }

            if (_lot.seller == admin()) {
                ISplitterContract(splitter).primaryDistributionETH{
                    value: _winner.value
                }(_artist, _winner.value);
            } else {
                ISplitterContract(splitter).secondaryDistributionETH{
                    value: _winner.value
                }(_artist, _lot.seller, _winner.value);
            }

            IERC721Upgradeable(_lot.nft).safeTransferFrom(
                address(this),
                _winner.bidder,
                _lot.tokenId
            );
            emit Sold(
                _winner.bidder,
                _lot.seller,
                _lot.nft,
                _lot.tokenId,
                lotId,
                _winner.value / 1e9
            );
        } else {
            _lot.status = LotStatus.returned;
            IERC721Upgradeable(_lot.nft).safeTransferFrom(
                address(this),
                _lot.seller,
                _lot.tokenId
            );
            emit Returned(_lot.seller, _lot.nft, _lot.tokenId, lotId);
        }
    }

    /**
     * System and private functions
     */

    /**
     * @notice Return last bid eth
     * @param lotId - ID of the lot instance (index)
     */
    function _returnFundsForLastBid(uint256 lotId) internal {
        Bid[] storage _bids = lotsBids[lotId];
        if (_bids.length > 0) {
            Bid storage _lastBid = _bids[_bids.length - 1];
            if (_lastBid.status == BidStatus.confirmed) {
                _lastBid.status = BidStatus.rejected;
                (bool success, ) = _lastBid.bidder.call{value: _lastBid.value}(
                    ""
                );
                require(success, "_returnFundsForLastBid: transfer failed");
            }
        }
    }

    /**
     * @notice Acts like constructor() for upgradeable contracts
     * @param adminAddress - Administrator address
     */
    function initialize(address adminAddress)
        external
        initializer
    {
        __Administrated_init();
        changeAdmin(adminAddress);
        availableDurations[1] = 1 days;
        availableDurations[2] = 2 days;
        availableDurations[3] = 3 days;
        availableDurations[5] = 5 days;
        minBidPercent = 250; // 2.5%
        extendDuration = true;
    }

    /// @notice To make ERC721 safeTransferFrom works
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev This is adoption of OpenZeppelin's OwnableUpgradeable.sol to fit our needs.
 */
abstract contract AdministratedUpgradeable is
    Initializable,
    ContextUpgradeable
{
    /// @dev Owner can change admin
    address private _owner;

    /**
     * @dev Admin is the main role. Since the administrator is a system role and will
     * be used on the backend, for security reasons, the owner can change the address of
     * the administrator to minimize possible risks.
     */
    address private _admin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Administrated_init() internal onlyInitializing {
        __Context_init_unchained();
        __Administrated_init_unchained();
    }

    function __Administrated_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
        _changeAdmin(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "caller is not the admin");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            admin() == _msgSender() || owner() == _msgSender(),
            "caller is not the admin or owner"
        );
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Change admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current owner.
     */
    function changeAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "new admin is the zero address");
        _changeAdmin(newAdmin);
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

    /**
     * @dev Change admin of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _changeAdmin(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminChanged(oldAdmin, newAdmin);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISplitterContract {
    function rkMarket() external view returns (address);

    function SELLER_SHARE() external view returns (uint256);

    function addMarket(address newMarket) external;

    function admin() external view returns (address);

    function getPrimaryDistribution(address artist)
        external
        view
        returns (address[] memory addresses, uint256[] memory shares);

    function getSecondaryDistribution(address artist)
        external
        view
        returns (address[] memory addresses, uint256[] memory shares);

    function initialize(
        address _admin,
        address _rkMarket,
        address _router,
        address[] memory _path
    ) external;

    function otherMarkets(address) external view returns (bool);

    function owner() external view returns (address);

    function path(uint256) external view returns (address);

    function primaryDistribution(address artist, uint256 amount) external;

    function primaryDistributionETH(address artist, uint256 amount)
        external
        payable;

    function renounceOwnership() external;

    function rescueTokens(address _token) external;

    function router() external view returns (address);

    function secondaryDistribution(
        address artist,
        address seller,
        uint256 amount
    ) external;

    function secondaryDistributionETH(
        address artist,
        address seller,
        uint256 amount
    ) external payable;

    function setAdmin(address newAdmin) external;

    function setDistribution(
        address artist,
        address[] calldata primary_addresses,
        uint256[] calldata primary_shares,
        address[] calldata secondary_addresses,
        uint256[] calldata secondary_shares
    ) external;

    function setFeeDecimals(uint256 _decimals) external;

    function setPath(address[] calldata _path) external;

    function setPrimaryDistribution(
        address artist,
        address[] calldata addresses,
        uint256[] calldata shares
    ) external;

    function setRKMarket(address newMarket) external;

    function setRouter(address _router) external;

    function setSecondaryDistribution(
        address artist,
        address[] calldata addresses,
        uint256[] calldata shares
    ) external;

    function setUSDC(address _usdc) external;

    function setWETH(address _weth) external;

    function shareDecimals() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function usdc() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRKMarket {
    function getArtistOfTokenId(address nft, uint256 id)
        external
        view
        returns (address artist);

    function getArtistForCollection(address nft)
        external
        view
        returns (address artist);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}