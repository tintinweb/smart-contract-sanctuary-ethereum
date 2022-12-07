// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyFactory.sol";
import "./ProxyPattern/SolidlyChildImplementation.sol";

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

interface IVeV2 {
    function token() external view returns (address);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface IBaseV2Factory {
    function isPair(address) external view returns (bool);
}

interface IBaseV2Pair {
    function claimFees() external returns (uint256, uint256);

    function tokens() external returns (address, address);
}

interface IBribeV2 {
    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);
}

interface IVoterV2 {
    function attachTokenToGauge(uint256 _tokenId, address account) external;

    function detachTokenFromGauge(uint256 _tokenId, address account) external;

    function generalFees() external view returns (address);

    function emitDeposit(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function emitWithdraw(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function distribute(address _gauge) external;

    function feeDists(address _pool) external view returns (address _feeDist);
}

interface IFeeDistV2 {
    function claimFees() external;
}

interface IBaseV2GeneralFees {
    function notifyRewardAmount(address token, uint256 amount) external;
}

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
/**
 * @dev Changelog:
 *      - Deprecate constructor with initialize()
 *      - Deprecate checkpoint and indexing system, replaced with opt-in multirewards like system
 *      - Uses RewardRatePerWeek instead of RewardRate for reward calculations (better precision)
 *      - Adapt _claimFees() to support transfer tax tokens
 *      - Immutable storage slots became mutable but made sure nothing changes them after initialize()
 */
contract GaugeV2 is SolidlyChildImplementation {
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10**44;
    /**
     * @dev storage slots start here
     */

    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    address public stake; // the LP token that needs to be staked for rewards
    address public _ve; // the ve token used for gauges
    address public solid;
    address public bribe;
    address public voter;

    uint256 public derivedSupply;
    mapping(address => uint128) public derivedBalances;
    mapping(address => uint256) public tokenIds;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public isOptIn; // userAddress => rewardAddress => bool
    mapping(address => address[]) public userOptIns; // array of rewards the user is opted into
    mapping(address => mapping(address => uint256)) public userOptInsIndex; // index of pools within userOptIns userAddress =>rewardAddress => index

    // default snx staking contract implementation
    mapping(address => RewardData) public rewardData;

    struct RewardData {
        uint128 rewardRatePerWeek;
        uint128 derivedSupply;
        uint256 rewardPerTokenStored;
        uint40 periodFinish;
        uint40 lastUpdateTime;
    }
    struct UserRewardData {
        uint256 userRewardPerTokenPaid;
        uint256 userEarnedStored;
    }

    mapping(address => mapping(address => UserRewardData))
        public userRewardData; // userAddress => tokenAddress => userRewardData

    uint256 public totalSupply;

    address[] public rewards;
    mapping(address => bool) public isReward;

    uint256 public fees0;
    uint256 public fees1;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event OptIn(address indexed from, address indexed reward);
    event OptOut(address indexed from, address indexed reward);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClawbackRewards(address indexed reward, uint256 amount);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function initialize(
        address _stake,
        address _bribe,
        address __ve,
        address _voter
    ) external onlyFactory notInitialized {
        _unlocked = 1;
        stake = _stake;
        bribe = _bribe;
        _ve = __ve;
        voter = _voter;
        solid = IVeV2(_ve).token();
    }

    /**************************************** 
                View Methods
    ****************************************/
    /**
     * @notice Returns the balance derived based on veToken staked. Used to determine ratio of rewards streamed
     * @param account User address
     */
    function derivedBalance(address account) public view returns (uint256) {
        uint256 _tokenId = tokenIds[account];
        uint256 _balance = balanceOf[account];
        uint256 _derived = (_balance * 40) / 100;
        uint256 _adjusted = 0;
        uint256 _supply = erc20(_ve).totalSupply();
        if (account == IVeV2(_ve).ownerOf(_tokenId) && _supply > 0) {
            _adjusted = IVeV2(_ve).balanceOfNFT(_tokenId);
            _adjusted = (((totalSupply * _adjusted) / _supply) * 60) / 100;
        }
        return Math.min((_derived + _adjusted), _balance);
    }

    /**
     * @dev ATTENTION ordering is flipped to (token, account) instead of (account, token) for backwards compatibility
     */
    function earned(address token, address account)
        external
        view
        returns (uint256)
    {
        RewardData memory _rewardData = rewardData[token];
        UserRewardData memory _userRewardData = userRewardData[account][token];

        uint256 _earned = _userRewardData.userEarnedStored;
        if (isOptIn[account][token]) {
            _earned += ((derivedBalances[account] *
                (_rewardPerToken(_rewardData) -
                    _userRewardData.userRewardPerTokenPaid)) / PRECISION);
        }
        return _earned;
    }

    /**
     * @notice Internal view method does not call _rewardPerToken() since it's always updated just before this is called
     * @dev ATTENTION input orders are (account, token) to comform with RewardData structures
     */
    function _earnedFromStored(address account, address token)
        internal
        view
        returns (uint256)
    {
        UserRewardData memory _userRewardData = userRewardData[account][token];
        uint256 _earned = (_userRewardData.userEarnedStored) +
            ((derivedBalances[account] *
                (rewardData[token].rewardPerTokenStored -
                    _userRewardData.userRewardPerTokenPaid)) / PRECISION);

        return _earned;
    }

    /**
     * @notice Returns the last time the reward was modified or periodFinish if the reward has ended
     */
    function lastTimeRewardApplicable(address token)
        external
        view
        returns (uint256)
    {
        return Math.min(block.timestamp, rewardData[token].periodFinish);
    }

    /**
     * @notice View method for backwards compatibility
     * @dev Now part of RewardData struct
     * @param token Reward token
     */
    function lastUpdateTime(address token) external view returns (uint256) {
        return rewardData[token].lastUpdateTime;
    }

    /**
     * @notice Returns the amount of rewards left in the reward period
     * @param token Reward token
     */
    function left(address token) external view returns (uint256) {
        RewardData memory _rewardData = rewardData[token];
        if (block.timestamp >= _rewardData.periodFinish) return 0;
        uint256 _remaining = _rewardData.periodFinish - block.timestamp;
        return (_remaining * _rewardData.rewardRatePerWeek) / DURATION;
    }

    /**
     * @notice View method for backwards compatibility
     * @dev Now part of RewardData struct
     * @param token Reward token
     */
    function periodFinish(address token) external view returns (uint256) {
        return rewardData[token].periodFinish;
    }

    /**
     * @notice View method for backwards compatibility
     * @dev Now part of RewardData struct
     * @param token Reward token
     */
    function rewardPerTokenStored(address token)
        external
        view
        returns (uint256)
    {
        return rewardData[token].rewardPerTokenStored;
    }

    /**
     * @notice View method for backwards compatibility
     * @dev rewardRate decprecated in favour of rewardRatePerWeek since DURATION is constant
     * @param token Reward token
     */
    function rewardRate(address token) external view returns (uint256) {
        return rewardData[token].rewardRatePerWeek / DURATION;
    }

    /**
     * @notice Returns the rewardsList length
     */
    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    /**
     * @notice Backwards compatible wiew method for rewardPerToken
     * @param token Reward token
     */
    function rewardPerToken(address token) external view returns (uint256) {
        RewardData memory _rewardData = rewardData[token];

        return _rewardPerToken(_rewardData);
    }

    /**
     * @notice view method for rewardPerToken
     * @dev passing RewardData instead of tokenAddress to save gas on SLOAD
     * @param _rewardData RewardData struct for the reward token
     */
    function _rewardPerToken(RewardData memory _rewardData)
        internal
        view
        returns (uint256)
    {
        if (_rewardData.derivedSupply == 0) {
            return _rewardData.rewardPerTokenStored;
        }

        uint256 timeElapsed = (Math.min(
            block.timestamp,
            _rewardData.periodFinish
        ) - Math.min(_rewardData.lastUpdateTime, _rewardData.periodFinish));

        return
            _rewardData.rewardPerTokenStored +
            uint256(
                ((((PRECISION / DURATION) * _rewardData.rewardRatePerWeek) /
                    _rewardData.derivedSupply) * timeElapsed)
            );
    }

    /**
     * @notice Backwards compatible wiew method for userRewardPerTokenStored
     * @dev ATTENTION input ordering is (token, account) for backwards compatibility
     * @param token Reward token
     * @param account User address
     */
    function userRewardPerTokenStored(address token, address account)
        external
        view
        returns (uint256)
    {
        return userRewardData[account][token].userRewardPerTokenPaid;
    }

    /**************************************** 
                Protocol Interaction
    ****************************************/
    /**
     * @notice Calls the feeDist to claimFees from the pair
     * @dev Kept for backwards compatibility
     */
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        // Fetch addresses
        address _feeDist = IVoterV2(voter).feeDists(stake);

        address[] memory tokens = new address[](2);
        (tokens[0], tokens[1]) = IBaseV2Pair(stake).tokens();

        // Fetch current status
        uint256[] memory balancesBefore = new uint256[](2);
        balancesBefore[0] = erc20(tokens[0]).balanceOf(_feeDist);
        balancesBefore[1] = erc20(tokens[1]).balanceOf(_feeDist);

        // Call feeDist to claim fees
        IFeeDistV2(_feeDist).claimFees();

        // Compute claimed amounts
        claimed0 = erc20(tokens[0]).balanceOf(_feeDist) - balancesBefore[0];
        claimed1 = erc20(tokens[1]).balanceOf(_feeDist) - balancesBefore[1];

        return (claimed0, claimed1);
    }

    /**************************************** 
                User Interaction
    ****************************************/

    modifier updateReward(address account) {
        uint128 _derivedBalance = derivedBalances[account];
        uint256 _balanceOf = balanceOf[account];
        for (uint256 i; i < userOptIns[account].length; i++) {
            address token = userOptIns[account][i];
            RewardData memory _rewardData = rewardData[token]; // gas savings

            _rewardData.rewardPerTokenStored = _rewardPerToken(_rewardData);
            _rewardData.lastUpdateTime = uint40(
                Math.min(block.timestamp, _rewardData.periodFinish)
            );
            // reduce derivedBalance for opted in pools, readjust them later
            rewardData[token] = _rewardData;

            UserRewardData memory _userRewardData = userRewardData[account][
                token
            ];
            uint256 _earnedBefore = _userRewardData.userEarnedStored;
            uint256 _earnedAfter = _earnedFromStored(account, token);

            // only update userRewardPerTokenPaid if earned goes up,
            // but if derivedBalance changes, update regardless (code at the end of modifier)
            if (_earnedAfter > _earnedBefore) {
                userRewardData[account][token].userEarnedStored = _earnedAfter;
                userRewardData[account][token]
                    .userRewardPerTokenPaid = rewardData[token]
                    .rewardPerTokenStored;
            }
        }

        _;

        // update balance
        uint128 _derivedBalanceBefore = _derivedBalance;
        uint256 _derivedSupply = derivedSupply;
        _derivedSupply -= _derivedBalanceBefore;
        _derivedBalance = uint128(derivedBalance(account));
        derivedBalances[account] = _derivedBalance;
        _derivedSupply += _derivedBalance;
        derivedSupply = _derivedSupply;

        // Update derivedBalances for the opted-in pools
        for (uint256 i; i < userOptIns[account].length; i++) {
            address token = userOptIns[account][i];
            uint128 _derivedSupply = rewardData[token].derivedSupply;
            _derivedSupply -= _derivedBalanceBefore;
            _derivedSupply += _derivedBalance;
            rewardData[token].derivedSupply = _derivedSupply;
        }

        // update userRewardPerTokenPaid anyways if derivedBalance changes
        if (_derivedBalanceBefore != _derivedBalance) {
            for (uint256 i; i < userOptIns[account].length; i++) {
                address token = userOptIns[account][i];
                userRewardData[account][token]
                    .userRewardPerTokenPaid = rewardData[token]
                    .rewardPerTokenStored;
            }
        }
    }

    /**
     * @notice Deposits all LP tokens into the gauge, opts into solid pool by default if not already opted-in
     * @param tokenId The veNFT tokenId to associate with the user
     */
    function depositAll(uint256 tokenId) external {
        deposit(erc20(stake).balanceOf(msg.sender), tokenId);
    }

    /**
     * @notice Deposits LP tokens into the gauge, opts into solid pool by default if not already opted-in
     * @param amount Amount to deposit
     * @param tokenId The veNFT tokenId to associate with the user
     */
    function deposit(uint256 amount, uint256 tokenId) public {
        address _solid = solid;

        // opt-in to solid and the 2 base tokens if not already opted into solid
        if (!isOptIn[msg.sender][_solid]) {
            address[] memory _optInPools = new address[](3);
            (address _token0, address _token1) = IBaseV2Pair(stake).tokens();
            _optInPools[0] = _solid;
            _optInPools[1] = _token0;
            _optInPools[2] = _token1;
            depositAndOptIn(amount, tokenId, _optInPools);
        } else {
            depositAndOptIn(amount, tokenId, new address[](0));
        }
    }

    /**
     * @notice Deposits LP tokens into the gauge, opts into pools specified if not already opted-in
     * @param amount Amount to deposit
     * @param tokenId The veNFT tokenId to associate with the user
     * @param optInPools The reward pools to opt-in to
     */
    function depositAndOptIn(
        uint256 amount,
        uint256 tokenId,
        address[] memory optInPools
    ) public lock updateReward(msg.sender) {
        require(amount > 0, "Cannot deposit 0");

        _safeTransferFrom(stake, msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        if (tokenId > 0) {
            require(IVeV2(_ve).ownerOf(tokenId) == msg.sender, "tokenId auth");
            if (tokenIds[msg.sender] == 0) {
                tokenIds[msg.sender] = tokenId;
                IVoterV2(voter).attachTokenToGauge(tokenId, msg.sender);
            }
            require(
                tokenIds[msg.sender] == tokenId,
                "Different tokenId already attached"
            );
        } else {
            tokenId = tokenIds[msg.sender];
        }

        for (uint256 i = 0; i < optInPools.length; i++) {
            if (!isOptIn[msg.sender][optInPools[i]]) {
                _optIn(optInPools[i]);
            }
        }

        IVoterV2(voter).emitDeposit(tokenId, msg.sender, amount);
        emit Deposit(msg.sender, tokenId, amount);
    }

    /**
     * @notice Opt-in to the specified reward pools
     * @dev Updates reward pools before hand because this is like a balance change for the pool
     * @param tokens The reward pools to opt-in to
     */
    function optIn(address[] calldata tokens)
        external
        lock
        updateReward(msg.sender)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            // Taking out checks for isReward allows people to opt-into pools before they start,
            // which might be benefitial if projects announce rewards in advance,
            // makes things fairer too.
            if (!isOptIn[msg.sender][tokens[i]]) {
                _optIn(tokens[i]);
            }
        }
    }

