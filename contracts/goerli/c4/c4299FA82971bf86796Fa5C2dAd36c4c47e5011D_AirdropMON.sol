// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IMONStaking.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IERC20Metadata.sol";

/*
This contract is reserved for MON airdrop of GHNY holders. 
Airdrop eligible users can either choose vesting or freezing and staking.

Vesting during 1000 days is chosen by default. Thus, users who want Freeze & Stake need to later call addUserToFreezer(). 
Any amount already claimed by the user during the Vesting will be deducted from the totalAmount the user is eligible.

Unvesting of Frozen MON starts in 2000 days and has 180 days of duration. Until that moment, user's MON is staked in the stakingPool. 

The mapping snapshots stores the user snapshots of F_ASSETS and F_DCHF in the form of key-value pair (address -> struct Snapshot)
The mapping F_ASSETS stores the asset fees in the form of key-value pair (address -> uint256).
The mapping entitiesVesting stores the user's vesting data in the form of key-value pair (address -> struct RuleVesting).
The mapping entitiesFreezing stores the user's vesting data in the form of key-value pair (address -> struct RuleFreezing).
The mapping stakes stores the user's stake in the form of key-value pair (address -> uint256).

START_VESTING_DATE & END_VESTING_DATE are immutable and excluded from RuleVesting struct in order to save gas.
This means all users have the same vesting conditions.
*/

