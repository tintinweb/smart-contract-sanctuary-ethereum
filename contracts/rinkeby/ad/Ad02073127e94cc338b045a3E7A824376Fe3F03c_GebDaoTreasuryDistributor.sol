/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorization ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}

abstract contract StructLike {
    function val(uint256 _id) virtual public view returns (uint256);
}

/**
 * @title LinkedList (Structured Link List)
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev A utility library for using sorted linked list data structures in your Solidity project.
 */
library LinkedList {

    uint256 private constant NULL = 0;
    uint256 private constant HEAD = 0;

    bool private constant PREV = false;
    bool private constant NEXT = true;

    struct List {
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function isList(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function isNode(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function range(List storage self) internal view returns (uint256) {
        uint256 i;
        uint256 num;
        (, i) = adj(self, HEAD, NEXT);
        while (i != HEAD) {
            (, i) = adj(self, i, NEXT);
            num++;
        }
        return num;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function node(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function adj(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!isNode(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function next(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function prev(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return adj(self, _node, PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `back` or `face` basing on your list order.
     * @dev If you want to order basing on other than `structure.val()` override this function
     * @param self stored linked list from contract
     * @param _struct the structure instance
     * @param _val value to seek
     * @return uint256 next node with a value less than StructLike(_struct).val(next_)
     */
    function sort(List storage self, address _struct, uint256 _val) internal view returns (uint256) {
        if (range(self) == 0) {
            return 0;
        }
        bool exists;
        uint256 next_;
        (exists, next_) = adj(self, HEAD, NEXT);
        while ((next_ != 0) && ((_val < StructLike(_struct).val(next_)) != NEXT)) {
            next_ = self.list[next_][NEXT];
        }
        return next_;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node first node for linking
     * @param _link  node to link to in the _direction
     */
    function form(List storage self, uint256 _node, uint256 _link, bool _dir) internal {
        self.list[_link][!_dir] = _node;
        self.list[_node][_dir] = _link;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function insert(List storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if (!isNode(self, _new) && isNode(self, _node)) {
            uint256 c = self.list[_node][_direction];
            form(self, _node, _new, _direction);
            form(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function face(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function back(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return insert(self, _node, _new, PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function del(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!isNode(self, _node))) {
            return 0;
        }
        form(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /**
     * @dev Pushes an entry to the head or tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (NEXT) or tail (PREV)
     * @return bool true if success, false otherwise
     */
    function push(List storage self, uint256 _node, bool _direction) internal returns (bool) {
        return insert(self, HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (NEXT) or the tail (PREV)
     * @return uint256 the removed node
     */
    function pop(List storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj_;
        (exists, adj_) = adj(self, HEAD, _direction);
        return del(self, adj_);
    }
}

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract GebDaoMinimalTreasuryLike {
    function epochLength() external virtual view returns (uint256);
    function delegateAllowance() external virtual view returns (uint256);
    function delegateLeftoverToSpend() external virtual view returns (uint256);
    function epochStart() external virtual view returns (uint256);
    function delegateTransferERC20(address, uint256) external virtual;
}

abstract contract TokenLike {
    function transfer(address, uint256) external virtual;
}

/**
* @notice   Treasury distributor
*           Should be setup as the delegate in the GebDaoMinimalTreasury contract
*           (https://github.com/reflexer-labs/geb-dao-minimal-treasury)
*           Distribute the delegate budget to up to 5 targets, according to preset weights
**/
contract GebDaoTreasuryDistributor is GebAuth, GebMath {
    using LinkedList for LinkedList.List;

    // --- State vars ---
    // maximum amount of targets (constant)
    uint256 public constant maxTargets = 5;
    // Total distribution weight
    uint256 public totalWeight;
    // Last target on the list
    address public lastTarget;

    // GebDaoMinimalTreasury
    GebDaoMinimalTreasuryLike public treasury;

    // Mapping of target weights used for distribution
    mapping (address => uint256) public targetWeights;

    // List of targets
    LinkedList.List internal targetList;

    // --- Events ---
    event TargetAdded(address target, uint256 weight, uint256 totalWeight);
    event TargetModified(address target, uint256 weight, uint256 totalWeight);
    event TargetRemoved(address target, uint256 totalWeight);

    // --- Constructor ---
    /**
     * @notice Constructor
     * @param treasuryAddress Address of the minimal treasury
     * @param targets Targets
     * @param weights Weights
     */
    constructor(
        address          treasuryAddress,
        address[] memory targets,
        uint256[] memory weights
    ) public {
        require(treasuryAddress != address(0), "GebDaoTreasuryDistributor/null-treasury");
        require(targets.length == weights.length, "GebDaoTreasuryDistributor/invalid-data");

        treasury = GebDaoMinimalTreasuryLike(treasuryAddress);

        for (uint256 i; i < targets.length; i++) {
            addTarget(targets[i], weights[i]);
        }
    }

    // --- Admin functions ---
    /**
     * @notice Adds a target
     * @param target Address of the distribution target
     * @param weight Weight, determines the amount distributed to the target
     */
    function addTarget(address target, uint256 weight) public isAuthorized {
        require(target != address(0), "GebDaoTreasuryDistributor/null-account");
        require(weight > 0, "GebDaoTreasuryDistributor/invalid-weight");
        require(targetList.range() < maxTargets, "GebDaoTreasuryDistributor/too-many-targets");
        require(targetWeights[target] == 0, "GebDaoTreasuryDistributor/target-already-exists");

        totalWeight = addition(totalWeight, weight);
        targetWeights[target] = weight;
        require(targetList.push(uint256(target), false), "GebDaoTreasuryDistributor/failed-adding-target");
        lastTarget = target;

        emit TargetAdded(target, weight, totalWeight);
    }

    /**
     * @notice Modifies a target weight
     * @param target Address of the distribution target
     * @param weight Weight, determines the amount distributed to the target
     */
    function modifyTarget(address target, uint256 weight) external isAuthorized {
        require(weight > 0, "GebDaoTreasuryDistributor/invalid-weight");
        require(targetWeights[target] != 0, "GebDaoTreasuryDistributor/target-does-not-exist");

        totalWeight = addition(subtract(totalWeight, targetWeights[target]), weight);
        targetWeights[target] = weight;

        emit TargetModified(target, weight, totalWeight);
    }

    /**
     * @notice Removes a target
     * @param target Address of the distribution target
     */
    function removeTarget(address target) external isAuthorized {
        require(targetWeights[target] != 0, "GebDaoTreasuryDistributor/target-does-not-exist");

        totalWeight = subtract(totalWeight, targetWeights[target]);
        delete targetWeights[target];

        if (lastTarget == target) {
            (, uint prevTarget) = targetList.prev(uint256(target));
            lastTarget = address(prevTarget);
        }

        require(targetList.del(uint256(target)) != 0, "GebDaoTreasuryDistributor/failed-removing-target");

        emit TargetRemoved(target, totalWeight);
    }

    /**
     * @notice Transfer any token from the distributor to dst (admin only)
     * @param token The address of the token to be transferred
     * @param dst The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function transferERC20(address token, address dst, uint256 amount) external isAuthorized {
        TokenLike(token).transfer(dst, amount);
    }

    // --- Distribution logic ---
    /**
     * @notice Distributes funds available on the DAO treasury according to preset weights
     */
    function distributeFunds() external {
        uint totalAmount = treasury.delegateLeftoverToSpend();
        require(totalAmount > 0, "GebDaoTreasuryDistributor/no-balance");
        uint currentTarget = uint256(lastTarget);

        while (currentTarget > 0) {
            treasury.delegateTransferERC20(address(currentTarget), multiply(totalAmount, targetWeights[address(currentTarget)]) / totalWeight);
            (, currentTarget) = targetList.prev(currentTarget);
        }
    }
}