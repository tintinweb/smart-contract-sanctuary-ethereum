// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IS1Proxy.sol";
import "./proxies/S1UnagiiETHProxy.sol";


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


contract S1UnagiiETH {
    uint8 constant public strategyIndex = 19;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;

    // protocols
    address public UnagiiEthVault;
    address public UnagiiEthV2;

    mapping(address => address) public depositors; 

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _UnagiiEthVault,
        address _UnagiiEthV2
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        UnagiiEthVault = _UnagiiEthVault;
        UnagiiEthV2 = _UnagiiEthV2;
    }

    event Deposit(address indexed _depositor, address indexed _token, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _fee);

    function calcWithdraw(uint256 _shares) external view returns(uint256) {
        return IUnagii(UnagiiEthVault).calcWithdraw(_shares);
    }

    function calcSharesToMint(uint256 _amount) external view returns(uint256) {
        return IUnagii(UnagiiEthVault).calcSharesToMint(_amount);
    }

    // Get current stake
    function getCurrentDeposit(address _address) external view returns(uint256, uint256) {
        uint256 UnagiiEthV2Balance = IERC20(UnagiiEthV2).balanceOf(depositors[_address]);
        uint256 UnagiiDeposit;
        if (UnagiiEthV2Balance > 0) {
            UnagiiDeposit = IUnagii(UnagiiEthVault).calcWithdraw(UnagiiEthV2Balance);
        }
        return (UnagiiEthV2Balance, UnagiiDeposit);
    }

    function depositETH(uint256 _depositMin) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        _yieldDeposit(msg.value, _depositMin);
        emit Deposit(msg.sender, wethAddress, msg.value, 0);     
    }

    function depositToken(address _token, uint256 _amount, uint256 _amountOutMin, uint256 _depositMin) external {
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
        _yieldDeposit(depositAmount, _depositMin);
 
        emit Deposit(msg.sender, _token, _amount, depositAmount);
    }

    function _yieldDeposit(uint256 _amount, uint256 _depositMin) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1UnagiiETHProxy s1proxy = new S1UnagiiETHProxy(
                address(this),
                UnagiiEthVault,
                UnagiiEthV2
            );
            depositors[msg.sender] = address(s1proxy);
            s1proxy.depositETHWithMin{value: _amount}(_depositMin);

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            IS1Proxy(depositors[msg.sender]).depositETHWithMin{value: _amount}(_depositMin);
        }
    }

    function withdrawETH(uint256 _amount, uint256 _withdrawMin, address _feeToken) external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_amount, _withdrawMin, _feeToken);

        // withdraw ETH
        (bool success, ) = payable(msg.sender).call{value: yieldDeposit - fee}("");
        require(success, "ERR: FAIL_SENDING_ETH");
        emit Withdraw(msg.sender, wethAddress, yieldDeposit - fee, fee);
    }

    function withdrawToken(address _token, uint256 _amount, uint256 _amountOutMin, uint256 _withdrawMin, address _feeToken) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_amount, _withdrawMin, _feeToken);

        uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: yieldDeposit - fee}(
            _token, 
            0, 
            _amountOutMin, 
            msg.sender
        );

        emit Withdraw(msg.sender, _token, tokenAmount, fee);
    }

    function _withdrawYieldDeposit(uint256 _amount, uint256 _withdrawMin, address _feeToken) private returns(uint256, uint256) {
        uint256 ethAmountToBeWithdrawn = IS1Proxy(depositors[msg.sender]).withdrawWithMin(_amount, _withdrawMin);
        
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

import "../interfaces/IERC20.sol";
import "../interfaces/IUnagii.sol";


contract S1UnagiiETHProxy {
    address public deployer;
    address public UnagiiEthVault;
    address public UnagiiEthV2;

    constructor(
        address _deployer,
        address _UnagiiEthVault,
        address _UnagiiEthV2
    ) {
        deployer = _deployer;
        UnagiiEthVault = _UnagiiEthVault;
        UnagiiEthV2 = _UnagiiEthV2;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function depositETHWithMin(uint256 _depositMin) external payable onlyDeployer {
        IUnagii(UnagiiEthVault).deposit{value: msg.value}(msg.value, _depositMin);
    }

    function withdrawWithMin(uint256 _amount, uint256 _withdrawMin) external onlyDeployer returns(uint256) {
        IUnagii(UnagiiEthVault).withdraw(_amount, _withdrawMin);
        uint256 ethBalance = address(this).balance;
        (bool success, ) = payable(deployer).call{value: ethBalance}("");
        require(success, "ERR: FAIL_SENDING_ETH");

        return ethBalance;
    }

    receive() external payable {}
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

interface IUnagii {
    function deposit(uint256 amount, uint256 _min) external payable;

    function withdraw(uint256 shares, uint256 _min) external;

    function calcWithdraw(uint256 _shares) external view returns(uint256);

    function calcSharesToMint(uint256 _amount) external view returns(uint256);
}