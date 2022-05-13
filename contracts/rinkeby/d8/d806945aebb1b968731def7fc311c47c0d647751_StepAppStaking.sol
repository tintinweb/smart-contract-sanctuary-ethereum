// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./ERC20.sol";

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

contract StepAppStaking is Ownable, ERC20 {
    /// @dev Max base points
    uint256 public constant MAX_BPS = 1e4;

    /// @dev Max penalty days
    uint256 private constant PENALTY_DAYS_LIMIT = 90;

    /// @dev Max penalty base points
    uint256 private constant PENALTY_BP_LIMIT = 0.5 * 1e4;

    /// @dev Staking token
    IERC20 public stakingToken;

    /// @dev Info about each stake by user address
    mapping(address => Stake[]) public stakers;

    /// @dev Penalty days value
    uint16 public penaltyDays;

    /// @dev Penalty base points value
    uint16 public penaltyBP;

    /// @dev The address to which the penalty tokens will be transferred
    address public treasury;

    /// @dev Total shares
    uint192 public totalShares;

    /// @dev Share bonus base points value for 1M staked tokens
    uint32 public shareBonusBPPer1MTokens;

    struct Stake {
        bool unstaked;
        uint128 amount;
        uint48 stakedTimestamp;
        uint16 penaltyDays;
        uint16 penaltyBP;
        uint192 shares;
    }

    event Staked(
        address indexed staker,
        uint256 indexed stakeIndex,
        uint128 amount,
        uint48 stakedTimestamp,
        uint16 penaltyDays,
        uint16 penaltyBP,
        uint128 totalSupply,
        uint192 shares,
        uint192 totalShares
    );

    event Unstaked(
        address indexed staker,
        uint256 indexed stakeIndex,
        uint128 amount,
        uint128 penaltyAmount,
        uint128 totalSupply,
        uint192 shares,
        uint192 totalShares
    );

    event SetPenaltyDays(uint16 penaltyDays);
    event SetPenaltyBP(uint16 penaltyBP);
    event SetTreasury(address treasury);
    event SetShareBonusBPPer1MTokens(uint32 shareBonusBPPer1MTokens);

    constructor() ERC20("XXX", "XXX") {}

    function initialize(
        IERC20 _stakingToken,
        uint16 _penaltyDays,
        uint16 _penaltyBP,
        address _treasury,
        uint32 _shareBonusBPPer1MTokens
    ) external virtual {
        require(
            address(_stakingToken) != address(0),
            "StepAppStaking: staking token is the zero address"
        );
        require(
            _penaltyDays <= PENALTY_DAYS_LIMIT,
            "StepAppStaking: penalty days exceeds limit"
        );
        require(
            _penaltyBP <= PENALTY_BP_LIMIT,
            "StepAppStaking: penalty BP exceeds limit"
        );
        require(
            _treasury != address(0),
            "StepAppStaking: treasury is the zero address"
        );

        stakingToken = _stakingToken;
        penaltyDays = _penaltyDays;
        penaltyBP = _penaltyBP;
        treasury = _treasury;
        shareBonusBPPer1MTokens = _shareBonusBPPer1MTokens;
    }

    /**
     * @notice Stake staking tokens
     * @param _amount amount to stake
     */
    function stake(uint128 _amount) external {
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);

        uint192 shares = calculateShares(_amount);
        totalShares += shares;
        stakers[msg.sender].push(
            Stake(
                false,
                _amount,
                uint48(block.timestamp),
                penaltyDays,
                penaltyBP,
                shares
            )
        );

        uint256 stakeIndex = stakers[msg.sender].length - 1;
        emit Staked(
            msg.sender,
            stakeIndex,
            _amount,
            uint48(block.timestamp),
            penaltyDays,
            penaltyBP,
            uint128(totalSupply()),
            shares,
            totalShares
        );
    }

    /**
     * @notice Unstake staking tokens
     * @notice If penalty period is not over grab penalty
     * @param _stakeIndex Stake index in array of user's stakes
     */
    function unstake(uint256 _stakeIndex) external {
        require(
            _stakeIndex < stakers[msg.sender].length,
            "StepAppStaking: invalid index"
        );
        Stake storage stakeRef = stakers[msg.sender][_stakeIndex];
        require(!stakeRef.unstaked, "StepAppStaking: unstaked already");

        _burn(msg.sender, stakeRef.amount);
        totalShares -= stakeRef.shares;
        stakeRef.unstaked = true;

        // pays a penalty if unstakes during the penalty period
        uint256 penaltyAmount = 0;
        if (
            stakeRef.stakedTimestamp + uint48(stakeRef.penaltyDays) * 86400 >
            block.timestamp
        ) {
            penaltyAmount = (stakeRef.amount * stakeRef.penaltyBP) / MAX_BPS;
            stakingToken.transfer(treasury, penaltyAmount);
        }

        stakingToken.transfer(msg.sender, stakeRef.amount - penaltyAmount);

        emit Unstaked(
            msg.sender,
            _stakeIndex,
            stakeRef.amount,
            uint128(penaltyAmount),
            uint128(totalSupply()),
            stakeRef.shares,
            totalShares
        );
    }

    /**
     * @notice Return a length of stake's array by user address
     * @param _stakerAddress User address
     */
    function stakerStakeCount(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return stakers[_stakerAddress].length;
    }

    /**
     * @notice Return shares for the staked amount
     * @dev Share bonus percentage doubles every 1M tokens for the entire amount. Value of 18 for token decimals
     * @param _amount Amount to calculate
     * @return shares Calculated shares for this amount
     */
    function calculateShares(uint256 _amount)
        public
        view
        returns (uint192 shares)
    {
        uint256 stakingMoreBonus = (_amount *
            _amount *
            shareBonusBPPer1MTokens) /
            1e24 /
            MAX_BPS;
        shares = uint192(_amount + stakingMoreBonus);
    }

    // ** ONLY OWNER **

    /**
     * @notice Set a new penalty days value
     * @param _penaltyDays New penalty days value
     */
    function setPenaltyDays(uint16 _penaltyDays) external onlyOwner {
        require(
            _penaltyDays <= PENALTY_DAYS_LIMIT,
            "StepAppStaking: penalty days exceeds limit"
        );
        penaltyDays = _penaltyDays;
        emit SetPenaltyDays(_penaltyDays);
    }

    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
        require(
            _penaltyBP <= PENALTY_BP_LIMIT,
            "StepAppStaking: penalty BP exceeds limit"
        );
        penaltyBP = _penaltyBP;
        emit SetPenaltyBP(_penaltyBP);
    }

    /**
     * @notice Set a new penalty treasury
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "StepAppStaking: treasury is the zero address"
        );
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /**
     * @notice Set a share bonus base points value for 1M staked tokens
     * @param _shareBonusBPPer1MTokens New share bonus base points value for 1M staked tokens
     */
    function setShareBonusBPPer1MTokens(uint32 _shareBonusBPPer1MTokens)
        external
        onlyOwner
    {
        shareBonusBPPer1MTokens = _shareBonusBPPer1MTokens;
        emit SetShareBonusBPPer1MTokens(_shareBonusBPPer1MTokens);
    }

    // ** INTERNAL **

    /// @dev disable transfers
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        revert("StepAppStaking: NON_TRANSFERABLE");
    }
}