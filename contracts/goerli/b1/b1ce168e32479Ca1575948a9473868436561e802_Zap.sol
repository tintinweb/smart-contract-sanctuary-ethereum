//SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDXswapFactory} from '@swapr/core/contracts/interfaces/IDXswapFactory.sol';
import {IDXswapPair} from '@swapr/core/contracts/interfaces/IDXswapPair.sol';
import {IERC20} from '@swapr/core/contracts/interfaces/IERC20.sol';
import {IWETH} from '@swapr/core/contracts/interfaces/IWETH.sol';
import {IDXswapRouter} from '@swapr/periphery/contracts/interfaces/IDXswapRouter.sol';
import {TransferHelper} from '@swapr/periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './peripherals/Ownable.sol';

error ForbiddenValue();
error InsufficientMinAmount();
error InvalidInputAmount();
error InvalidPair();
error InvalidStartPath();
error InvalidTargetPath();
error OnlyFeeSetter();
error ZeroAddressInput();
error InvalidRouterOrFactory();
error DexIndexAlreadyUsed();

struct DEX {
    string name;
    address router;
    address factory;
}

struct SwapTx {
    uint256 amount;
    uint256 amountMin;
    address[] path;
    uint8 dexIndex;
}

struct ZapInTx {
    uint256 amountAMin;
    uint256 amountBMin;
    uint256 amountLPMin;
    uint8 dexIndex;
    address to;
}

struct ZapOutTx {
    uint256 amountLpFrom;
    uint256 amountTokenToMin;
    uint8 dexIndex;
    address to;
}

