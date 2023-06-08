pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IDysonPair.sol";
import "interfaces/IWETH.sol";
import "interfaces/IDysonFactory.sol";
import "./SqrtMath.sol";
import "./TransferHelper.sol";

/// @title Router contract for all DysonPair contracts
/// @notice Users are expected to swap, deposit and withdraw via this contract
/// @dev IMPORTANT: Fund stuck or send to this contract is free for grab as `pair` param
/// in each swap functions is passed in and not validated so everyone can implement their
/// own `pair` contract and transfer the fund away.
contract DysonRouter {
    using SqrtMath for *;
    using TransferHelper for address;

    uint private constant MAX_FEE_RATIO = 2**64;
    address public immutable WETH;
    address public immutable DYSON_FACTORY;
    bytes32 public immutable CODE_HASH;

    address public owner;

    event TransferOwnership(address newOwner);

    constructor(address _WETH, address _owner, address _factory) {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        require(_WETH != address(0), "INVALID_WETH");
        WETH = _WETH;
        owner = _owner;
        DYSON_FACTORY = _factory;
        CODE_HASH = IDysonFactory(DYSON_FACTORY).getInitCodeHash();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, bytes32 initCodeHash, address tokenA, address tokenB, uint id) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1, id)), //salt
                initCodeHash
            )))));
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;

        emit TransferOwnership(_owner);
    }

    /// @notice Allow another address to transfer token from this contract
    /// @param tokenAddress Address of token to approve
    /// @param contractAddress Address to grant allowance
    /// @param enable True to enable allowance. False otherwise.
    function rely(address tokenAddress, address contractAddress, bool enable) onlyOwner external {
        tokenAddress.safeApprove(contractAddress, enable ? type(uint).max : 0);
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) onlyOwner external {
        tokenAddress.safeTransfer(to, amount);
    }

    /// @notice This contract can only receive ETH coming from WETH contract,
    /// i.e., when it withdraws from WETH
    receive() external payable {
        require(msg.sender == WETH);
    }

    /// @notice Swap tokenIn for tokenOut
    /// @param tokenIn Address of spent token
    /// @param tokenOut Address of received token
    /// @param index Number of pair instance
    /// @param to Address that will receive tokenOut
    /// @param input Amount of tokenIn to swap
    /// @param minOutput Minimum of tokenOut expected to receive
    /// @return output Amount of tokenOut received
    function swap(address tokenIn, address tokenOut, uint index, address to, uint input, uint minOutput) external returns (uint output) {
        address pair = pairFor(DYSON_FACTORY, CODE_HASH, tokenIn, tokenOut, index);
        (address token0,) = sortTokens(tokenIn, tokenOut);
        tokenIn.safeTransferFrom(msg.sender, address(this), input);
        if(tokenIn == token0)
            output = IDysonPair(pair).swap0in(to, input, minOutput);
        else
            output = IDysonPair(pair).swap1in(to, input, minOutput);
    }

    /// @notice Swap ETH for tokenOut
    /// @param tokenOut Address of received token
    /// @param index Number of pair instance
    /// @param to Address that will receive tokenOut
    /// @param minOutput Minimum of token1 expected to receive
    /// @return output Amount of tokenOut received
    function swapETHIn(address tokenOut, uint index, address to, uint minOutput) external payable returns (uint output) {
        address pair = pairFor(DYSON_FACTORY, CODE_HASH, tokenOut, WETH, index);
        (address token0,) = sortTokens(WETH, tokenOut);
        IWETH(WETH).deposit{value: msg.value}();
        if(WETH == token0)
            output = IDysonPair(pair).swap0in(to, msg.value, minOutput);
        else
            output = IDysonPair(pair).swap1in(to, msg.value, minOutput);
    }

    /// @notice Swap tokenIn for ETH
    /// @param tokenIn Address of spent token
    /// @param index Number of pair instance
    /// @param to Address that will receive ETH
    /// @param input Amount of tokenIn to swap
    /// @param minOutput Minimum of ETH expected to receive
    /// @return output Amount of ETH received
    function swapETHOut(address tokenIn, uint index, address to, uint input, uint minOutput) external returns (uint output) {
        address pair = pairFor(DYSON_FACTORY, CODE_HASH, tokenIn, WETH, index);
        (address token0,) = sortTokens(WETH, tokenIn);
        tokenIn.safeTransferFrom(msg.sender, address(this), input);
        if(WETH == token0)
            output = IDysonPair(pair).swap1in(address(this), input, minOutput);
        else
            output = IDysonPair(pair).swap0in(address(this), input, minOutput);
        IWETH(WETH).withdraw(output);
        to.safeTransferETH(output);
    }

    /// @notice Deposit tokenIn
    /// @param tokenIn Address of spent token
    /// @param tokenOut Address of received token
    /// @param index Number of pair instance
    /// @param to Address that will receive DysonPair note
    /// @param input Amount of tokenIn to deposit
    /// @param minOutput Minimum amount of tokenOut expected to receive if the swap is perfromed
    /// @param time Lock time
    /// @return output Amount of tokenOut received if the swap is performed
    function deposit(address tokenIn, address tokenOut, uint index, address to, uint input, uint minOutput, uint time) external returns (uint output) {
        address pair = pairFor(DYSON_FACTORY, CODE_HASH, tokenIn, tokenOut, index);
        (address token0,) = sortTokens(tokenIn, tokenOut);
        tokenIn.safeTransferFrom(msg.sender, address(this), input);
        if(tokenIn == token0)
            output = IDysonPair(pair).deposit0(to, input, minOutput, time);
        else
            output = IDysonPair(pair).deposit1(to, input, minOutput, time);
    }

    /// @notice Deposit ETH
    /// @param tokenOut Address of received token
    /// @param index Number of pair instance
    /// @param to Address that will receive DysonPair note
    /// @param minOutput Minimum amount of tokenOut expected to receive if the swap is perfromed
    /// @param time Lock time
    /// @return output Amount of tokenOut received if the swap is performed
    function depositETH(address tokenOut, uint index, address to, uint minOutput, uint time) external payable returns (uint output) {
        address pair = pairFor(DYSON_FACTORY, CODE_HASH, tokenOut, WETH, index);
        (address token0,) = sortTokens(WETH, tokenOut);
        IWETH(WETH).deposit{value: msg.value}();
        if(WETH == token0)
            output = IDysonPair(pair).deposit0(to, msg.value, minOutput, time);
        else
            output = IDysonPair(pair).deposit1(to, msg.value, minOutput, time);
    }

    /// @notice Withdrw DysonPair note.
    /// User who signs the withdraw signature must be the one who calls this function
    /// @param pair `Pair` contract address
    /// @param index Index of the note to withdraw
    /// @param to Address that will receive either token0 or token1
    /// @param deadline Deadline when the withdraw signature expires
    /// @param sig Withdraw signature
    /// @return token0Amt Amount of token0 withdrawn
    /// @return token1Amt Amount of token1 withdrawn
    function withdraw(address pair, uint index, address to, uint deadline, bytes calldata sig) external returns (uint token0Amt, uint token1Amt) {
        return IDysonPair(pair).withdrawWithSig(msg.sender, index, to, deadline, sig);
    }

    /// @notice Withdrw DysonPair note and if either token0 or token1 withdrawn is WETH, withdraw from WETH and send ETH to receiver.
    /// User who signs the withdraw signature must be the one who calls this function
    /// @param pair `Pair` contract address
    /// @param index Index of the note to withdraw
    /// @param to Address that will receive either token0 or token1
    /// @param deadline Deadline when the withdraw signature expires
    /// @param sig Withdraw signature
    /// @return token0Amt Amount of token0 withdrawn
    /// @return token1Amt Amount of token1 withdrawn
    function withdrawETH(address pair, uint index, address to, uint deadline, bytes calldata sig) external returns (uint token0Amt, uint token1Amt) {
        (token0Amt, token1Amt) = IDysonPair(pair).withdrawWithSig(msg.sender, index, address(this), deadline, sig);
        address token0 = IDysonPair(pair).token0();
        address token = token0Amt > 0 ? token0 : IDysonPair(pair).token1();
        uint amount = token0Amt > 0 ? token0Amt : token1Amt;
        if (token == WETH) {
            IWETH(WETH).withdraw(amount);
            to.safeTransferETH(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    /// @notice Calculate the price of token1 in token0
    /// Formula:
    /// amount1 = amount0 * reserve1 * sqrt(1-fee0) / reserve0 / sqrt(1-fee1)
    /// which can be transformed to:
    /// amount1 = sqrt( amount0**2 * (1-fee0) / (1-fee1) ) * reserve1 / reserve0
    /// @param pair `Pair` contract address
    /// @param token0Amt Amount of token0
    /// @return token1Amt Amount of token1
    function fairPrice(address pair, uint token0Amt) external view returns (uint token1Amt) {
        (uint reserve0, uint reserve1) = IDysonPair(pair).getReserves();
        (uint64 _fee0, uint64 _fee1) = IDysonPair(pair).getFeeRatio();
        return (token0Amt**2 * (MAX_FEE_RATIO - _fee0) / (MAX_FEE_RATIO - _fee1)).sqrt() * reserve1 / reserve0;
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IDysonPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getFeeRatio() external view returns(uint64, uint64);
    function getReserves() external view returns (uint reserve0, uint reserve1);
    function deposit0(address to, uint input, uint minOutput, uint time) external returns (uint output);
    function deposit1(address to, uint input, uint minOutput, uint time) external returns (uint output);
    function swap0in(address to, uint input, uint minOutput) external returns (uint output);
    function swap1in(address to, uint input, uint minOutput) external returns (uint output);
    function withdraw(uint index) external returns (uint token0Amt, uint token1Amt);
    function withdrawWithSig(address from, uint index, address to, uint deadline, bytes calldata sig) external returns (uint token0Amt, uint token1Amt);
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT
import "interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IDysonFactory {
    function controller() external returns (address);
    function getInitCodeHash() external view returns (bytes32);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

//https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
library SqrtMath {
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // This segment is to get a reasonable initial estimate for the Babylonian method.
            // If the initial estimate is bad, the number of correct bits increases ~linearly
            // each iteration instead of ~quadratically.
            // The idea is to get z*z*y within a small factor of x.
            // More iterations here gets y in a tighter range. Currently, we will have
            // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
            // between y and y+1 is small. If x < 256 this is not possible, but those cases
            // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := x
            // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
            // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
            // and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

            // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
            // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

            // Run the Babylonian method seven times. This should be enough given initial estimate.
            // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
            // The solmate implementation assigns zRoundDown := div(x, z) first, but
            // since this case is rare, we choose to save gas on the assignment and
            // repeat division in the rare case.
            // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(x, z), z) {
                z := div(x, z)
            }
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}