pragma solidity >0.8.0;

import "Wallet.sol";

contract WalletFactory {
    Wallet[] internal walletArray;
    address[] internal walletAddressList;
    string internal riskWeighting;
    address internal rebalancerOwner;
    address internal walletOwner;
    address internal depositFeeAddress;
    address internal performanceFeeAddress;
    uint256 internal depositFee;
    uint256 internal performanceFee;
    address internal wethAddress;
    address internal pancakeswapV2RouterAddress;
    mapping(address => address[]) internal walletsOfAddress;

    constructor(
        address _wethAddress,
        address _pancakeswapV2Router,
        address _rebalancerOwner,
        address _depositFeeAddress,
        address _performanceFeeAddress
    ) {
        rebalancerOwner = _rebalancerOwner;
        walletOwner = msg.sender;
        depositFeeAddress = payable(_depositFeeAddress);
        performanceFeeAddress = payable(_performanceFeeAddress);
        depositFee = 5; // 0.05% calculated as 5/1000
        performanceFee = 50; // 5.0% calculated as 50/1000
        wethAddress = _wethAddress;
        pancakeswapV2RouterAddress = _pancakeswapV2Router;
    }

    modifier onlyRebalancerOwner() {
        require(msg.sender == rebalancerOwner);
        _;
    }

    event Event(string msg, address ref);

    function createWallet(address _oracleAddress, string memory _riskWeighting)
        public
    {
        //
        // REQUIRE oracle address is in Oracle Factory List
        //
        Wallet SpaceTimeWallet = new Wallet(
            _oracleAddress,
            _riskWeighting,
            wethAddress,
            pancakeswapV2RouterAddress,
            rebalancerOwner,
            depositFeeAddress,
            performanceFeeAddress
        );
        walletArray.push(SpaceTimeWallet);
        walletAddressList.push(address(SpaceTimeWallet));
        walletsOfAddress[msg.sender].push(address(SpaceTimeWallet));

        emit Event("address", address(walletAddressList[0]));
    }

    function getWallet(uint256 _index) public view returns (address) {
        return walletAddressList[_index];
    }

    function getWalletsOf(address _address)
        public
        view
        returns (address[] memory)
    {
        return walletsOfAddress[_address];
    }

    function getListOfWallets() public view returns (address[] memory) {
        return walletAddressList;
    }
}

pragma solidity >0.8.0;

/* 
Version 0.0.14
 */
import "IWETH.sol";
import "IPancakeRouter02.sol";
import "ISpaceTimeOracle.sol";
import "IERC20.sol";
import "SafeERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint256);
}

