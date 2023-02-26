/**
 *Submitted for verification at Etherscan.io on 2023-02-26
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


// Dependency file: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// Dependency file: contracts/lib/ReferralTreeLib.sol

// pragma solidity 0.8.17;

library ReferralTreeLib {
    uint256 public constant DAY = 86_400;
    uint256 public constant DECIMALS = 10_000;
    address public constant EMPTY = address(0);

    /**
     * @dev Binary tree node object.
     * @param id - Node id.
     * @param level - Partner level.
     * @param height - Node height from binary tree root.
     * @param partners - Number of invited partners.
     * @param rewards - Received rewards for each day from start.
     * @param balance - How many nft of each level.
     */
    struct Node {
        uint256 id;
        uint256 level;
        uint256 height;
        address referrer;
        uint256 partners;
        uint256 rewardsTotal;
        mapping(uint256 => uint256) rewards;
        mapping(uint256 => uint256) balance;
    }

    /**
     * @dev Binary tree.
     * @param root - The Root of the tree.
     * @param count - Number of nodes in the tree.
     * @param start - Unix timestamp at 00:00.
     * @param refLimit - The maximum number of nodes to pay rewards.
     * @param refLevelRate - List of percentages for each line for each level.
     * @param ids - Table of accounts of the tree.
     * @param nodes - Table of nodes of the tree.
     */
    struct Tree {
        address root;
        uint256 count;
        uint256 start;
        uint256 refLimit;
        uint256[][] refLevelRate;
        mapping(uint256 => address) ids;
        mapping(address => Node) nodes;
        uint256 rewardsTotal;
        mapping(uint256 => uint256) rewards;
    }

    // Events
    event Registration(
        address indexed account,
        address indexed referrer,
        uint256 id
    );
    event LevelChange(
        address indexed account,
        uint256 oldLevel,
        uint256 newLevel
    );

    event PaidReferral(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 line
    );
    event Exit(address indexed account, uint256 level);

    function getBalanceTotal(Tree storage self, address account)
        internal
        view
        returns (uint256 balance)
    {
        for (uint256 i; i < 16; i++) {
            balance += self.nodes[account].balance[i];
        }
    }

    function getCurrentDay(Tree storage self) internal view returns (uint256) {
        return (block.timestamp - self.start) / DAY;
    }

    function exists(Tree storage self, address account)
        internal
        view
        returns (bool _exists)
    {
        if (account == EMPTY) return false;
        if (account == self.root) return true;
        if (self.nodes[account].referrer != EMPTY) return true;
        return false;
    }

    function getNode(Tree storage self, address account)
        internal
        view
        returns (
            uint256 _id,
            uint256 _level,
            uint256 _height,
            address _referrer
        )
    {
        Node storage gn = self.nodes[account];
        return (gn.id, gn.level, gn.height, gn.referrer);
    }

    function getNodeStats(Tree storage self, address account)
        internal
        view
        returns (uint256 _partners, uint256 _rewardsRefTotal)
    {
        Node storage gn = self.nodes[account];
        return (gn.partners, gn.rewardsTotal);
    }

    function getNodeStatsInDay(
        Tree storage self,
        address account,
        uint256 day
    ) internal view returns (uint256 _rewardsRef) {
        Node storage gn = self.nodes[account];
        return (gn.rewards[day]);
    }

    function insertNode(
        Tree storage self,
        address referrer,
        address account
    ) internal {
        require(!isContract(account), "Cannot be a contract");

        self.count++;
        self.ids[self.count] = account;

        Node storage newNode = self.nodes[account];
        newNode.id = self.count;
        newNode.level = 0;
        newNode.height = self.nodes[referrer].height + 1;
        newNode.referrer = referrer;
        newNode.partners = 0;

        emit Registration(account, newNode.referrer, newNode.id);
    }

    function setNodeLevel(
        Tree storage self,
        address account,
        uint256 level
    ) internal {
        emit LevelChange(account, self.nodes[account].level, level);
        self.nodes[account].level = level;
    }

    function addNodeRewardsRef(
        Tree storage self,
        address account,
        uint256 value
    ) internal {
        uint256 day = getCurrentDay(self);
        Node storage gn = self.nodes[account];
        gn.rewardsTotal += value;
        gn.rewards[day] += value;
    }

    function addTreeRewardsRef(Tree storage self, uint256 value) internal {
        uint256 day = getCurrentDay(self);
        self.rewardsTotal += value;
        self.rewards[day] += value;
    }

    /**
     * @dev This will calc and pay referral to uplines instantly
     * @param - value The number tokens will be calculated in referral process
     * @return - the total referral bonus paid
     */
    function payReferral(
        Tree storage self,
        address account,
        uint256 value
    ) internal returns (uint256) {
        uint256 totalPaid;
        address cursor = account;
        for (uint256 i; i < self.refLimit; i++) {
            address payable referrer = payable(self.nodes[cursor].referrer);
            Node storage rn = self.nodes[referrer];
            if (referrer == EMPTY || referrer == self.root) {
                break;
            }

            uint256 c = (value * self.refLevelRate[rn.level][i]) / DECIMALS;
            if (c > 0) {
                totalPaid += c;
                referrer.transfer(c);
                // node stats
                addNodeRewardsRef(self, referrer, c);
            }
            emit PaidReferral(account, referrer, c, i + 1);

            cursor = referrer;
        }

        // tree stats
        addTreeRewardsRef(self, totalPaid);
        return totalPaid;
    }

    function sum(uint256[] memory data) internal pure returns (uint256 s) {
        for (uint256 i; i < data.length; i++) {
            s += data[i];
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        else return b;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}


// Root file: contracts/ReferralSystemPolygon.sol

pragma solidity 0.8.17;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "contracts/lib/ReferralTreeLib.sol";

contract ReferralSystemPolygon is Ownable, Pausable {
    using ReferralTreeLib for ReferralTreeLib.Tree;

    uint256 public constant DECIMALS = ReferralTreeLib.DECIMALS;
    uint256[] public prices = [
        0,
        0.001 ether,
        0.002 ether,
        0.003 ether,
        0.004 ether,
        0.005 ether,
        0.006 ether,
        0.007 ether,
        0.008 ether,
        0.009 ether,
        0.010 ether,
        0.011 ether,
        0.012 ether,
        0.013 ether,
        0.014 ether,
        0.015 ether,
        0.016 ether
    ];
    uint256[] public series = [
        0,
        3_000,
        2_500,
        2_200,
        1_800,
        1_500,
        1_300,
        1_100,
        800,
        500,
        300,
        200,
        150,
        100,
        70,
        25,
        10
    ];

    address public wallet;

    ReferralTreeLib.Tree private tree;

    event Purchased(address user, uint256 level, uint256 quantity);
    event RefLevelUpgraded(address user, uint256 newLevel, uint256 oldLevel);

    constructor(uint256[][] memory refLevelRate) public {
        // ref sistem
        require(
            refLevelRate.length > 0,
            "Referral levels should be at least one"
        );
        for (uint256 i; i < refLevelRate.length; i++) {
            require(
                ReferralTreeLib.sum(refLevelRate[i]) <= DECIMALS,
                "Total level rate exceeds 100%"
            );
            if (refLevelRate[i].length > tree.refLimit) {
                tree.refLimit = refLevelRate[i].length;
            }
        }
        tree.refLevelRate = refLevelRate;

        // tree
        tree.start = 0;
        tree.root = address(this);
        tree.count++;
        tree.ids[tree.count] = tree.root;

        ReferralTreeLib.Node storage rootNode = tree.nodes[tree.root];
        rootNode.id = tree.count;
        rootNode.level = 0;
        rootNode.height = 1;
        rootNode.referrer = ReferralTreeLib.EMPTY;
        rootNode.partners = 0;

        emit ReferralTreeLib.Registration(
            tree.root,
            rootNode.referrer,
            rootNode.id
        );
    }

    function join(address referrer) public whenNotPaused {
        if (!tree.exists(referrer)) {
            referrer = tree.root;
        }
        if (!tree.exists(_msgSender())) {
            tree.insertNode(referrer, _msgSender());
        }
    }

    function upgrade(address referrer, uint256 nextLevel)
        external
        payable
        whenNotPaused
    {
        join(referrer);

        uint256 currentLevel = tree.nodes[_msgSender()].level;
        require(
            nextLevel > currentLevel,
            "The next level must be above the current level"
        );
        require(nextLevel < series.length, "Incorrect next level");
        require(series[nextLevel] > 0, "Next level is over");

        uint256 difference = prices[nextLevel] - prices[currentLevel];
        require(msg.value == difference, "Incorrect value");
        emit RefLevelUpgraded(_msgSender(), nextLevel, currentLevel);

        if (currentLevel > 0) {
            series[currentLevel]++;
            tree.nodes[_msgSender()].balance[currentLevel]--;
        }
        series[nextLevel]--;
        tree.nodes[_msgSender()].balance[nextLevel]++;
        tree.setNodeLevel(_msgSender(), nextLevel);
        uint256 refPaid = tree.payReferral(_msgSender(), difference);

        if (wallet != address(0)) {
            uint256 valueOut = difference - refPaid;
            if (valueOut > 0) payable(wallet).transfer(valueOut);
        }
    }

    function buy(
        address referrer,
        uint256 level,
        uint256 quantity
    ) external payable whenNotPaused {
        join(referrer);

        uint256 balanceTotal = tree.getBalanceTotal(_msgSender());
        require(balanceTotal + quantity <= 5, "MAX LIMIT 5");
        require(series[level] >= quantity, "Next level is over");

        uint256 total = prices[level] * quantity;
        require(msg.value == total, "Incorrect value");

        series[level] -= quantity;
        tree.nodes[_msgSender()].balance[level] += quantity;

        uint256 currentLevel = tree.nodes[_msgSender()].level;
        if (currentLevel < level) {
            tree.setNodeLevel(_msgSender(), level);
            emit RefLevelUpgraded(_msgSender(), level, currentLevel);
        }

        uint256 refPaid = tree.payReferral(_msgSender(), total);
        if (wallet != address(0)) {
            uint256 valueOut = total - refPaid;
            if (valueOut > 0) payable(wallet).transfer(valueOut);
        }
    }

    function exit() external whenNotPaused {
        uint256 currentLevel = tree.nodes[_msgSender()].level;
        require(currentLevel > 0, "Level 0");

        for (uint256 i; i < 16; i++) {
            uint256 balanceTotal = tree.nodes[_msgSender()].balance[i];
            if (balanceTotal > 0) {
                for (uint256 j; j < balanceTotal; j++) {
                    emit ReferralTreeLib.Exit(_msgSender(), i);
                }
                tree.nodes[_msgSender()].balance[i] = 0;
            }
        }
        tree.setNodeLevel(_msgSender(), 0);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function reduceQuantity(uint256 level, uint256 quantity)
        external
        onlyOwner
    {
        require(series[level] >= quantity, "Incorrect quantity");
        series[level] -= quantity;
    }

    function setWallet(address newWallet) external onlyOwner {
        wallet = newWallet;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 value) external onlyOwner {
        require(value <= balance(), "Incorrect value");
        payable(_msgSender()).transfer(value);
    }

    function getTreeParams()
        external
        view
        returns (
            address _root,
            uint256 _count,
            uint256 _start,
            uint256 _day
        )
    {
        _root = tree.root;
        _count = tree.count;
        _start = tree.start;
        _day = tree.getCurrentDay();
    }

    function getTreeStats() external view returns (uint256 _rewardsRefTotal) {
        _rewardsRefTotal = tree.rewardsTotal;
    }

    function getTreeStatsInDay(uint256 day)
        external
        view
        returns (uint256 _rewardsRef)
    {
        _rewardsRef = tree.rewards[day];
    }

    function getIdToAccount(uint256 id) external view returns (address) {
        require(id <= tree.count, "Index out of bounds");
        return tree.ids[id];
    }

    function isNodeExists(address account) external view returns (bool) {
        return tree.exists(account);
    }

    function getNode(address account)
        external
        view
        returns (
            uint256 _id,
            uint256 _level,
            uint256 _height,
            address _referrer
        )
    {
        (_id, _level, _height, _referrer) = tree.getNode(account);
    }

    function getNodeStats(address account)
        external
        view
        returns (uint256 _partners, uint256 _rewardsRefTotal)
    {
        (_partners, _rewardsRefTotal) = tree.getNodeStats(account);
    }

    function getNodeStatsInDay(address account, uint256 day)
        external
        view
        returns (uint256 _rewardsRef)
    {
        (_rewardsRef) = tree.getNodeStatsInDay(account, day);
    }
}