    /**
     * @notice Internal function for optIn()
     * @param token The reward pool to opt-in to
     */
    function _optIn(address token) internal {
        RewardData memory _rewardData = rewardData[token];

        UserRewardData memory _userRewardData = UserRewardData({
            userRewardPerTokenPaid: _rewardData.rewardPerTokenStored,
            userEarnedStored: 0
        });
        userRewardData[msg.sender][token] = _userRewardData;
        isOptIn[msg.sender][token] = true;
        userOptInsIndex[msg.sender][token] = userOptIns[msg.sender].length;

        rewardData[token].derivedSupply += derivedBalances[msg.sender];

        userOptIns[msg.sender].push(token);

        emit OptIn(msg.sender, token);
    }

    /**
     * @notice Opt-out of the specified reward pools
     * @dev This method updates the reward pools beforehand, storing all user earned amounts for later claiming
     * @param tokens The reward pools to opt-out of
     */
    function optOut(address[] calldata tokens)
        external
        lock
        updateReward(msg.sender)
    {
        // Actually doesn't really matter if the user has unclaimed rewards
        // since it updates all rewards in the modifier and users can claim
        // stored rewards even after opting out
        for (uint256 i = 0; i < tokens.length; i++) {
            if (isOptIn[msg.sender][tokens[i]]) {
                _optOut(tokens[i]);
            }
        }
    }

