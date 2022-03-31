/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity ^0.8.4;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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
interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function lock() external;
}interface ISurplusAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(uint256 creditToSell, uint256 bid) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 creditToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock(uint256 credit) external;

    function cancelAuction(uint256 id) external;
}
interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}
/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */
/// @title SurplusAuction
/// @notice
/// Uses Flap.sol from DSS (MakerDAO) as a blueprint
/// Changes from Flap.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract SurplusAuction is Guarded, ISurplusAuction {
    /// ======== Custom Errors ======== ///

    error SurplusAuction__setParam_unrecognizedParam();
    error SurplusAuction__startAuction_notLive();
    error SurplusAuction__startAuction_overflow();
    error SurplusAuction__redoAuction_notFinished();
    error SurplusAuction__redoAuction_bidAlreadyPlaced();
    error SurplusAuction__submitBid_notLive();
    error SurplusAuction__submit_recipientNotSet();
    error SurplusAuction__submitBid_alreadyFinishedBidExpiry();
    error SurplusAuction__submitBid_alreadyFinishedAuctionExpiry();
    error SurplusAuction__submitBid_creditToSellNotMatching();
    error SurplusAuction__submitBid_bidNotHigher();
    error SurplusAuction__submitBid_insufficientIncrease();
    error SurplusAuction__closeAuction_notLive();
    error SurplusAuction__closeAuction_notFinished();
    error SurplusAuction__cancelAuction_stillLive();
    error SurplusAuction__cancelAuction_recipientNotSet();

    /// ======== Storage ======== ///

    // Auction State
    struct Auction {
        // tokens paid for credit [wad]
        uint256 bid;
        // amount of credit to sell for tokens (bid) [wad]
        uint256 creditToSell;
        // current highest bidder
        address recipient;
        // bid expiry time [unix epoch time]
        uint48 bidExpiry;
        // auction expiry time [unix epoch time]
        uint48 auctionExpiry;
    }

    /// @notice State of auctions
    // AuctionId => Auction
    mapping(uint256 => Auction) public override auctions;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Tokens to receive for credit
    IERC20 public immutable override token;

    /// @notice 5% minimum bid increase
    uint256 public override minBidBump = 1.05e18;
    /// @notice 3 hours bid duration [seconds]
    uint48 public override bidDuration = 3 hours;
    /// @notice 2 days total auction length [seconds]
    uint48 public override auctionDuration = 2 days;
    /// @notice Auction Counter
    uint256 public override auctionCounter = 0;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///

    event StartAuction(uint256 id, uint256 creditToSell, uint256 bid);

    constructor(address codex_, address token_) Guarded() {
        codex = ICodex(codex_);
        token = IERC20(token_);
        live = 1;
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "minBidBump") minBidBump = data;
        else if (param == "bidDuration") bidDuration = uint48(data);
        else if (param == "auctionDuration") auctionDuration = uint48(data);
        else revert SurplusAuction__setParam_unrecognizedParam();
    }

    /// ======== Surplus Auction ======== ///

    /// @notice Start a new surplus auction
    /// @dev Sender has to be allowed to call this method
    /// @param creditToSell Amount of credit to sell for tokens [wad]
    /// @param bid Starting bid (in tokens) of the auction [wad]
    /// @return auctionId Id of the started surplus auction
    function startAuction(uint256 creditToSell, uint256 bid) external override checkCaller returns (uint256 auctionId) {
        if (live == 0) revert SurplusAuction__startAuction_notLive();
        if (auctionCounter >= ~uint256(0)) revert SurplusAuction__startAuction_overflow();
        unchecked {
            auctionId = ++auctionCounter;
        }

        auctions[auctionId].bid = bid;
        auctions[auctionId].creditToSell = creditToSell;
        auctions[auctionId].recipient = msg.sender; // configurable??
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), auctionDuration);

        codex.transferCredit(msg.sender, address(this), creditToSell);

        emit StartAuction(auctionId, creditToSell, bid);
    }

    /// @notice Resets an existing surplus auction
    /// @dev Auction expiry has to be exceeded and no bids have to be made
    /// @param auctionId Id of the auction to reset
    function redoAuction(uint256 auctionId) external override {
        if (auctions[auctionId].auctionExpiry >= block.timestamp) revert SurplusAuction__redoAuction_notFinished();
        if (auctions[auctionId].bidExpiry != 0) revert SurplusAuction__redoAuction_bidAlreadyPlaced();
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), auctionDuration);
    }

    /// @notice Bid for the fixed credit amount (`creditToSell`) with a higher amount of tokens (`bid`)
    /// @param auctionId Id of the debt auction
    /// @param creditToSell Amount of credit to receive (has to match)
    /// @param bid Amount of tokens to pay for credit (has to be higher than prev. bid)
    function submitBid(
        uint256 auctionId,
        uint256 creditToSell,
        uint256 bid
    ) external override {
        if (live == 0) revert SurplusAuction__submitBid_notLive();
        if (auctions[auctionId].recipient == address(0)) revert SurplusAuction__submit_recipientNotSet();
        if (auctions[auctionId].bidExpiry <= block.timestamp && auctions[auctionId].bidExpiry != 0)
            revert SurplusAuction__submitBid_alreadyFinishedBidExpiry();
        if (auctions[auctionId].auctionExpiry <= block.timestamp)
            revert SurplusAuction__submitBid_alreadyFinishedAuctionExpiry();

        if (creditToSell != auctions[auctionId].creditToSell)
            revert SurplusAuction__submitBid_creditToSellNotMatching();
        if (bid <= auctions[auctionId].bid) revert SurplusAuction__submitBid_bidNotHigher();
        if (mul(bid, WAD) < mul(minBidBump, auctions[auctionId].bid))
            revert SurplusAuction__submitBid_insufficientIncrease();

        if (msg.sender != auctions[auctionId].recipient) {
            token.transferFrom(msg.sender, auctions[auctionId].recipient, auctions[auctionId].bid);
            auctions[auctionId].recipient = msg.sender;
        }
        token.transferFrom(msg.sender, address(this), sub(bid, auctions[auctionId].bid));

        auctions[auctionId].bid = bid;
        auctions[auctionId].bidExpiry = add48(uint48(block.timestamp), bidDuration);
    }

    /// @notice Closes a finished auction and mints new tokens to the winning bidders
    /// @param auctionId Id of the debt auction to close
    function closeAuction(uint256 auctionId) external override {
        if (live == 0) revert SurplusAuction__closeAuction_notLive();
        if (
            !(auctions[auctionId].bidExpiry != 0 &&
                (auctions[auctionId].bidExpiry < block.timestamp ||
                    auctions[auctionId].auctionExpiry < block.timestamp))
        ) revert SurplusAuction__closeAuction_notFinished();
        codex.transferCredit(address(this), auctions[auctionId].recipient, auctions[auctionId].creditToSell);
        token.transfer(address(0), auctions[auctionId].bid);
        delete auctions[auctionId];
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract and transfer the credit in this contract to the caller
    /// @dev Sender has to be allowed to call this method
    function lock(uint256 credit) external override checkCaller {
        live = 0;
        codex.transferCredit(address(this), msg.sender, credit);
    }

    /// @notice Cancels an existing auction by returning the tokens bid to its bidder
    /// @dev Can only be called when the contract is locked
    /// @param auctionId Id of the surplus auction to cancel
    function cancelAuction(uint256 auctionId) external override {
        if (live == 1) revert SurplusAuction__cancelAuction_stillLive();
        if (auctions[auctionId].recipient == address(0)) revert SurplusAuction__cancelAuction_recipientNotSet();
        token.transferFrom(address(this), auctions[auctionId].recipient, auctions[auctionId].bid);
        delete auctions[auctionId];
    }
}