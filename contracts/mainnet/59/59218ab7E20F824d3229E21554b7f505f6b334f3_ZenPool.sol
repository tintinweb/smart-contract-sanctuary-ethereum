pragma solidity 0.8.6;

/**
 * @title Jelly Pool V1.3:
 *
 *              ,,,,
 *            [email protected]@@@@@K
 *           [email protected]@@@@@@@P
 *            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
 *             "*NNM"                     [email protected]@@  [email protected]@@
 *                                        [email protected]@@  [email protected]@@
 *             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
 *            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
 *           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
 *           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
 *           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
 *           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
 *            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
 *            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
 *             "[email protected]@@@@@        "**""       '''   '''        @@@Y
 *    ,[email protected]@g    "[email protected]@@P                                     @@@Y
 *   @@@@@@@@p    [email protected]@'                                    @@@Y
 *   @@@@@@@@P    [email protected]                                    RNNY
 *   '[email protected]@@@@@     $P
 *       "[email protected]@@p"'
 *
 *
 */

/**
 * @author ProfWobble
 * @dev
 * - Pool Contract with Staking NFTs:
 *   - Mints NFTs on stake() which represent staked tokens
 *          and claimable rewards in the pool.
 *   - Supports Merkle proofs using the JellyList interface.
 *   - External rewarder logic for multiple pools.
 *   - NFT attributes onchain via the descriptor.
 *
 */

import "IJellyAccessControls.sol";
import "IJellyRewarder.sol";
import "IJellyPool.sol";
import "IJellyContract.sol";
import "IMerkleList.sol";
import "IDescriptor.sol";
import "ILiquidityGauge.sol";
import "IJellyDocuments.sol";
import "SafeERC20.sol";
import "BoringMath.sol";
import "JellyPoolNFT.sol";

interface IMinter {
    function mint(address) external;
    function setMinterApproval(address minter, bool approval) external;
}


