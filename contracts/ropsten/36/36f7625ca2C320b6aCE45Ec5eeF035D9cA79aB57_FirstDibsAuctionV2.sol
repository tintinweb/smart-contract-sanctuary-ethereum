//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/IAccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/PullPayment.sol';

import '../interfaces/IOwnable.sol';
import './IFirstDibsMarketSettingsV2.sol';
import '../royaltyEngine/IRoyaltyEngineV1.sol';
import './BidUtils.sol';
import './FirstDibsERC2771Context.sol';
import './IERC721TokenCreatorV2.sol';

contract FirstDibsAuctionV2 is
    PullPayment,
    AccessControl,
    ReentrancyGuard,
    IERC721Receiver,
    FirstDibsERC2771Context
{
    using BidUtils for uint256;

    bytes32 public constant BIDDER_ROLE = keccak256('BIDDER_ROLE');
    /**
     * ========================
     * #Public state variables
     * ========================
     */
    bool public bidderRoleRequired; // if true, bids require bidder having BIDDER_ROLE role
    bool public globalPaused; // flag for pausing all auctions
    IFirstDibsMarketSettingsV2 public iFirstDibsMarketSettings;
    IERC721TokenCreatorV2 public iERC721TokenCreatorRegistry;
    address public manifoldRoyaltyEngineAddress; // address of the manifold royalty engine https://royaltyregistry.xyz
    address public auctionV1Address; // address of the V1 auction contract, used as the source of bidder role truth

    // Mapping auction id => Auction
    mapping(uint256 => Auction) public auctions;
    // Map token address => tokenId => auctionId
    mapping(address => mapping(uint256 => uint256)) public auctionIds;

    /*
     * ========================
     * #Private state variables
     * ========================
     */
    uint256 private auctionIdsCounter;

    /**
     * ========================
     * #Structs
     * ========================
     */
    struct AuctionSettings {
        uint32 buyerPremium; // RBS; added on top of current bid
        uint32 duration; // defaults to globalDuration
        uint32 minimumBidIncrement; // defaults to globalMinimumBidIncrement
        uint32 commissionRate; // percent; defaults to globalMarketCommission
    }

    struct Bid {
        uint256 amount; // current winning bid of the auction
        uint256 buyerPremiumAmount; // current buyer premium associated with current bid
    }

    struct Auction {
        uint256 startTime; // auction start timestamp
        uint256 pausedTime; // when was the auction paused
        uint256 reservePrice; // minimum bid threshold for auction to begin
        uint256 tokenId; // id of the token
        bool paused; // is individual auction paused
        address nftAddress; // address of the token
        address tokenOwner; // address of the owner of the token
        address payable fundsRecipient; // address of auction proceeds recipient
        address payable currentBidder; // current winning bidder of the auction
        address auctionCreator; // address of the creator of the auction (whoever called the createAuction method)
        AuctionSettings settings;
        Bid currentBid;
    }

    /**
     * ========================
     * #Modifiers
     * ========================
     */
    function onlyAdmin() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'caller is not an admin');
    }

    function notPaused(uint256 auctionId) internal view {
        require(!globalPaused && !auctions[auctionId].paused, 'auction paused');
    }

    function auctionExists(uint256 auctionId) internal view {
        require(auctions[auctionId].fundsRecipient != address(0), "auction doesn't exist");
    }

    function hasBid(uint256 auctionId) internal view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            // only admin may change state of auction with bids
            require(
                auctions[auctionId].currentBidder == address(0),
                'only admin can update state of auction with bids'
            );
        }
    }

    function senderIsAuctionCreatorOrAdmin(uint256 auctionId) internal view {
        require(
            _msgSender() == auctions[auctionId].auctionCreator ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'must be auction creator or admin'
        );
    }

    function checkZeroAddress(address addr) internal pure {
        require(addr != address(0), '0 address not allowed');
    }

    /**
     * ========================
     * #Events
     * ========================
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenSeller,
        address fundsRecipient,
        uint256 reservePrice,
        bool isPaused,
        address auctionCreator,
        uint64 duration
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidBuyerPremium,
        uint64 duration,
        uint256 startTime
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address indexed winningBidder,
        uint256 winningBid,
        uint256 winningBidBuyerPremium,
        uint256 adminCommissionFee,
        uint256 royaltyFee,
        uint256 sellerPayment
    );

    event AuctionPaused(
        uint256 indexed auctionId,
        address indexed tokenSeller,
        address toggledBy,
        bool isPaused,
        uint64 duration
    );

    event AuctionCanceled(uint256 indexed auctionId, address canceledBy, uint256 refundedAmount);

    event TransferFailed(address to, uint256 amount);

    /**
     * ========================
     * constructor
     * ========================
     */
    constructor(
        address _marketSettings,
        address _creatorRegistry,
        address _trustedForwarder,
        address _manifoldRoyaltyEngineAddress,
        address _auctionV1Address
    ) FirstDibsERC2771Context(_trustedForwarder) {
        require(
            _marketSettings != address(0) &&
                _creatorRegistry != address(0) &&
                _manifoldRoyaltyEngineAddress != address(0) &&
                _auctionV1Address != address(0),
            '0 address for contract ref'
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract gets admin permissions
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_marketSettings);
        iERC721TokenCreatorRegistry = IERC721TokenCreatorV2(_creatorRegistry);
        manifoldRoyaltyEngineAddress = _manifoldRoyaltyEngineAddress;
        auctionV1Address = _auctionV1Address;
        bidderRoleRequired = true;
        auctionIdsCounter = 0;
    }

    /**
     * @dev setter for manifold royalty engine address
     * @param _manifoldRoyaltyEngineAddress new manifold royalty engine address
     */
    function setManifoldRoyaltyEngineAddress(address _manifoldRoyaltyEngineAddress) external {
        onlyAdmin();
        checkZeroAddress(_manifoldRoyaltyEngineAddress);
        manifoldRoyaltyEngineAddress = _manifoldRoyaltyEngineAddress;
    }

    /**
     * @dev setter for market settings address
     * @param _iFirstDibsMarketSettings address of the FirstDibsMarketSettings contract to set for the auction
     */
    function setIFirstDibsMarketSettings(address _iFirstDibsMarketSettings) external {
        onlyAdmin();
        checkZeroAddress(_iFirstDibsMarketSettings);
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_iFirstDibsMarketSettings);
    }

    /**
     * @dev setter for creator registry address
     * @param _iERC721TokenCreatorRegistry address of the IERC721TokenCreator contract to set for the auction
     */
    function setIERC721TokenCreatorRegistry(address _iERC721TokenCreatorRegistry) external {
        onlyAdmin();
        checkZeroAddress(_iERC721TokenCreatorRegistry);
        iERC721TokenCreatorRegistry = IERC721TokenCreatorV2(_iERC721TokenCreatorRegistry);
    }

    /**
     * @dev setter for setting bidder role being required to bid
     * @param _bidderRole bool If true, bidder must have bidder role to bid
     */
    function setBidderRoleRequired(bool _bidderRole) external {
        onlyAdmin();
        bidderRoleRequired = _bidderRole;
    }

    /**
     * @dev setter for global pause state
     * @param _paused true to pause all auctions, false to unpause all auctions
     */
    function setGlobalPaused(bool _paused) external {
        onlyAdmin();
        globalPaused = _paused;
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, and custom minimum bid increment.
     *
     * @param _nftAddress address of ERC-721 contract
     * @param _tokenId uint256
     * @param _reservePrice uint256 reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg (optional) unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _fundsRecipient address to send auction proceeds to
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        address _fundsRecipient
    ) external {
        adminCreateAuction(
            _nftAddress,
            _tokenId,
            _reservePrice,
            _pausedArg,
            _startTimeArg,
            _auctionDurationArg,
            _fundsRecipient,
            10001 // adminCreateAuction function ignores values > 10000
        );
    }

    /**
     * @dev External function which creates an auction with a reserve price,
     * custom start time, custom duration, custom minimum bid increment,
     * custom commission rate, and custom creator royalty rate.
     *
     * @param _nftAddress address of ERC-721 contract (latest FirstDibsToken address)
     * @param _tokenId uint256
     * @param _reservePrice reserve price in ETH
     * @param _pausedArg create the auction in a paused state
     * @param _startTimeArg (optional) unix timestamp; allow bidding to start at this time
     * @param _auctionDurationArg (optional) auction duration in seconds
     * @param _fundsRecipient address to send auction proceeds to
     * @param _commissionRateArg (optional) admin-only; pass in a custom marketplace commission rate
     */
    function adminCreateAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice,
        bool _pausedArg,
        uint64 _startTimeArg,
        uint32 _auctionDurationArg,
        address _fundsRecipient,
        uint16 _commissionRateArg
    ) public {
        notPaused(0);
        // May not create auctions unless you are the token owner or
        // an admin of this contract
        address tokenOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        require(
            _msgSender() == tokenOwner ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                IERC721(_nftAddress).getApproved(_tokenId) == _msgSender() ||
                IERC721(_nftAddress).isApprovedForAll(tokenOwner, _msgSender()),
            'must be token owner, admin, or approved'
        );

        require(_fundsRecipient != address(0), 'must pass funds recipient');

        require(auctionIds[_nftAddress][_tokenId] == 0, 'auction already exists');

        require(_reservePrice > 0, 'Reserve must be > 0');

        Auction memory auction = Auction({
            currentBid: Bid({ amount: 0, buyerPremiumAmount: 0 }),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenOwner: tokenOwner,
            fundsRecipient: payable(_fundsRecipient), // pass in the fundsRecipient
            auctionCreator: _msgSender(),
            reservePrice: _reservePrice, // minimum bid threshold for auction to begin
            startTime: 0,
            currentBidder: payable(address(0)), // there is no bidder at auction creation
            paused: _pausedArg, // is individual auction paused
            pausedTime: 0, // when the auction was paused
            settings: AuctionSettings({ // Defaults to global market settings; admins may override
                buyerPremium: iFirstDibsMarketSettings.globalBuyerPremium(),
                duration: iFirstDibsMarketSettings.globalAuctionDuration(),
                minimumBidIncrement: iFirstDibsMarketSettings.globalMinimumBidIncrement(),
                commissionRate: iFirstDibsMarketSettings.globalMarketCommission()
            })
        });
        if (_auctionDurationArg > 0) {
            require(
                _auctionDurationArg >= iFirstDibsMarketSettings.globalTimeBuffer(),
                'duration must be >= time buffer'
            );
            auction.settings.duration = _auctionDurationArg;
        }

        if (_startTimeArg > 0) {
            require(block.timestamp < _startTimeArg, 'start time must be in the future');
            auction.startTime = _startTimeArg;
            // since `bid` is gated by `notPaused` modifier
            // and a start time in the future means that a bid
            // must be allowed after that time, we can't have
            // the auction paused if there is a start time > 0
            auction.paused = false;
        }

        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (_commissionRateArg <= 10000) {
                auction.settings.commissionRate = _commissionRateArg;
            }
        }

        auctionIdsCounter++;
        auctions[auctionIdsCounter] = auction;
        auctionIds[_nftAddress][_tokenId] = auctionIdsCounter;

        // transfer the NFT to the auction contract to hold in escrow for the duration of the auction
        IERC721(_nftAddress).safeTransferFrom(tokenOwner, address(this), _tokenId);

        emit AuctionCreated(
            auctionIdsCounter,
            _nftAddress,
            _tokenId,
            tokenOwner,
            _fundsRecipient,
            _reservePrice,
            auction.paused,
            _msgSender(),
            auction.settings.duration
        );
    }

    /**
     * @dev external function that can be called by any address which submits a bid to an auction
     * @param _auctionId uint256 id of the auction
     * @param _amount uint256 bid in WEI
     */
    function bid(uint256 _auctionId, uint256 _amount) external payable nonReentrant {
        auctionExists(_auctionId);
        notPaused(_auctionId);

        if (bidderRoleRequired == true) {
            require(
                IAccessControl(auctionV1Address).hasRole(BIDDER_ROLE, _msgSender()),
                'bidder role required'
            );
        }
        require(msg.value > 0 && _amount == msg.value, 'invalid bid value');
        // Auctions with a start time can't accept bids until now is greater than start time
        require(block.timestamp >= auctions[_auctionId].startTime, 'auction not started');
        // Auctions with an end time less than now may accept a bid
        require(
            auctions[_auctionId].startTime == 0 || block.timestamp < _endTime(_auctionId),
            'auction expired'
        );
        require(
            auctions[_auctionId].currentBidder != _msgSender() &&
                auctions[_auctionId].fundsRecipient != _msgSender() &&
                auctions[_auctionId].tokenOwner != _msgSender(),
            'invalid bidder'
        );

        // Validate the amount sent and get sent bid and sent premium
        (uint256 _sentBid, uint256 _sentPremium) = _amount.validateAndGetBid(
            auctions[_auctionId].settings.buyerPremium,
            auctions[_auctionId].reservePrice,
            auctions[_auctionId].currentBid.amount,
            auctions[_auctionId].settings.minimumBidIncrement,
            auctions[_auctionId].currentBidder
        );

        // bid amount is OK, if not first bid, then transfer funds
        // back to previous bidder & update current bidder to the current sender
        if (auctions[_auctionId].startTime == 0) {
            auctions[_auctionId].startTime = uint64(block.timestamp);
        } else if (auctions[_auctionId].currentBidder != address(0)) {
            _tryTransferThenEscrow(
                auctions[_auctionId].currentBidder, // prior
                auctions[_auctionId].currentBid.amount +
                    auctions[_auctionId].currentBid.buyerPremiumAmount // refund amount
            );
        }
        auctions[_auctionId].currentBid.amount = _sentBid;
        auctions[_auctionId].currentBid.buyerPremiumAmount = _sentPremium;
        auctions[_auctionId].currentBidder = payable(_msgSender());

        // extend countdown for bids within the time buffer of the auction
        if (
            // if auction ends less than globalTimeBuffer from now
            _endTime(_auctionId) < block.timestamp + iFirstDibsMarketSettings.globalTimeBuffer()
        ) {
            // increment the duration by the difference between the new end time and the old end time
            auctions[_auctionId].settings.duration += uint32(
                block.timestamp + iFirstDibsMarketSettings.globalTimeBuffer() - _endTime(_auctionId)
            );
        }

        emit AuctionBid(
            _auctionId,
            _msgSender(),
            _sentBid,
            _sentPremium,
            auctions[_auctionId].settings.duration,
            auctions[_auctionId].startTime
        );
    }

    /**
     * @dev method for ending an auction which has expired. Distrubutes payment to all parties & send
     * token to winning bidder (or returns it to the auction creator if there was no winner)
     * @param _auctionId uint256 id of the token
     */
    function endAuction(uint256 _auctionId) external nonReentrant {
        auctionExists(_auctionId);
        notPaused(_auctionId);
        require(auctions[_auctionId].currentBidder != address(0), 'no bidders; use cancelAuction');

        require(
            auctions[_auctionId].startTime > 0 && //  auction has started
                block.timestamp >= _endTime(_auctionId), // past the endtime of the auction,
            'auction is not complete'
        );

        Auction memory auction = auctions[_auctionId];
        _delete(_auctionId);

        // send commission fee & buyer premium to commission address
        uint256 commissionFee = (auction.currentBid.amount * auction.settings.commissionRate) /
            10000;
        // don't attempt to transfer fees if there are none
        if (commissionFee + auction.currentBid.buyerPremiumAmount > 0) {
            _tryTransferThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee + auction.currentBid.buyerPremiumAmount
            );
        }

        // Find token creator to determine if this is a primary sale
        // 1.  Get token creator from 1stDibs token registry;
        //     applies to 1stDibs tokens only
        address nftCreator = iERC721TokenCreatorRegistry.tokenCreator(
            auction.nftAddress,
            auction.tokenId
        );

        // 2. If token creator has not been registered through 1stDibs, check contract owner.
        //    We're assuming that creator is the owner, which isn't foolproof. Our primary use-case
        //    for non-1D tokens are Manifold ERC721 contracts and it's a reasonable assumption that
        //    creator equals contract owner. There are edge cases where this assumption will fail
        if (nftCreator == address(0)) {
            try IOwnable(auction.nftAddress).owner() returns (address owner) {
                nftCreator = owner;
            } catch {}
        }

        uint256 royaltyAmount = 0;
        if (nftCreator != auction.tokenOwner && nftCreator != address(0)) {
            // creator is not seller, so payout royalties
            // get royalty information from manifold royalty engine
            // https://royaltyregistry.xyz/
            (
                address payable[] memory royaltyRecipients,
                uint256[] memory amounts
            ) = IRoyaltyEngineV1(manifoldRoyaltyEngineAddress).getRoyalty(
                    auction.nftAddress,
                    auction.tokenId,
                    auction.currentBid.amount
                );
            uint256 arrLength = royaltyRecipients.length;
            for (uint256 i = 0; i < arrLength; ) {
                if (amounts[i] != 0 && royaltyRecipients[i] != address(0)) {
                    royaltyAmount += amounts[i];
                    _sendFunds(royaltyRecipients[i], amounts[i]);
                }
                unchecked {
                    ++i;
                }
            }
        }
        uint256 sellerFee = auction.currentBid.amount - royaltyAmount - commissionFee;
        _sendFunds(auction.fundsRecipient, sellerFee);

        // send the NFT to the winning bidder
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this), // from
            auction.currentBidder, // to
            auction.tokenId
        );
        emit AuctionEnded(
            _auctionId,
            auction.tokenOwner,
            auction.currentBidder,
            auction.currentBid.amount,
            auction.currentBid.buyerPremiumAmount,
            commissionFee,
            royaltyAmount,
            sellerFee
        );
    }

    /**
     * @dev external function to cancel an auction & return the NFT to the creator of the auction
     * @param _auctionId uint256 auction id
     */
    function cancelAuction(uint256 _auctionId) external nonReentrant {
        senderIsAuctionCreatorOrAdmin(_auctionId);
        auctionExists(_auctionId);
        hasBid(_auctionId);

        Auction memory auction = auctions[_auctionId];
        _delete(_auctionId);

        // return the token back to the original owner
        IERC721(auction.nftAddress).safeTransferFrom(
            address(this),
            auction.tokenOwner,
            auction.tokenId
        );

        uint256 refundAmount = 0;
        if (auction.currentBidder != address(0)) {
            // If there's a bidder, return funds to them
            refundAmount = auction.currentBid.amount + auction.currentBid.buyerPremiumAmount;
            _tryTransferThenEscrow(auction.currentBidder, refundAmount);
        }

        emit AuctionCanceled(_auctionId, _msgSender(), refundAmount);
    }

    /**
     * @dev external function for pausing / unpausing an auction
     * @param _auctionId uint256 auction id
     * @param _paused true to pause the auction, false to unpause the auction
     */
    function setAuctionPause(uint256 _auctionId, bool _paused) external {
        senderIsAuctionCreatorOrAdmin(_auctionId);
        auctionExists(_auctionId);
        hasBid(_auctionId);

        if (_paused == auctions[_auctionId].paused) {
            revert('auction paused state not updated');
        }
        if (_paused) {
            auctions[_auctionId].pausedTime = uint64(block.timestamp);
        } else if (
            !_paused && auctions[_auctionId].pausedTime > 0 && auctions[_auctionId].startTime > 0
        ) {
            if (auctions[_auctionId].currentBidder != address(0)) {
                // if the auction has started, increment duration by difference between current time and paused time
                // differentiate here between an auction that has started with a bid (increment time) vs an auction that has a start time in the future (do not increment time)
                auctions[_auctionId].settings.duration += uint32(
                    block.timestamp - auctions[_auctionId].pausedTime
                );
            }
            auctions[_auctionId].pausedTime = 0;
        }
        auctions[_auctionId].paused = _paused;
        emit AuctionPaused(
            _auctionId,
            auctions[_auctionId].tokenOwner,
            _msgSender(),
            _paused,
            auctions[_auctionId].settings.duration
        );
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev Per erc721 spec this interface must be implemented to receive NFTs via
     *      the safeTransferFrom function. See: https://eips.ethereum.org/EIPS/eip-721 for more.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external view override returns (bytes4) {
        return IERC721Receiver(address(this)).onERC721Received.selector;
    }

    /**
     * @dev utility function for calculating an auctions end time
     * @param _auctionId uint256
     */
    function _endTime(uint256 _auctionId) private view returns (uint256) {
        return auctions[_auctionId].startTime + auctions[_auctionId].settings.duration;
    }

    /**
     * @dev Delete auctionId for current auction for token+id & delete auction struct
     * @param _auctionId uint256
     */
    function _delete(uint256 _auctionId) private {
        // delete auctionId for current address+id token combo
        // only one auction at a time per token allowed
        delete auctionIds[auctions[_auctionId].nftAddress][auctions[_auctionId].tokenId];
        // Delete auction struct
        delete auctions[_auctionId];
    }

    /**
     * @dev Sending ether is not guaranteed complete, and the method used here will
     * escrow the value if it fails. For example, a contract can block transfer, or might use
     * an excessive amount of gas, thereby griefing a bidder.
     * We limit the gas used in transfers, and handle failure with escrowing.
     * @param _to address to transfer ETH to
     * @param _amount uint256 WEI amount to transfer
     */
    function _tryTransferThenEscrow(address _to, uint256 _amount) private {
        // increase the gas limit a reasonable amount above the default, and try
        // to send ether to the recipient.
        (bool success, ) = _to.call{ value: _amount, gas: 30000 }('');
        if (!success) {
            emit TransferFailed(_to, _amount);
            _asyncTransfer(_to, _amount);
        }
    }

    /**
     * @dev check if funds recipient is a contract. If it is, transfer ETH directly. If not, store in escrow on this contract.
     */
    function _sendFunds(address _to, uint256 _amount) private {
        // check if address is contract
        // see reference implementation at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L41
        if (_to.code.length > 0) {
            _tryTransferThenEscrow(_to, _amount);
        } else {
            _asyncTransfer(_to, _amount);
        }
    }

    function _msgSender()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IFirstDibsMarketSettingsV2 {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @author: manifold.xyz

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

library BidUtils {
    /**
     * @dev Retrieves the bid and buyer premium amount from the _amount based on _buyerPremiumRate
     *
     * @param _amount The entire amount (bid amount + buyer premium amount)
     * @param _buyerPremiumRate The buyer premium RBS used to calculate _amount
     * @return The bid sent and the premium sent
     */
    function _getSentBidAndPremium(uint256 _amount, uint64 _buyerPremiumRate)
        private
        pure
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        uint256 bpRate = _buyerPremiumRate + 10000;
        uint256 _sentBid = uint256((_amount * 10000) / bpRate);
        uint256 _sentPremium = uint256(_amount - _sentBid);
        return (_sentBid, _sentPremium);
    }

    /**
     * @dev Validates that the total amount sent is valid for the current state of the auction
     *  and returns the bid amount and buyer premium amount sent
     *
     * @param _totalAmount The total amount sent (bid amount + buyer premium amount)
     * @param _buyerPremium The current  buyer premium rate
     * @param _reservePrice The reserve price of the auction
     * @param _currentBidAmount The current bid to validate
     * @param _minimumBidIncrement The minimum bid increase threshold
     * @param _currentBidder The address of the highest bidder of the auction
     * @return boolean true if the amount satisfies the state of the auction; the sent bid; and the sent premium
     */
    function validateAndGetBid(
        uint256 _totalAmount,
        uint64 _buyerPremium,
        uint256 _reservePrice,
        uint256 _currentBidAmount,
        uint256 _minimumBidIncrement,
        address _currentBidder
    )
        internal
        pure
        returns (
            uint256, /*sentBid*/
            uint256 /*sentPremium*/
        )
    {
        (uint256 _sentBid, uint256 _sentPremium) = _getSentBidAndPremium(
            _totalAmount,
            _buyerPremium
        );
        if (_currentBidder == address(0)) {
            // This is the first bid against reserve price
            require(_sentBid >= _reservePrice, 'reserve not met');
        } else {
            // Subsequent bids must meet minimum bid increment
            require(
                _sentBid >= _currentBidAmount + (_currentBidAmount * _minimumBidIncrement) / 10000,
                'minimum bid not met'
            );
        }
        return (_sentBid, _sentPremium);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @dev Context variant with ERC2771 support.
 * copy/paste from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
 * but added a "setTrustedForwarder" function so we can deploy the forwarder contract after the token contract
 */
abstract contract FirstDibsERC2771Context is Context, Ownable {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 * @dev Interop with other systems supporting this interface
 * @notice Original license and source here: https://github.com/Pixura/pixura-contracts
 */
interface IERC721TokenCreatorV2 {
    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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