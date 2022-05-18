// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/ISushiMakerAuction.sol";

// TODO: add unchecked to satisfy some people gas thirst
// TODO: address(0) checks?
// TODO: slot packing
// TODO: cross-check scenarios with bug/vuln list? do we need non reentrant?
// TODO: do we need non reentrant?

// custom errors
error LPTokenNotAllowed();
error BidTokenNotAllowed();
error InsufficientBidAmount();
error BidAlreadyStarted();
error BidNotStarted();
error BidFinished();
error BidNotFinished();

contract SushiMakerAuction is
    ISushiMakerAuction,
    BoringBatchable,
    BoringOwnable,
    ReentrancyGuard
{
    uint128 public stakedBidToken;

    mapping(IERC20 => Bid) public bids;
    mapping(IERC20 => bool) public whitelistedTokens;

    address public receiver;
    IERC20 public immutable bidToken;
    address public immutable factory;
    bytes32 public immutable pairCodeHash;

    uint256 private constant MIN_BID = 1000;
    uint256 private constant MIN_BID_THRESHOLD = 1e15;
    uint256 private constant MIN_BID_THRESHOLD_PRECISION = 1e18;

    uint64 private constant minTTL = 10 minutes;
    uint64 private constant maxTTL = 20 minutes;

    modifier onlyToken(IERC20 token) {
        // Any cleaner way to find if it's a LP?
        if (!whitelistedTokens[token]) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSignature("token0()")
            );
            if (success && result.length == 32) revert LPTokenNotAllowed();
        }
        _;
    }

    constructor(
        address _receiver,
        IERC20 _bidToken,
        address _factory,
        bytes32 _pairCodeHash
    ) {
        receiver = _receiver;
        bidToken = _bidToken;
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    function start(
        IERC20 token,
        uint128 bidAmount,
        address to
    ) external override onlyToken(token) nonReentrant {
        if (token == bidToken) revert BidTokenNotAllowed();

        if (bidAmount < MIN_BID) revert InsufficientBidAmount();

        Bid storage bid = bids[token];

        if (bid.bidder != address(0)) revert BidAlreadyStarted();

        bidToken.transferFrom(msg.sender, address(this), bidAmount);

        bid.bidder = to;
        bid.bidAmount = bidAmount;
        bid.rewardAmount = uint128(token.balanceOf(address(this)));
        bid.minTTL = uint64(block.timestamp) + minTTL;
        bid.maxTTL = uint64(block.timestamp) + maxTTL;

        stakedBidToken += bidAmount;

        emit Started(token, msg.sender, bidAmount, bid.rewardAmount);
    }

    function placeBid(
        IERC20 token,
        uint128 bidAmount,
        address to
    ) external override nonReentrant {
        Bid storage bid = bids[token];

        if (bid.bidder == address(0)) revert BidNotStarted();
        if (bid.minTTL <= block.timestamp || bid.maxTTL <= block.timestamp)
            revert BidFinished();
        if (
            (bid.bidAmount +
                ((bid.bidAmount * MIN_BID_THRESHOLD) /
                    MIN_BID_THRESHOLD_PRECISION)) > bidAmount
        ) revert InsufficientBidAmount();

        stakedBidToken += bidAmount - bid.bidAmount;

        bidToken.transferFrom(msg.sender, address(this), bidAmount);
        bidToken.transfer(bid.bidder, bid.bidAmount);

        bid.bidder = to;
        bid.bidAmount = bidAmount;
        bid.minTTL = uint64(block.timestamp) + minTTL;

        emit PlacedBid(token, msg.sender, bidAmount);
    }

    function end(IERC20 token) external override nonReentrant {
        Bid memory bid = bids[token];

        if (bid.bidder == address(0)) revert BidNotStarted();

        if (bid.minTTL > block.timestamp && bid.maxTTL > block.timestamp)
            revert BidNotFinished();

        token.transfer(bid.bidder, bid.rewardAmount);

        bidToken.transfer(receiver, bid.bidAmount);

        stakedBidToken -= bid.bidAmount;

        emit Ended(token, bid.bidder, bid.bidAmount);

        delete bids[token];
    }

    function unwindLP(address token0, address token1) external override {
        IUniswapV2Pair pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, token0, token1, pairCodeHash)
        );
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));
    }

    function skimBidToken() external override {
        bidToken.transfer(
            receiver,
            bidToken.balanceOf(address(this)) - stakedBidToken
        );
    }

    function updateReceiver(address newReceiver) external override onlyOwner {
        receiver = newReceiver;
    }

    function updateWhitelistToken(IERC20 token, bool status)
        external
        override
        onlyOwner
    {
        whitelistedTokens[token] = status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/UniswapV2Library.sol";
import "../utils/BoringOwnable.sol";
import "../utils/BoringBatchable.sol";

interface ISushiMakerAuction {
    function start(
        IERC20 token,
        uint128 bidAmount,
        address to
    ) external;

    function placeBid(
        IERC20 token,
        uint128 bidAmount,
        address to
    ) external;

    function end(IERC20 token) external;

    function unwindLP(address token0, address token1) external;

    function skimBidToken() external;

    function updateReceiver(address newReceiver) external;

    function updateWhitelistToken(IERC20 token, bool status) external;

    struct Bid {
        address bidder;
        uint128 bidAmount;
        uint128 rewardAmount;
        uint64 minTTL;
        uint64 maxTTL;
    }

    event Started(
        IERC20 indexed token,
        address indexed bidder,
        uint128 indexed bidAmount,
        uint128 rewardAmount
    );

    event PlacedBid(
        IERC20 indexed token,
        address indexed bidder,
        uint128 indexed bidAmount
    );

    event Ended(
        IERC20 indexed token,
        address indexed bidder,
        uint128 indexed bidAmount
    );
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True.
    /// Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(
                newOwner != address(0) || renounce,
                "Ownable: zero address"
            );

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(
            msg.sender == _pendingOwner,
            "Ownable: caller != pending owner"
        );

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "../interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context,
    // so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}