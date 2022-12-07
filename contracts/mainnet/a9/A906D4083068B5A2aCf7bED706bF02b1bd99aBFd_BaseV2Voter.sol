// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyImplementation.sol";

library Math {
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

    function isDelegateOrOwner(address, uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;
}

interface IBaseV2Factory {
    function isPair(address) external view returns (bool);
}

interface IBaseV2Core {
    function claimFees() external returns (uint256, uint256);

    function tokens() external returns (address, address);
}

interface IBaseV2GaugeFactory {
    function createGauge(
        address,
        address,
        address
    ) external returns (address);
}

interface IBaseV2BribeFactory {
    function createBribe() external returns (address);
}

interface IBaseV2FeeDistFactory {
    function createFeeDist(address _pool)
        external
        returns (address lastFeeDist);
}

interface IGaugeV2 {
    function notifyRewardAmount(address token, uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function left(address token) external view returns (uint256);
}

interface IBribeV2 {
    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens)
        external;
}

interface IFeeDistV2 {
    function getRewardForOwner(uint256 tokenId, address[] memory tokens)
        external;
}

interface IMinterV2 {
    function update_period() external returns (uint256);

    function active_period() external view returns (uint256);
}

/**
 * @dev Changelog:
 *      - Deprecate constructor with initialize()
 *      - rename original initialize() -> initializeMinter()
 *      - Immutable storage slots became mutable but made sure nothing changes them after initialize()
 *      - Storage for generalFees
 *      - Votes reset weekly, storage slots for period (weekly) states
 *      - Backwards compatible view methods defaults to displaying states for current period
 */
contract BaseV2Voter is SolidlyImplementation {
    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days

    /**
     * @dev storage slots start here
     */
    address public _ve; // the ve token that governs these contracts
    address public factory; // the BaseV2Factory
    address internal base;
    address public gaugeFactory;
    address public bribeFactory;
    address public feeDistFactory;
    address public minter;
    address public generalFees;

    uint256 public activePeriod;
    mapping(uint256 => uint256) public periodTotalWeight; // period => total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => address) public feeDists; // pool => feeDist
    mapping(address => mapping(uint256 => int256)) public periodWeights; // pool => period => weight
    mapping(address => mapping(uint256 => bool)) public periodUpdated; //whether pool has updated for this period pool => activePeriod => periodUpdated
    mapping(uint256 => mapping(uint256 => mapping(address => int256)))
        public periodVotes; // nft => period => pool => votes
    mapping(uint256 => mapping(uint256 => address[])) public periodPoolVote; // nft => period => pools
    mapping(uint256 => mapping(uint256 => uint256)) public periodUsedWeights; // nft => period => total voting weight of user
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;
    bool public trainingWheels;
    uint256 public listingFeeRatio;

    // Gauge reward tracking
    mapping(uint256 => uint256) public rewards; // period => rewards
    mapping(address => uint256) public claimable; // gauge => claimable

    uint256 internal _unlocked = 1; // simple re-entrancy check

    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Abstained(
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Deposit(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );
    event Withdraw(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );
    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);
    event Blacklisted(address indexed blacklister, address indexed token);

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    // Replaces constructor
    function initialize(
        address __ve,
        address _factory,
        address _gaugesFactory,
        address _bribesFactory,
        address _feeDistFactory,
        address _generalFees,
        address _minter
    ) external onlyGovernance notInitialized {
        _unlocked = 1;
        _ve = __ve;
        factory = _factory;
        base = IVeV2(__ve).token();
        gaugeFactory = _gaugesFactory;
        bribeFactory = _bribesFactory;
        feeDistFactory = _feeDistFactory;
        generalFees = _generalFees;
        minter = _minter;
        trainingWheels = true;
        listingFeeRatio = 50;
        activePeriod = (block.timestamp / DURATION) * DURATION;
    }

    /**************************************** 
                Authorized Methods
     ****************************************/

    function setTrainingWheels(bool _status) external onlyGovernance {
        trainingWheels = _status;
    }

    function setListingFeeRatio(uint256 _listingFeeRatio)
        external
        onlyGovernance
    {
        listingFeeRatio = _listingFeeRatio;
    }

    function governanceWhitelist(address[] memory _tokens)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (isBlacklisted[_tokens[i]]) isBlacklisted[_tokens[i]] = false; // Governance whitelisting overrides blacklists
            _whitelist(_tokens[i]);
        }
    }

    function governanceBlacklist(address[] memory _tokens)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _blacklist(_tokens[i]);
        }
    }

    /**************************************** 
                    View Methods
     ****************************************/
    function listing_fee() public view returns (uint256) {
        return
            ((erc20(base).totalSupply() - erc20(_ve).totalSupply()) *
                listingFeeRatio) / 10000;
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function totalWeight() external view returns (uint256) {
        return periodTotalWeight[activePeriod];
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function weights(address pool) external view returns (int256) {
        return periodWeights[pool][activePeriod];
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function votes(uint256 tokenId, address pool)
        external
        view
        returns (int256)
    {
        return periodVotes[tokenId][activePeriod][pool];
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function poolVote(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {
        return periodPoolVote[tokenId][activePeriod];
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function poolVote(uint256 tokenId, uint256 index)
        external
        view
        returns (address)
    {
        return periodPoolVote[tokenId][activePeriod][index];
    }

    /**
     * @notice Backwards-compatible view method, reports state for current active period
     */
    function usedWeights(uint256 tokenId) external view returns (uint256) {
        return periodUsedWeights[tokenId][activePeriod];
    }

    /**************************************** 
                User Interaction
     ****************************************/

    function syncActivePeriod() public returns (uint256) {
        uint256 _activePeriod = activePeriod;

        if (block.timestamp >= _activePeriod + DURATION) {
            uint256 _minterActivePeriod = IMinterV2(minter).active_period();
            if (_activePeriod != _minterActivePeriod) {
                _activePeriod = _minterActivePeriod;
                activePeriod = _activePeriod;
            }
        }
        return _activePeriod;
    }

    function reset(uint256 _tokenId) external {
        require(
            IVeV2(_ve).isApprovedOrOwner(msg.sender, _tokenId),
            "tokenId auth"
        );
        _reset(_tokenId);
    }

    function _reset(uint256 _tokenId) internal {
        uint256 _activePeriod = syncActivePeriod();
        address[] storage _poolVote = periodPoolVote[_tokenId][_activePeriod];
        uint256 _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            int256 _votes = periodVotes[_tokenId][_activePeriod][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                periodWeights[_pool][_activePeriod] -= _votes;
                periodVotes[_tokenId][_activePeriod][_pool] -= _votes;
                if (_votes > 0) {
                    IBribeV2(bribes[gauges[_pool]])._withdraw(
                        uint256(_votes),
                        _tokenId
                    );
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _pool, _votes);
            }
        }
        periodTotalWeight[_activePeriod] -= uint256(_totalWeight);
        periodUsedWeights[_tokenId][_activePeriod] = 0;
        delete periodPoolVote[_tokenId][_activePeriod];
    }

    function _vote(
        uint256 _tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) internal {
        _reset(_tokenId);
        uint256 _activePeriod = syncActivePeriod();

        uint256 _poolCnt = _poolVote.length;
        int256 _weight = int256(IVeV2(_ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            /**
             * @dev Only record votes if:
             *      - The pool has a gauge
             *      - The vote is positive
             *      - The pool is still whitelisted
             *      Skip otherwise, to not disrupt convex layers with reverts
             */
            if (isGauge[_gauge] && _weights[i] > 0 && isWhitelisted[_pool]) {
                int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(
                    periodVotes[_tokenId][_activePeriod][_pool] == 0,
                    "Double vote"
                );
                require(_poolWeight != 0, "Vote rounded to 0");
                _updateFor(_gauge);

                periodPoolVote[_tokenId][_activePeriod].push(_pool);

                periodWeights[_pool][_activePeriod] += _poolWeight;
                periodVotes[_tokenId][_activePeriod][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IBribeV2(bribes[_gauge])._deposit(
                        uint256(_poolWeight),
                        _tokenId
                    );
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _pool, _poolWeight);
            }
        }
        periodTotalWeight[_activePeriod] += uint256(_totalWeight);
        periodUsedWeights[_tokenId][_activePeriod] = uint256(_usedWeight);
    }

    function vote(
        uint256 tokenId,
        address[] calldata _poolVote,
        int256[] calldata _weights
    ) external {
        require(
            IVeV2(_ve).isDelegateOrOwner(msg.sender, tokenId),
            "tokenId auth"
        );
        require(_poolVote.length == _weights.length, "Vote length mismatch");
        _vote(tokenId, _poolVote, _weights);
    }

    function whitelist(address _token, uint256 _tokenId) public {
        if (trainingWheels) {
            revert("Whitelisting not open yet");
        }
        if (_tokenId > 0) {
            require(msg.sender == IVeV2(_ve).ownerOf(_tokenId), "tokenId auth");
            require(
                IVeV2(_ve).balanceOfNFT(_tokenId) > listing_fee(),
                "Insuffient SOLID"
            );
        } else {
            _safeTransferFrom(base, msg.sender, minter, listing_fee());
        }

        _whitelist(_token);
    }

    /**
     * @notice Whitelists a pair
     * @dev This allows gauge creation for a pair
     *      However, you cannot whitelist blacklisted pairs
     *      unless it's with governanceWhitelist()
     */
    function _whitelist(address _token) internal {
        require(!isBlacklisted[_token], "Blacklisted"); // The public cannot re-whitelist blacklisted tokens
        require(!isWhitelisted[_token], "Already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    /**
     * @notice Blacklists a pair
     * @dev This prevents the pair from being voted on or whitelisted again,
     *      it also allows pre-emptive blacklisting
     */
    function _blacklist(address _token) internal {
        require(!isBlacklisted[_token], "Already blacklisted");
        isBlacklisted[_token] = true;
        if (isWhitelisted[_token]) isWhitelisted[_token] = false; // Revoke whitelisted status
        emit Blacklisted(msg.sender, _token);
    }

    function createGauge(address _pool) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(IBaseV2Factory(factory).isPair(_pool), "!_pool");
        (address tokenA, address tokenB) = IBaseV2Core(_pool).tokens();
        require(
            isWhitelisted[tokenA] &&
                isWhitelisted[tokenB] &&
                isWhitelisted[_pool],
            "!whitelisted"
        );
        address _bribe = IBaseV2BribeFactory(bribeFactory).createBribe();
        address _gauge = IBaseV2GaugeFactory(gaugeFactory).createGauge(
            _pool,
            _bribe,
            _ve
        );
        address _feeDist = IBaseV2FeeDistFactory(feeDistFactory).createFeeDist(
            _pool
        );

        erc20(base).approve(_gauge, type(uint256).max);
        bribes[_gauge] = _bribe;
        gauges[_pool] = _gauge;
        feeDists[_pool] = _feeDist;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
        return _gauge;
    }

    function attachTokenToGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender], "Not Gauge");
        if (tokenId > 0) IVeV2(_ve).attach(tokenId);
        emit Attach(account, msg.sender, tokenId);
    }

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {
        require(isGauge[msg.sender], "Not Gauge");
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function detachTokenFromGauge(uint256 tokenId, address account) external {
        require(isGauge[msg.sender], "Not Gauge");
        if (tokenId > 0) IVeV2(_ve).detach(tokenId);
        emit Detach(account, msg.sender, tokenId);
    }

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {
        require(isGauge[msg.sender], "Not Gauge");
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint256) {
        return pools.length;
    }

    function notifyRewardAmount(uint256 amount) external {
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in

        rewards[activePeriod] += amount;
        syncActivePeriod();

        emit NotifyReward(msg.sender, base, amount);
    }

    function updateFor(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    function updateForRange(uint256 start, uint256 end) public {
        for (uint256 i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    function updateAll() external {
        updateForRange(0, pools.length);
    }

    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function updateGauge(address _gauge, uint256 _activePeriod) external {
        _updateFor(_gauge, _activePeriod);
    }

    // By default update reward for latest confirmed period, which is last period
    function _updateFor(address _gauge) internal {
        _updateFor(_gauge, syncActivePeriod() - DURATION);
    }

    function _updateFor(address _gauge, uint256 _period) internal {
        // return without state changes if _period isn't finalized
        if (_period > syncActivePeriod() - DURATION) {
            return;
        }
        // require(
        //     _period <= syncActivePeriod() - DURATION,
        //     "Only confirmed periods"
        // );

        address _pool = poolForGauge[_gauge];
        bool _periodUpdated = periodUpdated[_pool][_period];

        if (!_periodUpdated) {
            // Record updated
            periodUpdated[_pool][_period] = true;

            uint256 _rewards = rewards[_period];
            int256 _supplied = periodWeights[_pool][_period];
            uint256 _totalWeight = periodTotalWeight[_period];

            // Calulate slice of reward for the period
            if (_supplied > 0) {
                uint256 _share = (_rewards * uint256(_supplied) * 1e18) /
                    _totalWeight /
                    1e18;

                claimable[_gauge] += _share;
            }
        } else {
            return;
        }
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external
    {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGaugeV2(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {
        require(
            IVeV2(_ve).isApprovedOrOwner(msg.sender, _tokenId),
            "tokenId auth"
        );
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribeV2(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {
        require(
            IVeV2(_ve).isApprovedOrOwner(msg.sender, _tokenId),
            "tokenId auth"
        );
        for (uint256 i = 0; i < _fees.length; i++) {
            IFeeDistV2(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function distributeFees(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGaugeV2(_gauges[i]).claimFees();
        }
    }

    function distribute(address _gauge, uint256 _activePeriod) public lock {
        IMinterV2(minter).update_period();

        _updateFor(_gauge, _activePeriod);

        uint256 _claimable = claimable[_gauge];
        if (_claimable > 0) {
            claimable[_gauge] = 0;
            erc20(base).approve(_gauge, _claimable);
            IGaugeV2(_gauge).notifyRewardAmount(base, _claimable);
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    // By default distribute latest confirmed week
    function distribute(address _gauge) public {
        distribute(_gauge, syncActivePeriod() - DURATION);
    }

    function distro() external {
        distribute(0, pools.length);
    }

    function distribute() external {
        distribute(0, pools.length);
    }

    function distribute(uint256 start, uint256 finish) public {
        for (uint256 x = start; x < finish; x++) {
            distribute(gauges[pools[x]]);
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint256 x = 0; x < _gauges.length; x++) {
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "Token address not contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransfer low-level call failed"
        );
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