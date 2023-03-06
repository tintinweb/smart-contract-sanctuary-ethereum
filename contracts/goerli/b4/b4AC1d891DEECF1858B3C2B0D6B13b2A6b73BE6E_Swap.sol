//
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IPancakeV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Swap is Ownable {
    struct LimitLock {
        uint256 amountIn;
        uint256 slippage;
        address tokenIn;
        address tokenOut;
        address user;
    }

    struct P2PLock {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        address sender;
        address receiver;
    }

    using SafeMath for uint256;

    uint256 public fee;
    IPancakeV2Router router;
    address Volt = 0x6070697491550f24E68C4eb5F461827c87978022;
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;

    LimitLock[] public limitlocks;
    P2PLock[] public p2plocks;

    event LimitDeposit(address indexed user, uint256 indexed lockId);
    event LimitWithdraw(address indexed user, uint256 indexed lockId);
    event LimitRefund(address indexed user, uint256 indexed lockId);

    event P2PDeposit(address indexed user, uint256 indexed lockId);
    event P2PRefund(address indexed user, uint256 indexed lockId);
    event P2PAccept(address indexed user, uint256 indexed lockId);

    constructor() {
        // router = IPancakeV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // test uniswap router address
        router = IPancakeV2Router(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // test pancake router address
        fee = 50;
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 slippage
    ) public {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        ///////////////////0.05% fee
        uint256 feeAmount = (amountIn * fee) / 10000;
        uint256 slippageAmount = (amountIn * slippage) / 1000;
        feeAmount += slippageAmount;
        IERC20(tokenIn).approve(address(router), amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn.sub(feeAmount),
            0,
            path,
            msg.sender,
            block.timestamp
        );

        path[0] = tokenIn;
        path[1] = Volt;
        uint256 oldAmt = IERC20(Volt).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            feeAmount / 2,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 delta = IERC20(Volt).balanceOf(address(this)).sub(oldAmt);

        IERC20(Volt).transfer(deadAddress, delta);
        IERC20(tokenIn).transfer(deadAddress, feeAmount / 2);
    }

    function p2p(
        address tokenIn,
        address toAddr,
        uint256 amountIn
    ) public {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        /////////////0.05% fee
        uint256 feeAmount = (amountIn * fee) / 10000;
        IERC20(tokenIn).transfer(toAddr, amountIn - feeAmount);
    }

    function limitDeposit(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 slippage
    ) public {
        require(
            IERC20(tokenIn).balanceOf(msg.sender) >= amountIn,
            "Swap: Not Enough Amount"
        );
        uint256 prevAmount = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        uint256 afterAmount = IERC20(tokenIn).balanceOf(address(this));
        limitlocks.push();
        uint256 index = limitlocks.length - 1;
        LimitLock storage _limitlock = limitlocks[index];
        _limitlock.amountIn = afterAmount - prevAmount;
        _limitlock.tokenIn = tokenIn;
        _limitlock.tokenOut = tokenOut;
        _limitlock.slippage = slippage;
        _limitlock.user = msg.sender;
        emit LimitDeposit(msg.sender, index);
    }

    function limitWithdraw(uint256 index, bool isSwap, uint256 isNativeToken) public onlyOwner {
        require(limitlocks[index].amountIn != 0, "Swap : There is no Amount");
        LimitLock storage _limitlock = limitlocks[index];
        if (isSwap) {
            address[] memory path = new address[](2);
            path[0] = _limitlock.tokenIn;
            path[1] = _limitlock.tokenOut;
            uint256 amountIn = _limitlock.amountIn;
            uint256 slippage = _limitlock.slippage;

            uint256 feeAmount = (_limitlock.amountIn * fee) / 10000;
            uint256 slippageAmount = (_limitlock.amountIn * slippage) / 1000;
            feeAmount += slippageAmount;
            IERC20(_limitlock.tokenIn).approve(address(router), amountIn.sub(feeAmount));
            if (isNativeToken == 1) { // token to token
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn.sub(feeAmount),
                    0,
                    path,
                    _limitlock.user,
                    block.timestamp
                );
            } else if (isNativeToken == 2) { // Native to token
                router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                    0,
                    path,
                    _limitlock.user,
                    block.timestamp
                );
            } else if (isNativeToken == 3) { // token to Native
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn.sub(feeAmount),
                    0,
                    path,
                    _limitlock.user,
                    block.timestamp
                );
            }
        } else {
            uint256 feeAmount = (_limitlock.amountIn * fee) / 10000;
            IERC20(_limitlock.tokenIn).transfer(
                _limitlock.user,
                _limitlock.amountIn.sub(feeAmount)
            );
        }
        _limitlock.amountIn = 0;
        emit LimitWithdraw(_limitlock.user, index);
    }

    function limitRefund(uint256 index) public onlyOwner {
        require(limitlocks[index].amountIn != 0, "Swap : There is no Amount");
        LimitLock storage _limitlock = limitlocks[index];
        uint256 feeAmount = (_limitlock.amountIn * fee) / 10000;

        IERC20(_limitlock.tokenIn).transfer(
            _limitlock.user,
            _limitlock.amountIn.sub(feeAmount)
        );
        _limitlock.amountIn = 0;
        emit LimitRefund(_limitlock.user, index);
    }

    function p2pDeposit(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        address receiver
    ) public {
        require(
            IERC20(tokenIn).balanceOf(msg.sender) >= amountIn,
            "Swap: Not Enough Amount"
        );
        uint256 prevAmount = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        uint256 afterAmount = IERC20(tokenIn).balanceOf(address(this));
        p2plocks.push();
        uint256 index = p2plocks.length - 1;
        P2PLock storage _p2plock = p2plocks[index];
        _p2plock.amountIn = afterAmount - prevAmount;
        _p2plock.tokenIn = tokenIn;
        _p2plock.tokenOut = tokenOut;
        _p2plock.amountOut = amountOut;
        _p2plock.sender = msg.sender;
        _p2plock.receiver = receiver;
        emit P2PDeposit(msg.sender, index);
    }

    function p2pRefund(uint256 index) public onlyOwner {
        require(p2plocks[index].amountIn != 0, "Swap : There is no Amount");
        P2PLock storage _p2plock = p2plocks[index];
        uint256 feeAmount = (_p2plock.amountIn * fee) / 10000;

        IERC20(_p2plock.tokenIn).transfer(
            _p2plock.sender,
            _p2plock.amountIn.sub(feeAmount)
        );
        _p2plock.amountIn = 0;
        emit LimitWithdraw(msg.sender, index);
    }

    function p2pAccept(uint256 index) public {
        P2PLock storage _p2plock = p2plocks[index];
        require(_p2plock.amountIn != 0, "Swap : There is no Amount");
        require(_p2plock.receiver == msg.sender, "Swap : You are not receiver");
        require(
            IERC20(_p2plock.tokenOut).balanceOf(msg.sender) >=
                _p2plock.amountOut,
            "Swap : Not Enough Amount"
        );
        uint256 feeAmount = (_p2plock.amountIn * fee) / 10000;
        uint256 feeAmountForOut = (_p2plock.amountOut * fee) / 10000;
        uint256 prevAmount = IERC20(_p2plock.tokenOut).balanceOf(address(this));
        IERC20(_p2plock.tokenOut).transferFrom(
            msg.sender,
            address(this),
            _p2plock.amountOut
        );
        uint256 afterAmount = IERC20(_p2plock.tokenOut).balanceOf(address(this));
        IERC20(_p2plock.tokenIn).transfer(
            _p2plock.sender,
            (afterAmount - prevAmount).sub(feeAmountForOut)
        );
        IERC20(_p2plock.tokenIn).transfer(
            _p2plock.receiver,
            _p2plock.amountIn.sub(feeAmount)
        );
        _p2plock.amountIn = 0;
        emit LimitWithdraw(msg.sender, index);
    }
}