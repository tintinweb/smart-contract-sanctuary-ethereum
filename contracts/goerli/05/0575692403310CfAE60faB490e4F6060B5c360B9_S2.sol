// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/IS2Proxy.sol";
import "./S2Proxy.sol";


interface IVars {
    function depositsStopped() external view returns (bool);
    function uniswapSlippage() external view returns (uint8);
    function truTokenUniswapFee() external view returns (uint16);
    function mtaTokenUniswapFee() external view returns (uint16);
    function swapRouterAddress() external view returns (address);
    function quoterAddress() external view returns (address);
    function usdcAddress() external view returns (address);
    function wethAddress() external view returns (address);
    function feeCollector() external view returns (address);
    function trueFiUSDCAddress() external view returns (address);
    function trueFiTokenAddress() external view returns (address);
    function stakedTrueFiTokenAddress() external view returns (address);
    function farmTrueFiAddress() external view returns (address);
    function mStableA() external view returns (address);
    function mStableVaultA() external view returns (address);
    function mUSDAddress() external view returns (address);
    function imUSDAddress() external view returns (address);
    function mtaTokenAddress() external view returns (address);
    function validateWhitelistedDepositCurrencyFee(address _token) external view returns(bool);
    function getWhitelistedDepositCurrencyFee(address _token) external view returns(uint16);
    function calcWithdrawFeeBasedOnTokenOrNFT(uint256 _amount, address _address, address _feeToken, address _feeNFT, uint256 _nftID) external view returns (uint256);
}


