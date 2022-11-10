// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1TrueFiProxy.sol";


interface IVars {
    function getDepositsStopped(uint8 _structIndex) external view returns(bool);
    function getUniswapSlippage(uint8 _structIndex) external view returns(uint8);
    function getFeeCollector(uint8 _structIndex) external view returns(address);
    function truTokenUniswapFee() external view returns (uint16);
    function swapRouterAddress() external view returns (address);
    function wethAddress() external view returns (address);
    function trueFiTokenAddress() external view returns (address);
    function stakedTrueFiTokenAddress() external view returns (address);
    function farmTrueFiAddress() external view returns (address);
    function validateWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) external view returns(bool);
    function getWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) external view returns(uint16);
    function calcWithdrawFeeBasedOnTokenOrNFT(uint256 _amount, address _address, address _feeToken, address _feeNFT, uint256 _nftID) external view returns (uint256);
}


contract S1TrueFi {
    address public varsA;
    address private swapRouterAddress;
    address private wethAddress;
    address private depositIn;
    address private tfDepositIn;
    uint8 private varsIndex;
    mapping(address => address) public depositors;

    constructor(
        address _varsA,
        address _depositIn,
        address _tfDepositIn,
        uint8 _varsIndex
    ) payable {
        varsA = _varsA;
        swapRouterAddress = IVars(varsA).swapRouterAddress();
        wethAddress = IVars(varsA).wethAddress();
        depositIn = _depositIn;
        tfDepositIn = _tfDepositIn;
        varsIndex = _varsIndex;

        IERC20(wethAddress).approve(swapRouterAddress, 2**256 - 1);
        IERC20(IVars(varsA).trueFiTokenAddress()).approve(swapRouterAddress, 2**256 - 1);
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    function depositETH(uint256 tokenAmountOut) public payable {
        require(!IVars(varsA).getDepositsStopped(varsIndex), "ERR: DEPOSITS_STOPPED");
        uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, depositIn);

        // Swap msg.value for USDC at Uniswap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn : wethAddress,
                tokenOut : depositIn,
                fee : usdcUniswapFee,
                recipient : address(this),
                amountIn : msg.value,
                amountOutMinimum : (tokenAmountOut * (100 - IVars(varsA).getUniswapSlippage(varsIndex))) / 100,
                sqrtPriceLimitX96 : 0
            });
        uint256 usdcAmount = ISwapRouter(swapRouterAddress).exactInputSingle{value : msg.value}(params);
        _yieldDeposit(usdcAmount);

        emit Deposit(msg.sender, wethAddress, msg.value, usdcAmount);
    }

    function depositTokens(address _token, uint256 _amount, uint256 wethAmountOut, uint256 tokenAmountOut) external {
        require(!IVars(varsA).getDepositsStopped(varsIndex), "ERR: DEPOSITS_STOPPED");
        require(IVars(varsA).validateWhitelistedDepositCurrencyFee(varsIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "ERR: INVALID_TRANSFER_FROM");

        uint256 usdcAmount;
        if (_token != depositIn) {
            // approve Uniswap router ONLY if needed
            if (IERC20(_token).allowance(address(this), swapRouterAddress) == 0) {
                IERC20(_token).approve(swapRouterAddress, 2**256 - 1);
            }

            uint16 tokenUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, _token);
            uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, depositIn);
            uint16 uniswapSlippage = IVars(varsA).getUniswapSlippage(0); 

            bytes[] memory uniswapCalls = new bytes[](2);
            uniswapCalls[0] = _getEncodedSingleSwap(
                _token,
                wethAddress,
                tokenUniswapFee,
                _amount,
                (wethAmountOut * (100 - uniswapSlippage)) / 100
            );

            uniswapCalls[1] = _getEncodedSingleSwap(
                wethAddress,
                depositIn,
                usdcUniswapFee,
                wethAmountOut,
                (tokenAmountOut * (100 - uniswapSlippage)) / 100 
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
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1TrueFiProxy s1proxy = new S1TrueFiProxy(
                address(this),
                varsA,
                depositIn,
                tfDepositIn
            );
            depositors[msg.sender] = address(s1proxy);
            IERC20(depositIn).approve(depositors[msg.sender], 2**256 - 1);
            s1proxy.deposit(_amount); 
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(depositIn).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(depositIn).approve(depositors[msg.sender], 2**256 - 1); 
            }
            
            IS1Proxy(depositors[msg.sender]).deposit(_amount);  
        }
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
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256) {
        uint256 _truToken = IFarmTrueFi(IVars(varsA).farmTrueFiAddress()).claimable(IERC20(tfDepositIn), _address);
        return _truToken;
    } 
    
    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256) {
        uint256 tfUSDCAmount = IFarmTrueFi(IVars(varsA).farmTrueFiAddress()).staked(
            IERC20(tfDepositIn),
            _address
        );
        uint256 trueFiDeposit = (ITrueFi(tfDepositIn).poolValue() * tfUSDCAmount) / ITrueFi(tfDepositIn).totalSupply();
        trueFiDeposit = (trueFiDeposit * ITrueFi(tfDepositIn).liquidExitPenalty(trueFiDeposit)) / 10000; // TrueFi's BASIS_PRECISION is 1000
        return trueFiDeposit;
    }

    // claim TRU tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS1Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, truTokens, 0, address(0));
    }

    // claim TRU tokens, swap them for ETH and withdraw
    function claimInETH(uint256 wethAmountOut) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer(); 
        address trueFiTokenAddress = IVars(varsA).trueFiTokenAddress();
        uint16 truTokenUniswapFee = IVars(varsA).truTokenUniswapFee();

        // swap USDC for WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : trueFiTokenAddress,
            tokenOut : wethAddress,
            fee : truTokenUniswapFee,
            recipient : address(this),
            amountIn : truTokens,
            amountOutMinimum : (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(varsIndex))) / 100, 
            sqrtPriceLimitX96 : 0
        });
        uint256 wethAmount = ISwapRouter(swapRouterAddress).exactInputSingle(params);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        payable(msg.sender).transfer(wethAmount);

        emit ClaimAdditionalTokens(msg.sender, truTokens, wethAmount, wethAddress);
    }

    // claim TRU tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 wethAmountOut, uint256 tokenAmountOut) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        uint256 truTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer(); 
        bytes[] memory uniswapCalls;
        uint8 uniswapSlippage = IVars(varsA).getUniswapSlippage(varsIndex); 
        address trueFiTokenAddress = IVars(varsA).trueFiTokenAddress();
        uint16 truTokenUniswapFee = IVars(varsA).truTokenUniswapFee(); 

        // swap the TRU tokens for WETH
        uniswapCalls[0] = _getEncodedSingleSwap(
            trueFiTokenAddress,
            wethAddress,
            truTokenUniswapFee,
            truTokens,
            (wethAmountOut * (100 - uniswapSlippage)) / 100
        );

        // swap the WETH from TRU swaps into the token last used for deposit
        uniswapCalls[1] = _getEncodedSingleSwap(
            wethAddress,
            _token,
            IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, _token),
            wethAmountOut,
            (tokenAmountOut * (100 - uniswapSlippage)) / 100 
        );

        (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

        IERC20(_token).transfer(
            msg.sender,
            abi.decode(results[1], (uint256))
        );

        emit ClaimAdditionalTokens(msg.sender, truTokens, abi.decode(results[1], (uint256)), _token);
    }

    function withdrawETH(uint256 _truAmount, uint256 wethAmountOut, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _feeToken, _feeNFT, _nftID);

        if (IERC20(depositIn).allowance(address(this), swapRouterAddress) == 0) {
            IERC20(depositIn).approve(swapRouterAddress, 2**256 - 1);
        }

        // swap USDC for WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : depositIn,
            tokenOut : wethAddress,
            fee : IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, depositIn),
            recipient : address(this),
            amountIn : yieldDeposit - fee,
            amountOutMinimum : (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(varsIndex))) / 100,
            sqrtPriceLimitX96 : 0
        });
        uint256 wethAmount = ISwapRouter(swapRouterAddress).exactInputSingle(params);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount); 
        // withdraw ETH
        payable(msg.sender).transfer(wethAmount);

        emit Withdraw(msg.sender, wethAddress, wethAmount, fee);
    }

    function withdrawToken(address _token, uint256 _truAmount, uint256 wethAmountOut, uint256 tokenAmountOut, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _feeToken, _feeNFT, _nftID);
        if (_token == depositIn) { 
            // withdraw USDC
            IERC20(depositIn).transfer(
                msg.sender,
                yieldDeposit - fee
            );

            emit Withdraw(msg.sender, depositIn, yieldDeposit - fee, fee);
        } else {
            if (IERC20(depositIn).allowance(address(this), swapRouterAddress) == 0) {
                IERC20(depositIn).approve(swapRouterAddress, 2**256 - 1);
            }

            bytes[] memory uniswapCalls = new bytes[](2);
            // swap USDC for WETH
            uniswapCalls[0] = _getEncodedSingleSwap(
                depositIn,
                wethAddress,
                IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, depositIn),
                yieldDeposit - fee,
                (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(varsIndex))) / 100
            );

            // swap WETH for _token
            uniswapCalls[1] = _getEncodedSingleSwap(
                wethAddress,
                _token,
                IVars(varsA).getWhitelistedDepositCurrencyFee(varsIndex, _token),
                wethAmountOut, 
                (tokenAmountOut * (100 - IVars(varsA).getUniswapSlippage(varsIndex))) / 100
            );
            (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

            IERC20(_token).transfer(
                msg.sender,
                abi.decode(results[1], (uint256))
            );

            emit Withdraw(msg.sender, _token, abi.decode(results[1], (uint256)), fee);
        }
    }

    function _withdrawYieldDeposit(uint256 _truAmount, address _feeToken, address _feeNFT, uint256 _nftID) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_truAmount); 
        require(IERC20(depositIn).transferFrom(depositors[msg.sender], address(this), usdcAmountToBeWithdrawn), "ERR: INVALID_TRANSFER_FROM");
        
        // if fee then send it to the feeCollector
        uint256 fee = (usdcAmountToBeWithdrawn * IVars(varsA).calcWithdrawFeeBasedOnTokenOrNFT(usdcAmountToBeWithdrawn, msg.sender, _feeToken, _feeNFT, _nftID)) / 1000;
        if (fee > 0) { 
            IERC20(depositIn).transfer(
                IVars(varsA).getFeeCollector(varsIndex),
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

interface IWETH {
    function withdraw(uint wad) external;
}

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

interface IS1Proxy {
    function deposit(uint256 _deposit) external;
    function depositETH() external payable;
    function withdraw(uint256 _amount) external returns(uint256);
    function claimToDepositor(address _depositor) external returns(uint256);
    function claimToDeployer() external returns(uint256);
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

import "../interfaces/IERC20.sol";
import "../interfaces/ITrueFi.sol";


interface IVarsP {
    function trueFiTokenAddress() external view returns (address);
    function stakedTrueFiTokenAddress() external view returns (address);
    function farmTrueFiAddress() external view returns (address);
}


contract S1TrueFiProxy {
    address public deployer;
    address private varsA;
    address private depositIn;
    address private tfDepositIn;

    constructor(
        address _deployer,
        address _varsA,
        address _depositIn,
        address _tfDepositIn
    ) payable {
        varsA = _varsA;
        deployer = _deployer;
        depositIn = _depositIn;
        tfDepositIn = _tfDepositIn;

        IERC20(depositIn).approve(_deployer, 2**256 - 1);
        IERC20(depositIn).approve(tfDepositIn, 2**256 - 1);
        IERC20(tfDepositIn).approve(IVarsP(varsA).farmTrueFiAddress(), 2**256 - 1);
        IERC20(IVarsP(varsA).trueFiTokenAddress()).approve(IVarsP(varsA).stakedTrueFiTokenAddress(), 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    }

    function deposit(uint256 _trueFiDeposit) external onlyDeployer {
        require(IERC20(depositIn).transferFrom(deployer, address(this), _trueFiDeposit), "ERR: INVALID_TRANSFER_FROM");

        // TrueFi deposit
        ITrueFi(tfDepositIn).join(_trueFiDeposit);
        IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).stake(
            IERC20(tfDepositIn),
            IERC20(tfDepositIn).balanceOf(address(this))
        );
    }

    function withdraw(uint256 _trueFiAmount) external onlyDeployer returns(uint256) {
        // unstake TrueFi tfUSDC
        IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).unstake(
            IERC20(tfDepositIn),
            _trueFiAmount
        );

        // TrueFi withdraw ( swap tfUSDC for USDC )
        ITrueFi(tfDepositIn).liquidExit(IERC20(tfDepositIn).balanceOf(address(this)));

        return IERC20(depositIn).balanceOf(address(this));
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        // TRU tokens
        IERC20[] memory tokens;
        tokens[0] = IERC20(tfDepositIn);
        IFarmTrueFi(IVarsP(varsA).farmTrueFiAddress()).claim(tokens);

        uint256 truBalance = IERC20(IVarsP(varsA).trueFiTokenAddress()).balanceOf(address(this));
        IERC20(IVarsP(varsA).trueFiTokenAddress()).transfer(
            _address,
            truBalance
        );

        return truBalance;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IERC20.sol";

interface ITrueFi {
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