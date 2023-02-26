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


// Dependency file: contracts/lib/BinaryTreeLib.sol

// pragma solidity 0.8.17;

library BinaryTreeLib {
    uint256 public constant DAY = 86_400;
    uint256 public constant DECIMALS = 10_000;
    address public constant EMPTY = address(0);

    enum Direction {
        RANDOM,
        RIGHT,
        LEFT
    }

    /**
     * @dev Statistics for each day from start.
     */
    struct NodeStats {
        uint256 my;
        uint256 left;
        uint256 right;
        uint256 total;
    }

    /**
     * @dev Received rewards for each day from start.
     */
    struct NodeRewards {
        uint256 ref;
        uint256 bin;
    }

    /**
     * @dev Binary tree node object.
     * @param id - Node id.
     * @param level - Partner level.
     * @param height - Node height from binary tree root.
     * @param parent -  Parent node.
     * @param left - Node on the left.
     * @param right - Node on the right.
     * @param direction - Referral distribution by tree branches.
     * @param partners - Number of invited partners.
     * @param stats - Statistics for each day from start.
     * @param rewards - Received rewards for each day from start.
     */
    struct Node {
        uint256 id;
        uint256 level;
        uint256 height;
        address referrer;
        bool isSponsoredRight;
        address parent;
        address left;
        address right;
        Direction direction;
        uint256 partners;
        NodeRewards rewardsTotal;
        mapping(uint256 => NodeStats) stats;
        mapping(uint256 => NodeRewards) rewards;
    }

    /**
     * @dev Binary tree.
     * @param root - The Root of the binary tree.
     * @param count - Number of nodes in the binary tree.
     * @param start - Unix timestamp at 00:00.
     * @param upLimit - The maximum number of nodes to update statistics. If 0, then there are no limit.
     * @param refLimit - The maximum number of nodes to pay rewards.
     * @param refLevelRate - List of percentages for each line for each level.
     * @param ids - Table of accounts of the binary tree.
     * @param nodes - Table of nodes of the binary tree.
     */
    struct Tree {
        address root;
        uint256 count;
        uint256 start;
        uint256 upLimit;
        uint256 refLimit;
        uint256[][] refLevelRate;
        mapping(uint256 => address) ids;
        mapping(address => Node) nodes;
        NodeRewards rewardsTotal;
        mapping(uint256 => NodeRewards) rewards;
    }

    // Events
    event Registration(
        address indexed account,
        address indexed referrer,
        address indexed parent,
        uint256 id,
        Direction parentDirection
    );
    event DirectionChange(address indexed account, Direction direction);
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
    event PaidBinar(address indexed to, uint256 amount);
    event Exit(address indexed account, uint256 level);

    function setUpLimit(Tree storage self, uint256 upLimit) internal {
        self.upLimit = upLimit;
    }

    function getCurrentDay(Tree storage self) internal view returns (uint256) {
        return (block.timestamp - self.start) / DAY;
    }

    function lastLeftIn(Tree storage self, address account)
        internal
        view
        returns (address)
    {
        while (self.nodes[account].left != EMPTY) {
            account = self.nodes[account].left;
        }
        return account;
    }

    function lastRightIn(Tree storage self, address account)
        internal
        view
        returns (address)
    {
        while (self.nodes[account].right != EMPTY) {
            account = self.nodes[account].right;
        }
        return account;
    }

    function exists(Tree storage self, address account)
        internal
        view
        returns (bool _exists)
    {
        if (account == EMPTY) return false;
        if (account == self.root) return true;
        if (self.nodes[account].parent != EMPTY) return true;
        return false;
    }

    function getNode(Tree storage self, address account)
        internal
        view
        returns (
            uint256 _id,
            uint256 _level,
            uint256 _height,
            address _referrer,
            address _parent,
            address _left,
            address _right,
            Direction _direction
        )
    {
        Node storage gn = self.nodes[account];
        return (
            gn.id,
            gn.level,
            gn.height,
            gn.referrer,
            gn.parent,
            gn.left,
            gn.right,
            gn.direction
        );
    }

    function getNodeStats(Tree storage self, address account)
        internal
        view
        returns (
            uint256 _partners,
            uint256 _rewardsRefTotal,
            uint256 _rewardsBinTotal
        )
    {
        Node storage gn = self.nodes[account];
        return (gn.partners, gn.rewardsTotal.ref, gn.rewardsTotal.bin);
    }

    function getNodeStatsInDay(
        Tree storage self,
        address account,
        uint256 day
    )
        internal
        view
        returns (
            uint256 _rewardsRef,
            uint256 _rewardsBin,
            uint256 _statsMy,
            uint256 _statsLeft,
            uint256 _statsRight,
            uint256 _statsTotal
        )
    {
        Node storage gn = self.nodes[account];
        return (
            gn.rewards[day].ref,
            gn.rewards[day].bin,
            gn.stats[day].my,
            gn.stats[day].left,
            gn.stats[day].right,
            gn.stats[day].total
        );
    }

    /**
     * @dev A function that returns the random distribution direction.
     */
    function _randomDirection(Tree storage self)
        private
        view
        returns (Direction direction)
    {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    self.count,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % uint256(10000);
        if (random < uint256(5000)) return Direction.RIGHT;
        else return Direction.LEFT;
    }

    function insertNode(
        Tree storage self,
        address referrer,
        address account
    ) internal {
        require(!isContract(account), "Cannot be a contract");

        Direction direction = self.nodes[referrer].direction;

        Node storage refNode = self.nodes[referrer];
        if (refNode.partners++ == 0) {
            if (refNode.isSponsoredRight) direction = Direction.RIGHT;
            else direction = Direction.LEFT;
        }

        if (direction == Direction.RANDOM) {
            direction = _randomDirection(self); // RIGHT or LEFT
        }

        address cursor;
        if (direction == Direction.RIGHT) {
            cursor = lastRightIn(self, referrer);
            self.nodes[cursor].right = account;
        } else if (direction == Direction.LEFT) {
            cursor = lastLeftIn(self, referrer);
            self.nodes[cursor].left = account;
        }

        self.count++;
        self.ids[self.count] = account;

        Node storage newNode = self.nodes[account];
        newNode.id = self.count;
        newNode.level = 0;
        newNode.height = self.nodes[cursor].height + 1;
        newNode.referrer = referrer;
        newNode.isSponsoredRight = refNode.isSponsoredRight;
        newNode.parent = cursor;
        newNode.left = EMPTY;
        newNode.right = EMPTY;
        newNode.direction = Direction.RANDOM;
        newNode.partners = 0;

        emit Registration(
            account,
            newNode.referrer,
            newNode.parent,
            newNode.id,
            direction
        );
    }

    function setNodeLevel(
        Tree storage self,
        address account,
        uint256 level
    ) internal {
        emit LevelChange(account, self.nodes[account].level, level);
        self.nodes[account].level = level;
    }

    function setNodeDirection(
        Tree storage self,
        address account,
        Direction direction
    ) internal {
        emit DirectionChange(account, direction);
        self.nodes[account].direction = direction;
    }

    function addNodeMyStats(
        Tree storage self,
        address account,
        uint256 value
    ) internal {
        uint256 day = getCurrentDay(self);
        Node storage gn = self.nodes[account];
        gn.stats[day].my += value;
        gn.stats[day].total =
            gn.stats[day].my +
            gn.stats[day].left +
            gn.stats[day].right;

        bool finished;
        uint256 i = 0;
        address cursor = gn.parent;
        address probe = account;
        while (!finished) {
            Node storage un = self.nodes[cursor];
            if (probe == un.right) {
                un.stats[day].right += value;
            } else if (probe == un.left) {
                un.stats[day].left += value;
            }
            un.stats[day].total =
                un.stats[day].my +
                un.stats[day].left +
                un.stats[day].right;

            probe = cursor;
            cursor = un.parent;
            if (cursor == EMPTY) {
                finished = true;
            } else if (self.upLimit > 0) {
                i++;
                if (i >= self.upLimit) {
                    finished = true;
                }
            }
        }
    }

    function addNodeRewardsRef(
        Tree storage self,
        address account,
        uint256 value
    ) internal {
        uint256 day = getCurrentDay(self);
        Node storage gn = self.nodes[account];
        gn.rewardsTotal.ref += value;
        gn.rewards[day].ref += value;
    }

    function addNodeRewardsBin(
        Tree storage self,
        address account,
        uint256 value
    ) internal {
        uint256 day = getCurrentDay(self);
        Node storage gn = self.nodes[account];
        gn.rewardsTotal.bin += value;
        gn.rewards[day].bin += value;
    }

    function addTreeRewardsRef(Tree storage self, uint256 value) internal {
        uint256 day = getCurrentDay(self);
        self.rewardsTotal.ref += value;
        self.rewards[day].ref += value;
    }

    function addTreeRewardsBin(Tree storage self, uint256 value) internal {
        uint256 day = getCurrentDay(self);
        self.rewardsTotal.bin += value;
        self.rewards[day].bin += value;
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


// Root file: contracts/ReferralSystemBsc.sol

pragma solidity 0.8.17;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "contracts/lib/BinaryTreeLib.sol";

contract ReferralSystemBsc is Ownable, Pausable {
    using BinaryTreeLib for BinaryTreeLib.Tree;

    uint256 public constant DECIMALS = BinaryTreeLib.DECIMALS;
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
        0.015 ether
    ];
    uint256[] public series = [
        0,
        3_000,
        2_800,
        2_300,
        2_000,
        1_700,
        1_500,
        1_000,
        550,
        300,
        200,
        100,
        50,
        25,
        20,
        10
    ];
    uint256[] public binLevelRate = [
        0,
        600,
        600,
        700,
        700,
        700,
        800,
        800,
        900,
        900,
        1_000,
        1_000,
        1_100,
        1_100,
        1_200,
        1_200
    ];

    address public wallet;

    BinaryTreeLib.Tree private tree;

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
                BinaryTreeLib.sum(refLevelRate[i]) <= DECIMALS,
                "Total level rate exceeds 100%"
            );
            if (refLevelRate[i].length > tree.refLimit) {
                tree.refLimit = refLevelRate[i].length;
            }
        }
        tree.refLevelRate = refLevelRate;

        // binary sistem
        tree.start = 0; // TODO
        tree.upLimit = 0; // 0 - unlimit
        tree.root = address(this);
        tree.count++;
        tree.ids[tree.count] = tree.root;

        BinaryTreeLib.Node storage rootNode = tree.nodes[tree.root];
        rootNode.id = tree.count;
        rootNode.level = 0;
        rootNode.height = 1;
        rootNode.referrer = BinaryTreeLib.EMPTY;
        rootNode.isSponsoredRight = true;
        rootNode.parent = BinaryTreeLib.EMPTY;
        rootNode.left = BinaryTreeLib.EMPTY;
        rootNode.right = BinaryTreeLib.EMPTY;
        rootNode.direction = BinaryTreeLib.Direction.RIGHT;
        rootNode.partners = 0;

        emit BinaryTreeLib.Registration(
            tree.root,
            rootNode.referrer,
            rootNode.parent,
            rootNode.id,
            BinaryTreeLib.Direction.RIGHT
        );
        emit BinaryTreeLib.DirectionChange(
            tree.root,
            BinaryTreeLib.Direction.RIGHT
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

        if (currentLevel > 0) series[currentLevel]++;
        series[nextLevel]--;
        tree.setNodeLevel(_msgSender(), nextLevel);
        tree.addNodeMyStats(_msgSender(), difference);
        uint256 refPaid = tree.payReferral(_msgSender(), difference);

        if (wallet != address(0)) {
            // TODO 6000/10000=60%
            uint256 valueOut = (difference * 6000) / DECIMALS;
            if ((difference - refPaid) < valueOut)
                valueOut = difference - refPaid;
            payable(wallet).transfer(valueOut);
        }
    }

    function claimBinaryRewards(uint256 day) external whenNotPaused {
        BinaryTreeLib.Node storage gn = tree.nodes[_msgSender()];

        gn.stats[day].left;
        gn.stats[day].right;
        uint256 value = BinaryTreeLib.min(
            gn.stats[day].left,
            gn.stats[day].right
        );
        uint256 rate = binLevelRate[gn.level];
        value = (value * rate) / DECIMALS;
        uint256 paid = value - tree.nodes[_msgSender()].rewards[day].bin;
        payable(_msgSender()).transfer(paid);
        emit BinaryTreeLib.PaidBinar(_msgSender(), paid);

        // node stats
        tree.addNodeRewardsBin(_msgSender(), paid);
        // tree stats
        tree.addTreeRewardsBin(paid);
    }

    function exit() external whenNotPaused {
        uint256 currentLevel = tree.nodes[_msgSender()].level;
        require(currentLevel > 0, "Level 0");
        emit BinaryTreeLib.Exit(_msgSender(), currentLevel);
        tree.setNodeLevel(_msgSender(), 0);
    }

    function setTreeNodeDirection(BinaryTreeLib.Direction direction) external {
        require(tree.exists(_msgSender()), "Node does not exist");
        tree.setNodeDirection(_msgSender(), direction);
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
            uint256 _upLimit,
            uint256 _day
        )
    {
        _root = tree.root;
        _count = tree.count;
        _start = tree.start;
        _upLimit = tree.upLimit;
        _day = tree.getCurrentDay();
    }

    function getTreeStats()
        external
        view
        returns (uint256 _rewardsRefTotal, uint256 _rewardsBinTotal)
    {
        _rewardsRefTotal = tree.rewardsTotal.ref;
        _rewardsBinTotal = tree.rewardsTotal.bin;
    }

    function getTreeStatsInDay(uint256 day)
        external
        view
        returns (uint256 _rewardsRef, uint256 _rewardsBin)
    {
        _rewardsRef = tree.rewards[day].ref;
        _rewardsBin = tree.rewards[day].bin;
    }

    function setUpLimit(uint256 upLimit) external onlyOwner {
        tree.setUpLimit(upLimit);
    }

    function getIdToAccount(uint256 id) external view returns (address) {
        require(id <= tree.count, "Index out of bounds");
        return tree.ids[id];
    }

    function getLastNodeLeftIn(address account)
        external
        view
        returns (address)
    {
        return tree.lastLeftIn(account);
    }

    function getLastNodeRightIn(address account)
        external
        view
        returns (address)
    {
        return tree.lastRightIn(account);
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
            address _referrer,
            address _parent,
            address _left,
            address _right,
            BinaryTreeLib.Direction _direction
        )
    {
        (
            _id,
            _level,
            _height,
            _referrer,
            _parent,
            _left,
            _right,
            _direction
        ) = tree.getNode(account);
    }

    function getNodeStats(address account)
        external
        view
        returns (
            uint256 _partners,
            uint256 _rewardsRefTotal,
            uint256 _rewardsBinTotal
        )
    {
        (_partners, _rewardsRefTotal, _rewardsBinTotal) = tree.getNodeStats(
            account
        );
    }

    function getNodeStatsInDay(address account, uint256 day)
        external
        view
        returns (
            uint256 _rewardsRef,
            uint256 _rewardsBin,
            uint256 _statsMy,
            uint256 _statsLeft,
            uint256 _statsRight,
            uint256 _statsTotal
        )
    {
        (
            _rewardsRef,
            _rewardsBin,
            _statsMy,
            _statsLeft,
            _statsRight,
            _statsTotal
        ) = tree.getNodeStatsInDay(account, day);
    }
}