// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IAave.sol";
import "./interfaces/IS3Proxy.sol";
import "./interfaces/IS3Admin.sol";
import "./proxies/S3TokenAavemStableUSDCProxy.sol";


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


contract S3TokenAavemStableUSDC {
    uint8 public constant strategyIndex = 16;
    address public s3Admin;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public usdcAddress;
    
    // protocols
    address private mStableA;
    address private mStableVaultA;
    address private mUSDAddress;
    address private imUSDAddress;
    address private mtaTokenAddress;
    address public collateral;
    address public aCollateral;
    mapping(address => address) public depositors; 

    constructor(
        address _s3Admin,
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _usdcAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress,
        address _collateral,
        address _aCollateral
    ) {
        s3Admin = _s3Admin;
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;
        collateral = _collateral; 
        aCollateral = _aCollateral;

        IERC20(usdcAddress).approve(uniswapConnector, 2**256 - 1);
        IERC20(mtaTokenAddress).approve(uniswapConnector, 2**256 - 1);
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, bool indexed _borrowAndDeposit);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event WithdrawCollateral(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get the current unclaimed VSP tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256) {
        (uint256 _mtaToken, , ) = ImStableVault(mStableVaultA).unclaimedRewards(depositors[_address]);
        return _mtaToken;
    }
    
    // Get the current Vesper Finance deposit
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
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
        return (imUSDCVaultBalance, mStableDeposit);
    }

    function getCurrentDebt(address _address) external view returns(uint256) {
        return IERC20(IS3Admin(s3Admin).interestTokens(strategyIndex)).balanceOf(depositors[_address]);
    }

    function getMaxUnlockedCollateral(address _address) external view returns(uint256) {
        (, uint256 totalDebtETH, , uint256 currentLiquidationThreshold, , ) = IAave(IS3Admin(s3Admin).aave()).getUserAccountData(depositors[_address]);
        uint256 maxAmountToBeWithdrawn;
        if (totalDebtETH > 0) {
            uint256 collateralPriceRatio = IPriceOracleGetter(IS3Admin(s3Admin).aavePriceOracle()).getAssetPrice(collateral);
            maxAmountToBeWithdrawn = (((10100 * totalDebtETH) / currentLiquidationThreshold) * 10 ** IERC20(collateral).decimals()) / collateralPriceRatio;
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(depositors[_address]) - maxAmountToBeWithdrawn;
        } else {
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(depositors[_address]);
        }

        return maxAmountToBeWithdrawn;
    }

    // Get the current Aave status
    function getAaveStatus(address _address) external view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return IAave(IS3Admin(s3Admin).aave()).getUserAccountData(depositors[_address]); 
    }

    function depositToken(uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        if (_borrowAndDeposit) {
            require(IS3Admin(s3Admin).whitelistedAaveBorrowPercAmounts(_borrowPercentage), "ERROR: INVALID_BORROW_PERC");
        }
        IERC20(collateral).transferFrom(msg.sender, address(this), _amount);

        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S3TokenAavemStableUSDCProxy s3proxy = new S3TokenAavemStableUSDCProxy(
                address(this),
                wethAddress,
                usdcAddress,
                mStableA,
                mStableVaultA,
                mUSDAddress,
                imUSDAddress,
                mtaTokenAddress,
                IS3Admin(s3Admin).aave(),
                collateral,
                aCollateral
            );  
            s3proxy.setupAddresses(
                uniswapConnector,
                IS3Admin(s3Admin).aavePriceOracle(),
                IS3Admin(s3Admin).interestTokens(strategyIndex),
                s3Admin
            );
            depositors[msg.sender] = address(s3proxy);
            IERC20(collateral).approve(depositors[msg.sender], 2**256 - 1);
            s3proxy.deposit(collateral, _amount, _borrowPercentage, _borrowAndDeposit);

            emit ProxyCreation(msg.sender, address(s3proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(collateral).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(collateral).approve(depositors[msg.sender], 2**256 - 1); 
            }

            IS3Proxy(depositors[msg.sender]).deposit(collateral, _amount, _borrowPercentage, _borrowAndDeposit);
        }

        emit Deposit(msg.sender, collateral, _amount, _borrowAndDeposit);
    }

    // claim VSP tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS3Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, truTokens, 0, address(0));
    }

    // claim VSP tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 mtaTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();

        uint256 wethAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            mtaTokenAddress,
            wethAddress,
            mtaTokens,
            _amountOutMin,
            address(this)
        );

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: wethAmount}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, wethAmount, wethAddress);
    }

    // claim VSP tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        uint256 mtaTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();
        uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            mtaTokenAddress, 
            _token,
            mtaTokens, 
            _amountOutMin, 
            msg.sender
        );

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, tokenAmount, _token);
    } 

    function withdraw(uint8 _percentage, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        (uint256 tokenAmountToBeWithdrawn, uint256 amountOut) = IS3Proxy(depositors[msg.sender]).withdraw(_percentage); 
        if (amountOut > 0) {
            tokenAmountToBeWithdrawn += _swapYieldProfitToCollateral(depositors[msg.sender], amountOut);
        }
        
        uint256 fee = (tokenAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) { 
            IERC20(collateral).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
                fee
            );
        }
        IERC20(collateral).transfer(
            msg.sender,
            tokenAmountToBeWithdrawn - fee
        );

        emit Withdraw(msg.sender, _percentage, tokenAmountToBeWithdrawn, fee);
    }

    function withdrawCollateral(uint8 _percentage, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        (uint256 tokenAmountToBeWithdrawn, ) = IS3Proxy(depositors[msg.sender]).withdrawCollateral(_percentage);
        uint256 fee = (tokenAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) {
            IERC20(collateral).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
                fee
            );
        }
        IERC20(collateral).transfer(
            msg.sender,
            tokenAmountToBeWithdrawn - fee
        );

        emit WithdrawCollateral(msg.sender, _percentage, tokenAmountToBeWithdrawn, fee);
    }

    function emergencyWithdraw(address _token, uint256 _amount) external {
        require(!IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_ARE_ON");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        IS3Proxy(depositors[msg.sender]).emergencyWithdraw(_token, msg.sender, _amount);
    }

    function _swapYieldProfitToCollateral(address _proxy, uint256 _amountOutMin) private returns(uint256) {
        uint256 proxyUSDCBalance = IERC20(usdcAddress).balanceOf(_proxy);
        if (proxyUSDCBalance > 0) {
            IERC20(usdcAddress).transferFrom(_proxy, address(this), proxyUSDCBalance);

            return IUniswapConnector(uniswapConnector).swapTokenForToken(
                usdcAddress, 
                collateral,
                IERC20(usdcAddress).balanceOf(address(this)), 
                _amountOutMin, 
                address(this)
            );
        } else {
            return 0;
        } 
    }

    receive() external payable {} 
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

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
    function getTokenFee(address _token) external view returns(uint24);

    function uniswapV3Router02() external view returns (address);

    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForTokenV3ExactOutput(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountInMaximum, address _to) external payable returns(uint256);
    
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IAave {
    function deposit(
        address asset, 
        uint256 amount, 
        address onBehalfOf, 
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount, 
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface IAaveETH {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address to
    ) external;
}

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS3Proxy {
    function depositETH(uint8 _borrowPercentage, bool _borrowAndDeposit) external payable;

    function deposit(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external;

    function withdraw(uint8 _percentage) external returns(uint256, uint256);

    function withdrawCollateral(uint8 _percentage) external returns(uint256, uint256);

    function emergencyWithdraw(address _token, address _depositor, uint256 _amount) external;

    function claimToDepositor(address _depositor) external returns(uint256);

    function claimToDeployer() external returns(uint256);

    function setupAddresses(
        address _aavePriceOracle,
        address _aaveInterestDAI,
        address _s3Admin
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IS3Admin {
    function interestTokens(uint8 _strategyIndex) external view returns (address);
    function whitelistedAaveBorrowPercAmounts(uint8 _amount) external view returns (bool);
    function aave() external view returns (address);
    function aaveEth() external view returns (address);
    function aavePriceOracle() external view returns (address);
    function aWETH() external view returns (address);
    function slippage() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IS3Admin.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IAave.sol";
import "../interfaces/ImStable.sol";
import "../interfaces/IQuoter.sol";
import "../interfaces/IUniswapConnector.sol";


contract S3TokenAavemStableUSDCProxy {
    uint8 private constant defaultInterestRate = 2;
    address private quoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address private deployer;
    address private uniswapConnector;
    address private wethAddress;
    address private usdcAddress;
    address private mStableA;
    address private mStableVaultA;
    address private mUSDAddress;
    address private imUSDAddress;
    address private mtaTokenAddress;
    address private aave;
    address private aavePriceOracle;
    address private aaveInterestUSDC;
    address private collateral;
    address private aCollateral;
    address private s3Admin;

    constructor(
        address _deployer,
        address _wethAddress,
        address _usdcAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress,
        address _aave,
        address _collateral,
        address _aCollateral
    ) {
        deployer = _deployer;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;
        aave = _aave;
        collateral = _collateral; 
        aCollateral = _aCollateral;  

        // Give Aave lending protocol approval - needed when repaying the USDC loan
        IERC20(usdcAddress).approve(aave, 2**256 - 1);
        // Give S3TokenAavemStableUSDC USDC approval - needed when sending the USDC rewards to the depositor
        IERC20(usdcAddress).approve(deployer, 2**256 - 1);
        // Allow mStable protocol to take USDC from the proxy
        IERC20(usdcAddress).approve(mStableA, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    }

    function setupAddresses(
        address _uniswapConnector,
        address _aavePriceOracle,
        address _aaveInterestUSDC,
        address _s3Admin
    ) external onlyDeployer {
        uniswapConnector = _uniswapConnector;
        aavePriceOracle = _aavePriceOracle;
        aaveInterestUSDC = _aaveInterestUSDC;
        s3Admin = _s3Admin;
    }

    function deposit(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external onlyDeployer {
        IERC20(_token).transferFrom(deployer, address(this), _amount);

        if (IERC20(_token).allowance(address(this), aave) == 0) {
            IERC20(_token).approve(aave, 2**256 - 1);
        }
        
        (, , uint256 availableBorrowsETH, , ,) = IAave(aave).getUserAccountData(address(this));

        // supply to Aave protocol
        IAave(aave).deposit(_token, _amount, address(this), 0);

        // Aave borrow & TrueFi deposit
        if (_borrowAndDeposit) {
            // borrow USDC from Aave protocol
            (, , uint256 availableBorrowsETHAfterDeposit, , ,) = IAave(aave).getUserAccountData(address(this));
            uint256 maxAmountToBeBorrowed = ((availableBorrowsETHAfterDeposit - availableBorrowsETH) * 10 ** IERC20(usdcAddress).decimals()) / IPriceOracleGetter(aavePriceOracle).getAssetPrice(usdcAddress); 
            IAave(aave).borrow(
                usdcAddress, 
                (maxAmountToBeBorrowed * _borrowPercentage) / 100,
                defaultInterestRate,
                0, 
                address(this)
            );

            uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));
            // mStable deposit
            ImStable(mStableA).saveViaMint(
                mUSDAddress,
                imUSDAddress,
                mStableVaultA,
                usdcAddress,
                usdcBalance,
                usdcBalance * 10 ** 12 - (((usdcBalance * 10 ** 12) * 5) / 100),  // scaling the min amount to 18 decimals and removing 5 percents
                true
            );
        }
    }

    function withdraw(uint8 _percentage) external onlyDeployer returns(uint256, uint256) {
        // mStable withdraw
        ImStableVault(mStableVaultA).withdraw((ImStableVault(mStableVaultA).balanceOf(address(this))* _percentage) / 100);
        // swap imUSD for mUSD
        uint256 credits = IimUSD(imUSDAddress).redeemCredits(IERC20(imUSDAddress).balanceOf(address(this)));
        // swap mUSD for USDC
        ImUSD(mUSDAddress).redeem(
            usdcAddress,
            credits,
            ImUSD(mUSDAddress).getRedeemOutput(usdcAddress, credits),
            address(this)
        );

        // repay the USDC loan to Aave protocol
        uint256 currentDebt = IERC20(aaveInterestUSDC).balanceOf(address(this));
        uint256 borrowAssetBalance = IERC20(usdcAddress).balanceOf(address(this));
        uint256 currentDebtAfterRepaying;
        if (borrowAssetBalance > (currentDebt * _percentage) / 100) {
            // full repay
            _aaveRepay((currentDebt * _percentage) / 100, address(this));
        } else {
            // partly repay
            _aaveRepay(borrowAssetBalance, address(this));
            currentDebtAfterRepaying = (currentDebt * _percentage) / 100 - borrowAssetBalance;
        }

        return _withdrawCollateral(
            _percentage,
            currentDebtAfterRepaying
        );
    }

    function withdrawCollateral(uint8 _percentage) external onlyDeployer returns(uint256, uint256) {
        return _withdrawCollateral(_percentage, 0);
    }

    function _withdrawCollateral(uint8 _percentage, uint256 _currentDebtAfterRepaying) private returns(uint256, uint256) {
        // if there is debt sell part of the collateral to cover it
        if (_currentDebtAfterRepaying > 0) {
            uint256 amountIn = IQuoter(quoterAddress).quoteExactOutput(
                abi.encodePacked(
                    usdcAddress, 
                    IUniswapConnector(uniswapConnector).getTokenFee(usdcAddress), 
                    wethAddress, 
                    IUniswapConnector(uniswapConnector).getTokenFee(collateral), 
                    collateral
                ), 
                _currentDebtAfterRepaying
            );
            amountIn = (amountIn * (100 + IS3Admin(s3Admin).slippage())) / 100;
            _aaveWithdraw(amountIn, address(this));

            if (IERC20(collateral).allowance(address(this), uniswapConnector) == 0) {
                IERC20(collateral).approve(uniswapConnector, 2**256 - 1);
            }
            
            // if withdrawing everything then refresh _currentDebtAfterRepaying once more
            if (_percentage == 100) {
                _currentDebtAfterRepaying = (IERC20(aaveInterestUSDC).balanceOf(address(this)) * _percentage) / 100 - IERC20(usdcAddress).balanceOf(address(this));
            }
            
            IUniswapConnector(uniswapConnector).swapTokenForTokenV3ExactOutput(
                collateral, 
                usdcAddress,
                _currentDebtAfterRepaying, 
                amountIn, 
                address(this)
            );

            _aaveRepay(IERC20(usdcAddress).balanceOf(address(this)), address(this));
            uint256 maxAmountToBeWithdrawnAfterRepay = _calculateMaxAmountToBeWithdrawn();
            if (_percentage != 100) {
                maxAmountToBeWithdrawnAfterRepay = (maxAmountToBeWithdrawnAfterRepay * _percentage) / 100;
            }
            
            // withdraw rest of the unlocked collateral after repaying the loan
            _aaveWithdraw(maxAmountToBeWithdrawnAfterRepay, address(this));
            uint256 currentCollateralBalance = IERC20(collateral).balanceOf(address(this));
            IERC20(collateral).transfer(deployer, currentCollateralBalance);

            return (currentCollateralBalance, 0);
        } else {
            uint256 maxAmountToBeWithdrawn = _calculateMaxAmountToBeWithdrawn();
            if (_percentage != 100) {
                maxAmountToBeWithdrawn = (maxAmountToBeWithdrawn * _percentage) / 100;
            }

            uint256 amountOut;
            uint256 currentUSDCBalance = IERC20(usdcAddress).balanceOf(address(this));
            if (currentUSDCBalance > 0) {
                amountOut = IQuoter(quoterAddress).quoteExactInput(
                    abi.encodePacked(
                        usdcAddress, 
                        IUniswapConnector(uniswapConnector).getTokenFee(usdcAddress), 
                        wethAddress, 
                        IUniswapConnector(uniswapConnector).getTokenFee(collateral), 
                        collateral
                    ), 
                    currentUSDCBalance
                );
                amountOut = (amountOut * (100 - IS3Admin(s3Admin).slippage())) / 100;
            }

            _aaveWithdraw(maxAmountToBeWithdrawn, deployer);
            return (maxAmountToBeWithdrawn, amountOut);
        }
    }

    function emergencyWithdraw(address _token, address _depositor, uint256 _amount) external onlyDeployer {
        IERC20(_token).transfer(_depositor, _amount);
    }

    function _calculateMaxAmountToBeWithdrawn() private view returns(uint256) {
        (, uint256 totalDebtETH, , uint256 currentLiquidationThreshold, , ) = IAave(aave).getUserAccountData(address(this));
        uint256 maxAmountToBeWithdrawn;
        if (totalDebtETH > 0) {
            uint256 collateralPriceRatio = IPriceOracleGetter(aavePriceOracle).getAssetPrice(collateral);
            maxAmountToBeWithdrawn = (((10100 * totalDebtETH) / currentLiquidationThreshold) * 10 ** IERC20(collateral).decimals()) / collateralPriceRatio;
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(address(this)) - maxAmountToBeWithdrawn;
        } else {
            maxAmountToBeWithdrawn = IERC20(aCollateral).balanceOf(address(this));
        }

        return maxAmountToBeWithdrawn;
    }

    function _aaveRepay(uint256 _amount, address _to) private {
        IAave(aave).repay(
            usdcAddress, 
            _amount,
            defaultInterestRate, 
            _to
        );
    }

    function _aaveWithdraw(uint256 _amount, address _to) private returns(uint256) {
        return IAave(aave).withdraw(
            collateral,
            _amount, 
            _to
        );
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        // MTA tokens
        (, uint256 first, uint256 last) = ImStableVault(mStableVaultA).unclaimedRewards(address(this));
        ImStableVault(mStableVaultA).claimRewards(first, last);

        uint256 mtaBalance = IERC20(mtaTokenAddress).balanceOf(address(this));
        IERC20(mtaTokenAddress).transfer(
            _address,
            mtaBalance
        );

        return mtaBalance;
    }
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
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

    function balanceOf(address _owner) external view returns (uint256);
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

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);

    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn);
}