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

pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Errors
error Conversion_Expired();
error Only_Stream_Owner();
error Invalid_Stream_Owner();
error Invalid_Recipient();
error Invalid_Stream_StartTime();
error Invalid_Token_Decimals();

// Interfaces
interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/// Converts a token to another token where the conversion price is fixed and the output token is streamed to the
/// owner over a fixed duration.
contract TokenConversion is Ownable {
    // Constants
    address public immutable tokenIn; // the token to deposit
    address public immutable tokenOut; // the token to stream
    uint256 public immutable rate; // tokenIn (in tokenIn precision) that converts to 1 tokenOut (in tokenOut precision)
    uint256 public immutable duration; // the vesting duration
    uint256 public immutable expiration; // expiration of the conversion program

    // Structs
    struct Stream {
        uint128 total; // expressed in tokenOut precision
        uint128 claimed; // expressed in tokenOut precision
    }

    // Storage vars
    // Stream owner and startTime is encoded in streamId
    mapping(uint256 => Stream) public streams;

    // Events
    event Convert(
        uint256 indexed streamId,
        address indexed sender,
        address indexed owner,
        uint256 amountIn,
        uint256 amountOut
    );
    event Withdraw(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );
    event UpdateStreamOwner(
        uint256 indexed streamId,
        uint256 indexed newStreamId
    );

    /// Instantiates a new converter contract with an owner
    /// @dev owner is able to withdraw tokenOut from the conversion contract
    constructor(
        address _tokenIn,
        address _tokenOut,
        uint256 _rate,
        uint256 _duration,
        uint256 _expiration,
        address _owner
    ) {
        // initialize conversion terms
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        rate = _rate;
        duration = _duration;
        expiration = _expiration;

        // Sanity checks
        if (IERC20Metadata(tokenIn).decimals() != 18)
            revert Invalid_Token_Decimals();
        if (IERC20Metadata(tokenOut).decimals() != 18)
            revert Invalid_Token_Decimals();

        transferOwnership(_owner);
    }

    /// Burns `amount` of tokenIn tokens and creates a new stream of tokenOut
    /// tokens claimable by `owner` over the stream `duration`
    /// @param amount The amount of tokenIn to convert (in tokenIn precision)
    /// @param owner The owner of the new stream
    /// @return streamId Encoded identifier of the stream [owner, startTime]
    function convert(uint256 amount, address owner)
        external
        returns (uint256 streamId)
    {
        // assert conversion is not expired
        if (block.timestamp > expiration) revert Conversion_Expired();

        // don't convert to zero address
        if (owner == address(0)) revert Invalid_Stream_Owner();

        // compute stream amount
        // rate converts from tokenIn precision to tokenOut precision
        uint256 amountOut = amount / rate;

        // create new stream or add to existing stream created in same block
        streamId = encodeStreamId(owner, uint64(block.timestamp));
        Stream storage stream = streams[streamId];
        // this is safe bc tokenOut totalSupply is only 10**7
        stream.total = uint128(amountOut + stream.total);

        // burn deposited tokens
        // reverts if insufficient allowance or balance
        IERC20Burnable(tokenIn).burnFrom(msg.sender, amount);
        emit Convert(streamId, msg.sender, owner, amount, amountOut);
    }

    /// Withdraws claimable tokenOut tokens to the stream's `owner`
    /// @param streamId The encoded identifier of the stream to claim from
    /// @return claimed The amount of tokens claimed
    /// @dev Reverts if not called by the stream's `owner`
    function claim(uint256 streamId) external returns (uint256 claimed) {
        Stream memory stream = streams[streamId];
        (address streamOwner, uint64 startTime) = decodeStreamId(streamId);

        // withdraw claimable amount
        return _claim(stream, streamId, streamOwner, streamOwner, startTime);
    }

    /// Withdraws claimable tokenOut tokens to a designated `recipient`
    /// @param streamId The encoded identifier of the stream to claim from
    /// @param recipient The recipient of the claimed token amount
    /// @return claimed The amount of tokens claimed
    /// @dev Reverts if not called by the stream's `owner`
    function claim(uint256 streamId, address recipient)
        external
        returns (uint256 claimed)
    {
        // don't claim to zero address
        if (recipient == address(0)) revert Invalid_Recipient();

        Stream memory stream = streams[streamId];
        (address streamOwner, uint64 startTime) = decodeStreamId(streamId);

        // withdraw claimable amount
        return _claim(stream, streamId, streamOwner, recipient, startTime);
    }

    // Implementation of the claim feature
    function _claim(
        Stream memory stream,
        uint256 streamId,
        address streamOwner,
        address recipient,
        uint64 startTime
    ) private returns (uint256 claimed) {
        // check owner
        if (msg.sender != streamOwner) revert Only_Stream_Owner();

        // compute claimable amount and update stream
        claimed = _claimableBalance(stream, startTime);
        stream.claimed = uint128(stream.claimed + claimed);
        streams[streamId] = stream;

        // withdraw claimable amount
        // reverts if insufficient balance
        IERC20(tokenOut).transfer(recipient, claimed);
        emit Withdraw(streamId, recipient, claimed);
    }

    /// Transfers stream to a new owner
    /// @param streamId The encoded identifier of the stream to transfer to a new owner
    /// @param owner The new owner of the stream
    /// @return newStreamId New identifier of the stream [newOwner, startTime]
    /// @dev Reverts if not called by the stream's `owner`
    function transferStreamOwnership(uint256 streamId, address owner)
        external
        returns (uint256 newStreamId)
    {
        // don't transfer stream to zero address
        if (owner == address(0)) revert Invalid_Stream_Owner();

        Stream memory stream = streams[streamId];
        (address currentOwner, uint64 startTime) = decodeStreamId(streamId);

        // only stream owner is allowed to update ownership
        if (currentOwner != msg.sender) revert Only_Stream_Owner();

        // store stream with new streamId or add to existing stream
        newStreamId = encodeStreamId(owner, startTime);

        Stream memory newStream = streams[newStreamId];
        newStream.total += stream.total;
        newStream.claimed += stream.claimed;
        streams[newStreamId] = newStream;

        delete streams[streamId];
        emit UpdateStreamOwner(streamId, newStreamId);
    }

    // Owner methods

    /// Withdraws `amount` of tokenOut to owner
    /// @param amount The amount of tokens to withdraw from the conversion contract
    /// @dev Reverts if not called by the contract's `owner`
    /// @dev This is used in two scenarios:
    /// - Emergency such as a vulnerability in the contract
    /// - Recover unconverted funds
    function withdraw(uint256 amount) external onlyOwner {
        // reverts if insufficient balance
        IERC20(tokenOut).transfer(owner(), amount);
    }

    // View methods

    /// Returns the claimable balance for a stream
    /// @param streamId The encoded identifier of the stream to view `claimableBalance` of
    /// @return claimable The amount of tokens claimable
    function claimableBalance(uint256 streamId)
        external
        view
        returns (uint256 claimable)
    {
        (, uint64 startTime) = decodeStreamId(streamId);
        return _claimableBalance(streams[streamId], startTime);
    }

    // Implementation of claimableBalance query
    function _claimableBalance(Stream memory stream, uint64 startTime)
        private
        view
        returns (uint256 claimable)
    {
        uint256 endTime = startTime + duration;
        if (block.timestamp <= startTime) {
            revert Invalid_Stream_StartTime();
        } else if (endTime <= block.timestamp) {
            claimable = stream.total - stream.claimed;
        } else {
            uint256 diffTime = block.timestamp - startTime;
            claimable = (stream.total * diffTime) / duration - stream.claimed;
        }
    }

    /// @notice Encodes `owner` and `startTime` as `streamId`
    /// @param owner Owner of the stream
    /// @param startTime Stream startTime timestamp
    /// @return streamId Encoded identifier of the stream [owner, startTime]
    function encodeStreamId(address owner, uint64 startTime)
        public
        pure
        returns (uint256 streamId)
    {
        unchecked {
            streamId = (uint256(uint160(owner)) << 96) + startTime;
        }
    }

    /// @notice Decodes the `owner` and `startTime` from `streamId`
    /// @param streamId The encoded stream identifier consisting of [owner, startTime]
    /// @return owner owner extracted from `streamId`
    /// @return startTime startTime extracted from `streamId`
    function decodeStreamId(uint256 streamId)
        public
        pure
        returns (address owner, uint64 startTime)
    {
        owner = address(uint160(uint256(streamId >> 96)));
        startTime = uint64(streamId);
    }
}