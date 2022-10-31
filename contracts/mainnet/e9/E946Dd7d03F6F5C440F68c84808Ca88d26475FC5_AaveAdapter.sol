// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../../base/AdapterBase.sol";
import "../../../interfaces/aave/v2/IProtocolDataProvider.sol";
import "../../../interfaces/aave/v2/IIncentivesController.sol";
import "../../../interfaces/aave/v2/ILendingPool.sol";
import "../../../interfaces/aave/v2/IWETHGateway.sol";
import "../../../interfaces/aave/v2/IAToken.sol";
import "../../../interfaces/aave/v2/IVariableDebtToken.sol";
import "../../../interfaces/aave/v2/IOracle.sol";
import "../../../interfaces/balancer/IVault.sol";
import "../../../interfaces/balancer/IFlashLoanRecipient.sol";
import "../../../core/controller/IAccount.sol";

contract AaveAdapter is AdapterBase, IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    mapping(address => address) public trustATokenAddr;
    IVault public constant flashLoanVault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    event AaveDeposit(address token, uint256 amount, address account);
    event AaveWithdraw(address token, uint256 amount, address account);
    event AaveBorrow(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveRepay(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveClaim(address target, uint256 amount);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "AaveV2Adapter")
    {}

    function initialize(
        address[] calldata tokenAddr,
        address[] calldata aTokenAddr
    ) external onlyTimelock {
        require(
            tokenAddr.length > 0 && tokenAddr.length == aTokenAddr.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            if (tokenAddr[i] == ethAddr) {
                require(
                    IAToken(aTokenAddr[i]).UNDERLYING_ASSET_ADDRESS() ==
                        wethAddr,
                    "Address mismatch."
                );
            } else {
                require(
                    IAToken(aTokenAddr[i]).UNDERLYING_ASSET_ADDRESS() ==
                        tokenAddr[i],
                    "Address mismatch."
                );
            }
            trustATokenAddr[tokenAddr[i]] = aTokenAddr[i];
        }
    }

    address public constant wethVtokenAddr =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;

    address public constant stethTokenAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant aaveProviderAddr =
        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    address public constant aaveDataAddr =
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

    address public constant wethGatewayAddr =
        0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04;

    address public constant aaveOracleAddr =
        0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;

    address public constant aaveLendingPoolAddr =
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    address public constant incentivesController =
        0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public executor; //for flashloan

    /// @dev Aave Referral Code
    uint16 internal constant referralCode = 0;

    function deposit(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (address token, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        require(trustATokenAddr[token] != address(0), "token error");
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);

        if (token == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.depositETH{value: msg.value}(
                aaveLendingPoolAddr,
                account,
                referralCode
            );
            emit AaveDeposit(token, msg.value, account);
        } else {
            pullAndApprove(token, account, aaveLendingPoolAddr, amount);
            aave.deposit(token, amount, account, referralCode);
            emit AaveDeposit(token, amount, account);
        }
    }

    function setCollateral(address token, bool isCollateral)
        external
        onlyDelegation
    {
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        aave.setUserUseReserveAsCollateral(token, isCollateral);
    }

    function withdraw(address tokenAddr, uint256 amount)
        external
        onlyDelegation
    {
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        if (tokenAddr == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.withdrawETH(aaveLendingPoolAddr, amount, address(this));
        } else {
            aave.withdraw(tokenAddr, amount, address(this));
        }
        emit AaveWithdraw(tokenAddr, amount, address(this));
    }

    function borrow(
        address token,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (token == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            wethGateway.borrowETH(
                aaveLendingPoolAddr,
                amount,
                rateMode,
                referralCode
            );
        } else {
            IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
            aave.borrow(token, amount, rateMode, referralCode, address(this));
        }
        emit AaveBorrow(token, amount, address(this), rateMode);
    }

    function approveDelegation(uint256 amount) external onlyDelegation {
        IVariableDebtToken(wethVtokenAddr).approveDelegation(
            wethGatewayAddr,
            amount
        );
    }

    function payback(
        address tokenAddr,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (tokenAddr == ethAddr) {
            IWETHGateway wethGateway = IWETHGateway(wethGatewayAddr);
            if (amount == type(uint256).max) {
                uint256 repayValue = IERC20(wethVtokenAddr).balanceOf(
                    address(this)
                );
                wethGateway.repayETH{value: repayValue}(
                    aaveLendingPoolAddr,
                    repayValue,
                    rateMode,
                    address(this)
                );
            } else {
                wethGateway.repayETH{value: amount}(
                    aaveLendingPoolAddr,
                    amount,
                    rateMode,
                    address(this)
                );
            }
        } else {
            IAaveLendingPool(aaveLendingPoolAddr).repay(
                tokenAddr,
                amount,
                rateMode,
                address(this)
            );
        }
        emit AaveRepay(tokenAddr, amount, address(this), rateMode);
    }

    function getReward(address[] memory assertAddress, uint256 amount)
        external
        onlyDelegation
    {
        IAaveIncentivesController(incentivesController).claimRewards(
            assertAddress,
            amount,
            address(this)
        );
        emit AaveClaim(incentivesController, amount);
    }

    function positionTransfer(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tempCollateralToken, uint256 loanAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        bytes memory callbackData = abi.encode(
            tempCollateralToken,
            loanAmount,
            IAccount(account).owner(),
            account
        );
        executeFlashLoan(tempCollateralToken, loanAmount, callbackData);
    }

    function executeFlashLoan(
        address _token,
        uint256 _amount,
        bytes memory _callbackData
    ) internal {
        executor = msg.sender;
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = IERC20(_token);
        amounts[0] = _amount;
        flashLoanVault.flashLoan(this, tokens, amounts, _callbackData);
    }

    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _feeAmounts,
        bytes memory _callbackData
    ) external override {
        require(msg.sender == address(flashLoanVault), "Invalid call!");
        require(executor != address(0), "Reentrant call!");
        (, , , address account) = abi.decode(
            _callbackData,
            (address, uint256, address, address)
        );
        uint256 tokenBefore = _tokens[0].balanceOf(ADAPTER_ADDRESS);
        approveToken(address(_tokens[0]), aaveLendingPoolAddr, _amounts[0]);
        IAaveLendingPool(aaveLendingPoolAddr).deposit(
            address(_tokens[0]),
            _amounts[0],
            account,
            referralCode
        );
        toCallback(account, AaveAdapter.exchangeDebt.selector, _callbackData);
        uint256 tokenAfter = _tokens[0].balanceOf(ADAPTER_ADDRESS);
        require(tokenBefore == tokenAfter, "Unbalanced assets!");

        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeTransfer(address(flashLoanVault), _amounts[i]);
        }
        executor = address(0);
    }

    function exchangeDebt(
        address loanToken,
        uint256 loanAmount,
        address user,
        address account
    ) external onlyDelegation {
        require(account == address(this) && tx.origin == user, "Invalid call!");
        IAaveProtocolDataProvider aaveDataProvider = IAaveProtocolDataProvider(
            aaveDataAddr
        );
        IAaveLendingPool aave = IAaveLendingPool(aaveLendingPoolAddr);
        address[] memory tokens = aave.getReservesList();
        for (uint256 i = 0; i < tokens.length; i++) {
            (, , address variableDebtTokenAddress) = aaveDataProvider
                .getReserveTokensAddresses(tokens[i]);
            uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(
                user
            );
            if (debtAmount != 0) {
                uint256 rateMode = 2;
                aave.borrow(
                    tokens[i],
                    debtAmount,
                    rateMode,
                    referralCode,
                    account
                );
                IERC20(tokens[i]).safeApprove(aaveLendingPoolAddr, 0);
                IERC20(tokens[i]).safeApprove(aaveLendingPoolAddr, debtAmount);
                aave.repay(tokens[i], debtAmount, rateMode, user);
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            (address aTokenAddress, , ) = aaveDataProvider
                .getReserveTokensAddresses(tokens[i]);
            uint256 aTokenAmount = IAToken(aTokenAddress).balanceOf(user);
            if (aTokenAmount != 0) {
                IAToken(aTokenAddress).transferFrom(
                    user,
                    account,
                    aTokenAmount
                );
            }
        }
        (address loanAToken, , ) = aaveDataProvider.getReserveTokensAddresses(
            loanToken
        );
        IERC20(loanAToken).safeApprove(aaveLendingPoolAddr, 0);
        IERC20(loanAToken).safeApprove(aaveLendingPoolAddr, loanAmount);
        aave.withdraw(loanToken, loanAmount, ADAPTER_ADDRESS);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../timelock/TimelockCallable.sol";
import "../../common/Basic.sol";

abstract contract AdapterBase is Basic, Ownable, TimelockCallable {
    using SafeERC20 for IERC20;

    address public ADAPTER_MANAGER;
    address public immutable ADAPTER_ADDRESS;
    string public ADAPTER_NAME;
    mapping(address => mapping(address => bool)) private approved;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            ADAPTER_MANAGER == msg.sender,
            "Caller is not the adapterManager."
        );
        _;
    }

    modifier onlyDelegation() {
        require(ADAPTER_ADDRESS != address(this), "Only for delegatecall.");
        _;
    }

    constructor(
        address _adapterManager,
        address _timelock,
        string memory _name
    ) TimelockCallable(_timelock) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        require(_token != address(0) && _token != ethAddr);
        uint256 balance = IERC20(_token).balanceOf(_from);
        uint256 currentAmount = balance < _amount ? balance : _amount;
        IERC20(_token).safeTransferFrom(_from, address(this), currentAmount);
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (!approved[_token][_spender]) {
            IERC20 token = IERC20(_token);
            token.safeApprove(_spender, 0);
            token.safeApprove(_spender, type(uint256).max);
            approved[_token][_spender] = true;
        }
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address _token,
        address _from,
        address _spender,
        uint256 _amount
    ) internal {
        pullTokensIfNeeded(_token, _from, _amount);
        approveToken(_token, _spender, _amount);
    }

    function returnAsset(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            if (_token == ethAddr) {
                safeTransferETH(_to, _amount);
            } else {
                require(_token != address(0), "Token error!");
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function toCallback(
        address _target,
        bytes4 _selector,
        bytes memory _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodePacked(_selector, _callData)
        );
        require(success, string(returnData));
    }

    //Handle when someone else accidentally transfers assets to this contract
    function sweep(address[] memory tokens, address receiver)
        external
        onlyTimelock
    {
        require(address(this) == ADAPTER_ADDRESS, "!Invalid call");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(token).safeTransfer(receiver, amount);
            }
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeTransferETH(receiver, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAaveProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER() external view returns (address);

    function getAllATokens() external view returns (TokenData[] memory);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveEModeCategory(address asset)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAaveIncentivesController {
    function DISTRIBUTION_END() external view returns (uint256);

    function EMISSION_MANAGER() external view returns (address);

    function PRECISION() external view returns (uint8);

    function REVISION() external view returns (uint256);

    function REWARD_TOKEN() external view returns (address);

    function assets(address)
        external
        view
        returns (
            uint104 emissionPerSecond,
            uint104 index,
            uint40 lastUpdateTimestamp
        );

    function claimRewards(
        address[] memory assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    function claimRewardsOnBehalf(
        address[] memory assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    function configureAssets(
        address[] memory assets,
        uint256[] memory emissionsPerSecond
    ) external;

    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getClaimer(address user) external view returns (address);

    function getDistributionEnd() external view returns (uint256);

    function getRewardsBalance(address[] memory assets, address user)
        external
        view
        returns (uint256);

    function getRewardsVault() external view returns (address);

    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    function getUserUnclaimedRewards(address _user)
        external
        view
        returns (uint256);

    function handleAction(
        address user,
        uint256 totalSupply,
        uint256 userBalance
    ) external;

    function initialize(address rewardsVault) external;

    function setClaimer(address user, address caller) external;

    function setDistributionEnd(uint256 distributionEnd) external;

    function setRewardsVault(address rewardsVault) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./library/DataTypes.sol";

interface IAaveLendingPool {
    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external;

    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;

    function repay(
        address _asset,
        uint256 _amount,
        uint256 _rateMode,
        address _onBehalfOf
    ) external;

    function setUserUseReserveAsCollateral(
        address _asset,
        bool _useAsCollateral
    ) external;

    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IWETHGateway {
    function authorizeLendingPool(address lendingPool) external;

    function borrowETH(
        address lendingPool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function emergencyEtherTransfer(address to, uint256 amount) external;

    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function getWETHAddress() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function repayETH(
        address lendingPool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function transferOwnership(address newOwner) external;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAToken {
    function balanceOf(address _user) external view returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function POOL() external view returns (address);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IVariableDebtToken {
    function scaledBalanceOf(address user) external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    function scaledTotalSupply() external view returns (uint256);

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAaveOracle {
    function BASE_CURRENCY() external view returns (address);

    function BASE_CURRENCY_UNIT() external view returns (uint256);

    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets)
        external
        view
        returns (uint256[] calldata);

    function getFallbackOracle() external view returns (address);

    function getSourceOfAsset(address asset) external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;

    function setFallbackOracle(address fallbackOracle) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";
import "./IAsset.sol";

interface IVault is IFlashLoanRecipient {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function WETH() external view returns (address);

    function batchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function deregisterTokens(bytes32 poolId, address[] calldata tokens)
        external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external;

    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getAuthorizer() external view returns (address);

    function getDomainSeparator() external view returns (bytes32);

    function getInternalBalance(address user, address[] calldata tokens)
        external
        view
        returns (uint256[] memory balances);

    function getNextNonce(address user) external view returns (uint256);

    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getProtocolFeesCollector() external view returns (address);

    function hasApprovedRelayer(address user, address relayer)
        external
        view
        returns (bool);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external;

    function managePoolBalance(PoolBalanceOp[] calldata ops) external;

    function manageUserBalance(UserBalanceOp[] calldata ops) external;

    function queryBatchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory);

    function registerPool(uint8 specialization) external returns (bytes32);

    function registerTokens(
        bytes32 poolId,
        address[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    function setAuthorizer(address newAuthorizer) external;

    function setPaused(bool paused) external;

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAccount {
    function owner() external view returns (address);

    function createSubAccount(bytes memory _data, uint256 _costETH)
        external
        payable
        returns (address newSubAccount);

    function executeOnAdapter(bytes calldata _callBytes, bool _callType)
        external
        payable
        returns (bytes memory);

    function multiCall(
        bool[] calldata _callType,
        bytes[] calldata _callArgs,
        bool[] calldata _isNeedCallback
    ) external;

    function setAdvancedOption(bool val) external;

    function callOnSubAccount(
        address _target,
        bytes calldata _callArgs,
        uint256 amountETH
    ) external;

    function withdrawAssets(
        address[] calldata _tokens,
        address _receiver,
        uint256[] calldata _amounts
    ) external;

    function approve(
        address tokenAddr,
        address to,
        uint256 amount
    ) external;

    function approveTokens(
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts
    ) external;

    function isSubAccount(address subAccount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Basic {
    using SafeERC20 for IERC20;
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped ETH address
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function safeTransferETH(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "helper::safeTransferETH: ETH transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data; // size is _maxReserves / 128 + ((_maxReserves % 128 > 0) ? 1 : 0), but need to be literal
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}