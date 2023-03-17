// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.0;
// Library imports
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

// Local imports
import "../general/Ownable.sol";
import "../general/ERC721TokenReceiver.sol";

//  Interfaces
import "../interfaces/IERC20Mintable.sol";
import "../interfaces/IWNXM.sol";
import "../interfaces/INexusMutual.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IShieldMining.sol";

// solhint-disable not-rely-on-time
// solhint-disable reason-string
// solhint-disable max-states-count
// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks
// solhint-disable contract-name-camelcase
// solhint-disable var-name-mixedcase
// solhint-disable avoid-tx-origin

contract arNXMVault is Ownable, ERC721TokenReceiver {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;

    struct WithdrawalRequest {
        uint48 requestTime;
        uint104 nAmount;
        uint104 arAmount;
    }

    event Deposit(
        address indexed user,
        uint256 nAmount,
        uint256 arAmount,
        uint256 timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint256 arAmount,
        uint256 nAmount,
        uint256 requestTime,
        uint256 withdrawTime
    );
    event Withdrawal(
        address indexed user,
        uint256 nAmount,
        uint256 arAmount,
        uint256 timestamp
    );

    event NxmReward(uint256 reward, uint256 timestamp, uint256 totalAum);

    uint256 private constant DENOMINATOR = 1000;

    // Amount of time between
    uint256 private ____deprecated____0;

    // Amount of time that rewards are distributed over.
    uint256 public rewardDuration;

    // This used to be unstake percent but has now been deprecated in favor of individual unstakes.
    // Paranoia results in this not being replaced but rather deprecated and new variables placed at the bottom.
    uint256 private ____deprecated____1;

    // Amount of wNXM (in token Wei) to reserve each period.
    // Overwrites reservePercent in update.
    uint256 public reserveAmount;

    // Withdrawals may be paused if a hack has recently happened. Timestamp of when the pause happened.
    uint256 public withdrawalsPaused;

    // Amount of time withdrawals may be paused after a hack.
    uint256 public pauseDuration;

    // Address that will receive administration funds from the contract.
    address public beneficiary;

    // Percent of funds to be distributed for administration of the contract. 10 == 1%; 1000 == 100%.
    uint256 public adminPercent;

    // Percent of staking rewards that referrers get.
    uint256 public referPercent;

    // Timestamp of when the last restake took place--7 days between each.
    uint256 private ____deprecated____2;

    // The amount of the last reward.
    uint256 public lastReward;

    // Uniswap, Maker, Compound, Aave, Curve, Synthetix, Yearn, RenVM, Balancer, dForce.
    address[] public protocols;

    // Amount to unstake each time.
    uint256[] private ____deprecated____3;

    // Protocols being actively used in staking or unstaking.
    address[] private ____deprecated____4;

    // Nxm tokens.
    IERC20 public wNxm;
    IERC20 public nxm;
    IERC20Mintable public arNxm;

    // Nxm Master address.
    INxmMaster public nxmMaster;

    // Reward manager for referrers.
    IRewardManager public rewardManager;

    // Referral => referrer
    mapping(address => address) public referrers;

    /*//////////////////////////////////////////////////////////////
                            FIRST UPDATE
    //////////////////////////////////////////////////////////////*/

    uint256 public lastRewardTimestamp;

    /*//////////////////////////////////////////////////////////////
                            SECOND UPDATE
    //////////////////////////////////////////////////////////////*/

    // Protocol that the next restaking will begin on.
    uint256 private ____deprecated____5;

    // Checkpoint in case we want to cut off certain buckets (where we begin the rotations).
    // To bar protocols from being staked/unstaked, move them to before checkpointProtocol.
    uint256 private ____deprecated____6;

    // Number of protocols to stake each time.
    uint256 private ____deprecated____7;

    // Individual percent to unstake.
    uint256[] private ____deprecated____8;

    // Last time an EOA has called this contract.
    mapping(address => uint256) private ____deprecated____9;

    /*//////////////////////////////////////////////////////////////
                            THIRD UPDATE
    //////////////////////////////////////////////////////////////*/

    // Withdraw fee to withdraw immediately.
    uint256 public withdrawFee;

    // Delay to withdraw
    uint256 public withdrawDelay;

    // Total amount of withdrawals pending.
    uint256 public totalPending;

    mapping(address => WithdrawalRequest) public withdrawals;

    /*//////////////////////////////////////////////////////////////
                            FOURTH UPDATE
    //////////////////////////////////////////////////////////////*/

    /// @dev record of vaults NFT tokenIds
    uint256[] public tokenIds;

    /// @dev tokenId to risk pool address
    mapping(uint256 => address) public tokenIdToPool;

    /// @dev Nexus mutual staking NFT
    IStakingNFT public stakingNFT;

    /*//////////////////////////////////////////////////////////////
                            MODIFIER'S
    //////////////////////////////////////////////////////////////*/
    ///@dev Avoid composability issues for liquidation.
    modifier notContract() {
        require(msg.sender == tx.origin, "Sender must be an EOA.");
        _;
    }

    /**
     * @param _wNxm Address of the wNxm contract.
     * @param _arNxm Address of the arNxm contract.
     * @param _nxmMaster Address of Nexus' master address (to fetch others).
     * @param _rewardManager Address of the ReferralRewards smart contract.
     **/
    function initialize(
        address _wNxm,
        address _arNxm,
        address _nxm,
        address _nxmMaster,
        address _rewardManager
    ) public {
        require(
            address(arNxm) == address(0),
            "Contract has already been initialized."
        );

        Ownable.initializeOwnable();
        wNxm = IERC20(_wNxm);
        nxm = IERC20(_nxm);
        arNxm = IERC20Mintable(_arNxm);
        nxmMaster = INxmMaster(_nxmMaster);
        rewardManager = IRewardManager(_rewardManager);
        // unstakePercent = 100;
        adminPercent = 0;
        referPercent = 25;
        reserveAmount = 30 ether;
        pauseDuration = 10 days;
        beneficiary = msg.sender;
        // restakePeriod = 3 days;
        rewardDuration = 9 days;

        // Approve to wrap and send funds to reward manager.
        arNxm.approve(_rewardManager, type(uint256).max);
    }

    /**
     * @dev Set's initial state for nexus mutual v2
     * @param _stakingNFT Nexus mutual staking NFT contract
     * @param _tokenIds Array of tokenIds this vault initially owns
     * @param _riskPools Array of risk pools this vault has initially staked into
     **/
    function initializeV2(
        IStakingNFT _stakingNFT,
        uint256[] memory _tokenIds,
        address[] memory _riskPools
    ) external onlyOwner {
        require(address(stakingNFT) == address(0), "initialized already");
        require(_tokenIds.length == _riskPools.length, "length mismatch");

        tokenIds = _tokenIds;
        for (uint256 i; i < _tokenIds.length; i++) {
            tokenIdToPool[_tokenIds[i]] = _riskPools[i];
        }
        stakingNFT = _stakingNFT;

        _collectOldRewards();
    }

    /**
     * @dev Deposit wNxm or NXM to get arNxm in return.
     * @param _nAmount The amount of NXM to stake.
     * @param _referrer The address that referred this user.
     * @param _isNxm True if the token is NXM, false if the token is wNXM.
     **/
    function deposit(
        uint256 _nAmount,
        address _referrer,
        bool _isNxm
    ) external {
        if (referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = _referrer != address(0)
                ? _referrer
                : beneficiary;
            address refToSet = _referrer != address(0)
                ? _referrer
                : beneficiary;
            referrers[msg.sender] = refToSet;

            // A wallet with a previous arNXM balance would be able to subtract referral weight that it never added.
            uint256 prevBal = arNxm.balanceOf(msg.sender);
            if (prevBal > 0) rewardManager.stake(refToSet, msg.sender, prevBal);
        }

        // This amount must be determined before arNxm mint.
        uint256 arAmount = arNxmValue(_nAmount);

        if (_isNxm) {
            nxm.safeTransferFrom(msg.sender, address(this), _nAmount);
        } else {
            wNxm.safeTransferFrom(msg.sender, address(this), _nAmount);
            _unwrapWnxm(_nAmount);
        }

        // Mint also increases sender's referral balance through alertTransfer.
        arNxm.mint(msg.sender, arAmount);

        emit Deposit(msg.sender, _nAmount, arAmount, block.timestamp);
    }

    /**
     * @dev Withdraw an amount of wNxm or NXM by burning arNxm.
     * @param _arAmount The amount of arNxm to burn for the wNxm withdraw.
     * @param _payFee Flag to pay fee to withdraw without delay.
     **/
    function withdraw(uint256 _arAmount, bool _payFee) external {
        require(
            (block.timestamp - withdrawalsPaused) > pauseDuration,
            "Withdrawals are temporarily paused."
        );

        // This amount must be determined before arNxm burn.
        uint256 nAmount = nxmValue(_arAmount);

        require(
            (totalPending + nAmount) <= nxm.balanceOf(address(this)),
            "Not enough NXM available for withdrawal."
        );

        if (_payFee) {
            uint256 fee = (nAmount * withdrawFee) / (1000);
            uint256 disbursement = (nAmount - fee);

            // Burn also decreases sender's referral balance through alertTransfer.
            arNxm.burn(msg.sender, _arAmount);
            _wrapNxm(disbursement);
            wNxm.safeTransfer(msg.sender, disbursement);

            emit Withdrawal(msg.sender, nAmount, _arAmount, block.timestamp);
        } else {
            totalPending = totalPending + nAmount;
            arNxm.safeTransferFrom(msg.sender, address(this), _arAmount);
            WithdrawalRequest memory prevWithdrawal = withdrawals[msg.sender];
            withdrawals[msg.sender] = WithdrawalRequest(
                uint48(block.timestamp),
                prevWithdrawal.nAmount + uint104(nAmount),
                prevWithdrawal.arAmount + uint104(_arAmount)
            );

            emit WithdrawRequested(
                msg.sender,
                _arAmount,
                nAmount,
                block.timestamp,
                block.timestamp + withdrawDelay
            );
        }
    }

    /**
     * @dev Finalize withdraw request after withdrawal delay
     **/
    function withdrawFinalize() external {
        address user = msg.sender;
        WithdrawalRequest memory withdrawal = withdrawals[user];
        uint256 nAmount = uint256(withdrawal.nAmount);
        uint256 arAmount = uint256(withdrawal.arAmount);
        uint256 requestTime = uint256(withdrawal.requestTime);

        require(
            (block.timestamp - withdrawalsPaused) > pauseDuration,
            "Withdrawals are temporarily paused."
        );
        require(
            (requestTime + withdrawDelay) <= block.timestamp,
            "Not ready to withdraw"
        );
        require(nAmount > 0, "No pending amount to withdraw");

        // Burn also decreases sender's referral balance through alertTransfer.
        arNxm.burn(address(this), arAmount);
        _wrapNxm(nAmount);
        wNxm.safeTransfer(user, nAmount);
        delete withdrawals[user];
        totalPending = totalPending - nAmount;

        emit Withdrawal(user, nAmount, arAmount, block.timestamp);
    }

    /**
     * @dev collect rewards from staking pool
     **/
    function getRewardNxm() external notContract {
        // only allow to claim rewards after 1 week
        require(
            (block.timestamp - lastRewardTimestamp) > rewardDuration,
            "reward interval not reached"
        );
        uint256 prevAum = aum();
        uint256 rewards;
        for (uint256 i; i < tokenIds.length; i++) {
            rewards += _getRewardsNxm(tokenIdToPool[tokenIds[i]], tokenIds[i]);
        }

        // rewards to be given to users (full reward - admin reward - referral reward).
        uint256 finalReward = _feeRewardsNxm(rewards);

        // update last reward
        lastReward = finalReward;
        if (finalReward > 0) {
            emit NxmReward(rewards, block.timestamp, prevAum);
        }
        lastRewardTimestamp = block.timestamp;
    }

    /**
     * @dev claim rewards from shield mining
     * @param _shieldMining shield mining contract address
     * @param _protocols Protocol funding the rewards.
     * @param _sponsors sponsor address who funded the shield mining
     * @param _tokens token address that sponsor is distributing
     **/
    function getShieldMiningRewards(
        address _shieldMining,
        address[] calldata _protocols,
        address[] calldata _sponsors,
        address[] calldata _tokens
    ) external notContract {
        IShieldMining(_shieldMining).claimRewards(
            _protocols,
            _sponsors,
            _tokens
        );
    }

    function aum() public view returns (uint256) {
        uint256 stakedDeposit;
        INFTDescriptor nftDescriptor = INFTDescriptor(
            stakingNFT.nftDescriptor()
        );

        for (uint256 i; i < tokenIds.length; i++) {
            (, uint256 totalStaked, ) = nftDescriptor.getActiveDeposits(
                tokenIds[i],
                tokenIdToPool[tokenIds[i]]
            );
            stakedDeposit += totalStaked;
        }
        // balance of this address

        return stakedDeposit + nxm.balanceOf(address(this));
    }

    /**
     * @dev Find the arNxm value of a certain amount of wNxm.
     * @param _nAmount The amount of NXM to check arNxm value of.
     * @return arAmount The amount of arNxm the input amount of wNxm is worth.
     **/
    function arNxmValue(
        uint256 _nAmount
    ) public view returns (uint256 arAmount) {
        // Get reward allowed to be distributed.
        uint256 reward = _currentReward();

        // aum() holds full reward so we sub lastReward (which needs to be distributed over time)
        // and add reward that has been distributed
        uint256 totalN = aum() + reward - lastReward;
        uint256 totalAr = arNxm.totalSupply();

        // Find exchange amount of one token, then find exchange amount for full value.
        if (totalN == 0) {
            arAmount = _nAmount;
        } else {
            uint256 oneAmount = (totalAr * 1e18) / totalN;
            arAmount = (_nAmount * oneAmount) / (1e18);
        }
    }

    /**
     * @dev Find the wNxm value of a certain amount of arNxm.
     * @param _arAmount The amount of arNxm to check wNxm value of.
     * @return nAmount The amount of wNxm the input amount of arNxm is worth.
     **/
    function nxmValue(uint256 _arAmount) public view returns (uint256 nAmount) {
        // Get reward allowed to be distributed.
        uint256 reward = _currentReward();

        // aum() holds full reward so we sub lastReward (which needs to be distributed over time)
        // and add reward that has been distributed
        uint256 totalN = aum() + reward - lastReward;
        uint256 totalAr = arNxm.totalSupply();

        // Find exchange amount of one token, then find exchange amount for full value.
        uint256 oneAmount = (totalN * 1e18) / totalAr;
        nAmount = (_arAmount * (oneAmount)) / 1e18;
    }

    /**
     * @dev Used to determine staked nxm amount in pooled staking contract.
     * @return staked Staked nxm amount.
     **/
    function stakedNxm() public view returns (uint256 staked) {
        staked = aum() - nxm.balanceOf(address(this));
    }

    /**
     * @dev Used to determine distributed reward amount
     * @return reward distributed reward amount
     **/
    function currentReward() external view returns (uint256 reward) {
        reward = _currentReward();
    }

    /**
     * @dev Anyone may call this function to pause withdrawals for a certain amount of time.
     *      We check Nexus contracts for a recent accepted claim, then can pause to avoid further withdrawals.
     * @param _claimId The ID of the cover that has been accepted for a confirmed hack.
     **/
    function pauseWithdrawals(uint256 _claimId) external {
        IClaimsData claimsData = IClaimsData(_getClaimsData());

        (, /*coverId*/ uint256 status) = claimsData.getClaimStatusNumber(
            _claimId
        );
        uint256 dateUpdate = claimsData.getClaimDateUpd(_claimId);

        // Status must be 14 and date update must be within the past 7 days.
        if (status == 14 && (block.timestamp - dateUpdate) <= 7 days) {
            withdrawalsPaused = block.timestamp;
        }
    }

    /**
     * @dev When arNXM tokens are transferred, the referrer stakes must be adjusted on RewardManager.
     *      This is taken care of by a "_beforeTokenTransfer" function on the arNXM ERC20.
     * @param _from The user that tokens are being transferred from.
     * @param _to The user that tokens are being transferred to.
     * @param _amount The amount of tokens that are being transferred.
     **/
    function alertTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        require(
            msg.sender == address(arNxm),
            "Sender must be the token contract."
        );

        // address(0) means the contract or EOA has not interacted directly with arNXM Vault.
        if (referrers[_from] != address(0))
            rewardManager.withdraw(referrers[_from], _from, _amount);
        if (referrers[_to] != address(0))
            rewardManager.stake(referrers[_to], _to, _amount);
    }

    /**
     * @dev Collect old rewards from nexus v1
     **/
    function _collectOldRewards() private {
        IPooledStaking pool = IPooledStaking(nxmMaster.getLatestAddress("PS"));
        // Find current reward, find user reward (transfers reward to admin within this).
        uint256 fullReward = pool.stakerReward(address(this));
        _feeRewardsNxm(fullReward);
        pool.withdrawReward(address(this));
    }

    /**
     * @dev Withdraw any available rewards from Nexus.
     * @return reward The amount of rewards collect from a risk pool.
     **/
    function _getRewardsNxm(
        address _poolAddress,
        uint256 _tokenId
    ) internal returns (uint256 reward) {
        IStakingPool pool = IStakingPool(_poolAddress);

        (, reward) = pool.withdraw(
            _tokenId,
            false,
            true,
            _getActiveTrancheIds()
        );
    }

    /**
     * @dev Find and distribute administrator rewards.
     * @param reward Full reward given from this week.
     * @return userReward Reward amount given to users (full reward - admin reward).
     **/
    function _feeRewardsNxm(
        uint256 reward
    ) internal returns (uint256 userReward) {
        // Find both rewards before minting any.
        uint256 adminReward = arNxmValue((reward * adminPercent) / DENOMINATOR);
        uint256 referReward = arNxmValue((reward * referPercent) / DENOMINATOR);

        // Mint to beneficary then this address (to then transfer to rewardManager).
        if (adminReward > 0) {
            arNxm.mint(beneficiary, adminReward);
        }
        if (referReward > 0) {
            arNxm.mint(address(this), referReward);
            rewardManager.notifyRewardAmount(referReward);
        }

        userReward = reward - (adminReward + referReward);
    }

    /**
     * @dev Used to withdraw nxm from staking pool with ability to pass in risk pool address
     * @param _poolAddress risk pool address
     * @param _tokenId Staking NFT token id
     * @param _trancheIds tranches to unstake from
     **/
    function withdrawNxm(
        address _poolAddress,
        uint256 _tokenId,
        uint256[] memory _trancheIds
    ) external onlyOwner {
        _withdrawFromPool(_poolAddress, _tokenId, true, false, _trancheIds);
    }

    /**
     * @dev Used to unwrap wnxm tokens to nxm
     **/
    function unwrapWnxm() external {
        uint256 balance = wNxm.balanceOf(address(this));
        _unwrapWnxm(balance);
    }

    /**
     * @dev Used to stake nxm tokens to stake pool. it is determined manually
     **/
    function stakeNxm(
        uint256 _amount,
        address _poolAddress,
        uint256 _trancheId,
        uint256 _requestTokenId
    ) external onlyOwner {
        _stakeNxm(_amount, _poolAddress, _trancheId, _requestTokenId);
    }

    /**
     * @dev Used to withdraw nxm from staking pool after tranche expires
     * @param _tokenId Staking NFT token id
     * @param _trancheIds tranches to unstake from
     **/
    function unstakeNxm(
        uint256 _tokenId,
        uint256[] memory _trancheIds
    ) external onlyOwner {
        _withdrawFromPool(
            tokenIdToPool[_tokenId],
            _tokenId,
            true,
            false,
            _trancheIds
        );
    }

    /**
     * @dev Withdraw any Nxm we can from the staking pool.
     * @return amount The amount of funds that are being withdrawn.
     **/
    function _withdrawFromPool(
        address _poolAddress,
        uint256 _tokenId,
        bool _withdrawStake,
        bool _withdrawRewards,
        uint256[] memory _trancheIds
    ) internal returns (uint256 amount) {
        IStakingPool pool = IStakingPool(_poolAddress);
        (amount, ) = pool.withdraw(
            _tokenId,
            _withdrawStake,
            _withdrawRewards,
            _trancheIds
        );
    }

    /**
     * @dev Stake any wNxm over the amount we need to keep in reserve (bufferPercent% more than withdrawals last week).
     * @param _amount amount of NXM to stake
     * @param _poolAddress risk pool address
     * @param _trancheId tranche to stake NXM in
     * @param _requestTokenId token id of NFT
     **/
    function _stakeNxm(
        uint256 _amount,
        address _poolAddress,
        uint256 _trancheId,
        uint256 _requestTokenId
    ) internal {
        IStakingPool pool = IStakingPool(_poolAddress);
        uint256 balance = nxm.balanceOf(address(this));
        // If we do need to restake funds...
        // toStake == additional stake on top of old ones

        require(
            (reserveAmount + totalPending + _amount) <= balance,
            "Not enough NXM"
        );

        _approveNxm(_getTokenController(), _amount);
        uint256 tokenId = pool.depositTo(
            _amount,
            _trancheId,
            _requestTokenId,
            address(this)
        );
        // if new nft token is minted we need to keep track of
        // tokenId and poolAddress inorder to calculate assets
        // under management
        if (tokenIdToPool[tokenId] == address(0)) {
            tokenIds.push(tokenId);
            tokenIdToPool[tokenId] = _poolAddress;
        }
    }

    /**
     * @dev Calculate what the current reward is. We stream this to arNxm value to avoid dumps.
     * @return reward Amount of reward currently calculated into arNxm value.
     **/
    function _currentReward() internal view returns (uint256 reward) {
        uint256 duration = rewardDuration;
        uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
        if (timeElapsed == 0) {
            return 0;
        }

        // Full reward is added to the balance if it's been more than the disbursement duration.
        if (timeElapsed >= duration) {
            reward = lastReward;
            // Otherwise, disburse amounts linearly over duration.
        } else {
            // 1e18 just for a buffer.
            uint256 portion = (duration * 1e18) / timeElapsed;
            reward = (lastReward * 1e18) / portion;
        }
    }

    /**
     * @dev Wrap Nxm tokens to be able to be withdrawn as wNxm.
     **/
    function _wrapNxm(uint256 _amount) internal {
        _approveNxm(address(wNxm), _amount);
        IWNXM(address(wNxm)).wrap(_amount);
    }

    /**
     * @dev Unwrap wNxm tokens to be able to be used within the Nexus Mutual system.
     * @param _amount Amount of wNxm tokens to be unwrapped.
     **/
    function _unwrapWnxm(uint256 _amount) internal {
        IWNXM(address(wNxm)).unwrap(_amount);
    }

    /**
     * @dev Approve wNxm contract to be able to transferFrom Nxm from this contract.
     **/
    function _approveNxm(address _to, uint256 _amount) internal {
        nxm.approve(_to, _amount);
    }

    /**
     * @dev Get the current NXM token controller (for NXM actions) from Nexus Mutual.
     * @return controller Address of the token controller.
     **/
    function _getTokenController() internal view returns (address controller) {
        controller = nxmMaster.getLatestAddress("TC");
    }

    /**
     * @dev Get current address of the Nexus Claims Data contract.
     * @return claimsData Address of the Nexus Claims Data contract.
     **/
    function _getClaimsData() internal view returns (address claimsData) {
        claimsData = nxmMaster.getLatestAddress("CD");
    }

    /// @dev get active trancheId's to collect rewards
    function _getActiveTrancheIds() internal view returns (uint256[] memory) {
        uint8 trancheCount = 3;
        uint256 trancheDuration = 91 days;
        uint256[] memory _trancheIds = new uint256[](trancheCount);

        // assuming we have not collected rewards from last expired tranche
        uint256 lastExpiredTrancheId = (block.timestamp / trancheDuration) - 1;
        for (uint256 i = 0; i < trancheCount; i++) {
            _trancheIds[i] = lastExpiredTrancheId + i;
        }
        return _trancheIds;
    }

    /*---- Ownable functions ----*/

    /**
     * @dev pull nxm from arNFT and wrap it to wnxm
     **/
    function pullNXM(
        address _from,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        nxm.transferFrom(_from, address(this), _amount);
        _wrapNxm(_amount);
        wNxm.transfer(_to, _amount);
    }

    /**
     * @dev Buy NXM direct from Nexus Mutual. Used by ExchangeManager.
     * @param _minNxm Minimum amount of NXM tokens to receive in return for the Ether.
     **/
    function buyNxmWithEther(uint256 _minNxm) external payable {
        require(
            msg.sender == 0x1337DEF157EfdeF167a81B3baB95385Ce5A14477,
            "Sender must be ExchangeManager."
        );
        INXMPool pool = INXMPool(nxmMaster.getLatestAddress("P1"));
        pool.buyNXM{value: address(this).balance}(_minNxm);
    }

    /**
     * @dev Vote on Nexus Mutual governance proposals using tokens.
     * @param _proposalId ID of the proposal to vote on.
     * @param _solutionChosen Side of the proposal we're voting for (0 for no, 1 for yes).
     **/
    function submitVote(
        uint256 _proposalId,
        uint256 _solutionChosen
    ) external onlyOwner {
        address gov = nxmMaster.getLatestAddress("GV");
        IGovernance(gov).submitVote(_proposalId, _solutionChosen);
    }

    /**
     * @dev rescue tokens locked in contract
     * @param token address of token to withdraw
     */
    function rescueToken(address token) external onlyOwner {
        require(
            token != address(nxm) &&
                token != address(wNxm) &&
                token != address(arNxm),
            "Cannot rescue NXM-based tokens"
        );
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);
    }

    function transferERC721Token(
        address to,
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        // owner of this contract should not be able to transfer nxmStakingNFT
        // as stake nft can be traded being able to transfer it may cause centralization
        require(
            tokenAddress != address(stakingNFT),
            "cannot transfer stakingNFT"
        );

        IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
    }

    /*---- Admin functions ----*/

    /**
     * @dev Owner may change how much of the AUM should be saved in reserve each period.
     * @param _reserveAmount The amount of wNXM (in token Wei) to reserve each period.
     **/
    function changeReserveAmount(uint256 _reserveAmount) external onlyOwner {
        reserveAmount = _reserveAmount;
    }

    /**
     * @dev Owner may change the percent of insurance fees referrers receive.
     * @param _referPercent The percent of fees referrers receive. 50 == 5%.
     **/
    function changeReferPercent(uint256 _referPercent) external onlyOwner {
        require(
            _referPercent <= 500,
            "Cannot give referrer more than 50% of rewards."
        );
        referPercent = _referPercent;
    }

    /**
     * @dev Owner may change the withdraw fee.
     * @param _withdrawFee The fee of withdraw.
     **/
    function changeWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(
            _withdrawFee <= DENOMINATOR,
            "Cannot take more than 100% of withdraw"
        );
        withdrawFee = _withdrawFee;
    }

    /**
     * @dev Owner may change the withdraw delay.
     * @param _withdrawDelay Withdraw delay.
     **/
    function changeWithdrawDelay(uint256 _withdrawDelay) external onlyOwner {
        withdrawDelay = _withdrawDelay;
    }

    /**
     * @dev Change the percent of rewards that are given for administration of the contract.
     * @param _adminPercent The percent of rewards to be given for administration (10 == 1%, 1000 == 100%)
     **/
    function changeAdminPercent(uint256 _adminPercent) external onlyOwner {
        require(
            _adminPercent <= 500,
            "Cannot give admin more than 50% of rewards."
        );
        adminPercent = _adminPercent;
    }

    /**
     * @dev Owner may change the amount of time it takes to distribute rewards from Nexus.
     * @param _rewardDuration The amount of time it takes to fully distribute rewards.
     **/
    function changeRewardDuration(uint256 _rewardDuration) external onlyOwner {
        require(
            _rewardDuration <= 30 days,
            "Reward duration cannot be more than 30 days."
        );
        rewardDuration = _rewardDuration;
    }

    /**
     * @dev Owner may change the amount of time that withdrawals are paused after a hack is confirmed.
     * @param _pauseDuration The new amount of time that withdrawals will be paused.
     **/
    function changePauseDuration(uint256 _pauseDuration) external onlyOwner {
        require(
            _pauseDuration <= 30 days,
            "Pause duration cannot be more than 30 days."
        );
        pauseDuration = _pauseDuration;
    }

    /**
     * @dev Change beneficiary of the administration funds.
     * @param _newBeneficiary Address of the new beneficiary to receive funds.
     **/
    function changeBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiary = _newBeneficiary;
    }

    /**
     * @dev remove token id from tokenIds array
     * @param _index Index of the tokenId to remove
     **/
    function removeTokenIdAtIndex(uint256 _index) external onlyOwner {
        uint256 tokenId = tokenIds[_index];
        tokenIds[_index] = tokenIds[tokenIds.length - 1];
        tokenIds.pop();
        // remove mapping to pool
        delete tokenIdToPool[tokenId];
    }

    /**
     * @notice Needed for Nexus to prove this contract lost funds.
     * @param _coverAddress Address that we need to send 0 eth to to confirm we had a loss.
     */
    function proofOfLoss(address payable _coverAddress) external onlyOwner {
        _coverAddress.transfer(0);
    }
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.0;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @dev Based on Solmate https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * @dev We've added a second owner to share control of the timelocked owner contract.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    // Second allows a DAO to share control.
    address private _secondOwner;
    address private _pendingSecond;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SecondOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        _secondOwner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        emit SecondOwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return the address of the owner.
     */
    function secondOwner() public view returns (address) {
        return _secondOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner");
        _;
    }

    modifier onlyFirstOwner() {
        require(msg.sender == _owner, "only owner");
        _;
    }

    modifier onlySecondOwner() {
        require(msg.sender == _secondOwner, "only owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || msg.sender == _secondOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyFirstOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferSecondOwnership(address newOwner) public onlySecondOwner {
        _pendingSecond = newOwner;
    }

    function receiveSecondOwnership() public {
        require(msg.sender == _pendingSecond, "only pending owner");
        _transferSecondOwnership(_pendingSecond);
        _pendingSecond = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferSecondOwnership(address newOwner) internal {
        require(newOwner != address(0), "zero address");
        emit SecondOwnershipTransferred(_secondOwner, newOwner);
        _secondOwner = newOwner;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.17;

// Library imports
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.17;

/**
 * @dev Quick interface for the Nexus Mutual contract to work with the Armor Contracts.
 **/

// to get nexus mutual contract address

// solhint-disable func-name-mixedcase

interface INxmMaster {
    function tokenAddress() external view returns (address);

    function owner() external view returns (address);

    function pauseTime() external view returns (uint);

    function masterInitialized() external view returns (bool);

    function isPause() external view returns (bool check);

    function isMember(address _add) external view returns (bool);

    function getLatestAddress(
        bytes2 _contractName
    ) external view returns (address payable contractAddress);
}

interface IPooledStaking {
    function unstakeRequests(
        uint256 id
    )
        external
        view
        returns (
            uint256 amount,
            uint256 unstakeAt,
            address contractAddress,
            address stakerAddress,
            uint256 next
        );

    function processPendingActions(
        uint256 iterations
    ) external returns (bool success);

    function lastUnstakeRequestId() external view returns (uint256);

    function stakerDeposit(address user) external view returns (uint256);

    function stakerMaxWithdrawable(
        address user
    ) external view returns (uint256);

    function withdrawReward(address user) external;

    function requestUnstake(
        address[] calldata protocols,
        uint256[] calldata amounts,
        uint256 insertAfter
    ) external;

    function depositAndStake(
        uint256 deposit,
        address[] calldata protocols,
        uint256[] calldata amounts
    ) external;

    function stakerContractCount(
        address staker
    ) external view returns (uint256);

    function stakerContractAtIndex(
        address staker,
        uint contractIndex
    ) external view returns (address);

    function stakerContractStake(
        address staker,
        address protocol
    ) external view returns (uint256);

    function stakerContractsArray(
        address staker
    ) external view returns (address[] memory);

    function stakerContractPendingUnstakeTotal(
        address staker,
        address protocol
    ) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function stakerReward(address staker) external view returns (uint256);
}

interface IClaimsData {
    function getClaimStatusNumber(
        uint256 claimId
    ) external view returns (uint256, uint256);

    function getClaimDateUpd(uint256 claimId) external view returns (uint256);
}

interface INXMPool {
    function buyNXM(uint minTokensOut) external payable;
}

interface IGovernance {
    function submitVote(uint256 _proposalId, uint256 _solution) external;
}

interface IQuotation {
    function getWithdrawableCoverNoteCoverIds(
        address owner
    ) external view returns (uint256[] memory, bytes32[] memory);
}

interface IStakingPool {
    function ALLOCATION_UNITS_PER_NXM() external view returns (uint256);

    function BUCKET_DURATION() external view returns (uint256);

    function BUCKET_TRANCHE_GROUP_SIZE() external view returns (uint256);

    function CAPACITY_REDUCTION_DENOMINATOR() external view returns (uint256);

    function COVER_TRANCHE_GROUP_SIZE() external view returns (uint256);

    function GLOBAL_CAPACITY_DENOMINATOR() external view returns (uint256);

    function MAX_ACTIVE_TRANCHES() external view returns (uint256);

    function NXM_PER_ALLOCATION_UNIT() external view returns (uint256);

    function ONE_NXM() external view returns (uint256);

    function POOL_FEE_DENOMINATOR() external view returns (uint256);

    function REWARDS_DENOMINATOR() external view returns (uint256);

    function REWARD_BONUS_PER_TRANCHE_DENOMINATOR()
        external
        view
        returns (uint256);

    function REWARD_BONUS_PER_TRANCHE_RATIO() external view returns (uint256);

    function TRANCHE_DURATION() external view returns (uint256);

    function WEIGHT_DENOMINATOR() external view returns (uint256);

    function implementation() external view returns (address);

    function beacon() external view returns (address);

    function calculateNewRewardShares(
        uint256 initialStakeShares,
        uint256 stakeSharesIncrease,
        uint256 initialTrancheId,
        uint256 newTrancheId,
        uint256 blockTimestamp
    ) external pure returns (uint256);

    function coverContract() external view returns (address);

    function coverTrancheAllocations(uint256) external view returns (uint256);

    function depositTo(
        uint256 amount,
        uint256 trancheId,
        uint256 requestTokenId,
        address destination
    ) external returns (uint256 tokenId);

    function deposits(
        uint256,
        uint256
    )
        external
        view
        returns (
            uint96 lastAccNxmPerRewardShare,
            uint96 pendingRewards,
            uint128 stakeShares,
            uint128 rewardsShares
        );

    function expiringCoverBuckets(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function extendDeposit(
        uint256 tokenId,
        uint256 initialTrancheId,
        uint256 newTrancheId,
        uint256 topUpAmount
    ) external;

    function getAccNxmPerRewardsShare() external view returns (uint256);

    function getActiveAllocations(
        uint256 productId
    ) external view returns (uint256[] memory trancheAllocations);

    function getActiveStake() external view returns (uint256);

    function getActiveTrancheCapacities(
        uint256 productId,
        uint256 globalCapacityRatio,
        uint256 capacityReductionRatio
    )
        external
        view
        returns (uint256[] memory trancheCapacities, uint256 totalCapacity);

    function getDeposit(
        uint256 tokenId,
        uint256 trancheId
    )
        external
        view
        returns (
            uint256 lastAccNxmPerRewardShare,
            uint256 pendingRewards,
            uint256 stakeShares,
            uint256 rewardsShares
        );

    function getExpiredTranche(
        uint256 trancheId
    )
        external
        view
        returns (
            uint256 accNxmPerRewardShareAtExpiry,
            uint256 stakeAmountAtExpiry,
            uint256 stakeSharesSupplyAtExpiry
        );

    function getFirstActiveBucketId() external view returns (uint256);

    function getFirstActiveTrancheId() external view returns (uint256);

    function getLastAccNxmUpdate() external view returns (uint256);

    function getMaxPoolFee() external view returns (uint256);

    function getNextAllocationId() external view returns (uint256);

    function getPoolFee() external view returns (uint256);

    function getPoolId() external view returns (uint256);

    function getRewardPerSecond() external view returns (uint256);

    function getRewardsSharesSupply() external view returns (uint256);

    function getStakeSharesSupply() external view returns (uint256);

    function getTranche(
        uint256 trancheId
    ) external view returns (uint256 stakeShares, uint256 rewardsShares);

    function getTrancheCapacities(
        uint256 productId,
        uint256 firstTrancheId,
        uint256 trancheCount,
        uint256 capacityRatio,
        uint256 reductionRatio
    ) external view returns (uint256[] memory trancheCapacities);

    function initialize(
        bool _isPrivatePool,
        uint256 _initialPoolFee,
        uint256 _maxPoolFee,
        uint256 _poolId,
        string memory ipfsDescriptionHash
    ) external;

    function isHalted() external view returns (bool);

    function isPrivatePool() external view returns (bool);

    function manager() external view returns (address);

    function masterContract() external view returns (address);

    function multicall(
        bytes[] memory data
    ) external returns (bytes[] memory results);

    function nxm() external view returns (address);

    function processExpirations(bool updateUntilCurrentTimestamp) external;

    function rewardPerSecondCut(uint256) external view returns (uint256);

    function setPoolDescription(string memory ipfsDescriptionHash) external;

    function setPoolFee(uint256 newFee) external;

    function setPoolPrivacy(bool _isPrivatePool) external;

    function stakingNFT() external view returns (address);

    function stakingProducts() external view returns (address);

    function tokenController() external view returns (address);

    function trancheAllocationGroups(
        uint256,
        uint256
    ) external view returns (uint256);

    function withdraw(
        uint256 tokenId,
        bool withdrawStake,
        bool withdrawRewards,
        uint256[] memory trancheIds
    ) external returns (uint256 withdrawnStake, uint256 withdrawnRewards);
}

// V2 Interfaces

interface IStakingNFT {
    function approve(address spender, uint256 id) external;

    function balanceOf(address owner) external view returns (uint256);

    function changeNFTDescriptor(address newNFTDescriptor) external;

    function changeOperator(address newOperator) external;

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function isApprovedOrOwner(
        address spender,
        uint256 id
    ) external view returns (bool);

    function mint(uint256 poolId, address to) external returns (uint256 id);

    function name() external view returns (string memory);

    function nftDescriptor() external view returns (address);

    function operator() external view returns (address);

    function ownerOf(uint256 id) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function setApprovalForAll(address spender, bool approved) external;

    function stakingPoolFactory() external view returns (address);

    function stakingPoolOf(
        uint256 tokenId
    ) external view returns (uint256 poolId);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function symbol() external view returns (string memory);

    function tokenInfo(
        uint256 tokenId
    ) external view returns (uint256 poolId, address owner);

    function tokenURI(uint256 id) external view returns (string memory uri);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 id) external;
}

interface INFTDescriptor {
    struct StakeData {
        uint poolId;
        uint stakeAmount;
        uint tokenId;
    }

    function getActiveDeposits(
        uint256 tokenId,
        address stakingPool
    )
        external
        view
        returns (
            string memory depositInfo,
            uint256 totalStake,
            uint256 pendingRewards
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRewardDistributionRecipient.sol";

interface IRewardManager is IRewardDistributionRecipient {
    function initialize(
        address _rewardToken,
        address _stakeController
    ) external;

    function stake(
        address _user,
        address _referral,
        uint256 _coverPrice
    ) external;

    function withdraw(
        address _user,
        address _referral,
        uint256 _coverPrice
    ) external;

    function getReward(address payable _user) external;
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.17;

interface IShieldMining {
    function claimRewards(
        address[] calldata stakedContracts,
        address[] calldata sponsors,
        address[] calldata tokenAddresses
    ) external returns (uint[] memory tokensRewarded);
}

// SPDX-License-Identifier: (c) Ease DAO
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWNXM is IERC20 {
    function wrap(uint256 _amount) external;

    function unwrap(uint256 _amount) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}