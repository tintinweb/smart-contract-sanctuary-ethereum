// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS2Proxy.sol";
import "./S2Proxy.sol";


interface IFees {
    function feeCollector(uint256 _index) external view returns (address);
    function depositStatus(uint256 _index) external view returns (bool);
    function calcFee(
        uint256 _strategyId,
        address _user,
        address _feeToken
    ) external view returns (uint256);
    function whitelistedDepositCurrencies(uint256 _index, address _token) external view returns(bool);
}


contract S2 {
    uint8 constant public strategyIndex = 6;
    address constant public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public feesAddress;
    address public uniswapConnector;

    // protocols
    address public trueFiUSDCAddress;
    address public trueFiTokenAddress;
    address public stakedTrueFiTokenAddress;
    address public farmTrueFiAddress;
    address public mStableA;
    address public mStableVaultA;
    address public mUSDAddress;
    address public imUSDAddress;
    address public mtaTokenAddress;
    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _trueFiUSDCAddress,
        address _trueFiTokenAddress,
        address _stakedTrueFiTokenAddress,
        address _farmTrueFiAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        trueFiUSDCAddress = _trueFiUSDCAddress;
        trueFiTokenAddress = _trueFiTokenAddress;
        stakedTrueFiTokenAddress = _stakedTrueFiTokenAddress;
        farmTrueFiAddress = _farmTrueFiAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, uint256 _amount2, address indexed _swappedTo);

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256, uint256) {
        uint256 _truToken = IFarmTrueFi(farmTrueFiAddress).claimable(IERC20(trueFiUSDCAddress), depositors[_address]);
        (uint256 _mtaToken, , ) = ImStableVault(mStableVaultA).unclaimedRewards(depositors[_address]);
        return(_truToken, _mtaToken);
    }

    // Get current stake in USDC
    function getCurrentDeposit(address _address) external view returns(uint256, uint256, uint256, uint256) {
        uint256 tfUSDCAmount = IFarmTrueFi(farmTrueFiAddress).staked(
            IERC20(trueFiUSDCAddress),
            depositors[_address]
        );
        uint256 trueFiDeposit;
        if (tfUSDCAmount > 0) {
            trueFiDeposit = (ITrueFiUSDC(trueFiUSDCAddress).poolValue() * tfUSDCAmount) / ITrueFiUSDC(trueFiUSDCAddress).totalSupply();
            trueFiDeposit = (trueFiDeposit * ITrueFiUSDC(trueFiUSDCAddress).liquidExitPenalty(trueFiDeposit)) / 10000; // TrueFi's BASIS_PRECISION is 1000
        }

        uint256 imUSDCVaultBalance = IERC20(mStableVaultA).balanceOf(depositors[_address]);
        uint256 mStableDeposit;
        if (imUSDCVaultBalance > 0) {
            mStableDeposit = ImUSD(mUSDAddress).getRedeemOutput(
                usdcAddress,
                IimUSD(imUSDAddress).convertToAssets(
                    imUSDCVaultBalance
                )
            );
        }
        return (tfUSDCAmount, trueFiDeposit, imUSDCVaultBalance, mStableDeposit);
    }

    function depositETH(uint256 _amountOutMin) public payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        uint256 usdcAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
            usdcAddress, 
            0, 
            _amountOutMin, 
            address(this)
        );
        _yieldDeposit(usdcAmount);

        emit Deposit(msg.sender, wethAddress, msg.value, usdcAmount);
    }

    function depositToken(address _token, uint256 _amount, uint256 _amountOutMin) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(IFees(feesAddress).whitelistedDepositCurrencies(strategyIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 usdcAmount;
        if (_token != usdcAddress) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }
            
            usdcAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                usdcAddress, 
                _amount, 
                _amountOutMin, 
                address(this)
            );
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
                usdcAddress,
                trueFiUSDCAddress,
                trueFiTokenAddress,
                stakedTrueFiTokenAddress,
                farmTrueFiAddress,
                mStableA,
                mStableVaultA,
                mUSDAddress,
                imUSDAddress,
                mtaTokenAddress
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

    // claim TRU & MTA tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDepositor(msg.sender);

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, 0, address(0));
    }

    // claim TRU & MTA tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin0, uint256 _amountOutMin1) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDeployer();
        
        uint256 wethAmount0;
        uint256 wethAmount1;
        if (truTokens > 0) {
            if (IERC20(trueFiTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(trueFiTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }
            wethAmount0 = IUniswapConnector(uniswapConnector).swapTokenForToken(
                trueFiTokenAddress,
                wethAddress,
                truTokens,
                _amountOutMin0,
                address(this)
            );
        }

        if (mtaTokens > 0) {
            if (IERC20(mtaTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(mtaTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }
            wethAmount1 = IUniswapConnector(uniswapConnector).swapTokenForToken(
                mtaTokenAddress,
                wethAddress,
                mtaTokens,
                _amountOutMin1,
                address(this)
            );
        }

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount0 + wethAmount1);
        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: wethAmount0 + wethAmount1}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, wethAmount0 + wethAmount1, wethAddress);
    }

    // claim TRU & MTA tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin0, uint256 _amountOutMin1) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 truTokens, uint256 mtaTokens) = IS2Proxy(depositors[msg.sender]).claimToDeployer();

        uint256 tokenAmount0;
        uint256 tokenAmount1;

        if (truTokens > 0) {
            if (IERC20(trueFiTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(trueFiTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }
            tokenAmount0 = IUniswapConnector(uniswapConnector).swapTokenForToken(
                trueFiTokenAddress, 
                _token,
                truTokens, 
                _amountOutMin0, 
                msg.sender
            );
        }
        
        if (mtaTokens > 0) {
            if (IERC20(mtaTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(mtaTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }
            tokenAmount1 = IUniswapConnector(uniswapConnector).swapTokenForToken(
                mtaTokenAddress, 
                _token,
                mtaTokens, 
                _amountOutMin1, 
                msg.sender
            );
        }

        emit ClaimAdditionalTokens(msg.sender, truTokens, mtaTokens, tokenAmount0 + tokenAmount1, _token);
    }

    function withdrawETH(uint256 _truAmount, uint256 _mtaAmount, uint256 _amountOutMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _mtaAmount, _feeToken);

        if (IERC20(usdcAddress).allowance(address(this), uniswapConnector) == 0) {
            IERC20(usdcAddress).approve(uniswapConnector, 2**256 - 1);
        }

        uint256 wethAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            usdcAddress,
            wethAddress,
            yieldDeposit - fee,
            _amountOutMin,
            address(this)
        );

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: wethAmount}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        emit Withdraw(msg.sender, wethAddress, wethAmount, fee);
    }

    function withdrawToken(address _token, uint256 _truAmount, uint256 _mtaAmount, uint256 _amountOutMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _mtaAmount, _feeToken);
        if (_token == usdcAddress) {
            // withdraw USDC
            IERC20(usdcAddress).transfer(
                msg.sender,
                yieldDeposit - fee
            );

            emit Withdraw(msg.sender, usdcAddress, yieldDeposit - fee, fee);
        } else {
            if (IERC20(usdcAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(usdcAddress).approve(uniswapConnector, 2**256 - 1);
            }

            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                usdcAddress,
                _token, 
                yieldDeposit - fee, 
                _amountOutMin, 
                msg.sender
            );

            emit Withdraw(msg.sender, _token, tokenAmount, fee);
        }
    }

    function _withdrawYieldDeposit(uint256 _trueFiAmount, uint256 _mStableAmount, address _feeToken) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS2Proxy(depositors[msg.sender]).withdraw(_trueFiAmount, _mStableAmount);
        IERC20(usdcAddress).transferFrom(depositors[msg.sender], address(this), usdcAmountToBeWithdrawn);

        uint256 fee = (usdcAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        // if fee then send it to the feeCollector
        if (fee > 0) {
            IERC20(usdcAddress).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
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

import "./interfaces/IERC20.sol";
import "./interfaces/ITrueFi.sol";
import "./interfaces/ImStable.sol";


contract S2Proxy {
    address private deployer;
    address private usdcAddress;
    address private trueFiUSDCAddress;
    address private trueFiTokenAddress;
    address private farmTrueFiAddress;
    address private mStableA;
    address private mStableVaultA;
    address private mUSDAddress;
    address private imUSDAddress;
    address private mtaTokenAddress;

    constructor(
        address _deployer,
        address _usdcAddress,
        address _trueFiUSDCAddress,
        address _trueFiTokenAddress,
        address _stakedTrueFiTokenAddress,
        address _farmTrueFiAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress
    ) {
        deployer = _deployer;
        usdcAddress = _usdcAddress;
        trueFiUSDCAddress = _trueFiUSDCAddress;
        trueFiTokenAddress = _trueFiTokenAddress;
        farmTrueFiAddress = _farmTrueFiAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;

        IERC20(usdcAddress).approve(_deployer, 2**256 - 1);
        IERC20(usdcAddress).approve(trueFiUSDCAddress, 2**256 - 1);
        IERC20(usdcAddress).approve(mStableA, 2**256 - 1);
        IERC20(trueFiUSDCAddress).approve(farmTrueFiAddress, 2**256 - 1);
        IERC20(trueFiTokenAddress).approve(_stakedTrueFiTokenAddress, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(uint256 _trueFiDeposit, uint256 _mStableDeposit) external onlyDeployer {
        IERC20(usdcAddress).transferFrom(deployer, address(this), _trueFiDeposit + _mStableDeposit);

        // TrueFi deposit
        ITrueFiUSDC(trueFiUSDCAddress).join(_trueFiDeposit); 
        IFarmTrueFi(farmTrueFiAddress).stake(
            IERC20(trueFiUSDCAddress),
            IERC20(trueFiUSDCAddress).balanceOf(address(this))
        );

        // mStable deposit
        ImStable(mStableA).saveViaMint(
            mUSDAddress,
            imUSDAddress,
            mStableVaultA,
            usdcAddress,
            _mStableDeposit,
            _mStableDeposit * 10 ** 12 - (((_mStableDeposit * 10 ** 12) * 5) / 100),  // scaling the min amount to 18 decimals and removing 5 percents
            true
        );
    }

    function withdraw(uint256 _trueFiAmount, uint256 _mStableAmount) external onlyDeployer returns(uint256) {
        if (IFarmTrueFi(farmTrueFiAddress).staked(IERC20(trueFiUSDCAddress), address(this)) > 0) {
            // unstake TrueFi tfUSDC
            IFarmTrueFi(farmTrueFiAddress).unstake(
                IERC20(trueFiUSDCAddress),
                _trueFiAmount
            );

            // TrueFi withdraw ( swap tfUSDC for USDC )
            ITrueFiUSDC(trueFiUSDCAddress).liquidExit(IERC20(trueFiUSDCAddress).balanceOf(address(this)));
        }

        if (IERC20(mStableVaultA).balanceOf(address(this)) > 0) {
            // mStable withdraw
            ImStableVault(mStableVaultA).withdraw(_mStableAmount);
            // swap imUSD for mUSD
            uint256 credits = IimUSD(imUSDAddress).redeemCredits(IERC20(imUSDAddress).balanceOf(address(this)));
            // swap mUSD for USDC
            ImUSD(mUSDAddress).redeem( 
                usdcAddress,
                credits,
                ImUSD(mUSDAddress).getRedeemOutput(usdcAddress, credits),
                address(this)
            );
        }

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
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(trueFiUSDCAddress);
        IFarmTrueFi(farmTrueFiAddress).claim(tokens);

        // MTA tokens
        (, uint256 first, uint256 last) = ImStableVault(mStableVaultA).unclaimedRewards(address(this));
        ImStableVault(mStableVaultA).claimRewards(first, last);

        uint256 truBalance = IERC20(trueFiTokenAddress).balanceOf(address(this));
        if (truBalance > 0) {
            IERC20(trueFiTokenAddress).transfer(
                _address,
                truBalance
            );
        }

        uint256 mtaBalance = IERC20(mtaTokenAddress).balanceOf(address(this));
        if (mtaBalance > 0) {
            IERC20(mtaTokenAddress).transfer(
                _address,
                mtaBalance
            );
        }

        return(truBalance, mtaBalance);
    }
} 

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapConnector {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
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

interface IWETH {
    function withdraw(uint wad) external;
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