contract Wallet {
    address public oracleAddress;
    string public riskWeighting;
    address internal rebalancerOwner;
    address public walletOwner;
    address[] internal ownedAssets;
    uint256 internal totalDeposited = 0;
    uint256 internal valueAtClose;
    address internal depositFeeAddress;
    address internal performanceFeeAddress;
    uint256 internal depositFee;
    uint256 internal performanceFee;
    uint256 internal walletCreation = block.timestamp;
    uint256 internal rebalancePeriods = 2 * 30; //30 * 86400;
    uint256 internal lastRebalance = 0;
    uint256 internal walletStatus = 0; //Set status to inactive (0 = inactive, 1 = active, 2 = closed)
    address internal wethAddress;
    IWETH wethToken;
    address internal pancakeswapV2RouterAddress;
    IPancakeRouter02 pancakeswapRouter;

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    constructor(
        address _SpaceTimeOracleAddress,
        string memory _riskWeighting,
        address _wethAddress,
        address _pancakeswapV2Router,
        address _rebalancerOwner,
        address _depositFeeAddress,
        address _performanceFeeAddress
    ) {
        oracleAddress = address(_SpaceTimeOracleAddress);
        riskWeighting = _riskWeighting;
        rebalancerOwner = _rebalancerOwner;
        walletOwner = msg.sender;
        depositFeeAddress = _depositFeeAddress;
        performanceFeeAddress = _performanceFeeAddress;
        depositFee = 5; // 0.05% calculated as 5/1000
        performanceFee = 50; // 5.0% calculated as 50/1000
        wethAddress = _wethAddress;
        wethToken = IWETH(wethAddress);
        pancakeswapV2RouterAddress = _pancakeswapV2Router;
        pancakeswapRouter = IPancakeRouter02(pancakeswapV2RouterAddress);
    }

    modifier onlyRebalancerOwner() {
        require(msg.sender == rebalancerOwner);
        _;
    }

    modifier onlyWalletOwner() {
        require(msg.sender == walletOwner);
        _;
    }

    function processDepositFee(uint256 _ethBalance) internal {
        uint256 depositFeeAmount = (_ethBalance * depositFee) / 1000;
        IERC20(wethAddress).safeTransfer(depositFeeAddress, depositFeeAmount);
    }

    function processPerformanceFee(uint256 _profit) internal {
        uint256 performanceFeeAmount = (_profit * performanceFee) / 1000;
        IERC20(wethAddress).safeTransfer(
            performanceFeeAddress,
            performanceFeeAmount
        );
    }

    function getRiskWeighting() public view returns (string memory) {
        return riskWeighting;
    }

    function getStrategyName() public view returns (string memory) {
        return ISpaceTimeOracle(oracleAddress).getStrategyName();
    }

    function getStrategyId() public view returns (string memory) {
        return ISpaceTimeOracle(oracleAddress).getStrategyId();
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWethBalance() public view returns (uint256) {
        return IERC20Detailed(wethAddress).balanceOf(address(this));
    }

    function getTokenBalance(address _tokenAddress)
        public
        view
        returns (uint256, uint256)
    {
        IERC20Detailed assetToken = IERC20Detailed(_tokenAddress);
        uint256 tokenBalance = assetToken.balanceOf(address(this));
        uint256 tokenDecimals = assetToken.decimals();
        uint256 tokenPrice = ISpaceTimeOracle(oracleAddress)
            .getTokenAddressPrice(_tokenAddress);
        uint256 tokenBalanceInWeth = (tokenBalance * tokenPrice) /
            10**tokenDecimals;
        return (tokenBalance, tokenBalanceInWeth);
    }

    function getTotalBalanceInWeth(address[] memory _ownedAssets)
        public
        view
        returns (uint256)
    {
        uint256 _tokenBalances = 0;
        if (_ownedAssets.length > 0) {
            for (uint256 x = 0; x < _ownedAssets.length; x++) {
                (, uint256 tokenBalanceInWeth) = getTokenBalance(
                    _ownedAssets[x]
                );
                _tokenBalances = _tokenBalances + tokenBalanceInWeth;
            }
        }
        uint256 _totalBalance = _tokenBalances +
            getEthBalance() +
            getWethBalance();
        return _totalBalance;
    }

    // Update targetAssets with the latest targets from the SpaceTimeOracle
    function getTargetAssets() public view returns (address[] memory) {
        (address[] memory targetAssets, ) = ISpaceTimeOracle(oracleAddress)
            .getTargetAssets();
        return targetAssets;
    }

    function getOwnedAssets() public view returns (address[] memory) {
        return ownedAssets;
    }

    function updateOwnedAssets(address[] memory _ownedAssets)
        public
        onlyRebalancerOwner
    {
        ownedAssets = _ownedAssets;
    }

    function getRebalanceRequired() public view returns (uint256) {
        uint256 required;
        if (walletStatus == 0 || walletStatus == 1) {
            if (block.timestamp > (lastRebalance + rebalancePeriods)) {
                required = 1;
            } else {
                required = 0;
            }
        } else {
            required = 0;
        }
        return required;
    }

    function getTotalDeposited() public view returns (uint256) {
        return totalDeposited;
    }

    function getValueAtClose() public view returns (uint256) {
        return valueAtClose;
    }

    event returnBalance(string msg, uint256 ref);

    function checkForDeposits() public onlyRebalancerOwner {
        uint256 _ethBalance = getEthBalance();
        emit returnBalance("BNB", _ethBalance);
        if (_ethBalance > 0) {
            totalDeposited = _ethBalance + totalDeposited;
            wrapETH();
            processDepositFee(_ethBalance);
            walletStatus = 1; // Set status to active (0 = inactive, 1 = active, 2 = closed)
        }
        uint256 _wethBalance = getWethBalance();
        emit returnBalance("WETH", _wethBalance);
        lastRebalance = block.timestamp;
    }

    event swapTokenEvent(
        string msg,
        string ref1,
        address ref2,
        uint256 ref3,
        uint256 ref4,
        uint256 ref5
    );

    event transactionDetail(
        string msg,
        string ref1,
        uint256 ref2,
        uint256 ref3
    );

    function sellToken(
        string memory _symbol,
        address _tokenAddress,
        uint256 _token_amount_in,
        uint256 _weth_amount_out,
        uint256 _slippage
    ) public onlyRebalancerOwner {
        emit swapTokenEvent(
            "sellToken",
            _symbol,
            _tokenAddress,
            _token_amount_in,
            _weth_amount_out,
            _slippage
        );
        uint256 token_amount_in = _token_amount_in;
        uint256 amountOutMinimum = ((10000 - _slippage) * _weth_amount_out) /
            10000; // e.g. 0.05% calculated as 50/10000
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = wethAddress;
        address recipient = address(this);
        uint256 deadline = block.timestamp + 15;
        IERC20 assetToken = IERC20(_tokenAddress);
        require(
            assetToken.approve(
                address(pancakeswapV2RouterAddress),
                _token_amount_in
            ),
            "TOKEN approve failed"
        );
        pancakeswapRouter.swapExactTokensForTokens(
            token_amount_in,
            amountOutMinimum,
            path,
            recipient,
            deadline
        );

        (uint256 tokenBalance, uint256 tokenBalanceInWeth) = getTokenBalance(
            _tokenAddress
        );
        emit transactionDetail(
            "Sold",
            _symbol,
            tokenBalance,
            tokenBalanceInWeth
        );
    }

    event iswapApproval(string msg);

    function buyToken(
        string memory _symbol,
        address _tokenAddress,
        uint256 _weth_amount_in,
        uint256 _token_amount_out,
        uint256 _slippage
    ) public onlyRebalancerOwner {
        emit swapTokenEvent(
            "buyToken",
            _symbol,
            _tokenAddress,
            _weth_amount_in,
            _token_amount_out,
            _slippage
        );
        uint256 weth_amount_in = _weth_amount_in;
        uint256 amountOutMinimum = ((10000 - _slippage) * _token_amount_out) /
            10000; // e.g. 0.05% calculated as 50/10000
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = _tokenAddress;
        address recipient = address(this);
        uint256 deadline = block.timestamp + 15;

        require(
            wethToken.approve(
                address(pancakeswapV2RouterAddress),
                _weth_amount_in
            ),
            "WETH approve failed"
        );
        pancakeswapRouter.swapExactTokensForTokens(
            weth_amount_in,
            amountOutMinimum,
            path,
            recipient,
            deadline
        );

        (uint256 tokenBalance, uint256 tokenBalanceInWeth) = getTokenBalance(
            _tokenAddress
        );
        emit transactionDetail(
            "Bought",
            _symbol,
            tokenBalance,
            tokenBalanceInWeth
        );
    }

    receive() external payable {}

    fallback() external payable {}

    function wrapETH() internal {
        uint256 ethBalance = getEthBalance();
        require(ethBalance > 0, "No ETH available to wrap");
        wethToken.deposit{value: ethBalance}();
    }

    function unwrapETH() internal {
        uint256 wethBalance = getWethBalance();
        require(wethBalance > 0, "No WETH available to unwrap");
        wethToken.approve(address(this), wethBalance);
        wethToken.withdraw(wethBalance);
    }

    event closeWalletEvent(string msg, uint256 ref);

    function closeWallet() public onlyWalletOwner {
        //require(
        //    block.timestamp >= end,
        //    "The wallet is locked. Check the time left."
        //);
        if (ownedAssets.length > 0) {
            for (uint256 i = 0; i < ownedAssets.length; i++) {
                address tokenAddress = ownedAssets[i];
                (
                    uint256 tokenBalance,
                    uint256 tokenBalanceInWeth
                ) = getTokenBalance(tokenAddress);
                uint256 amountOutMinimum = ((10000 - 300) *
                    tokenBalanceInWeth) / 10000; // e.g. 0.05% calculated as 50/10000
                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = wethAddress;
                uint256 deadline = block.timestamp + 15;
                address recipient = address(this);
                IERC20 assetToken = IERC20(tokenAddress);
                require(
                    assetToken.approve(
                        address(pancakeswapV2RouterAddress),
                        tokenBalance
                    ),
                    "TOKEN approve failed"
                );

                pancakeswapRouter.swapExactTokensForTokens(
                    tokenBalance,
                    amountOutMinimum, // NEED TO OPTIMISE FOR BEST EXIT
                    path,
                    address(this),
                    deadline
                );
            }
        }

        // Clear owned assets
        delete ownedAssets;

        uint256 wethBalance = getWethBalance();
        emit closeWalletEvent("WETH in wallet:", wethBalance);
        valueAtClose = wethBalance;

        if (wethBalance > totalDeposited) {
            uint256 profit = wethBalance - totalDeposited;
            processPerformanceFee(profit);
        }

        if (wethBalance > 0) {
            unwrapETH();
            emit closeWalletEvent("Weth amount unwrapped:", wethBalance);
        }

        uint256 ethBalance = getEthBalance();
        emit closeWalletEvent("ETH balance:", ethBalance);

        if (ethBalance > 0) {
            (bool sent, ) = walletOwner.call{value: ethBalance}("");
            require(sent, "Failed to send BNB");
            emit closeWalletEvent("Wallet amount returned:", ethBalance);
        }

        walletStatus = 2; // Set status to closed (0 = inactive, 1 = active, 2 = closed)
    }
}

pragma solidity >0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external payable;

    function totalSupply() external returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

pragma solidity >=0.6.2;

import "IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

pragma solidity >0.8.0;

interface ISpaceTimeOracle {
    function getTargetAssets()
        external
        view
        returns (address[] memory, uint256);

    function getTokenAddressSymbol(address _tokenAddress)
        external
        view
        returns (address);

    function getTokenAddressPrice(address _tokenAddress)
        external
        view
        returns (uint256);

    function getTokenAddressTargetPercentage(
        address _tokenAddress,
        string memory _targetRiskWeighting
    ) external view returns (uint256);

    function getStrategyName() external view returns (string memory);

    function getStrategyId() external view returns (string memory);
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

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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