contract AirdropMON is Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public isInitialized;

    // --- Data --- //

    string public constant NAME = "AirdropContract";

    address public immutable ETH_REF_ADDRESS = address(0);
    address public immutable WBTC_ADDRESS =
        0xE76AfA0301B9eaAeC6636AB873AB358D21B52D61; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public stakingPool = 0x0042D05eFDBf27F86D734c311D7401Cd7f70e1D4; // 0x8Bc3702c35D33E5DF7cb0F06cb72a0c34Ae0C56F;
    address public oracle = 0x5C206ADDb7DC3F9B154966651fe71Ee8E0C4bB9e; // 0x09AB3C0ce6Cb41C13343879A667a6bDAd65ee9DA;
    address public treasury;
    address public distributor;

    bytes32 public immutable merkleRoot =
        0x65c7999e2b67ecdae078a717f79e8988f522b33febd260ad1b9515382113b782;

    IERC20 public immutable MON =
        IERC20(address(0x3092854cdAe1a34c94c0210CCDEfDd07944D3443)); // IERC20(address(0x1EA48B9965bb5086F3b468E50ED93888a661fc17));
    IERC20 public immutable DCHF =
        IERC20(address(0xD550283363c981c363a71050a4A14a0DF6C6BDaD)); // IERC20(address(0x045da4bFe02B320f4403674B3b7d121737727A36));

    uint256 public constant VEST_TIME_VESTING = 2 days; // 2,74 years of Vesting
    uint128 public constant VEST_TIME_FREEZER = 3 days; // Half a year of Vesting
    uint128 public constant VEST_DELAY_FREEZER = 1 days; // 5,48 years of Freezing
    uint256 internal constant PRECISION = 1 ether; // 1e18

    uint256 public protocolFee; // In bps 1% = 100, 10% = 1000, 100% = 10000

    uint256 public immutable START_VESTING_DATE;
    uint256 public immutable END_VESTING_DATE;

    struct RuleVesting {
        uint256 totalMON;
        uint256 claimed;
    }

    struct RuleFreezing {
        uint128 startVestingDate;
        uint128 endVestingDate;
        uint256 totalMON;
        uint256 claimed;
    }

    mapping(address => RuleVesting) public entitiesVesting;
    mapping(address => RuleFreezing) public entitiesFreezing;

    mapping(address => uint256) public stakes;

    uint256 internal totalMONStaked; // Used to get fees per-MON-staked
    uint256 internal totalMONVested;

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
    error ProtectedToken(address token);
    error AssetExists(address asset);
    error AssetNotExists(address asset);
    error NotStakingPool(address sender);

    event SentToTreasury(address indexed asset, uint256 amount);
    event AssetSent(
        address indexed asset,
        address indexed account,
        uint256 amount
    );
    event AssetAdded(address asset);
    event F_AssetUpdated(address indexed asset, uint256 F_ASSET);
    event F_DCHFUpdated(uint256 F_DCHF);
    event StakerSnapshotUpdated(
        address staker,
        address asset,
        uint256 F_Snapshot
    );
    event StakeChanged(address indexed staker, uint256 newStake);
    event StakingGainsAssetWithdrawn(
        address indexed staker,
        address indexed asset,
        uint256 assetGain
    );
    event StakingGainsDCHFWithdrawn(address indexed staker, uint256 DCHFGain);
    event Claim(address indexed user, uint256 amount);
    event ClaimAirdrop(address indexed user, uint256 amount);
    event Sweep(address indexed token, uint256 amount);
    event SetFees(uint256 fee, uint256 prevFee);

    // --- External Functions --- //

    constructor() {
        START_VESTING_DATE = block.timestamp;
        END_VESTING_DATE = block.timestamp + VEST_TIME_VESTING;
    }

    function setAddresses(address _treasury, address _distributor)
        external
        onlyOwner
    {
        require(!isInitialized, "Already Initialized");
        if (_treasury == address(0) || _distributor == address(0))
            revert ZeroAddress();

        isInitialized = true;

        _pause();

        treasury = _treasury;
        distributor = _distributor;

        isAssetTracked[ETH_REF_ADDRESS] = true;
        ASSET_TYPES.push(ETH_REF_ADDRESS);

        isAssetTracked[WBTC_ADDRESS] = true;
        ASSET_TYPES.push(WBTC_ADDRESS);

        // Approve the stakingPool for spending MON
        MON.approve(stakingPool, 0);
        MON.approve(stakingPool, type(uint256).max);
    }

    function claimAirdrop(uint256 amount, bytes32[] calldata merkleProof)
        external
    {
        require(
            entitiesVesting[msg.sender].totalMON == 0 &&
                isFreezerUser(msg.sender) == false,
            "AirDrop already claimed"
        );

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        // Add entity vesting for the user
        _addEntityVestingAirdrop(msg.sender, amount);

        emit ClaimAirdrop(msg.sender, amount);
    }

    function addEntityVestingBatch(
        address[] memory _entities,
        uint256[] memory _totalSupplies
    ) external onlyOwner {
        require(
            _entities.length == _totalSupplies.length,
            "Array length missmatch"
        );

        uint256 _sumTotalSupplies = 0;

        for (uint256 i = 0; i < _entities.length; i = _uncheckedInc(i)) {
            if (_entities[i] == address(0)) revert ZeroAddress();

            require(
                entitiesVesting[_entities[i]].totalMON == 0,
                "Existing Vesting Rule"
            );

            entitiesVesting[_entities[i]] = RuleVesting({
                totalMON: _totalSupplies[i],
                claimed: 0
            });

            _sumTotalSupplies += _totalSupplies[i];
        }

        totalMONVested += _sumTotalSupplies;

        MON.safeTransferFrom(msg.sender, address(this), _sumTotalSupplies);
    }

    function addEntityVesting(address _entity, uint256 _totalSupply)
        external
        onlyOwner
    {
        if (_entity == address(0)) revert ZeroAddress();

        require(
            entitiesVesting[_entity].totalMON == 0,
            "Existing Vesting Rule"
        );

        entitiesVesting[_entity] = RuleVesting({
            totalMON: _totalSupply,
            claimed: 0
        });

        totalMONVested += _totalSupply;

        MON.safeTransferFrom(msg.sender, address(this), _totalSupply);
    }

    function _addEntityVestingAirdrop(address _entity, uint256 _totalSupply)
        internal
    {
        entitiesVesting[_entity] = RuleVesting({
            totalMON: _totalSupply,
            claimed: 0
        });

        totalMONVested += _totalSupply;

        MON.safeTransferFrom(distributor, address(this), _totalSupply);
    }

    function removeEntityVesting(address _entity)
        external
        nonReentrant
        onlyOwner
        entityRuleVestingExists(_entity)
    {
        require(isFreezerUser(_entity) == false, "Only Vesters");

        uint256 amountLeft = _removeEntityVesting(_entity);
        MON.safeTransfer(treasury, amountLeft);
    }

    function _removeEntityVesting(address _entity)
        internal
        returns (uint256 amountLeft)
    {
        // Send claimable MON to the user
        _sendMONVesting(_entity);

        RuleVesting memory vestingRule = entitiesVesting[_entity];

        totalMONVested =
            totalMONVested -
            (vestingRule.totalMON - vestingRule.claimed);

        delete entitiesVesting[_entity];

        amountLeft = vestingRule.totalMON - vestingRule.claimed;
    }

    function addUserToFreezer()
        external
        nonReentrant
        whenNotPaused
        entityRuleVestingExists(msg.sender)
    {
        // amountLeft is the amount of MON left to freeze, once deducted the claimed MON
        uint256 amountLeft = _removeEntityVesting(msg.sender);
        if (amountLeft == 0) revert ZeroAmount();

        // Storage update
        entitiesFreezing[msg.sender] = RuleFreezing({
            startVestingDate: uint128(block.timestamp) + VEST_DELAY_FREEZER, // Vesting period starts 2000 days
            endVestingDate: uint128(block.timestamp) +
                VEST_DELAY_FREEZER +
                VEST_TIME_FREEZER, // Vesting period ends in 2180 days
            totalMON: amountLeft,
            claimed: 0
        });

        // Save initial contract balances
        uint256 initialBalanceDCHF = balanceOfDCHF();
        uint256[] memory initialAssetBalances = _getInitialAssetBal();

        // With stake we automatically claim the rewards generated
        _stake(amountLeft);

        // We update the fees per asset as rewards have been collected
        _updateFeesPerAsset(initialAssetBalances);

        uint256 diffDCHF = balanceOfDCHF() - initialBalanceDCHF;
        if (diffDCHF > 0) {
            _increaseF_DCHF(diffDCHF);
        }

        stakes[msg.sender] = amountLeft;
        totalMONStaked += amountLeft;

        // We update the snapshots so user starts earning from this moment
        _updateUserSnapshots(msg.sender);

        emit StakeChanged(msg.sender, amountLeft);
    }

    /// @notice For claiming the unvested MON from Vesting
    function claimMONVesting() external entityRuleVestingExists(msg.sender) {
        _sendMONVesting(msg.sender);
    }

    function _sendMONVesting(address _entity) private {
        uint256 unclaimedAmount = getClaimableMONVesting(_entity);
        if (unclaimedAmount == 0) return;

        RuleVesting storage entityRule = entitiesVesting[_entity];
        entityRule.claimed += unclaimedAmount;

        totalMONVested = totalMONVested - unclaimedAmount;

        MON.safeTransfer(_entity, unclaimedAmount);
        emit Claim(_entity, unclaimedAmount);
    }

    function claimRewards()
        external
        nonReentrant
        whenNotPaused
        stakeExists(msg.sender)
    {
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

    /// @notice For claiming existing rewards from the contract based on snapshots
    function claimExistingRewards()
        external
        nonReentrant
        whenNotPaused
        stakeExists(msg.sender)
    {
        _processUserGains(msg.sender);
    }

    /// @notice For claiming the unvested MON from Freezing and the staking rewards
    function claimMONAndRewards()
        external
        nonReentrant
        whenNotPaused
        stakeExists(msg.sender)
    {
        // Save initial contract balances
        uint256 initialBalanceDCHF = balanceOfDCHF();
        uint256[] memory initialAssetBalances = _getInitialAssetBal();

        // Claim the unvested MON, here we already unstake from stakingPool
        _claimMONFreezing();

        // Update fees per Asset to reflect the last earnings state
        _updateFeesPerAsset(initialAssetBalances);
        uint256 diffDCHF = balanceOfDCHF() - initialBalanceDCHF;
        if (diffDCHF > 0) {
            _increaseF_DCHF(diffDCHF);
        }

        // Update user snapshots to current state and send any accumulated asset & DCHF gains
        _processUserGains(msg.sender);
    }

    function _claimMONFreezing() internal {
        uint256 unclaimedAmount = getClaimableMONFreezing(msg.sender);

        if (unclaimedAmount > 0) {
            _unstake(unclaimedAmount);
            _sendMONFreezing(msg.sender, unclaimedAmount);
        }
    }

    function _sendMONFreezing(address _entity, uint256 _unclaimedAmount)
        private
    {
        RuleFreezing storage entityRule = entitiesFreezing[_entity];
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

    /// @notice Sweep tokens that are airdropped or transferred by mistake into the contract
    function sweep(address _token) external onlyOwner {
        if (_notProtectedTokens(_token) == false) revert ProtectedToken(_token);
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(treasury, amount);
        emit Sweep(_token, amount);
    }

    /// @notice This allows for flexibility and airdrop of ERC20 rewards to the stakers
    function airdropRewards(address _asset, uint256 _amount)
        external
        onlyOwner
    {
        if (_asset == address(DCHF)) {
            DCHF.safeTransferFrom(msg.sender, address(this), _amount);
            _increaseF_DCHF(_amount);
        } else {
            if (isAssetTracked[_asset] == false) revert AssetNotExists(_asset);
            uint256 diffAssetWithPrecision = _decimalsPrecision(
                _asset,
                _amount
            );
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _increaseF_Asset(_asset, diffAssetWithPrecision);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Pending reward functions --- //

    function getPendingAssetGain(address _asset, address _user)
        public
        view
        returns (uint256 _assetGain)
    {
        _assetGain = _getPendingAssetGain(_asset, _user);
    }

    function getPendingDCHFGain(address _user)
        public
        view
        returns (uint256 _DCHFGain)
    {
        _DCHFGain = _getPendingDCHFGain(_user);
    }

    function _getPendingAssetGain(address _asset, address _user)
        internal
        view
        returns (uint256 _assetGain)
    {
        uint256 F_ASSET_Snapshot = snapshots[_user].F_ASSET_Snapshot[_asset];
        _assetGain =
            (stakes[_user] * (F_ASSETS[_asset] - F_ASSET_Snapshot)) /
            PRECISION;
    }

    function _getPendingDCHFGain(address _user)
        internal
        view
        returns (uint256 _DCHFGain)
    {
        uint256 F_DCHF_Snapshot = snapshots[_user].F_DCHF_Snapshot;
        _DCHFGain = (stakes[_user] * (F_DCHF - F_DCHF_Snapshot)) / PRECISION;
    }

    // Returns the current claimable gain in DCHF since last user snapshots were taken
    function getUserPendingGainInDCHF(address _user)
        public
        view
        returns (uint256 _totalDCHFGain)
    {
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountAsset = _getPendingAssetGain(assets[i], _user);
            uint256 priceAsset = getPriceAssetInDCHF(assets[i]);
            uint256 amountAssetInDCHF = (amountAsset * priceAsset) / PRECISION; // Precision 1e18
            _totalDCHFGain += amountAssetInDCHF;
        }
        _totalDCHFGain += _getPendingDCHFGain(_user);
    }

    function getClaimableMONFreezing(address _entity)
        public
        view
        returns (uint256 claimable)
    {
        RuleFreezing memory entityRule = entitiesFreezing[_entity];

        if (block.timestamp < entityRule.startVestingDate) return 0;

        if (block.timestamp >= entityRule.endVestingDate) {
            claimable = entityRule.totalMON - entityRule.claimed;
        } else {
            claimable =
                ((entityRule.totalMON *
                    (block.timestamp - entityRule.startVestingDate)) /
                    (entityRule.endVestingDate - entityRule.startVestingDate)) -
                entityRule.claimed;
        }
    }

    function getClaimableMONVesting(address _entity)
        public
        view
        returns (uint256 claimable)
    {
        RuleVesting memory entityRule = entitiesVesting[_entity];

        if (block.timestamp < START_VESTING_DATE) return 0;

        if (block.timestamp >= END_VESTING_DATE) {
            claimable = entityRule.totalMON - entityRule.claimed;
        } else {
            claimable =
                ((entityRule.totalMON *
                    (block.timestamp - START_VESTING_DATE)) /
                    (END_VESTING_DATE - START_VESTING_DATE)) -
                entityRule.claimed;
        }
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
        emit StakerSnapshotUpdated(_user, _asset, F_ASSETS[_asset]);
    }

    function _updateUserDCHFSnapshot(address _user) internal {
        snapshots[_user].F_DCHF_Snapshot = F_DCHF;
        emit StakerSnapshotUpdated(_user, address(DCHF), F_DCHF);
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
                uint256 balanceAsset = IERC20(assets[i]).balanceOf(
                    address(this)
                );
                uint256 diffAsset = balanceAsset - _initBalances[i];
                uint256 diffAssetWithPrecision = _decimalsPrecision(
                    assets[i],
                    diffAsset
                );
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
        emit AssetSent(_asset, _user, _assetGain);
    }

    /// @notice F_ASSETS has a precision of 1e18 regardless the decimals of the asset
    function _decimalsCorrection(address _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
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
    function _decimalsPrecision(address _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
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

    function _notProtectedTokens(address _token)
        internal
        view
        virtual
        returns (bool)
    {
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
    function getGlobalPendingRewardsInDCHF()
        public
        view
        returns (uint256 _rewardsInDCHF)
    {
        uint256 amountDCHF = IMONStaking(stakingPool).getPendingDCHFGain(
            address(this)
        );

        uint256 amountAssetsInDCHF;
        address[] memory assets = ASSET_TYPES;
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountAsset = IMONStaking(stakingPool).getPendingAssetGain(
                assets[i],
                address(this)
            );
            uint256 priceAsset = getPriceAssetInDCHF(assets[i]);
            uint256 amountAssetInDCHF = (amountAsset * priceAsset) / PRECISION;
            amountAssetsInDCHF += amountAssetInDCHF;
        }
        _rewardsInDCHF = amountDCHF + amountAssetsInDCHF;
    }

    function getPriceAssetInDCHF(address _asset)
        public
        view
        returns (uint256 _price)
    {
        _price = IPriceFeed(oracle).getDirectPrice(_asset); // 1e18 precision
    }

    function getUserSnapshot(address _user, address _asset)
        public
        view
        returns (uint256 _snapshot)
    {
        if (_asset == address(DCHF)) {
            _snapshot = snapshots[_user].F_DCHF_Snapshot;
        } else {
            _snapshot = snapshots[_user].F_ASSET_Snapshot[_asset];
        }
    }

    function status()
        public
        view
        returns (uint256 _totalMONVested, uint256 _totalMONStaked)
    {
        (_totalMONVested, _totalMONStaked) = (totalMONVested, totalMONStaked);
    }

    function isFreezerUser(address _user)
        public
        view
        returns (bool _freezingUser)
    {
        if (stakes[_user] > 0) return true;
        return false;
    }

    // --- 'Require' functions --- //

    modifier entityRuleVestingExists(address _entity) {
        require(entitiesVesting[_entity].totalMON != 0, "Missing Vesting Rule");
        _;
    }

    modifier stakeExists(address _entity) {
        require(stakes[_entity] > 0, "Missing Stake");
        _;
    }

    modifier callerIsStakingPool() {
        if (msg.sender != stakingPool) revert NotStakingPool(msg.sender);
        _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IMONStaking {
    function stake(uint256 _MONamount) external;

    function unstake(uint256 _MONamount) external;

    function getPendingAssetGain(address _asset, address _user)
        external
        view
        returns (uint256);

    function getPendingDCHFGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPriceFeed {
    function getDirectPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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