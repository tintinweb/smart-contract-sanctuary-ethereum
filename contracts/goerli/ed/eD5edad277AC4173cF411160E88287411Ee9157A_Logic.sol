// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

interface IStorage {
    function takeToken(uint256 amount, address token) external;

    function returnToken(uint256 amount, address token) external;

    function addEarn(uint256 amount) external;
}

interface IDistribution {
    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function markets(address vTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function claimVenus(address holder) external;

    function claimVenus(address holder, address[] memory vTokens) external;
}

interface IMasterChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address account) external view returns (uint256, uint256);
}

interface IVToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint() external payable;

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function repayBorrow() external payable;
}

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IPancakeRouter01 {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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
}

contract Logic is Ownable, Multicall {
    using SafeERC20 for IERC20;

    struct ReserveLiquidity {
        address tokenA;
        address tokenB;
        address vTokenA;
        address vTokenB;
        address swap;
        address swapMaster;
        address lpToken;
        uint256 poolID;
        address[][] path;
    }

    address private _storage;
    address private blid;
    address private admin;
    address private venusController;
    address private pancake;
    address private apeswap;
    address private biswap;
    address private pancakeMaster;
    address private apeswapMaster;
    address private biswapMaster;
    address private expenseAddress;
    address private vBNB;
    mapping(address => bool) private usedVTokens;
    mapping(address => address) private VTokens;

    ReserveLiquidity[] reserves;

    event SetAdmin(address admin);
    event SetBLID(address _blid);
    event SetStorage(address _storage);

    constructor(
        address _expenseAddress,
        address _venusController,
        address _pancakeRouter,
        address _apeswapRouter,
        address _biswapRouter,
        address _pancakeMaster,
        address _apeswapMaster,
        address _biswapMaster
    ) {
        expenseAddress = _expenseAddress;
        venusController = _venusController;

        apeswap = _apeswapRouter;
        pancake = _pancakeRouter;
        biswap = _biswapRouter;
        pancakeMaster = _pancakeMaster;
        apeswapMaster = _apeswapMaster;
        biswapMaster = _biswapMaster;
    }

    fallback() external payable {}

    receive() external payable {}

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "E1");
        _;
    }

    modifier onlyStorage() {
        require(msg.sender == _storage, "E1");
        _;
    }

    modifier isUsedVToken(address vToken) {
        require(usedVTokens[vToken], "E2");
        _;
    }

    modifier isUsedSwap(address swap) {
        require(swap == apeswap || swap == pancake || swap == biswap, "E3");
        _;
    }

    modifier isUsedMaster(address swap) {
        require(swap == pancakeMaster || apeswapMaster == swap || biswapMaster == swap, "E4");
        _;
    }

    /**
     * @notice Add VToken in Contract and approve token  for storage, venus,
     * pancakeswap/apeswap router, and pancakeswap/apeswap master(Main Staking contract)
     * @param token Address of Token for deposited
     * @param vToken Address of VToken
     */
    function addVTokens(address token, address vToken) external onlyOwner {
        bool _isUsedVToken;
        (_isUsedVToken, , ) = IDistribution(venusController).markets(vToken);
        require(_isUsedVToken, "E5");
        if ((token) != address(0)) {
            IERC20(token).approve(vToken, type(uint256).max);
            IERC20(token).approve(apeswap, type(uint256).max);
            IERC20(token).approve(pancake, type(uint256).max);
            IERC20(token).approve(biswap, type(uint256).max);
            IERC20(token).approve(_storage, type(uint256).max);
            IERC20(token).approve(pancakeMaster, type(uint256).max);
            IERC20(token).approve(apeswapMaster, type(uint256).max);
            IERC20(token).approve(biswapMaster, type(uint256).max);
            VTokens[token] = vToken;
        } else {
            vBNB = vToken;
        }
        usedVTokens[vToken] = true;
    }

    /**
     * @notice Set blid in contract and approve blid for storage, venus, pancakeswap/apeswap
     * router, and pancakeswap/apeswap master(Main Staking contract), you can call the
     * function once
     * @param blid_ Adrees of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        require(blid == address(0), "E6");
        blid = blid_;
        IERC20(blid).safeApprove(apeswap, type(uint256).max);
        IERC20(blid).safeApprove(pancake, type(uint256).max);
        IERC20(blid).safeApprove(biswap, type(uint256).max);
        IERC20(blid).safeApprove(pancakeMaster, type(uint256).max);
        IERC20(blid).safeApprove(apeswapMaster, type(uint256).max);
        IERC20(blid).safeApprove(biswapMaster, type(uint256).max);
        IERC20(blid).safeApprove(_storage, type(uint256).max);
        emit SetBLID(blid_);
    }

    /**
     * @notice Set storage, you can call the function once
     * @param storage_ Addres of Storage Contract
     */
    function setStorage(address storage_) external onlyOwner {
        require(_storage == address(0), "E7");
        _storage = storage_;
        emit SetStorage(storage_);
    }

    /**
     * @notice Approve token for storage, venus, pancakeswap/apeswap router,
     * and pancakeswap/apeswap master(Main Staking contract)
     * @param token  Address of Token that is approved
     */
    function approveTokenForSwap(address token) external onlyOwner {
        (IERC20(token).approve(apeswap, type(uint256).max));
        (IERC20(token).approve(pancake, type(uint256).max));
        (IERC20(token).approve(biswap, type(uint256).max));
        (IERC20(token).approve(pancakeMaster, type(uint256).max));
        (IERC20(token).approve(apeswapMaster, type(uint256).max));
        (IERC20(token).approve(biswapMaster, type(uint256).max));
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnToken(uint256 amount, address token) external payable onlyStorage {
        uint256 takeFromVenus = 0;
        uint256 length = reserves.length;
        //check logic balance
        if (IERC20(token).balanceOf(address(this)) >= amount) {
            return;
        }
        //loop by reserves lp token
        for (uint256 i = 0; i < length; i++) {
            address[] memory path = findPath(i, token); // get path for router
            ReserveLiquidity memory reserve = reserves[i];
            uint256 lpAmount = getPriceFromTokenToLp(
                reserve.lpToken,
                amount - takeFromVenus,
                token,
                reserve.swap,
                path
            ); //get amount of lp token that need for reedem liqudity

            //get how many deposited to farming
            (uint256 depositedLp, ) = IMasterChef(reserve.swapMaster).userInfo(reserve.poolID, address(this));
            if (depositedLp == 0) continue;
            // if deposited LP tokens don't enough  for repay borrow and for reedem token then only repay
            // borow and continue loop, else repay borow, reedem token and break loop
            if (lpAmount >= depositedLp) {
                takeFromVenus += getPriceFromLpToToken(
                    reserve.lpToken,
                    depositedLp,
                    token,
                    reserve.swap,
                    path
                );
                withdrawAndRepay(reserve, depositedLp);
            } else {
                withdrawAndRepay(reserve, lpAmount);

                // get supplied token and break loop
                IVToken(VTokens[token]).redeemUnderlying(amount);
                return;
            }
        }
        //try get supplied token
        IVToken(VTokens[token]).redeemUnderlying(amount);
        //if get money
        if (IERC20(token).balanceOf(address(this)) >= amount) {
            return;
        }
        revert("no money");
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
        emit SetAdmin(newAdmin);
    }

    /**
     * @notice Transfer amount of token from Storage to Logic contract token - address of the token
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeTokenFromStorage(uint256 amount, address token) external onlyOwnerAndAdmin {
        IStorage(_storage).takeToken(amount, token);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage contract token - address of token
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnTokenToStorage(uint256 amount, address token) external onlyOwnerAndAdmin {
        IStorage(_storage).returnToken(amount, token);
    }

    /**
     * @notice Distribution amount of blid to depositors.
     * @param amount Amount of BLID
     */
    function addEarnToStorage(uint256 amount) external onlyOwnerAndAdmin {
        IERC20(blid).safeTransfer(expenseAddress, (amount * 3) / 100);
        IStorage(_storage).addEarn((amount * 97) / 100);
    }

    /**
     * @notice Enter into a list of markets(address of VTokens) - it is not an
     * error to enter the same market more than once.
     * @param vTokens The addresses of the vToken markets to enter.
     * @return For each market, returns an error code indicating whether or not it was entered.
     * Each is 0 on success, otherwise an Error code
     */
    function enterMarkets(address[] calldata vTokens) external onlyOwnerAndAdmin returns (uint256[] memory) {
        return IDistribution(venusController).enterMarkets(vTokens);
    }

    /**
     * @notice Every Venus user accrues XVS for each block
     * they are supplying to or borrowing from the protocol.
     * @param vTokens The addresses of the vToken markets to enter.
     */
    function claimVenus(address[] calldata vTokens) external onlyOwnerAndAdmin {
        IDistribution(venusController).claimVenus(address(this), vTokens);
    }

    /**
     * @notice Stake token and mint VToken
     * @param vToken: that mint Vtokens to this contract
     * @param mintAmount: The amount of the asset to be supplied, in units of the underlying asset.
     * @return 0 on success, otherwise an Error code
     */
    function mint(address vToken, uint256 mintAmount)
        external
        isUsedVToken(vToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        if (vToken == vBNB) {
            IVToken(vToken).mint{ value: mintAmount }();
        }
        return IVToken(vToken).mint(mintAmount);
    }

    /**
     * @notice The borrow function transfers an asset from the protocol to the user and creates a
     * borrow balance which begins accumulating interest based on the Borrow Rate for the asset.
     * The amount borrowed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param vToken: that mint Vtokens to this contract
     * @param borrowAmount: The amount of underlying to be borrow.
     * @return 0 on success, otherwise an Error code
     */
    function borrow(address vToken, uint256 borrowAmount)
        external
        payable
        isUsedVToken(vToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return IVToken(vToken).borrow(borrowAmount);
    }

    /**
     * @notice The repay function transfers an asset into the protocol, reducing the user's borrow balance.
     * @param vToken: that mint Vtokens to this contract
     * @param repayAmount: The amount of the underlying borrowed asset to be repaid.
     * A value of -1 (i.e. 2256 - 1) can be used to repay the full amount.
     * @return 0 on success, otherwise an Error code
     */
    function repayBorrow(address vToken, uint256 repayAmount)
        external
        isUsedVToken(vToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        if (vToken == vBNB) {
            IVToken(vToken).repayBorrow{ value: repayAmount }();
            return 0;
        }
        return IVToken(vToken).repayBorrow(repayAmount);
    }

    /**
     * @notice The redeem underlying function converts vTokens into a specified quantity of the
     * underlying asset, and returns them to the user.
     * The amount of vTokens redeemed is equal to the quantity of underlying tokens received,
     * divided by the current Exchange Rate.
     * The amount redeemed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param vToken: that mint Vtokens to this contract
     * @param redeemAmount: The amount of underlying to be redeemed.
     * @return 0 on success, otherwise an Error code
     */
    function redeemUnderlying(address vToken, uint256 redeemAmount)
        external
        isUsedVToken(vToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return IVToken(vToken).redeemUnderlying(redeemAmount);
    }

    /**
     * @notice Adds liquidity to a BEP20⇄BEP20 pool.
     * @param swap Address of swap router
     * @param tokenA The contract address of one token from your liquidity pair.
     * @param tokenB The contract address of the other token from your liquidity pair.
     * @param amountADesired The amount of tokenA you'd like to provide as liquidity.
     * @param amountBDesired The amount of tokenA you'd like to provide as liquidity.
     * @param amountAMin The minimum amount of tokenA to provide (slippage impact).
     * @param amountBMin The minimum amount of tokenB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountADesired, amountBDesired, amountAMin) = IPancakeRouter01(swap).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        return (amountADesired, amountBDesired, amountAMin);
    }

    /**
     * @notice Removes liquidity from a BEP20⇄BEP20 pool.
     * @param swap Address of swap router
     * @param tokenA The contract address of one token from your liquidity pair.
     * @param tokenB The contract address of the other token from your liquidity pair.
     * @param liquidity The amount of LP Tokens to remove.
     * @param amountAMin he minimum amount of tokenA to provide (slippage impact).
     * @param amountBMin The minimum amount of tokenB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external onlyOwnerAndAdmin isUsedSwap(swap) returns (uint256 amountA, uint256 amountB) {
        (amountAMin, amountBMin) = IPancakeRouter01(swap).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        return (amountAMin, amountBMin);
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swap Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swap Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactTokens(
        address swap,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwnerAndAdmin isUsedSwap(swap) returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Adds liquidity to a BEP20⇄WBNB pool.
     * @param swap Address of swap router
     * @param token The contract address of one token from your liquidity pair.
     * @param amountTokenDesired The amount of the token you'd like to provide as liquidity.
     * @param amountETHDesired The minimum amount of the token to provide (slippage impact).
     * @param amountTokenMin The minimum amount of token to provide (slippage impact).
     * @param amountETHMin The minimum amount of BNB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountETHDesired, amountTokenMin, amountETHMin) = IPancakeRouter01(swap).addLiquidityETH{
            value: amountETHDesired
        }(token, amountTokenDesired, amountTokenMin, amountETHMin, address(this), deadline);

        return (amountETHDesired, amountTokenMin, amountETHMin);
    }

    /**
     * @notice Removes liquidity from a BEP20⇄WBNB pool.
     * @param swap Address of swap router
     * @param token The contract address of one token from your liquidity pair.
     * @param liquidity The amount of LP Tokens to remove.
     * @param amountTokenMin The minimum amount of the token to remove (slippage impact).
     * @param amountETHMin The minimum amount of BNB to remove (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external payable isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256 amountToken, uint256 amountETH) {
        (deadline, amountETHMin) = IPancakeRouter01(swap).removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        return (deadline, amountETHMin);
    }

    /**
     * @notice Receive as many output tokens as possible for an exact amount of BNB.
     * @param swap Address of swap router
     * @param amountETH Payable BNB amount.
     * @param amountOutMin 	The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapExactETHForTokens{ value: amountETH }(
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swap Address of swap router
     * @param amountOut Payable BNB amount.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactETH(
        address swap,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external payable isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive as much BNB as possible for an exact amount of input tokens.
     * @param swap Address of swap router
     * @param amountIn Payable amount of input tokens.
     * @param amountOutMin The maximum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as little BNB as possible.
     * @param swap Address of swap router
     * @param amountOut The amount tokens to receive.
     * @param amountETH Payable BNB amount.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external isUsedSwap(swap) onlyOwnerAndAdmin returns (uint256[] memory amounts) {
        return
            IPancakeRouter01(swap).swapETHForExactTokens{ value: amountETH }(
                amountOut,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Deposit LP tokens to Master
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _pid pool id
     * @param _amount amount of lp token
     */
    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external isUsedMaster(swapMaster) onlyOwnerAndAdmin {
        IMasterChef(swapMaster).deposit(_pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Master
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _pid pool id
     * @param _amount amount of lp token
     */
    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external isUsedMaster(swapMaster) onlyOwnerAndAdmin {
        IMasterChef(swapMaster).withdraw(_pid, _amount);
    }

    /**
     * @notice Stake BANANA/Cake tokens to STAKING.
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _amount amount of lp token
     */
    function enterStaking(address swapMaster, uint256 _amount)
        external
        isUsedMaster(swapMaster)
        onlyOwnerAndAdmin
    {
        IMasterChef(swapMaster).enterStaking(_amount);
    }

    /**
     * @notice Withdraw BANANA/Cake tokens from STAKING.
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _amount amount of lp token
     */
    function leaveStaking(address swapMaster, uint256 _amount)
        external
        isUsedMaster(swapMaster)
        onlyOwnerAndAdmin
    {
        IMasterChef(swapMaster).leaveStaking(_amount);
    }

    /**
     * @notice Add reserve staked lp token to end list
     * @param reserveLiquidity Data is about staked lp in farm
     */
    function addReserveLiquidity(ReserveLiquidity memory reserveLiquidity) external onlyOwnerAndAdmin {
        reserves.push(reserveLiquidity);
    }

    /**
     * @notice Delete last ReserveLiquidity from list of ReserveLiquidity
     */
    function deleteLastReserveLiquidity() external onlyOwnerAndAdmin {
        reserves.pop();
    }

    /**
     * @notice Return count reserves staked lp tokens for return users their tokens.
     */
    function getReservesCount() external view returns (uint256) {
        return reserves.length;
    }

    /**
     * @notice Return reserves staked lp tokens for return user their tokens. return ReserveLiquidity
     */
    function getReserve(uint256 id) external view returns (ReserveLiquidity memory) {
        return reserves[id];
    }

    /*** Prive Function ***/

    /**
     * @notice Repay borrow when in farms  erc20 and BNB
     */
    function repayBorrowBNBandToken(
        address swap,
        address tokenB,
        address VTokenA,
        address VTokenB,
        uint256 lpAmount
    ) private {
        (uint256 amountToken, uint256 amountETH) = IPancakeRouter01(swap).removeLiquidityETH(
            tokenB,
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp + 1 days
        );
        {
            uint256 totalBorrow = IVToken(VTokenA).borrowBalanceCurrent(address(this));
            if (totalBorrow >= amountETH) {
                IVToken(VTokenA).repayBorrow{ value: amountETH }();
            } else {
                IVToken(VTokenA).repayBorrow{ value: totalBorrow }();
            }

            totalBorrow = IVToken(VTokenB).borrowBalanceCurrent(address(this));
            if (totalBorrow >= amountToken) {
                IVToken(VTokenB).repayBorrow(amountToken);
            } else {
                IVToken(VTokenB).repayBorrow(totalBorrow);
            }
        }
    }

    /**
     * @notice Repay borrow when in farms only erc20
     */
    function repayBorrowOnlyTokens(
        address swap,
        address tokenA,
        address tokenB,
        address VTokenA,
        address VTokenB,
        uint256 lpAmount
    ) private {
        (uint256 amountA, uint256 amountB) = IPancakeRouter01(swap).removeLiquidity(
            tokenA,
            tokenB,
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp + 1 days
        );
        {
            uint256 totalBorrow = IVToken(VTokenA).borrowBalanceCurrent(address(this));
            if (totalBorrow >= amountA) {
                IVToken(VTokenA).repayBorrow(amountA);
            } else {
                IVToken(VTokenA).repayBorrow(totalBorrow);
            }

            totalBorrow = IVToken(VTokenB).borrowBalanceCurrent(address(this));
            if (totalBorrow >= amountB) {
                IVToken(VTokenB).repayBorrow(amountB);
            } else {
                IVToken(VTokenB).repayBorrow(totalBorrow);
            }
        }
    }

    /**
     * @notice Withdraw lp token from farms and repay borrow
     */
    function withdrawAndRepay(ReserveLiquidity memory reserve, uint256 lpAmount) private {
        IMasterChef(reserve.swapMaster).withdraw(reserve.poolID, lpAmount);
        if (reserve.tokenA == address(0) || reserve.tokenB == address(0)) {
            //if tokenA is BNB
            if (reserve.tokenA == address(0)) {
                repayBorrowBNBandToken(
                    reserve.swap,
                    reserve.tokenB,
                    reserve.vTokenA,
                    reserve.vTokenB,
                    lpAmount
                );
            }
            //if tokenB is BNB
            else {
                repayBorrowBNBandToken(
                    reserve.swap,
                    reserve.tokenA,
                    reserve.vTokenB,
                    reserve.vTokenA,
                    lpAmount
                );
            }
        }
        //if token A and B is not BNB
        else {
            repayBorrowOnlyTokens(
                reserve.swap,
                reserve.tokenA,
                reserve.tokenB,
                reserve.vTokenA,
                reserve.vTokenB,
                lpAmount
            );
        }
    }

    /*** Prive View Function ***/
    /**
     * @notice Convert Lp Token To Token
     */
    function getPriceFromLpToToken(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) private view returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20(token0).balanceOf(lpToken) * (2);
        uint256 amountIn = (value * totalTokenAmount) / (totalSupply);

        if (amountIn == 0 || token0 == token) {
            return amountIn;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut(amountIn, path);
        return price[price.length - 1];
    }

    /**
     * @notice Convert Token To Lp Token
     */
    function getPriceFromTokenToLp(
        address lpToken,
        uint256 value,
        address token,
        address swap,
        address[] memory path
    ) private view returns (uint256) {
        //make price returned not affected by slippage rate
        uint256 totalSupply = IERC20(lpToken).totalSupply();
        address token0 = IPancakePair(lpToken).token0();
        uint256 totalTokenAmount = IERC20(token0).balanceOf(lpToken);

        if (token0 == token) {
            return (value * (totalSupply)) / (totalTokenAmount) / 2;
        }

        uint256[] memory price = IPancakeRouter01(swap).getAmountsOut((1 gwei), path);
        return (value * (totalSupply)) / ((price[price.length - 1] * 2 * totalTokenAmount) / (1 gwei));
    }

    /**
     * @notice FindPath for swap router
     */
    function findPath(uint256 id, address token) private view returns (address[] memory path) {
        ReserveLiquidity memory reserve = reserves[id];
        uint256 length = reserve.path.length;

        for (uint256 i = 0; i < length; i++) {
            if (reserve.path[i][reserve.path[i].length - 1] == token) {
                return reserve.path[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}