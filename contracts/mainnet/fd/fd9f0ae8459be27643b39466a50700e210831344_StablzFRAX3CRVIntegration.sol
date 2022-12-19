//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "contracts/integrations/curve/common/Stablz3CRVMetaPoolIntegration.sol";

/// @title Stablz FRAX-3CRV pool integration
contract StablzFRAX3CRVIntegration is Stablz3CRVMetaPoolIntegration {

    /// @dev Meta pool specific addresses
    address private constant FRAX_3CRV_POOL = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address private constant FRAX_3CRV_GAUGE = 0x72E158d38dbd50A483501c24f792bDAAA3e7D55C;

    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _oracle, address _feeHandler) Stablz3CRVMetaPoolIntegration(
        FRAX_3CRV_POOL,
        FRAX_3CRV_GAUGE,
        _oracle,
        _feeHandler
    ) {

    }

}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/fees/IStablzFeeHandler.sol";
import "contracts/integrations/curve/common/ICurve3CRVDepositZap.sol";
import "contracts/integrations/curve/common/ICurve3CRVGauge.sol";
import "contracts/integrations/curve/common/ICurve3CRVBasePool.sol";
import "contracts/integrations/curve/common/ICurve3CRVPool.sol";
import "contracts/integrations/curve/common/ICurve3CRVMinter.sol";
import "contracts/integrations/curve/common/ICurveSwap.sol";
import "contracts/integrations/common/StablzLPIntegration.sol";

