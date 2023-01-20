// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1VesperFinanceETHProxy.sol";


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


contract S1VesperFinanceETH {
    uint8 constant public strategyIndex = 4;
    address public feesAddress;
    address public uniswapConnector;
    address private wethAddress;

    // protocols
    address public vPoolETH;
    address public vPoolRewardsETH;
    address public vspToken;

    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _vPoolETH,
        address _vPoolRewardsETH,
        address _vspToken
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        vPoolETH = _vPoolETH;
        vPoolRewardsETH = _vPoolRewardsETH;
        vspToken = _vspToken;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    // Get current unclaimed additional tokens amount
    function getPendingAdditionalTokenClaims(address _address) external view returns(address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        return IVPoolRewards(vPoolRewardsETH).claimable(depositors[_address]);
    }

    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 vaETHShare = IERC20(vPoolETH).balanceOf(depositors[_address]);
        uint256 ethEquivalent;
        if (vaETHShare > 0) {
            uint256 pricePerShare = IVPoolETH(vPoolETH).pricePerShare();
            ethEquivalent = (pricePerShare * vaETHShare) / 10 ** 18;
        }
        return (vaETHShare, ethEquivalent);
    }

    function depositETH() public payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        _yieldDeposit(msg.value);
        emit Deposit(msg.sender, wethAddress, msg.value, 0);
    }

    function depositToken(address _token, uint256 _amount, uint256 _amountOutMin) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(IFees(feesAddress).whitelistedDepositCurrencies(strategyIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
            IERC20(_token).approve(uniswapConnector, 2**256 - 1);
        }

        uint256 depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
            _token,
            wethAddress, 
            _amount, 
            _amountOutMin, 
            address(this)
        );
        IWETH(wethAddress).withdraw(depositAmount);
        _yieldDeposit(depositAmount);
 
        emit Deposit(msg.sender, _token, _amount, depositAmount);
    }

    function _yieldDeposit(uint256 _amount) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1VesperFinanceETHProxy s1proxy = new S1VesperFinanceETHProxy(
                address(this),
                vPoolETH,
                vPoolRewardsETH,
                vspToken
            );
            depositors[msg.sender] = address(s1proxy);
            s1proxy.depositETH{value: _amount}();

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            IS1Proxy(depositors[msg.sender]).depositETH{value: _amount}();
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

    function withdrawETH(uint256 _vaETHAmount, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_vaETHAmount, _feeToken);

        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: yieldDeposit - fee}("");
        require(success, "ERR: FAIL_SENDING_ETH");
        emit Withdraw(msg.sender, wethAddress, yieldDeposit - fee, fee);
    }

    function withdrawToken(address _token, uint256 _vaETHAmount, uint256 _amountOutMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_vaETHAmount, _feeToken);

        uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: yieldDeposit - fee}(
            _token, 
            0, 
            _amountOutMin, 
            msg.sender
        );

        emit Withdraw(msg.sender, _token, tokenAmount, fee);
    }

    function _withdrawYieldDeposit(uint256 _vaETHAmount, address _feeToken) private returns(uint256, uint256) {
        uint256 ethAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdraw(_vaETHAmount);

        // if fee then send it to the feeCollector
        uint256 fee = (ethAmountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (fee > 0) {
            (bool success, ) = payable(IFees(feesAddress).feeCollector(strategyIndex)).call{value: fee}("");
            require(success, "ERR: FAIL_SENDING_ETH");
        }
        return (ethAmountToBeWithdrawn, fee);  
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

import "../interfaces/IERC20.sol";
import "../interfaces/IVesperFinance.sol";


contract S1VesperFinanceETHProxy {
    address public deployer;
    address public vPoolETH;
    address public vPoolRewardsETH;
    address public vspToken;

    constructor(
        address _deployer,
        address _vPoolETH,
        address _vPoolRewardsETH,
        address _vspToken
    ) {
        deployer = _deployer;
        vPoolETH = _vPoolETH;
        vPoolRewardsETH = _vPoolRewardsETH;
        vspToken = _vspToken;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function depositETH() external payable onlyDeployer {
        IVPoolETH(vPoolETH).deposit{value: msg.value}();
    }

    function withdraw(uint256 _amount) external onlyDeployer returns(uint256) {
        IVPoolETH(vPoolETH).withdrawETH(_amount);
        uint256 ethBalance = address(this).balance;
        (bool success, ) = payable(deployer).call{value: ethBalance}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        return ethBalance;
    }

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        // VSP tokens
        IVPoolRewards(vPoolRewardsETH).claimReward(address(this));

        uint256 vspBalance = IERC20(vspToken).balanceOf(address(this));
        IERC20(vspToken).transfer(
            _address,
            vspBalance
        );

        return vspBalance;
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