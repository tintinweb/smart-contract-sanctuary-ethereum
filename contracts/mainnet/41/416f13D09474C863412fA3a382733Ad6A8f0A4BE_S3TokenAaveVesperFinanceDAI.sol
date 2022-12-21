// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IAave.sol";
import "./interfaces/IS3Proxy.sol";
import "./interfaces/IS3Admin.sol";
import "./proxies/S3TokenAaveVesperFinanceDAIProxy.sol";


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


contract S3TokenAaveVesperFinanceDAI {
    uint8 public constant strategyIndex = 12;
    address public s3Admin;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public daiAddress;
    
    // protocols
    address public vPoolDAI;
    address public vPoolRewardsDAI;
    address public vspToken;
    address public collateral;
    address public aCollateral;
    mapping(address => address) public depositors; 

    constructor(
        address _s3Admin,
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken,
        address _collateral,
        address _aCollateral
    ) {
        s3Admin = _s3Admin;
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken;
        collateral = _collateral; 
        aCollateral = _aCollateral;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn);

    event Withdraw(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event WithdrawCollateral(address indexed _depositor, uint8 _percentage, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get the current unclaimed VSP tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        return IVPoolRewards(vPoolRewardsDAI).claimable(depositors[_address]);
    }   
    
    // Get the current Vesper Finance deposit
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 vaDAIShare = IERC20(vPoolDAI).balanceOf(depositors[_address]);
        uint256 daiEquivalent;
        if (vaDAIShare > 0) {
            uint256 pricePerShare = IVPoolDAI(vPoolDAI).pricePerShare();
            daiEquivalent = (pricePerShare * vaDAIShare) / 10 ** 18;
        }
        
        return (vaDAIShare, daiEquivalent);
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

    function depositToken(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        if (_borrowAndDeposit) {
            require(IS3Admin(s3Admin).whitelistedAaveBorrowPercAmounts(_borrowPercentage), "ERROR: INVALID_BORROW_PERC");
        }
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S3TokenAaveVesperFinanceDAIProxy s3proxy = new S3TokenAaveVesperFinanceDAIProxy(
                address(this),
                uniswapConnector,
                wethAddress,
                daiAddress,
                vPoolDAI,
                vPoolRewardsDAI,
                vspToken,
                IS3Admin(s3Admin).aave(),
                collateral,
                aCollateral
            );  
            s3proxy.setupAaveAddresses(
                IS3Admin(s3Admin).aavePriceOracle(),
                IS3Admin(s3Admin).interestTokens(strategyIndex)
            );
            depositors[msg.sender] = address(s3proxy);
            IERC20(_token).approve(depositors[msg.sender], 2**256 - 1);
            s3proxy.deposit(_token, _amount, _borrowPercentage, _borrowAndDeposit); 
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(_token).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(_token).approve(depositors[msg.sender], 2**256 - 1); 
            }

            IS3Proxy(depositors[msg.sender]).deposit(_token, _amount, _borrowPercentage, _borrowAndDeposit);
        }

        emit Deposit(msg.sender, _token, _amount);
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
        uint256 vspTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();

        if (IERC20(vspToken).allowance(address(this), uniswapConnector) == 0) {
            IERC20(vspToken).approve(uniswapConnector, 2**256 - 1);
        }
        uint256 wethAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            vspToken,
            wethAddress,
            vspTokens,
            _amountOutMin,
            address(this)
        );

        // swap WETH for ETH
        IWETH(wethAddress).withdraw(wethAmount);
        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: wethAmount}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        emit ClaimAdditionalTokens(msg.sender, vspTokens, wethAmount, wethAddress);
    }

    // claim VSP tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        uint256 vspTokens = IS3Proxy(depositors[msg.sender]).claimToDeployer();
        if (IERC20(vspToken).allowance(address(this), uniswapConnector) == 0) {
            IERC20(vspToken).approve(uniswapConnector, 2**256 - 1);
        }
        uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            vspToken, 
            _token,
            vspTokens, 
            _amountOutMin, 
            msg.sender
        );

        emit ClaimAdditionalTokens(msg.sender, vspTokens, tokenAmount, _token);
    } 

    function withdraw(uint8 _percentage, uint256 _amountInMaximum, uint256 _amountOutMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR"); 

        uint256 tokenAmountToBeWithdrawn = IS3Proxy(depositors[msg.sender]).withdraw(_percentage, _amountInMaximum); 
        tokenAmountToBeWithdrawn += _swapYieldProfitTo(depositors[msg.sender], _amountOutMin);

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

        uint256 tokenAmountToBeWithdrawn = IS3Proxy(depositors[msg.sender]).withdrawCollateral(_percentage);
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

    function emergencyWithdraw(address _token) external {
        require(!IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_ARE_ON");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        IS3Proxy(depositors[msg.sender]).emergencyWithdraw(_token, msg.sender);
    }

    function _swapYieldProfitTo(address _proxy, uint256 _amountOutMin) private returns(uint256) {
        if (IERC20(daiAddress).balanceOf(_proxy) > 0) {
            if (IERC20(daiAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(daiAddress).approve(uniswapConnector, 2**256 - 1);
            }
            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                daiAddress, 
                collateral,
                IERC20(daiAddress).balanceOf(address(this)), 
                _amountOutMin, 
                address(this)
            );
            
            return tokenAmount;
        } else {
            return 0;
        } 
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

interface IUniswapConnector {
    function uniswapV3Router02() external view returns (address);

    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForTokenV3ExactOutput(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountInMaximum, address _to) external payable returns(uint256);
    
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IAave.sol";
import "../interfaces/IVesperFinance.sol";
import "../interfaces/IUniswapConnector.sol";


contract S3TokenAaveVesperFinanceDAIProxy {
    uint8 private constant defaultInterestRate = 2;
    address private deployer;
    address private uniswapConnector;
    address private wethAddress;
    address private daiAddress;
    address private vPoolDAI;
    address private vPoolRewardsDAI;
    address private vspToken;
    address private aave;
    address private aavePriceOracle;
    address private aaveInterestDAI;
    address private collateral;
    address private aCollateral;

    constructor(
        address _deployer,
        address _uniswapConnector,
        address _wethAddress,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken,
        address _aave,
        address _collateral,
        address _aCollateral
    ) {
        deployer = _deployer;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken; 
        aave = _aave;
        collateral = _collateral; 
        aCollateral = _aCollateral;  

        // Give Aave lending protocol approval - needed when repaying the DAI loan
        IERC20(daiAddress).approve(aave, 2**256 - 1);
        // Give S3AaveVesperFinanceDAI DAI approval - needed when sending the DAI rewards to the depositor
        IERC20(daiAddress).approve(deployer, 2**256 - 1);
        // Allow Vesper Finance protocol to take DAI from the proxy
        IERC20(daiAddress).approve(vPoolDAI, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    }

    function setupAaveAddresses(
        address _aavePriceOracle,
        address _aaveInterestDAI
    ) external onlyDeployer {
        aavePriceOracle = _aavePriceOracle;
        aaveInterestDAI = _aaveInterestDAI;
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
            // borrow DAI from Aave protocol
            (, , uint256 availableBorrowsETHAfterDeposit, , ,) = IAave(aave).getUserAccountData(address(this));
            uint256 maxAmountToBeBorrowed = ((availableBorrowsETHAfterDeposit - availableBorrowsETH) * 10 ** IERC20(daiAddress).decimals()) / IPriceOracleGetter(aavePriceOracle).getAssetPrice(daiAddress); 
            IAave(aave).borrow(
                daiAddress, 
                (maxAmountToBeBorrowed * _borrowPercentage) / 100,
                defaultInterestRate,
                0, 
                address(this)
            );

            // Vesper Finance deposit
            IVPoolDAI(vPoolDAI).deposit(IERC20(daiAddress).balanceOf(address(this)));
        }
    }

    function withdraw(uint8 _percentage, uint256 _amountInMaximum) external onlyDeployer returns(uint256) {
        IVPoolDAI(vPoolDAI).withdraw((IERC20(vPoolDAI).balanceOf(address(this)) * _percentage) / 100);

        // repay the DAI loan to Aave protocol
        uint256 currentDebt = IERC20(aaveInterestDAI).balanceOf(address(this));
        uint256 borrowAssetBalance = IERC20(daiAddress).balanceOf(address(this));
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
            currentDebtAfterRepaying, 
            _amountInMaximum
        );
    }

    function withdrawCollateral(uint8 _percentage) external onlyDeployer returns(uint256) {
        return _withdrawCollateral(_percentage, 0, 0);
    }

    function _withdrawCollateral(uint8 _percentage, uint256 _currentDebtAfterRepaying, uint256 _amountInMaximum) private returns(uint256) {
        uint256 maxAmountToBeWithdrawn = _calculateMaxAmountToBeWithdrawn();
        if (_percentage != 100) {
            maxAmountToBeWithdrawn = (maxAmountToBeWithdrawn * _percentage) / 100;
        }

        // if there is debt sell part of the collateral to cover it
        if (_currentDebtAfterRepaying > 0) {
            _aaveWithdraw(maxAmountToBeWithdrawn, address(this));

            if (IERC20(collateral).allowance(address(this), uniswapConnector) == 0) {
                IERC20(collateral).approve(uniswapConnector, 2**256 - 1);
            }

            IUniswapConnector(uniswapConnector).swapTokenForTokenV3ExactOutput(
                collateral, 
                daiAddress,
                _currentDebtAfterRepaying, 
                _amountInMaximum, 
                address(this)
            );

            uint256 maxAmountToBeWithdrawnBeforeRepay = _calculateMaxAmountToBeWithdrawn();
            _aaveRepay(IERC20(daiAddress).balanceOf(address(this)), address(this));
            uint256 maxAmountToBeWithdrawnAfterRepay = _calculateMaxAmountToBeWithdrawn();
            
            // withdraw rest of the unlocked collateral after repaying the loan
            _aaveWithdraw(maxAmountToBeWithdrawnAfterRepay - maxAmountToBeWithdrawnBeforeRepay, deployer);
            uint256 currentCollateralBalance = IERC20(collateral).balanceOf(address(this));
            IERC20(collateral).transfer(deployer, currentCollateralBalance);

            return currentCollateralBalance;
        } else {
            return _aaveWithdraw(maxAmountToBeWithdrawn, deployer);
        }
    }

    function emergencyWithdraw(address _token, address _depositor) external onlyDeployer {
        IERC20(_token).transfer(_depositor, IERC20(_token).balanceOf(address(this)));
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
            daiAddress, 
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
        // VSP tokens
        IVPoolRewards(vPoolRewardsDAI).claimReward(address(this));

        uint256 vspBalance = IERC20(vspToken).balanceOf(address(this));
        IERC20(vspToken).transfer(
            _address,
            vspBalance
        );

        return vspBalance;
    }
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS3Proxy {
    function depositETH(uint8 _borrowPercentage, bool _borrowAndDeposit) external payable;

    function deposit(address _token, uint256 _amount, uint8 _borrowPercentage, bool _borrowAndDeposit) external;

    function withdraw(uint8 _percentage, uint256 _amountInMaximum) external returns(uint256);

    function withdrawCollateral(uint8 _percentage) external returns(uint256);

    function emergencyWithdraw(address _token, address _depositor) external;

    function claimToDepositor(address _depositor) external returns(uint256);

    function claimToDeployer() external returns(uint256);

    function setupAaveAddresses(
        address _aave,
        address _aaveEth,
        address _aavePriceOracle,
        address _aWETH,
        address _aaveInterest
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IVPoolDAI {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function pricePerShare() external view returns (uint256);
}


interface IVPoolETH {
    function deposit() external payable;

    function withdrawETH(uint256 _shares) external;

    function pricePerShare() external view returns (uint256);
}


interface IVPoolRewards {
    function claimable(address _account) external view returns (
        address[] memory _rewardTokens,
        uint256[] memory _claimableAmounts
    );

    function claimReward(address _account) external;
}