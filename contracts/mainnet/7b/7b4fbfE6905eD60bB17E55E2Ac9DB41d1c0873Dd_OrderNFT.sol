// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./Errors.sol";
import "./utils/OrderKeyUtils.sol";

contract OrderNFT is ERC165, CloberOrderNFT {
    using Address for address;
    using Strings for uint256;
    using OrderKeyUtils for OrderKey;

    CloberMarketFactory private immutable _factory;
    address private immutable _canceler;

    string public override name;
    string public override symbol;
    string public override baseURI;
    address public override market;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(address factory, address canceler) {
        _factory = CloberMarketFactory(factory);
        _canceler = canceler;
    }

    function init(
        string memory name_,
        string memory symbol_,
        address market_
    ) external {
        if (market != address(0)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        if (market_ == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        name = name_;
        symbol = symbol_;
        market = market_;
    }

    modifier onlyMarket() {
        if (msg.sender != market) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _;
    }

    modifier onlyExists(uint256 tokenId) {
        if (_getOrderOwner(tokenId) == address(0)) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        _;
    }

    function changeBaseURI(string memory newBaseURI) external {
        if (_getHost() != msg.sender) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address user) public view returns (uint256) {
        if (user == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        uint256 balance = _balances[user];
        return balance > 0 ? balance - 1 : balance;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _getOrderOwner(tokenId);
        if (tokenOwner == address(0)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        return tokenOwner;
    }

    function tokenURI(uint256 tokenId) public view onlyExists(tokenId) returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (to == tokenOwner) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        _approve(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view onlyExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (msg.sender == operator) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert Errors.CloberError(Errors.NOT_IMPLEMENTED_INTERFACE);
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || isApprovedForAll(tokenOwner, spender) || getApproved(tokenId) == spender);
    }

    function _increaseBalance(address to) internal {
        _balances[to] += _balances[to] > 0 ? 1 : 2;
    }

    function _decreaseBalance(address to) internal {
        _balances[to] -= 1;
    }

    function onMint(address to, uint256 tokenId) external onlyMarket {
        if (to == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }

        _increaseBalance(to);

        emit Transfer(address(0), to, tokenId);
    }

    function onBurn(uint256 tokenId) external onlyMarket {
        address tokenOwner = ownerOf(tokenId);

        // Clear approvals
        _approve(tokenOwner, address(0), tokenId);

        _decreaseBalance(tokenOwner);

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external {
        if (msg.sender != _canceler) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        OrderKey[] memory orderKeys = new OrderKey[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (!_isApprovedOrOwner(from, tokenIds[i])) {
                revert Errors.CloberError(Errors.ACCESS);
            }
            orderKeys[i] = decodeId(tokenIds[i]);
        }
        CloberOrderBook(market).cancel(receiver, orderKeys);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (ownerOf(tokenId) != from) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        if (to == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }

        // Clear approvals from the previous owner
        _approve(from, address(0), tokenId);

        _decreaseBalance(from);
        _increaseBalance(to);
        CloberOrderBook(market).changeOrderOwner(decodeId(tokenId), to);

        emit Transfer(from, to, tokenId);
    }

    function _approve(
        address tokenOwner,
        address to,
        uint256 tokenId
    ) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert Errors.CloberError(Errors.NOT_IMPLEMENTED_INTERFACE);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function decodeId(uint256 id) public pure returns (OrderKey memory) {
        return OrderKeyUtils.decode(id);
    }

    function encodeId(OrderKey memory orderKey) external pure returns (uint256 id) {
        return orderKey.encode();
    }

    function owner() external view returns (address) {
        return _getHost();
    }

    function _getHost() internal view returns (address) {
        return _factory.getMarketHost(market);
    }

    function _getOrderOwner(uint256 tokenId) internal view returns (address) {
        return CloberOrderBook(market).getOrder(decodeId(tokenId)).owner;
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Errors {
    error CloberError(uint256 errorCode); // 0x1d25260a

    uint256 public constant ACCESS = 0;
    uint256 public constant FAILED_TO_SEND_VALUE = 1;
    uint256 public constant INSUFFICIENT_BALANCE = 2;
    uint256 public constant OVERFLOW_UNDERFLOW = 3;
    uint256 public constant EMPTY_INPUT = 4;
    uint256 public constant DELEGATE_CALL = 5;
    uint256 public constant DEADLINE = 6;
    uint256 public constant NOT_IMPLEMENTED_INTERFACE = 7;
    uint256 public constant INVALID_FEE = 8;
    uint256 public constant REENTRANCY = 9;
    uint256 public constant POST_ONLY = 10;
    uint256 public constant SLIPPAGE = 11;
    uint256 public constant QUEUE_REPLACE_FAILED = 12;
    uint256 public constant INVALID_COEFFICIENTS = 13;
    uint256 public constant INVALID_ID = 14;
    uint256 public constant INVALID_QUOTE_TOKEN = 15;
    uint256 public constant INVALID_PRICE = 16;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberOrderBook {
    /**
     * @notice Emitted when an order is created.
     * @param sender The address who sent the tokens to make the order.
     * @param user The address with the rights to claim the proceeds of the order.
     * @param rawAmount The ordered raw amount.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param options LSB: 0 - Ask, 1 - Bid.
     */
    event MakeOrder(
        address indexed sender,
        address indexed user,
        uint64 rawAmount,
        uint32 claimBounty,
        uint256 orderIndex,
        uint16 priceIndex,
        uint8 options
    );

    /**
     * @notice Emitted when an order takes from the order book.
     * @param sender The address who sent the tokens to take the order.
     * @param user The recipient address of the traded token.
     * @param priceIndex The price book index.
     * @param rawAmount The ordered raw amount.
     * @param options MSB: 0 - Limit, 1 - Market / LSB: 0 - Ask, 1 - Bid.
     */
    event TakeOrder(address indexed sender, address indexed user, uint16 priceIndex, uint64 rawAmount, uint8 options);

    /**
     * @notice Emitted when an order is canceled.
     * @param user The owner of the order.
     * @param rawAmount The raw amount remaining that was canceled.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBid The flag indicating whether it's a bid order or an ask order.
     */
    event CancelOrder(address indexed user, uint64 rawAmount, uint256 orderIndex, uint16 priceIndex, bool isBid);

    /**
     * @notice Emitted when the proceeds of an order is claimed.
     * @param claimer The address that initiated the claim.
     * @param user The owner of the order.
     * @param rawAmount The ordered raw amount.
     * @param bountyAmount The size of the claim bounty.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBase The flag indicating whether the user receives the base token or the quote token.
     */
    event ClaimOrder(
        address indexed claimer,
        address indexed user,
        uint64 rawAmount,
        uint256 bountyAmount,
        uint256 orderIndex,
        uint16 priceIndex,
        bool isBase
    );

    /**
     * @notice Emitted when a flash-loan is taken.
     * @param caller The caller address of the flash-loan.
     * @param borrower The address of the flash loan token receiver.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param earnedQuote The amount of quote tokens the protocol earned in quote tokens.
     * @param earnedBase The amount of base tokens the protocol earned in base tokens.
     */
    event Flash(
        address indexed caller,
        address indexed borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 earnedQuote,
        uint256 earnedBase
    );

    /**
     * @notice A struct that represents an order.
     * @param amount The raw amount not filled yet. In case of a stale order, the amount not claimed yet.
     * @param claimBounty The bounty amount in gwei that can be collected by the party that fully claims the order.
     * @param owner The address of the order owner.
     */
    struct Order {
        uint64 amount;
        uint32 claimBounty;
        address owner;
    }

    /**
     * @notice Take orders better or equal to the given priceIndex and make an order with the remaining tokens.
     * @dev `msg.value` will be used as the claimBounty.
     * @param user The taker/maker address.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param baseAmount The base token amount to trade, utilized by asks.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - Post only.
     * @param data Custom callback data
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Returns the expected input amount and output amount.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * Bid & expendInput => Used as input amount.
     * Bid & !expendInput => Not used.
     * Ask & expendInput => Not used.
     * Ask & !expendInput => Used as output amount.
     * @param baseAmount The base token amount to trade.
     * Bid & expendInput => Not used.
     * Bid & !expendInput => Used as output amount.
     * Ask & expendInput => Used as input amount.
     * Ask & !expendInput => Not used.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     */
    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256, uint256);

    /**
     * @notice Take opens orders until certain conditions are met.
     * @param user The taker address.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     * @param data Custom callback data.
     */
    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external;

    /**
     * @notice Cancel orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param receiver The address to receive canceled tokens.
     * @param orderKeys The order keys of the orders to cancel.
     */
    function cancel(address receiver, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Claim the proceeds of orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param claimer The address to receive the claim bounties.
     * @param orderKeys The order keys of the orders to claim.
     */
    function claim(address claimer, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Flash loan the tokens in the OrderBook.
     * @param borrower The address to receive the loan.
     * @param quoteAmount The quote token amount to borrow.
     * @param baseAmount The base token amount to borrow.
     * @param data The user's custom callback data.
     */
    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Returns the quote unit amount.
     * @return The amount that one raw amount represent in quote tokens.
     */
    function quoteUnit() external view returns (uint256);

    /**
     * @notice Returns the maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The maker fee. 100 = 1bp.
     */
    function makerFee() external view returns (int24);

    /**
     * @notice Returns the take fee
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The taker fee. 100 = 1bps.
     */
    function takerFee() external view returns (uint24);

    /**
     * @notice Returns the address of the order NFT contract.
     * @return The address of the order NFT contract.
     */
    function orderToken() external view returns (address);

    /**
     * @notice Returns the address of the quote token.
     * @return The address of the quote token.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the address of the base token.
     * @return The address of the base token.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the current total open amount at the given price.
     * @param isBid The flag to choose which side to check the depth for.
     * @param priceIndex The price book index.
     * @return The total open amount.
     */
    function getDepth(bool isBid, uint16 priceIndex) external view returns (uint64);

    /**
     * @notice Returns the fee balance that has not been collected yet.
     * @return quote The current fee balance for the quote token.
     * @return base The current fee balance for the base token.
     */
    function getFeeBalance() external view returns (uint128 quote, uint128 base);

    /**
     * @notice Returns the amount of tokens that can be collected by the host.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the host.
     */
    function uncollectedHostFees(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that can be collected by the dao treasury.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the dao treasury.
     */
    function uncollectedProtocolFees(address token) external view returns (uint256);

    /**
     * @notice Returns whether the order book is empty or not.
     * @param isBid The flag to choose which side to check the emptiness of.
     * @return Whether the order book is empty or not on that side.
     */
    function isEmpty(bool isBid) external view returns (bool);

    /**
     * @notice Returns the order information.
     * @param orderKey The order key of the order.
     * @return The order struct of the given order key.
     */
    function getOrder(OrderKey calldata orderKey) external view returns (Order memory);

    /**
     * @notice Returns the lowest ask price index or the highest bid price index.
     * @param isBid Returns the lowest ask price if false, highest bid price if true.
     * @return The current price index. If the order book is empty, it will revert.
     */
    function bestPriceIndex(bool isBid) external view returns (uint16);

    /**
     * @notice Converts a raw amount to its corresponding base amount using a given price index.
     * @param rawAmount The raw amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted base amount.
     */
    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint256);

    /**
     * @notice Converts a raw amount to its corresponding quote amount.
     * @param rawAmount The raw amount to be converted.
     * @return The converted quote amount.
     */
    function rawToQuote(uint64 rawAmount) external view returns (uint256);

    /**
     * @notice Converts a base amount to its corresponding raw amount using a given price index.
     * @param baseAmount The base amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint64);

    /**
     * @notice Converts a quote amount to its corresponding raw amount.
     * @param quoteAmount The quote amount to be converted.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function quoteToRaw(uint256 quoteAmount, bool roundingUp) external view returns (uint64);

    /**
     * @notice Collects fees for either the protocol or host.
     * @param token The token address to collect. It should be the quote token or the base token.
     * @param destination The destination address to transfer fees.
     * It should be the dao treasury address or the host address.
     */
    function collectFees(address token, address destination) external;

    /**
     * @notice Change the owner of the order.
     * @dev Only the OrderToken contract can call this function.
     * @param orderKey The order key of the order.
     * @param newOwner The new owner address.
     */
    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactory {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the VolatileMarketDeployer.
     * @return The address of the VolatileMarketDeployer.
     */
    function volatileMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the StableMarketDeployer.
     * @return The address of the StableMarketDeployer.
     */
    function stableMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    /**
     * @notice Computes the OrderNFT contract address.
     * @param marketNonce The nonce to compute the OrderNFT contract address via CREATE2.
     */
    function computeTokenAddress(uint256 marketNonce) external view returns (address);

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./CloberOrderKey.sol";

interface CloberOrderNFT is IERC721, IERC721Metadata {
    /**
     * @notice Returns the base URI for the metadata of this NFT collection.
     * @return The base URI for the metadata of this NFT collection.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the address of the market contract that manages this token.
     * @return The address of the market contract that manages this token.
     */
    function market() external view returns (address);

    /**
     * @notice Returns the address of contract owner.
     * @return The address of the contract owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Called when a new token is minted.
     * @param to The receiver address of the minted token.
     * @param tokenId The id of the token minted.
     */
    function onMint(address to, uint256 tokenId) external;

    /**
     * @notice Called when a token is burned.
     * @param tokenId The id of the token burned.
     */
    function onBurn(uint256 tokenId) external;

    /**
     * @notice Changes the base URI for the metadata of this NFT collection.
     * @param newBaseURI The new base URI for the metadata of this NFT collection.
     */
    function changeBaseURI(string memory newBaseURI) external;

    /**
     * @notice Decodes a token id into an order key.
     * @param id The id to decode.
     * @return The order key corresponding to the given id.
     */
    function decodeId(uint256 id) external pure returns (OrderKey memory);

    /**
     * @notice Encodes an order key to a token id.
     * @param orderKey The order key to encode.
     * @return The id corresponding to the given order key.
     */
    function encodeId(OrderKey memory orderKey) external pure returns (uint256);

    /**
     * @notice Cancels orders with token ids.
     * @dev Only the OrderCanceler can call this function.
     * @param from The address of the owner of the tokens.
     * @param tokenIds The ids of the tokens to cancel.
     * @param receiver The address to send the underlying assets to.
     */
    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external;
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";
import "../interfaces/CloberOrderKey.sol";

library OrderKeyUtils {
    function encode(OrderKey memory orderKey) internal pure returns (uint256) {
        return encode(orderKey.isBid, orderKey.priceIndex, orderKey.orderIndex);
    }

    function encode(
        bool isBid,
        uint16 priceIndex,
        uint256 orderIndex
    ) internal pure returns (uint256 id) {
        if (orderIndex > type(uint232).max) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        assembly {
            id := add(orderIndex, add(shl(232, priceIndex), shl(248, isBid)))
        }
    }

    function decode(uint256 id) internal pure returns (OrderKey memory) {
        uint8 isBid;
        uint16 priceIndex;
        uint232 orderIndex;
        assembly {
            orderIndex := id
            priceIndex := shr(232, id)
            isBid := shr(248, id)
        }
        if (isBid > 1) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        return OrderKey({isBid: isBid == 1, priceIndex: priceIndex, orderIndex: orderIndex});
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/**
 * @notice A struct that represents a unique key for an order.
 * @param isBid The flag indicating whether it's a bid order or an ask order.
 * @param priceIndex The price book index.
 * @param orderIndex The order index.
 */
struct OrderKey {
    bool isBid;
    uint16 priceIndex;
    uint256 orderIndex;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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