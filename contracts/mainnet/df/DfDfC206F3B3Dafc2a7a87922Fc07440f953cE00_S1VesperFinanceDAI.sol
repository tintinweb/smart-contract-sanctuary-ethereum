// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1VesperFinanceDAIProxy.sol";


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


contract S1VesperFinanceDAI {
    uint8 constant public strategyIndex = 5;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;
    address public daiAddress;

    // protocols
    address public vPoolDAI;
    address public vPoolRewardsDAI;
    address public vspToken;

    mapping(address => address) public depositors; 

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        return IVPoolRewards(vPoolRewardsDAI).claimable(depositors[_address]);
    }

    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 vaDAIShare = IERC20(vPoolDAI).balanceOf(depositors[_address]);
        uint256 daiEquivalent;
        if (vaDAIShare > 0) {
            uint256 pricePerShare = IVPoolDAI(vPoolDAI).pricePerShare();
            daiEquivalent = (pricePerShare * vaDAIShare) / 10 ** 18;
        }
        return (vaDAIShare, daiEquivalent);
    }

    function depositETH(uint256 _amountOutMin) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
            daiAddress, 
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
        if (_token != daiAddress) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }

            depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                daiAddress, 
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
            S1VesperFinanceDAIProxy s1proxy = new S1VesperFinanceDAIProxy(
                address(this),
                daiAddress,
                vPoolDAI,
                vPoolRewardsDAI,
                vspToken
            );
            depositors[msg.sender] = address(s1proxy);
            IERC20(daiAddress).approve(depositors[msg.sender], 2**256 - 1);
            s1proxy.deposit(_amount); 

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (IERC20(daiAddress).allowance(address(this), depositors[msg.sender]) == 0) {
                IERC20(daiAddress).approve(depositors[msg.sender], 2**256 - 1); 
            }

            IS1Proxy(depositors[msg.sender]).deposit(_amount);  
        }
    }

    // claim VSP tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 vspTokens = IS1Proxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, vspTokens, 0, address(0));
    }

    // claim VSP tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        claimInToken(wethAddress, _amountOutMin);        
    }

    // claim VSP tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _amountOutMin) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 vspTokens = IS1Proxy(depositors[msg.sender]).claimToDeployer();

        address receiver;
        if (_token == wethAddress) {
            receiver = address(this);
        } else {
            receiver = msg.sender;
        }
        
        uint256 tokenAmount;
        if (vspTokens > 0) {
            if (IERC20(vspToken).allowance(address(this), uniswapConnector) == 0) {
                IERC20(vspToken).approve(uniswapConnector, 2**256 - 1);
            }

            tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                vspToken,
                _token,
                vspTokens,
                _amountOutMin,
                receiver
            );

            if (_token == wethAddress) {
                IWETH(wethAddress).withdraw(tokenAmount);
                (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }
        }

        emit ClaimAdditionalTokens(msg.sender, vspTokens, tokenAmount, _token);
    }

    function withdrawETH(uint256 _vaDAIAmount, uint256 _amountOutMin, address _feeToken) external {
        withdrawToken(wethAddress, _vaDAIAmount, _amountOutMin, _feeToken);
    }

    function withdrawToken(address _token, uint256 _vaDAIAmount, uint256 _amountOutMin, address _feeToken) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_vaDAIAmount, _feeToken);

        if (_token == daiAddress) { 
            // withdraw DAI
            IERC20(daiAddress).transfer(
                msg.sender,
                yieldDeposit - fee
            );

            emit Withdraw(msg.sender, daiAddress, yieldDeposit - fee, fee);
        } else {
            if (IERC20(daiAddress).allowance(address(this), uniswapConnector) == 0) {
                IERC20(daiAddress).approve(uniswapConnector, 2**256 - 1);
            }

            address receiver;
            if (_token == wethAddress) {
                receiver = address(this);
            } else {
                receiver = msg.sender;
            }

            uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                daiAddress,
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

    function _withdrawYieldDeposit(uint256 _vaDAIAmount, address _feeToken) private returns(uint256, uint256) {
        uint256 daiAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_vaDAIAmount); 
        IERC20(daiAddress).transferFrom(depositors[msg.sender], address(this), daiAmountToBeWithdrawn);
        
        // if fee then send it to the feeCollector 
        uint256 fee = (daiAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) {
            IERC20(daiAddress).transfer(
                IFees(feesAddress).feeCollector(strategyIndex),
                fee
            );
        }
        return (daiAmountToBeWithdrawn, fee);
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

interface IUniswapConnector {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IVesperFinance.sol";


contract S1VesperFinanceDAIProxy {
    address private deployer;
    address private daiAddress;
    address private vPoolDAI;
    address private vPoolRewardsDAI;
    address private vspToken;

    constructor(
        address _deployer,
        address _daiAddress,
        address _vPoolDAI,
        address _vPoolRewardsDAI,
        address _vspToken
    ) {
        deployer = _deployer;
        daiAddress = _daiAddress;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        vspToken = _vspToken;

        IERC20(daiAddress).approve(_deployer, 2**256 - 1);
        IERC20(daiAddress).approve(vPoolDAI, 2**256 - 1);
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(uint256 _amount) external onlyDeployer {
        IERC20(daiAddress).transferFrom(deployer, address(this), _amount);

        IVPoolDAI(vPoolDAI).deposit(_amount);
    }

    function withdraw(uint256 _amount) external onlyDeployer returns(uint256) {
        IVPoolDAI(vPoolDAI).withdraw(_amount);

        return IERC20(daiAddress).balanceOf(address(this));
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
        if (vspBalance > 0) {
            IERC20(vspToken).transfer(
                _address,
                vspBalance
            );
        }

        return vspBalance;
    }
}

// MN bby ¯\_(ツ)_/¯

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