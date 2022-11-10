// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1mStableUSDCProxy.sol";


interface IVars {
    function getDepositsStopped(uint8 _structIndex) external view returns(bool);
    function getUniswapSlippage(uint8 _structIndex) external view returns(uint8);
    function getFeeCollector(uint8 _structIndex) external view returns(address);
    function mtaTokenUniswapFee() external view returns (uint16);
    function swapRouterAddress() external view returns (address);
    function usdcAddress() external view returns (address);
    function wethAddress() external view returns (address);
    function mStableA() external view returns (address);
    function mStableVaultA() external view returns (address);
    function mUSDAddress() external view returns (address);
    function imUSDAddress() external view returns (address);
    function mtaTokenAddress() external view returns (address);
    function validateWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) external view returns(bool);
    function getWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) external view returns(uint16);
    function calcWithdrawFeeBasedOnTokenOrNFT(uint256 _amount, address _address, address _feeToken, address _feeNFT, uint256 _nftID) external view returns (uint256);
}


contract S1mStableUSDC {
    address public varsA;
    address private swapRouterAddress;
    address private wethAddress;
    address private usdcAddress;
    mapping(address => address) public depositors; 

    constructor(
        address _varsA
    ) payable {
        varsA = _varsA;
        swapRouterAddress = IVars(varsA).swapRouterAddress();
        wethAddress = IVars(varsA).wethAddress();
        usdcAddress = IVars(varsA).usdcAddress();

        IERC20(wethAddress).approve(swapRouterAddress, 2**256 - 1);
        IERC20(IVars(varsA).mtaTokenAddress()).approve(swapRouterAddress, 2**256 - 1);
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    function depositETH(uint256 tokenAmountOut) public payable {
        require(!IVars(varsA).getDepositsStopped(2), "ERR: DEPOSITS_STOPPED");
        uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(2, usdcAddress);

        // Swap msg.value for USDC at Uniswap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : wethAddress,
            tokenOut : usdcAddress,
            fee : usdcUniswapFee,
            recipient : address(this),
            amountIn : msg.value,
            amountOutMinimum : (tokenAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100,
            sqrtPriceLimitX96 : 0
        });
        uint256 usdcAmount = ISwapRouter(swapRouterAddress).exactInputSingle{value : msg.value}(params);
        _yieldDeposit(usdcAmount);

        emit Deposit(msg.sender, wethAddress, msg.value, usdcAmount);
    }

    function depositTokens(address _token, uint256 _amount, uint256 wethAmountOut, uint256 tokenAmountOut) external {
        require(!IVars(varsA).getDepositsStopped(2), "ERR: DEPOSITS_STOPPED");
        require(IVars(varsA).validateWhitelistedDepositCurrencyFee(2, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "ERR: INVALID_TRANSFER_FROM");

        uint256 usdcAmount;
        if (_token != usdcAddress) {
            // approve Uniswap router ONLY if needed
            if (IERC20(_token).allowance(address(this), swapRouterAddress) == 0) {
                IERC20(_token).approve(swapRouterAddress, 2**256 - 1);
            }

            uint16 tokenUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(2, _token);
            uint16 usdcUniswapFee = IVars(varsA).getWhitelistedDepositCurrencyFee(2, usdcAddress);
            uint16 uniswapSlippage = IVars(varsA).getUniswapSlippage(2);

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
                usdcAddress,
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
            S1mStableUSDTProxy s1proxy = new S1mStableUSDTProxy(
                address(this),
                varsA,
                usdcAddress
            );
            depositors[msg.sender] = address(s1proxy);
            IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1);
            s1proxy.deposit(_amount); 
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(usdcAddress).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1); 
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
        (uint256 _mtaToken, , ) = ImStableVault(IVars(varsA).mStableVaultA()).unclaimedRewards(_address);
        return _mtaToken;
    } 
    
    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256) {
        uint256 mStableDeposit = ImUSD(IVars(varsA).mUSDAddress()).getRedeemOutput(
            usdcAddress,
            IimUSD(IVars(varsA).imUSDAddress()).convertToAssets(
                IERC20(IVars(varsA).mStableVaultA()).balanceOf(_address)
            )
        );
        return mStableDeposit;
    }

    // claim MTA tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 mtaTokens = IS1Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, 0, address(0));
    }

    // claim MTA tokens, swap them for ETH and withdraw
    function claimInETH(uint256 wethAmountOut) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 mtaTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer(); 
        address mtaTokenAddress = IVars(varsA).mtaTokenAddress();
        uint16 mtaTokenUniswapFee = IVars(varsA).mtaTokenUniswapFee();

        // swap USDC for WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : mtaTokenAddress,
            tokenOut : wethAddress,
            fee : mtaTokenUniswapFee,
            recipient : address(this),
            amountIn : mtaTokens,
            amountOutMinimum : (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100, 
            sqrtPriceLimitX96 : 0
        });
        uint256 wethAmount = ISwapRouter(swapRouterAddress).exactInputSingle(params);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount); 
        // withdraw ETH
        payable(msg.sender).transfer(wethAmount);

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, wethAmount, wethAddress);
    }

    // claim MTA tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 wethAmountOut, uint256 tokenAmountOut) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        uint256 mtaTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer(); 
        bytes[] memory uniswapCalls;
        uint8 uniswapSlippage = IVars(varsA).getUniswapSlippage(2); 
        address mtaTokenAddress = IVars(varsA).mtaTokenAddress();
        uint16 mtaTokenUniswapFee = IVars(varsA).mtaTokenUniswapFee();

        // swap the MTA tokens for WETH
        uniswapCalls[0] = _getEncodedSingleSwap(
            mtaTokenAddress,
            wethAddress,
            mtaTokenUniswapFee,
            mtaTokens,
            (wethAmountOut * (100 - uniswapSlippage)) / 100
        );

        // swap the WETH from MTA swaps into the token last used for deposit
        uniswapCalls[1] = _getEncodedSingleSwap(
            wethAddress,
            _token,
            IVars(varsA).getWhitelistedDepositCurrencyFee(2, _token),
            wethAmountOut,
            (tokenAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100
        );

        (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

        IERC20(_token).transfer(
            msg.sender,
            abi.decode(results[1], (uint256))
        );

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, abi.decode(results[1], (uint256)), _token);
    }

    function withdrawETH(uint256 _mtaAmount, uint256 wethAmountOut, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_mtaAmount, _feeToken, _feeNFT, _nftID);

        if (IERC20(usdcAddress).allowance(address(this), swapRouterAddress) == 0) {
            IERC20(usdcAddress).approve(swapRouterAddress, 2**256 - 1);
        }

        // swap USDC for WETH
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn : usdcAddress,
            tokenOut : wethAddress,
            fee : IVars(varsA).getWhitelistedDepositCurrencyFee(2, usdcAddress),
            recipient : address(this),
            amountIn : yieldDeposit - fee,
            amountOutMinimum : (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100,
            sqrtPriceLimitX96 : 0
        });
        uint256 wethAmount = ISwapRouter(swapRouterAddress).exactInputSingle(params);

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount); 
        // withdraw ETH
        payable(msg.sender).transfer(wethAmount);

        emit Withdraw(msg.sender, wethAddress, wethAmount, fee);
    }

    function withdrawToken(address _token, uint256 _mtaAmount, uint256 wethAmountOut, uint256 tokenAmountOut, address _feeToken, address _feeNFT, uint256 _nftID) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_mtaAmount, _feeToken, _feeNFT, _nftID);
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

            bytes[] memory uniswapCalls = new bytes[](2);
            // swap USDC for WETH
            uniswapCalls[0] = _getEncodedSingleSwap(
                usdcAddress,
                wethAddress,
                IVars(varsA).getWhitelistedDepositCurrencyFee(2, usdcAddress),
                yieldDeposit - fee,
                (wethAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100
            );

            // swap WETH for _token
            uniswapCalls[1] = _getEncodedSingleSwap(
                wethAddress,
                _token,
                IVars(varsA).getWhitelistedDepositCurrencyFee(2, _token),
                wethAmountOut,
                (tokenAmountOut * (100 - IVars(varsA).getUniswapSlippage(2))) / 100
            );
            (bytes[] memory results) = ISwapRouter(swapRouterAddress).multicall(uniswapCalls);

            IERC20(_token).transfer(
                msg.sender,
                abi.decode(results[1], (uint256)) 
            );

            emit Withdraw(msg.sender, _token, abi.decode(results[1], (uint256)), fee);
        }
    }

    function _withdrawYieldDeposit(uint256 _mStableAmount, address _feeToken, address _feeNFT, uint256 _nftID) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_mStableAmount); 
        require(IERC20(usdcAddress).transferFrom(depositors[msg.sender], address(this), usdcAmountToBeWithdrawn), "ERR: INVALID_TRANSFER_FROM");
        
        uint256 fee = (usdcAmountToBeWithdrawn * IVars(varsA).calcWithdrawFeeBasedOnTokenOrNFT(usdcAmountToBeWithdrawn, msg.sender, _feeToken, _feeNFT, _nftID)) / 1000;
        // if fee then send it to the feeCollector 
        if (fee > 0) {
            IERC20(usdcAddress).transfer(
                IVars(varsA).getFeeCollector(2),
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

import "../interfaces/IERC20.sol";
import "../interfaces/ImStable.sol"; 


interface IVarsP {
    function mStableA() external view returns (address);
    function mStableVaultA() external view returns (address);
    function mUSDAddress() external view returns (address);
    function imUSDAddress() external view returns (address);
    function mtaTokenAddress() external view returns (address);
}


contract S1mStableUSDTProxy {
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

        IERC20(usdcAddress).approve(_deployer, 2**256 - 1);
        IERC20(usdcAddress).approve(IVarsP(varsA).mStableA(), 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(uint256 mStableDeposit) external onlyDeployer {
        require(IERC20(usdcAddress).transferFrom(deployer, address(this), mStableDeposit), "ERR: INVALID_TRANSFER_FROM");

        // mStable deposit
        ImStable(IVarsP(varsA).mStableA()).saveViaMint(
            IVarsP(varsA).mUSDAddress(),
            IVarsP(varsA).imUSDAddress(),
            IVarsP(varsA).mStableVaultA(),
            usdcAddress,
            mStableDeposit,
            mStableDeposit * 10 ** 12 - (((mStableDeposit * 10 ** 12) * 5) / 100),  // scaling the min amount to 18 decimals and removing 5 percents
            true
        );
    }

    function withdraw(uint256 _mStableAmount) external onlyDeployer returns(uint256) {
        // mStable withdraw
        ImStableVault(IVarsP(varsA).mStableVaultA()).withdraw(_mStableAmount);
        // swap imUSD for mUSD
        uint256 credits = IimUSD(IVarsP(varsA).imUSDAddress()).redeemCredits(IERC20(IVarsP(varsA).imUSDAddress()).balanceOf(address(this)));
        // swap mUSD for USDC
        ImUSD(IVarsP(varsA).mUSDAddress()).redeem(
            usdcAddress,
            credits,
            ImUSD(IVarsP(varsA).mUSDAddress()).getRedeemOutput(usdcAddress, credits),
            address(this)
        );

        return IERC20(usdcAddress).balanceOf(address(this));
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        // MTA tokens
        address mStableVaultA = IVarsP(varsA).mStableVaultA();
        (, uint256 first, uint256 last) = ImStableVault(mStableVaultA).unclaimedRewards(address(this));
        ImStableVault(mStableVaultA).claimRewards(first, last);

        uint256 mtaBalance = IERC20(IVarsP(varsA).mtaTokenAddress()).balanceOf(address(this));
        IERC20(IVarsP(varsA).mtaTokenAddress()).transfer(
            _address,
            mtaBalance
        );

        return mtaBalance;
    }
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