// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1TrueFiProxy.sol";


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


contract S1TrueFi {
    uint8 public strategyIndex; // 1 for USDC and 2 for USDT
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public depositIn; // USDC or USDT

    // protocols
    address public tfDepositIn; // tfUSDC or tfUSDT
    address public trueFiTokenAddress;
    address public stakedTrueFiTokenAddress;
    address public farmTrueFiAddress;

    mapping(address => address) public depositors; 

    constructor(
        uint8 _strategyIndex,
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _depositIn,
        address _tfDepositIn,
        address _trueFiTokenAddress,
        address _stakedTrueFiTokenAddress,
        address _farmTrueFiAddress
    ) {
        strategyIndex = _strategyIndex;
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        depositIn = _depositIn;
        tfDepositIn = _tfDepositIn;
        trueFiTokenAddress = _trueFiTokenAddress;
        stakedTrueFiTokenAddress = _stakedTrueFiTokenAddress;
        farmTrueFiAddress = _farmTrueFiAddress;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256) {
        uint256 _truToken = IFarmTrueFi(farmTrueFiAddress).claimable(IERC20(tfDepositIn), depositors[_address]);
        return _truToken;
    }

    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 tfUSDCAmount = IFarmTrueFi(farmTrueFiAddress).staked(
            IERC20(tfDepositIn),
            depositors[_address]
        );
        uint256 trueFiDeposit;
        if (tfUSDCAmount > 0) {
            trueFiDeposit = (ITrueFi(tfDepositIn).poolValue() * tfUSDCAmount) / ITrueFi(tfDepositIn).totalSupply();
            trueFiDeposit = (trueFiDeposit * ITrueFi(tfDepositIn).liquidExitPenalty(trueFiDeposit)) / 10000; // TrueFi's BASIS_PRECISION is 1000
        }
        return (tfUSDCAmount, trueFiDeposit);
    }

    function depositETH(uint256 _amountOutMin) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
            depositIn, 
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
        if (_token != depositIn) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }

            depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                depositIn, 
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
            S1TrueFiProxy s1proxy = new S1TrueFiProxy(
                address(this),
                depositIn,
                tfDepositIn,
                trueFiTokenAddress,
                stakedTrueFiTokenAddress,
                farmTrueFiAddress
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

    // claim TRU tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS1Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, truTokens, 0, address(0));
    }

    // claim TRU tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        claimInToken(wethAddress, _amountOutMin);        
    }

    // claim TRU tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 truTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer();

        address receiver;
        if (_token == wethAddress) {
            receiver = address(this);
        } else {
            receiver = msg.sender;
        }
        
        uint256 tokenAmount;
        if (truTokens > 0) {
            if (IERC20(trueFiTokenAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(trueFiTokenAddress).approve(uniswapConnector, 2**256 - 1);
            }

            tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                trueFiTokenAddress,
                _token,
                truTokens,
                _amountOutMin,
                receiver
            );

            if (_token == wethAddress) {
                IWETH(wethAddress).withdraw(tokenAmount);
                (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }
        }

        emit ClaimAdditionalTokens(msg.sender, truTokens, tokenAmount, _token);
    }

    function withdrawETH(uint256 _truAmount, uint256 _amountOutMin, address _feeToken) external {
        withdrawToken(wethAddress, _truAmount, _amountOutMin, _feeToken);        
    }

    function withdrawToken(address _token, uint256 _truAmount, uint256 _amountOutMin, address _feeToken) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_truAmount, _feeToken);

        if (_token == depositIn) { 
            // withdraw USDC or USDT
            IERC20(depositIn).transfer(
                msg.sender,
                yieldDeposit - fee
            );

            emit Withdraw(msg.sender, depositIn, yieldDeposit - fee, fee);
        } else {
            if (IERC20(depositIn).allowance(address(this), uniswapConnector) == 0) {
                IERC20(depositIn).approve(uniswapConnector, 2**256 - 1);
            }

            address receiver;
            if (_token == wethAddress) {
                receiver = address(this);
            } else {
                receiver = msg.sender;
            }

            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                depositIn,
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

    function _withdrawYieldDeposit(uint256 _truAmount, address _feeToken) private returns(uint256, uint256) {
        uint256 usdcAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_truAmount); 
        IERC20(depositIn).transferFrom(depositors[msg.sender], address(this), usdcAmountToBeWithdrawn);
        
        // if fee then send it to the feeCollector
        uint256 fee = (usdcAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) { 
            IERC20(depositIn).transfer(
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

interface IWETH {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/ITrueFi.sol";


contract S1TrueFiProxy {
    address private deployer;
    address private depositIn;
    address private tfDepositIn;
    address private trueFiTokenAddress;
    address private farmTrueFiAddress;

    constructor(
        address _deployer,
        address _depositIn,
        address _tfDepositIn,
        address _trueFiTokenAddress,
        address _stakedTrueFiTokenAddress,
        address _farmTrueFiAddress
    ) {
        deployer = _deployer;
        depositIn = _depositIn;
        tfDepositIn = _tfDepositIn;
        trueFiTokenAddress = _trueFiTokenAddress;
        farmTrueFiAddress = _farmTrueFiAddress;

        IERC20(depositIn).approve(_deployer, 2**256 - 1);
        IERC20(depositIn).approve(tfDepositIn, 2**256 - 1);
        IERC20(tfDepositIn).approve(farmTrueFiAddress, 2**256 - 1);
        IERC20(trueFiTokenAddress).approve(_stakedTrueFiTokenAddress, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    }

    function deposit(uint256 _trueFiDeposit) external onlyDeployer {
        IERC20(depositIn).transferFrom(deployer, address(this), _trueFiDeposit);

        // TrueFi deposit
        ITrueFi(tfDepositIn).join(_trueFiDeposit);
        IFarmTrueFi(farmTrueFiAddress).stake(
            IERC20(tfDepositIn),
            IERC20(tfDepositIn).balanceOf(address(this))
        );
    }

    function withdraw(uint256 _trueFiAmount) external onlyDeployer returns(uint256) {
        // unstake TrueFi tfUSDC
        IFarmTrueFi(farmTrueFiAddress).unstake(
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
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(tfDepositIn);
        IFarmTrueFi(farmTrueFiAddress).claim(tokens);

        uint256 truBalance = IERC20(trueFiTokenAddress).balanceOf(address(this));
        if (truBalance > 0) {
            IERC20(trueFiTokenAddress).transfer(
                _address,
                truBalance
            );
        }

        return truBalance;
    }
}

// MN bby ¯\_(ツ)_/¯

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapConnector {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
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