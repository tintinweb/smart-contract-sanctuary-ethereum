// PowerFan LockRewards
// Version: 20220512001
// Website: https://powerfan.io
// Twitter: https://twitter.com/powerfanio (@powerfanio)
// Discord: https://discord.com/invite/xrd2dMW6DP
// TG: https://t.me/powerfaninc
// Facebook: https://www.facebook.com/powerfanio
// Instagram: https://www.instagram.com/powerfanio/
// PowerDao All Rights Reserved.

pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./InterestMath.sol";

// Interface for lockLP for migration
interface PrevLockLPTokens {
    function getStakings(address owner)
        external
        returns (LockLPTokens.Bonds[] memory);
}

contract LockLPTokens is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct RewardBundle {
        uint256 thirtyDay;
        uint256 sixtyDay;
        uint256 ninetyDay;
    }

    struct Bonds {
        uint256 index;
        address pairAddress;
        uint256 amountA; // PFAN
        uint256 amountB;
        uint256 liquidity;
        uint256 startTime;
        uint16 lockingDays;
        bool staking;
        uint256 lastClaimed;
        uint256 rewards;
    }

    IUniswapV2Router02 public router;

    address public pfan;
    address public uniswapV2pfanEthPair;

    address[] public pairs;
    address[] public stakersAddress;

    uint256 public rewardAdjustPercent = 100;

    mapping(address => bool) public isPairAdded;
    mapping(address => Bonds[]) public stakes;

    //-------------------------------------------------------------------------
    //  EVENTS
    //-------------------------------------------------------------------------

    event Received(address sender, uint256 to);

    event StakeLockLP(
        address investor,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity,
        uint16 lockingDays
    );

    event RestakeLP(address investor, address pair, uint256 bondIndex);

    event UnstakeLP(
        address investor,
        address pair,
        uint256 amountA,
        uint256 amountB
    );

    event TakeOutTokens(uint256 indexed tokenAmount);

    event WithdrawReward(
        address investor,
        address pair,
        uint256 bondIndex,
        uint256 interest
    );

    LockLPTokens public previousStakingContract;

    constructor() public {
        

        // Uniswapv2 router is same on main and testnets, for polygon we use uniswapv3 router.
        // Quickswap: https://docs.quickswap.exchange/reference/smart-contracts/router02
        // QUICKswap: https://polygonscan.com/address/0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        // Ethereum: https://etherscan.io/address/0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pfan = 0x671781D2792708d7d9E3eF2ABc145b11be910e6B; //must match pair

        // Get the pair for pfan and weth in uniswap factory
        uniswapV2pfanEthPair = IUniswapV2Factory(router.factory()).getPair(
            pfan,
            router.WETH()
        );

        addPair(uniswapV2pfanEthPair);
    }

    //-------------------------------------------------------------------------
    //  EXTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function createNewPairWithPfan(address _newTokenAddress) external nonReentrant {

         // Create a uniswap pair for this new token
       address quickswapV2pfanPair = IUniswapV2Factory(router.factory())
            .createPair(pfan, _newTokenAddress);
       addPair(quickswapV2pfanPair);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stakeLP(
        address _pairAddress,
        uint256 _amountA,
        uint256 _amountB,
        uint16 _lockingDays
    ) external payable {
        require(isPairAdded[_pairAddress], "PAIR_NOT_EXISTS");
        require(
            _lockingDays == 30 || _lockingDays == 60 || _lockingDays == 90,
            "INVALID_LOCKING_DAYS"
        );
        require(_amountA != 0 && _amountB != 0, "INVALID_AMOUNT");

        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);

        address token0 = uniPair.token0();
        address token1 = uniPair.token1();

        uint256 amount0;
        uint256 amount1;
        uint256 liquidity;

        if (token0 == router.WETH() || token1 == router.WETH()) {
            require(msg.value > 0, "INVALID_MSG_VALUE");

            // Make sure token0 is pfan
            address token0Pfan = token0 == pfan ? token0 : token1;

            // PFAN amount should be larger than eth
            _amountA = _amountA > _amountB ? _amountA : _amountB;

            IERC20(token0Pfan).transferFrom(
                msg.sender,
                address(this),
                _amountA
            );
            IERC20(token0Pfan).approve(address(router), _amountA);

            (amount0, amount1, liquidity) = router.addLiquidityETH{
                value: msg.value
            }(token0Pfan, _amountA, 0, 0, address(this), block.timestamp);
        } else {
            // Other pairs that is not eth, as long as amounts match, sequence does not matter.
            IERC20(token0).transferFrom(msg.sender, address(this), _amountA);
            IERC20(token0).approve(address(router), _amountA);

            IERC20(token1).transferFrom(msg.sender, address(this), _amountB);
            IERC20(token1).approve(address(router), _amountB);

            (amount0, amount1, liquidity) = router.addLiquidity(
                token0,
                token1,
                _amountA,
                _amountB,
                0,
                0,
                address(this),
                block.timestamp
            );
        }

        uint256 rewards = getRewardBundle(amount0, _lockingDays);
        uint256 index = stakes[msg.sender].length;

        stakes[msg.sender].push(
            Bonds(
                index,
                _pairAddress,
                amount0,
                amount1,
                liquidity,
                block.timestamp,
                _lockingDays,
                true, // Staking
                0, // Last claimed
                rewards
            )
        );

        //allStakerArray.push(msg.sender); //todo : uncomment after migration

        emit StakeLockLP(
            msg.sender,
            _pairAddress,
            amount0,
            amount1,
            liquidity,
            _lockingDays
        );
    }

    function restakeLP(uint256 _bondIndex, uint16 _lockingDays) external {
        require(
            _lockingDays == 30 || _lockingDays == 60 || _lockingDays == 90,
            "INVALID_LOCKING_DAYS"
        );

        Bonds[] storage stakings = stakes[msg.sender];
        Bonds storage bond = stakings[_bondIndex];

        require(
            bond.pairAddress != address(0) &&
                bond.amountA != 0 &&
                bond.amountB != 0,
            "BOND_NOT_EXISTS"
        );

        uint256 daysPast = getDaysStaked(bond.startTime);

        require(daysPast > bond.lockingDays, "BOND_NOT_MATURED_YET");
        require(!bond.staking, "REWARDS_MUST_WIDTHRAWN_FIRST");
        require(bond.lastClaimed != 0, "REWARDS_MUST_WIDTHRAWN_FIRST");

        uint256 rewards = getRewardBundle(bond.amountA, _lockingDays);
        uint256 index = stakings.length;

        stakes[msg.sender].push(
            Bonds(
                index,
                bond.pairAddress,
                bond.amountA,
                bond.amountB,
                bond.liquidity,
                block.timestamp,
                _lockingDays,
                true, // Staking
                0, // Last claimed
                rewards
            )
        );

        bond.pairAddress = address(0);
        bond.amountA = 0;
        bond.amountB = 0;

        emit RestakeLP(msg.sender, bond.pairAddress, index);
    }

    function unstakeLP(uint256 _bondIndex) external nonReentrant {
        Bonds[] storage stakings = stakes[msg.sender];
        Bonds storage bond = stakings[_bondIndex];

        require(
            bond.pairAddress != address(0) &&
                bond.amountA != 0 &&
                bond.amountB != 0,
            "BOND_NOT_EXISTS"
        );

        require(!bond.staking, "BOND_IS_STAKING");
        require(bond.lastClaimed != 0, "REWARDS_MUST_WIDTHRAWN_FIRST");
        require(bond.rewards == 0, "REWARDS_MUST_BE_ZERO_AFTER_CLAIM");

        uint256 daysPast = getDaysStaked(bond.startTime);
        require(daysPast > bond.lockingDays, "BOND_NOT_MATURED_YET");

        // Approve pair before removing liquidity
        IUniswapV2Pair pair = IUniswapV2Pair(bond.pairAddress);
        pair.approve(address(router), bond.liquidity);
        
        // Set states as zero before removing lp to prevent re-entry attack.
        bond.pairAddress = address(0);
        bond.amountA = 0;
        bond.amountB = 0;

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 amountA;
        uint256 amountB;

        if (token0 == router.WETH() || token1 == router.WETH()) {
            token0 = token0 == router.WETH() ? token1 : token0;

            (amountB) = router.removeLiquidityETHSupportingFeeOnTransferTokens(
                token0,
                bond.liquidity,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        } else {
            (amountA, amountB) = router.removeLiquidity(
                token0,
                token1,
                bond.liquidity,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        }

        emit UnstakeLP(msg.sender, address(pair), amountA, amountB);
    }

    //-------------------------------------------------------------------------
    //  PUBLIC FUNCTIONS
    //-------------------------------------------------------------------------

    function getRewardBundle(uint256 amount, uint256 _lockingDays)
        public
        view
        returns (uint256)
    {
        return
            InterestMath.getInterest(amount, _lockingDays, rewardAdjustPercent);
    }

    function getDaysStaked(uint256 time) public view returns (uint256) {
        uint256 daysStaked = calculateDays(time);
        return daysStaked;
    }

    function withdrawReward(uint256 _bondIndex) public nonReentrant {
        Bonds[] storage stakings = stakes[msg.sender];
        Bonds storage bond = stakings[_bondIndex];

        require(bond.staking, "BOND_NOT_STAKING");
        require(bond.lastClaimed == 0, "HAS ALREAY CLAIMED");

        uint256 daysPast = getDaysStaked(bond.startTime);
        require(bond.lockingDays > 10, "NON_VALID_LOCKDAYS");
        require(daysPast > bond.lockingDays, "BOND_NOT_MATURED_YET");

        uint256 interest;
        interest = bond.rewards;

        require(
            IERC20(pfan).balanceOf(address(this)) >= interest,
            "NOT_ENOUGH_REWARDS"
        );

        // We have to set this to false in order the bond is now free to unstake anytime
        bond.staking = false;
        bond.lastClaimed = block.timestamp;
        bond.rewards = 0; // Rewards are now zero

        // Send reward to client at very end of all checks.
        IERC20(pfan).transfer(msg.sender, interest);
        emit WithdrawReward(msg.sender, bond.pairAddress, _bondIndex, interest);
    }

    function getStakings(address _user) public view returns (Bonds[] memory) {
        uint256 stakesLength = stakes[_user].length;
        uint256 resultCount = 0;

        for (uint256 i = 0; i < stakesLength; i++) {
            Bonds storage bond = stakes[_user][i];

            if (bond.pairAddress != address(0)) {
                resultCount++;
            }
        }

        Bonds[] memory bonds = new Bonds[](resultCount);

        uint256 idx = 0;
        for (uint256 i = 0; i < stakesLength; i++) {
            Bonds storage bond = stakes[_user][i];

            if (bond.pairAddress != address(0)) {
                bonds[idx] = bond;
                idx++;
            }
        }

        return bonds;
    }

    function getPairs() public view returns (address[] memory) {
        return pairs;
    }

    function getStakersAddress() public view returns (address[] memory) {
        return stakersAddress;
    }

    function calculateDays(uint256 _depositTime) public view returns (uint256) {
        if (_depositTime == 0) return 0;

        // Update to days on production
        // Update to minutes if running some unit tests
        return block.timestamp.sub(_depositTime).div(1 days);
    }

    //-------------------------------------------------------------------------
    //  ONLY OWNER FUNCTIONS
    //-------------------------------------------------------------------------

    // Only owner should be able to add pairs
    function addPair(address _pair) public nonReentrant onlyOwner {
        require(_pair != address(0), "INVALID_ADDRESS");

        pairs.push(_pair);
        isPairAdded[_pair] = true;
    }

    // Only owner adjust reward
    function adjustRewardPercent(uint256 _rewardAdjustPercent)
        public
        nonReentrant
        onlyOwner
    {
        rewardAdjustPercent = _rewardAdjustPercent;
    }

    // Only owner should be able to add pairs
    function deletePair(uint256 _index, address _pair)
        public
        nonReentrant
        onlyOwner
    {
        require(_index < pairs.length);

        // Replace one to remove with last entry
        pairs[_index] = pairs[pairs.length - 1];
        pairs.pop();

        isPairAdded[_pair] = false;
    }

    // Only owner can take out all the tokens
    function ownerTakeOutRewardTokens() external nonReentrant onlyOwner {
        uint256 balance = IERC20(pfan).balanceOf(address(this));
        IERC20(pfan).transfer(msg.sender, balance);

        emit TakeOutTokens(balance);
    }

    // Only owner can update pfan address
    function updatePfanAddress(address _newPfanAddress)
        external
        nonReentrant
        onlyOwner
    {
        pfan = _newPfanAddress;
    }

    function clearOtherTokens(IERC20 _tokenAddress, address _to)
        external
        nonReentrant
        onlyOwner
    {
        _tokenAddress.transfer(_to, _tokenAddress.balanceOf(address(this)));
    }

    // Only Owner can migrate user's staking history from previous bond contract
    function migrateStakingHistoryFromPrevious(
        address _prevContractAddress,
        address[] memory _stakers
    ) external nonReentrant onlyOwner {
        PrevLockLPTokens prevContract = PrevLockLPTokens(_prevContractAddress);

        for (uint256 i = 0; i < _stakers.length; i++) {
            address staker = _stakers[i];
            uint256 length = prevContract.getStakings(staker).length;

            if (length > 0) {
                for (uint256 j = 0; j < length; j++) {
                    if (staker != address(0)) {
                        Bonds memory bond = prevContract.getStakings(staker)[j];

                        // We have to reset the index to zero to prevent conflicts to the previous index
                        uint256 newIndex = stakes[staker].length;

                        stakes[staker].push(
                            Bonds(
                                newIndex,
                                bond.pairAddress,
                                bond.amountA,
                                bond.amountB,
                                bond.liquidity,
                                bond.startTime,
                                bond.lockingDays,
                                bond.staking,
                                bond.lastClaimed,
                                bond.rewards
                            )
                        );
                    }
                }

                stakersAddress.push(staker);
            }
        }
    }// migrate

    function updateUniswapRouterAddress(address _uniswapAddress) external nonReentrant onlyOwner {

        router = IUniswapV2Router02(_uniswapAddress);

        // Get the pair for pfan and weth in uniswap factory
        uniswapV2pfanEthPair = IUniswapV2Factory(router.factory()).getPair(
            pfan,
            router.WETH()
        );

        addPair(uniswapV2pfanEthPair);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library InterestMath {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 constant THIRTY_DAYS = 30;
    uint256 constant SIXTY_DAYS = 60;
    uint256 constant NINETY_DAYS = 90;

    function getInterest(
        uint256 pFanAmount,
        uint256 daysStaked,
        uint256 rewardAdjustPercent
    ) internal pure returns (uint256) {
        uint256 principal = pFanAmount;

        // Calculate rate
        uint8 r_numerator = 0;
        uint8 r_denominator = 0;

        if (daysStaked < THIRTY_DAYS) {
            r_numerator = 1;
            r_denominator = 4;
        } else if (daysStaked >= THIRTY_DAYS && daysStaked < SIXTY_DAYS) {
            r_numerator = 1;
            r_denominator = 2;
        } else if (daysStaked >= SIXTY_DAYS && daysStaked < NINETY_DAYS) {
            r_numerator = 3;
            r_denominator = 4;
        } else if (daysStaked >= NINETY_DAYS) {
            r_numerator = 1;
            r_denominator = 1;
        } else {
            revert("INVALID_DAYS_STAKED");
        }

        require(r_numerator != 0, "INVALID_R_NUMERATOR");
        require(r_denominator != 0, "INVALID_R_DENOMINATOR");

        uint256 eq_1 = r_numerator
            .mul(1e18)
            .div(r_denominator)
            .mul(rewardAdjustPercent)
            .div(100);
        uint256 totalBalance = principal.mul(eq_1).div(1e18).div(365).mul(
            daysStaked
        );

        return totalBalance.mul(2); // Since it is a pair with eth, APY should be of total value for both pair.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}