/// @title Stablz 3CRV - Meta pool integration
contract Stablz3CRVMetaPoolIntegration is StablzLPIntegration {

    using SafeERC20 for IERC20;

    /// @dev Meta pool specific addresses
    address public immutable CRV_META_POOL;
    address public immutable CRV_GAUGE;

    /// @dev Common Curve contracts
    address public constant CRV_SWAP = 0x81C46fECa27B31F3ADC2b91eE4be9717d1cd3DD7;
    address internal constant CRV_DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
    address internal constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address internal constant CRV_BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    /// @dev Underlying pool token addresses
    address public immutable META_TOKEN;
    address internal constant DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @dev Curve tokens
    address internal constant CRV_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant LP_3CRV_TOKEN = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    mapping(address => uint) private _stablecoinIndex;

    uint[3] public emergencyWithdrawnTokens;

    /// @param _metaPool Meta pool address
    /// @param _gauge Gauge address
    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _metaPool, address _gauge, address _oracle, address _feeHandler) StablzLPIntegration(_oracle, _feeHandler){
        require(_metaPool != address(0), "Stablz3CRVMetaPoolIntegration: _metaPool cannot be the zero address");
        require(_gauge != address(0), "Stablz3CRVMetaPoolIntegration: _gauge cannot be the zero address");
        CRV_META_POOL = _metaPool;
        CRV_GAUGE = _gauge;
        META_TOKEN = ICurve3CRVPool(CRV_META_POOL).coins(0);
        _stablecoinIndex[DAI_TOKEN] = 1;
        _stablecoinIndex[USDC_TOKEN] = 2;
        _stablecoinIndex[USDT_TOKEN] = 3;
    }

    /// @notice Calculate the amount of a given stablecoin received when withdrawing Meta pool LP tokens
    /// @param _stablecoin stablecoin address
    /// @param _metaPoolLPTokens Meta pool LP amount to remove
    /// @return uint Expected number of stablecoin tokens received
    function calcWithdrawalAmount(address _stablecoin, uint _metaPoolLPTokens) external view onlyWithdrawalTokens(_stablecoin) returns (uint) {
        return ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).calc_withdraw_one_coin(CRV_META_POOL, _metaPoolLPTokens, _getStablecoinIndex(_stablecoin));
    }

    /// @notice Calculate the amount of a given stablecoin received when withdrawing base pool LP (3CRV) tokens
    /// @param _stablecoin stablecoin address
    /// @param _3CRVLPTokens 3CRV LP amount to remove
    /// @return uint Expected number of stablecoin tokens received
    function calcRewardAmount(address _stablecoin, uint _3CRVLPTokens) external view onlyRewardTokens(_stablecoin) returns (uint) {
        return ICurve3CRVBasePool(CRV_BASE_POOL).calc_withdraw_one_coin(_3CRVLPTokens, _getBasePoolStablecoinIndex(_stablecoin));
    }

    /// @notice Check if an address is an accepted deposit token
    /// @param _token Token address
    /// @return bool true if it is a supported deposit token, false if not
    function isDepositToken(address _token) public override view returns (bool) {
        return _token == META_TOKEN || _isBasePoolToken(_token);
    }

    /// @notice Check if an address is an accepted withdrawal token
    /// @param _token Token address
    /// @return bool true if it is a supported withdrawal token, false if not
    function isWithdrawalToken(address _token) public override view returns (bool) {
        return _token == META_TOKEN || _isBasePoolToken(_token);
    }

    /// @notice Check if an address is an accepted reward token
    /// @param _token Token address
    /// @return bool true if it is a supported reward token, false if not
    function isRewardToken(address _token) public override view returns (bool) {
        return _isBasePoolToken(_token);
    }

    /// @notice Get the CRV to 3CRV swap route
    /// @return route Swap route for CRV to 3CRV
    function getCRVTo3CRVRoute() public pure returns (address[9] memory route) {
        route[0] = CRV_TOKEN;
        route[1] = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
        route[2] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        route[3] = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
        route[4] = USDT_TOKEN;
        route[5] = CRV_BASE_POOL;
        route[6] = LP_3CRV_TOKEN;
        return route;
    }

    /// @notice Get the CRV to 3CRV swap params
    /// @return swapParams Swap params for CRV to 3CRV
    function getCRVTo3CRVSwapParams() public pure returns (uint[3][4] memory swapParams) {
        swapParams[0][0] = 1;
        swapParams[0][2] = 3;
        swapParams[1][0] = 2;
        swapParams[1][2] = 3;
        swapParams[2][0] = 2;
        swapParams[2][2] = 7;
        return swapParams;
    }

    /// @dev Deposit stablecoins
    /// @param _stablecoin stablecoin to deposit
    /// @param _amount amount to deposit
    /// @param _minLPAmount minimum amount of LP to receive
    /// @return lpTokens Amount of LP tokens received from depositing
    function _farmDeposit(address _stablecoin, uint _amount, uint _minLPAmount) internal override returns (uint lpTokens) {
        uint[4] memory amounts = _constructAmounts(_stablecoin, _amount);
        IERC20(_stablecoin).safeIncreaseAllowance(CRV_DEPOSIT_ZAP, _amount);
        lpTokens = ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).add_liquidity(
            CRV_META_POOL,
            amounts,
            _minLPAmount
        );
        IERC20(CRV_META_POOL).safeIncreaseAllowance(CRV_GAUGE, lpTokens);
        ICurve3CRVGauge(CRV_GAUGE).deposit(lpTokens);
    }

    /// @dev Withdraw stablecoins
    /// @param _stablecoin chosen stablecoin to withdraw
    /// @param _lpTokens LP amount to remove
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return received Amount of _stablecoin received from withdrawing _lpToken
    function _farmWithdrawal(address _stablecoin, uint _lpTokens, uint _minAmount) internal override returns (uint received) {
        ICurve3CRVGauge(CRV_GAUGE).withdraw(_lpTokens);

        IERC20(CRV_META_POOL).safeIncreaseAllowance(CRV_DEPOSIT_ZAP, _lpTokens);

        received = ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).remove_liquidity_one_coin(CRV_META_POOL, _lpTokens, _getStablecoinIndex(_stablecoin), _minAmount);
    }

    /// @dev Claim Curve rewards and convert them to 3CRV
    /// @param _minAmounts Minimum swap amounts for harvesting, index: 0 - USDD => 3CRV, 1 - CRV => 3CRV
    /// @return rewards Amount of 3CRV rewards harvested
    function _farmHarvest(uint[10] memory _minAmounts) internal override returns (uint rewards) {
        if (_minAmounts[0] > 0) {
            /// @dev claim Meta Token rewards, its possible for the gauge contract to changes it's reward token to a token other than the meta token
            /// therefore if this occurs, the owner/oracle should perform an emergency shutdown and a new contract should be redeployed to support this
            ICurve3CRVGauge(CRV_GAUGE).claim_rewards();
            uint metaTokenBalance = IERC20(META_TOKEN).balanceOf(address(this));
            rewards += _exchangeMetaTokenFor3CRV(metaTokenBalance, _minAmounts[0]);
        }
        if (_minAmounts[1] > 0) {
            /// @dev claim CRV rewards, this function call is expensive but is dependant on time since last call, not rewards
            ICurve3CRVMinter(CRV_MINTER).mint(CRV_GAUGE);
            uint crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));
            rewards += _swapCRVTo3CRV(crvBalance, _minAmounts[1]);
        }
        return rewards;
    }

    /// @dev Withdraw all LP in base tokens
    /// @param _metaPoolLPTokens Amount of Meta pool LP tokens
    /// @param _minAmounts Minimum amounts for withdrawal, index: 0 - 3CRV, 1 - DAI, 2 - USDC, 3 - USDT
    function _farmEmergencyWithdrawal(uint _metaPoolLPTokens, uint[10] memory _minAmounts) internal override {
        ICurve3CRVGauge(CRV_GAUGE).withdraw(_metaPoolLPTokens);

        uint basePoolLPTokens = ICurve3CRVPool(CRV_META_POOL).remove_liquidity_one_coin(_metaPoolLPTokens, 1, _minAmounts[0]);

        uint[3] memory minTokenAmounts = [_minAmounts[1], _minAmounts[2], _minAmounts[3]];
        emergencyWithdrawnTokens = _removeBasePoolLiquidity(basePoolLPTokens, minTokenAmounts);
    }

    /// @dev Transfer pro rata amount of stablecoins to user
    function _withdrawAfterShutdown() internal override {
        _mergeRewards();
        for (uint i; i < 3; i++) {
            address stablecoin = ICurve3CRVBasePool(CRV_BASE_POOL).coins(i);
            uint amount = emergencyWithdrawnTokens[i] * users[_msgSender()].lpBalance / totalActiveDeposits;
            IERC20(stablecoin).safeTransfer(_msgSender(), amount);
        }
    }

    /// @param _stablecoin Stablecoin address
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return rewards Rewards claimed in _stablecoin
    function _claimRewards(address _stablecoin, uint _minAmount) internal override returns (uint rewards) {
        _mergeRewards();
        /// @dev rewards are 3CRV LP tokens
        uint heldRewards = users[_msgSender()].heldRewards;
        require(heldRewards > 0, "Stablz3CRVMetaPoolIntegration: No rewards available");

        users[_msgSender()].heldRewards = 0;

        rewards = _removeBasePoolLiquidityOneCoin(heldRewards, _stablecoin, _minAmount);

        IERC20(_stablecoin).safeTransfer(_msgSender(), rewards);
        return rewards;
    }

    /// @dev convert 3CRV fee to USDT and transfer to fee handler contract
    /// @param _minAmount minimum amount of USDT to receive
    function _handleFee(uint _minAmount) internal override {
        uint fee = totalUnhandledFee;
        totalUnhandledFee = 0;

        uint usdtFee = _removeBasePoolLiquidityOneCoin(fee, USDT_TOKEN, _minAmount);

        IERC20(USDT_TOKEN).safeTransfer(feeHandler, usdtFee);
    }

    /// @dev Construct an amounts array for a given stablecoin amount
    /// @param _stablecoin Stablecoin address
    /// @param _amount Amount of tokens
    /// @return amounts Array of amounts with the stablecoin index set to the amount
    function _constructAmounts(address _stablecoin, uint _amount) internal view returns (uint[4] memory amounts) {
        amounts[_stablecoinIndex[_stablecoin]] = _amount;
        return amounts;
    }

    /// @dev remove _lpTokens from base pool as _stablecoin
    /// @param _lpTokens LP amount to remove
    /// @param _stablecoin Stablecoin address
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return received Amount of _stablecoin received
    function _removeBasePoolLiquidityOneCoin(uint _lpTokens, address _stablecoin, uint _minAmount) internal returns (uint received) {
        uint stablecoinBalanceBefore = IERC20(_stablecoin).balanceOf(address(this));
        ICurve3CRVBasePool(CRV_BASE_POOL).remove_liquidity_one_coin(_lpTokens, _getBasePoolStablecoinIndex(_stablecoin), _minAmount);
        uint stablecoinBalanceAfter = IERC20(_stablecoin).balanceOf(address(this));
        received = stablecoinBalanceAfter - stablecoinBalanceBefore;
    }

    /// @dev remove _lpTokens from base pool as underlying tokens
    /// @param _lpTokens LP amount to remove
    /// @param _minAmounts minimum amounts of each underlying token to receive
    /// @return received Amounts of each underlying token received
    function _removeBasePoolLiquidity(uint _lpTokens, uint[3] memory _minAmounts) internal returns (uint[3] memory received) {
        uint daiBalanceBefore = IERC20(DAI_TOKEN).balanceOf(address(this));
        uint usdcBalanceBefore = IERC20(USDC_TOKEN).balanceOf(address(this));
        uint usdtBalanceBefore = IERC20(USDT_TOKEN).balanceOf(address(this));
        ICurve3CRVBasePool(CRV_BASE_POOL).remove_liquidity(_lpTokens, _minAmounts);
        uint daiBalanceAfter = IERC20(DAI_TOKEN).balanceOf(address(this));
        uint usdcBalanceAfter = IERC20(USDC_TOKEN).balanceOf(address(this));
        uint usdtBalanceAfter = IERC20(USDT_TOKEN).balanceOf(address(this));
        received[0] = daiBalanceAfter - daiBalanceBefore;
        received[1] = usdcBalanceAfter - usdcBalanceBefore;
        received[2] = usdtBalanceAfter - usdtBalanceBefore;
        return received;
    }

    /// @dev Exchange Meta token for 3CRV if _amount is greater than zero
    /// @param _amount Amount of Meta tokens to swap to 3CRV
    /// @param _minAmount minimum amount of 3CRV to receive
    /// @return received Amount of 3CRV tokens received
    function _exchangeMetaTokenFor3CRV(uint _amount, uint _minAmount) internal returns (uint received) {
        IERC20(META_TOKEN).safeIncreaseAllowance(CRV_META_POOL, _amount);
        received = ICurve3CRVPool(CRV_META_POOL).exchange(
            0,
            1,
            _amount,
            _minAmount
        );
    }

    /// @dev Swap CRV to 3CRV
    /// @param _amount Amount of CRV tokens to swap to 3CRV
    /// @param _minAmount minimum amount of 3CRV to receive
    /// @return received Amount of 3CRV tokens received
    function _swapCRVTo3CRV(uint _amount, uint _minAmount) internal returns (uint received) {
        IERC20(CRV_TOKEN).safeIncreaseAllowance(CRV_SWAP, _amount);
        /// @dev swapping CRV to 3CRV may revert due to the swap contract being killed therefore it is recommended
        /// to harvest frequently to reduce any loss that may occur as a result of the swap contract being killed
        received = ICurveSwap(CRV_SWAP).exchange_multiple(
            getCRVTo3CRVRoute(),
            getCRVTo3CRVSwapParams(),
            _amount,
            _minAmount
        );
    }

    /// @param _token Token address
    /// @return bool true if _token is a base pool token, false if not
    function _isBasePoolToken(address _token) internal view returns (bool) {
        return _stablecoinIndex[_token] > 0;
    }

    /// @param _stablecoin Stablecoin address
    /// @return int128 Index of stablecoin in meta pool combined with base pool
    function _getStablecoinIndex(address _stablecoin) internal view returns (int128) {
        return int128(int(_stablecoinIndex[_stablecoin]));
    }

    /// @param _stablecoin Stablecoin address
    /// @return int128 Index of base pool stablecoin
    function _getBasePoolStablecoinIndex(address _stablecoin) internal view returns (int128) {
        return int128(int(_stablecoinIndex[_stablecoin] - 1));
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "contracts/access/OracleManaged.sol";
import "contracts/fees/IStablzFeeHandler.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Stablz LP integration
abstract contract StablzLPIntegration is OracleManaged, ReentrancyGuard {

    using SafeERC20 for IERC20;

    address public immutable feeHandler;

    uint public totalActiveDeposits;
    uint public totalUnhandledFee;
    uint public currentRewardFactor;
    // @dev this is used to allow for decimals in the currentRewardValue
    uint internal constant rewardFactorAccuracy = 1 ether;
    uint public depositThreshold = 50 ether;
    uint public feeHandlingThreshold = 50 ether;

    bool public isShutdown;
    bool public isDepositingEnabled;

    struct User {
        uint rewardFactor;
        uint heldRewards;
        uint lpBalance;
        bool hasEmergencyWithdrawn;
    }

    mapping(address => User) public users;

    event Deposit(address user, address stablecoin, uint amount, uint lpTokens);
    event Withdraw(address user, address stablecoin, uint lpTokens, uint received);
    event ClaimRewards(address user, address stablecoin, uint rewards);
    event WithdrawAfterShutdown(address user);
    event DepositingEnabled();
    event DepositingDisabled();
    event FeeHandlingThresholdUpdated(uint feeHandlingThreshold);
    event EmergencyShutdown();
    event Harvest(uint total, uint rewards, uint fee);
    event RewardDistribution(uint rewards, uint currentActiveDeposits);
    event DepositThresholdUpdated(uint threshold);

    /// @param _token Token address
    modifier onlyDepositTokens(address _token) {
        require(isDepositToken(_token), "StablzLPIntegration: Token is not a supported deposit token");
        _;
    }

    /// @param _token Token address
    modifier onlyWithdrawalTokens(address _token) {
        require(isWithdrawalToken(_token), "StablzLPIntegration: Token is not a supported withdrawal token");
        _;
    }

    /// @param _token Token address
    modifier onlyRewardTokens(address _token) {
        require(isRewardToken(_token), "StablzLPIntegration: Token is not a supported reward token");
        _;
    }

    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _oracle, address _feeHandler) {
        require(_feeHandler != address(0), "StablzLPIntegration: _feeHandler cannot be the zero address");
        _setOracle(_oracle);
        feeHandler = _feeHandler;
    }

    /// @notice Deposit stablecoins
    /// @param _stablecoin Stablecoin to deposit
    /// @param _amount Amount of _stablecoin to deposit
    /// @param _minLPAmount Minimum amount of LP to receive
    function deposit(address _stablecoin, uint _amount, uint _minLPAmount) external nonReentrant onlyDepositTokens(_stablecoin) {
        require(!isShutdown, "StablzLPIntegration: Integration shutdown, depositing is no longer available");
        require(isDepositingEnabled, "StablzLPIntegration: Depositing is not allowed at this time");
        require(_normalize(_stablecoin, _amount) >= depositThreshold && _amount > 0, "StablzLPIntegration: Deposit threshold not met");
        uint lpTokens = _deposit(_stablecoin, _amount, _minLPAmount);
        emit Deposit(_msgSender(), _stablecoin, _amount, lpTokens);
    }

    /// @notice Withdraw stablecoins
    /// @param _stablecoin Desired stablecoin to withdraw
    /// @param _lpTokens Amount of LP tokens to remove from pool in the _stablecoin
    /// @param _minAmount Minimum amount of desired stablecoin
    function withdraw(address _stablecoin, uint _lpTokens, uint _minAmount) external nonReentrant onlyWithdrawalTokens(_stablecoin) {
        require(!isShutdown, "StablzLPIntegration: Cannot withdraw using this function, use withdrawAfterShutdown instead");
        require(_lpTokens > 0, "StablzLPIntegration: _lpTokens is invalid");
        uint received = _withdraw(_stablecoin, _lpTokens, _minAmount);
        emit Withdraw(_msgSender(), _stablecoin, _lpTokens, received);
    }

    /// @notice Claim rewards from the contract
    /// @param _stablecoin Desired stablecoin to receive rewards in
    /// @param _minAmount Minimum amount of desired stablecoin
    function claimRewards(address _stablecoin, uint _minAmount) external nonReentrant onlyRewardTokens(_stablecoin) {
        uint rewards = _claimRewards(_stablecoin, _minAmount);
        emit ClaimRewards(_msgSender(), _stablecoin, rewards);
    }

    /// @notice Withdraw stablecoins after the contract has been shutdown
    function withdrawAfterShutdown() external nonReentrant {
        require(isShutdown, "StablzLPIntegration: Cannot withdraw using this function, use withdraw instead");
        require(!users[_msgSender()].hasEmergencyWithdrawn && users[_msgSender()].lpBalance > 0, "StablzLPIntegration: Nothing to withdraw");
        users[_msgSender()].hasEmergencyWithdrawn = true;
        _withdrawAfterShutdown();
        emit WithdrawAfterShutdown(_msgSender());
    }

    /// @notice Harvest farm rewards (if there are any) and store them in the contract
    /// @param _minAmounts Minimum amounts for harvesting, data is specific to integration
    function harvest(uint[10] memory _minAmounts) external onlyOwnerOrOracle nonReentrant {
        _harvest(_minAmounts);
    }

    /// @notice Handle the collected fee and transfer to StablzFeeHandler
    /// @param _minAmount minimum amount of stablecoin to receive
    function handleFee(uint _minAmount) external onlyOwnerOrOracle nonReentrant {
        require(totalUnhandledFee > 0, "StablzLPIntegration: No fees to handle");
        require(isShutdown || totalUnhandledFee >= feeHandlingThreshold, "StablzLPIntegration: Collected fees are below threshold");
        _handleFee(_minAmount);
    }

    /// @notice Remove liquidity from farm and leave tokens in the contract for user's to claim pro rata
    /// @param _minAmounts Minimum amounts for removing liquidity, data is specific to integration
    function emergencyShutdown(uint[10] memory _minAmounts) external onlyOwnerOrOracle {
        require(!isShutdown, "StablzLPIntegration: Integration is already shutdown");
        isShutdown = true;
        _emergencyShutdown(_minAmounts);
        emit EmergencyShutdown();
    }

    /// @notice Enable depositing
    function enableDepositing() external onlyOwner {
        require(!isShutdown, "StablzLPIntegration: Enabling deposits is not allowed due to the integration being shutdown");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    /// @notice Disable depositing
    function disableDepositing() external onlyOwner {
        require(!isShutdown, "StablzLPIntegration: Deposits are already disabled due to the integration being shutdown");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    /// @notice Set the deposit threshold
    /// @param _threshold Deposit threshold
    function setDepositThreshold(uint _threshold) external onlyOwner {
        depositThreshold = _threshold;
        emit DepositThresholdUpdated(_threshold);
    }

    /// @notice Set the threshold the unhandled fee needs to reach before it can be handled
    /// @param _threshold Fee handling threshold
    function setFeeHandlingThreshold(uint _threshold) external onlyOwner {
        feeHandlingThreshold = _threshold;
        emit FeeHandlingThresholdUpdated(feeHandlingThreshold);
    }

    /// @notice Get the LP balance acquired from depositing for a user
    /// @param _user User address
    /// @return uint User's LP balance
    function getLPBalance(address _user) external view virtual returns (uint) {
        return users[_user].lpBalance;
    }

    /// @notice Get the current rewards for a user
    /// @param _user User address
    /// @return uint Current rewards for _user
    function getReward(address _user) external view virtual returns (uint) {
        return _getHeldRewards(_user) + _getCalculatedRewards(_user);
    }

    /// @notice Check if an address is an accepted deposit token
    /// @param _token Token address
    /// @return bool true if it is a supported deposit token, false if not
    function isDepositToken(address _token) public virtual view returns (bool);

    /// @notice Check if an address is an accepted withdrawal token
    /// @param _token Token address
    /// @return bool true if it is a supported withdrawal token, false if not
    function isWithdrawalToken(address _token) public virtual view returns (bool);

    /// @notice Check if an address is an accepted reward token
    /// @param _token Token address
    /// @return bool true if it is a supported reward token, false if not
    function isRewardToken(address _token) public virtual view returns (bool);

    /// @param _user User address
    /// @return uint Held rewards
    function _getHeldRewards(address _user) internal view virtual returns (uint) {
        return users[_user].heldRewards;
    }

    /// @param _user User address
    /// @return uint Calculated rewards
    function _getCalculatedRewards(address _user) internal view virtual returns (uint) {
        uint balance = users[_user].lpBalance;
        return balance * (currentRewardFactor - users[_user].rewardFactor) / rewardFactorAccuracy;
    }

    /// @dev Merge held rewards with calculated rewards
    function _mergeRewards() internal virtual {
        _holdCalculatedRewards();
        users[_msgSender()].rewardFactor = currentRewardFactor;
    }

    /// @dev Convert calculated rewards into held rewards
    /// @dev Used when the user carries out an action that would cause their calculated rewards to change unexpectedly
    function _holdCalculatedRewards() internal virtual {
        uint calculatedReward = _getCalculatedRewards(_msgSender());
        if (calculatedReward > 0) {
            users[_msgSender()].heldRewards += calculatedReward;
        }
    }

    /// @param _stablecoin Stablecoin to deposit
    /// @param _amount Amount of _stablecoin to deposit
    /// @param _minLPAmount Minimum amount of LP to receive
    /// @return lpTokens Amount of LP tokens received from depositing
    function _deposit(address _stablecoin, uint _amount, uint _minLPAmount) internal virtual returns (uint lpTokens){
        _mergeRewards();

        IERC20(_stablecoin).safeTransferFrom(_msgSender(), address(this), _amount);

        lpTokens = _farmDeposit(_stablecoin, _amount, _minLPAmount);
        users[_msgSender()].lpBalance += lpTokens;
        totalActiveDeposits += lpTokens;
        return lpTokens;
    }

    /// @param _stablecoin Desired stablecoin to withdraw
    /// @param _lpTokens Amount of LP tokens to remove from pool in the _stablecoin
    /// @param _minAmount Minimum amount of _stablecoin to receive
    /// @return received Amount of _stablecoin received from withdrawing _lpTokens
    function _withdraw(address _stablecoin, uint _lpTokens, uint _minAmount) internal virtual returns (uint received) {
        require(_lpTokens <= users[_msgSender()].lpBalance, "StablzLPIntegration: Amount exceeds your LP balance");
        _mergeRewards();

        users[_msgSender()].lpBalance -= _lpTokens;
        totalActiveDeposits -= _lpTokens;

        received = _farmWithdrawal(_stablecoin, _lpTokens, _minAmount);
        IERC20(_stablecoin).safeTransfer(_msgSender(), received);
        return received;
    }

    /// @param _minAmounts Minimum amounts for harvesting, data is specific to integration
    function _harvest(uint[10] memory _minAmounts) internal virtual {
        uint total = _farmHarvest(_minAmounts);
        uint fee = IStablzFeeHandler(feeHandler).calculateFee(total);
        uint rewards = total - fee;
        _distribute(rewards);
        totalUnhandledFee += fee;
        emit Harvest(total, rewards, fee);
    }

    /// @param _rewards Amount of rewards to distribute
    function _distribute(uint _rewards) internal virtual {
        require(totalActiveDeposits > 0, "StablzLPIntegration: No active deposits");
        currentRewardFactor += rewardFactorAccuracy * _rewards / totalActiveDeposits;
        emit RewardDistribution(_rewards, totalActiveDeposits);
    }

    /// @dev Perform an emergency withdrawal
    function _emergencyShutdown(uint[10] memory _minAmounts) internal virtual {
        _farmEmergencyWithdrawal(totalActiveDeposits, _minAmounts);
    }

    /// @dev Convert amount of stablecoins to 18 decimals
    /// @param _stablecoin Stablecoin address
    /// @param _amount Amount of _stablecoin
    /// @return uint Normalized amount
    function _normalize(address _stablecoin, uint _amount) internal view returns (uint) {
        uint8 decimals = IERC20Metadata(_stablecoin).decimals();
        if (decimals > 18) {
            return _amount / 10 ** (decimals - 18);
        } else if (decimals < 18) {
            return _amount * 10 ** (18 - decimals);
        }
        return _amount;
    }

    function _farmDeposit(address _stablecoin, uint _amount, uint _minLPAmount) internal virtual returns (uint lpTokens);

    function _farmWithdrawal(address _stablecoin, uint _lpTokens, uint _minAmount) internal virtual returns (uint received);

    function _farmEmergencyWithdrawal(uint _lpTokens, uint[10] memory _minAmounts) internal virtual;

    function _farmHarvest(uint[10] memory _minAmounts) internal virtual returns (uint rewards);

    function _withdrawAfterShutdown() internal virtual;

    function _claimRewards(address _stablecoin, uint _minAmount) internal virtual returns (uint rewards);

    function _handleFee(uint _minAmount) internal virtual;
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurveSwap {

    function exchange_multiple(
        address[9] memory _route,
        uint[3][4] memory _swap_params,
        uint _amount,
        uint _expected
    ) external returns (uint);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint[3][4] memory _swap_params,
        uint _amount
    ) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVMinter {
    function mint(address gauge_addr) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVPool {

    function coins(uint index) external view returns (address);

    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);

    function exchange(int128 _i, int128 _j, uint _dx, uint _min_dy) external returns (uint);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);

    function remove_liquidity_one_coin(uint _token_amount, int128 _i, uint _min_amount) external returns (uint);
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVBasePool {
    function coins(uint index) external view returns (address);

    function exchange(int128 _i, int128 _j, uint _dx, uint _min_dy) external returns (uint);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);

    function remove_liquidity(uint _amount, uint[3] memory _min_amounts) external;

    function remove_liquidity_one_coin(uint _token_amount, int128 _i, uint _min_amount) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVGauge {

    function deposit(uint _value) external;

    function withdraw(uint _value) external;

    function claim_rewards() external;

    function balanceOf(address _address) external view returns (uint);

    function claimed_reward(address _address, address _reward_token) external view returns (uint);

    function claimable_reward(address _address, address _reward_token) external view returns (uint);

    function claimable_tokens(address _address) external returns (uint);

    function deposit_reward_token(address _reward_token, uint _amount) external;

}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVDepositZap {

    function add_liquidity(address _pool, uint[4] memory _deposit_amounts, uint _min_mint_amount) external returns (uint);

    function remove_liquidity_one_coin(address _pool, uint _burn_amount, int128 _i, uint _min_amount) external returns (uint);

    function remove_liquidity_imbalance(address _pool, uint[4] memory _amounts, uint _max_burn_amount) external;

    function calc_withdraw_one_coin(address _pool, uint _token_amount, int128 i) external view returns (uint);

    function calc_token_amount(address _pool, uint[4] memory _amounts, bool _is_deposit) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface IStablzFeeHandler {

    function usdt() external view returns (address);

    function treasury() external view returns (address);

    function calculateFee(uint _amount) external view returns (uint);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OracleManaged
contract OracleManaged is Ownable {

    address private _oracle;

    event OracleUpdated(address indexed prev, address indexed next);

    modifier onlyOracle {
        require(_msgSender() == _oracle, "OracleManaged: caller is not the Oracle");
        _;
    }

    modifier onlyOwnerOrOracle() {
        require(_msgSender() == owner() || _msgSender() == _oracle, "OracleManaged: Only the owner or oracle can call this function");
        _;
    }

    /// @notice Get Oracle address
    /// @return address Oracle address
    function oracle() public view returns (address) {
        return _oracle;
    }

    /// @notice Set Oracle address
    /// @param _newOracle New Oracle address
    function setOracle(address _newOracle) external onlyOwner {
        _setOracle(_newOracle);
    }

    /// @dev Set Oracle address and emit event with previous and new address
    /// @param _newOracle New Oracle address
    function _setOracle(address _newOracle) internal {
        require(_newOracle != address(0), "OracleManaged: _newOracle cannot be the zero address");
        address prev = _oracle;
        _oracle = _newOracle;
        emit OracleUpdated(prev, _newOracle);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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