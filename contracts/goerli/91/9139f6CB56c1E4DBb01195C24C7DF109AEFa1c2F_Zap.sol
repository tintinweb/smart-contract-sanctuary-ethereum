//SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IDXswapFactory} from '@swapr/core/contracts/interfaces/IDXswapFactory.sol';
import {IDXswapPair} from '@swapr/core/contracts/interfaces/IDXswapPair.sol';
import {IERC20} from '@swapr/core/contracts/interfaces/IERC20.sol';
import {IWETH} from '@swapr/core/contracts/interfaces/IWETH.sol';
import {IDXswapRouter} from '@swapr/periphery/contracts/interfaces/IDXswapRouter.sol';
import {TransferHelper} from '@swapr/periphery/contracts/libraries/TransferHelper.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Ownable} from './peripherals/Ownable.sol';

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
}

struct ZapOutTx {
    uint256 amountLpFrom;
    uint256 amountTokenToMin;
    uint8 dexIndex;
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
    uint16 public affiliateSplit; // % share of protocol fee 0-100 % (range: 0-10000)
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

    event ZapIn(
        address sender,
        address receiver,
        address tokenFrom,
        uint256 amountFrom,
        address pairTo,
        uint256 amountTo
    );

    event ZapOut(
        address sender,
        address receiver,
        address pairFrom,
        uint256 amountFrom,
        address tokenTo,
        uint256 amountTo
    );

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
    constructor(address _owner, address _feeToSetter, address _nativeCurrencyWrapper) Ownable(_owner) {
        feeToSetter = _feeToSetter;
        nativeCurrencyWrapper = _nativeCurrencyWrapper;
    }

    /// @notice Allows the contract to receive native currency
    /// @dev It is necessary to be able to receive native currency when using nativeCurrencyWrapper.withdraw()
    receive() external payable {}

    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @dev Pool's token A and token B don't need to be sorted
    @param zap Data for zap in - min amounts and dex index
    @param swapTokenA Data for swap tx pool's token A - amounts, path & DEX
    @param swapTokenB Data for swap tx pool's token B - amounts, path & DEX
    @param receiver LP token receiver address
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a ZapTx
    @return lpBought Amount of LP tokens transferred to receiver 
    @return lpToken LP token address
     */
    function zapIn(
        ZapInTx calldata zap,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        address receiver,
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
        TransferHelper.safeTransfer(lpToken, receiver, lpBought);

        emit ZapIn(msg.sender, receiver, swapTokenA.path[0], swapTokenA.amount + swapTokenB.amount, lpToken, lpBought);
    }

    /**
    @notice ZapTx out LP token in a single token
    @dev Pool's token A and token B don't need to be sorted
    @param zap Data for zap out - min amounts & DEX
    @param swapTokenA Data for swap tx pool's token A - amounts, path & DEX
    @param swapTokenB Data for swap tx pool's token B - amounts, path & DEX
    @param receiver Target token receiver address
    @param affiliate Affiliate address
    @return amountTransferred Amount of tokenTo transferred to receiver 
    @return tokenTo Target token address
    */
    function zapOut(
        ZapOutTx calldata zap,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        address receiver,
        address affiliate
    ) external nonReentrant stopInEmergency returns (uint256 amountTransferred, address tokenTo) {
        // check if target token is the same for both paths
        if (swapTokenA.path[swapTokenA.path.length - 1] != swapTokenB.path[swapTokenB.path.length - 1])
            revert InvalidTargetPath();
        tokenTo = swapTokenA.path[swapTokenA.path.length - 1];

        (uint256 amountTo, address lpToken) = _performZapOut(zap, swapTokenA, swapTokenB);

        amountTransferred = _getFeeAndTransferTokens(tokenTo, amountTo, receiver, affiliate);
        if (amountTransferred < zap.amountTokenToMin) revert InsufficientMinAmount();

        emit ZapOut(msg.sender, receiver, lpToken, zap.amountLpFrom, tokenTo, amountTransferred);
    }

    /** 
    @notice Set address exempt from fee
    */
    function setFeeWhitelist(address zapAddress, bool status) external onlyOwner {
        feeWhitelist[zapAddress] = status;
    }

