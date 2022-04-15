// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/curve/tricrypto/ITricryptoStrategyConfig.sol";
import "../../interfaces/curve/tricrypto/ITricryptoStrategy.sol";
import "../../interfaces/IBridgeManager.sol";

import "../../libraries/FeeOperations.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

//TODO:
// - tests

/// @notice User should be able to enter with either Tricrypto LP or any of the assets underlying
contract CurveTricryptoStrategy is
    ITricryptoStrategy,
    Ownable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice the config's contract address
    ITricryptoStrategyConfig public override tricryptoConfig;

    /// @notice pause state for withdrawal
    bool public override isWithdrawalPaused;

    /// @notice last emergency save initalization timestamp
    uint256 public override emergencyTimestamp;

    /// @notice emergency save time window
    uint256 public emergencyWindow = 2 days;

    /// @notice struct related to user's past actions in the strategy
    struct UserHistory {
        mapping(address => uint256) claimedRewards;
        uint256 lastWithdrawTimestamp;
    }

    /// @notice mapping containg user's info
    mapping(address => UserInfo) public userInfo;

    /// @notice mapping containg user's past information
    mapping(address => UserHistory) public userHistory;

    /// @notice total amount of LPs the strategy has
    uint256 public override totalAmountOfLPs;

    /// @notice start time considered for calculating rewards
    uint256 public rewardsStartime;

    /// @notice Constructor
    /// @param _config the config's contract address
    constructor(address _config) {
        require(_config != address(0), "ERR: INVALID CONFIG");
        tricryptoConfig = ITricryptoStrategyConfig(_config);
        isWithdrawalPaused = false;
    }

    //-----------------
    //----------------- Owner methods -----------------
    //-----------------
    /// @notice Pause withdraw operations
    function pauseWithdrawal() external onlyOwner {
        isWithdrawalPaused = true;
        emit WithdrawalPaused(msg.sender);
    }

    /// @notice Resume withdraw operations
    function resumeWithdrawal() external onlyOwner {
        isWithdrawalPaused = false;
        emit WithdrawalResumed(msg.sender);
    }

    /// @notice Initialize emergency save
    function initEmergency() external onlyOwner {
        emergencyTimestamp = block.timestamp;
        emit EmergencySaveTriggered(msg.sender);
    }

    /// @notice Save funds from the contract
    /// @param _token Tokens's address
    /// @param _amount Tokens's amount
    function emergencySave(address _token, uint256 _amount) external onlyOwner {
        require(emergencyTimestamp > 0, "ERR: NOT INITIALIZED");
        require(
            emergencyTimestamp + emergencyWindow < block.timestamp,
            "ERR: NOT AUTHORIZED"
        );
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(_amount <= balance, "ERR: EXCEEDS BALANCE");
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit EmergencySaveTriggered(msg.sender);
        emergencyTimestamp = 0;
    }

    //-----------------
    //----------------- View methods -----------------
    //-----------------
    /// @notice Return current user information
    /// @param _user User's address
    /// @return UserInfo struct
    function getUserInfo(address _user)
        external
        view
        override
        returns (UserInfo memory)
    {
        return userInfo[_user];
    }

    /// @notice Return current reward amount for user
    /// @param _user User's address
    /// @return Reward amount
    function getPendingRewards(address _user)
        public
        view
        override
        returns (uint256)
    {
        return
            userInfo[_user].accruedCrvRewards +
            _calculateRewardsForUser(
                userInfo[_user].lastDepositTimestamp,
                userInfo[_user].lastLPAmount,
                totalAmountOfLPs
            );
    }

    /// @notice Return current rewards for user (others than the main one)
    /// @param tokens Tokens to check
    /// @param _user User's address
    /// @return Reward amounts
    function tokenRewards(address[] memory tokens, address _user)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](tokens.length);
        uint256 crvRatio = _getCrvRatioForUser(_user);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                tricryptoConfig.whitelistedRewardTokens(tokens[i]),
                "ERR: NOT A REWARD"
            );

            uint256 tokenAmount = IERC20(tokens[i]).balanceOf(address(this));
            if (tokenAmount == 0) {
                result[i] = 0;
            } else {
                uint256 decimals = IERC20Metadata(tokens[i]).decimals();

                uint256 tokenShares = 0;
                if (decimals < 18) {
                    tokenShares =
                        (tokenAmount * (10**(18 - decimals)) * crvRatio) /
                        (10**(18 - decimals));
                } else {
                    tokenShares = tokenAmount * crvRatio;
                }
                result[i] = tokenShares;
            }
        }
        return result;
    }

    //-----------------
    //----------------- Non-view methods -----------------
    //-----------------
    /// @notice Deposit asset into the strategy
    /// @param _asset Deposited asset
    /// @param _amount Amount
    /// @param _minLpAmount In case asset is not LP, minimum amount of LPs to receive
    /// @return Staked LP amount
    function deposit(
        address _asset,
        uint256 _amount,
        uint256 _minLpAmount
    )
        external
        override
        nonReentrant
        validAmount(_amount)
        validAddress(_asset)
        returns (uint256)
    {
        require(
            tricryptoConfig.underlyingAssets(_asset) ||
                tricryptoConfig.tricryptoToken() == _asset,
            "ERR: TOKEN NOT ACCEPTED"
        );
        if (_asset != tricryptoConfig.tricryptoToken()) {
            require(_minLpAmount > 0, "ERR: INVALID LP AMOUNT");
        }

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        address lpAddress = tricryptoConfig.tricryptoToken();

        //get LPs
        uint256 lpAmount = _getLPAmount(
            lpAddress,
            _asset,
            _amount,
            _minLpAmount
        );

        //stake LPs into the gauge
        if (rewardsStartime == 0) {
            rewardsStartime = block.timestamp;
        }
        _safeApprove(
            lpAddress,
            address(tricryptoConfig.tricryptoGauge()),
            lpAmount
        );
        tricryptoConfig.tricryptoGauge().deposit(lpAmount, address(this), true);

        //fill user & general info
        uint256 newRewards = _calculateRewardsForUser(
            userInfo[msg.sender].lastDepositTimestamp,
            lpAmount,
            totalAmountOfLPs
        );
        _fillUserInfo(msg.sender, lpAmount, newRewards, false);

        // if (!_isSenderKeeperOrOwner(msg.sender)) {
        totalAmountOfLPs = totalAmountOfLPs + lpAmount;
        // }

        emit Deposit(msg.sender, _asset, _amount, lpAmount);
        return lpAmount;
    }

    /// @notice Withdraw LP from the strategy
    /// @param _amount LP Amount for withdrawal
    /// @param _asset Asset user wants to receive
    /// @param params _assetMinAmount In case asset is not LP, minimum amount of the asset to receive; _claimOtherRewards In case asset is not LP, minimum amount of the asset to receive
    /// @return The amount of CRV tokens obtained
    function withdraw(
        uint256 _amount,
        address _asset,
        ITricryptoStrategy.WithdrawParamData memory params
    )
        external
        override
        nonReentrant
        validAmount(_amount)
        validAddress(_asset)
        returns (uint256)
    {
        address lpAddress = tricryptoConfig.tricryptoToken();
        if (!_isSenderKeeperOrOwner(msg.sender)) {
            require(!isWithdrawalPaused, "ERR: WITHDRAWAL PAUSED");
            require(
                tricryptoConfig.underlyingAssets(_asset) || lpAddress == _asset,
                "ERR: TOKEN NOT ACCEPTED"
            );
            require(
                _amount <= userInfo[msg.sender].lastLPAmount,
                "ERR: EXCEEDS RANGE"
            );
        }
        //unstake from the gauge
        uint256 lpAmount = _unstake(_amount, lpAddress);

        //transfer asset to user
        uint256 assetAmount = 0;
        if (_asset == lpAddress) {
            assetAmount = lpAmount;
            IERC20(lpAddress).safeTransfer(msg.sender, assetAmount);
        } else {
            //unwrap if necessary
            assetAmount = _unwrapLPsIntoAsset(
                _asset,
                params._assetMinAmount,
                _amount,
                _getTokenIndex(_asset)
            );
            IERC20(_asset).safeTransfer(msg.sender, assetAmount);
        }

        //We have to claim the CRV rewards first
        tricryptoConfig.minter().mint(
            address(tricryptoConfig.tricryptoGauge())
        );
        //compute rewards & user info
        uint256 newRewards = _calculateRewardsForUser(
            userInfo[msg.sender].lastDepositTimestamp,
            lpAmount,
            totalAmountOfLPs
        );
        _fillUserInfo(msg.sender, lpAmount, newRewards, true);
        // if (!_isSenderKeeperOrOwner(msg.sender)) {
        totalAmountOfLPs = totalAmountOfLPs - lpAmount;
        // }

        //transfer CRV rewards
        uint256 crvRewardsAmount = _transferCRVRewards(msg.sender);

        if (params._claimOtherRewards) {
            _claimOtherTokens(msg.sender);
        }

        emit Withdraw(
            msg.sender,
            _asset,
            lpAmount,
            assetAmount,
            crvRewardsAmount,
            params._claimOtherRewards
        );

        return crvRewardsAmount;
    }

    /// @notice Claim rewards other than crvToken
    function claimOtherRewards() external override nonReentrant {
        _claimOtherTokens(msg.sender);
    }

    /// @notice Claims rewards to this contract
    function updateRewards() external override nonReentrant {
        tricryptoConfig.tricryptoGauge().claim_rewards(
            address(this),
            address(this)
        );
    }

    /// @notice Stake transferred LPs into the gauge
    /// @param _lpAmount Amount of tricrypto LP token
    function stakeIntoGauge(uint256 _lpAmount)
        external
        override
        onlyOwnerOrKeeper
        nonReentrant
    {
        require(_lpAmount > 0, "ERR: INVALID AMOUNT");
        _safeApprove(
            tricryptoConfig.tricryptoToken(),
            address(tricryptoConfig.tricryptoGauge()),
            _lpAmount
        );
        tricryptoConfig.tricryptoGauge().deposit(
            _lpAmount,
            address(this),
            true
        );
    }

    /// @notice Transfer LPs or WETH to another layer
    /// @param bridgeId The bridge id to be used for this operation
    /// @param unwrap If 'true', the LP is unwrapped into WETH
    /// @param wethMinAmount When 'unwrap' is true, this should be represent the minimum amount of WETH to be received
    /// @return An unique id
    function transferLPs(
        uint256 bridgeId,
        uint256 _destinationNetworkId,
        bool unwrap,
        uint256 wethMinAmount,
        uint256 lpAmountToTransfer,
        bytes calldata _data
    ) external override onlyOwnerOrKeeper nonReentrant returns (uint256) {
        require(bridgeId > 0, "ERR: INVALID BRIDGE");
        require(lpAmountToTransfer > 0, "ERR: INVALID AMOUNT");
        isWithdrawalPaused = true;
        address transferredToken = tricryptoConfig.tricryptoToken();
        uint256 balance = tricryptoConfig.tricryptoGauge().balanceOf(
            address(this)
        );

        require(lpAmountToTransfer <= balance, "ERR: EXCEEDS RANGE");
        tricryptoConfig.tricryptoGauge().withdraw(lpAmountToTransfer, true);
        if (unwrap) {
            //unwrap LP into weth
            transferredToken = tricryptoConfig.tricryptoLPVault().coins(2);

            require(
                transferredToken == tricryptoConfig.wethToken(),
                "ERR: NOT WETH"
            );

            lpAmountToTransfer = _unwrapLPsIntoAsset(
                transferredToken,
                wethMinAmount,
                lpAmountToTransfer,
                2
            );
            require(lpAmountToTransfer > 0, "ERR: INVALID UNWRAPPED AMOUNT");
        }

        require(
            tricryptoConfig.underlyingAssets(transferredToken) ||
                tricryptoConfig.tricryptoToken() == transferredToken,
            "ERR: TOKEN NOT ACCEPTED"
        );

        // transfer the tokens to another layer
        address bridgeManager = tricryptoConfig.bridgeManager();
        FeeOperations.safeApprove(
            transferredToken,
            bridgeManager,
            lpAmountToTransfer
        );
        IBridgeManager(bridgeManager).transferERC20(
            bridgeId,
            _destinationNetworkId,
            transferredToken,
            lpAmountToTransfer,
            tricryptoConfig.keeper(), // the keeper will deposit the funds on the destination layer
            _data
        );
        return lpAmountToTransfer;
    }

    /// @notice Receive LPs or WETH that come back from another Layer, basically deposit but with the transferral of all accumulated CRV tokens in the owner/keeper account (NEED Owner/Keeper to approve the CRV spending by this contract)
    /// @param _asset Deposited asset
    /// @param _amount Amount
    /// @param _minLpAmount In case asset is not LP, minimum amount of LPs to receive
    /// @return Staked LP amount
    function receiveBackLPs(
        address _asset,
        uint256 _amount,
        uint256 _minLpAmount
    )
        external
        override
        onlyOwnerOrKeeper
        nonReentrant
        validAmount(_amount)
        validAddress(_asset)
        returns (uint256)
    {
        require(
            tricryptoConfig.underlyingAssets(_asset) ||
                tricryptoConfig.tricryptoToken() == _asset,
            "ERR: TOKEN NOT ACCEPTED"
        );
        if (_asset != tricryptoConfig.tricryptoToken()) {
            require(_minLpAmount > 0, "ERR: INVALID LP AMOUNT");
        }

        uint256 balanceCRVOwner = IERC20(tricryptoConfig.crvToken()).balanceOf(
            msg.sender
        );
        IERC20(tricryptoConfig.crvToken()).safeTransferFrom(
            msg.sender,
            address(this),
            balanceCRVOwner
        );

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        address lpAddress = tricryptoConfig.tricryptoToken();

        //get LPs
        uint256 lpAmount = _getLPAmount(
            lpAddress,
            _asset,
            _amount,
            _minLpAmount
        );

        //stake LPs into the gauge
        if (rewardsStartime == 0) {
            rewardsStartime = block.timestamp;
        }
        _safeApprove(
            lpAddress,
            address(tricryptoConfig.tricryptoGauge()),
            lpAmount
        );
        tricryptoConfig.tricryptoGauge().deposit(lpAmount, address(this), true);

        emit Deposit(msg.sender, _asset, _amount, lpAmount);
        return lpAmount;
    }

    //-----------------
    //----------------- Private methods -----------------
    //-----------------
    /// @notice Extracts fee from amount & transfers it to the feeAddress
    /// @param _amount Amount from which the fee is subtracted from
    /// @param _asset Asset that's going to be transferred
    function _takeFee(uint256 _amount, address _asset)
        private
        returns (uint256)
    {
        uint256 feePart = FeeOperations.getFeeAbsolute(
            _amount,
            tricryptoConfig.currentFee()
        );
        if (feePart > 0) {
            IERC20(_asset).safeTransfer(tricryptoConfig.feeAddress(), feePart);
        }
        return feePart;
    }

    /// @notice Get CRV ratio for a user
    /// @param _user User address
    /// @return Ratio
    function _getCrvRatioForUser(address _user) private view returns (uint256) {
        uint256 crvTokenRewards = getPendingRewards(_user);
        uint256 crvBalance = IERC20(tricryptoConfig.crvToken()).balanceOf(
            address(this)
        );
        return FeeOperations.getRatio(crvTokenRewards, crvBalance, 18);
    }

    /// @notice Unstake from LP Gauge
    /// @param _amount Amount to unstake
    /// @param lpAddress LP token address
    /// @return Received LP tokens
    function _unstake(uint256 _amount, address lpAddress)
        private
        returns (uint256)
    {
        uint256 balanceOfLPsBefore = IERC20(lpAddress).balanceOf(address(this));
        _safeApprove(
            lpAddress,
            address(tricryptoConfig.tricryptoGauge()),
            _amount
        );
        tricryptoConfig.tricryptoGauge().withdraw(_amount, true);
        uint256 balanceOfLPsAfter = IERC20(lpAddress).balanceOf(address(this));
        require(balanceOfLPsAfter > balanceOfLPsBefore, "ERR: UNSTAKE FAILED");
        return balanceOfLPsAfter - balanceOfLPsBefore;
    }

    /// @notice Transfers CRV rewards to user
    /// @param _user Receiver address
    /// @return (total CRV available, total CRV user is entitled to)
    function _transferCRVRewards(address _user) private returns (uint256) {
        address crvToken = tricryptoConfig.crvToken();
        uint256 crvRewardsAmount = userInfo[_user].accruedCrvRewards -
            userHistory[_user].claimedRewards[crvToken];
        uint256 totalCrvAmount = IERC20(crvToken).balanceOf(address(this));
        require(
            crvRewardsAmount <= totalCrvAmount,
            "ERR: CRV REWARDS EXCEED BALANCE"
        );
        if (msg.sender != tricryptoConfig.feeAddress()) {
            uint256 fee = _takeFee(crvRewardsAmount, crvToken);
            crvRewardsAmount = crvRewardsAmount - fee;
            emit FeeTaken(_user, crvToken, fee);
        }
        IERC20(crvToken).safeTransfer(_user, crvRewardsAmount);
        userHistory[_user].claimedRewards[crvToken] = userInfo[_user]
            .accruedCrvRewards;
        userHistory[_user].lastWithdrawTimestamp = block.timestamp;
        emit CRVRewardClaimed(_user, crvRewardsAmount);
        return crvRewardsAmount;
    }

    /// @notice Used to claim rewards other than the crvToken
    /// @dev Same crvRatio will be applied to extra rewards
    /// @param _user User receiving them
    function _claimOtherTokens(address _user) private {
        address[] memory rewardsArr = tricryptoConfig.getRewardTokensArray();
        uint256[] memory shares = tokenRewards(rewardsArr, _user);

        for (uint256 i = 0; i < rewardsArr.length; i++) {
            if (shares[i] > 0) {
                IERC20(rewardsArr[i]).safeTransfer(_user, shares[i]);
                emit ExtraRewardClaimed(_user, rewardsArr[i], shares[i]);
            }
        }
    }

    /// @notice Calculate rewards for a specific time interval
    /// @param _lastDepositTimestamp Start time to start computing rewards for
    /// @param _lastLPAmount Last deposit amount for user
    /// @param _totalLPAmount Total deposited LPs
    /// @return Reward amount
    function _calculateRewardsForUser(
        uint256 _lastDepositTimestamp,
        uint256 _lastLPAmount,
        uint256 _totalLPAmount
    ) private view returns (uint256) {
        if (
            _lastLPAmount == 0 ||
            _totalLPAmount == 0 ||
            rewardsStartime == block.timestamp
        ) {
            return 0;
        }
        uint256 timeInVault = block.timestamp - _lastDepositTimestamp;
        uint256 shareInVault = FeeOperations.getRatio(
            _lastLPAmount,
            _totalLPAmount,
            18
        );
        uint256 rewardsAmount = IERC20(tricryptoConfig.crvToken()).balanceOf(
            address(this)
        );
        uint256 rewardPerBlock = rewardsAmount /
            (block.timestamp - rewardsStartime);
        uint256 userRewards = rewardPerBlock * timeInVault * shareInVault;
        // Add to divide by 18 to get the correct amount of rewards but maybe it should be done elsewhere
        return userRewards / 10**18;
    }

    /// @notice Fill user info with latest details
    /// @param _user User address
    /// @param _lpAmount New LP amount
    /// @param _newRewards New rewrds
    function _fillUserInfo(
        address _user,
        uint256 _lpAmount,
        uint256 _newRewards,
        bool isWithdrawal
    ) private {
        // if (!_isSenderKeeperOrOwner(msg.sender)) {
        UserInfo storage info = userInfo[_user];
        if (isWithdrawal) {
            info.lastLPAmount = info.lastLPAmount - _lpAmount;
        } else {
            info.lastLPAmount = info.lastLPAmount + _lpAmount;
            info.lastDepositTimestamp = block.timestamp;
        }
        info.accruedCrvRewards = info.accruedCrvRewards + _newRewards;
        // }
    }

    /// @notice Depending on asset address, either use it directly or add liquidity to get the LP token
    /// @param _lpAddress Address of the LP token
    /// @param _asset Asset address
    /// @param _amount Asset amount
    /// @param _minLpAmount Minimum LP amount to receive in case of an add liquidity event
    /// @return Amount of LPs
    function _getLPAmount(
        address _lpAddress,
        address _asset,
        uint256 _amount,
        uint256 _minLpAmount
    ) private returns (uint256) {
        uint256 lpAmount = 0;
        if (_asset == _lpAddress) {
            lpAmount = _amount;
        } else {
            uint256[] memory amountsArr = _createLiquidityArray(
                _asset,
                _amount
            );
            uint256[3] memory liquidityArr;
            for (uint256 i = 0; i < amountsArr.length; i++) {
                liquidityArr[i] = amountsArr[i];
            }

            uint256 balanceOfLPsBefore = IERC20(_lpAddress).balanceOf(
                address(this)
            );
            _safeApprove(
                _asset,
                address(tricryptoConfig.tricryptoLPVault()),
                _amount
            );
            tricryptoConfig.tricryptoLPVault().add_liquidity(
                liquidityArr,
                _minLpAmount,
                address(this)
            );
            uint256 balanceOfLPsAfter = IERC20(_lpAddress).balanceOf(
                address(this)
            );

            lpAmount = balanceOfLPsAfter - balanceOfLPsBefore;
            require(lpAmount > 0, "ERR: LIQUIDITY ADD FAILED");
        }

        return lpAmount;
    }

    /// @notice Unwrap LPs using remove_liquidity_one_coin into an underlying asset
    /// @param _asset Asset address
    /// @param _assetMinAmount The minimum amount of asset to receive
    /// @param _lpAmount The LP amount to unwrap
    /// @param _index Asset index from the underlying asset array
    /// @return The amount of asset obtained
    function _unwrapLPsIntoAsset(
        address _asset,
        uint256 _assetMinAmount,
        uint256 _lpAmount,
        uint256 _index
    ) private returns (uint256) {
        require(_assetMinAmount > 0, "ERR: MIN TOO LOW");
        require(_lpAmount > 0, "ERR: INVALID LP AMOUNT");

        uint256 assetBalanceBefore = IERC20(_asset).balanceOf(address(this));
        _safeApprove(
            tricryptoConfig.tricryptoToken(),
            address(tricryptoConfig.tricryptoLPVault()),
            _lpAmount
        );
        tricryptoConfig.tricryptoSwap().remove_liquidity_one_coin(
            _lpAmount,
            _index,
            _assetMinAmount
        );
        uint256 assetBalanceAfter = IERC20(_asset).balanceOf(address(this));
        require(
            assetBalanceAfter > assetBalanceBefore,
            "ERR: REMOVE LIQUIDITY FAILED"
        );

        return assetBalanceAfter - assetBalanceBefore;
    }

    /// @notice Create amounts array for an add_liquidity call
    /// @param _asset Asset to add as liquidity
    /// @param _amount Amount of asset
    /// @return The amounts array
    function _createLiquidityArray(address _asset, uint256 _amount)
        private
        view
        returns (uint256[] memory)
    {
        uint256 index = _getTokenIndex(_asset);
        uint256 noOfAssets = tricryptoConfig.underlyingAssetsNo();
        uint256[] memory amountsArr = new uint256[](3);
        for (uint256 i = 0; i < noOfAssets; i++) {
            if (i == index) {
                amountsArr[i] = _amount;
            } else {
                amountsArr[i] = 0;
            }
        }
        return amountsArr;
    }

    /// @notice Get index of a token from the LP pool
    /// @param _asset Asset to add as liquidity
    /// @return The index
    function _getTokenIndex(address _asset) private view returns (uint256) {
        uint256 returnIndex = 99;
        for (uint256 i = 0; i < tricryptoConfig.underlyingAssetsNo(); i++) {
            address underlyingAddr = tricryptoConfig.tricryptoLPVault().coins(
                i
            );
            if (underlyingAddr == _asset) {
                returnIndex = i;
            }
        }
        require(returnIndex < 99, "ERR: INVALID INDEX");
        return returnIndex;
    }

    /// @notice Save approve token for spending on contract
    /// @param token Token's address
    /// @param to Contract's address
    /// @param value Amount
    function _safeApprove(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERR::safeApprove: approve failed"
        );
    }

    function _isSenderKeeperOrOwner(address _user) private view returns (bool) {
        return _user == owner() || _user == tricryptoConfig.keeper();
    }

    //-----------------
    //----------------- Modifiers -----------------
    //-----------------
    modifier onlyOwnerOrKeeper() {
        require(
            msg.sender == owner() || msg.sender == tricryptoConfig.keeper(),
            "ERR: NOT AUTHORIZED"
        );
        _;
    }
    modifier onlyWhitelistedUnderlying(address token) {
        require(
            tricryptoConfig.underlyingAssets(token),
            "ERR: NOT WHITELISTED"
        );
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "ERR: INVALID AMOUNT");
        _;
    }
    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITricryptoLPVault.sol";
