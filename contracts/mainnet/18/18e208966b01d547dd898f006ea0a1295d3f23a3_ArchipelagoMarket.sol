// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITraitOracle.sol";
import "./IRoyaltyOracle.sol";
import "./IWeth.sol";
import "./MarketMessages.sol";
import "./SignatureChecker.sol";

contract ArchipelagoMarket is Ownable {
    using MarketMessages for Ask;
    using MarketMessages for Bid;
    using MarketMessages for OrderAgreement;

    event NonceCancellation(address indexed participant, uint256 indexed nonce);

    event BidApproval(
        address indexed participant,
        bytes32 indexed bidHash,
        bool approved,
        Bid bid
    );
    event AskApproval(
        address indexed participant,
        bytes32 indexed askHash,
        bool approved,
        Ask ask
    );

    event Trade(
        uint256 indexed tradeId,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 proceeds,
        uint256 cost,
        IERC20 currency
    );
    /// Emitted once for every token that's transferred as part of a trade,
    /// i.e. a Trade event will correspond to one TokenTraded events.
    /// It's part of a separate event so that we can index more fields.
    event TokenTraded(
        uint256 indexed tradeId,
        IERC721 indexed tokenAddress,
        uint256 indexed tokenId
    );

    event RoyaltyPaid(
        uint256 indexed tradeId,
        address indexed payer,
        address indexed recipient,
        uint256 micros,
        uint256 amount,
        IERC20 currency
    );

    mapping(address => mapping(uint256 => bool)) public nonceCancellation;

    /// `onChainApprovals[address][structHash]` is `true` if `address` has
    /// provided on-chain approval of a message with hash `structHash`.
    ///
    /// These approvals are not bounded by a domain separator; the contract
    /// storage itself is the signing domain.
    mapping(address => mapping(bytes32 => bool)) public onChainApprovals;

    /// Whether the market is in emergencyShutdown mode (in which case, no trades
    /// can be made).
    bool emergencyShutdown;

    /// Address of the Archipelago protocol treasury (to which hardcoded
    /// royalties accrue)
    address archipelagoTreasuryAddress;

    /// Royalty rate that accrues to the Archipelago protocol treasury
    /// (expressed as millionths of each transaction value)
    uint256 archipelagoRoyaltyMicros;

    /// Hardcap the Archipelago royalty rate at 50 basis points.
    /// Prevents "rug" attacks where the contract owner unexpectedly
    /// spikes the royalty rate, abusing existing asks. Also, it's a nice
    /// commitment to our users.
    uint256 constant MAXIMUM_PROTOCOL_ROYALTY = 5000;

    uint256 constant ONE_MILLION = 1000000;

    string constant INVALID_ARGS = "Market: invalid args";

    string constant ORDER_CANCELLED_OR_EXPIRED =
        "Market: order cancelled or expired";

    string constant AGREEMENT_MISMATCH =
        "Market: bid or ask's agreement hash doesn't match order agreement";

    string constant TRANSFER_FAILED = "Market: transfer failed";

    bytes32 constant TYPEHASH_DOMAIN_SEPARATOR =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// Needs to be present so that the WETH contract can send ETH here for
    /// automatic unwrapping on behalf of sellers. No-one else should send
    /// ETH to this contract.
    receive() external payable {}

    /// Shut down the market. Should be used if a critical security
    /// flaw is discovered.
    function setEmergencyShutdown(bool isShutdown) external onlyOwner {
        emergencyShutdown = isShutdown;
    }

    function setTreasuryAddress(address newTreasuryAddress) external onlyOwner {
        archipelagoTreasuryAddress = newTreasuryAddress;
    }

    function setArchipelagoRoyaltyRate(uint256 newRoyaltyRate)
        external
        onlyOwner
    {
        require(
            newRoyaltyRate <= MAXIMUM_PROTOCOL_ROYALTY,
            "protocol royalty too high"
        );
        archipelagoRoyaltyMicros = newRoyaltyRate;
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_DOMAIN_SEPARATOR,
                    keccak256("ArchipelagoMarket"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function verify(
        bytes32 domainSeparator,
        bytes32 structHash,
        bytes memory signature,
        SignatureKind signatureKind
    ) internal view returns (address) {
        if (signatureKind != SignatureKind.EXTERNAL) {
            return
                SignatureChecker.recover(
                    domainSeparator,
                    structHash,
                    signature,
                    signatureKind
                );
        }
        address signer = abi.decode(signature, (address));
        require(
            signer == msg.sender || onChainApprovals[signer][structHash],
            "Market: on-chain approval missing"
        );
        return signer;
    }

    function setOnChainBidApproval(Bid memory bid, bool approved) external {
        bytes32 hash = bid.structHash();
        onChainApprovals[msg.sender][hash] = approved;
        emit BidApproval(msg.sender, hash, approved, bid);
    }

    function setOnChainAskApproval(Ask memory ask, bool approved) external {
        bytes32 hash = ask.structHash();
        onChainApprovals[msg.sender][hash] = approved;
        emit AskApproval(msg.sender, hash, approved, ask);
    }

    /// Computes the EIP-712 struct hash of the given bid. The resulting hash
    /// can be passed to `onChainApprovals(address, bytes32)` to check whether
    /// a given account has signed this bid.
    function bidHash(Bid memory bid) external pure returns (bytes32) {
        return bid.structHash();
    }

    /// Computes the EIP-712 struct hash of the given ask. The resulting hash
    /// can be passed to `onChainApprovals(address, bytes32)` to check whether
    /// a given account has signed this ask.
    function askHash(Ask memory ask) external pure returns (bytes32) {
        return ask.structHash();
    }

    /// Computes the EIP-712 struct hash of the parts of an order that must be
    /// shared between a bid and an ask. The resulting hash should appear as
    /// the `agreementHash` field of both the `Bid` and the `Ask` structs.
    function orderAgreementHash(OrderAgreement memory agreement)
        external
        pure
        returns (bytes32)
    {
        return agreement.structHash();
    }

    function cancelNonces(uint256[] calldata nonces) external {
        for (uint256 i; i < nonces.length; i++) {
            uint256 nonce = nonces[i];
            nonceCancellation[msg.sender][nonce] = true;
            emit NonceCancellation(msg.sender, nonce);
        }
    }

    function _verifyOrder(
        OrderAgreement memory agreement,
        Bid memory bid,
        bytes memory bidSignature,
        SignatureKind bidSignatureKind,
        Ask memory ask,
        bytes memory askSignature,
        SignatureKind askSignatureKind
    ) internal view returns (address bidder, address asker) {
        bytes32 agreementHash = agreement.structHash();
        require(bid.agreementHash == agreementHash, AGREEMENT_MISMATCH);
        require(ask.agreementHash == agreementHash, AGREEMENT_MISMATCH);

        bytes32 domainSeparator = computeDomainSeparator();
        bidder = verify(
            domainSeparator,
            bid.structHash(),
            bidSignature,
            bidSignatureKind
        );
        asker = verify(
            domainSeparator,
            ask.structHash(),
            askSignature,
            askSignatureKind
        );
    }

    function fillOrder(
        OrderAgreement memory agreement,
        Bid memory bid,
        bytes memory bidSignature,
        SignatureKind bidSignatureKind,
        Ask memory ask,
        bytes memory askSignature,
        SignatureKind askSignatureKind
    ) external {
        (address bidder, address asker) = _verifyOrder(
            agreement,
            bid,
            bidSignature,
            bidSignatureKind,
            ask,
            askSignature,
            askSignatureKind
        );
        _fillOrder(agreement, bid, bidder, ask, asker);
    }

    /// Variant of fill order where the buyer pays in ETH (which is converted to
    /// WETH under the hood). Added as a convenience. Code is mostly a repeat of
    /// fillOrder, since we need to get the bidder from the signature, and then
    /// convert the paid ETH to WETH.
    ///
    /// We don't know exactly how much the order will cost the bidder upfront
    /// (we'd need to calculate royalties). So instead, the bidder just provides
    /// any amount of ETH they want, which will be added to their WETH balance
    /// before attempting to fill the transaction. If they haven't sent enough,
    /// the tx will fail; if they sent extra, they wil have a remaining WETH
    /// balance afterwards, which we assume was their intent (maybe they have
    /// other bids outstanding).
    function fillOrderEth(
        OrderAgreement memory agreement,
        Bid memory bid,
        bytes memory bidSignature,
        SignatureKind bidSignatureKind,
        Ask memory ask,
        bytes memory askSignature,
        SignatureKind askSignatureKind
    ) external payable {
        (address bidder, address asker) = _verifyOrder(
            agreement,
            bid,
            bidSignature,
            bidSignatureKind,
            ask,
            askSignature,
            askSignatureKind
        );
        require(msg.sender == bidder, "only bidder may fill with ETH");
        IWeth currency = IWeth(address(agreement.currencyAddress));
        currency.deposit{value: msg.value}();
        require(currency.transfer(bidder, msg.value), TRANSFER_FAILED);
        _fillOrder(agreement, bid, bidder, ask, asker);
    }

    function _fillOrder(
        OrderAgreement memory agreement,
        Bid memory bid,
        address bidder,
        Ask memory ask,
        address asker
    ) internal {
        require(!emergencyShutdown, "Market is shut down");

        IERC721 token = agreement.tokenAddress;
        uint256 price = agreement.price;
        IERC20 currency = agreement.currencyAddress;

        uint256 tokenId = ask.tokenId;

        require(
            ask.authorizedBidder == address(0) ||
                ask.authorizedBidder == bidder,
            "bidder is not authorized"
        );

        require(block.timestamp <= bid.deadline, ORDER_CANCELLED_OR_EXPIRED);
        require(block.timestamp <= ask.deadline, ORDER_CANCELLED_OR_EXPIRED);

        require(
            !nonceCancellation[bidder][bid.nonce],
            ORDER_CANCELLED_OR_EXPIRED
        );
        require(
            !nonceCancellation[asker][ask.nonce],
            ORDER_CANCELLED_OR_EXPIRED
        );

        // Bids and asks are cancelled on execution, to prevent replays. Cancel
        // upfront so that external calls (`transferFrom`, `safeTransferFrom`,
        // the ERC-721 receive hook) only observe the cancelled state.
        nonceCancellation[bidder][bid.nonce] = true;
        nonceCancellation[asker][ask.nonce] = true;

        uint256 tradeId = uint256(
            keccak256(abi.encode(bidder, bid.nonce, asker, ask.nonce))
        );
        // amount paid to seller, after subtracting asker royalties
        uint256 proceeds = price;
        // amount spent by the buyer, after including bidder royalties
        uint256 cost = price;

        if (address(bid.traitOracle) == address(0)) {
            uint256 expectedTokenId = uint256(bytes32(bid.trait));
            require(expectedTokenId == tokenId, "tokenid mismatch");
        } else {
            require(
                bid.traitOracle.hasTrait(token, tokenId, bid.trait),
                "missing trait"
            );
        }

        for (uint256 i = 0; i < agreement.requiredRoyalties.length; i++) {
            proceeds -= _payRoyalty(
                agreement.requiredRoyalties[i],
                bidder,
                asker,
                price,
                tradeId,
                currency,
                token,
                tokenId
            );
        }
        // Note that the extra royalties on the ask is basically duplicated
        // from the required royalties. If you make a change to one code path,
        // you should also change the other.
        // We're support "extra" asker royalties so that the seller can reward
        // an agent, broker, or advisor, as appropriate.
        for (uint256 i = 0; i < ask.extraRoyalties.length; i++) {
            proceeds -= _payRoyalty(
                ask.extraRoyalties[i],
                bidder,
                asker,
                price,
                tradeId,
                currency,
                token,
                tokenId
            );
        }

        // Finally, we pay the hardcoded protocol royalty. It also comes from
        // the asker, so it's in the same style as the required royalties and
        // asker's extra royalties.
        if (archipelagoTreasuryAddress != address(0)) {
            uint256 amt = (archipelagoRoyaltyMicros * price) / 1000000;
            proceeds -= amt;
            require(
                currency.transferFrom(bidder, archipelagoTreasuryAddress, amt),
                TRANSFER_FAILED
            );
            emit RoyaltyPaid(
                tradeId,
                asker,
                archipelagoTreasuryAddress,
                archipelagoRoyaltyMicros,
                amt,
                currency
            );
        }

        for (uint256 i = 0; i < bid.extraRoyalties.length; i++) {
            // Now we handle bid extra royalties.
            // This time we are increasing the cost (not decreasing the proceeds) and the RoyaltyPaid
            // event will specify the bidder as the entity paying the royalty.
            cost += _payRoyalty(
                bid.extraRoyalties[i],
                bidder,
                bidder,
                price,
                tradeId,
                currency,
                token,
                tokenId
            );
        }

        bool ownerOrApproved;
        address tokenOwner = token.ownerOf(tokenId);
        if (tokenOwner == asker) {
            ownerOrApproved = true;
        } else if (token.getApproved(tokenId) == asker) {
            ownerOrApproved = true;
        } else if (token.isApprovedForAll(tokenOwner, asker)) {
            ownerOrApproved = true;
        }
        require(ownerOrApproved, "asker is not owner or approved");
        token.safeTransferFrom(tokenOwner, bidder, tokenId);
        if (ask.unwrapWeth) {
            require(
                currency.transferFrom(bidder, address(this), proceeds),
                TRANSFER_FAILED
            );
            IWeth(address(currency)).withdraw(proceeds);
            // Note: This invokes the asker's fallback function. Be careful of
            // re-entrancy attacks. We deliberately invalidate the bid and ask
            // nonces before this point, to prevent replay attacks.
            payable(asker).transfer(proceeds);
        } else {
            require(
                currency.transferFrom(bidder, asker, proceeds),
                TRANSFER_FAILED
            );
        }

        emit Trade(tradeId, bidder, asker, price, proceeds, cost, currency);
        emit TokenTraded(tradeId, token, tokenId);
    }

    function _computeRoyalty(
        bytes32 royalty,
        IERC721 tokenContract,
        uint256 tokenId
    ) internal view returns (RoyaltyResult[] memory) {
        address target = address(bytes20(royalty));
        uint32 micros = uint32(uint256(royalty));
        uint32 staticBit = 1 << 31;
        bool isStatic = (micros & (staticBit)) != 0;
        micros &= ~staticBit;
        if (isStatic) {
            RoyaltyResult[] memory results = new RoyaltyResult[](1);
            results[0].micros = micros;
            results[0].recipient = target;
            return results;
        } else {
            uint64 data = uint64(uint256(royalty) >> 32);
            RoyaltyResult[] memory results = IRoyaltyOracle(target).royalties(
                tokenContract,
                tokenId,
                micros,
                data
            );
            uint256 totalMicros = 0;
            for (uint256 i = 0; i < results.length; i++) {
                totalMicros += results[i].micros;
            }
            require(
                totalMicros <= micros,
                "oracle wants to overspend royalty allotment"
            );
            return results;
        }
    }

    function _payComputedRoyalties(
        RoyaltyResult[] memory results,
        address bidder,
        // `logicalPayer` is either the bidder or the asker, depending on who
        // semantically is bearing the cost of this royalty. In all cases, the
        // funds will actually be transferred from the bidder; this only
        // affects the emitted event.
        address logicalPayer,
        uint256 price,
        uint256 tradeId,
        IERC20 currency
    ) internal returns (uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < results.length; i++) {
            RoyaltyResult memory result = results[i];
            uint256 amt = (result.micros * price) / ONE_MILLION;
            totalAmount += amt;
            require(
                currency.transferFrom(bidder, result.recipient, amt),
                TRANSFER_FAILED
            );
            emit RoyaltyPaid(
                tradeId,
                logicalPayer,
                result.recipient,
                result.micros,
                amt,
                currency
            );
        }
        return totalAmount;
    }

    function _payRoyalty(
        bytes32 royalty,
        address bidder,
        address logicalPayer,
        uint256 price,
        uint256 tradeId,
        IERC20 currency,
        IERC721 tokenContract,
        uint256 tokenId
    ) internal returns (uint256) {
        RoyaltyResult[] memory results = _computeRoyalty(
            royalty,
            tokenContract,
            tokenId
        );
        return
            _payComputedRoyalties(
                results,
                bidder,
                logicalPayer,
                price,
                tradeId,
                currency
            );
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitOracle {
    /// Queries whether the given NFT has the given trait. The NFT is specified
    /// by token ID only; the token contract is assumed to be known already.
    /// For instance, a trait oracle could be designed for a specific token
    /// contract, or it could call a method on `msg.sender` to determine what
    /// contract to use.
    ///
    /// The interpretation of trait IDs may be domain-specific and is at the
    /// discretion of the trait oracle. For example, an oracle might choose to
    /// encode traits called "Normal" and "Rare" as `0` and `1` respectively,
    /// or as `uint256(keccak256("Normal"))` and `uint256(keccak256("Rare"))`,
    /// or as something else. The trait oracle may expose other domain-specific
    /// methods to describe these traits.
    function hasTrait(
        IERC721 _tokenContract,
        uint256 _tokenId,
        bytes calldata _trait
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRoyaltyOracle {
    function royalties(
        IERC721 _tokenContract,
        uint256 _tokenId,
        uint32 _micros,
        uint64 _data
    ) external view returns (RoyaltyResult[] memory);
}

struct RoyaltyResult {
    address recipient;
    uint32 micros;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ITraitOracle.sol";

/// On Royalty Representations
///
/// Royalties take two possible forms. There are "static" and "dynamic"
/// royalties.
///
/// Static royalties consist of a specific recipient address, and a uint32
/// number of micros of royalty payment. Each micro corresponds to one
/// millionth of the purchase price.
///
/// Dynamic royalties have a royalty oracle address, and a uint32 max number
/// of micros that the oracle may allocate. The dynamic royalty also includes
/// a uint64 of arbitrary data that may be passed to the royalty oracle.
///
/// Whether a royalty is static or dynamic is encoded in the most significant
/// bit of the royalty micros value. Thus, while micros are encoded as a
/// uint32, there are only actually 31 bits available. This only rules out
/// unreasonably massive royalty values (billions of micros, or 1000x the total
/// purchase price), so it's not a serious limitation in practice. The sdk
/// prohibits setting the most significant bit in royalty micros.
///
/// Representationally, each royalty is a bytes32 where the first 20 bytes are
/// the recipient or oracle address, the next 8 bytes are the royalty oracle
/// calldata, and the final 4 bytes are the micros value.

/// Fields that a bid and ask must agree upon exactly for an order to be
/// filled.
struct OrderAgreement {
    /// Address of the ERC-20 contract being used as payment currency
    /// (typically WETH).
    IERC20 currencyAddress;
    /// Order price, in units of the ERC-20 given by `currencyAddress`.
    uint256 price;
    /// Address of the ERC-721 whose tokens are being traded.
    IERC721 tokenAddress;
    /// Royalties paid by the seller. This typically includes a royalty to the
    /// artist and to platforms supporting the token or the order.
    ///
    /// This is separated from the extra royalties on the ask to prevent token
    /// holders from taking an open bid on the orderbook and filling it without
    /// the conventional seller royalties.
    bytes32[] requiredRoyalties;
}

struct Bid {
    /// EIP-712 struct hash of the parts of this order shared between the bid
    /// and the ask, as an `OrderAgreement` struct.
    bytes32 agreementHash;
    uint256 nonce;
    /// Timestamp past which this order is no longer valid.
    uint40 deadline;
    /// Extra royalties specified by the participant who created this order.
    /// If the extra royalties are added on an Ask, they will be paid by the
    /// seller; extra royalties on a Bid are paid by the buyer (i.e. on top of
    /// the listed sale price).
    bytes32[] extraRoyalties;
    /// This is either: an encoding of the trait data that will be passed to
    /// the trait oracle (if one is provided), or the raw token id for the token
    /// being bid on (if the traitOracle is address zero).
    bytes trait;
    /// The address of the trait oracle used to interpret the trait data.
    /// If this is the zero address, the trait must be a uint256 token ID.
    ITraitOracle traitOracle;
}

struct Ask {
    /// EIP-712 struct hash of the parts of this order shared between the bid
    /// and the ask, as an `OrderAgreement` struct.
    bytes32 agreementHash;
    uint256 nonce;
    /// Timestamp past which this order is no longer valid.
    uint40 deadline;
    /// Extra royalties specified by the participant who created this order.
    /// If the extra royalties are added on an Ask, they will be paid by the
    /// seller; extra royalties on a Bid are paid by the buyer (i.e. on top of
    /// the listed sale price).
    bytes32[] extraRoyalties;
    /// The token ID listed for sale, under the token contract given by
    /// `orderAgreement.tokenAddress`.
    uint256 tokenId;
    /// Whether the asker would like their WETH proceeds to be automatically
    /// unwrapped to ETH on order execution.
    /// Purely a convenience for people who prefer ETH to WETH.
    bool unwrapWeth;
    /// The address of the account that is allowed to fill this order.
    /// If this address is the zero address, then anyone's bid may match.
    /// If this address is nonzero, they are the only address allowed to match
    /// this ask.
    address authorizedBidder;
}

library MarketMessages {
    using MarketMessages for OrderAgreement;
    using MarketMessages for bytes32[];

    bytes32 internal constant TYPEHASH_BID =
        keccak256(
            "Bid(bytes32 agreementHash,uint256 nonce,uint40 deadline,bytes32[] extraRoyalties,bytes trait,address traitOracle)"
        );
    bytes32 internal constant TYPEHASH_ASK =
        keccak256(
            "Ask(bytes32 agreementHash,uint256 nonce,uint40 deadline,bytes32[] extraRoyalties,uint256 tokenId,bool unwrapWeth,address authorizedBidder)"
        );
    bytes32 internal constant TYPEHASH_ORDER_AGREEMENT =
        keccak256(
            "OrderAgreement(address currencyAddress,uint256 price,address tokenAddress,bytes32[] requiredRoyalties)"
        );

    function structHash(Bid memory _self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_BID,
                    _self.agreementHash,
                    _self.nonce,
                    _self.deadline,
                    _self.extraRoyalties.structHash(),
                    keccak256(_self.trait),
                    _self.traitOracle
                )
            );
    }

    function structHash(Ask memory _self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_ASK,
                    _self.agreementHash,
                    _self.nonce,
                    _self.deadline,
                    _self.extraRoyalties.structHash(),
                    _self.tokenId,
                    _self.unwrapWeth,
                    _self.authorizedBidder
                )
            );
    }

    function structHash(OrderAgreement memory _self)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TYPEHASH_ORDER_AGREEMENT,
                    _self.currencyAddress,
                    _self.price,
                    _self.tokenAddress,
                    _self.requiredRoyalties.structHash()
                )
            );
    }

    function structHash(bytes32[] memory _self)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_self));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

