import "./AbsEnglishAuction.sol";
import "./AbsSignatureRestricted.sol";

contract RestrictedEnglishAuction is AbsEnglishAuction, AbsSignatureRestricted {
    bytes32 public constant AUCTION_CREATOR_ROLE = keccak256("AUCTION_CREATOR_ROLE");

    constructor(address wrappedNativeAsset) AbsEnglishAuction(wrappedNativeAsset) AbsSignatureRestricted(msg.sender) {
        _grantRole(AUCTION_CREATOR_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @notice Create an English auction, restricted to AUCTION_CREATOR_ROLE
     * @param tokenId uint256 Token ID of the NFT to auction
     * @param tokenContract address Address of the NFT token contract
     * @param tokenType TokenType Either ERC721 or ERC1155
     * @param duration uint256 Length of the auction in seconds
     * @param startTime uint256 Start time of the auction in seconds
     * @param startingBid uint256 Minimum initial bid for the auction
     * @param paymentCurrency address Contract address of the token used to bid and pay with
     * @param extensionWindow uint256 Window where there must be no bids before auction ends, in seconds
     * @param minBidIncrementBps uint256 Each bid must be at least this % higher than the previous one
     * @param feeRecipients address[] Addresses of fee recipients
     * @param feePercentages uint32[] Percentages of winning bid paid to fee recipients, in basis points
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        TokenType tokenType,
        uint256 duration,
        uint256 startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] memory feeRecipients,
        uint32[] memory feePercentages
    ) public onlyRole(AUCTION_CREATOR_ROLE) {
        super._createAuction(
            tokenId,
            tokenContract,
            tokenType,
            duration,
            startTime,
            startingBid,
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );
    }

    /**
     * @notice Place bid on a running auction with an ERC20 token with SIGNER restriction
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     * @param expiresAt uint256 Timestamp until which singature is value
     * @param v uint8 Signature of input params with SIGNERs key
     * @param r bytes32  Signature of input params with SIGNERs key
     * @param s bytes32 Signature of input params with SIGNERs key
     */
    function placeBid(
        uint256 auctionId,
        uint256 bidAmount,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        verifySignedData(abi.encodePacked(auctionId, bidAmount), expiresAt, v, r, s);
        super._placeBid(auctionId, bidAmount);
    }

    /**
     * @notice Place bid on a running auction in the native currency with SIGNER restriction
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     * @param expiresAt uint256 Timestamp until which singature is value
     * @param v uint8 Signature of input params with SIGNERs key
     * @param r bytes32  Signature of input params with SIGNERs key
     * @param s bytes32 Signature of input params with SIGNERs key
     */
    function placeBidInEth(
        uint256 auctionId,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        verifySignedData(abi.encodePacked(auctionId), expiresAt, v, r, s);
        super._placeBidInEth(auctionId);
    }
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./mixins/WrappedNativeHelpers.sol";

/**
 * ERC20 based English auction contract for ERC721 and ERC1155 tokens.
 * - NFTs being auctioned are held in escrow, by this contract.
 * - All bids are held in escrow, by this contract.
 * - All bids placed for an auction are binding and cannot be rescinded.
 * - On being outbid, the previous winning bidder will be sent back their bid amount.
 * - Auctions in the wrapped native currency (WETH) can accept bids in the native currency, but on being outbid will be returned in WETH.
 * - On successful auctions, NFT is transfered to the buyer and all the funds are transferred to the auction fee recipients.
 * - Auctions can have multiple fee recipients with % allocations.
 * - There is no reserve price on auctions, rather a startingBid.
 */
abstract contract AbsEnglishAuction is ERC721Holder, ERC1155Holder, ReentrancyGuard, WrappedNativeHelpers {
    using SafeERC20 for IERC20;

    enum TokenType { ERC721, ERC1155 }

    struct Auction {
        uint256 tokenId;
        address tokenContract;
        TokenType tokenType;
        uint256 winningBidAmount;
        uint256 duration;
        uint256 startTime;
        uint256 startingBid;
        address seller;
        address winningBidder;
        address paymentCurrency;
        uint256 extensionWindow;
        uint256 minBidIncrementBps;
        address[] feeRecipients;
        uint32[] feePercentages;
    }

    struct AuctionState {
        uint256 auctionEnd;
        uint256 previousBidAmount;
        address previousBidder;
    }

    struct SettlementState {
        bool tokenTransferred;
        bool paymentTransferred;
    }

    // auction id => auction.  deleted once an auction is successfully settled.
    mapping(uint256 => Auction) private auctionIdToAuction;

    // auction id => settlement state.  lives forever.
    mapping(uint256 => SettlementState) private auctionSettlementState;

    // start at one to avoid bad truthy checks
    uint256 private nextAuctionId = 1;

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 indexed startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, bool extended);

    event AuctionSettled(uint256 indexed auctionId, address indexed seller, address indexed buyer);
    event AuctionCancelled(uint256 indexed auctionId);

    /**
     * Create a new auction contract with an optional ERC20 address for native currency (WETH).
     * Auctions created with the currency wrappedNativeAssetAddress will allow bids in either
     * the wrapped or native versions.  Passing the zero address will prevent bids in native currency.
     */
    constructor(address wrappedNativeAssetAddress) {
        if (wrappedNativeAssetAddress != address(0)) {
            _setWrappedAddress(wrappedNativeAssetAddress);
        }
    }

    /**
     * @notice Create an English auction
     * @param tokenId uint256 Token ID of the NFT to auction
     * @param tokenContract address Address of the NFT token contract
     * @param tokenType TokenType Either ERC721 or ERC1155
     * @param duration uint256 Length of the auction in seconds
     * @param startTime uint256 Start time of the auction in seconds
     * @param startingBid uint256 Minimum initial bid for the auction
     * @param paymentCurrency address Contract address of the token used to bid and pay with
     * @param extensionWindow uint256 Window where there must be no bids before auction ends, in seconds
     * @param minBidIncrementBps uint256 Each bid must be at least this % higher than the previous one
     * @param feeRecipients address[] Addresses of fee recipients
     * @param feePercentages uint32[] Percentages of winning bid paid to fee recipients, in basis points
     */
    function _createAuction(
        uint256 tokenId,
        address tokenContract,
        TokenType tokenType,
        uint256 duration,
        uint256 startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] memory feeRecipients,
        uint32[] memory feePercentages
    ) internal {
        // Validate Auction config
        require(startTime < 10000000000, "enter an unix timestamp in seconds, not miliseconds");
        require(duration > 0, "invalid duration");
        require(startTime + duration >= block.timestamp, "start time + duration is before current time");
        require(startingBid > 0, "minimum starting bid not met");

        // Check fee lengths
        require(feeRecipients.length > 0, "at least 1 fee recipient is required");
        require(feeRecipients.length == feePercentages.length, "mismatched fee recipients and percentages");
        for (uint256 i = 0; i < feePercentages.length; i++) {
            require(feePercentages[i] > 0, "fee percentages cannot be zero");
        }

        uint256 auctionId = nextAuctionId;
        nextAuctionId += 1;

        // Check fee percentages add up to 100% (10000 basis points), use scope to limit variables
        {
            uint32 totalPercent;
            for (uint256 i = 0; i < feePercentages.length; i++) {
                totalPercent = totalPercent + feePercentages[i];
            }
            require(totalPercent == 10000, "fee percentages do not add up to 10000 basis points");
        }

        require(paymentCurrency != address(0), "must provide valid erc20 address");

        require(minBidIncrementBps <= 10000, "min bid increment % must be less or equal to 10000");

        auctionIdToAuction[auctionId] = Auction(
            tokenId,
            tokenContract,
            tokenType,
            0, // no bids yet so no winningBidAmount
            duration,
            startTime,
            startingBid,
            msg.sender,
            address(0), // no bids so no winningBidder
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );

        emit AuctionCreated(
            auctionId,
            msg.sender,
            tokenId,
            tokenContract,
            duration,
            startTime,
            startingBid,
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );

        transferNFT(msg.sender, address(this), tokenId, 1, tokenContract, tokenType);
    }

    /**
     * @notice Place bid on a running auction with an ERC20 token, internal. Caller should perform nonReentrant check
     * @dev msg.value is bid amount when paying in ETH
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     */
    function _placeBid(uint256 auctionId, uint256 bidAmount) internal {
        requireValidAuction(auctionId);
        Auction storage auction = auctionIdToAuction[auctionId];

        (AuctionState memory auctionState, bool extended) = beforeBidPaymentTransfer(auction, bidAmount);

        // bid funds start in contract until auction over or outbid
        transferPayment(msg.sender, address(this), bidAmount, auction.paymentCurrency);

        afterBidPaymentTransfer(auctionState, bidAmount, extended, auctionId, auction.paymentCurrency);
    }

    /**
     * @notice Place bid on a running auction in the native currency. Caller should perform nonReentrant check
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     */
    function _placeBidInEth(uint256 auctionId) internal {
        requireValidAuction(auctionId);
        Auction storage auction = auctionIdToAuction[auctionId];
        require(auction.paymentCurrency == wrappedAddress, "Auction not in wrapped native currency");

        (AuctionState memory auctionState, bool extended) = beforeBidPaymentTransfer(auction, msg.value);

        // attempt to wrap native currency -> WETH
        wrap(msg.value);

        afterBidPaymentTransfer(auctionState, msg.value, extended, auctionId, auction.paymentCurrency);
    }

    /**
     * @notice Settle an auction to send NFT and tokens to correct parties. Anybody can call it.  This
     * is the normal flow that should be used after an auction is complete.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuction(uint256 auctionId) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");

        SettlementState storage settlementState = auctionSettlementState[auctionId];

        delete auctionIdToAuction[auctionId];

        emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);

        // no bidders
        if (auction.winningBidder == address(0)) {
            // transfer NFT to seller
            settlementState.paymentTransferred = true;
            if (!settlementState.tokenTransferred) {
                settlementState.tokenTransferred = true;

                transferNFT(
                    address(this),
                    auction.seller,
                    auction.tokenId,
                    1,
                    auction.tokenContract,
                    auction.tokenType
                );
            }
        } else {
            // transfer NFT to bidder, if not already done
            if (!settlementState.tokenTransferred) {
                settlementState.tokenTransferred = true;

                transferNFT(
                    address(this),
                    auction.winningBidder,
                    auction.tokenId,
                    1,
                    auction.tokenContract,
                    auction.tokenType
                );
            }

            if (!settlementState.paymentTransferred) {
                // transfer fees to fee recipients
                settlementState.paymentTransferred = true;
                transferAuctionPayment(auction);
            }
        }
    }

    /**
     * @notice Alternative way to settle the NFT side of an auction.  Only the winner can call this
     * function, and allows the winner to specify the address to transfer to.  This should only be used
     * if for some reason the settleAuction call fails.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuctionNftToAddress(uint256 auctionId, address alternateAddress) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");
        require(auction.winningBidder != address(0), "no winning bidder");
        require(auction.winningBidder == msg.sender, "only winner");

        SettlementState storage settlementState = auctionSettlementState[auctionId];
        require(!settlementState.tokenTransferred, "NFT already transferred");

        bool fullySettled = false;
        if (settlementState.paymentTransferred) {
            // if payment has been transferred, and we're now transferring the token, the auction is
            // done, delete it
            fullySettled = true;
            delete auctionIdToAuction[auctionId];
        }

        settlementState.tokenTransferred = true;
        if (fullySettled) {
            emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);
        }

        transferNFT(address(this), alternateAddress, auction.tokenId, 1, auction.tokenContract, auction.tokenType);
    }

    /**
     * @notice Alternative way to settle the payment side of an auction.  Only the seller can call this
     * function.  If for some reason the NFT cannot be transferred to the winning bidder and the settleAuction
     * call reverts, this will still allow the seller to get the payment.
     * @param auctionId uint256 Id of the auction to settle.
     */
    function settleAuctionPayment(uint256 auctionId) external nonReentrant {
        Auction memory auction = getAuction(auctionId);
        require(isAuctionComplete(auctionId), "auction still in progess");
        require(auction.winningBidder != address(0), "no winning bidder");
        require(auction.seller == msg.sender, "only seller");

        SettlementState storage settlementState = auctionSettlementState[auctionId];
        require(!settlementState.paymentTransferred, "Payment already transferred");

        bool fullySettled = false;
        if (settlementState.tokenTransferred) {
            // if payment has been transferred, and we're now transferring the token, the auction is
            // done, delete it
            fullySettled = true;
            delete auctionIdToAuction[auctionId];
        }

        settlementState.paymentTransferred = true;
        if (fullySettled) {
            emit AuctionSettled(auctionId, auction.seller, auction.winningBidder);
        }

        transferAuctionPayment(auction);
    }

    function isAuctionSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.tokenTransferred && settlementState.paymentTransferred;
    }

    function isAuctionPaymentSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.paymentTransferred;
    }

    function isAuctionNftSettled(uint256 auctionId) external view returns (bool) {
        SettlementState storage settlementState = auctionSettlementState[auctionId];
        return settlementState.tokenTransferred;
    }

    /**
     * @notice Cancel auction
     * @dev cannot cancel if auction has started and there are existing bids
     * @param auctionId uint256 Id of the auction the get details for
     */
    function cancelAuction(uint256 auctionId) external {
        Auction memory auction = getAuction(auctionId);
        // this also should cover if auction does not exist
        require(msg.sender == auction.seller, "only seller can cancel auction");
        require(auction.winningBidder == address(0), "cannot cancel auction has bidders");

        delete auctionIdToAuction[auctionId];

        emit AuctionCancelled(auctionId);

        // transfer NFT to seller
        transferNFT(address(this), auction.seller, auction.tokenId, 1, auction.tokenContract, auction.tokenType);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId uint256 Id of the auction the get details for
     */
    function getAuction(uint256 auctionId) public view returns (Auction memory) {
        requireValidAuction(auctionId);
        return auctionIdToAuction[auctionId];
    }

    //////////////////////////
    // INTERNAL FUNCTIONS   //
    //////////////////////////
    function checkBidIsValid(Auction storage auction, uint256 bidAmount) internal view returns (AuctionState memory) {
        uint256 auctionEnd = auction.startTime + auction.duration;
        address previousBidder = auction.winningBidder;
        uint256 previousBidAmount = auction.winningBidAmount;

        require(auction.seller != address(0), "auction does not exist");
        require(auction.startTime <= block.timestamp, "auction not started yet");
        require(auctionEnd > block.timestamp, "auction has ended");
        require(bidAmount >= auction.startingBid, "starting bid not met");
        require(previousBidder != msg.sender, " cannot outbid yourself");

        // not first bid
        if (auction.winningBidAmount != 0) {
            require(
                bidAmount >= previousBidAmount + (previousBidAmount * auction.minBidIncrementBps) / 10000,
                "invalid bid"
            );
        }

        return AuctionState(auctionEnd, previousBidAmount, previousBidder);
    }

    function extendAuctionIfWithinWindow(uint256 auctionEnd, Auction storage auction) internal returns (bool) {
        uint256 timeRemaining = auctionEnd - block.timestamp;

        if (timeRemaining < auction.extensionWindow) {
            // extension is from current time
            // auctionEnd = block.timestamp + auction.extensionWindow;
            // auctionEnd = auction.startTime + auction.duration
            // >  auction.startTime + auction.duration = block.timestamp + auction.extensionWindow;
            // >  auction.duration = block.timestamp + auction.extensionWindow - auction.startTime;
            auction.duration = block.timestamp + auction.extensionWindow - auction.startTime;
            return true;
        }
        return false;
    }

    /**
     * Should be called prior to attempting to transfer the bid payment to the contract.  This
     * will do validation on the bid amount and extend the auction if required.
     */
    function beforeBidPaymentTransfer(Auction storage auction, uint256 bidAmount)
        internal
        returns (AuctionState memory auctionState, bool extended)
    {
        auctionState = checkBidIsValid(auction, bidAmount);
        auction.winningBidAmount = bidAmount;
        auction.winningBidder = msg.sender;
        extended = extendAuctionIfWithinWindow(auctionState.auctionEnd, auction);
        return (auctionState, extended);
    }

    /**
     * Should be called after transfering bid payment to the contract.  This will refund
     * the previous bidder (if there was one), and emit the BidPlaced event.
     */
    function afterBidPaymentTransfer(
        AuctionState memory auctionState,
        uint256 bidAmount,
        bool extended,
        uint256 auctionId,
        address paymentCurrency
    ) internal {
        emit BidPlaced(auctionId, msg.sender, bidAmount, extended);

        if (auctionState.previousBidAmount != 0) {
            transferPayment(
                address(this),
                auctionState.previousBidder,
                auctionState.previousBidAmount,
                paymentCurrency
            );
        }
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments).
     */
    function getPortionOfBid(uint256 totalBid, uint256 percentageBips) private pure returns (uint256) {
        return (totalBid * (percentageBips)) / 10000;
    }

    function requireValidAuction(uint256 auctionId) private view {
        require(auctionIdToAuction[auctionId].seller != address(0), "auction does not exist");
    }

    /**
     * Transfer the winning bid for an auction to the fee recipients.
     */
    function transferAuctionPayment(Auction memory auction) private {
        for (uint256 i = 0; i < auction.feeRecipients.length; i++) {
            uint256 fee = getPortionOfBid(auction.winningBidAmount, auction.feePercentages[i]);
            if (fee > 0) {
                transferPayment(address(this), payable(auction.feeRecipients[i]), fee, auction.paymentCurrency);
            }
        }
    }

    function transferNFT(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        address token,
        TokenType tokenType
    ) internal {
        if (tokenType == TokenType.ERC1155) {
            IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
        } else {
            IERC721(token).safeTransferFrom(from, to, tokenId, "");
        }
    }

    function transferPayment(
        address from,
        address to,
        uint256 amount,
        address token
    ) internal {
        if (from == address(this)) {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
        }
    }

    function getAuctionEndTime(uint256 auctionId) public view returns (uint256) {
        Auction memory auction = getAuction(auctionId);
        return auction.startTime + auction.duration;
    }

    function isAuctionComplete(uint256 auctionId) public view returns (bool) {
        return block.timestamp > getAuctionEndTime(auctionId);
    }
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWRAPPED {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

// this contract can be used in L2s. Wrapped on mainnet eth is WETH, on polygon is WMATIC
abstract contract WrappedNativeHelpers {
    using SafeERC20 for IERC20;
    address public wrappedAddress;

    function sendValueIfFailsSendWrapped(address payable user, uint256 amount) internal {
        require(amount > 0, "cannot send 0");

        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: 60000 }("");
        if (!success) {
            // Send WETH instead
            wrap(amount);
            safeTransferWrappedTo(user, amount);
        }
    }

    function _setWrappedAddress(address wrappedNativeAssetAddress) internal {
        require(wrappedNativeAssetAddress != address(0), "zero address");
        wrappedAddress = wrappedNativeAssetAddress;
    }

    function safeTransferWrappedTo(address user, uint256 amount) internal {
        IERC20(wrappedAddress).safeTransferFrom(address(this), user, amount);
    }

    function unwrap(uint256 amount) internal {
        IWRAPPED(wrappedAddress).withdraw(amount);
    }

    function wrap(uint256 amount) internal {
        IWRAPPED(wrappedAddress).deposit{ value: amount }();
    }
}

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AbsSignatureRestricted is AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    constructor(address _initialSigner) {
        _grantRole(SIGNER_ROLE, _initialSigner);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function hashCalldata(
        bytes memory data,
        uint256 expiresAt,
        uint256 value,
        address sender
    ) public pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(data, expiresAt, value, sender)));
    }

    function verifySignedData(
        bytes memory data,
        uint256 expiresAt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        require(expiresAt > block.timestamp, "Expired timestamp");

        address recoveredSigner = ecrecover(hashCalldata(data, expiresAt, msg.value, msg.sender), v, r, s);

        require(recoveredSigner != address(0), "Invalid signature");
        require(hasRole(SIGNER_ROLE, recoveredSigner), "Invalid signature");
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./mixins/EthBalanceMixin.sol";
import "./mixins/WrappedNativeHelpers.sol";
import "./IExchange.sol";

contract TreumExchange is IExchange, Ownable, EIP712, ReentrancyGuard, TreumOrder, WrappedNativeHelpers {
    using SafeERC20 for IERC20;

    // order hash => isCanceled boolean
    mapping(bytes32 => bool) public canceledOrders;
    // order hash => filled amount
    // considered complete when filled amount is more than taker amount in order
    mapping(bytes32 => uint256) public filledAmount;

    //  maker address => nonce
    mapping(address => uint256) public invalidNonces;

    event CancelAllBefore(uint256 indexed nonce, address indexed makerAddress);

    constructor() EIP712("exchange.treum.io", "1.0.0") {}

    //////////////////////////
    // PUBLIC FUNCTIONS     //
    //////////////////////////
    /**
     * @notice Fills the signed input order
     * @dev Only ASK orders can be partially filled
     * @param fillAmount uint256 the amount of the order the taker will fill
     * @param order Order Order to be filled
     * @param signature bytes Signature for the order
     */
    function fill(
        uint256 fillAmount,
        Order calldata order,
        bytes memory signature
    ) external override nonReentrant {
        require(fillAmount > 0, "CANNOT_FILL_ZERO");

        bytes32 orderHash = getTypedDataHash(order);
        checkOrderIsValid(order, orderHash, signature);
        checkOrderIsFillable(fillAmount, order, orderHash);

        // should be filled by an authorized taker
        address taker = getTaker(order);

        updateFilledAmount(fillAmount, orderHash);

        OrderType orderType = getOrderType(order);
        _fill(order, fillAmount, signature, taker);
    }

    // TODO: add emergency withdraw method to withdraw weth
    /**
     * @notice Converts ETH to WETH before filling signed order
     * @param order Order Order to be filled
     * @param signature bytes Signature for the order
     */
    function fillWithNativeAsset(
        uint256 fillAmount,
        Order calldata order,
        bytes memory signature
    ) external payable override nonReentrant {
        require(fillAmount > 0, "CANNOT_FILL_ZERO");
        require(wrappedAddress != address(0), "WRAPPED_ADDRESS_NOT_SET");
        require(order.takerToken.token == wrappedAddress, "TAKER_TOKEN_NOT_WETH");

        uint256 totalCost = order.takerToken.amount * fillAmount;
        require(msg.value == totalCost, "INSUFFICIENT_FUNDS");

        wrap(msg.value);

        {
            bytes32 orderHash = getTypedDataHash(order);
            checkOrderIsValid(order, orderHash, signature);
            checkOrderIsFillable(fillAmount, order, orderHash);

            updateFilledAmount(fillAmount, orderHash);
        }

        // Taker payouts paid from this contracts WETH balance
        if (order.payoutAmount.length > 0) {
            distributePayouts(fillAmount, address(this), order.payoutTo, order.payoutAmount, order.takerToken);
        } else {
            transferERC20(address(this), order.makerAddress, order.takerToken.token, totalCost);
        }

        // validate taker is authorized
        address taker = getTaker(order);
        // NFT transfer from maker -> taker
        transferNFT(order.makerAddress, taker, fillAmount, order.makerToken);

        emit Fill(
            order.nonce,
            taker,
            order.takerToken.amount,
            order.takerToken.id,
            order.takerToken.token,
            order.makerAddress,
            order.makerToken.amount,
            order.makerToken.id,
            order.makerToken.token,
            msg.sender,
            fillAmount
        );
    }

    /**
     * @notice Third-party fills the input order with signatures from taker and maker
     * @dev cannot partial fill
     * @param order Order Order to be filled
     * @param makerSignature bytes MakerSignature for the order
     * @param takerSignature bytes TakerSignature for the order
     */
    function fillFor(
        Order calldata order,
        bytes memory makerSignature,
        bytes memory takerSignature
    ) external nonReentrant {
        bytes32 orderHash = getTypedDataHash(order);

        // this will verify order is valid and signed by maker
        checkOrderIsValid(order, orderHash, makerSignature);
        // taker will be recovered from signature
        address taker = getTaker(order, orderHash, takerSignature);
        // fully fill the order so fill amount is the entire order.makerToken.amount
        checkOrderIsFillable(order.makerToken.amount, order, orderHash);

        updateFilledAmount(order.makerToken.amount, orderHash);
        _fill(order, order.makerToken.amount, makerSignature, taker);
    }

    /**
     * @notice Cancel the order
     * @dev Must be from the maker
     * @param order Order Order to be cancelled
     */
    function cancel(Order calldata order) external override {
        // check sender is the maker of the order
        require(msg.sender == order.makerAddress, "NOT_AUTHORIZED");

        bytes32 orderHash = getTypedDataHash(order);

        // cannot cancel an already completed order
        require(!canceledOrders[orderHash], "ORDER_CANCELLED");
        require(!isFilledOrder(order, orderHash), "ORDER_FILLED");

        // set complete
        canceledOrders[orderHash] = true;

        // emit event
        emit Cancel(orderHash, msg.sender);
    }

    /**
     * @notice Cancel all orders from maker with nonce prior to this
     * @dev Must be from the maker
     * @param nonce uint256
     */
    function cancelAllBefore(uint256 nonce) external {
        uint256 oldNonce = invalidNonces[msg.sender];
        // must be after currently set nonce
        require(nonce > oldNonce, "INVALID_NONCE");

        invalidNonces[msg.sender] = nonce;
        emit CancelAllBefore(nonce, msg.sender);
    }

    /**
     * @notice Fills the signed input order
     * @param order Order Order to be hashed
     * @return bytes32 The hash of the order
     */
    function getTypedDataHash(Order calldata order) public view returns (bytes32) {
        return _hashTypedDataV4(hash(order));
    }

    //////////////////////////
    // INTERNAL FUNCTIONS   //
    //////////////////////////
    // do any checks to make sure taker address is correct in calling function
    // do any checks to make sure order type is valid in calling function
    function _fill(
        Order calldata order,
        uint256 fillAmount,
        bytes memory signature,
        address taker
    ) internal {
        require(fillAmount > 0, "CANNOT_FILL_ZERO");

        OrderType orderType = getOrderType(order);

        if (orderType == OrderType.ASK) {
            settleAskOrder(fillAmount, order, taker);
        } else if (orderType == OrderType.BID) {
            settleBidOrder(fillAmount, order, taker);
        } else {
            settleSwap(order, taker);
        }

        emit Fill(
            order.nonce,
            taker,
            order.takerToken.amount,
            order.takerToken.id,
            order.takerToken.token,
            order.makerAddress,
            order.makerToken.amount,
            order.makerToken.id,
            order.makerToken.token,
            msg.sender,
            fillAmount
        );
    }

    function checkOrderIsValid(
        Order calldata order,
        bytes32 orderHash,
        bytes memory makerSignature
    ) internal view {
        // should be signed by the maker
        require(
            SignatureChecker.isValidSignatureNow(order.makerAddress, orderHash, makerSignature),
            "INVALID_SIGNATURE"
        );
        // should not be expired
        require(order.expiry > block.timestamp, "ORDER_EXPIRED");
        // should not be canceled or filled already
        require(!canceledOrders[orderHash], "ORDER_CANCELLED");
        // should not be a stale order
        require(order.nonce > invalidNonces[order.makerAddress], "ORDER_CANCELLED");
    }

    function isFilledOrder(Order calldata order, bytes32 orderHash) internal view returns (bool) {
        return filledAmount[orderHash] >= order.makerToken.amount;
    }

    function checkOrderIsFillable(
        uint256 fillAmount,
        Order calldata order,
        bytes32 orderHash
    ) internal view returns (bool) {
        require(!isFilledOrder(order, orderHash), "ORDER_FILLED");
        require(filledAmount[orderHash] + fillAmount <= order.makerToken.amount, "NOT_ENOUGH_SUPPLY");
    }

    function getTaker(Order calldata order) internal view returns (address) {
        if (order.takerAddress == address(0)) {
            return msg.sender;
        } else {
            require(order.takerAddress == msg.sender, "TAKER_UNAUTHORIZED");
            return order.takerAddress;
        }
    }

    function getTaker(
        Order calldata order,
        bytes32 orderHash,
        bytes memory takerSignature
    ) internal view returns (address taker) {
        if (order.takerAddress == address(0)) {
            // taker is address that signed the order
            // note: will not work with ERC1271
            taker = ECDSA.recover(orderHash, takerSignature);
            require(taker != order.makerAddress, "MAKER_IS_TAKER");
        } else {
            taker = order.takerAddress;
            // should be signed by the taker
            require(SignatureChecker.isValidSignatureNow(taker, orderHash, takerSignature), "INVALID_SIGNATURE");
        }
    }

    function updateFilledAmount(uint256 fillAmount, bytes32 orderHash) internal {
        filledAmount[orderHash] += fillAmount;
    }

    function settleAskOrder(
        uint256 fillAmount,
        Order calldata order,
        address taker
    ) internal {
        if (order.payoutAmount.length > 0) {
            // taker pays payouts
            distributePayouts(fillAmount, taker, order.payoutTo, order.payoutAmount, order.takerToken);
        } else {
            // transfer from taker pays direct to maker
            uint256 totalCost = order.takerToken.amount * fillAmount;
            transferERC20(taker, order.makerAddress, order.takerToken.token, totalCost);
        }

        // NFT transfer from maker -> taker
        transferNFT(order.makerAddress, taker, fillAmount, order.makerToken);
    }

    function settleBidOrder(
        uint256 fillAmount,
        Order calldata order,
        address taker
    ) internal {
        require(fillAmount == order.makerToken.amount, "CANNOT_PARTIAL_FILL_BID");

        if (order.payoutAmount.length > 0) {
            // maker pays payouts
            distributePayouts(fillAmount, order.makerAddress, order.payoutTo, order.payoutAmount, order.makerToken);
        } else {
            // transfer from maker pays direct to taker
            transferERC20(order.makerAddress, taker, order.makerToken.token, fillAmount);
        }

        // NFT transfer from taker -> maker
        transferNFT(taker, order.makerAddress, order.takerToken);
    }

    function settleSwap(Order calldata order, address taker) internal {
        // transfer from maker to taker
        transferNFT(order.makerAddress, taker, order.makerToken);
        // transfer from taker to maker
        transferNFT(taker, order.makerAddress, order.takerToken);
    }

    function transferNFT(
        address from,
        address to,
        uint256 amount,
        Token memory token
    ) internal {
        require(to != address(0), "TRANSFER_TO_ZERO_ADDRESS");

        if (token.kind == TokenType.ERC1155) {
            transferERC1155(from, to, token.token, amount, token.id);
        } else if (token.kind == TokenType.ERC721) {
            transferERC721(from, to, token.token, token.id);
        } else {
            revert("UNSUPPORTED_TOKEN_TYPE");
        }
    }

    function transferNFT(
        address from,
        address to,
        Token memory token
    ) internal {
        transferNFT(from, to, token.amount, token);
    }

    function transferERC20(
        address from,
        address to,
        address tokenAddress,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(tokenAddress != address(0), "INVALID_TOKEN");
        IERC20(tokenAddress).transferFrom(from, to, amount);
    }

    function transferERC1155(
        address from,
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 tokenId
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "");
    }

    // TODO: restrict free NFTs or free ERC20?
    function transferERC721(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId
    ) internal {
        IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, "");
    }

    ////////////////////////////////////
    // ROYALTIES AND FEES (PAYOUTS)   //
    ////////////////////////////////////
    function distributePayouts(
        uint256 fillAmount,
        address from,
        address[] memory to,
        uint256[] memory amount,
        Token memory token
    ) internal {
        require(to.length == amount.length, "MISMATCHED_PAYOUT");
        uint256 portionPaid = 0;

        for (uint256 i = 0; i < to.length; ++i) {
            portionPaid += amount[i];
            transferERC20(from, to[i], token.token, amount[i] * fillAmount);
        }

        require(portionPaid == token.amount, "INCOMPLETE_PAYOUT");
        emit Payout(from, to, fillAmount, token.token, amount, block.timestamp);
    }

    //////////////////////////
    // ADMIN FUNCTIONS      //
    //////////////////////////
    function setWrappedAddress(address weth) external onlyOwner {
        _setWrappedAddress(weth);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract EthBalanceMixin {
    mapping(address => uint256) private ethBalance;

    event Deposit(address indexed from, uint256 weiAmount);
    event Withdraw(address indexed to, uint256 weiAmount);

    /**
     * @notice Deposit ETH
     */
    function deposit() public payable virtual {
        uint256 amount = msg.value;
        _deposit(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function _deposit(address recipient, uint256 amount) internal {
        require(amount > 0, "ZERO_DEPOSIT");
        ethBalance[recipient] += amount;
    }

    function _depositWeights(
        address[] memory recipients,
        uint32[] memory weights,
        uint256 totalWeight,
        uint256 amount
    ) internal {
        // Verify that input arrays are correct length
        require(recipients.length == weights.length, "Invalid input length");

        // Adds up the weight
        uint256 expectedWeight;

        // Variable for current weight
        uint256 weight;

        // Variable for current deposit amount
        uint256 depositAmount;

        // Tracks amount left to be deposited to handle rounding errors
        uint256 remainderAmount = amount;

        for (uint256 i = 0; i < recipients.length; i++) {
            weight = uint256(weights[i]);

            expectedWeight += weight;

            // give last recipient the remainder to avoid rounding errors
            if (i == recipients.length - 1) {
                _deposit(recipients[i], remainderAmount);
            } else {
                depositAmount = (amount * weight) / totalWeight;
                _deposit(recipients[i], depositAmount);
                remainderAmount -= depositAmount;
            }
        }

        require(expectedWeight == totalWeight, "Invalid weights");
    }

    /**
     * @notice Withdraw unspent ETH that was previously deposited
     */
    function withdraw() external virtual {
        uint256 amount = ethBalance[msg.sender];
        require(amount > 0, "ZERO_BALANCE");
        ethBalance[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount);
    }

    // Warning: this does not send the ETH. Enables sending ETH from account, to another account
    function _subtractEthBalance(address account, uint256 amount) internal {
        require(ethBalance[account] >= amount, "INSUFFICIENT_FUNDS");
        ethBalance[account] -= amount;
    }

    function ethBalanceOf(address account) public view virtual returns (uint256) {
        return ethBalance[account];
    }
}

pragma solidity ^0.8.0;
import "./TreumOrder.sol";

interface IExchange {
    event Fill(
        uint256 indexed nonce,
        address indexed taker,
        uint256 takerAmount,
        uint256 takerTokenId,
        address takerToken,
        address indexed maker,
        uint256 makerAmount,
        uint256 makerId,
        address makerToken,
        address senderAddress,
        uint256 fillAmount
    );

    event Payout(
        address indexed from,
        address[] to,
        uint256 fillAmount,
        address indexed token,
        uint256[] amount,
        uint256 timestamp
    );

    event Cancel(bytes32 indexed orderHash, address indexed makerAddress);

    /**
     * @notice Exchange NFTs and ERC20 tokens
     * @param order Types.Order
     * @param signature bytes
     */
    function fill(
        uint256 fillAmount,
        TreumOrder.Order calldata order,
        bytes memory signature
    ) external;

    /**
     * @notice Exchange NFTs and Native asset (wrap to ERC20)
     * @param order Types.Order
     * @param signature bytes
     */
    function fillWithNativeAsset(
        uint256 fillAmount,
        TreumOrder.Order calldata order,
        bytes memory signature
    ) external payable;

    /**
     * @notice Cancel order - only by maker
     * @param order Types.Order
     */
    function cancel(TreumOrder.Order calldata order) external;
}

pragma solidity ^0.8.0;

contract TreumOrder {
    enum TokenType { ERC721, ERC1155, ERC20 }
    // ASK == NFT is maker asset, BID == NFT is taker asset, Swap == NFT is taker and maker asset
    enum OrderType { ASK, BID, SWAP }

    struct Order {
        uint256 expiry; // Timestamp in seconds at which order expires.
        uint256 nonce; // nonce used to facilitate uniqueness of the order's hash and allow for bulk cancels
        address makerAddress; // Order creator - needs to sign the order
        address takerAddress; // if set, then only this address can fill the order
        Token makerToken; // Token info for maker side
        Token takerToken; // Token info for taker side
        address[] payoutTo; // Address to send other funds that need to be distributed (fees, royalties)
        uint256[] payoutAmount; // Amounts to send other funds that need to be distributed (fees, royalties)
    }

    struct Token {
        TokenType kind;
        address token;
        uint256 id;
        uint256 amount;
    }

    bytes32 internal constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(uint256 expiry,uint256 nonce,address makerAddress,address takerAddress,Token makerToken,Token takerToken,address[] payoutTo,uint256[] payoutAmount)Token(uint8 kind,address token,uint256 id,uint256 amount)"
            )
        );
    bytes32 internal constant TOKEN_TYPEHASH =
        keccak256(abi.encodePacked("Token(uint8 kind,address token,uint256 id,uint256 amount)"));

    function hash(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.expiry,
                    order.nonce,
                    order.makerAddress,
                    order.takerAddress,
                    hash(order.makerToken),
                    hash(order.takerToken),
                    keccak256(abi.encodePacked(order.payoutTo)),
                    keccak256(abi.encodePacked(order.payoutAmount))
                )
            );
    }

    function hash(Token memory token) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_TYPEHASH, token.kind, token.token, token.id, token.amount));
    }

    function getOrderType(Order memory order) public pure returns (OrderType) {
        TokenType makerAsset = order.makerToken.kind;
        TokenType takerAsset = order.takerToken.kind;

        bool makerAssetIsNFT = makerAsset == TokenType.ERC1155 || makerAsset == TokenType.ERC721;
        bool takerAssetIsNFT = takerAsset == TokenType.ERC1155 || takerAsset == TokenType.ERC721;

        if (makerAssetIsNFT) {
            if (takerAssetIsNFT) {
                return OrderType.SWAP;
            }
            return OrderType.ASK;
        } else if (takerAssetIsNFT) {
            return OrderType.BID;
        } else {
            revert("UNSUPPORTED_TRADE_TYPE");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Abstract, as without permission system
abstract contract AbsERC1155 is ERC1155 {
    string public baseURI;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public currentSupply;

    constructor(string memory baseURIParam) ERC1155("") {
        _setBaseURI(baseURIParam);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(isCreated(tokenId), "BaseERC1155: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    // be careful when overriding as this is used in the _create function
    function isCreated(uint256 tokenId) public view virtual returns (bool) {
        return maxSupply[tokenId] != 0;
    }

    // Internal function to create a token
    function _create(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply_
    ) internal {
        require(maxSupply_ != 0, "BaseERC1155: maxSupply cannot be 0");
        require(!isCreated(tokenId), "BaseERC1155: token already created");
        require(initialSupply <= maxSupply_, "BaseERC1155: initial supply cannot exceed max");
        maxSupply[tokenId] = maxSupply_;
        if (initialSupply > 0) {
            _mint(msg.sender, tokenId, initialSupply, hex"");
        }
    }

    // To be overridden with permissioning
    function setBaseURI(string memory baseURIParam) external virtual;

    // Internal function to create a token
    function _setBaseURI(string memory baseURIParam) internal {
        baseURI = baseURIParam;
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(amount != 0, "Zero amount");
        require(currentSupply[id] + amount <= maxSupply[id], "Max supply");
        currentSupply[id] += amount;
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(ids.length == amounts.length, "Array length");
        require(ids.length != 0, "Zero values");

        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] != 0, "Zero amount");
            uint256 tokenId = ids[i];
            require(currentSupply[tokenId] + amounts[i] <= maxSupply[tokenId], "Max supply");
            currentSupply[tokenId] += amounts[i];
        }
        super._mintBatch(to, ids, amounts, data);
    }
}

contract ReceiveAndDoTooMuch {
    uint256 count = 0;

    receive() external payable {
        for (uint256 i = 0; i < 255; i++) {
            count += 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../AbsERC1155.sol";
import "../mixins/TimeframeMixin.sol";

// unsafe
contract TestTimeframeMixin is TimeframeMixin {
    function setValidBefore(uint256 key, uint256 timestamp) external {
        _setValidBefore(key, timestamp);
    }

    function setValidAfter(uint256 key, uint256 timestamp) external {
        _setValidAfter(key, timestamp);
    }

    function setTimeframe(
        uint256 key,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        _setTimeframe(key, startTimestamp, endTimestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev Applies a timeframe to a key.
 */
abstract contract TimeframeMixin {
    mapping(uint256 => uint256) private startTimestamps;
    mapping(uint256 => uint256) private endTimestamps;

    function isWithinTimeframe(uint256 key) public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= startTimestamps[key] && block.timestamp <= endTimestamps[key];
    }

    function getTimeframe(uint256 key) public view returns (uint256, uint256) {
        return (startTimestamps[key], endTimestamps[key]);
    }

    /**
     * @dev Sets a timeframe that is valid <= the given timestamp.
     */
    function _setValidBefore(uint256 key, uint256 timestamp) internal {
        _setTimeframe(key, 0, timestamp);
    }

    /**
     * @dev Sets a timeframe that is valid >= the given timestamp.
     */
    function _setValidAfter(uint256 key, uint256 timestamp) internal {
        _setTimeframe(key, timestamp, type(uint256).max);
    }

    /**
     * @dev Set the valid timeframe for the particular key.  A timeframe consists of a start time and an end time.
     * Any block timestamp in the range [startTimestamp,endTimestamp] (inclusive) will be treated as within the
     * timeframe and deemed valid.
     */
    function _setTimeframe(
        uint256 key,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal {
        require(startTimestamp < endTimestamp, "Invalid state");
        startTimestamps[key] = startTimestamp;
        endTimestamps[key] = endTimestamp;
    }
}

contract CanReceiveEth {
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../AbsERC721.sol";

// Unsafe contract
contract TestBaseERC721 is AbsERC721 {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) AbsERC721(name, symbol, baseURI) {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }

    function setBaseURI(string memory baseURI) external override {
        _setBaseURI(baseURI);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AbsERC721 is ERC721 {
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURIParam
    ) ERC721(name, symbol) {
        _setBaseURI(baseURIParam);
    }

    function setBaseURI(string memory baseURIParam) external virtual;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURIParam) internal {
        baseURI = baseURIParam;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../pricing/BucketTieredPricing.sol";

// Unsafe contract
contract TestBucketTieredPricing is BucketTieredPricing {
    function setPriceBuckets(
        uint256 key,
        uint256 bucketSize,
        uint256[] memory bucketPrices
    ) external {
        _setPriceBuckets(key, bucketSize, bucketPrices);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ISupplyBasedPrice.sol";

/**
 * @dev A tiered pricing strategy that uses buckets to determine the price.  Each price bucket has a size
 * and a list of prices.  The logic for determining the price is: prices[floor((supply - 1) / this.bucket_size)].
 * where we have a list of prices and know the bucket size.
 *
 * If the index exceeds the length of price list, the last price will be used.
 */
abstract contract BucketTieredPricing is ISupplyBasedPrice {
    struct PriceBucket {
        uint256 size;
        uint256[] prices;
    }

    mapping(uint256 => PriceBucket) private priceBucketsByKey;

    function getPriceForSupply(uint256 key, uint256 supply) public view override returns (uint256 price) {
        require(priceBucketsByKey[key].size > 0, "Unknown key");
        require(supply > 0, "Invalid supply");

        uint256 index = (supply - 1) / priceBucketsByKey[key].size;
        if (index >= priceBucketsByKey[key].prices.length) {
            // if this would cause an index error, choose the last bucket
            index = priceBucketsByKey[key].prices.length - 1;
        }

        return priceBucketsByKey[key].prices[index];
    }

    function _setPriceBuckets(
        uint256 key,
        uint256 bucketSize,
        uint256[] memory bucketPrices
    ) internal {
        require(bucketSize > 0, "Bucket size");
        require(bucketPrices.length > 0, "Bucket length");
        require(priceBucketsByKey[key].size == 0, "Already initialized");
        priceBucketsByKey[key] = PriceBucket(bucketSize, bucketPrices);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISupplyBasedPrice {
    function getPriceForSupply(uint256 key, uint256 supply) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleERC721 is ERC721 {
    constructor() ERC721("simple", "SIMPLE") {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}

import "../pricing/LinearPricingStorage.sol";

contract TestLinearPricingStorage is LinearPricingStorage {
    function setParams(
        uint256 tokenId,
        uint256 M_NUM,
        uint256 M_DENOM,
        uint256 B_NUM,
        uint256 B_DENOM
    ) public {
        _setParams(tokenId, Params(M_NUM, M_DENOM, B_NUM, B_DENOM));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ISupplyBasedPrice.sol";

// Linear pricing formula: price = m * supply + b, where m, b are positive and can be fractions
abstract contract LinearPricingStorage is ISupplyBasedPrice {
    // Struct with numerator, denominator values
    struct Params {
        uint256 M_NUM;
        uint256 M_DENOM;
        uint256 B_NUM;
        uint256 B_DENOM;
    }

    // Mapping of key => line params, private so accessible only with this contract methods
    mapping(uint256 => Params) private keyParams;

    /**
     * @dev Returns base price for a given key. When working with ether, 1 ether is a easy base price around which to specify fractions of m, b
     * @param key Arbitrary key that can be used for multiple pricing mechanisms per contract
     */
    function _BASE_PRICE(uint256 key) internal view virtual returns (uint256) {
        return 1 ether;
    }

    /**
     * @dev Internal function for setting the params for a given key
     * @param key Arbitrary key that can be used for multiple pricing mechanisms per contract
     */
    function _setParams(uint256 key, Params memory params) internal virtual {
        keyParams[key] = params;
    }

    /**
     * @dev Internal function for setting the params for a given key
     * @param key Arbitrary key that can be used for multiple pricing mechanisms per contract
     * @param supply Token supply that will determine the mint price
     */
    function getPriceForSupply(uint256 key, uint256 supply) public view override returns (uint256 price) {
        Params memory params = getParams(key);
        price =
            (supply * _BASE_PRICE(key) * params.M_NUM) /
            params.M_DENOM +
            (params.B_NUM * _BASE_PRICE(key)) /
            params.B_DENOM;
    }

    /**
     * @dev Public view function for getting the line params data for a given key
     * @param key Arbitrary key that can be used for multiple pricing mechanisms per contract
     */
    function getParams(uint256 key) public view virtual returns (Params memory params) {
        params = keyParams[key];
        require(params.M_DENOM != 0 && params.B_DENOM != 0, "Params not set");
    }
}

contract ReceiveAndDoSomething {
    uint256 count = 0;

    struct Test {
        address test;
    }

    mapping(uint256 => Test) countTests;

    receive() external payable {
        count += 1;

        countTests[count] = Test(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../mixins/WrappedNativeHelpers.sol";

contract TestSendValueBackupWeth is WrappedNativeHelpers {
    constructor(address weth) {
        _setWrappedAddress(weth);
    }

    function deposit() external payable {}

    function send(address to, uint256 amount) external {
        sendValueIfFailsSendWrapped(payable(to), amount);
    }
}

import "../AbsSignatureRestricted.sol";

contract TestAbsSignatureRestricted is AbsSignatureRestricted {
    constructor() AbsSignatureRestricted(msg.sender) {}

    function testVerifySignedData(
        bytes memory data,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        verifySignedData(data, timestamp, v, r, s);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../mixins/OwnerWithdrawable.sol";

contract TestOwnerWithdrawable is OwnerWithdrawable {
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Helper to withdraw all ether from the contract.
 */
abstract contract OwnerWithdrawable is Ownable {
    /**
     * @dev Withdraw all the ether in this contract.
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Zero balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}

// SPDX-License-Identifier: UNLICENSED

import "../mixins/RoyaltyMixin.sol";
import "../OwnableERC1155.sol";

contract TestRoyaltyERC1155 is OwnableERC1155, RoyaltyMixin {
    constructor() OwnableERC1155("") {}

    function setRoyaltyInfo(
        uint256 tokenId,
        address payable recipient,
        uint256 percentNumerator
    ) external onlyOwner {
        _setRoyaltyInfo(tokenId, recipient, percentNumerator);
    }

    function setDefaultRoyaltyInfo(address payable recipient, uint256 percentNumerator) external onlyOwner {
        _setDefaultRoyaltyInfo(recipient, percentNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(RoyaltyMixin, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

import "../AbsERC2981.sol";
import "../AbsRaribleRoyalties.sol";

abstract contract RoyaltyMixin is AbsERC2981, AbsRaribleRoyalties {
    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    uint256 public constant DENOMINATOR = 10000;

    struct RoyaltyInfo {
        address payable recipient;
        uint256 percentNumerator;
    }

    mapping(uint256 => RoyaltyInfo) public tokenRoyaltyInfo;
    RoyaltyInfo public defaultRoyaltyInfo;

    /***********************************|
    |   Public Getters                  |
    |__________________________________*/

    /**
     * @dev Public getter method to return RoyaltyInfo for a particular tokenId given an value input
     * @param tokenId Id of token for which to get the RoyaltyInfo
     * @param value Total amount that will be paid in secondary sale
     * @param data Extra data for the transaction
     * @return reciever Address that will recieve royalties
     * @return royaltyAmount Uint amount that will be sent from the value to the recipient
     * @return royaltyPaymentData Extra bytes that might be used in paying out royalties
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    )
        external
        view
        virtual
        override
        returns (
            address payable reciever,
            uint256 royaltyAmount,
            bytes memory royaltyPaymentData
        )
    {
        RoyaltyInfo memory royaltyData = _getRoyaltyInfo(tokenId);

        reciever = royaltyData.recipient;
        royaltyAmount = (value * royaltyData.percentNumerator) / DENOMINATOR;
    }

    /**
     * @dev Public getter method to return fee recipients array for a particular tokenId
     * @param tokenId Id of token for which to get the RoyaltyInfo
     * @return recipients Array of addresses that get royalties for a tokenId
     */
    function getFeeRecipients(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address payable[] memory recipients)
    {
        recipients = new address payable[](1);
        RoyaltyInfo memory royaltyData = _getRoyaltyInfo(tokenId);
        recipients[0] = royaltyData.recipient;
    }

    /**
     * @dev Public getter method to return fee pbs array for a particular tokenId
     * @param tokenId Id of token for which to get the RoyaltyInfo
     * @return feeBps Array of fee basis points / 10,000 that represent % of payment sent as royalties
     */
    function getFeeBps(uint256 tokenId) public view virtual override returns (uint256[] memory feeBps) {
        feeBps = new uint256[](1);
        RoyaltyInfo memory royaltyData = _getRoyaltyInfo(tokenId);
        feeBps[0] = royaltyData.percentNumerator;
    }

    /**
     * @dev Public getter for if an ERC165 interface is supported
     * @param interfaceID Id of ERC165 interface signature
     */
    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override(AbsERC2981, AbsRaribleRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    /***********************************|
    |  Internal Functions               |
    |__________________________________*/

    /**
     * @dev Internal helper method to get RoyaltyInfo given a tokenId
     * @param tokenId Id of token for which to get RoyaltyInfo
     * @return royaltyData RoyaltyInfo struct
     */
    function _getRoyaltyInfo(uint256 tokenId) internal view returns (RoyaltyInfo memory royaltyData) {
        royaltyData = tokenRoyaltyInfo[tokenId];

        // tokenId royalty data not set, use default
        if (royaltyData.recipient == address(0)) {
            royaltyData = defaultRoyaltyInfo;
        }
    }

    /**
     * @dev Internal helper method to validate that recipient and percentNumerator are valid
     * @param recipient Address that will recieve royalties
     * @param percentNumerator Uint representation of percents as basis points / 10,000
     */
    function _validateRecipientAndPercent(address payable recipient, uint256 percentNumerator) internal {
        require(recipient != address(0) || percentNumerator == 0, "Invalid recipient");
        require(percentNumerator <= DENOMINATOR, "Invalid percent numerator");
    }

    /***********************************|
    |  Internal Functions - Setters     |
    |__________________________________*/

    /**
     * @dev Internal setter method to set RoyaltyInfo for a tokenId
     * @param tokenId Id of token for which to set RoyaltyInfo
     * @param recipient Address that will recieve royalties
     * @param percentNumerator Uint representation of percents as basis points / 10,000
     */
    function _setRoyaltyInfo(
        uint256 tokenId,
        address payable recipient,
        uint256 percentNumerator
    ) internal {
        _validateRecipientAndPercent(recipient, percentNumerator);
        tokenRoyaltyInfo[tokenId] = RoyaltyInfo(recipient, percentNumerator);

        uint256[] memory bps = new uint256[](1);
        bps[0] = percentNumerator;

        address[] memory recipients = new address[](1);
        recipients[0] = recipient;

        emit SecondarySaleFees(tokenId, recipients, bps);
    }

    /**
     * @dev Internal setter method to set default RoyaltyInfo for all tokenIds
     * @param recipient Address that will recieve royalties
     * @param percentNumerator Uint representation of percents as basis points / 10,000
     */
    function _setDefaultRoyaltyInfo(address payable recipient, uint256 percentNumerator) internal {
        _validateRecipientAndPercent(recipient, percentNumerator);
        defaultRoyaltyInfo = RoyaltyInfo(recipient, percentNumerator);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract AbsERC2981 is ERC165 {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    )
        external
        virtual
        returns (
            address payable _receiver,
            uint256 _royaltyAmount,
            bytes memory _royaltyPaymentData
        );

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract AbsRaribleRoyalties is ERC165 {
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);

    function getFeeBps(uint256 id) public view virtual returns (uint256[] memory);

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == _INTERFACE_ID_FEES || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableERC1155 is AbsERC1155, Ownable {
    constructor(string memory baseURI) AbsERC1155(baseURI) {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function create(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply
    ) external virtual onlyOwner {
        _create(tokenId, initialSupply, maxSupply);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOwner {
        _mint(account, id, amount, data);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../pricing/LinearPricingStorage.sol";
import "../mixins/OriginalPrinter.sol";

contract TestERC1155LinearOriginalPrinter is OriginalPrinter, Ownable, LinearPricingStorage {
    constructor(string memory baseURI) AbsERC1155(baseURI) {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    // Creates an original token
    function createOriginalWithPrints(
        uint256 tokenId,
        uint256 maxSupply,
        uint256 M_NUM,
        uint256 M_DENOM,
        uint256 B_NUM,
        uint256 B_DENOM
    ) external onlyOwner {
        _setParams(getPrintTokenIdFromOriginal(tokenId), Params(M_NUM, M_DENOM, B_NUM, B_DENOM));
        _createOriginal(tokenId, 1);
        _createPrints(tokenId, maxSupply);
    }

    // Set fees as global for the contract
    function _getFeeRecipients(uint256 printTokenId)
        internal
        view
        virtual
        override
        returns (address[] memory recipients)
    {
        uint256 originalTokenId = getOriginalTokenIdFromPrint(printTokenId);
        address payable tokenOwner = getOriginalOwner(originalTokenId);
        recipients = new address[](2);
        recipients[0] = tokenOwner;
        recipients[1] = owner();
    }

    function _getFeeWeights() internal view virtual override returns (uint32[] memory weights) {
        weights = new uint32[](2);
        weights[0] = 500;
        weights[1] = 500;
    }

    function _getFeeTotalWeight() internal view virtual override returns (uint256) {
        return 1000;
    }

    function _RESERVE_NUM(uint256 tokenId) internal view virtual override returns (uint256) {
        return 90;
    }

    function _RESERVE_DENOM(uint256 tokenId) internal view virtual override returns (uint256) {
        return 100;
    }

    // Pricing is determined by linear function set per-token
    function getMintPrice(uint256 tokenId, uint256 supply) public view virtual override returns (uint256 price) {
        price = getPriceForSupply(getPrintTokenIdFromOriginal(tokenId), supply);
    }
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./BondingCurveMixin.sol";
import "./EthBalanceMixin.sol";
import "../AbsERC1155.sol";

// Abstract contract for creating an original, the owner of which receives royalties from prints purchases
abstract contract OriginalPrinter is AbsERC1155, BondingCurveMixin, EthBalanceMixin, ReentrancyGuard {
    using Address for address payable;

    mapping(uint256 => address payable) private originalOwners;

    /***********************************|
    |   Public Virtual Helpers 			|
    |__________________________________*/

    // Returns whether a tokenId is an original
    function isOriginalTokenId(uint256 tokenId) public view virtual returns (bool) {
        return tokenId & _PRINTS_FLAG_BIT() != _PRINTS_FLAG_BIT();
    }

    // Returns a print tokenId given an original
    function getPrintTokenIdFromOriginal(uint256 originalTokenId) public view virtual returns (uint256) {
        return originalTokenId | _PRINTS_FLAG_BIT();
    }

    function getOriginalTokenIdFromPrint(uint256 printTokenId) public view virtual returns (uint256) {
        return printTokenId & ~_PRINTS_FLAG_BIT();
    }

    function getOriginalOwner(uint256 tokenId) public view returns (address payable owner) {
        require(isOriginalTokenId(tokenId), "Invalid tokenId");
        owner = originalOwners[tokenId];
    }

    /***********************************|
    |   Internal Functions  			|
    |__________________________________*/

    // Function to refund sender if they overpaid
    function _refundSender(uint256 printPrice) internal {
        if (msg.value - printPrice > 0) {
            payable(msg.sender).sendValue(msg.value - printPrice);
        }
    }

    function _PRINTS_FLAG_BIT() internal pure virtual returns (uint256) {
        return 2**255;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (isOriginalTokenId(ids[i]) && amounts[i] > 0) {
                originalOwners[ids[i]] = payable(to);
            }
        }
    }

    function _getFeeRecipients(uint256 tokenId) internal view virtual returns (address[] memory recipients) {}

    function _getFeeWeights() internal view virtual returns (uint32[] memory weights) {}

    // Total fee weight, default to 10000 to mimic bps
    function _getFeeTotalWeight() internal view virtual returns (uint256 totalWeight) {
        totalWeight = 10000;
    }

    // Hooks that can turning on/off minting or burning
    function _beforeMintPrint(uint256 originalTokenId) internal view virtual {}

    function _beforeBurnPrint(uint256 originalTokenId) internal view virtual {}

    function _createPrints(uint256 tokenId, uint256 maxSupply) internal virtual {
        require(isOriginalTokenId(tokenId), "Invalid tokenId");
        // Create prints
        _create(getPrintTokenIdFromOriginal(tokenId), 0, maxSupply);
    }

    function _createOriginal(uint256 tokenId, uint256 initialSupply) internal virtual {
        require(isOriginalTokenId(tokenId), "Invalid tokenId");
        // Enforce maxSupply for original is 1
        _create(tokenId, initialSupply, 1);
    }

    function _handleFees(uint256 tokenId, uint256 amount) internal virtual override {
        _depositWeights(_getFeeRecipients(tokenId), _getFeeWeights(), _getFeeTotalWeight(), amount);
    }

    /***********************************|
    |   User Interaction		  		|
    |__________________________________*/

    function mintPrint(uint256 originalTokenId) external payable nonReentrant {
        _beforeMintPrint(originalTokenId);

        require(isOriginalTokenId(originalTokenId) == true, "Invalid tokenId");

        // Derive print tokenId from original tokenId
        uint256 tokenId = getPrintTokenIdFromOriginal(originalTokenId);

        // Mint price a function of new token supply
        uint256 newSupply = currentSupply[tokenId] + 1;
        uint256 cost = _addToReserve(tokenId, newSupply);

        // Create the print for the msg.sender
        // Also increments currentSupply
        _mint(msg.sender, tokenId, 1, "");

        _refundSender(cost);
    }

    function burnPrint(uint256 originalTokenId, uint256 minimumSupply) external nonReentrant {
        _beforeBurnPrint(originalTokenId);

        require(isOriginalTokenId(originalTokenId) == true, "Invalid tokenId");

        uint256 tokenId = getPrintTokenIdFromOriginal(originalTokenId);

        uint256 oldSupply = currentSupply[tokenId];
        require(oldSupply >= minimumSupply, "Min supply not met");

        uint256 burnAmount = _burnFromReserve(tokenId, oldSupply);

        uint256 newSupply = currentSupply[tokenId] - 1;
        currentSupply[tokenId] = newSupply;

        // Disburse funds
        payable(msg.sender).sendValue(burnAmount);
    }
}

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract BondingCurveMixin {
    using Address for address payable;

    // Amount of ETH held in the contract
    mapping(uint256 => uint256) private reserves;

    /***********************************|
    |  User Interaction                 |
    |__________________________________*/

    /**
     * @dev Function to return mint price for a bonding curve given a tokenId and supply post-mint
     * @param tokenId Id of token with varying supply (if ERC1155), mayb not be used if 721
     * @param supply The supply of tokens post-mint, on which to base the mint price
     */
    function getMintPrice(uint256 tokenId, uint256 supply) public view virtual returns (uint256 price);

    /**
     * @dev Function to return burn price for a bonding curve given a tokenId and its supply pre-burn
     * @param tokenId Id of token with varying supply (if ERC1155), maybe not be used if 721
     * @param prevSupply The supply of tokens pre-burn, on which to base the mint price
     */
    function getBurnPrice(uint256 tokenId, uint256 prevSupply) public view virtual returns (uint256 price) {
        // Default implementation is a fraction of mintPrice for given supply
        // Fraction can be optionally derived from tokenId
        price = (_RESERVE_NUM(tokenId) * getMintPrice(tokenId, prevSupply)) / _RESERVE_DENOM(tokenId);
    }

    /***********************************|
    |  Internal Functions               |
    |__________________________________*/

    /**
     * @dev Function to confirm user has sufficient balance, authorization before adding to reserves
     * @param tokenId Token for which to validate the balance is paid. Could determine payment currency
     * @param amount Amount of wei or ERC20 tokens to validate that a user has sent to this contract
     */
    function _validateBalance(uint256 tokenId, uint256 amount) internal virtual {
        // Default implementation assumes ETH
        // For ERC20, would override this with attempt to transfer amount to address(this)
        require(msg.value >= amount, "Insufficient funds");
    }

    /**
     * @dev Function to manage the depositing of an amount of fees given a tokenId
     * @param tokenId Token with variable supply for which mintPrice, burnPrice are computed, reserves are tracked
     * @param amount Amount of wei or ERC20 tokens that will be paid out for a tokenId
     */
    function _handleFees(uint256 tokenId, uint256 amount) internal virtual {}

    /**
     * @dev Adds part of mintPrice to reserve, and deposit remainder to set of weighted recipients
     * @param tokenId Token with variable supply for which mintPrice, burnPrice are computed, reserves are tracked
     * @param newSupply New supply of tokenId
     */
    function _addToReserve(uint256 tokenId, uint256 newSupply) internal returns (uint256 cost) {
        cost = getMintPrice(tokenId, newSupply);
        _validateBalance(tokenId, cost);
        uint256 reserveAmount = getBurnPrice(tokenId, newSupply);
        reserves[tokenId] += reserveAmount;
        uint256 remainder = cost - reserveAmount;

        // If difference between burn + mint, deposit to recipients, divided up by weights
        if (remainder > 0) {
            _handleFees(tokenId, remainder);
        }
    }

    /**
     * @dev Returns numerator of fraction that is applied to mintPrice, burnPrice difference to keep in reserves
     * @param tokenId Id of variable supply token
     */
    function _RESERVE_NUM(uint256 tokenId) internal view virtual returns (uint256) {}

    /**
     * @dev Returns denominator of fraction that is applied to mintPrice, burnPrice difference to keep in reserves
     * @param tokenId Id of variable supply token
     */
    function _RESERVE_DENOM(uint256 tokenId) internal view virtual returns (uint256) {}

    /**
     * @dev Determines burn redemption amount given token and supply, removes amount from token reserves and returns value
     * @param tokenId Id of variable supply token
     * @param prevSupply The supply of tokens pre-burn, on which to base the mint price
     */
    function _burnFromReserve(uint256 tokenId, uint256 prevSupply) internal returns (uint256 amount) {
        amount = getBurnPrice(tokenId, prevSupply);
        reserves[tokenId] -= amount;
    }

    /***********************************|
    |  Public Getters                   |
    |__________________________________*/

    /**
     * @dev Get the reserve balance for a particular token
     * @param tokenId Id of variable supply token
     */
    function getReserve(uint256 tokenId) external view returns (uint256) {
        return reserves[tokenId];
    }
}

contract RevertOnETHPayment {
    receive() external payable {
        revert();
    }
}

contract NoReceive {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../AbsERC1155.sol";

// Unsafe contract
contract TestBaseERC1155 is AbsERC1155 {
    constructor(string memory baseURI) AbsERC1155(baseURI) {}

    function create(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply
    ) external {
        _create(tokenId, initialSupply, maxSupply);
    }

    function setBaseURI(string memory baseURI) external override {
        _setBaseURI(baseURI);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _mintBatch(to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SimpleERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(uint256 tokenId, uint256 amount) public {
        _mint(msg.sender, tokenId, amount, "");
    }

    function mintBatch(uint256[] memory tokenIds, uint256[] memory amounts) public {
        _mintBatch(msg.sender, tokenIds, amounts, "");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleERC20 is ERC20 {
    constructor() ERC20("simple", "TOKEN") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract RestrictedMixin is AccessControl {
    // List roles as constants
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant CREATE_ROLE = keccak256("CREATE_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

pragma solidity 0.8.9;

abstract contract AllowlistMixin {
    mapping(uint256 => mapping(address => bool)) private allowlists;

    event Allow(uint256 indexed key, address indexed addressInList, bool allowed);

    function isAllowed(uint256 key, address address_) internal view returns (bool) {
        return allowlists[key][address_];
    }

    function allow(
        uint256 key,
        address address_,
        bool allowed
    ) internal {
        allowlists[key][address_] = allowed;
        emit Allow(key, address_, allowed);
    }

    function allowBatch(
        uint256 key,
        address[] memory address_,
        bool[] memory allowed
    ) internal {
        require(address_.length == allowed.length, "Array lengths");

        for (uint256 i = 0; i < address_.length; i++) {
            allow(key, address_[i], allowed[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC1155.sol";
import "./mixins/RestrictedMixin.sol";

contract RestrictedERC1155 is AbsERC1155, RestrictedMixin {
    constructor(string memory baseURI) AbsERC1155(baseURI) RestrictedMixin() {
        _setupRole(CREATE_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);
    }

    function setBaseURI(string memory baseURI) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(baseURI);
    }

    function create(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply
    ) external virtual onlyRole(CREATE_ROLE) {
        _create(tokenId, initialSupply, maxSupply);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual onlyRole(MINT_ROLE) {
        _mint(account, id, amount, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AbsERC1155.sol";

/**
 * ERC1155 implementation that allows admin minting with a max supply
 */
contract TreumERC1155 is AbsERC1155, Ownable {
    using SafeERC20 for IERC20;

    struct PublicMintData {
        address erc20Address;
        uint256 mintPrice;
        bool enabled;
    }

    mapping(uint256 => PublicMintData) public tokenMintPrices;
    mapping(uint256 => string) private tokenURIs;

    constructor() AbsERC1155("") {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Create an ERC1155 token, with a max supply
     * @dev The contract owner can mint tokens on demand up to the max supply
     */
    function createForAdminMint(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory uri
    ) external onlyOwner {
        tokenURIs[tokenId] = uri;

        // Create ERC1155 token with specified supplies
        _create(tokenId, initialSupply, maxSupply);
    }

    /**
     * @dev Mints an amount of ERC1155 tokens to an address
     */
    function adminMint(
        uint256 tokenId,
        uint256 amount,
        address to
    ) external onlyOwner {
        _mint(to, tokenId, amount, hex"");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        // we could revert for non existant ones
        return tokenURIs[tokenId];
    }

    /**
     * @dev Safety function to be able to recover tokens if they are sent to this contract by mistake
     */
    function withdrawTokensTo(address erc20Address, address recipient) external onlyOwner {
        uint256 tokenBalance = IERC20(erc20Address).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens");

        IERC20(erc20Address).safeTransfer(recipient, tokenBalance);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TreumERC721 is AbsERC721, ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) AbsERC721(name, symbol, "") {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(AbsERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        ERC721URIStorage._burn(tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override(AbsERC721, ERC721) returns (string memory) {
        return AbsERC721._baseURI();
    }

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri
    ) external onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function isMinter(address account) external view returns (bool) {
        return owner() == account;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract to support splitting ERC20 and ETH payments among an array of recipients
contract ETHAndTokenSplitter is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // Recipients and corresponding weight array
    address payable[] public recipients;
    uint256[] public weights;
    // Total weight
    uint256 public total;
    // Max weight to avoid overflow of total
    uint256 public constant MAX_WEIGHT = 2**32;

    constructor(address payable[] memory recipientsParam, uint256[] memory weightsParam) {
        _setState(recipientsParam, weightsParam);
    }

    // Support ether payments to contract
    receive() external payable {}

    // Compatible with EulerBeats contract payouts
    function addReward() external payable {}

    /***********************************|
    |        User Interactions          |
    |__________________________________*/

    /**
     * @dev Function to distribute tokens owned by this contract to recipients. Available to public
     * @param tokens Array of ERC20 addresses of which to transfer balances
     */
    function distributeTokens(address[] memory tokens) public nonReentrant {
        uint256 tokenBalance;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            for (uint256 j = 0; j < recipients.length; j++) {
                IERC20(tokens[i]).safeTransfer(recipients[j], (weights[j] * tokenBalance) / total);
            }
        }
    }

    /**
     * @dev Function to distribute ETH owned by this contract to recipients. Available to public
     */
    function distributeEth() public nonReentrant {
        uint256 ethBalance = address(this).balance;

        uint256 sendAmount;
        address payable recipient;

        for (uint256 j = 0; j < recipients.length; j++) {
            sendAmount = (weights[j] * ethBalance) / total;
            recipient = recipients[j];

            Address.sendValue(recipient, sendAmount);
        }
    }

    /**
     * @dev Function to distribute tokens and ETH owned by this contract to recipients. Available to public
     * @param tokens Array of ERC20 addresses of which to transfer balances
     */
    function distributeTokensAndETH(address[] memory tokens) external {
        distributeTokens(tokens);
        distributeEth();
    }

    /***********************************|
    |   Public Getters - Pricing        |
    |__________________________________*/

    /**
     * @dev Function to get info about recipients and weights
     */
    function getSplitterInfo()
        external
        view
        returns (address payable[] memory recipientOutput, uint256[] memory weightOutput)
    {
        recipientOutput = recipients;
        weightOutput = weights;
    }

    /***********************************|
    |        Admin                      |
    |__________________________________*/

    /**
     * @dev Function to update array of recipients and weights. Restricted to owner
     * @param recipientsParam Array of payable addresses to split the payments
     * @param weightsParam Array of uints to assign %s to each recipients
     */
    function updateRecipients(address payable[] memory recipientsParam, uint256[] memory weightsParam)
        external
        onlyOwner
    {
        _setState(recipientsParam, weightsParam);
    }

    /***********************************|
    |  Internal Functions               |
    |__________________________________*/

    /**
     * @dev Internal function to update array of recipients and weights. Callable by owner and constructor
     * @param recipientsParam Array of payable addresses to split the payments
     * @param weightsParam Array of uints to assign %s to each recipients
     */
    function _setState(address payable[] memory recipientsParam, uint256[] memory weightsParam) internal {
        delete recipients;
        delete weights;
        total = 0;

        require(recipientsParam.length == weightsParam.length, "Invalid input length");
        for (uint256 i = 0; i < recipientsParam.length; i++) {
            require(weightsParam[i] != 0, "Invalid weight");
            require(weightsParam[i] < MAX_WEIGHT, "Max weight exceeded");
            require(recipientsParam[i] != address(0), "Invalid recipient");

            recipients.push(recipientsParam[i]);
            weights.push(weightsParam[i]);
            total += weightsParam[i];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../AbsERC1155.sol";
import "../pricing/BucketTieredPricing.sol";
import "../mixins/OwnerWithdrawable.sol";

/**
 * ERC1155 implementation that allows public minting with a max supply and a deadline for minting.
 */
contract ERC1155TieredPricing is AbsERC1155, Ownable, BucketTieredPricing, OwnerWithdrawable {
    constructor(string memory baseURI) AbsERC1155(baseURI) {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function createTokenWithTieredPricing(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 bucketSize,
        uint256[] memory bucketPrices
    ) external virtual onlyOwner {
        _setPriceBuckets(tokenId, bucketSize, bucketPrices);
        _create(tokenId, initialSupply, maxSupply);
    }

    /**
     * @dev Mint a single token to msg.sender.
     */
    function mint(uint256 tokenId) external payable {
        require(msg.value == getPriceForSupply(tokenId, currentSupply[tokenId] + 1), "Bad price");
        _mint(msg.sender, tokenId, 1, hex"");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../AbsERC1155.sol";
import "../mixins/OwnerWithdrawable.sol";
import "../mixins/TimeframeMixin.sol";

/**
 * ERC1155 implementation that allows public minting with a max supply and a timeframe for minting.
 */
contract ERC1155OpenEdition is AbsERC1155, Ownable, TimeframeMixin, OwnerWithdrawable {
    uint256 public mintPrice;

    constructor(string memory baseURI) AbsERC1155(baseURI) {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function createOpenEditionToken(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 mintPrice_,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external virtual onlyOwner {
        mintPrice = mintPrice_;
        _setTimeframe(tokenId, startTimestamp, endTimestamp);
        _create(tokenId, initialSupply, maxSupply);
    }

    function mint(uint256 tokenId) external payable {
        require(isWithinTimeframe(tokenId), "Minting closed");
        require(msg.value == mintPrice, "Mint price");
        _mint(msg.sender, tokenId, 1, hex"");
    }
}

import "./AbsEnglishAuction.sol";

contract TreumEnglishAuction is AbsEnglishAuction {
    constructor(address wrappedNativeAsset) AbsEnglishAuction(wrappedNativeAsset) {}

    /**
     * @notice Create an English auction
     * @param tokenId uint256 Token ID of the NFT to auction
     * @param tokenContract address Address of the NFT token contract
     * @param tokenType TokenType Either ERC721 or ERC1155
     * @param duration uint256 Length of the auction in seconds
     * @param startTime uint256 Start time of the auction in seconds
     * @param startingBid uint256 Minimum initial bid for the auction
     * @param paymentCurrency address Contract address of the token used to bid and pay with
     * @param extensionWindow uint256 Window where there must be no bids before auction ends, in seconds
     * @param minBidIncrementBps uint256 Each bid must be at least this % higher than the previous one
     * @param feeRecipients address[] Addresses of fee recipients
     * @param feePercentages uint32[] Percentages of winning bid paid to fee recipients, in basis points
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        TokenType tokenType,
        uint256 duration,
        uint256 startTime,
        uint256 startingBid,
        address paymentCurrency,
        uint256 extensionWindow,
        uint256 minBidIncrementBps,
        address[] memory feeRecipients,
        uint32[] memory feePercentages
    ) public {
        super._createAuction(
            tokenId,
            tokenContract,
            tokenType,
            duration,
            startTime,
            startingBid,
            paymentCurrency,
            extensionWindow,
            minBidIncrementBps,
            feeRecipients,
            feePercentages
        );
    }

    /**
     * @notice Place bid on a running auction with an ERC20 token with SIGNER restriction
     * @param auctionId uint256 Auction ID of the auction
     * @param bidAmount uint256 Amount of bid if non-eth currency
     */
    function placeBid(uint256 auctionId, uint256 bidAmount) public payable nonReentrant {
        super._placeBid(auctionId, bidAmount);
    }

    /**
     * @notice Place bid on a running auction in the native currency with SIGNER restriction
     * @dev msg.value is bid amount
     * @param auctionId uint256 Auction ID of the auction
     */
    function placeBidInEth(uint256 auctionId) public payable nonReentrant {
        super._placeBidInEth(auctionId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../AbsERC1155.sol";

/**
 * ERC1155 implementation that allows public minting with a max supply, and a fixed price for minting (payable via ERC20 token)
 */
contract WIPTreumERC1155 is AbsERC1155, Ownable {
    using SafeERC20 for IERC20;

    struct PublicMintData {
        address erc20Address;
        uint256 mintPrice;
        bool enabled;
    }

    mapping(uint256 => PublicMintData) public tokenMintPrices;
    mapping(uint256 => string) private tokenURIs;

    constructor() AbsERC1155("") {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Creates an ERC1155 token, optionally setting a fixed price (erc20) for minting the ERC1155
     * @dev Can also be used to premint the full supply of an ERC1155 to the contract owner
     */
    function createWithFixedPrice(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 mintPrice,
        address mintPriceTokenAddress,
        string memory uri
    ) external onlyOwner {
        if (initialSupply < maxSupply) {
            require(mintPrice > 0, "Invalid Mint Price");
        }

        tokenMintPrices[tokenId] = PublicMintData({
            erc20Address: mintPriceTokenAddress,
            mintPrice: mintPrice,
            enabled: true
        });
        tokenURIs[tokenId] = uri;

        // Create ERC1155 token with specified supplies
        _create(tokenId, initialSupply, maxSupply);
    }

    /**
     * @dev Mints a single ERC1155 to msg.sender
     */
    function publicMint(uint256 tokenId) external {
        // Get the address & price for minting via ERC20
        PublicMintData storage publicMintData = tokenMintPrices[tokenId];
        require(publicMintData.enabled, "Public Minting Not Enabled");

        if (publicMintData.mintPrice > 0) {
            // Receive ERC20 mintPrice amount
            IERC20(publicMintData.erc20Address).safeTransferFrom(msg.sender, address(this), publicMintData.mintPrice);
        }

        // Mint ERC1155
        _mint(msg.sender, tokenId, 1, hex"");
    }

    /**
     * @dev Create an ERC1155 token, with a max supply, public minting not enabled
     * @dev For backwards compatibility, it can also be used to premint the full supply
     * @dev to the contract owner
     */
    function createForAdminMint(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory uri
    ) external onlyOwner {
        tokenURIs[tokenId] = uri;

        // Create ERC1155 token with specified supplies
        _create(tokenId, initialSupply, maxSupply);
    }

    /**
     * @dev Mints an amount of ERC1155 tokens to an address
     */
    function adminMint(
        uint256 tokenId,
        uint256 amount,
        address to
    ) external onlyOwner {
        _mint(to, tokenId, amount, hex"");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        // we could revert for non existant ones
        return tokenURIs[tokenId];
    }

    function withdrawTokensTo(address erc20Address, address recipient) external onlyOwner {
        uint256 tokenBalance = IERC20(erc20Address).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens");

        IERC20(erc20Address).safeTransfer(recipient, tokenBalance);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableERC721 is AbsERC721, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) AbsERC721(name, symbol, baseURI) {}

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function mint(address to, uint256 tokenId) external virtual onlyOwner {
        _safeMint(to, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC721.sol";
import "./mixins/RestrictedMixin.sol";

contract RestrictedERC721 is AbsERC721, RestrictedMixin {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) AbsERC721(name, symbol, baseURI) RestrictedMixin() {}

    function setBaseURI(string memory baseURI) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(baseURI);
    }

    function mint(address to, uint256 tokenId) external virtual onlyRole(MINT_ROLE) {
        _safeMint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Anchor {
    mapping(bytes32 => uint256) public merkleRoots;

    function setRoot(bytes32 rootHash) public returns (uint256) {
        merkleRoots[rootHash] = block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}