contract ZenPool is IJellyPool, IJellyContract, JellyPoolNFT {
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public constant override TEMPLATE_TYPE = 3;
    bytes32 public constant override TEMPLATE_ID = keccak256("ZEN_POOL");
    uint256 public constant pointMultiplier = 10e12;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IJellyAccessControls public accessControls;
    IJellyRewarder public rewardsContract;
    ILiquidityGauge public liquidityGauge;
    IDescriptor public descriptor;
    IJellyDocuments public documents;
    /// @notice Balancer Minter.
    IMinter public bal_minter;

    /// @notice Token to stake.
    address public override poolToken;
    /// @notice Balancer Token.
    address public bal;
    address public owner;
    struct PoolSettings {
        bool tokensClaimable;
        bool useList;
        bool useListAmounts;
        bool initialised;
        bool gaugeDeposit;
        uint256 transferTimeout;
        /// @notice Address that manages approvals.
        address list;
    }
    PoolSettings public poolSettings;

    /// @notice Total tokens staked.
    uint256 public override stakedTokenTotal;

    struct RewardInfo {
        uint48 lastUpdateTime;
        uint208 rewardsPerTokenPoints;
    }

    /// @notice reward token address => rewardsPerTokenPoints
    mapping(address => RewardInfo) public poolRewards;

    address[] public rewardTokens;

    struct TokenRewards {
        uint128 rewardsEarned;
        uint128 rewardsReleased;
        uint48 lastUpdateTime;
        uint208 lastRewardPoints;
    }
    /// @notice Mapping from tokenId => rewards token => reward info.
    mapping(uint256 => mapping(address => TokenRewards)) public tokenRewards;

    struct TokenInfo {
        uint128 staked;
        uint48 lastUpdateTime;
    }
    /// @notice Mapping from tokenId => token info.
    mapping(uint256 => TokenInfo) public tokenInfo;

    struct UserPool {
        uint128 stakeLimit;
    }

    /// @notice user address => pool details
    mapping(address => UserPool) public userPool;

    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event TokensClaimable(bool status);
    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsContractSet(
        address indexed oldRewardsToken,
        address newRewardsToken
    );
    /**
     * @notice Event emmited when a user has staked LPs.
     * @param owner Address of the staker.
     * @param amount Amount staked in LP tokens.
     */
    event Staked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardsClaimed(address indexed user, uint256 reward);
    /**
     * @notice Event emitted when a user has unstaked LPs.
     * @param owner Address of the unstaker.
     * @param amount Amount unstaked in LP tokens.
     */
    event Unstaked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when user unstaked in emergency mode.
     * @param user Address of the user.
     * @param tokenId unstaked tokenId.
     */
    event EmergencyUnstake(address indexed user, uint256 tokenId);
    /**
     * @notice Event emitted when Balancer Gauge whitelist has changed 
     * @param previous Previous status.
     * @param status Current status.
     */
    event GaugeDepositSet(bool previous, bool status);

    event LiquidityGaugeSet(
        address indexed previousGauge,
        address indexed newGauge
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
    }

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }


    //--------------------------------------------------------
    // Pool Config
    //--------------------------------------------------------

    /**
     * @notice Admin can change rewards contract through this function.
     * @param _addr Address of the new rewards contract.
     */
    function setRewardsContract(address _addr) external override {
        require(accessControls.hasAdminRole(msg.sender));
        require(_addr != address(0));
        emit RewardsContractSet(address(rewardsContract), _addr);
        rewardsContract = IJellyRewarder(_addr);
        if (rewardTokens.length > 0 ) {
            for (uint256 i = 0; i < rewardTokens.length ; i++) {
                rewardTokens.pop();
            }
        }
        rewardTokens = rewardsContract.rewardTokens(address(this));
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external override {
        require(accessControls.hasAdminRole(msg.sender));
        emit TokensClaimable(_enabled);
        poolSettings.tokensClaimable = _enabled;
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setGaugeDeposit(bool _enabled) external {
        require(accessControls.hasAdminRole(msg.sender));
        emit GaugeDepositSet(poolSettings.gaugeDeposit, _enabled);
        poolSettings.gaugeDeposit = _enabled;
    }

    /**
     * @notice Admin can set the Balancer gauge contract.
     * @param _gauge Address of the LiquidityGauge contract.
     */
    function setLiquidityGauge(address _gauge) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_gauge != address(0));
        emit LiquidityGaugeSet(address(liquidityGauge), _gauge);
        OZIERC20(poolToken).safeApprove(_gauge, 0);
        OZIERC20(poolToken).safeApprove(_gauge, MAX_INT);
        liquidityGauge = ILiquidityGauge(_gauge);
    }

    /**
     * @notice Admin can set the balancer minter contract.
     * @param _bal_minter Address of the BalancerMinter contract.
     */
    function setBalancerMinter(address _bal_minter) external {
        require(accessControls.hasAdminRole(msg.sender));
        bal_minter = IMinter(_bal_minter);
    }

    /**
     * @notice Set rewards reciever for Liquidity gauge
     * @param _receiver Address of the recipient of rewards.
     */
    function setRewardsReceiver(address _receiver) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_receiver != address(0)); // dev: Address must be non zero
        liquidityGauge.set_rewards_receiver(_receiver);

    }

    /**
     * @notice Set approval for Balancer Minter
     * @param _minter Address allowed to mint for this pool
     */
    function setMinterApproval(address _minter, bool _approval) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_minter != address(0)); // dev: Address must be non zero
        bal_minter.setMinterApproval(_minter, _approval);
    }


    /**
     * @notice Getter function for tokens claimable.
     */
    function tokensClaimable() external view override returns (bool) {
        return poolSettings.tokensClaimable;
    }

    //--------------------------------------------------------
    // Jelly Pool NFTs
    //--------------------------------------------------------

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the admin.
     */
    function setDescriptor(address _descriptor) external {
        require(accessControls.hasAdminRole(msg.sender));
        descriptor = IDescriptor(_descriptor);
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTokenDetails(string memory _name, string memory _symbol)
        external
    {
        require(accessControls.hasAdminRole(msg.sender));
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setNFTAdmin(address _owner) external {
        require(accessControls.hasAdminRole(msg.sender));
        address oldOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(oldOwner, _owner);
    }

    /**
     * @notice Add a delay between updating staked position and a token transfer.
     * @dev Only callable by the admin.
     */
    function setTransferTimeout(uint256 _timeout) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_timeout < block.timestamp);
        poolSettings.transferTimeout = _timeout;
    }

    function getOwnerTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = _ownedTokens[_owner][i];
        }
        return tokenIds;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Non-existent token");
        return descriptor.tokenURI(_tokenId);
    }


    //--------------------------------------------------------
    // Verify
    //--------------------------------------------------------

    /**
     * @notice Whitelisted staking
     * @param _merkleRoot List identifier.
     * @param _index User index.
     * @param _user User address.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.
     */
    function verify(
        bytes32 _merkleRoot,
        uint256 _index,
        address _user,
        uint256 _stakeLimit,
        bytes32[] calldata _data
    ) public nonreentrant {
        UserPool storage _userPool = userPool[_user];
        require(_stakeLimit > 0, "Limit must be > 0");

        if (_stakeLimit > uint256(_userPool.stakeLimit)) {
            uint256 merkleAmount = IMerkleList(poolSettings.list)
                .tokensClaimable(
                    _merkleRoot,
                    _index,
                    _user,
                    _stakeLimit,
                    _data
                );
            require(merkleAmount > 0, "Incorrect merkle proof");
            _userPool.stakeLimit = BoringMath.to128(merkleAmount);
        }
    }

    /**
     * @notice Function for verifying whitelist, staking and minting a Staking NFT
     * @param _amount Number of tokens in merkle proof.
     * @param _merkleRoot Merkle root.
     * @param _index Merkle index.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.

     */
    function verifyAndStake(
        uint256 _amount,
        bytes32 _merkleRoot,
        uint256 _index,
        uint256 _stakeLimit,
        bytes32[] calldata _data
    ) external {
        verify(_merkleRoot, _index, msg.sender, _stakeLimit, _data);
        _stake(msg.sender, _amount);
    }

    //--------------------------------------------------------
    // Stake
    //--------------------------------------------------------

    /**
     * @notice Deposits tokens into the JellyPool and mints a Staking NFT
     * @param _amount Number of tokens deposited into the pool.
     */
    function stake(uint256 _amount) external nonreentrant {
        _stake(msg.sender, _amount);
    }

    /**
     * @notice Internal staking function called by both verifyAndStake() and stake().
     * @param _user Stakers address.
     * @param _amount Number of tokens to deposit.
     */
    function _stake(address _user, uint256 _amount) internal {
        require(_amount > 0, "Amount must be > 0");

        /// @dev If a whitelist is set, this checks user balance.
        if (poolSettings.useList) {
            if (poolSettings.useListAmounts) {
                require(_amount < userPool[_user].stakeLimit);
            } else {
                require(userPool[_user].stakeLimit > 0);
            }
        }

        /// @dev Mints a Staking NFT if the user doesnt already have one.
        if (balanceOf(_user) == 0) {
            // Mints new Staking NFT
            uint256 _tokenId = _safeMint(_user);
            // Sets initial rewards points
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                if (tokenRewards[_tokenId][rewardToken].lastRewardPoints == 0) {
                    tokenRewards[_tokenId][rewardToken]
                        .lastRewardPoints = poolRewards[rewardToken]
                        .rewardsPerTokenPoints;
                }
            }
        }
        /// We always add balance to the users first token.
        uint256 tokenId = _ownedTokens[_user][0];

        /// Updates internal accounting and stakes tokens
        snapshot(tokenId);
        tokenInfo[tokenId] = TokenInfo(
            tokenInfo[tokenId].staked + BoringMath.to128(_amount),
            BoringMath.to48(block.timestamp)
        );
        stakedTokenTotal += BoringMath.to128(_amount);
        OZIERC20(poolToken).safeTransferFrom(
            address(_user),
            address(this),
            _amount
        );

        if (poolSettings.gaugeDeposit) {
            liquidityGauge.deposit(_amount, address(this));
        }

        emit Staked(_user, _amount);
    }

    /**
     * @notice Returns the number of tokens staked for a tokenID.
     * @param _tokenId TokenID to be checked.
     */
    function stakedBalance(uint256 _tokenId)
        external
        view
        override
        returns (uint256)
    {
        return tokenInfo[_tokenId].staked;
    }

    //--------------------------------------------------------
    // Rewards
    //--------------------------------------------------------

    /// @dev Updates the rewards accounting onchain for a specific tokenID.
    function snapshot(uint256 _tokenId) public {
        require(_exists(_tokenId), "Non-existent token");
        IJellyRewarder rewarder = rewardsContract;
        rewarder.updateRewards();
        uint256 sTotal = stakedTokenTotal;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            RewardInfo storage rInfo = poolRewards[rewardTokens[i]];
            /// Get total pool rewards from rewarder
            uint208 currentRewardPoints;
            if (sTotal == 0) {
                currentRewardPoints = rInfo.rewardsPerTokenPoints;
            } else {
                uint256 currentRewards = rewarder.poolRewards(
                    address(this),
                    rewardToken,
                    uint256(rInfo.lastUpdateTime),
                    block.timestamp
                );

                /// Convert to reward points
                currentRewardPoints =
                    rInfo.rewardsPerTokenPoints +
                    BoringMath.to208(
                        (currentRewards * 1e18 * pointMultiplier) / sTotal
                    );
            }
            /// Update reward info
            rInfo.rewardsPerTokenPoints = currentRewardPoints;
            rInfo.lastUpdateTime = BoringMath.to48(block.timestamp);

            _updateTokenRewards(_tokenId, rewardToken, currentRewardPoints);
        }
    }
    
    /// @dev Updates the TokenRewards accounting for a specific tokenID.
    function _updateTokenRewards(
        uint256 _tokenId,
        address _rewardToken,
        uint208 currentRewardPoints
    ) internal {
        TokenRewards storage _tokenRewards = tokenRewards[_tokenId][
            _rewardToken
        ];
        // update token rewards
        _tokenRewards.rewardsEarned += BoringMath.to128(
            (tokenInfo[_tokenId].staked *
                uint256(currentRewardPoints - _tokenRewards.lastRewardPoints)) /
                1e18 /
                pointMultiplier
        );
        // Update token details
        _tokenRewards.lastUpdateTime = BoringMath.to48(block.timestamp);
        _tokenRewards.lastRewardPoints = currentRewardPoints;
    }

    //--------------------------------------------------------
    // Claim
    //--------------------------------------------------------

    /**
     * @notice Claim rewards for all Staking NFTS owned by the sender.
     */
    function claim() external {
        require(poolSettings.tokensClaimable == true, "Not yet claimable");
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                snapshot(tokenIds[i]);
            }
            for (uint256 j = 0; j < rewardTokens.length; j++) {
                _claimRewards(tokenIds, rewardTokens[j], msg.sender);
            }
        }
    }

    /**
     * @notice Claiming rewards on behalf of a token ID.
     * @param _tokenId Token ID.
     */
    function fancyClaim(uint256 _tokenId) public {
        claimRewards(_tokenId, rewardTokens);
    }

    /**
     * @notice Claiming rewards for user for specific rewards.
     * @param _tokenId Token ID.
     */
    function claimRewards(uint256 _tokenId, address[] memory _rewardTokens)
        public 
    {
        require(poolSettings.tokensClaimable == true, "Not yet claimable");
        snapshot(_tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        address recipient = ownerOf(_tokenId);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _claimRewards(tokenIds, _rewardTokens[i], recipient);
        }
    }

    /**
     * @notice Claiming rewards for user.
     * @param _tokenIds Array of Token IDs.
     */
    function _claimRewards(
        uint256[] memory _tokenIds,
        address _rewardToken,
        address _recipient
    ) internal returns(uint256) {
        uint256 payableAmount;
        uint128 rewards;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            TokenRewards storage _tokenRewards = tokenRewards[_tokenIds[i]][
                _rewardToken
            ];
            rewards =
                _tokenRewards.rewardsEarned -
                _tokenRewards.rewardsReleased;
            payableAmount += uint256(rewards);
            _tokenRewards.rewardsReleased += rewards;
        }

        OZIERC20(_rewardToken).safeTransfer(_recipient, payableAmount);
        emit RewardsClaimed(_recipient, payableAmount);
        return payableAmount;
    }

    //--------------------------------------------------------
    // Unstake
    //--------------------------------------------------------
    /**
     * @notice Function for unstaking exact amount of tokens, claims all rewards.
     * @param _amount amount of tokens to unstake.
     */

    function unstake(uint256 _amount) external nonreentrant {
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);
        uint256 unstakeAmount;
        require(tokenIds.length > 0, "Nothing to unstake");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_amount > 0) {
                unstakeAmount = tokenInfo[tokenIds[i]].staked;
                if (unstakeAmount > _amount) {
                    unstakeAmount = _amount;
                }
                _amount = _amount - unstakeAmount;
                fancyClaim(tokenIds[i]);
                _unstake(msg.sender, tokenIds[i], unstakeAmount);
            }
        }
    }

    /**
     * @notice Function for unstaking exact amount of tokens, for a specific NFT token id.
     * @param _tokenId TokenID to be unstaked
     * @param _amount amount of tokens to unstake.
     */
    function unstakeToken(uint256 _tokenId, uint256 _amount) external nonreentrant {
        require(ownerOf(_tokenId) == msg.sender, "Must own tokenId");
        fancyClaim(_tokenId);
        _unstake(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Function that executes the unstaking.
     * @param _user Stakers address.
     * @param _tokenId TokenID to unstake.
     * @param _amount amount of tokens to unstake.
     */
    function _unstake(
        address _user,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        tokenInfo[_tokenId] = TokenInfo(
            tokenInfo[_tokenId].staked - BoringMath.to128(_amount),
            BoringMath.to48(block.timestamp)
        );
        stakedTokenTotal -= BoringMath.to128(_amount);

        if (tokenInfo[_tokenId].staked == 0) {
            delete tokenInfo[_tokenId];
            _burn(_tokenId);
        }

        uint256 tokenBal = OZIERC20(poolToken).balanceOf(address(this));
        if (tokenBal < _amount) {
            uint256 gaugeBal = balanceOfGauge();
            if (gaugeBal >= _amount - tokenBal) {
                liquidityGauge.withdraw(_amount - tokenBal);
            } else if (gaugeBal > 0 ) { 
                liquidityGauge.withdraw(gaugeBal);
                _amount = tokenBal + gaugeBal;
            } else { 
                _amount = tokenBal;
            }
        }
        OZIERC20(poolToken).safeTransfer(address(_user), _amount);
        emit Unstaked(_user, _amount);
    }

    /**
     * @notice Unstake without rewards. EMERGENCY ONLY.
     * @param _tokenId TokenID to unstake.
     */
    function emergencyUnstake(uint256 _tokenId) external  nonreentrant {
        require(ownerOf(_tokenId) == msg.sender, "Must own tokenId");
        _unstake(msg.sender, _tokenId, tokenInfo[_tokenId].staked);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }


    //--------------------------------------------------------
    // Balancer Gauge
    //--------------------------------------------------------
    /**
     * @notice Total mount of staked tokens in the Balancer Gauge
     */
    function balanceOfGauge() public view returns (uint256) {
        return liquidityGauge.balanceOf(address(this));
    }

    /**
     * @notice Claim BAL from Balancer
     * @param _vault Address of the recipient of rewards.
     * @dev Claim BAL for LP token staking from the BAL minter contract
     */
    function claimBal(address _vault) external returns (uint256){
        require(
            accessControls.hasAdminRole(msg.sender),
            "Sender must be admin"
        );
        require(_vault != address(0)); // dev: Address must be non zero
        uint256 balance = 0;

        try bal_minter.mint(address(liquidityGauge)){
            balance = OZIERC20(bal).balanceOf(address(this));
            OZIERC20(bal).safeTransfer(_vault, balance);
        }catch{}

        return balance;
    }

    /**
     * @notice  Withdraw tokens from a gauge to pool save gas on unstake
     * @dev     Only callable by the admin 
     * @param _amount  Amount of tokens to remove from gauge
     */
    function withdrawGauge(uint _amount) external returns(bool){
        require(
            accessControls.hasAdminRole(msg.sender) ,
            "Sender must be admin"
        );
        liquidityGauge.withdraw(_amount);
        return true;
    }


    /**
     * @notice  Deposits tokens from a gauge to pool save user gas on stake
     * @dev     Only callable by the admin 
     * @param _amount  Amount of tokens to remove from gauge
     */
    function depositGauge(uint _amount) external returns(bool){
        require(
            accessControls.hasAdminRole(msg.sender) ,
            "Sender must be admin"
        );
        liquidityGauge.deposit(_amount, address(this));
        return true;
    }


    //--------------------------------------------------------
    // List
    //--------------------------------------------------------
    /**
     * @notice Address used for whitelist if activated
     */
    function list() external view returns (address) {
        return poolSettings.list;
    }

    function setList(address _list) external {
        require(accessControls.hasAdminRole(msg.sender));
        if (_list != address(0)) {
            poolSettings.list = _list;
        }
    }

    function enableList(bool _useList, bool _useListAmounts) public {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.useList = _useList;
        poolSettings.useListAmounts = _useListAmounts;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------
    /**
     * @notice Set the global document store.
     * @dev Only callable by the admin.
     */
    function setDocumentController(address _documents) external {
        require(accessControls.hasAdminRole(msg.sender));
        documents = IJellyDocuments(_documents);
    }
    /**
     * @notice Set the documents in the global store.
     * @dev Only callable by the admin and operator.
     * @param _name Document key.
     * @param _data Document value. Leave blank to remove document
     */
    function setDocument(string calldata _name, string calldata _data)
        external
    {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender));
        if (bytes(_data).length > 0) {
            documents.setDocument(address(this), _name, _data);
        } else {
            documents.removeDocument(address(this), _name);
        }
    }

    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.
     * @param _bal_minter address of Balancer Minter contract.

     */
    function initJellyPool(address _poolToken, address _accessControls, address _bal, address _bal_minter) public {
        require(!poolSettings.initialised);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        bal_minter = IMinter(_bal_minter);
        bal = _bal;
        _entered_state = 1;

        poolSettings.initialised = true;
    }

    function init(bytes calldata _data) external payable override {}

    function initContract(bytes calldata _data) external override {
        (address _poolToken, address _accessControls,  address _bal, address _bal_minter) = abi.decode(
            _data,
            (address, address, address, address)
        );

        initJellyPool(_poolToken, _accessControls, _bal, _bal_minter);
    }
}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

