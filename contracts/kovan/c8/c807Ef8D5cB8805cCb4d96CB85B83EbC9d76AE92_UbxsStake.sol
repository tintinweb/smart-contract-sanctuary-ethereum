// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UbxsStake is Ownable {
    struct Action {
        // 0 for invest, 1 for reinvest , 2 for withdraw
        uint8 types;
        uint256 amount;
        uint256 date;
    }

    struct Plan {
        uint256 investingDays;
        uint256 investingNominator;
    }
    struct Deposit {
        uint256 amount;
        uint256 start;
        // 0 for invest , 1 for reinvest
        uint8 depositType;
        Plan plan;
    }

    struct User {
        address referer;
        address[] referals;
        uint256 refBonus;
        uint256 totalRefBonus;
        Deposit[] deposits;
        uint256 checkpoint;
        Action[] actions;
        uint256 withdrawn;
    }

    IERC20 public immutable ubxs;
    // ubxs inside the contract
    uint256 public ubxsAmount = 0;

    uint256 public minUbxsAmount = 500e6;

    //total amount of invested ubxs in this contract
    uint256 public totalStaked = 0;

    // true = invest can be done , false = can be not done
    bool private investStatus = true;

    // true = reinvest can be done , false = can be not done
    bool private reinvestStatus = true;

    Plan public investPlan =
        Plan({ investingDays: 180, investingNominator: 50 });

    Plan public reinvestPlan =
        Plan({ investingDays: 180, investingNominator: 75 });

    uint256 public constant DENOMINATOR = 10000;

    mapping(address => bool) public isBlacklist; // no ref gain
    mapping(string => address) public aliases;
    mapping(address => string) public aliasAddresses;
    mapping(address => User) public users;

    // divide by 1000, total %30 goes to referrers
    // solhint-disable-next-line
    uint8[10] public REFERENCE_INCOME_PERCENTAGES = [
        100,
        75,
        50,
        25,
        10,
        10,
        10,
        10,
        5,
        5
    ];

    event Invested(
        address indexed user,
        address indexed referer,
        uint256 amount
    );

    event RefGained(
        address indexed user,
        address indexed referral,
        uint256 amount
    );

    event Reinvested(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    error AliasTaken();
    error AlreadyHaveAlias();
    error InvalidReferer();
    error NoRemaingUbxs();
    error LessThenMinAmount();
    error NoInvestment();
    error InvestClosedByAdmin();
    error ReinvestClosedByAdmin();

    constructor(address ubxsAddress) {
        ubxs = IERC20(ubxsAddress);
        User storage user = users[msg.sender];
        user.referer = address(this);
        isBlacklist[address(this)] = true;
        isBlacklist[msg.sender] = true;
        aliases["bixos"] = address(this);
        aliases["ubxs"] = address(this);
        IERC20(ubxsAddress).approve(msg.sender, type(uint256).max);
    }

    function setAlias(string memory newAlias) external {
        //check user has staked or not
        if (users[msg.sender].referer == address(0)) revert NoInvestment();

        //check alias is taken
        if (aliases[newAlias] != address(0)) revert AliasTaken();

        //check address has aliasses
        if (bytes(aliasAddresses[msg.sender]).length != 0)
            revert AlreadyHaveAlias();

        //set aliass
        aliasAddresses[msg.sender] = newAlias;
        aliases[newAlias] = msg.sender;
    }

    function calculateReward(Deposit memory deposit)
        internal
        pure
        returns (uint256)
    {
        return ((deposit.plan.investingDays *
            deposit.plan.investingNominator *
            deposit.amount) / DENOMINATOR);
    }

    // solhint-disable not-rely-on-time

    function investTo(
        address to,
        address refererAddress,
        uint256 amount
    ) private {
        if (!investStatus) revert InvestClosedByAdmin();

        if (to == refererAddress) revert InvalidReferer();

        if (amount < minUbxsAmount) revert LessThenMinAmount();

        User storage user = users[to];

        if (user.referer == address(0)) {
            User storage referer = users[refererAddress];
            if (referer.referer == address(0)) revert InvalidReferer();
            else {
                user.referer = refererAddress;
                referer.referals.push(to);
            }
        }

        Deposit memory deposit = Deposit({
            amount: amount,
            start: block.timestamp,
            plan: investPlan,
            depositType: 0
        });

        user.actions.push(Action(0, amount, block.timestamp));
        user.deposits.push(deposit);
        totalStaked += amount;

        uint256 totalBonus = 0;
        uint256 counter = 0;
        address tempAddress = user.referer;
        User storage ref = users[tempAddress];
        do {
            if (!isBlacklist[tempAddress]) {
                uint8 percent = REFERENCE_INCOME_PERCENTAGES[counter++];
                uint256 bonus = (amount * percent) / 1000;
                ref.refBonus += bonus;
                ref.totalRefBonus += bonus;
                totalBonus += bonus;
                emit RefGained(tempAddress, to, bonus);
            }

            tempAddress = ref.referer;
            ref = users[tempAddress];
        } while (
            ref.referer != address(0) && ref.referer != owner() && counter < 10
        );

        uint256 amountToBeReduced = calculateReward(deposit) + totalBonus;
        if (ubxsAmount < amountToBeReduced) revert NoRemaingUbxs();

        ubxsAmount -= amountToBeReduced;
        emit Invested(to, user.referer, amount);
        bool result = ubxs.transferFrom(msg.sender, address(this), amount);
        require(result, "Tx Error");
    }

    function investFor(address to, uint256 amount) external onlyOwner {
        investTo(to, msg.sender, amount);
    }

    function invest(address refererAddress, uint256 amount) external {
        investTo(msg.sender, refererAddress, amount);
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        Deposit[] memory deposits = users[userAddress].deposits;
        uint256 checkpoint = users[userAddress].checkpoint;
        uint256 len = deposits.length;
        uint256 totalDividen;

        for (uint256 i = 0; i < len; i++) {
            uint256 endTime = deposits[i].start +
                deposits[i].plan.investingDays *
                1 days;

            if (checkpoint > endTime) continue;

            uint256 withdrawTime = block.timestamp;

            if (block.timestamp >= endTime) {
                // if staking period is completed ,user cant get stake bonus
                withdrawTime = endTime;
                // add his stake to bonus ,if user has not been withdrawed stake
                if (checkpoint < endTime) totalDividen += deposits[i].amount;
            }
            uint256 passedTime;
            deposits[i].start > checkpoint
                ? passedTime = withdrawTime - deposits[i].start
                : passedTime = withdrawTime - checkpoint;

            uint256 reward = (deposits[i].plan.investingNominator *
                deposits[i].amount *
                passedTime) / (DENOMINATOR * 1 days);

            totalDividen += reward;
        }
        return totalDividen;
    }

    function withdraw() external {
        User storage user = users[msg.sender];

        uint256 dividen = getUserDividends(msg.sender);
        uint256 totalWithdrawable = dividen + user.refBonus;

        users[msg.sender].actions.push(
            Action(2, totalWithdrawable, block.timestamp)
        );
        users[msg.sender].checkpoint = block.timestamp;
        user.refBonus = 0;
        user.withdrawn += totalWithdrawable;

        emit Withdrawn(msg.sender, totalWithdrawable);
        bool result = ubxs.transfer(msg.sender, totalWithdrawable);
        require(result, "Tx Error");
    }

    // solhint-enable not-rely-on-time

    function reinvest() external {
        if (!reinvestStatus) revert ReinvestClosedByAdmin();

        User storage user = users[msg.sender];

        uint256 dividen = getUserDividends(msg.sender);
        uint256 totalWithdrawable = dividen + user.refBonus;
        user.withdrawn += totalWithdrawable;

        // solhint-disable not-rely-on-time
        Deposit memory deposit = Deposit({
            amount: totalWithdrawable,
            start: block.timestamp,
            plan: reinvestPlan,
            depositType: 1
        });

        user.actions.push(Action(1, totalWithdrawable, block.timestamp));
        user.checkpoint = block.timestamp;
        // solhint-enable not-rely-on-time

        user.deposits.push(deposit);
        totalStaked += totalWithdrawable;
        user.refBonus = 0;

        uint256 amountToBeReduced = calculateReward(deposit);

        if (ubxsAmount < amountToBeReduced) revert NoRemaingUbxs();

        ubxsAmount -= amountToBeReduced;
        emit Reinvested(msg.sender, totalWithdrawable);
    }

    function getUserActions(address userAddress)
        external
        view
        returns (
            uint8[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Action[] memory actions = users[userAddress].actions;
        uint256 len = actions.length;
        uint8[] memory types = new uint8[](len);
        uint256[] memory amount = new uint256[](len);
        uint256[] memory date = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            types[i] = actions[i].types;
            amount[i] = actions[i].amount;
            date[i] = actions[i].date;
        }

        return (types, amount, date);
    }

    function getUserActionLength(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].actions.length;
    }

    function getUserDeposits(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        return users[userAddress].deposits;
    }

    function getUserReferals(address userAddress)
        public
        view
        returns (address[] memory)
    {
        return users[userAddress].referals;
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        Deposit[] memory deposits = users[userAddress].deposits;
        uint256 len = deposits.length;
        for (uint256 i = 0; i < len; i++) {
            amount = amount + deposits[i].amount;
        }
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].refBonus;
    }

    function getUserTotalReferralBonus(address userAddress)
        external
        view
        returns (uint256)
    {
        return users[userAddress].totalRefBonus;
    }

    function getUserAvailable(address userAddress)
        external
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress) + getUserDividends(userAddress);
    }

    function getUserTotalWithdrawn(address userAddress)
        external
        view
        returns (uint256)
    {
        return users[userAddress].withdrawn;
    }

    function getRefCount(address userAddress) external view returns (uint256) {
        return users[userAddress].referals.length;
    }

    function addToBlacklist(address userAddress) external onlyOwner {
        isBlacklist[userAddress] = true;
    }

    function isUserValid(address userAddress) external view returns (bool) {
        return users[userAddress].referer != address(0);
    }

    function addUbxsToContract(uint256 amount) external onlyOwner {
        ubxsAmount += amount;
        bool result = ubxs.transferFrom(msg.sender, address(this), amount);
        require(result, "Tx Error");
    }

    function changeInvestStatus(bool status) external onlyOwner {
        investStatus = status;
    }

    function changeReInvestStatus(bool status) external onlyOwner {
        reinvestStatus = status;
    }

    function changePlan(
        uint256 newMinUbxsAmount,
        uint256 investingDays,
        uint256 reinvestingDays,
        uint256 investingNominator,
        uint256 reinvestingNominator
    ) external onlyOwner {
        minUbxsAmount = newMinUbxsAmount;
        investPlan = Plan({
            investingDays: investingDays,
            investingNominator: investingNominator
        });

        reinvestPlan = Plan({
            investingDays: reinvestingDays,
            investingNominator: reinvestingNominator
        });
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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