/**  
@title Zap
@notice Allows to zapIn from an ERC20 or native currency to ERC20 pair
and zapOut from an ERC20 pair to an ERC20 or native currency
@dev Dusts from zap can be withdrawn by owner
*/
contract Zap is Ownable, ReentrancyGuard {
    bool public stopped = false; // pause the contract if emergency
    uint16 public protocolFee = 50; // default 0.5% of zap amount protocol fee (range: 0-10000)
    uint16 public affiliateSplit; // % share of protocol fee (0-100 %) (range: 0-10000)
    address public feeTo;
    address public feeToSetter;
    address public immutable nativeCurrencyWrapper;

    // set list of supported DEXs for zap
    mapping(uint8 => DEX) public supportedDEXs;
    // if true, protocol fee is not deducted
    mapping(address => bool) public feeWhitelist;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;

    // native currency address used for balances
    address private constant nativeCurrencyAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // placeholder for swap deadline
    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    event ZapIn(address sender, address tokenFrom, uint256 amountFrom, address pairTo, uint256 amountTo);

    event ZapOut(address sender, address pairFrom, uint256 amountFrom, address tokenTo, uint256 amountTo);

    // circuit breaker modifiers
    modifier stopInEmergency() {
        if (stopped) {
            revert('Temporarily Paused');
        } else {
            _;
        }
    }

    /**  
    @notice Constructor
    @param _owner The address of contract owner
    @param _feeToSetter The address setter of fee receiver
    @param _nativeCurrencyWrapper The address of wrapped native currency
    */
    constructor(
        address _owner,
        address _feeToSetter,
        address _nativeCurrencyWrapper
    ) Ownable(_owner) {
        feeToSetter = _feeToSetter;
        nativeCurrencyWrapper = _nativeCurrencyWrapper;
    }

    /// @notice Allows the contract to receive native currency
    /// @dev It is necessary to be able to receive native currency when using nativeCurrencyWrapper.withdraw()
    receive() external payable {}

    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a ZapTx
     */
    function zapIn(
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        ZapInTx calldata zap,
        address affiliate,
        bool transferResidual
    ) external payable nonReentrant stopInEmergency returns (uint256 lpBought, address lpToken) {
        // check if start token is the same for both paths
        if (swapTokenA.path[0] != swapTokenB.path[0]) revert InvalidStartPath();

        (uint256 amountAToInvest, uint256 amountBToInvest) = _pullTokens(swapTokenA, swapTokenB, affiliate);
        (lpBought, lpToken) = _performZapIn(
            amountAToInvest,
            amountBToInvest,
            swapTokenA,
            swapTokenB,
            zap,
            transferResidual
        );

        if (lpBought < zap.amountLPMin) revert InsufficientMinAmount();
        TransferHelper.safeTransfer(lpToken, msg.sender, lpBought);

        emit ZapIn(msg.sender, swapTokenA.path[0], swapTokenA.amount + swapTokenB.amount, lpToken, lpBought);
    }

    /**
    @notice ZapTx out LP token in a single token
    @dev path0 and path1 do not need to be ordered
    @param affiliate Affiliate address
    */
    function zapOut(
        ZapOutTx calldata zap,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        address affiliate
    ) external nonReentrant stopInEmergency returns (uint256 amountTransferred, address tokenTo) {
        // check if target token is the same for both paths
        if (swapTokenA.path[swapTokenA.path.length - 1] != swapTokenB.path[swapTokenB.path.length - 1])
            revert InvalidTargetPath();
        tokenTo = swapTokenA.path[swapTokenA.path.length - 1];

        (uint256 amountTo, address lpToken) = _performZapOut(zap, swapTokenA, swapTokenB);

        amountTransferred = _getFeeAndTransferTokens(tokenTo, amountTo, zap.to, affiliate);
        if (amountTransferred < zap.amountTokenToMin) revert InsufficientMinAmount();

        emit ZapOut(msg.sender, lpToken, zap.amountLpFrom, tokenTo, amountTransferred);
    }

    /** 
    @notice 
    */
    function setFeeWhitelist(address zapAddress, bool status) external onlyOwner {
        feeWhitelist[zapAddress] = status;
    }

    /** 
    @notice 
    */
    function setNewAffiliateSplit(uint16 _newAffiliateSplit) external onlyOwner {
        if (_newAffiliateSplit > 10000) revert ForbiddenValue();
        affiliateSplit = _newAffiliateSplit;
    }

    /** 
    @notice 
    */
    function setAffiliateStatus(address _affiliate, bool _status) external onlyOwner {
        affiliates[_affiliate] = _status;
    }

    /** 
    @notice 
    */
    function setSupportedDEX(
        uint8 _dexIndex,
        string calldata _name,
        address _router,
        address _factory
    ) external onlyOwner {
        if (supportedDEXs[_dexIndex].router != address(0)) revert DexIndexAlreadyUsed();
        if (_router == address(0) || _factory == address(0)) revert ZeroAddressInput();
        if (_factory != IDXswapRouter(_router).factory()) revert InvalidRouterOrFactory();
        supportedDEXs[_dexIndex] = DEX({name: _name, router: _router, factory: _factory});
    }

    /** 
    @notice 
    */
    function removeSupportedDEX(uint8 _dexIndex) external onlyOwner {
        supportedDEXs[_dexIndex].router = address(0);
        supportedDEXs[_dexIndex].factory = address(0);
        supportedDEXs[_dexIndex].name = '';
    }

    /** 
    @notice Sets the fee receiver address
    @param _feeTo The address to send received zap fee 
    */
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeTo = _feeTo;
    }

    /** 
    @param _feeToSetter The address of the fee setter
    @notice Sets the setter address
    */
    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeToSetter = _feeToSetter;
    }

    /**  
    @notice Sets the protocol fee percent
    @param _protocolFee The new protocol fee percent
    */
    function setProtocolFee(uint16 _protocolFee) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        if (_protocolFee > 10000) revert ForbiddenValue();
        protocolFee = _protocolFee;
    }

    /** 
    @notice Withdraw protocolFee share, retaining affilliate share 
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == nativeCurrencyAddress) {
                qty = address(this).balance - totalAffiliateBalance[tokens[i]];
                TransferHelper.safeTransferETH(owner, qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this)) - totalAffiliateBalance[tokens[i]];
                TransferHelper.safeTransfer(tokens[i], owner, qty);
            }
        }
    }

    /**  
    @notice Withdraw affilliate share
    */
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]] - tokenBal;

            if (tokens[i] == nativeCurrencyAddress) {
                TransferHelper.safeTransferETH(msg.sender, tokenBal);
            } else {
                TransferHelper.safeTransfer(tokens[i], msg.sender, tokenBal);
            }
        }
    }

    /** 
    @notice Pause the contract
    */
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    /** 
    @notice Check if DEX is supported and return addresses
    */
    function getSupportedDEX(uint8 _dexIndex) public view returns (address router, address factory) {
        router = supportedDEXs[_dexIndex].router;
        factory = supportedDEXs[_dexIndex].factory;
        if (router == address(0) || factory == address(0)) revert InvalidRouterOrFactory();
    }

    /** 
    @notice 
    */
    function _performZapIn(
        uint256 amountAToInvest,
        uint256 amountBToInvest,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        ZapInTx calldata zap,
        bool transferResidual
    ) internal returns (uint256 liquidity, address lpToken) {
        // check if dex is supported
        (address router, address factory) = getSupportedDEX(zap.dexIndex);

        // get pair and check if exists
        lpToken = _getPairAddress(
            swapTokenA.path[swapTokenA.path.length - 1],
            swapTokenB.path[swapTokenB.path.length - 1],
            factory
        );

        (uint256 tokenABought, uint256 tokenBBought) = _buyTokens(
            amountAToInvest,
            amountBToInvest,
            swapTokenA,
            swapTokenB
        );

        (, , liquidity) = _addLiquidity(
            swapTokenA.path[swapTokenA.path.length - 1],
            swapTokenB.path[swapTokenB.path.length - 1],
            tokenABought,
            tokenBBought,
            swapTokenA.amountMin,
            swapTokenB.amountMin,
            router,
            transferResidual
        );
    }

    /** 
    @notice 
    */
    function _performZapOut(
        ZapOutTx calldata zap,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB
    ) internal returns (uint256 amountTo, address lpToken) {
        if (zap.amountLpFrom == 0) revert InvalidInputAmount();
        // check if dex is supported
        (address router, address factory) = getSupportedDEX(zap.dexIndex);
        // validate pair
        lpToken = _getPairAddress(swapTokenA.path[0], swapTokenB.path[0], factory);
        address token0 = IDXswapPair(lpToken).token0();
        address token1 = IDXswapPair(lpToken).token1();

        (uint256 amount0, uint256 amount1) = _removeLiquidity(
            token0,
            token1,
            lpToken,
            zap.amountLpFrom,
            swapTokenA.amountMin,
            swapTokenB.amountMin,
            router
        );

        //swaps tokens to target token through proper path
        if (swapTokenA.path[0] == token0 && swapTokenB.path[0] == token1) {
            amountTo = _swapLpTokensToTargetTokens(amount0, amount1, swapTokenA, swapTokenB, address(this));
        } else if (swapTokenA.path[0] == token1 && swapTokenB.path[0] == token0) {
            amountTo = _swapLpTokensToTargetTokens(amount1, amount0, swapTokenA, swapTokenB, address(this));
        } else revert InvalidPair();
    }

    /** 
    @notice 
    */
    function _pullTokens(
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        address affiliate
    ) internal returns (uint256 amountAToInvest, uint256 amountBToInvest) {
        address fromTokenAddress = swapTokenA.path[0];
        uint256 totalAmount = swapTokenA.amount + swapTokenB.amount;

        if (fromTokenAddress == address(0)) {
            if (msg.value == 0 || msg.value != totalAmount) revert InvalidInputAmount();
            fromTokenAddress = nativeCurrencyAddress;
        } else {
            if (msg.value > 0 || totalAmount == 0) revert InvalidInputAmount();
            //transfer tokens to zap contract
            TransferHelper.safeTransferFrom(fromTokenAddress, msg.sender, address(this), totalAmount);
        }

        // subtract protocol fee
        return (
            amountAToInvest = swapTokenA.amount - _subtractProtocolFee(fromTokenAddress, swapTokenA.amount, affiliate),
            amountBToInvest = swapTokenB.amount - _subtractProtocolFee(fromTokenAddress, swapTokenB.amount, affiliate)
        );
    }

    /** 
    @notice 
    */
    function _subtractProtocolFee(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalProtocolFeePortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && protocolFee > 0) {
            totalProtocolFeePortion = (amount * protocolFee) / 10000;

            if (affiliates[affiliate] && affiliateSplit > 0) {
                uint256 affiliatePortion = (totalProtocolFeePortion * affiliateSplit) / 10000;
                affiliateBalance[affiliate][token] = affiliateBalance[affiliate][token] + affiliatePortion;
                totalAffiliateBalance[token] = totalAffiliateBalance[token] + affiliatePortion;
            }
        }
    }

    /** 
    @notice 
    */
    function _buyTokens(
        uint256 amountAToInvest,
        uint256 amountBToInvest,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB
    ) internal returns (uint256 tokenABought, uint256 tokenBBought) {
        // wrap native currency
        if (swapTokenA.path[0] == address(0)) {
            address[] memory pathA = swapTokenA.path;
            address[] memory pathB = swapTokenB.path;

            IWETH(nativeCurrencyWrapper).deposit{value: amountAToInvest + amountAToInvest}();
            // set path to start with native currency wrapper instead of address(0x00)
            pathA[0] = nativeCurrencyWrapper;
            pathB[0] = nativeCurrencyWrapper;

            tokenABought = _swapExactTokensForTokens(
                amountAToInvest,
                swapTokenA.amountMin,
                pathA,
                address(this),
                supportedDEXs[swapTokenA.dexIndex].router
            );
            tokenBBought = _swapExactTokensForTokens(
                amountBToInvest,
                swapTokenB.amountMin,
                pathB,
                address(this),
                supportedDEXs[swapTokenB.dexIndex].router
            );

            return (tokenABought, tokenBBought);
        }

        tokenABought = _swapExactTokensForTokens(
            amountAToInvest,
            swapTokenA.amountMin,
            swapTokenA.path,
            address(this),
            supportedDEXs[swapTokenA.dexIndex].router
        );
        tokenBBought = _swapExactTokensForTokens(
            amountBToInvest,
            swapTokenB.amountMin,
            swapTokenB.path,
            address(this),
            supportedDEXs[swapTokenB.dexIndex].router
        );
    }

    /**  
    @notice Swaps exact tokenFrom following path
    @param amountFrom The amount of tokenFrom to swap
    @param amountToMin The min amount of tokenTo to receive
    @param path The path to follow to swap tokenFrom to TokenTo
    @param to The address that will receive tokenTo
    @return amountTo The amount of token received
    */
    function _swapExactTokensForTokens(
        uint256 amountFrom,
        uint256 amountToMin,
        address[] memory path,
        address to,
        address router
    ) internal returns (uint256 amountTo) {
        uint256 len = path.length;
        address tokenTo = path[len - 1];
        uint256 balanceBefore = IERC20(tokenTo).balanceOf(to);

        // swap tokens following the path
        if (len > 1) {
            _approveTokenIfNeeded(path[0], amountFrom, router);
            IDXswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountFrom,
                amountToMin,
                path,
                to,
                deadline
            );
            amountTo = IERC20(tokenTo).balanceOf(to) - balanceBefore;
        } else {
            // no swap needed because path is only 1-element
            if (to != address(this)) {
                // transfer token to receiver address
                TransferHelper.safeTransfer(tokenTo, to, amountFrom);
                amountTo = IERC20(tokenTo).balanceOf(to) - balanceBefore;
            } else {
                // ZapIn case: token already on Zap contract balance
                amountTo = amountFrom;
            }
        }
        if (amountTo < amountToMin) revert InsufficientMinAmount();
    }

    /**  
    @notice Add liquidity to the pool
    @param tokenA The address of the first pool token
    @param tokenB The address of the second pool token
    @param amountADesired The desired amount of token A to add
    @param amountBDesired The desired amount of token A to add
    @param amountAMin The minimum amount of token A to receive
    @param amountBMin The minimum amount of token A to receive
    @param router The address of platform's router
    @param transferResidual Set false to save gas by donating the residual remaining after a ZapTx
    */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address router,
        bool transferResidual
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        _approveTokenIfNeeded(tokenA, amountADesired, router);
        _approveTokenIfNeeded(tokenB, amountBDesired, router);

        (amountA, amountB, liquidity) = IDXswapRouter(router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        if (transferResidual) {
            // returning residue in token0, if any
            if (amountADesired - amountA > 0) {
                TransferHelper.safeTransfer(tokenA, msg.sender, (amountADesired - amountA));
            }

            // returning residue in token1, if any
            if (amountBDesired - amountB > 0) {
                TransferHelper.safeTransfer(tokenB, msg.sender, (amountBDesired - amountB));
            }
        }
    }

    /** 
    @notice 
    */
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        address lpToken,
        uint256 amountLp,
        uint256 amountAMin,
        uint256 amountBMin,
        address router
    ) internal returns (uint256 amountA, uint256 amountB) {
        _approveTokenIfNeeded(lpToken, amountLp, router);

        // pull LP tokens from sender
        TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), amountLp);

        // removeLiquidity sort tokens so no need to set them in exact order
        (amountA, amountB) = IDXswapRouter(router).removeLiquidity(
            tokenA,
            tokenB,
            amountLp,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        if (amountA == 0 || amountB == 0) revert InsufficientMinAmount();
    }

    /**  
    @notice Approves the token if needed
    @param token The address of the token
    @param amount The amount of token to send
    */
    function _approveTokenIfNeeded(
        address token,
        uint256 amount,
        address router
    ) internal {
        if (IERC20(token).allowance(address(this), router) < amount) {
            // Note: some tokens (e.g. USDT, KNC) allowance must be first reset
            // to 0 before being able to update it
            TransferHelper.safeApprove(token, router, 0);
            TransferHelper.safeApprove(token, router, amount);
        }
    }

    /** 
    @notice 
    */
    function _getFeeAndTransferTokens(
        address tokenTo,
        uint256 amountTo,
        address to,
        address affiliate
    ) internal returns (uint256 amountTransferred) {
        uint256 totalProtocolFeePortion;

        if (tokenTo == address(0)) {
            // unwrap to native currency
            IWETH(nativeCurrencyWrapper).withdraw(amountTo);
            totalProtocolFeePortion = _subtractProtocolFee(nativeCurrencyAddress, amountTo, affiliate);
            TransferHelper.safeTransferETH(to, amountTo - totalProtocolFeePortion);
        } else {
            totalProtocolFeePortion = _subtractProtocolFee(tokenTo, amountTo, affiliate);
            TransferHelper.safeTransfer(tokenTo, to, amountTo - totalProtocolFeePortion);
        }

        amountTransferred = amountTo - totalProtocolFeePortion;
    }

    /** 
    @notice 
    */
    function _swapLpTokensToTargetTokens(
        uint256 amountA,
        uint256 amountB,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        address to
    ) internal returns (uint256 amountTo) {
        (address routerSwapA, ) = getSupportedDEX(swapTokenA.dexIndex);
        (address routerSwapB, ) = getSupportedDEX(swapTokenB.dexIndex);

        if (swapTokenA.path[swapTokenA.path.length - 1] == address(0)) {
            // set target token for native currency wrapper instead of address(0x00)
            address[] memory pathA = swapTokenA.path;
            address[] memory pathB = swapTokenB.path;
            pathA[pathA.length - 1] = nativeCurrencyWrapper;
            pathB[pathB.length - 1] = nativeCurrencyWrapper;

            return
                amountTo =
                    _swapExactTokensForTokens(amountA, swapTokenA.amountMin, pathA, to, routerSwapA) +
                    _swapExactTokensForTokens(amountB, swapTokenB.amountMin, pathB, to, routerSwapB);
        }

        amountTo =
            _swapExactTokensForTokens(amountA, swapTokenA.amountMin, swapTokenA.path, to, routerSwapA) +
            _swapExactTokensForTokens(amountB, swapTokenB.amountMin, swapTokenB.path, to, routerSwapB);
    }

    /** 
    @notice Gets and validates pair's address
    @param tokenA The addres of the first token of the pair
    @param tokenB The addres of the second token of the pair
    @return pair The address of the pair
    */
    function _getPairAddress(
        address tokenA,
        address tokenB,
        address factory
    ) internal view returns (address pair) {
        pair = IDXswapFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) revert InvalidPair();
    }
}