    /** 
    @notice Set new affiliate split value
    */
    function setNewAffiliateSplit(uint16 _newAffiliateSplit) external onlyOwner {
        if (_newAffiliateSplit > 10000) revert ForbiddenValue();
        affiliateSplit = _newAffiliateSplit;
    }

    /** 
    @notice Set new affiliate status for specified address
    */
    function setAffiliateStatus(address _affiliate, bool _status) external onlyOwner {
        affiliates[_affiliate] = _status;
    }

    /** 
    @notice Set DEX's info which can be used for zap tx
    @param _dexIndex Index used to identify DEX within the contract
    @param _name DEX's conventional name used to identify DEX by the user 
    @param _router DEX's router address
    @param _factory DEX's factory address
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
    @notice Remove DEX's info which can be used for zap tx
    @param _dexIndex Index of the DEX not supported anymore by the contract
    */
    function removeSupportedDEX(uint8 _dexIndex) external onlyOwner {
        supportedDEXs[_dexIndex].router = address(0);
        supportedDEXs[_dexIndex].factory = address(0);
        supportedDEXs[_dexIndex].name = '';
    }

    /** 
    @notice Set the fee receiver address
    @param _feeTo Fee receiver address
    */
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeTo = _feeTo;
    }

    /** 
    @notice Set the fee setter address
    @param _feeToSetter Fee setter address
    */
    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeToSetter = _feeToSetter;
    }

    /**  
    @notice Set the protocol fee percent
    @param _protocolFee The new protocol fee percent 0-100% (range: 0-10000)
    */
    function setProtocolFee(uint16 _protocolFee) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        if (_protocolFee > 10000) revert ForbiddenValue();
        protocolFee = _protocolFee;
    }

    /** 
    @notice Withdraw protocolFee share, retaining affilliate share 
    @param tokens Tokens' addresses transferred to the owner as protocol fee
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
    @param tokens Tokens' addresses transferred to the msg sender as affiliate share of protocol fee
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
    @notice Check if DEX's address is valid and supported
    @return router DEX's router address
    @return factory DEX's factory address
    */
    function getSupportedDEX(uint8 _dexIndex) public view returns (address router, address factory) {
        router = supportedDEXs[_dexIndex].router;
        factory = supportedDEXs[_dexIndex].factory;
        if (router == address(0) || factory == address(0)) revert InvalidRouterOrFactory();
    }

    /** 
    @notice Internal zap in
    */
    function _performZapIn(
        uint256 amountAToInvest,
        uint256 amountBToInvest,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB,
        ZapInTx calldata zap,
        bool transferResidual
    ) internal returns (uint256 liquidity, address lpToken) {
        // check if dex address is valid and supported
        (address router, address factory) = getSupportedDEX(zap.dexIndex);

        lpToken = IDXswapFactory(factory).getPair(
            swapTokenA.path[swapTokenA.path.length - 1],
            swapTokenB.path[swapTokenB.path.length - 1]
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
    @notice Internal zap out
    */
    function _performZapOut(
        ZapOutTx calldata zap,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB
    ) internal returns (uint256 amountTo, address lpToken) {
        if (zap.amountLpFrom == 0) revert InvalidInputAmount();
        // check if dex address is valid and supported
        (address router, address factory) = getSupportedDEX(zap.dexIndex);

        lpToken = _pullLpTokens(zap.amountLpFrom, swapTokenA.path[0], swapTokenB.path[0], router, factory);

        // router.removeLiquidity() sorts tokens so no need to set them in exact order
        (uint256 amountA, uint256 amountB) = IDXswapRouter(router).removeLiquidity(
            swapTokenA.path[0],
            swapTokenB.path[0],
            zap.amountLpFrom,
            swapTokenA.amountMin,
            swapTokenB.amountMin,
            address(this),
            deadline
        );

        if (amountA == 0 || amountB == 0) revert InsufficientMinAmount();

        amountTo = _swapLpTokensToTargetTokens(amountA, amountB, swapTokenA, swapTokenB, address(this));
    }

    /** 
    @notice Transfer tokens or native currency to the contract for zap in
    @param swapTokenA Data for swap tx pool's token A - amounts, path & DEX
    @param swapTokenB Data for swap tx pool's token B - amounts, path & DEX
    @param affiliate Affiliate address
    @return amountAToInvest Token A amount to invest after fee substract
    @return amountBToInvest Token B amount to invest after fee substract
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
    @notice Transfer LP tokens to the contract for zap out
    @param amount LP tokens amount
    @param tokenA Pair's token A address 
    @param tokenB Pair's token B address
    @param router DEX router address
    @param factory DEX factory address
    @return lpToken LP tokens transferred from msg sender to the zap contract
    */
    function _pullLpTokens(
        uint256 amount,
        address tokenA,
        address tokenB,
        address router,
        address factory
    ) internal returns (address lpToken) {
        // validate pair
        lpToken = IDXswapFactory(factory).getPair(tokenA, tokenB);
        if (lpToken == address(0)) revert InvalidPair();

        _approveTokenIfNeeded(lpToken, amount, router);

        // pull LP tokens from sender
        TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), amount);
    }

    /** 
    @notice Subtract protocol fee for fee receiver and affiliate (if any)
    @param token Token address
    @param amount Token amount
    @param affiliate Affiliate address
    @return totalProtocolFeePortion Total amount of protocol fee taken
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
    @notice Internal fct for swapping lp pair's tokens
    @param amountAToInvest Amount from of pair's tokenA to swap
    @param amountBToInvest Amount from of pair's tokenB to swap
    @param swapTokenA Data for swap tx pool's token A - amounts, path & DEX
    @param swapTokenB Data for swap tx pool's token B - amounts, path & DEX
    */
    function _buyTokens(
        uint256 amountAToInvest,
        uint256 amountBToInvest,
        SwapTx calldata swapTokenA,
        SwapTx calldata swapTokenB
    ) internal returns (uint256 tokenABought, uint256 tokenBBought) {
        //
        (address routerSwapA, ) = getSupportedDEX(swapTokenA.dexIndex);
        (address routerSwapB, ) = getSupportedDEX(swapTokenB.dexIndex);
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
                routerSwapA
            );
            tokenBBought = _swapExactTokensForTokens(
                amountBToInvest,
                swapTokenB.amountMin,
                pathB,
                address(this),
                routerSwapB
            );

            return (tokenABought, tokenBBought);
        }

        tokenABought = _swapExactTokensForTokens(
            amountAToInvest,
            swapTokenA.amountMin,
            swapTokenA.path,
            address(this),
            routerSwapA
        );
        tokenBBought = _swapExactTokensForTokens(
            amountBToInvest,
            swapTokenB.amountMin,
            swapTokenB.path,
            address(this),
            routerSwapB
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
    @return amountA Token A amount added to LP
    @return amountB Token B amount added to LP
    @return liquidity LP tokens minted
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
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
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
            // returning residue in tokenA, if any
            if (amountADesired - amountA > 0) {
                TransferHelper.safeTransfer(tokenA, msg.sender, (amountADesired - amountA));
            }

            // returning residue in tokenB, if any
            if (amountBDesired - amountB > 0) {
                TransferHelper.safeTransfer(tokenB, msg.sender, (amountBDesired - amountB));
            }
        }
    }

    /**  
    @notice Approves the token if needed
    @param token The address of the token
    @param amount The amount of token to send
    */
    function _approveTokenIfNeeded(address token, uint256 amount, address router) internal {
        if (IERC20(token).allowance(address(this), router) < amount) {
            // Note: some tokens (e.g. USDT, KNC) allowance must be first reset
            // to 0 before being able to update it
            TransferHelper.safeApprove(token, router, 0);
            TransferHelper.safeApprove(token, router, amount);
        }
    }

    /** 
    @notice Get protocol fee from zap out tx and transfer tokens to receiver
    @param tokenTo Zap out target token's address
    @param amountTo tokenTo amount
    @param to Target token receiver address
    @param affiliate Affiliate address
    @return amountTransferred Target token transferred
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
    @notice Swap LP pair's tokens to target token
    @param amountA The amount of pair's token A to swap
    @param amountB The amount of pair's token B to swap
    @param swapTokenA Data for swap tx pool's token A - amounts, path & DEX
    @param swapTokenB Data for swap tx pool's token B - amounts, path & DEX
    @param to The address that will receive tokenTo
    @return amountTo The amount of token received
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