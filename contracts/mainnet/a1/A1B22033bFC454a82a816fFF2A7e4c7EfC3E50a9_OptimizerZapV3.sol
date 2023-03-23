/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
}

library BoringERC20 {
        bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// Simplified by BoringCrypto

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

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
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

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

interface IPopsicleV3Optimizer {
    function token0() external view returns (address);
    function token1() external view returns (address);
 
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );
}

contract OptimizerZapV3 is Ownable {
    using BoringERC20 for IERC20;

    error ErrSwapFailed0();
    error ErrSwapFailed1();
    
    mapping (address => bool) public approvedTargets;
    address public immutable weth;
    address public immutable eth;

    struct ZapData {
        address tokenIn;
        address to;
        address swapTarget0;
        address swapTarget1;
        IPopsicleV3Optimizer optimizer;
        uint amountIn;
        bytes swapData0;
        bytes swapData1;
    }

    struct Cache {
        address token0;
        address token1;
        uint256 balance0;
        uint256 balance1;
        uint256 balanceIn;
    }

    constructor (address _weth, address _eth){
        weth = _weth;
        eth = _eth;
        approvedTargets[address(0)] = true; // for non-swaps
    }

    function DepositInEth(IPopsicleV3Optimizer optimizer, address to, uint _otherAmount) external payable {
        require(address(optimizer) != address(0), "ONA");
        require(to != address(0), "RNA");

        Cache memory cache;

        cache.balanceIn = msg.value;
        cache.token0 = optimizer.token0();
        cache.token1 = optimizer.token1();
        require(cache.token0 == weth || cache.token1 == weth, "BO");

        IWETH9(weth).deposit{value: cache.balanceIn}();
        _approveToken(weth, address(optimizer), cache.balanceIn);
        if (cache.token0 == weth) {
            IERC20(cache.token1).safeTransferFrom(msg.sender, address(this), _otherAmount);
            _approveToken(cache.token1, address(optimizer), _otherAmount);
            (, uint256 amount0,uint256 amount1) = optimizer.deposit(cache.balanceIn, _otherAmount, to);
            cache.balance0 = cache.balanceIn-amount0;
            cache.balance1 = _otherAmount-amount1;
        } else {
            IERC20(cache.token0).safeTransferFrom(msg.sender, address(this), _otherAmount);
            _approveToken(cache.token0, address(optimizer), _otherAmount);
            (, uint256 amount0,uint256 amount1) = optimizer.deposit(_otherAmount, cache.balanceIn, to);
            cache.balance0 = _otherAmount-amount0;
            cache.balance1 = cache.balanceIn-amount1;
        }
        if (cache.balance0 > 0 ) IERC20(cache.token0).safeTransfer(to, cache.balance0);
        if (cache.balance1 > 0 ) IERC20(cache.token1).safeTransfer(to, cache.balance1);
    }

    function ZapIn(ZapData memory data) external payable {
        require(approvedTargets[data.swapTarget0], "STNA0");
        require(approvedTargets[data.swapTarget1], "STNA1");
        Cache memory cache;
        uint value = msg.value;
        cache.token0 = data.optimizer.token0();
        cache.token1 = data.optimizer.token1();
        cache.balance0 = IERC20(cache.token0).safeBalanceOf(address(this));
        cache.balance1 = IERC20(cache.token1).safeBalanceOf(address(this));
        if (data.tokenIn == eth || data.tokenIn == address(0)) {
            cache.balanceIn = IERC20(weth).safeBalanceOf(address(this));
            IWETH9(weth).deposit{value: value}();
            data.amountIn = value;
            data.tokenIn = weth;
        } else {
            cache.balanceIn = IERC20(data.tokenIn).safeBalanceOf(address(this));
            IERC20(data.tokenIn).safeTransferFrom(msg.sender, address(this), data.amountIn);
        }
        if (data.swapData0.length > 0) {
            _approveToken(data.tokenIn, data.swapTarget0, data.amountIn);
            (bool success, ) = data.swapTarget0.call(data.swapData0);
            if (!success) {
                revert ErrSwapFailed0();
            }
        }
        if (data.swapData1.length > 0) {
            _approveToken(data.tokenIn, data.swapTarget1, data.amountIn);
            (bool success, ) = data.swapTarget1.call(data.swapData1);
            if (!success) {
                revert ErrSwapFailed1();
            }
        }
        cache.balance0 = IERC20(cache.token0).safeBalanceOf(address(this)) - cache.balance0;
        cache.balance1 = IERC20(cache.token1).safeBalanceOf(address(this)) - cache.balance1;
        _approveToken(cache.token0, address(data.optimizer), cache.balance0);
        _approveToken(cache.token1, address(data.optimizer), cache.balance1);
        (, uint amount0, uint amount1) = data.optimizer.deposit(cache.balance0, cache.balance1, data.to);
        cache.balance0 = cache.balance0 - amount0;
        cache.balance1 = cache.balance1 - amount1;
        if (cache.balance0 > 0 ) IERC20(cache.token0).safeTransfer(data.to, cache.balance0);
        if (cache.balance1 > 0 ) IERC20(cache.token1).safeTransfer(data.to, cache.balance1);
        cache.balanceIn = IERC20(data.tokenIn).safeBalanceOf(address(this)) - cache.balanceIn;
        if (cache.balanceIn > 0 ) IERC20(data.tokenIn).safeTransfer(data.to, cache.balanceIn);
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    //Only Owner

    function approveTarget(address _target) external onlyOwner {
        approvedTargets[_target] = true;
    }

    function rejectTarget(address _target) external onlyOwner {
        require(approvedTargets[_target], "TNA");
        approvedTargets[_target] = false;
    }

    function recoverLostToken( IERC20 _token ) external onlyOwner {
        _token.safeTransfer(owner, _token.safeBalanceOf( address(this)));
    }

    function refundETH() external onlyOwner {
        if (address(this).balance > 0) BoringERC20.safeTransferETH(owner, address(this).balance);
    }
}