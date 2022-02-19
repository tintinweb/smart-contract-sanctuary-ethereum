/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

library CastU256U32 {
    /// @dev Safely cast an uint256 to an u32
    function u32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;

        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.

        // MINOR CHANGE HERE:

        // previous code
        // uint256 cs;
        // assembly { cs := extcodesize(address) }
        // return cs == 0;

        // current code
        address _self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(_self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public virtual initializer {
        _owner = sender;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public virtual initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

interface IProviderPair {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function sync() external;

    function token0() external;
}

contract RUSDFraction is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using CastU256U32 for uint256;
    using CastU256U128 for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    event LogrewardstokenUpdated(IERC20 rewardedToken);
    event LogDeveloperAddress(address developer);
    event LogLiquidityAddress(address liquiditypool);
    event LogDeveloperfee(uint256 developerpercent);
    event Logliquidityfee(uint256 liquidityfee);
    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsPerTokenUpdated(uint256 accumulated);
    event UserRewardsUpdated(
        address user,
        uint256 userRewards,
        uint256 paidRewardPerToken
    );
    event Claimed(address receiver, uint256 claimed);

    enum RewardStatus {
        NOT_ADDED,
        PENDING,
        APPROVED,
        REJECTED
    }

    struct RewardsPeriod {
        uint32 start; // Start time for the current rewardsToken schedule
        uint32 end; // End time for the current rewardsToken schedule
    }

    struct RewardsPerToken {
        uint128 accumulated; // Accumulated rewards per token for the period, scaled up by 1e18
        uint32 lastUpdated; // Last time the rewards per token accumulator was updated
        uint96 rate; // Wei rewarded per second among all token holders
    }

    struct UserRewards {
        uint128 accumulated; // Accumulated rewards for the user until the checkpoint
        uint128 checkpoint; // RewardsPerToken the last time the user rewards were updated
    }

    struct TempRewardDetail {
        address tokenOwner;
        uint32 start;
        uint32 end;
        uint256 rate;
    }

    // RewardsPeriod public rewardsPeriod;                 // Period in which rewards are accumulated by users

    RewardsPerToken public rewardsPerToken; // Accumulator to track rewards per token
    mapping(address => mapping(IERC20 => UserRewards)) public rewards; // Rewards accumulated by users
    mapping(IERC20 => RewardStatus) public rewardStatus;
    mapping(IERC20 => RewardsPerToken) public rewardsTokenDetail;
    mapping(IERC20 => RewardsPeriod) public rewardsPeriod;
    mapping(IERC20 => TempRewardDetail) public tempRewardDetails;
    mapping(address => uint256) gaslessClaimTimestamp;

    /// @dev Return the earliest of two timestamps
    function earliest(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = (x < y) ? x : y;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 public gaslessClaimPeriod;
    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRACTIONS_SUPPLY =
        50 * 10**6 * 10**DECIMALS; // 50 million
    IERC20[] public rewardPool;
    IERC20[] public pendingPool;
    IERC20 public defaultReward;

    // TOTAL_FRAC is a multiple of INITIAL_FRACTIONS_SUPPLY so that _fracsPerRUSD is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_FRAC =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRACTIONS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_FRAC + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1

    address public monetaryPolicy;
    IProviderPair[] public providerPairs;
    IERC20 public rewardsToken;
    address public developer;
    address public liquiditypool;
    uint256 public developerpercent;
    uint256 public liquidityfee;
    uint256 public buybackpool;
    uint256 public buybackcontract;
    uint256 public sellbackpool;
    uint256 public sellbackcontract;
    address public reflectoAdd;
    address public poolAddress;
    uint256 private _totalSupply;
    uint256 private _fracsPerRUSD;
    uint256 public MAX_REWARD_POOL;

    mapping(address => uint256) private _fracBalances;

    // This is denominated in fractions, because the fracs-fractions conversion might change before
    // it's fully paid.
    mapping(address => mapping(address => uint256)) private _allowedFractions;

    // EIP-2612: permit – 712-signed approvals
    // https://eips.ethereum.org/EIPS/eip-2612
    string public constant EIP712_REVISION = "1";
    bytes32 public constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // EIP-2612: keeps track of number of permits per address
    mapping(address => uint256) private _nonces;

    function setMonetaryPolicy(address monetaryPolicy_) external onlyOwner {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }

    function setRewardsToken(IERC20 rewardsToken_) external onlyOwner {
        rewardsToken = rewardsToken_;
        emit LogrewardstokenUpdated(rewardsToken_);
    }

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy);
        _;
    }

    function setClaimPeriod(uint256 gaslessClaimPeriod_) external onlyOwner {
        gaslessClaimPeriod = gaslessClaimPeriod_;
    }

    function setDeveloperAddress(address developer_) external onlyOwner {
        developer = developer_;
        emit LogDeveloperAddress(developer_);
    }

    function setliquiditypool(address liquiditypool_) external onlyOwner {
        liquiditypool = liquiditypool_;
        emit LogLiquidityAddress(liquiditypool_);
    }

    function setDeveloperpercent(uint256 percent_) external onlyOwner {
        developerpercent = percent_;
        emit LogDeveloperfee(percent_);
    }

    function setMaxRewardPoolLength(uint256 _maxRewardPool) external onlyOwner{
        MAX_REWARD_POOL= _maxRewardPool;
    }

    function setDefaultToken(IERC20 _defaultToken) external onlyOwner {
        defaultReward = _defaultToken;
        rewardPool.push(defaultReward);
        rewardStatus[defaultReward] = RewardStatus.APPROVED;
    }

    function setliquiditypercent(uint256 liquidityfee_) external onlyOwner {
        liquidityfee = liquidityfee_;
        emit Logliquidityfee(liquidityfee_);
    }

    function setreflectoPoolAddress(address poolAddress_) external onlyOwner {
        poolAddress = poolAddress_;
    }

    function setreflectoContractAddress(address reflectoAdd_)
        external
        onlyOwner
    {
        reflectoAdd = reflectoAdd_;
    }

    function setbuysellfee(
        uint256 buybackpool_,
        uint256 buybackcontract_,
        uint256 sellbackpool_,
        uint256 sellbackcontract_
    ) external onlyOwner {
        buybackpool = buybackpool_;
        buybackcontract = buybackcontract_;
        sellbackpool = sellbackpool_;
        sellbackcontract = sellbackcontract_;
    }

    // function setBuyBackPool(uint256 buybackpool_) external onlyOwner {
    //     buybackpool = buybackpool_;
    // }

    // function setBuyBackContract(uint256 buybackcontract_) external onlyOwner {
    //     buybackcontract = buybackcontract_;
    // }

    // function setSellBackPool(uint256 sellbackpool_) external onlyOwner {
    //     sellbackpool = sellbackpool_;
    // }

    // function setsellBackContract(uint256 sellbackcontract_) external onlyOwner {
    //     sellbackcontract = sellbackcontract_;
    // }

    function addProviderPair(IProviderPair _providerPair) external onlyOwner {
        require(providerPairs.length <= 20, "cannot add more than 20");
        providerPairs.push(_providerPair);
    }

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMonetaryPolicy
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            // reduce the supply
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            // add to the supply
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _fracsPerRUSD = TOTAL_FRAC.div(_totalSupply);
        // The applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_FRAC - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_FRAC.div(_fracsPerRUSD)
        _updateRewardsPerToken();
        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function initialize(address owner_) public override initializer {
        ERC20Detailed.initialize("ReflectUSD", "RUSD", uint8(DECIMALS));
        Ownable.initialize(owner_);
        MAX_REWARD_POOL=5;
        gaslessClaimPeriod = 86400; // Gasless Claim once every 1 day
        developerpercent = 10; //0.1%
        liquidityfee = 300; //3%
        buybackpool = 25; //0.25%
        buybackcontract = 25; //0.25%
        sellbackpool = 25; //0.25%
        sellbackcontract = 25; //0.25%
        MAX_REWARD_POOL = 130;
        _totalSupply = INITIAL_FRACTIONS_SUPPLY; // 50m
        _fracBalances[owner_] = TOTAL_FRAC; // 50m
        _fracsPerRUSD = TOTAL_FRAC.div(_totalSupply); // how many fracs make up 1 Fraction
        emit Transfer(address(0x0), owner_, _totalSupply);
    }

    /**
     * @return The total number of Fractions.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external view override returns (uint256) {
        return _fracBalances[who].div(_fracsPerRUSD);
    }

    /**
     * @param who The address to query.
     * @return The fracs balance of the specified address.
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _fracBalances[who];
    }

    /**
     * @return the total number of fracs.
     */
    function scaledTotalSupply() external pure returns (uint256) {
        return TOTAL_FRAC;
    }

    /**
     * @return The number of successful permits by the specified address.
     */
    function nonces(address who) public view returns (uint256) {
        return _nonces[who];
    }

    /**
     * @return The computed DOMAIN_SEPARATOR to be used off-chain services
     *         which implement EIP-712.
     *         https://eips.ethereum.org/EIPS/eip-2612
     **/
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(name())),
                    keccak256(bytes(EIP712_REVISION)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _updateRewardsPerToken();
        _updateUserRewards(msg.sender);
        _updateUserRewards(to);
        uint256 fracValue = value.mul(_fracsPerRUSD);
        _fracBalances[msg.sender] = _fracBalances[msg.sender].sub(fracValue);
        uint256 fracDeveloper = (fracValue.mul(developerpercent)).div(10000);
        uint256 fracLiquidity = (fracValue.mul(liquidityfee)).div(10000);
        uint256 fracTo;
        uint256 poolFee;
        uint256 contractFee;

        if (providerPairs.length > 0) {
            for (uint8 i = 0; i < providerPairs.length; i++) {
                if (to == address(providerPairs[i])) {
                    poolFee = (fracValue.mul(sellbackpool)).div(10000);
                    contractFee = (fracValue.mul(sellbackcontract)).div(10000);
                    _fracBalances[poolAddress] = _fracBalances[poolAddress].add(
                        poolFee
                    );
                    _fracBalances[reflectoAdd] = _fracBalances[reflectoAdd].add(
                        contractFee
                    );
                    fracTo = fracValue.sub(
                        fracDeveloper.add(fracLiquidity).add(poolFee).add(
                            contractFee
                        )
                    );
                } else if (msg.sender == address(providerPairs[i])) {
                    poolFee = (fracValue.mul(buybackpool)).div(10000);
                    contractFee = (fracValue.mul(buybackcontract)).div(10000);
                    _fracBalances[poolAddress] = _fracBalances[poolAddress].add(
                        poolFee
                    );
                    _fracBalances[reflectoAdd] = _fracBalances[reflectoAdd].add(
                        contractFee
                    );
                    fracTo = fracValue.sub(
                        fracDeveloper.add(fracLiquidity).add(poolFee).add(
                            contractFee
                        )
                    );
                } else {
                    fracTo = fracValue.sub(fracDeveloper.add(fracLiquidity));
                }
            }
        } else {
            fracTo = fracValue.sub(fracDeveloper.add(fracLiquidity));
        }
        _fracBalances[developer] = _fracBalances[developer].add(fracDeveloper);
        _fracBalances[liquiditypool] = _fracBalances[liquiditypool].add(
            fracLiquidity
        );
        _fracBalances[to] = _fracBalances[to].add(fracTo);

        emit Transfer(msg.sender, to, fracTo.div(_fracsPerRUSD));
        emit Transfer(msg.sender, developer, fracDeveloper.div(_fracsPerRUSD));
        emit Transfer(
            msg.sender,
            liquiditypool,
            fracLiquidity.div(_fracsPerRUSD)
        );
        emit Transfer(msg.sender, poolAddress, poolFee.div(_fracsPerRUSD));
        emit Transfer(msg.sender, reflectoAdd, contractFee.div(_fracsPerRUSD));
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFractions[owner_][spender];
    }

    /**x
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        // update first
        _updateRewardsPerToken();
        _updateUserRewards(from);
        _updateUserRewards(to);

        _allowedFractions[from][msg.sender] = _allowedFractions[from][
            msg.sender
        ].sub(value);

        uint256 fracValue = value.mul(_fracsPerRUSD);
        uint256 fracDeveloper = (fracValue.mul(developerpercent)).div(10000);
        uint256 fracLiquidity = (fracValue.mul(liquidityfee)).div(10000);
        _fracBalances[from] = _fracBalances[from].sub(fracValue);
        uint256 fracTo;
        uint256 poolFee;
        uint256 contractFee;

        if (providerPairs.length > 0) {
            for (uint8 i = 0; i < providerPairs.length; i++) {
                if (to == address(providerPairs[i])) {
                    poolFee = (fracValue.mul(sellbackpool)).div(10000);
                    contractFee = (fracValue.mul(sellbackcontract)).div(10000);
                    _fracBalances[poolAddress] = _fracBalances[poolAddress].add(
                        poolFee
                    );
                    _fracBalances[reflectoAdd] = _fracBalances[reflectoAdd].add(
                        contractFee
                    );
                    fracTo = fracValue.sub(
                        fracDeveloper.add(fracLiquidity).add(poolFee).add(
                            contractFee
                        )
                    );
                } else if (from == address(providerPairs[i])) {
                    poolFee = (fracValue.mul(buybackpool)).div(10000);
                    contractFee = (fracValue.mul(buybackcontract)).div(10000);
                    _fracBalances[poolAddress] = _fracBalances[poolAddress].add(
                        poolFee
                    );
                    _fracBalances[reflectoAdd] = _fracBalances[reflectoAdd].add(
                        contractFee
                    );
                    fracTo = fracValue.sub(
                        fracDeveloper.add(fracLiquidity).add(poolFee).add(
                            contractFee
                        )
                    );
                } else {
                    fracTo = fracValue.sub(fracDeveloper.add(fracLiquidity));
                }
            }
        } else {
            fracTo = fracValue.sub(fracDeveloper.add(fracLiquidity));
        }

        _fracBalances[developer] = _fracBalances[developer].add(fracDeveloper);
        _fracBalances[liquiditypool] = _fracBalances[liquiditypool].add(
            fracLiquidity
        );
        _fracBalances[to] = _fracBalances[to].add(fracTo);

        emit Transfer(from, to, fracTo.div(_fracsPerRUSD));
        emit Transfer(from, developer, fracDeveloper.div(_fracsPerRUSD));
        emit Transfer(from, liquiditypool, fracLiquidity.div(_fracsPerRUSD));
        emit Transfer(from, poolAddress, poolFee.div(_fracsPerRUSD));
        emit Transfer(from, reflectoAdd, contractFee.div(_fracsPerRUSD));
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _allowedFractions[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFractions[msg.sender][spender] = _allowedFractions[msg.sender][
            spender
        ].add(addedValue);

        emit Approval(
            msg.sender,
            spender,
            _allowedFractions[msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFractions[msg.sender][spender];
        _allowedFractions[msg.sender][spender] = (subtractedValue >= oldValue)
            ? 0
            : oldValue.sub(subtractedValue);

        emit Approval(
            msg.sender,
            spender,
            _allowedFractions[msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Allows for approvals to be made via secp256k1 signatures.
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline);

        uint256 ownerNonce = _nonces[owner];
        bytes32 permitDataDigest = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                ownerNonce,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), permitDataDigest)
        );

        require(owner == ecrecover(digest, v, r, s));

        _nonces[owner] = ownerNonce.add(1);

        _allowedFractions[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /*-------------------------------- Rewards ------------------------------------*/

    /// @dev Set a rewards schedule
    function setDefaultReward(
        uint32 start,
        uint32 end,
        uint96 rate
    ) external onlyOwner {
        require(start < end, "Incorrect input");
        // A new rewards program can be set if one is not running
        require(
            block.timestamp.u32() < rewardsPeriod[defaultReward].start ||
                block.timestamp.u32() > rewardsPeriod[defaultReward].end,
            "Ongoing rewards"
        );
        require(
            rewardStatus[defaultReward] == RewardStatus.APPROVED,
            "this token is not approved reward"
        );
        rewardsPeriod[defaultReward].start = uint32(block.timestamp) + start;
        rewardsPeriod[defaultReward].end = uint32(block.timestamp) + end;

        // If setting up a new rewards program, the rewardsPerToken.accumulated is used and built upon
        // New rewards start accumulating from the new rewards program start
        // Any unaccounted rewards from last program can still be added to the user rewards
        // Any unclaimed rewards can still be claimed
        rewardsTokenDetail[defaultReward].lastUpdated =
            uint32(block.timestamp) +
            start;
        rewardsTokenDetail[defaultReward].rate = rate;

        emit RewardsSet(start, end, rate);
    }

    /// @dev Update the rewards per token accumulator.
    /// @notice Needs to be called on each liquidity event
    function _updateRewardsPerToken() internal {
        // RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;
        // RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;
        uint256 totalSupply_ = _totalSupply;

        for (uint8 i = 0; i < rewardPool.length; i++) {
            // We skip the update if the program hasn't started
            if (block.timestamp.u32() < rewardsPeriod[rewardPool[i]].start)
                return;

            // Find out the unaccounted time
            uint32 end = earliest(
                block.timestamp.u32(),
                rewardsPeriod[rewardPool[i]].end
            );
            uint256 unaccountedTime = end -
                rewardsTokenDetail[rewardPool[i]].lastUpdated; // Cast to uint256 to avoid overflows later on
            if (unaccountedTime == 0) return; // We skip the storage changes if already updated in the same block

            // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
            // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
            if (totalSupply_ != 0)
                rewardsTokenDetail[rewardPool[i]]
                    .accumulated = (rewardsTokenDetail[rewardPool[i]]
                    .accumulated +
                    (1e9 *
                        unaccountedTime *
                        rewardsTokenDetail[rewardPool[i]].rate) /
                    totalSupply_).u128(); // The rewards per token are scaled up for precision
            rewardsTokenDetail[rewardPool[i]].lastUpdated = end;
        }
        // emit RewardsPerTokenUpdated(rewardsTokenDetail[rewardPool[i]].accumulated);
    }

    /// @dev Accumulate rewards for an user..
    /// @notice Needs to be called on each liquidity event, or when user balances change.
    function _updateUserRewards(address user) internal {
        // UserRewards memory userRewards_ = rewards[user];
        // RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;

        for (uint8 i = 0; i < rewardPool.length; i++) {
            // Calculate and update the new value user reserves. _fracBalances[user] casts it into uint256, which is desired.
            // accumulated+= (RUSD_BALANCE * (RPT.accumulated - UR.checkpoint)/ 1e9)
            rewards[user][rewardPool[i]].accumulated = (rewards[user][
                rewardPool[i]
            ].accumulated +
                ((_fracBalances[user].div(_fracsPerRUSD)) *
                    (rewardsTokenDetail[rewardPool[i]].accumulated -
                        rewards[user][rewardPool[i]].checkpoint)) /
                1e9).u128(); // We must scale down the rewards by the precision factor

            rewards[user][rewardPool[i]].checkpoint = rewardsTokenDetail[
                rewardPool[i]
            ].accumulated;
        }
        // emit UserRewardsUpdated(user, userRewards_.accumulated, userRewards_.checkpoint);
        // return userRewards_.accumulated;
    }

    function addReward(
        IERC20 _rewardToken,
        uint32 start,
        uint32 end,
        uint32 rate
    ) external payable {
        require(
            rewardStatus[_rewardToken] != RewardStatus.PENDING,
            "Already exists in pending pool"
        );
        uint8 flag=0;
        // IF Token is present in the reward pool but the supply is 0, then allow addition
        if((rewardStatus[_rewardToken] == RewardStatus.APPROVED) && 
        (_rewardToken.balanceOf(address(this))!= 0) ){
            revert();
        }
        require(
            start > 0 && end > 0 && rate > 10 && end > start && msg.value > 0,
            "does not meet requirements"
        );
        // If the rewardPool if filled and there are no tokens with 0 supply, then revert
        if(rewardPool.length==MAX_REWARD_POOL){
            for (uint8 i = 1; i < rewardPool.length; i++) {
                if (IERC20(rewardPool[i]).balanceOf(address(this)) == 0) {
                    flag=1;
                }
            }
        }
        if(flag==1){
            revert();
        }

        payable(reflectoAdd).transfer(msg.value / 2);
        payable(developer).transfer(msg.value / 2);
        tempRewardDetails[_rewardToken].start = uint32(block.timestamp) + start;
        tempRewardDetails[_rewardToken].end = uint32(block.timestamp) + end;
        tempRewardDetails[_rewardToken].rate = rate;
        tempRewardDetails[_rewardToken].tokenOwner = msg.sender;
        rewardStatus[_rewardToken] = RewardStatus.PENDING;
        pendingPool.push(_rewardToken);
    }

    function approveReward(IERC20 _rewardToken) public onlyOwner{
        require(
            rewardStatus[_rewardToken] == RewardStatus.PENDING,
            "token needs to be added first"
        );
        require(rewardPool.length >0, "Default reward must be added");
        address tokenOwner = tempRewardDetails[_rewardToken].tokenOwner;

        // set reward period with rate
        rewardsPeriod[_rewardToken].start = tempRewardDetails[_rewardToken]
            .start;
        rewardsPeriod[_rewardToken].end = tempRewardDetails[_rewardToken].end;
        rewardsTokenDetail[_rewardToken].lastUpdated = rewardsPeriod[
            _rewardToken
        ].start;
        rewardsTokenDetail[_rewardToken].rate = uint96(
            tempRewardDetails[_rewardToken].rate
        );
        // delete the struct data for tempRewardDetails
        delete tempRewardDetails[_rewardToken];

        if (rewardPool.length >= MAX_REWARD_POOL) {
            for (uint8 i = 1; i < rewardPool.length; i++) {
                if (IERC20(rewardPool[i]).balanceOf(address(this)) == 0) {
                    rewardPool[i] = _rewardToken; // overwritten with this new token
                    removeToken(rewardPool[i]);
                    break;
                }
            }
        } else {
            rewardPool.push(_rewardToken);
        }
        // remove this token from pending pool
        for (uint8 i = 0; i < pendingPool.length; i++) {
            if (pendingPool[i] == _rewardToken) {
                delete pendingPool[i];
                break;
            }
        }

        rewardStatus[_rewardToken] = RewardStatus.APPROVED;
        // get the tokens in this contract
        IERC20(_rewardToken).transferFrom(
            tokenOwner,
            address(this),
            _rewardToken.allowance(tokenOwner, address(this))
        );
    }

    function removeToken(IERC20 _rewardToken) internal{
        rewardStatus[_rewardToken]=RewardStatus.NOT_ADDED;
        delete rewardsTokenDetail[_rewardToken];
    }

    function approveMultipleReward(IERC20[] memory _rewardToken) external {
        for (uint8 i = 0; i < _rewardToken.length; i++) {
            approveReward(_rewardToken[i]);
        }
    }

    // List of approved tokens
    function approvedTokens() public view returns (IERC20[] memory) {
        return rewardPool;
    }

    // list of Unapproves/Pending tokens
    function pendingTokens() public view returns (IERC20[] memory) {
        return pendingPool;
    }

    function getMessageHash(
        address _to,
        uint256 _amount,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return recoverSigner(_messageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function gaslessClaim(
        address _to,
        IERC20[] memory _rewardTokens,
        bytes32 _messageHash,
        bytes memory signature
    ) external onlyOwner {
        require(
            block.timestamp >=
                gaslessClaimTimestamp[_to].add(gaslessClaimPeriod),
            "Cannot reclaim before 1 day"
        );
        require(
            verify(_to, _messageHash, signature),
            "signature is not matching"
        );
        gaslessClaimTimestamp[_to] = block.timestamp;
        claim(_to, _rewardTokens);
    }

    /// @dev Claim all rewards from caller into a given address
    function claim(address _to, IERC20[] memory _rewardTokens) public {
        _updateRewardsPerToken();
        _updateUserRewards(msg.sender);
        for (uint8 i = 0; i < _rewardTokens.length; i++) {
            uint256 claiming = rewards[msg.sender][_rewardTokens[i]]
                .accumulated;
            require(claiming > 0, "Claim amount cannot be less than 0");
            rewards[msg.sender][_rewardTokens[i]].accumulated = 0;
            _rewardTokens[i].transfer(_to, claiming);
        }
        // emit Claimed(to, claiming);
    }
}