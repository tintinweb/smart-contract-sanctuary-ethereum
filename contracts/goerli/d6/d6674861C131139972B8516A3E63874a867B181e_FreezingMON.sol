// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./dependencies/DfrancMath.sol";
import "./dependencies/Initializable.sol";
import "./dependencies/CheckContract.sol";

import "./interfaces/IMONStaking.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IERC20Metadata.sol";

/*
This contract is reserved for MON airdrop users that choose freezing and staking.
The mapping snapshots stores the user snapshots of F_ASSETS and F_DCHF in the form of key-value pair (address -> struct Snapshot)
The mapping F_ASSETS stores the asset fees in the form of key-value pair (address -> uint256).
The mapping entitiesVesting stores the user's vesting data in the form of key-value pair (address -> struct Rule).
The mapping stakes stores the user's stake in the form of key-value pair (address -> uint256).
Unvesting of MON starts in 2000 days and has 180 days of duration. Until that moment, user's MON is staked in the stakingPool. 
The freezingContract has the ability to remove the user from Vesting to Freeze & Stake. Any amount already claimed by the user 
during the Vesting will be deducted from the totalAmount the user is eligible.
*/

contract FreezingMON is Pausable, Ownable, CheckContract, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    bool public isInitialized;

    // --- Data --- //

    string public constant NAME = "FreezingContract";

    address public immutable ETH_REF_ADDRESS = address(0);
    address public immutable WBTC_ADDRESS = 0xE76AfA0301B9eaAeC6636AB873AB358D21B52D61; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public stakingPool = 0x92C7ecb907446Fd37E7be65436b55bF8c24ed6A3; // 0x8Bc3702c35D33E5DF7cb0F06cb72a0c34Ae0C56F;
    address public oracle = 0x5C206ADDb7DC3F9B154966651fe71Ee8E0C4bB9e; // 0x09AB3C0ce6Cb41C13343879A667a6bDAd65ee9DA;
    address public vestingContract;
    address public treasury;

    IERC20 public immutable MON = IERC20(address(0x3092854cdAe1a34c94c0210CCDEfDd07944D3443)); // IERC20(address(0x1EA48B9965bb5086F3b468E50ED93888a661fc17));
    IERC20 public immutable DCHF = IERC20(address(0x7482798d0Cc40be8267ccbE541961AB33A5703aC)); // IERC20(address(0x045da4bFe02B320f4403674B3b7d121737727A36));

    uint256 public constant VEST_TIME = 10 days; // Half a year of Vesting
    uint256 public constant VEST_DELAY = 1 days; // 5,48 years of Freezing
    uint256 internal constant PRECISION = 1 ether; // 1e18

    uint256 public protocolFee; // In bps 1% = 100, 10% = 1000, 100% = 10000

    struct Rule {
        uint256 startVestingDate;
        uint256 totalMON;
        uint256 endVestingDate;
        uint256 claimed;
    }

    mapping(address => Rule) public entitiesVesting;
    mapping(address => uint256) public stakes;

    uint256 public totalMONStaked; // Used to get fees per-MON-staked

    mapping(address => uint256) public F_ASSETS; // Running sum of Asset fees per-MON-staked
    uint256 public F_DCHF; // Running sum of DCHF fees per-MON-staked

    struct Snapshot {
        mapping(address => uint256) F_ASSET_Snapshot;
        uint256 F_DCHF_Snapshot;
    }

    // User snapshots of F_ASSETS and F_DCHF, taken at the point at which their latest deposit was made
    mapping(address => Snapshot) public snapshots;

    address[] public ASSET_TYPES;
    mapping(address => bool) isAssetTracked;

    error ZeroAddress();
    error ZeroAmount();
    error FailToSendETH();
    error NonZeroStake(uint256 stake);
    error ProtectedToken(address token);
    error AssetExists(address asset);
    error NotStakingPool(address sender);

    event SentToTreasury(address indexed asset, uint256 amount);
    event AssetSent(address indexed asset, address indexed account, uint256 amount);
    event AssetAdded(address asset);
    event F_AssetUpdated(address indexed asset, uint256 F_ASSET);
    event F_DCHFUpdated(uint256 F_DCHF);
    event StakerSnapshotUpdated(address staker, uint256 F_Snapshot);
    event StakeChanged(address indexed staker, uint256 newStake);
    event StakingGainsAssetWithdrawn(address indexed staker, address indexed asset, uint256 assetGain);
    event StakingGainsDCHFWithdrawn(address indexed staker, uint256 DCHFGain);
    event Claim(address indexed user, uint256 amount);
    event Sweep(address indexed token, uint256 amount);
    event SetFees(uint256 fee, uint256 prevFee);

    // --- External Functions --- //

    function setAddresses(address _treasury, address _vestingContract) external initializer onlyOwner {
        require(!isInitialized, "Already Initialized");
        if (_treasury == address(0)) revert ZeroAddress();

        checkContract(_vestingContract);

        isInitialized = true;

        _pause();

        treasury = _treasury;
        vestingContract = _vestingContract;

        isAssetTracked[ETH_REF_ADDRESS] = true;
        ASSET_TYPES.push(ETH_REF_ADDRESS);

        isAssetTracked[WBTC_ADDRESS] = true;
        ASSET_TYPES.push(WBTC_ADDRESS);

        // Approve the stakingPool for spending MON
        MON.approve(stakingPool, 0);
        MON.approve(stakingPool, type(uint256).max);
    }

    function addUserToFreezer() external nonReentrant whenNotPaused {
        uint256 monAmount = IVesting(vestingContract).transferEntity(msg.sender);
        if (monAmount == 0) revert ZeroAmount();

        require(entitiesVesting[msg.sender].startVestingDate == 0, "Existing Vesting Rule");

        stakes[msg.sender] = monAmount;

        entitiesVesting[msg.sender] = Rule({
            startVestingDate: block.timestamp + VEST_DELAY, // vesting period starts 2yrs
            totalMON: monAmount,
            endVestingDate: block.timestamp + VEST_DELAY + VEST_TIME, // vesting period ends in 3yrs
            claimed: 0
        });

        totalMONStaked += monAmount;

        // Save initial contract balances
        uint256 initialBalanceDCHF = balanceOfDCHF();
        uint256[] memory initialAssetBalances = _getInitialAssetBal();

        // With stake we automatically claim the rewards generated
        _stake(monAmount);

        // We update the fees per asset as rewards have been collected
        _updateFeesPerAsset(initialAssetBalances);

        uint256 diffDCHF = balanceOfDCHF() - initialBalanceDCHF;
        if (diffDCHF > 0) {
            _increaseF_DCHF(diffDCHF);
        }

        // We update the snapshots so user starts earning from this moment
        _updateUserSnapshots(msg.sender);

        emit StakeChanged(msg.sender, monAmount);
    }

    function claimRewards() external nonReentrant whenNotPaused {
        _requireUserHasStake(stakes[msg.sender]);

        // Save initial contract balances
        uint256 initialBalanceDCHF = balanceOfDCHF();
        uint256[] memory initialAssetBalances = _getInitialAssetBal();

        // Claim rewards from the MONStaking contract
        _unstake(0);

        // We update the fees per asset as rewards have been collected
        _updateFeesPerAsset(initialAssetBalances);
        uint256 diffDCHF = balanceOfDCHF() - initialBalanceDCHF;
        if (diffDCHF > 0) {
            _increaseF_DCHF(diffDCHF);
        }

        // Update user snapshots to current state and send any accumulated asset & DCHF gains
        _processUserGains(msg.sender);
    }

    /// @notice The rewards fees are not claimed in this function in order to save gas fees
    // Therefore, users need to voluntarily claim rewards prior to claim their unvested Mon
    // Optionally, users can do both options together in the function claimMONAndRewards()
    function claimMON() external nonReentrant whenNotPaused {
        _claimMON();
    }

    /// @notice In this function the user claims the unvested MON and the staking rewards
    function claimMONAndRewards() external nonReentrant whenNotPaused {
        // Save initial contract balances
        uint256 initialBalanceDCHF = balanceOfDCHF();
        uint256[] memory initialAssetBalances = _getInitialAssetBal();

        // Claim the unvested MON, here we already unstake from stakingPool
        _claimMON();

        // Update fees per Asset to reflect the last earnings state
        _updateFeesPerAsset(initialAssetBalances);
        uint256 diffDCHF = balanceOfDCHF() - initialBalanceDCHF;
        if (diffDCHF > 0) {
            _increaseF_DCHF(diffDCHF);
        }

        // Update user snapshots to current state and send any accumulated asset & DCHF gains
        _processUserGains(msg.sender);
    }

    function _claimMON() internal {
        _requireUserHasStake(stakes[msg.sender]);
        require(entitiesVesting[msg.sender].startVestingDate != 0, "Missing Vesting Rule");
        uint256 unclaimedAmount = getClaimableMON(msg.sender);

        if (unclaimedAmount > 0) {
            _unstake(unclaimedAmount);
            _sendMONToEntity(msg.sender, unclaimedAmount);
        }
    }

    function getClaimableMON(address _entity) public view returns (uint256 claimable) {
        Rule memory entityRule = entitiesVesting[_entity];

        if (block.timestamp < entityRule.startVestingDate) return 0;

        if (block.timestamp >= entityRule.endVestingDate) {
            claimable = entityRule.totalMON - entityRule.claimed;
        } else {
            claimable =
                ((entityRule.totalMON * (block.timestamp - entityRule.startVestingDate)) / VEST_TIME) -
                entityRule.claimed;
        }
    }

    function _sendMONToEntity(address _entity, uint256 _unclaimedAmount) private {
        Rule storage entityRule = entitiesVesting[_entity];
        entityRule.claimed += _unclaimedAmount;

        // Update state variables to reflect the reduction of MON
        totalMONStaked -= _unclaimedAmount;
        stakes[msg.sender] -= _unclaimedAmount;

        MON.safeTransfer(_entity, _unclaimedAmount);
        emit Claim(_entity, _unclaimedAmount);
    }

    function addAsset(address _asset) external onlyOwner {
        if (_asset == address(0)) revert ZeroAddress();
        if (isAssetTracked[_asset] == true) revert AssetExists(_asset);
        isAssetTracked[_asset] = true;
        ASSET_TYPES.push(_asset);
        emit AssetAdded(_asset);
    }

    function changeTreasuryAddress(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee >= 0 && _fee < 10000, "Invalid fee value");
        uint256 prevFee = protocolFee;
        protocolFee = _fee;
        emit SetFees(protocolFee, prevFee);
    }

    /// @notice Sweep tokens that are airdropped/transferred into the contract
    function sweep(address _token) external onlyOwner {
        if (_notProtectedTokens(_token) == false) revert ProtectedToken(_token);
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(treasury, amount);
        emit Sweep(_token, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Pending reward functions --- //

    function getPendingAssetGain(address _asset, address _user) public view returns (uint256 _assetGain) {
        _assetGain = _getPendingAssetGain(_asset, _user);
    }

    function getPendingDCHFGain(address _user) public view returns (uint256 _DCHFGain) {
        _DCHFGain = _getPendingDCHFGain(_user);
    }

    function _getPendingAssetGain(address _asset, address _user) internal view returns (uint256 _assetGain) {
        uint256 F_ASSET_Snapshot = snapshots[_user].F_ASSET_Snapshot[_asset];
        _assetGain = (stakes[_user] * (F_ASSETS[_asset] - F_ASSET_Snapshot)) / PRECISION;
    }

    function _getPendingDCHFGain(address _user) internal view returns (uint256 _DCHFGain) {
        uint256 F_DCHF_Snapshot = snapshots[_user].F_DCHF_Snapshot;
        _DCHFGain = (stakes[_user] * (F_DCHF - F_DCHF_Snapshot)) / PRECISION;
    }

    // Returns the current claimable gain in DCHF since last user snapshots were taken
    function getUserPendingGainInDCHF(address _user) public view returns (uint256 _totalDCHFGain) {
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountAsset = _getPendingAssetGain(assets[i], _user);
            uint256 priceAsset = IPriceFeed(oracle).getDirectPrice(assets[i]);
            uint256 amountAssetInDCHF = (amountAsset * priceAsset) / PRECISION;
            amountAssetInDCHF = _decimalsCorrection(assets[i], amountAssetInDCHF);
            _totalDCHFGain += amountAssetInDCHF;
        }
        _totalDCHFGain += _getPendingDCHFGain(_user);
    }

    // --- Internal helper functions --- //

    function _updateUserSnapshots(address _user) internal {
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i = _uncheckedInc(i)) {
            _updateUserAssetSnapshot(_user, assets[i]);
        }
        _updateUserDCHFSnapshot(_user);
    }

    function _updateUserAssetSnapshot(address _user, address _asset) internal {
        snapshots[_user].F_ASSET_Snapshot[_asset] = F_ASSETS[_asset];
        emit StakerSnapshotUpdated(_user, F_ASSETS[_asset]);
    }

    function _updateUserDCHFSnapshot(address _user) internal {
        snapshots[_user].F_DCHF_Snapshot = F_DCHF;
        emit StakerSnapshotUpdated(_user, F_DCHF);
    }

    function _updateFeesPerAsset(uint256[] memory _initBalances) internal {
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i = _uncheckedInc(i)) {
            if (assets[i] == ETH_REF_ADDRESS) {
                uint256 balanceETH = address(this).balance;
                uint256 diffETH = balanceETH - _initBalances[i];
                if (diffETH > 0) {
                    _increaseF_Asset(assets[i], diffETH);
                }
            } else {
                uint256 balanceAsset = IERC20(assets[i]).balanceOf(address(this));
                uint256 diffAsset = balanceAsset - _initBalances[i];
                uint256 diffAssetWithPrecision = _decimalsPrecision(assets[i], diffAsset);
                if (diffAsset > 0) {
                    _increaseF_Asset(assets[i], diffAssetWithPrecision);
                }
            }
        }
    }

    /// @notice F_ASSETS has a precision of 1e18 regardless the decimals of the asset
    function _increaseF_Asset(address _asset, uint256 _assetFee) internal {
        uint256 assetFeePerMONStaked;
        uint256 _totalMONStaked = totalMONStaked;

        if (_totalMONStaked > 0) {
            assetFeePerMONStaked = (_assetFee * PRECISION) / _totalMONStaked;
        }

        F_ASSETS[_asset] = F_ASSETS[_asset] + assetFeePerMONStaked;
        emit F_AssetUpdated(_asset, F_ASSETS[_asset]);
    }

    function _increaseF_DCHF(uint256 _DCHFFee) internal {
        uint256 DCHFFeePerMONStaked;
        uint256 _totalMONStaked = totalMONStaked;

        if (_totalMONStaked > 0) {
            DCHFFeePerMONStaked = (_DCHFFee * PRECISION) / _totalMONStaked;
        }

        F_DCHF = F_DCHF + DCHFFeePerMONStaked;
        emit F_DCHFUpdated(F_DCHF);
    }

    function _getInitialAssetBal() internal view returns (uint256[] memory) {
        address[] memory assets = ASSET_TYPES;
        uint256[] memory balances = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i = _uncheckedInc(i)) {
            if (assets[i] == ETH_REF_ADDRESS) {
                balances[i] = address(this).balance;
            } else {
                balances[i] = IERC20(assets[i]).balanceOf(address(this));
            }
        }

        return balances;
    }

    function _processUserGains(address _user) internal {
        uint256 assetGain;
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i = _uncheckedInc(i)) {
            // Get the user pending asset gain
            assetGain = _getPendingAssetGain(assets[i], _user);

            // Update user F_ASSET_Snapshot[assets[i]]
            _updateUserAssetSnapshot(_user, assets[i]);

            // Transfer the asset gain to the user
            _sendAssetGainToUser(_user, assets[i], assetGain);
            emit StakingGainsAssetWithdrawn(_user, assets[i], assetGain);
        }

        // Get the user pending DCHF gain
        uint256 DCHFGain = _getPendingDCHFGain(_user);

        // Update user F_DCHF_Snapshot
        _updateUserDCHFSnapshot(_user);

        if (protocolFee > 0) {
            uint256 protocolGain = (DCHFGain * protocolFee) / 10000;
            DCHFGain -= protocolGain;
            DCHF.safeTransfer(treasury, protocolGain);
        }

        // Transfer the DCHF gain to the user
        DCHF.safeTransfer(_user, DCHFGain);
        emit StakingGainsDCHFWithdrawn(_user, DCHFGain);
    }

    function _sendAssetGainToUser(
        address _user,
        address _asset,
        uint256 _assetGain
    ) internal {
        _assetGain = _decimalsCorrection(_asset, _assetGain);

        // If there are protocolFees we charge a percentage and send it to the treasury
        if (protocolFee > 0) {
            uint256 protocolGain = (_assetGain * protocolFee) / 10000;
            _assetGain -= protocolGain;
            _sendToTreasury(_asset, protocolGain);
        }

        _sendAsset(_user, _asset, _assetGain);
        emit AssetSent(_asset, msg.sender, _assetGain);
    }

    /// @notice F_ASSETS has a precision of 1e18 regardless the decimals of the asset
    function _decimalsCorrection(address _token, uint256 _amount) internal view returns (uint256) {
        if (_token == address(0)) return _amount;
        if (_amount == 0) return 0;

        uint8 decimals = IERC20Metadata(_token).decimals();
        if (decimals < 18) {
            return _amount / (10**(18 - decimals));
        } else {
            return _amount * (10**(decimals - 18));
        }
    }

    /// @notice F_ASSETS has a precision of 1e18 regardless the decimals of the asset
    function _decimalsPrecision(address _token, uint256 _amount) internal view returns (uint256) {
        if (_token == address(0)) return _amount;
        if (_amount == 0) return 0;

        uint8 decimals = IERC20Metadata(_token).decimals();
        if (decimals < 18) {
            return _amount * (10**(18 - decimals));
        } else {
            return _amount / (10**(decimals - 18));
        }
    }

    function _sendToTreasury(address _asset, uint256 _amount) internal {
        _sendAsset(treasury, _asset, _amount);
        emit SentToTreasury(_asset, _amount);
    }

    function _sendAsset(
        address _to,
        address _asset,
        uint256 _amount
    ) internal {
        if (_asset == ETH_REF_ADDRESS) {
            (bool success, ) = _to.call{value: _amount}("");
            if (success == false) revert FailToSendETH();
        } else {
            IERC20(_asset).safeTransfer(_to, _amount);
        }
    }

    function _stake(uint256 _amount) internal {
        IMONStaking(stakingPool).stake(_amount);
    }

    function _unstake(uint256 _amount) internal {
        IMONStaking(stakingPool).unstake(_amount);
    }

    /// @notice Unchecked increment of an index for gas optimization purposes
    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _notProtectedTokens(address _token) internal view virtual returns (bool) {
        if (_token == address(DCHF) || _token == address(MON)) return false;
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _token) return false;
        }
        return true;
    }

    // --- 'Public view' functions --- //

    function balanceOfDCHF() public view returns (uint256 _balanceDCHF) {
        _balanceDCHF = DCHF.balanceOf(address(this));
    }

    // Returns the global pending staking rewards that this contract could claim from the stakingPool
    function getGlobalPendingRewardsInDCHF() public view returns (uint256 _rewardsInDCHF) {
        uint256 amountDCHF = IMONStaking(stakingPool).getPendingDCHFGain(address(this));

        uint256 amountAssetsInDCHF;
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountAsset = IMONStaking(stakingPool).getPendingAssetGain(assets[i], address(this));
            uint256 priceAsset = IPriceFeed(oracle).getDirectPrice(assets[i]);
            uint256 amountAssetInDCHF = (amountAsset * priceAsset) / PRECISION;
            amountAssetInDCHF = _decimalsCorrection(assets[i], amountAssetInDCHF);
            amountAssetsInDCHF += amountAssetInDCHF;
        }
        _rewardsInDCHF = amountDCHF + amountAssetsInDCHF;
    }

    function getPriceAssetInDCHF(address _asset) public view returns (uint256 _price) {
        _price = _decimalsCorrection(_asset, IPriceFeed(oracle).getDirectPrice(_asset));
    }

    function getUserSnapshot(address _user, address _asset) public view returns (uint256 _snapshot) {
        if (_asset == address(DCHF)) {
            _snapshot = snapshots[_user].F_DCHF_Snapshot;
        } else {
            _snapshot = snapshots[_user].F_ASSET_Snapshot[_asset];
        }
    }

    // --- 'Require' functions --- //

    modifier callerIsStakingPool() {
        if (msg.sender != stakingPool) revert NotStakingPool(msg.sender);
        _;
    }

    function _requireUserHasStake(uint256 currentStake) internal pure {
        if (currentStake == 0) revert NonZeroStake(currentStake);
    }

    receive() external payable callerIsStakingPool {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library DfrancMath {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1 ether;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 decProd)
    {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint256 _base, uint256 _minutes)
        internal
        pure
        returns (uint256)
    {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint256 _coll, uint256 _debt)
        internal
        pure
        returns (uint256)
    {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(_price).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract CheckContract {
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMONStaking {
    function stake(uint256 _MONamount) external;

    function unstake(uint256 _MONamount) external;

    function getPendingAssetGain(address _asset, address _user) external view returns (uint256);

    function getPendingDCHFGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IVesting {
    function transferEntity(address _entity) external returns (uint256 amountLeft);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPriceFeed {
    function getDirectPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}