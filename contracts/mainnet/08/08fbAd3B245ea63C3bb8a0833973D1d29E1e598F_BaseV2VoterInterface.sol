// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

contract BaseV2VoterInterface {
    address public _ve; // the ve token that governs these contracts
    address public factory; // the BaseV2Factory
    address public gaugeFactory;
    address public bribeFactory;
    address public minter;
    address public generalFees;

    uint256 public activePeriod;
    mapping(uint256 => uint256) public periodTotalWeight; // period => total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(address => mapping(uint256 => int256)) public periodWeights; // pool => period => weight
    mapping(address => mapping(uint256 => bool)) public periodUpdated; //whether pool has updated for this period pool => activePeriod => periodUpdated
    mapping(uint256 => mapping(uint256 => mapping(address => int256)))
        public periodVotes; // nft => period => pool => votes
    mapping(uint256 => mapping(uint256 => address[])) public periodPoolVote; // nft => period => pools
    mapping(uint256 => mapping(uint256 => uint256)) public periodUsedWeights; // nft => period => total voting weight of user
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    bool public trainingWheels;
    uint256 public listingFeeRatio;

    // Gauge reward tracking
    mapping(uint256 => uint256) public rewards; // period => rewards
    mapping(address => uint256) public claimable; // gauge => claimable

    event Abstained(
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Deposit(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );
    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        address indexed pool,
        int256 weight
    );
    event Whitelisted(address indexed whitelister, address indexed token);
    event Withdraw(
        address indexed lp,
        address indexed gauge,
        uint256 tokenId,
        uint256 amount
    );

    function attachTokenToGauge(uint256 tokenId, address account) external {}

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {}

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external {}

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external
    {}

    function createGauge(address _pool) external returns (address) {}

    function detachTokenFromGauge(uint256 tokenId, address account) external {}

    function distribute(address[] memory _gauges) external {}

    function distribute(address _gauge) external {}

    function distribute(uint256 start, uint256 finish) external {}

    function distribute() external {}

    function distribute(address _gauge, uint256 _activePeriod) external {}

    function distributeFees(address[] memory _gauges) external {}

    function distro() external {}

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {}

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function governanceWhitelist(address[] memory _tokens) external {}

    function governanceBlacklist(address[] memory _tokens) external {}

    function initialize(
        address __ve,
        address _factory,
        address _gauges,
        address _bribes,
        address _generalFees,
        address _minter
    ) external {}

    function length() external view returns (uint256) {}

    function listing_fee() external view returns (uint256) {}

    function notifyRewardAmount(uint256 amount) external {}

    function poolVote(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {}

    function poolVote(uint256 tokenId, uint256 index)
        external
        view
        returns (address)
    {}

    function reset(uint256 _tokenId) external {}

    function setListingFeeRatio(uint256 _listingFeeRatio) external {}

    function setTrainingWheels(bool _status) external {}

    function syncActivePeriod() external returns (uint256) {}

    function totalWeight() external view returns (uint256) {}

    function updateAll() external {}

    function updateFor(address[] memory _gauges) external {}

    function updateForRange(uint256 start, uint256 end) external {}

    function updateGauge(address _gauge) external {}

    function updateGauge(address _gauge, uint256 _activePeriod) external {}

    function usedWeights(uint256 tokenId) external view returns (uint256) {}

    function vote(
        uint256 tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) external {}

    function votes(uint256 tokenId, address pool)
        external
        view
        returns (int256)
    {}

    function weights(address pool) external view returns (int256) {}

    function whitelist(address _token, uint256 _tokenId) external {}
}