    /**
     * @notice skips updateReward(). Forfeits all unstored accrued rewards for the selected pools. Only useful when a user enters too many pools
     */
    function emergencyOptOut(address[] calldata tokens) external lock {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint128 _derivedBalance = derivedBalances[msg.sender];
            if (isOptIn[msg.sender][tokens[i]]) {
                rewardData[tokens[i]].derivedSupply -= _derivedBalance;
                _optOut(tokens[i]);
            }
        }
    }

    /**
     * @notice Internal function for optOut() and emergencyOptOut()
     * @param token The reward pool to opt-in to
     */
    function _optOut(address token) internal {
        isOptIn[msg.sender][token] = false;
        uint256 index = userOptInsIndex[msg.sender][token];
        delete userOptInsIndex[msg.sender][token]; // Delete index for tokenId

        // Fetch last opt-in in array
        address lastOptIn = userOptIns[msg.sender][
            userOptIns[msg.sender].length - 1
        ];

        userOptIns[msg.sender][index] = lastOptIn; // Update userOptIns
        userOptInsIndex[msg.sender][lastOptIn] = index; // Update index by token ID
        userOptIns[msg.sender].pop(); // Remove last userOptIn

        emit OptOut(msg.sender, token);
    }

    function withdrawAll() external {
        withdraw(balanceOf[msg.sender]);
    }

    /**
     * @notice Withdraws LP tokens, and detaches veNFT from the gauge final balance becomes 0
     * @param amount The amount of LP to withdraw
     */
    function withdraw(uint256 amount) public {
        uint256 tokenId = 0;
        if (amount == balanceOf[msg.sender]) {
            tokenId = tokenIds[msg.sender];
        }
        withdrawToken(amount, tokenId);
    }

    /**
     * @notice Withdraws LP tokens, and detaches veNFT from the gauge if specified
     * @param amount The amount of LP to withdraw
     * @param tokenId The veNFT to detach, input 0 to skip detachment
     */
    function withdrawToken(uint256 amount, uint256 tokenId)
        public
        lock
        updateReward(msg.sender)
    {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);

        if (tokenId > 0) {
            require(tokenId == tokenIds[msg.sender], "tokenId auth");
            tokenIds[msg.sender] = 0;
            IVoterV2(voter).detachTokenFromGauge(tokenId, msg.sender);
        } else {
            tokenId = tokenIds[msg.sender];
        }

        IVoterV2(voter).emitWithdraw(tokenId, msg.sender, amount);
        emit Withdraw(msg.sender, tokenId, amount);
    }

    function getReward(address account, address[] memory tokens)
        external
        lock
        updateReward(account)
    {
        require(
            msg.sender == account || msg.sender == voter,
            "msg.sender not account"
        );
        _unlocked = 1;
        IVoterV2(voter).distribute(address(this));
        _unlocked = 2;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 _reward = userRewardData[account][tokens[i]]
                .userEarnedStored;

            if (_reward > 0) {
                // only need to look at stored amounts because updateReward() is called beforehand
                userRewardData[account][tokens[i]].userEarnedStored = 0;

                _safeTransfer(tokens[i], account, _reward);
            }

            emit ClaimRewards(msg.sender, tokens[i], _reward);
        }
    }

    function notifyRewardAmount(address token, uint256 amount) external lock {
        require(token != stake, "Invalid reward token");
        require(amount > 0, "Cannot notify 0");
        require(amount < type(uint128).max, "too much amount");
        uint128 amount = uint128(amount);

        RewardData memory _rewardData = rewardData[token]; // gas savings

        // update pool first
        _rewardData.rewardPerTokenStored = _rewardPerToken(_rewardData);
        _rewardData.lastUpdateTime = uint40(
            Math.min(block.timestamp, _rewardData.periodFinish)
        );

        // fetch current balance
        uint256 balanceBefore = erc20(token).balanceOf(address(this));

        // transfer tokens, recalculate amount in case of transfer-tax
        _safeTransferFrom(token, msg.sender, address(this), amount);
        amount = uint128(erc20(token).balanceOf(address(this)) - balanceBefore);

        if (block.timestamp >= _rewardData.periodFinish) {
            _rewardData.rewardRatePerWeek = amount;
        } else {
            uint40 _remaining = _rewardData.periodFinish -
                uint40(block.timestamp);
            uint128 _left = uint128(
                (_remaining * _rewardData.rewardRatePerWeek) / DURATION
            );
            require(amount > _left || msg.sender == voter, "amount < left");
            _rewardData.rewardRatePerWeek = amount + _left;
        }
        require(_rewardData.rewardRatePerWeek > 0, "rewardRate too low");
        uint256 balance = erc20(token).balanceOf(address(this));
        require(
            _rewardData.rewardRatePerWeek <= balance,
            "Not enough tokens provided"
        );
        _rewardData.periodFinish = uint40(block.timestamp + DURATION);
        _rewardData.lastUpdateTime = uint40(block.timestamp);

        rewardData[token] = _rewardData;
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }

        emit NotifyReward(msg.sender, token, amount);
    }

    // Be VERY CAREFUL when using this, gauge does not track how much reward
    // is supposed to be in the contract, since it'll take too much gas
    // to record balance changes on every interaction just for the next to
    // 0 possibility that this function is used
    // Off-chain calculations should be double-checked before using this function
    function clawbackRewards(address token, uint256 amount)
        external
        onlyGovernance
    {
        require(token != stake, "Cannot clawback LP");

        require(amount > 0, "Cannot clawback 0");
        address generalFeesAddress = IVoterV2(voter).generalFees();

        // Approve amount and notifyReward for generalFees
        _safeApprove(token, generalFeesAddress, amount);
        IBaseV2GeneralFees(generalFeesAddress).notifyRewardAmount(
            token,
            amount
        );

        emit ClawbackRewards(token, amount);
    }

    /****************************************
                    SafeERC20
     ****************************************/

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransfer low-level call failed"
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransferFrom low-level call failed"
        );
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.approve.selector, spender, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: approve low-level call failed"
        );
    }
}

