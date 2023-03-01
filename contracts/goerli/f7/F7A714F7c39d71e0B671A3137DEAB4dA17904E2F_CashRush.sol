/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

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


// Root file: contracts/CashRush.sol

pragma solidity 0.8.17;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iNft {
    function extraRate(address account) external view returns (uint256 _rate);
}

contract CashRush is Ownable {
    using SafeMath for uint256;

    uint256 private constant PSN = 10_000;
    uint256 private constant PSNH = 5_000;

    uint256 private constant ONE_DAY = 86_400;
    uint256 private constant ONE_WEEK = 604_800;

    uint256 private constant PERIOD = 100;
    uint256 private constant LOOT_TO_HIRE_1MOBSTER = PERIOD * ONE_DAY;

    uint256 private constant MIN_REINVEST = 0.05 ether;
    uint256 private constant MIN_DEPOSIT = 0.05 ether;
    uint256 private constant DEPOSIT_STEP = 2 ether;

    //+
    uint256 private constant DEV_FEE_PERCENT = 300;
    uint256 private constant NFT_FEE_PERCENT = 300;
    uint256 private constant POOL_FEE_PERCENT = 50;
    uint256 private constant MOBSTER_KILL_PERCENT = 500;
    uint256 private constant REF_PERCENT = 500;
    uint256 private constant DECIMALS = 10000;

    //+
    address payable public root;
    address payable public devWallet;
    address payable public nftWallet;
    address public poolWallet;

    //+
    bool public initialized = false;
    uint256 public initializedAt;

    struct User {
        address user;
        uint256 totalDeposit;
        uint256 totalReinvest;
        uint256 totalRefIncome;
        uint256 totalRefs;
        uint256 mobsters;
        uint256 loot;
        uint256 lastClaim;
    }
    mapping(address => User) public users;

    struct Referral {
        address payable inviter;
        address payable user;
    }
    mapping(address => Referral) public referrers;
    mapping(address => mapping(uint256 => uint256)) private referralsIncome;
    mapping(address => mapping(uint256 => uint256)) private referralsCount;

    uint256 public marketLoot;
    bool private isPurchase = false;

    modifier whenInitialized() {
        require(initialized, "NOT INITIALIZED");
        _;
    }

    event Purchase(
        address indexed user,
        address indexed inviter,
        uint256 eth,
        uint256 loot
    );
    event Hiring(address indexed user, uint256 loot, uint256 mobsters);
    event Sale(address indexed user, uint256 loot, uint256 eth);

    constructor(address _devWallet, address _nftWallet) {
        // TODO multisig address
        devWallet = payable(_devWallet);
        nftWallet = payable(_nftWallet);
        //poolWallet = ?;

        referrers[_msgSender()] = Referral(
            payable(_msgSender()),
            payable(_msgSender())
        );
        root = payable(_msgSender());
    }

    function setDevWallet(address newWallet) external onlyOwner {
        devWallet = payable(newWallet);
    }

    function setNftWallet(address newWallet) external onlyOwner {
        require(nftWallet == address(0), "Already set");
        nftWallet = payable(newWallet);
    }

    function setPoolWallet(address newWallet) external onlyOwner {
        require(poolWallet == address(0), "Already set");
        poolWallet = newWallet;
    }

    function getMaxDeposit(address _user) public view returns (uint256) {
        User memory user = users[_user];
        uint256 weeksPast = 1 +
            block.timestamp.sub(initializedAt).mul(10).div(ONE_WEEK).div(10);
        uint256 maxDepositSinceInitialisation = DEPOSIT_STEP.mul(weeksPast);
        return
            maxDepositSinceInitialisation.sub(
                user.totalDeposit.add(user.totalReinvest)
            );
    }

    // deposit
    function buyLoot(address payable inviter) external payable {
        require(msg.value >= MIN_DEPOSIT, "DEPOSIT MINIMUM VALUE");
        require(
            msg.value <= getMaxDeposit(_msgSender()),
            "DEPOSIT VALUE EXCEEDS MAXIMUM"
        );

        if (inviter == _msgSender() || inviter == address(0)) {
            inviter = root;
        }
        if (referrers[_msgSender()].inviter != address(0)) {
            inviter = referrers[_msgSender()].inviter;
        }
        require(referrers[inviter].user == inviter, "INVITER MUST EXIST");
        if (referrers[_msgSender()].user == address(0))
            referrers[_msgSender()] = Referral(inviter, payable(_msgSender()));

        User memory user;
        if (users[_msgSender()].totalDeposit > 0) {
            user = users[_msgSender()];
        } else {
            user = User(_msgSender(), 0, 0, 0, 0, 0, 0, block.timestamp);
            users[inviter].totalRefs++;
        }
        user.totalDeposit = user.totalDeposit.add(msg.value);

        uint256 lootBought = _calculateLootBuy(
            msg.value,
            SafeMath.sub(getBalance(), msg.value)
        );
        lootBought = SafeMath.sub(
            lootBought,
            _allFees(lootBought, inviter != root)
        );
        user.loot = user.loot.add(lootBought);
        users[_msgSender()] = user;
        emit Purchase(_msgSender(), inviter, msg.value, lootBought);

        uint256 devFee = _devFee(msg.value);
        devWallet.transfer(devFee);
        uint256 nftFee = _nftFee(msg.value);
        nftWallet.transfer(nftFee);
        uint256 poolFee = _poolFee(msg.value);
        _sendToPoolWallet(_msgSender(), poolFee);

        if (inviter != root) {
            uint256 refFee = _refFee(msg.value);
            inviter.transfer(refFee);
        }

        isPurchase = true;
        hireMobsters();
        isPurchase = false;
    }

    // reinvest
    function hireMobsters() public whenInitialized {
        User memory user = users[_msgSender()];

        uint256 hasLoot = getMyLoot(_msgSender());
        if (!isPurchase) {
            require(
                (user.lastClaim + 7 * ONE_DAY) <= block.timestamp,
                "Too early"
            );

            uint256 ethValue = calculateLootSell(hasLoot);
            require(ethValue >= MIN_REINVEST, "REINVEST MINIMUM VALUE");
            require(
                ethValue <= getMaxDeposit(_msgSender()),
                "DEPOSIT VALUE EXCEEDS MAXIMUM"
            );
            user.totalReinvest += ethValue;
        }

        uint256 newMobsters = hasLoot.div(LOOT_TO_HIRE_1MOBSTER);
        user.mobsters = user.mobsters.add(newMobsters);
        user.loot = 0;
        user.lastClaim = block.timestamp;
        users[_msgSender()] = user;
        emit Hiring(_msgSender(), hasLoot, newMobsters);

        // boost market to nerf miners hoarding
        marketLoot = marketLoot.add(hasLoot.div(5)); // +20%
    }

    // withdraw
    function sellLoot() external whenInitialized {
        User memory user = users[_msgSender()];
        require((user.lastClaim + 7 * ONE_DAY) <= block.timestamp, "Too early");

        uint256 hasLoot = getMyLoot(_msgSender());
        uint256 ethValue = calculateLootSell(hasLoot);
        require(getBalance() >= ethValue, "NOT ENOUGH BALANCE");

        uint256 devFee = _devFee(ethValue);
        devWallet.transfer(devFee);
        uint256 nftFee = _nftFee(ethValue);
        nftWallet.transfer(nftFee);

        ethValue = ethValue.sub(devFee.add(nftFee));

        user.loot = 0;
        user.lastClaim = block.timestamp;
        user.mobsters = user.mobsters.sub(_mobstersKillFee(user.mobsters));
        users[_msgSender()] = user;
        marketLoot = marketLoot.add(hasLoot);

        payable(_msgSender()).transfer(ethValue);
        emit Sale(_msgSender(), hasLoot, ethValue);
    }

    function _calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private pure returns (uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function _calculateLootBuy(uint256 eth, uint256 contractBalance)
        private
        view
        returns (uint256)
    {
        return _calculateTrade(eth, contractBalance, marketLoot);
    }

    function calculateLootBuy(uint256 eth) external view returns (uint256) {
        return _calculateLootBuy(eth, getBalance());
    }

    function calculateLootSell(uint256 loot) public view returns (uint256) {
        return _calculateTrade(loot, marketLoot, getBalance());
    }

    function _sendToPoolWallet(address from, uint256 value) private {
        (bool success, bytes memory data) = poolWallet.call{value: value}(
            abi.encodeWithSignature("deposit(address)", from)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ETH_TRANSFER_FAILED"
        );
    }

    // 3+3+0.5 +5
    function _allFees(uint256 amount, bool withRef)
        private
        pure
        returns (uint256)
    {
        if (withRef)
            return
                _devFee(amount) +
                _nftFee(amount) +
                _poolFee(amount) +
                _refFee(amount);
        return _devFee(amount) + _nftFee(amount) + _poolFee(amount);
    }

    function _devFee(uint256 amount) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, DEV_FEE_PERCENT), DECIMALS);
    }

    function _nftFee(uint256 amount) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, NFT_FEE_PERCENT), DECIMALS);
    }

    function _poolFee(uint256 amount) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, POOL_FEE_PERCENT), DECIMALS);
    }

    function _mobstersKillFee(uint256 amount) private pure returns (uint256) {
        return
            SafeMath.div(SafeMath.mul(amount, MOBSTER_KILL_PERCENT), DECIMALS);
    }

    function _refFee(uint256 amount) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, REF_PERCENT), DECIMALS);
    }

    function seedMarket() external payable onlyOwner {
        require(marketLoot == 0);
        initialized = true;
        initializedAt = block.timestamp;
        marketLoot = LOOT_TO_HIRE_1MOBSTER * 100_000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMobsters(address _user) external view returns (uint256) {
        User memory user = users[_user];
        return user.mobsters;
    }

    function getMyLoot(address _user) public view returns (uint256) {
        User memory user = users[_user];
        return user.loot.add(getMyLootSinceLastHire(_user));
    }

    function getMyLootSinceLastHire(address _user)
        public
        view
        returns (uint256)
    {
        User memory user = users[_user];
        uint256 secondsPassed = _min(
            LOOT_TO_HIRE_1MOBSTER,
            block.timestamp.sub(user.lastClaim)
        );
        uint256 extraRate = iNft(nftWallet).extraRate(_user);
        secondsPassed = secondsPassed.add(
            secondsPassed.mul(extraRate).div(100)
        );
        return secondsPassed.mul(user.mobsters);
    }

    function getMyRewards(address _user) external view returns (uint256) {
        uint256 hasLoot = getMyLoot(_user);
        uint256 ethValue = calculateLootSell(hasLoot);
        return ethValue;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}