enum SignatureKind {
    /// A message for which authorization is handled specially by the verifying
    /// contract. Signatures with this kind will always be rejected by
    /// `SignatureChecker.recover`; this enum variant exists to let callers
    /// handle other types of authorization, such as pre-authorization in
    /// contract storage or association with `msg.sender`.
    EXTERNAL,
    /// A message that starts with "\x19Ethereum Signed Message[...]", as
    /// implemented by the `personal_sign` JSON-RPC method.
    ETHEREUM_SIGNED_MESSAGE,
    /// A message that starts with "\x19\x01" and follows the EIP-712 typed
    /// data specification.
    EIP_712
}

library SignatureChecker {
    function recover(
        bytes32 _domainSeparator,
        bytes32 _structHash,
        bytes memory _signature,
        SignatureKind _kind
    ) internal pure returns (address) {
        bytes32 _hash;
        if (_kind == SignatureKind.ETHEREUM_SIGNED_MESSAGE) {
            _hash = ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(_domainSeparator, _structHash))
            );
        } else if (_kind == SignatureKind.EIP_712) {
            _hash = ECDSA.toTypedDataHash(_domainSeparator, _structHash);
        } else {
            revert("SignatureChecker: no signature given");
        }
        return ECDSA.recover(_hash, _signature);
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