pragma solidity 0.8.6;

interface IJellyRewarder {

    // function setRewards( 
    //     uint256[] memory rewardPeriods, 
    //     uint256[] memory amounts
    // ) external;
    // function setBonus(
    //     uint256 poolId,
    //     uint256[] memory rewardPeriods,
    //     uint256[] memory amounts
    // ) external;
    function updateRewards() external returns(bool);
    // function updateRewards(address _pool) external returns(bool);

    function totalRewards(address _poolAddress) external view returns (uint256 rewards);
    function totalRewards() external view returns (address[] memory, uint256[] memory);
    // function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function poolRewards(address _pool, address _rewardToken, uint256 _from, uint256 _to) external view returns (uint256 rewards);

    function rewardTokens() external view returns (address[] memory rewards);
    function rewardTokens(address _pool) external view returns (address[] memory rewards);

    function poolCount() external view returns (uint256);

    function setPoolPoints(address _poolAddress, uint256 _poolPoints) external;

    function setVault(address _addr) external;
    function addRewardsToPool(
        address _poolAddress,
        address _rewardAddress,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) external ;

}

pragma solidity 0.8.6;

interface IJellyPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function stakedTokenTotal() external view returns(uint256);
    function stakedBalance(uint256 _tokenId) external view returns(uint256);
    function tokensClaimable() external view returns(bool);
    function poolToken() external view returns(address);

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IMerkleList {
    function tokensClaimable(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (bool);
    function tokensClaimable(bytes32 _merkleRoot, uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (uint256);
    function currentMerkleRoot() external view returns (bytes32);
    function currentMerkleURI() external view returns (string memory);
    function initMerkleList(address accessControl) external ;
    function addProof(bytes32 _merkleRoot, string memory _merkleURI) external;
    function updateProof(bytes32 _merkleRoot, string memory _merkleURI) external;
}

pragma solidity 0.8.6;
interface IDescriptor {

    function tokenURI(
        uint256 tokenId
    ) external view returns (string memory);

}

pragma solidity 0.8.6;

interface ILiquidityGauge {
    function deposit(uint256 value, address recipient) external;
    function withdraw(uint256 value) external;
    function claim_rewards(address _addr, address _receiver) external;
    function lp_token() external view returns(address);
    function set_rewards_receiver(address _receiver) external;
    function balanceOf(address account) external view returns (uint256);

}

pragma solidity 0.8.6;

interface IJellyDocuments {
    function setDocument(
        address _contractAddr,
        string calldata _name,
        string calldata _data
    ) external;

    function setDocuments(
        address _contractAddr,
        string[] calldata _name,
        string[] calldata _data
    ) external;

    function removeDocument(address _contractAddr, string calldata _name)
        external;
}

pragma solidity ^0.8.0;

import "OZIERC20.sol";
import "Address.sol";

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
        OZIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        OZIERC20 token,
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
        OZIERC20 token,
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
        OZIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        OZIERC20 token,
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
    function _callOptionalReturn(OZIERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZIERC20 {
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
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "low-level call failed");
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
        return functionCallWithValue(target, data, value, "low-level call with value failed");
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
        require(address(this).balance >= value, "insufficient balance for call");
        require(isContract(target), "call to non-contract");

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
        return functionStaticCall(target, data, "low-level static call failed");
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
        require(isContract(target), "static call to non-contract");

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
        return functionDelegateCall(target, data, "low-level delegate call failed");
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
        require(isContract(target), "delegate call to non-contract");

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

pragma solidity 0.8.6;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        require(a <= type(uint208).max, "BoringMath: uint128 Overflow");
        c = uint208(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to48(uint256 a) internal pure returns (uint48 c) {
        require(a <= type(uint48).max);
        c = uint48(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max);
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max);
        c = uint16(a);
    }

    function to8(uint256 a) internal pure returns (uint8 c) {
        require(a <= type(uint8).max);
        c = uint8(a);
    }

}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath208 {
    function add(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath48 {
    function add(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint8.
library BoringMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.8.6;

import "ERC721SemiNumerable.sol";
import "Counters.sol";


contract JellyPoolNFT is ERC721SemiNumerable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdTracker;

    constructor() ERC721("JellyPool NFT","JPOOL") {

    }

    function _safeMint(address _user) internal returns (uint256){
        uint256 _tokenId = _tokenIdTracker.current();
        _safeMint(_user, _tokenId);
        _tokenIdTracker.increment();
        return _tokenId;
    }

}

pragma solidity ^0.8.0;

import "ERC721.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721SemiNumerable is ERC721 {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "Index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

}

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string internal tokenName;

    // Token symbol
    string internal tokenSymbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        tokenName = name_;
        tokenSymbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0));
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return tokenName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Non-existent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "Approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Non-existent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Non ERC721Receiver");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "Non-existent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "Non ERC721Receiver"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));
        require(!_exists(tokenId));

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "Not owner of token");
        require(to != address(0));

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0);
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}