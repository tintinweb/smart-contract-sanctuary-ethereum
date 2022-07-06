//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICheapSwapRouterV3.sol";
import "./interfaces/ICheapSwapAddress.sol";
import "./lib/ISwapRouter.sol";
import "./lib/IWETH.sol";
import "./lib/CheapSwapRouterBytesLib.sol";

contract CheapSwapRouterV3 is ICheapSwapRouterV3 {
    using CheapSwapRouterBytesLib for bytes;

    // uniswapV3 Router
    ISwapRouter public Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // WETH
    IWETH9 public WETH;

    constructor() {
        WETH = IWETH9(Router.WETH9());
        // WETH 授权给 Router
        IERC20(address(WETH)).approve(address(Router), type(uint256).max);
    }

    /* =================== UTIL FUNCTIONS =================== */

    function _preSwap(bool isPer, bool isInput)
        internal
        returns (
            address,
            address,
            uint120,
            uint120,
            bytes memory
        )
    {
        (uint80 callMsgValue, uint120 amountOut, uint120 amountIn, bytes memory path) = getSwapData(
            msg.data,
            msg.value
        );
        ICheapSwapAddress cheapSwapAddress = ICheapSwapAddress(msg.sender);
        address owner = cheapSwapAddress.owner();
        address tokenIn;
        // 获取卖出代币
        if (msg.value > 0) {
            WETH.deposit{value: amountIn}();
        } else {
            if (isInput) {
                tokenIn = path.toAddress(0);
            } else {
                tokenIn = path.toAddress(23);
            }
            if (isPer && amountIn == 0) {
                amountIn = uint120(IERC20(tokenIn).balanceOf(owner));
            }
            // 从 owner 获取数量为 amountIn 的 tokenIn
            cheapSwapAddress.call(
                callMsgValue,
                tokenIn,
                abi.encodeWithSignature("transferFrom(address,address,uint256)", owner, address(this), amountIn)
            );
            if (IERC20(tokenIn).allowance(address(this), address(Router)) == 0) {
                IERC20(tokenIn).approve(address(Router), type(uint256).max);
            }
        }
        return (owner, tokenIn, amountOut, amountIn, path);
    }

    /* =================== VIEW FUNCTIONS =================== */

    function getSwapData(bytes calldata msgData, uint256 msgValue)
        public
        pure
        override
        returns (
            uint80 callMsgValue,
            // 买入数量
            uint120 amountOut,
            // 卖出数量
            uint120 amountIn,
            // 交易路径
            bytes memory path
        )
    {
        callMsgValue = msgData.toUint80(4);
        amountOut = msgData.toUint120(14);
        if (msgValue > 0) {
            amountIn = uint120(msgValue);
            path = msgData.slice(29, msgData.length - 29);
        } else {
            amountIn = msgData.toUint120(29);
            path = msgData.slice(44, msgData.length - 44);
        }
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function exactInput() external payable {
        (address owner, , uint120 amountOutMin, uint120 amountIn, bytes memory path) = _preSwap(false, true);
        // 执行 swap
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: owner,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });
        Router.exactInput(params);
    }

    function exactPerAmountIn() external payable {
        (address owner, , uint120 amountOutMinPerAmountIn, uint120 amountIn, bytes memory path) = _preSwap(true, true);
        // 执行 swap
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: owner,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: (amountIn * amountOutMinPerAmountIn) / 10**18
        });
        Router.exactInput(params);
    }

    function exactOutput() external payable {
        (address owner, address tokenIn, uint120 amountOut, uint120 amountInMax, bytes memory path) = _preSwap(
            false,
            false
        );
        // 执行 swap
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: owner,
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: amountInMax
        });
        uint256 amountIn = Router.exactOutput(params);
        uint256 amount = amountInMax - amountIn;
        // 退回多余代币
        if (amount > 0) {
            if (msg.value > 0) {
                WETH.withdraw(amount);
                payable(owner).transfer(amount);
            } else {
                IERC20(tokenIn).transfer(owner, amount);
            }
        }
    }

    receive() external payable {
        require(msg.sender == address(WETH), "CheapSwapRouterV3: not WETH");
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
pragma solidity ^0.8.12;

interface ICheapSwapRouterV3 {
    /* =================== VIEW FUNCTIONS =================== */

    function getSwapData(bytes calldata msgData, uint256 msgValue)
        external
        pure
        returns (
            uint80 callMsgValue,
            uint120 amountOut,
            uint120 amountIn,
            bytes memory path
        );

    /* ================ TRANSACTION FUNCTIONS ================ */

    function exactInput() external payable;

    function exactPerAmountIn() external payable;

    function exactOutput() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapAddress {
    /* ==================== EVENTS =================== */

    event SetTargetData(uint256 indexed value, bytes targetData);

    event SetPause(bool isPause);

    /* ==================== VIEW FUNCTIONS =================== */

    function owner() external view returns (address);

    function getTargetData(uint256 msgValue)
        external
        view
        returns (
            uint8 runTime,
            uint8 maxRunTime,
            uint40 deadline,
            address target,
            uint80 value,
            bytes memory data
        );

    /* ================ TRANSACTION FUNCTIONS ================ */

    function doReceive() external payable;

    function call(
        uint256 callMsgValue,
        address target,
        bytes calldata data
    ) external payable;

    /* ===================== ADMIN FUNCTIONS ==================== */

    function setPause(bool isPause) external;

    function setTargetData(
        uint256 msgValue,
        uint8 maxRunTime,
        uint40 deadline,
        address target,
        uint80 value,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface ISwapRouter {
    function WETH9() external view returns (address);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0;

library CheapSwapRouterBytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint80(bytes memory _bytes, uint256 _start) internal pure returns (uint80) {
        require(_start + 10 >= _start, "toUint80_overflow");
        require(_bytes.length >= _start + 10, "toUint80_outOfBounds");
        uint80 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xa), _start))
        }

        return tempUint;
    }

    function toUint120(bytes memory _bytes, uint256 _start) internal pure returns (uint120) {
        require(_start + 15 >= _start, "toUint120_overflow");
        require(_bytes.length >= _start + 15, "toUint120_outOfBounds");
        uint120 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xf), _start))
        }

        return tempUint;
    }
}