import "./ITricryptoLPGauge.sol";
import "./ITricryptoSwap.sol";
import "./IMinter.sol";

/// @title Interface for Curve Tricrypto strategy config
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoStrategyConfig {
    event CurrentFeeChanged(uint256 newMinFee);
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event FeeAddressSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event TricryptoTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event CrvTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event LPVaultSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event SwapVaultSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event GaugeSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event MinterSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event KeeperSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event BridgeManagerSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event RewardTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event UnderlyingWhitelistStatusChange(
        address indexed underlying,
        address indexed owner,
        bool whitelisted
    );
    event RewardTokenStatusChange(
        address indexed owner,
        address indexed token,
        bool whitelisted
    );
    event UnderlyingAssetNoChange(
        address indexed owner,
        uint256 newNo,
        uint256 previousNo
    );

    event WethTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    function wethToken() external view returns (address);

    function crvToken() external view returns (address);

    function tricryptoToken() external view returns (address);

    function tricryptoLPVault() external view returns (ITricryptoLPVault);

    function tricryptoSwap() external view returns (ITricryptoSwap);

    function tricryptoGauge() external view returns (ITricryptoLPGauge);

    function minter() external view returns (IMinter);

    function keeper() external view returns (address);

    function bridgeManager() external view returns (address);

    function underlyingAssets(address asset) external view returns (bool);

    function whitelistedRewardTokens(address asset)
        external
        view
        returns (bool);

    function getRewardTokensArray() external view returns (address[] memory);

    function feeAddress() external view returns (address);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function currentFee() external view returns (uint256);

    function underlyingAssetsNo() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITricryptoStrategyConfig.sol";

/// @title Interface for Curve Tricrypto strategy
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoStrategy {
    event Deposit(
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 lpAmount
    );
    event Withdraw(
        address indexed user,
        address indexed asset,
        uint256 lpAmount,
        uint256 assetAmount,
        uint256 crvRewards,
        bool claimOtherTokens
    );
    event ExtraRewardClaimed(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event CRVRewardClaimed(address indexed user, uint256 amount);
    event WithdrawalPaused(address indexed owner);
    event WithdrawalResumed(address indexed owner);
    event EmergencySaveTriggered(address indexed owner);
    event EmergencySaveInitialized(address indexed owner);
    event FeeTaken(address indexed user, address indexed asset, uint256 amount);

    struct WithdrawParamData {
        uint256 _assetMinAmount;
        bool _claimOtherRewards;
    }

    /// @notice struct containing user information
    struct UserInfo {
        uint256 lastDepositTimestamp;
        uint256 lastLPAmount;
        uint256 accruedCrvRewards;
    }

    function tricryptoConfig() external view returns (ITricryptoStrategyConfig);

    function totalAmountOfLPs() external view returns (uint256);

    function isWithdrawalPaused() external view returns (bool);

    function emergencyTimestamp() external view returns (uint256);

    function getPendingRewards(address _user) external view returns (uint256);

    function tokenRewards(address[] memory tokens, address _user)
        external
        view
        returns (uint256[] memory);

    function getUserInfo(address _user) external view returns (UserInfo memory);

    function deposit(
        address _asset,
        uint256 _amount,
        uint256 _minLpAmount
    ) external returns (uint256);

    function withdraw(
        uint256 _amount,
        address _asset,
        ITricryptoStrategy.WithdrawParamData memory params
    ) external returns (uint256);

    function claimOtherRewards() external;

    function updateRewards() external;

    function transferLPs(
        uint256 bridgeId,
        uint256 _destinationNetworkId,
        bool unwrap,
        uint256 wethMinAmount,
        uint256 lpAmountToTransfer,
        bytes calldata _data
    ) external returns (uint256);

    function receiveBackLPs(
        address _asset,
        uint256 _amount,
        uint256 _minLpAmount
    ) external returns (uint256);

    function stakeIntoGauge(uint256 _lpAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeManager {
    
    function transferERC20(
        uint256 _bridgeId,
        uint256 _destinationNetworkId,
        address _tokenIn,
        uint256 _amount,
        address _destinationAddress,
        bytes calldata _data
    ) external;
    
    function getBridgeAddress(uint256 _bridgeId) external returns (address);
    
    function isNetworkSupported(uint256 _bridgeId, uint256 _networkId) external returns (bool);
    
}

// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @author: Pepe Blasco
 */
pragma solidity ^0.8.0;

library FeeOperations {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice Save approve token for spending on contract
    /// @param token Token's address
    /// @param to Contract's address
    /// @param value Amount
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERR::safeApprove: approve failed"
        );
    }

    /// @notice Safe transfer ETH to address
    /// @param to Contract's address
    /// @param value Contract's address
    /// @param value Amount
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ERR::safeTransferETH: ETH transfer failed");
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
pragma solidity ^0.8.0;

/// @title Interface for Curve Tricrypto swaps & liquidity
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoLPVault {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        address _receiver
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata min_amounts,
        address _receiver
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external;

    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Tricrypto LP staking gauge
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoLPGauge {
    function crv_token() external view returns (address);

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 value, bool _claim_rewards) external;

    function claim_rewards(address _addr, address _receiver) external;

    function balanceOf(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Tricrypto remove liquidity operation
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Minter
interface IMinter {
    function mint(address _gauge_addr) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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