pragma solidity >=0.5.0;

interface IDXswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
    function feeTo() external view returns (address);
    function protocolFeeDenominator() external view returns (uint8);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint8 _protocolFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

pragma solidity >=0.5.0;

interface IDXswapPair {
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
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}

pragma solidity >=0.6.2;


interface IDXswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IOwnable.sol';

abstract contract Ownable is IOwnable {
    /// @inheritdoc IOwnable
    address public override owner;

    /// @inheritdoc IOwnable
    address public override pendingOwner;

    constructor(address _owner) {
        if (_owner == address(0)) revert NoOwnerZeroAddress();
        owner = _owner;
    }

    /// @inheritdoc IOwnable
    function setOwner(address _owner) external override onlyOwner {
        pendingOwner = _owner;
        emit OwnerProposal(_owner);
    }

    /// @inheritdoc IOwnable
    function acceptOwner() external override onlyPendingOwner {
        owner = pendingOwner;
        delete pendingOwner;
        emit OwnerSet(owner);
    }

    /// @notice Functions with this modifier can only be called by owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    /// @notice Functions with this modifier can only be called by pendingOwner
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert OnlyPendingOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Ownable contract
/// @notice Manages the owner role
interface IOwnable {
    // Events

    /// @notice Emitted when pendingOwner accepts to be owner
    /// @param _owner Address of the new owner
    event OwnerSet(address _owner);

    /// @notice Emitted when a new owner is proposed
    /// @param _pendingOwner Address that is proposed to be the new owner
    event OwnerProposal(address _pendingOwner);

    // Errors

    /// @notice Throws if the caller of the function is not owner
    error OnlyOwner();

    /// @notice Throws if the caller of the function is not pendingOwner
    error OnlyPendingOwner();

    /// @notice Throws if trying to set owner to zero address
    error NoOwnerZeroAddress();

    // Variables

    /// @notice Stores the owner address
    /// @return _owner The owner addresss
    function owner() external view returns (address _owner);

    /// @notice Stores the pendingOwner address
    /// @return _pendingOwner The pendingOwner addresss
    function pendingOwner() external view returns (address _pendingOwner);

    // Methods

    /// @notice Proposes a new address to be owner
    /// @param _owner The address being proposed as the new owner
    function setOwner(address _owner) external;

    /// @notice Changes the owner from the current owner to the previously proposed address
    function acceptOwner() external;
}