contract S2 {
    address private varsA;
    address private swapRouterAddress;
    address private quoterAddress;
    address private wethAddress;
    address private usdcAddress;
    mapping(address => address) public depositors;

    constructor(
        address _varsA
    ) payable {
        varsA = _varsA;
        swapRouterAddress = IVars(varsA).swapRouterAddress();
        quoterAddress = IVars(varsA).quoterAddress();
        wethAddress = IVars(varsA).wethAddress();
        usdcAddress = IVars(varsA).usdcAddress();

        IERC20(wethAddress).approve(swapRouterAddress, 2**256 - 1);
        IERC20(IVars(varsA).trueFiTokenAddress()).approve(swapRouterAddress, 2**256 - 1);
        IERC20(IVars(varsA).mtaTokenAddress()).approve(swapRouterAddress, 2**256 - 1);
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, uint256 _amount2, address indexed _swappedTo);

    function depositETH() public payable {
        require(!IVars(varsA).depositsStopped(), "ERR: DEPOSITS_STOPPED");
        uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress);
        // calculate Uniswap amountOutMinimum to prevent sandwich attack
        uint256 quoteAmountOut = _getQuoteAmountOut(
            wethAddress,
            usdcAddress,
            usdcUniswapFee,
            msg.value
        );
        require(quoteAmountOut > 0, "ERR: quoteAmountOut");

        // Swap msg.value for USDC at Uniswap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : wethAddress,
            tokenOut : usdcAddress,
            fee : usdcUniswapFee,
            recipient : address(this),
            amountIn : msg.value,
            amountOutMinimum : (quoteAmountOut * (100 - IVars(varsA).uniswapSlippage())) / 100,
            sqrtPriceLimitX96 : 0
            });
        uint256 usdcAmount = ISwapRouter(swapRouterAddress).exactInputSingle{value : msg.value}(params);
        _yieldDeposit(usdcAmount);

        emit Deposit(msg.sender, wethAddress, msg.value, usdcAmount);
    }

    function depositTokens(address _token, uint256 _amount) external {
        require(!IVars(varsA).depositsStopped(), "ERR: DEPOSITS_STOPPED");
        require(IVars(varsA).validateWhitelistedDepositCurrencyFee(_token), "ERR: INVALID_DEPOSIT_TOKEN");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "ERR: INVALID_TRANSFER_FROM");

        uint256 usdcAmount;
        if (_token != usdcAddress) {
            // approve Uniswap router ONLY if needed
            if (IERC20(_token).allowance(address(this), swapRouterAddress) == 0) {
                IERC20(_token).approve(swapRouterAddress, 2**256 - 1);
            }

            uint16 tokenUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(_token);
            uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress);
            uint16 uniswapSlippage = IVars(varsA).uniswapSlippage();

            // calculate slippage to prevent sandwich attack
            uint256 quoteAmountOutTokenWeth = _getQuoteAmountOut(
                _token,
                wethAddress,
                tokenUniswapFee,
                _amount
            );
            require(quoteAmountOutTokenWeth > 0, "ERR: quoteAmountOutTokenWeth");

            bytes[] memory uniswapCalls = new bytes[](2);
            uniswapCalls[0] = _getEncodedSingleSwap(
                _token,
                wethAddress,
                tokenUniswapFee,
                _amount,
                (quoteAmountOutTokenWeth * (100 - uniswapSlippage)) / 100
            );

            uint256 quoteAmountOutWethToken = _getQuoteAmountOut(
                wethAddress,
                usdcAddress,
                usdcUniswapFee,
                quoteAmountOutTokenWeth
            );
            require(quoteAmountOutWethToken > 0, "ERR: quoteAmountOutWethToken");

            uniswapCalls[1] = _getEncodedSingleSwap(
                wethAddress,
                usdcAddress,
                usdcUniswapFee,
                quoteAmountOutTokenWeth,
                (quoteAmountOutWethToken * (100 - uniswapSlippage)) / 100
            );
            (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);
            usdcAmount = abi.decode(results[1], (uint256));
        } else {
            usdcAmount = _amount;
        }
        _yieldDeposit(usdcAmount);

        emit Deposit(msg.sender, _token, _amount, usdcAmount);
    }

    function _yieldDeposit(uint256 _amount) internal {
        uint256 yieldPortion = _amount / 2;
        uint256 remainder;
        if (_amount % 2 > 0) {
            remainder += _amount % 2;
        }

        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S2Proxy s2proxy = new S2Proxy(
                address(this),
                varsA,
                usdcAddress
            );
            depositors[msg.sender] = address(s2proxy);
            IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1);
            s2proxy.deposit(yieldPortion, yieldPortion + remainder);
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(usdcAddress).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1);
            }

            IS2Proxy(depositors[msg.sender]).deposit(yieldPortion, yieldPortion + remainder);
        }
    }

    function _getQuoteAmountOut(address _tokenIn, address _tokenOut, uint16 _fee, uint256 _amount) internal returns(uint256) {
        return IQuoter(quoterAddress).quoteExactInputSingle(
            _tokenIn,
            _tokenOut,
            _fee,
            _amount,
            0
        );
    }

    function _getEncodedSingleSwap(address _tokenIn, address _tokenOut, uint16 _fee, uint256 _amountIn, uint256 _amountOutMinimum) internal view returns(bytes memory) {
        return abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            ISwapRouter.ExactInputSingleParams({
            tokenIn : _tokenIn,
            tokenOut : _tokenOut,
            fee : _fee,
            recipient : address(this),
            amountIn : _amountIn,
            amountOutMinimum : _amountOutMinimum,
            sqrtPriceLimitX96 : 0
            })
        );
    }

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256, uint256) {
        uint256 _truToken = IFarmTrueFi(IVars(varsA).farmTrueFiAddress()).claimable(IERC20(IVars(varsA).trueFiUSDCAddress()), _address);
        (uint256 _mtaToken, , ) = ImStableVault(IVars(varsA).mStableVaultA()).unclaimedRewards(_address);
        return(_truToken, _mtaToken);
    }

    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 tfUSDCAmount = IFarmTrueFi(IVars(varsA).farmTrueFiAddress()).staked(
            IERC20(IVars(varsA).trueFiUSDCAddress()),
            _address
        );
        uint256 trueFiDeposit = (ITrueFiUSDC(IVars(varsA).trueFiUSDCAddress()).poolValue() * tfUSDCAmount) / ITrueFiUSDC(IVars(varsA).trueFiUSDCAddress()).totalSupply();
        trueFiDeposit = (trueFiDeposit * ITrueFiUSDC(IVars(varsA).trueFiUSDCAddress()).liquidExitPenalty(trueFiDeposit)) / 10000; // TrueFi's BASIS_PRECISION is 1000
        uint256 mStableDeposit = ImUSD(IVars(varsA).mUSDAddress()).getRedeemOutput(
            usdcAddress,
            IimUSD(IVars(varsA).imUSDAddress()).convertToAssets(
                IERC20(IVars(varsA).mStableVaultA()).balanceOf(_address)
            )
        );
        return (trueFiDeposit, mStableDeposit);
    }

    // claim TRU & MTA tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDepositor(msg.sender);

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, 0, address(0));
    }

    // claim TRU & MTA tokens, swap them for ETH and withdraw
    function claimInETH() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDeployer();

        (bytes[] memory uniswapCalls, ) = _prepareClaimUniswapCalls(truTokens, mtaTokens);
        (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(abi.decode(results[1], (uint256)));
        // withdraw ETH
        payable(msg.sender).transfer(abi.decode(results[1], (uint256)));

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, abi.decode(results[1], (uint256)), wethAddress);
    }

    // claim TRU & MTA tokens, swap them for _token and withdraw
    function claimInToken(address _token) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDeployer();

        (bytes[] memory uniswapCalls, uint256 totalQuote) = _prepareClaimUniswapCalls(truTokens, mtaTokens);
        // calculate slippage to prevent sandwich attack
        uint256 quoteAmountOutWethToken = _getQuoteAmountOut(
            wethAddress,
            _token,
            IVars(varsA).getWhitelistedDepositCurrencyFee(_token),
            totalQuote
        );
        require(quoteAmountOutWethToken > 0, "ERR: quoteAmountOutWethToken");

        // swap the WETH from TRU & MTA swaps into the token last used for deposit
        uniswapCalls[2] = _getEncodedSingleSwap(
            wethAddress,
            _token,
            IVars(varsA).getWhitelistedDepositCurrencyFee(_token),
            totalQuote,
            (quoteAmountOutWethToken * (100 - IVars(varsA).uniswapSlippage())) / 100
        );

        (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

        IERC20(_token).transfer(
            msg.sender,
            abi.decode(results[1], (uint256))
        );

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, abi.decode(results[1], (uint256)), _token);
    }

    function _prepareClaimUniswapCalls(uint256 _truTokens, uint256 _mtaTokens) internal returns(bytes[] memory, uint256) {
        bytes[] memory uniswapCalls;
        uint256 quoteAmountOutTRUTokenWeth;
        uint256 quoteAmountOutMTATokenWeth;
        uint8 uniswapSlippage = IVars(varsA).uniswapSlippage();
        uint16 truTokenUniswapFee = IVars(varsA).truTokenUniswapFee(); 
        uint16 mtaTokenUniswapFee = IVars(varsA).mtaTokenUniswapFee();  

        address trueFiTokenAddress = IVars(varsA).trueFiTokenAddress();
        // calculate slippage to prevent sandwich attack
        quoteAmountOutTRUTokenWeth = _getQuoteAmountOut(
            trueFiTokenAddress,
            wethAddress,
            truTokenUniswapFee,
            _truTokens
        );
        require(quoteAmountOutTRUTokenWeth > 0, "ERR: quoteAmountOutTRUTokenWeth");

        // swap the TRU tokens for WETH
        uniswapCalls[0] = _getEncodedSingleSwap(
            trueFiTokenAddress,
            wethAddress,
            truTokenUniswapFee,
            _truTokens,
            (quoteAmountOutTRUTokenWeth * (100 - uniswapSlippage)) / 100
        );

        address mtaTokenAddress = IVars(varsA).mtaTokenAddress();
        // calculate slippage to prevent sandwich attack
        quoteAmountOutMTATokenWeth = _getQuoteAmountOut(
            mtaTokenAddress,
            wethAddress,
            mtaTokenUniswapFee,
            _mtaTokens
        );
        require(quoteAmountOutMTATokenWeth > 0, "ERR: quoteAmountOutMTATokenWeth");

        // swap the MTA tokens for WETH
        uniswapCalls[1] = _getEncodedSingleSwap(
            mtaTokenAddress,
            wethAddress,
            mtaTokenUniswapFee,
            _mtaTokens,
            (quoteAmountOutMTATokenWeth * (100 - uniswapSlippage)) / 100
        );

        return (uniswapCalls, quoteAmountOutTRUTokenWeth + quoteAmountOutMTATokenWeth);
    }

    function withdrawETH(uint256 _truAmount, uint256 _mtaAmount, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _mtaAmount, _feeToken, _feeNFT, _nftID);

        if (IERC20(usdcAddress).allowance(address(this), swapRouterAddress) == 0) {
            IERC20(usdcAddress).approve(swapRouterAddress, 2**256 - 1); 
        }

        // calculate slippage to prevent sandwich attack
        uint256 quoteWethAmountOut = _getQuoteAmountOut(
            usdcAddress,
            wethAddress,
            IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress),
            yieldDeposit - fee
        );
        require(quoteWethAmountOut > 0, "ERR: quoteAmountOut");

        // swap USDC for WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : usdcAddress,
            tokenOut : wethAddress,
            fee : IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress),
            recipient : address(this),
            amountIn : yieldDeposit - fee,
            amountOutMinimum : (quoteWethAmountOut * (100 - IVars(varsA).uniswapSlippage())) / 100,
            sqrtPriceLimitX96 : 0
            });
        uint256 wethAmount = ISwapRouter(swapRouterAddress).exactInputSingle(params);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        payable(msg.sender).transfer(wethAmount);

        emit Withdraw(msg.sender, wethAddress, wethAmount, fee);
    }

    function withdrawToken(address _token, uint256 _truAmount, uint256 _mtaAmount, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _mtaAmount, _feeToken, _feeNFT, _nftID);
        if (_token == usdcAddress) {
            // withdraw USDC
            IERC20(usdcAddress).transfer(
                msg.sender,
                yieldDeposit - fee
            );

            emit Withdraw(msg.sender, usdcAddress, yieldDeposit - fee, fee);
        } else {
            if (IERC20(usdcAddress).allowance(address(this), swapRouterAddress) == 0) {
                IERC20(usdcAddress).approve(swapRouterAddress, 2**256 - 1);
            }

            // calculate slippage to prevent sandwich attack
            uint256 quoteWethAmountOut = _getQuoteAmountOut(
                usdcAddress,
                wethAddress,
                IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress),
                yieldDeposit - fee
            );
            require(quoteWethAmountOut > 0, "ERR: quoteAmountOut");

            bytes[] memory uniswapCalls = new bytes[](2);
            // swap USDC for WETH
            uniswapCalls[0] = _getEncodedSingleSwap(
                usdcAddress,
                wethAddress,
                IVars(varsA).getWhitelistedDepositCurrencyFee(usdcAddress),
                yieldDeposit - fee,
                (quoteWethAmountOut * (100 - IVars(varsA).uniswapSlippage())) / 100
            );

            // calculate slippage to prevent sandwich attack
            uint256 quoteTokenAmountOut = _getQuoteAmountOut(
                wethAddress,
                _token,
                IVars(varsA).getWhitelistedDepositCurrencyFee(_token),
                quoteWethAmountOut
            );
            require(quoteTokenAmountOut > 0, "ERR: quoteAmountOut");

            // swap WETH for _token
            uniswapCalls[1] = _getEncodedSingleSwap(
                wethAddress,
                _token,
                IVars(varsA).getWhitelistedDepositCurrencyFee(_token),
                quoteWethAmountOut,
                (quoteTokenAmountOut * (100 - IVars(varsA).uniswapSlippage())) / 100
            );
            (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

            IERC20(_token).transfer(
                msg.sender,
                abi.decode(results[1], (uint256))
            );

            emit Withdraw(msg.sender, _token, abi.decode(results[1], (uint256)), fee);
        }
    }

    function _withdrawYieldDeposit(uint256 _trueFiAmount, uint256 _mStableAmount, address _feeToken, address _feeNFT, uint256 _nftID) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS2Proxy(depositors[msg.sender]).withdraw(_trueFiAmount, _mStableAmount);
        require(IERC20(usdcAddress).transferFrom(depositors[msg.sender], address(this), usdcAmountToBeWithdrawn), "ERR: INVALID_TRANSFER_FROM");

        uint256 fee = (usdcAmountToBeWithdrawn * IVars(varsA).calcWithdrawFeeBasedOnTokenOrNFT(usdcAmountToBeWithdrawn, msg.sender, _feeToken, _feeNFT, _nftID)) / 1000;
        // if fee then send it to the feeCollector
        if (fee > 0) {
            IERC20(usdcAddress).transfer(
                IVars(varsA).feeCollector(),
                fee
            );
        }
        return (usdcAmountToBeWithdrawn, fee);
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISwapRouter {
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}


interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS2Proxy {
    function deposit(uint256 _trueFiDeposit, uint256 mStableDeposit) external;
    function withdraw(uint256 _truAmount, uint256 _mtaAmount) external returns(uint256);
    function claimToDepositor(address _depositor) external returns(uint256, uint256);
    function claimToDeployer() external returns(uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/ITrueFi.sol";
import "./interfaces/ImStable.sol";


interface IVarsP {
    function trueFiUSDCAddress() external view returns (address);
    function trueFiTokenAddress() external view returns (address);
    function stakedTrueFiTokenAddress() external view returns (address);
    function farmTrueFiAddress() external view returns (address);
    function mStableA() external view returns (address);
    function mStableVaultA() external view returns (address);
    function mUSDAddress() external view returns (address);
    function imUSDAddress() external view returns (address);
    function mtaTokenAddress() external view returns (address);
}


contract S2Proxy {
    address public deployer;
    address private varsA;
    address private usdcAddress;

    constructor(
        address _deployer,
        address _varsA,
        address _usdcAddress
    ) payable {
        varsA = _varsA;
        deployer = _deployer;
        usdcAddress = _usdcAddress;

        address trueFiUSDCAddress = IVarsP(varsA).trueFiUSDCAddress();
        IERC20(usdcAddress).approve(_deployer, 2**256 - 1);
        IERC20(usdcAddress).approve(trueFiUSDCAddress, 2**256 - 1);
        IERC20(usdcAddress).approve(IVarsP(varsA).mStableA(), 2**256 - 1);
        IERC20(trueFiUSDCAddress).approve(IVarsP(varsA).farmTrueFiAddress(), 2**256 - 1);
        IERC20(IVarsP(varsA).trueFiTokenAddress()).approve(IVarsP(varsA).stakedTrueFiTokenAddress(), 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(uint256 _trueFiDeposit, uint256 _mStableDeposit) external onlyDeployer {
        require(IERC20(usdcAddress).transferFrom(deployer, address(this), _trueFiDeposit + _mStableDeposit), "ERR: INVALID_TRANSFER_FROM");

        // TrueFi deposit
        address trueFiUSDCAddress = IVarsP(varsA).trueFiUSDCAddress(); 
        ITrueFiUSDC(trueFiUSDCAddress).join(_trueFiDeposit); 
        //IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).stake(
        //    IERC20(trueFiUSDCAddress),
        //    IERC20(trueFiUSDCAddress).balanceOf(address(this))
        //);

        // mStable deposit
        ImStable(IVarsP(varsA).mStableA()).saveViaMint(
            IVarsP(varsA).mUSDAddress(),
            IVarsP(varsA).imUSDAddress(),
            IVarsP(varsA).mStableVaultA(),
            usdcAddress,
            _mStableDeposit,
            _mStableDeposit * 10 ** 12 - (((_mStableDeposit * 10 ** 12) * 5) / 100),  // scaling the min amount to 18 decimals and removing 5 percents
            true
        );
    }

    function withdraw(uint256 _trueFiAmount, uint256 _mStableAmount) external onlyDeployer returns(uint256) {
        // unstake TrueFi tfUSDC
        address trueFiUSDCAddress = IVarsP(varsA).trueFiUSDCAddress();
        //IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).unstake(
        //    IERC20(trueFiUSDCAddress),
        //    _trueFiAmount
        //);

        // TrueFi withdraw ( swap tfUSDC for USDC )
        ITrueFiUSDC(trueFiUSDCAddress).liquidExit(IERC20(trueFiUSDCAddress).balanceOf(address(this)));

        // mStable withdraw
        ImStableVault(IVarsP(varsA).mStableVaultA()).withdraw(_mStableAmount);
        // swap imUSD for mUSD
        uint256 balanceToBeListed = IERC20(IVarsP(varsA).imUSDAddress()).balanceOf(address(this));
        uint256 credits = IimUSD(IVarsP(varsA).imUSDAddress()).redeemCredits(IERC20(IVarsP(varsA).imUSDAddress()).balanceOf(address(this)));
        credits = balanceToBeListed; // delete on MAINNET
        // swap mUSD for USDC
        ImUSD(IVarsP(varsA).mUSDAddress()).redeem(
            usdcAddress,
            credits,
            ImUSD(IVarsP(varsA).mUSDAddress()).getRedeemOutput(usdcAddress, credits),
            address(this)
        );

        return IERC20(usdcAddress).balanceOf(address(this));
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256, uint256) {
        (uint256 truTokens, uint256 mtaTokens) = _claim(_depositor);
        return (truTokens, mtaTokens);
    }

    function claimToDeployer() external onlyDeployer returns(uint256, uint256) {
        (uint256 truTokens, uint256 mtaTokens) = _claim(deployer);
        return (truTokens, mtaTokens);
    }

    function _claim(address _address) private returns(uint256, uint256) {
        // TRU tokens
        IERC20[] memory tokens;
        tokens[0] = IERC20(IVarsP(varsA).trueFiUSDCAddress());
        IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).claim(tokens);

        // MTA tokens
        address mStableVaultA = IVarsP(varsA).mStableVaultA();
        (, uint256 first, uint256 last) = ImStableVault(mStableVaultA).unclaimedRewards(address(this));
        ImStableVault(mStableVaultA).claimRewards(first, last);

        uint256 truBalance = IERC20(IVarsP(varsA).trueFiTokenAddress()).balanceOf(address(this));
        IERC20(IVarsP(varsA).trueFiTokenAddress()).transfer(
            _address,
            truBalance
        );

        uint256 mtaBalance = IERC20(IVarsP(varsA).mtaTokenAddress()).balanceOf(address(this));
        IERC20(IVarsP(varsA).mtaTokenAddress()).transfer(
            _address,
            mtaBalance
        );

        return(truBalance, mtaBalance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ImStable {
    function saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake
    ) external;
}


interface ImStableVault {
    function withdraw(uint256 _amount) external;

    function unclaimedRewards(address _account) external view returns (uint256, uint256, uint256);

    function claimRewards(uint256 _first, uint256 _last) external;
}


interface ImUSD {
    function getRedeemOutput(
        address _output,
        uint256 _mAssetQuantity
    ) external view returns (uint256);

    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256);
}


interface IimUSD {
    function redeemCredits(uint256 _credits) external returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IERC20.sol";

interface ITrueFiUSDC {
    function join(uint256 amount) external;

    function liquidExit(uint256 amount) external;

    function liquidExitPenalty(uint256 amount) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function poolValue() external view returns (uint256);
}


interface IFarmTrueFi {
    function stake(IERC20 token, uint256 amount) external;

    function unstake(IERC20 token, uint256 amount) external;

    function claim(IERC20[] calldata tokens) external;

    function staked(IERC20 token, address staker) external view returns (uint256);

    function claimable(IERC20 token, address account) external view returns (uint256);
}


interface IStkTruToken {
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;
}