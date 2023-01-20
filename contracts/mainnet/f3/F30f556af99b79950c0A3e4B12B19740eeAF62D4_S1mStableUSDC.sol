// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1mStableUSDCProxy.sol";


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


contract S1mStableUSDC {
    uint8 constant public strategyIndex = 3;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public usdcAddress;

    // protocols
    address public mStableA;
    address public mStableVaultA;
    address public mUSDAddress;
    address public imUSDAddress;
    address public mtaTokenAddress;

    mapping(address => address) public depositors; 

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _usdcAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256) {
        (uint256 _mtaToken, , ) = ImStableVault(mStableVaultA).unclaimedRewards(depositors[_address]);
        return _mtaToken;
    }

    // Get current stake
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

    function depositETH(uint256 _amountOutMin) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
            usdcAddress, 
            0, 
            _amountOutMin, 
            address(this)
        );
        _yieldDeposit(depositAmount);

        emit Deposit(msg.sender, wethAddress, msg.value, depositAmount);        
    }

    function depositToken(address _token, uint256 _amount, uint256 _amountOutMin) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(IFees(feesAddress).whitelistedDepositCurrencies(strategyIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 depositAmount;
        if (_token != usdcAddress) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }

            depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                usdcAddress, 
                _amount, 
                _amountOutMin, 
                address(this)
            );
        } else {
            depositAmount = _amount;
        }
        _yieldDeposit(depositAmount);
 
        emit Deposit(msg.sender, _token, _amount, depositAmount);
    }

    function _yieldDeposit(uint256 _amount) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1mStableUSDTProxy s1proxy = new S1mStableUSDTProxy(
                address(this),
                usdcAddress,
                mStableA,
                mStableVaultA,
                mUSDAddress,
                imUSDAddress,
                mtaTokenAddress
            );
            depositors[msg.sender] = address(s1proxy);
            IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1);
            s1proxy.deposit(_amount);

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(usdcAddress).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(usdcAddress).approve(depositors[msg.sender], 2**256 - 1); 
            }

            IS1Proxy(depositors[msg.sender]).deposit(_amount);  
        }
    }

    // claim MTA tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 mtaTokens = IS1Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, 0, address(0));
    }

    // claim MTA tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        claimInToken(wethAddress, _amountOutMin);  
    }

    // claim MTA tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 mtaTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer();

        address receiver;
        if (_token == wethAddress) {
            receiver = address(this);
        } else {
            receiver = msg.sender;
        }
        
        uint256 tokenAmount;
        if (mtaTokens > 0) {
            if (IERC20(mtaTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(mtaTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }

            tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                mtaTokenAddress,
                _token,
                mtaTokens,
                _amountOutMin,
                receiver
            );

            if (_token == wethAddress) {
                IWETH(wethAddress).withdraw(tokenAmount);
                (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }
        }

        emit ClaimAdditionalTokens(msg.sender, mtaTokens, tokenAmount, _token);
    }

    function withdrawETH(uint256 _mtaAmount, uint256 _amountOutMin, address _feeToken) external {
        withdrawToken(wethAddress, _mtaAmount, _amountOutMin, _feeToken);        
    }

    function withdrawToken(address _token, uint256 _mtaAmount, uint256 _amountOutMin, address _feeToken) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_mtaAmount, _feeToken);

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

            address receiver;
            if (_token == wethAddress) {
                receiver = address(this);
            } else {
                receiver = msg.sender;
            }

            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                usdcAddress,
                _token, 
                yieldDeposit - fee, 
                _amountOutMin, 
                receiver
            );

            if (_token == wethAddress) {
                IWETH(wethAddress).withdraw(tokenAmount);
                (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }

            emit Withdraw(msg.sender, _token, tokenAmount, fee);
        }
    }

    function _withdrawYieldDeposit(uint256 _mStableAmount, address _feeToken) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_mStableAmount); 
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

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS1Proxy {
    function deposit(uint256 _deposit) external;
    function depositETH() external payable;
    function depositETHWithMin(uint256 _depositMin) external payable;
    function withdraw(uint256 _amount) external returns(uint256);
    function withdrawWithMin(uint256 _amount, uint256 _withdrawMin) external returns(uint256);
    function claimToDepositor(address _depositor) external returns(uint256);
    function claimToDeployer() external returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
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

import "../interfaces/IERC20.sol";
import "../interfaces/ImStable.sol"; 


contract S1mStableUSDTProxy {
    address private deployer;
    address private usdcAddress;
    address private mStableA;
    address private mStableVaultA;
    address private mUSDAddress;
    address private imUSDAddress;
    address private mtaTokenAddress;

    constructor(
        address _deployer,
        address _usdcAddress,
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress
    ) {
        deployer = _deployer;
        usdcAddress = _usdcAddress;
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;

        IERC20(usdcAddress).approve(_deployer, 2**256 - 1);
        IERC20(usdcAddress).approve(mStableA, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(uint256 _mStableDeposit) external onlyDeployer {
        IERC20(usdcAddress).transferFrom(deployer, address(this), _mStableDeposit);

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

    function withdraw(uint256 _mStableAmount) external onlyDeployer returns(uint256) {
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
        (, uint256 first, uint256 last) = ImStableVault(mStableVaultA).unclaimedRewards(address(this));
        ImStableVault(mStableVaultA).claimRewards(first, last);

        uint256 mtaBalance = IERC20(mtaTokenAddress).balanceOf(address(this));
        if (mtaBalance > 0) {
            IERC20(mtaTokenAddress).transfer(
                _address,
                mtaBalance
            );
        }

        return mtaBalance;
    }
}

// MN bby ¯\_(ツ)_/¯

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