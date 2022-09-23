// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;
import "../IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "../trade_utils.sol";

interface ISwapRouter2 {
	/// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
	/// @dev The `msg.value` should not be trusted for any method callable from multicall.
	/// @param deadline The time by which this function must be called before failing
	/// @param data The encoded function data for each of the calls to make to this contract
	/// @return results The results from each of the calls passed in via data
	function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

	/// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
	/// @dev The `msg.value` should not be trusted for any method callable from multicall.
	/// @param previousBlockhash The expected parent blockHash
	/// @param data The encoded function data for each of the calls to make to this contract
	/// @return results The results from each of the calls passed in via data
	// function multicall(bytes32 previousBlockhash, bytes[] calldata data)
	// external
	// payable
	// returns (bytes[] memory results);
	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
	function WETH9() external returns(address);
}

interface Wmatic is IERC20 {
	function withdraw(uint256 amount) external;
}

contract UniswapProxy is Executor {
	using Path for bytes;
	// Variables
	address constant public ETH_CONTRACT_ADDRESS = 0x0000000000000000000000000000000000000000;
	uint constant public MAX = uint(-1);
	ISwapRouter2 public swaprouter02;
	Wmatic public wmatic;

	struct CallSummary {
		address to;
		address token;
		uint256 amount;
		bytes data;
	}

	/**
     * @dev Contract constructor
     * @param _swaproute02 uniswap routes contract address
     */
	constructor(ISwapRouter2 _swaproute02) payable {
		swaprouter02 = _swaproute02;
		wmatic = Wmatic(swaprouter02.WETH9());
	}

	function tradeInputSingle(ISwapRouter2.ExactInputSingleParams calldata params, bool isNative) external payable returns(address, uint) {
		checkApproved(IERC20(params.tokenIn), params.amountIn);
		uint amountOut = swaprouter02.exactInputSingle{value: msg.value}(params);
		require(amountOut >= params.amountOutMinimum, "lower than expected output");
		address returnToken = withdrawMatic(params.tokenOut, amountOut, isNative);
		return (returnToken, amountOut);
	}

	function tradeInput(ISwapRouter2.ExactInputParams calldata params, bool isNative) external payable returns(address, uint) {
		(address tokenIn,,) = params.path.decodeFirstPool();
		checkApproved(IERC20(tokenIn), params.amountIn);
		uint amountOut = swaprouter02.exactInput{value: msg.value}(params);
		bytes memory tempPath = params.path;
		address returnToken;
		while (true) {
			bool hasMultiplePools = tempPath.hasMultiplePools();
			// decide whether to continue or terminate
			if (hasMultiplePools) {
				tempPath = tempPath.skipToken();
			} else {
				(,returnToken,) = tempPath.decodeFirstPool();
				break;
			}
		}
		returnToken = withdrawMatic(returnToken, amountOut, isNative);
		return (returnToken, amountOut);
	}

	function multiTrades(uint256 deadline, bytes[] calldata data, IERC20 sellToken, address buyToken, uint256 sellAmount, bool isNative) external payable returns(address, uint) {
		checkApproved(sellToken, sellAmount);
		uint256 amountOut;
		bytes[] memory results = swaprouter02.multicall{value: msg.value}(deadline, data);
		for (uint i = 0; i < results.length; i++) {
			amountOut += abi.decode(results[i], (uint256));
		}
		address returnToken = withdrawMatic(buyToken, amountOut, isNative);

		return (returnToken, amountOut);
	}

	function _inspectTradeInputSingle(ISwapRouter2.ExactInputSingleParams calldata params, bool isNative) external view returns (bytes memory, CallSummary memory) {
		bytes memory rdata = abi.encodeWithSelector(0x421f4388, params, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), params.tokenIn, params.amountIn,
			abi.encodeWithSelector(0x04e45aaf, params)
		);
		return (rdata, cs);
	}

	function _inspectTradeInput(ISwapRouter2.ExactInputParams calldata params, bool isNative) external view returns(bytes memory, CallSummary memory) {
		(address tokenIn,,) = params.path.decodeFirstPool();
		bytes memory rdata = abi.encodeWithSelector(0xc8dc75e6, params, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), tokenIn, params.amountIn,
			abi.encodeWithSelector(0xb858183f, params)
		);
		return (rdata, cs);
	}

	function _inspectMultiTrades(uint256 deadline, bytes[] calldata data, IERC20 sellToken, address buyToken, uint256 sellAmount, bool isNative) external view returns (bytes memory, CallSummary memory) {
		bytes memory rdata = abi.encodeWithSelector(0x92171fd8, block.timestamp + 1000000000, data, sellToken, buyToken, sellAmount, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), address(sellToken), sellAmount,
			abi.encodeWithSelector(0x5ae401dc, block.timestamp + 1000000000, data)
		);
		return (rdata, cs);
	}

	function checkApproved(IERC20 srcToken, uint256 amount) internal {
		if (msg.value == 0 && srcToken.allowance(address(this), address(swaprouter02)) < amount) {
			srcToken.approve(address(swaprouter02), MAX);
		}
	}

	function withdrawMatic(address tokenOut, uint256 amountOut, bool isNative) internal returns(address returnToken) {
		if (tokenOut == address(wmatic) && isNative) {
			// convert wmatic to matic
			// recipient in params must be this contract
			wmatic.withdraw(amountOut);
			returnToken = ETH_CONTRACT_ADDRESS;
			transfer(returnToken, amountOut);
		} else {
			returnToken = tokenOut;
		}
	}

	function transfer(address token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount, "IUP: transfer amount exceeds balance");
			(bool success, ) = msg.sender.call{value: amount}("");
			require(success, "IUP: transfer failed");
		} else {
			IERC20(token).transfer(msg.sender, amount);
			require(checkSuccess(), "IUP: transfer token failed");
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
	function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
		// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
			// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

			// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}

	/**
     * @dev Payable receive function to receive Ether from oldVault when migrating
     */
	receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint amount) external;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

pragma solidity >=0.6.12 <=0.8.9;

import './IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TradeUtils {
	IERC20 constant public ETH_CONTRACT_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

	function balanceOf(IERC20 token) internal view returns (uint256) {
		if (token == ETH_CONTRACT_ADDRESS) {
			return address(this).balance;
		}
        return token.balanceOf(address(this));
    }

	function transfer(IERC20 token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount);
			(bool success, ) = msg.sender.call{value: amount}("");
          	require(success);
		} else {
			token.transfer(msg.sender, amount);
			require(checkSuccess());
		}
	}

	function approve(IERC20 token, address proxy, uint amount) internal {
		if (token != ETH_CONTRACT_ADDRESS) {
			token.approve(proxy, 0);
			require(checkSuccess());
			token.approve(proxy, amount);
			require(checkSuccess());
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
    function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
			// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
				// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

				// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}
}

abstract contract Executor is Ownable {
	mapping (address => bool) public dappAddresses;

	constructor() internal {
		dappAddresses[address(this)] = true;
	}

	function addDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = true;
	}

	function removeDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = false;
	}

	function dappExists(address addr) public view returns (bool) {
		return dappAddresses[addr];
	}

    function execute(address fns, bytes calldata data) external payable returns (bytes memory) {
    	require(dappExists(fns), "Executor:DNE"); // dapp does not exist
        (bool success, bytes memory result) = fns.delegatecall(data);
        if (!success) {
        	// Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}