/**
 * @dev Changelog:
 *      - Deprecate createGaugeSingle()
 *      - Deprecate last_gauge;
 *      - Refactored createGauge();
 */
contract BaseV2GaugeFactory is SolidlyFactory {
    function createGauge(
        address _pool,
        address _bribe,
        address _ve
    ) external returns (address lastGauge) {
        lastGauge = _deployChildProxy();
        GaugeV2(lastGauge).initialize(_pool, _bribe, _ve, msg.sender);
        return lastGauge;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFactory {
    function governanceAddress() external view returns (address);

    function childSubImplementationAddress() external view returns (address);

    function childInterfaceAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./interfaces/IFactory.sol";

contract SolidlyChildImplementation is SolidlyImplementation {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyProxy.sol";
import "./interfaces/IFactory.sol";

/**
 * @notice Child Proxy deployed by factories for pairs, fees, gauges, and bribes. Calls back to the factory to fetch proxy implementation.
 */
contract SolidlyChildProxy is SolidlyProxy {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /**
     * @notice Records factory address and current interface implementation
     */
    constructor() {
        address _factory = msg.sender;
        address _interface = IFactory(msg.sender).childInterfaceAddress();
        assembly {
            sstore(FACTORY_SLOT, _factory)
            sstore(IMPLEMENTATION_SLOT, _interface) // Storing the interface into EIP-1967's implementation slot so Etherscan picks up the interface
        }
    }

    /****************************************
                    SETTINGS
     ****************************************/

    /**
     * @notice Governance callable method to update the Factory address
     */
    function updateFactoryAddress(address _factory) external onlyGovernance {
        assembly {
            sstore(FACTORY_SLOT, _factory)
        }
    }

    /**
     * @notice Publically callable function to sync proxy interface with the one recorded in the factory
     */
    function updateInterfaceAddress() external {
        address _newInterfaceAddress = IFactory(factoryAddress())
            .childInterfaceAddress();
        require(
            implementationAddress() != _newInterfaceAddress,
            "Nothing to update"
        );
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newInterfaceAddress)
        }
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }

    /**
     *@notice Fetch address where actual contract logic is at
     */
    function subImplementationAddress()
        public
        view
        returns (address _subimplementation)
    {
        return IFactory(factoryAddress()).childSubImplementationAddress();
    }

    /**
     * @notice Fetch address where the interface for the contract is
     */
    function interfaceAddress()
        public
        view
        override
        returns (address _interface)
    {
        assembly {
            _interface := sload(IMPLEMENTATION_SLOT)
        }
    }

    /****************************************
                  FALLBACK METHODS 
     ****************************************/

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal override {
        address contractLogic = IFactory(factoryAddress())
            .childSubImplementationAddress();
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    fallback() external payable override {
        _delegateCallSubimplmentation();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./SolidlyChildProxy.sol";

contract SolidlyFactory is SolidlyImplementation {
    bytes32 constant CHILD_SUBIMPLEMENTATION_SLOT =
        0xa7461aa7cde97eb2572f8234e341359c6baae47e1feeb3c235edffe5f0fc089d; // keccak256('CHILD_SUBIMPLEMENTATION') - 1
    bytes32 constant CHILD_INTERFACE_SLOT =
        0x23762bb6469fe7a7bd6609262f442817ed09ca1f07add24ef069610d59c90649; // keccak256('CHILD_INTERFACE') - 1
    bytes32 constant SUBIMPLEMENTATION_SLOT =
        0xa1056f3ed783ff191ada02861fcb19d9ae3a8f50b739813a127951ef5290458d; // keccak256('SUBIMPLEMENTATION') - 1
    bytes32 constant INTERFACE_SLOT =
        0x4a9bf2931aa5eae439c602abae4bd662e7919244decac463e2e35fc862c5fb98; // keccak256('INTERFACE') - 1

    address public interfaceSourceAddress;

    function _deployChildProxy() internal returns (address) {
        address addr = address(new SolidlyChildProxy());

        return addr;
    }

    function _deployChildProxyWithSalt(bytes32 salt)
        internal
        returns (address)
    {
        address addr = address(new SolidlyChildProxy{salt: salt}());

        return addr;
    }

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external onlyGovernance {
        assembly {
            sstore(CHILD_SUBIMPLEMENTATION_SLOT, _childSubImplementationAddress)
        }
    }

    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(CHILD_INTERFACE_SLOT, _childInterfaceAddress)
        }
    }

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {
        assembly {
            _childSubImplementation := sload(CHILD_SUBIMPLEMENTATION_SLOT)
        }
    }

    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {
        assembly {
            _childInterface := sload(CHILD_INTERFACE_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL
pragma solidity 0.8.11;

/**
 * @title Solidly+ governance killable proxy
 * @author Solidly+
 * @notice EIP-1967 upgradeable proxy with the ability to kill governance and render the contract immutable
 */
contract SolidlyProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation'), actually used for interface so etherscan picks up the interface
    bytes32 constant LOGIC_SLOT =
        0x5942be825425c77e56e4bce97986794ab0f100954e40fc1390ae0e003710a3ab; // keccak256('LOGIC') - 1, actual logic implementation
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev Used by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)
        }
        _;
    }

    /**
     * @notice Sets up deployer as a proxy governance
     */
    constructor() {
        address _governanceAddress = msg.sender;
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Detect whether or not governance is killed
     * @return Return true if governance is killed, false if not
     * @dev If governance is killed this contract becomes immutable
     */
    function governanceIsKilled() public view returns (bool) {
        return governanceAddress() == address(0);
    }

    /**
     * @notice Kill governance, making this contract immutable
     * @dev Only governance can kil governance
     */
    function killGovernance() external onlyGovernance {
        updateGovernanceAddress(address(0));
    }

    /**
     * @notice Update implementation address
     * @param _interfaceAddress Address of the new interface
     * @dev Only governance can update implementation
     */
    function updateInterfaceAddress(address _interfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _interfaceAddress)
        }
    }

    /**
     * @notice Actually updates interface, kept for etherscan pattern recognition
     * @param _implementationAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateImplementationAddress(address _implementationAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    /**
     * @notice Update implementation address
     * @param _logicAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateLogicAddress(address _logicAddress) external onlyGovernance {
        assembly {
            sstore(LOGIC_SLOT, _logicAddress)
        }
    }

    /**
     * @notice Update governance address
     * @param _governanceAddress New governance address
     * @dev Only governance can update governance
     */
    function updateGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _implementationAddress Returns the current implementation address
     */
    function implementationAddress()
        public
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _interfaceAddress Returns the current implementation address
     */
    function interfaceAddress()
        public
        view
        virtual
        returns (address _interfaceAddress)
    {
        assembly {
            _interfaceAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _logicAddress Returns the current implementation address
     */
    function logicAddress()
        public
        view
        virtual
        returns (address _logicAddress)
    {
        assembly {
            _logicAddress := sload(LOGIC_SLOT)
        }
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal virtual {
        assembly {
            let contractLogic := sload(LOGIC_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    /**
     * @notice Delegatecall fallback proxy
     */
    fallback() external payable virtual {
        _delegateCallSubimplmentation();
    }

    receive() external payable virtual {
        _delegateCallSubimplmentation();
    }
}