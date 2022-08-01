// SPDX-License-Identifier: MIT
pragma solidity ^0.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "sortition-sum-tree-factory/contracts/SortitionSumTreeFactory.sol";
import "@pooltogether/uniform-random-number/contracts/UniformRandomNumber.sol";

/*
@notice The interface of the RNG contract
@dev we require a request() function to get the request ID back.
@dev we require a getRandomNumber() function to get the random number corresponding to the request ID.
*/
interface RNGInterface {
    function request() external returns(bytes32);
    function getRandomNumber(bytes32 requestID) external view returns(uint256);
}

/*
@title Lottery Contract. Users can enter into the lottery and be picked at random with winning probability proportional to the contributed amount of ether.
@author Jesper Kristensen
@notice You can enter the lottery and your winnings are in proportion to amount contributed. Simply send ether to the contract address to enter.
*/
contract Lottery is Ownable, Pausable {
    bool public finished;  // we can check if the Lottery is finished
    uint256 lotteryDurationSeconds;
    uint256 lotteryEndTime;
    bytes32 rng_request_id;
    address rngContractAddress;  // RNG contract from which we draw random numbers
    RNGInterface RNGContract;
    uint256 private lottery_number;
    bytes32 private tree_key;
    uint256 constant private MAX_TREE_LEAVES = 5;

    // Odds weighed by contribution from each participant
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    SortitionSumTreeFactory.SortitionSumTrees sumTreeFactory;

    /// @notice construct the Lottery contract and set the duration and point to the RNG contract which must already be deployed
    /// @param _lotteryDurationSeconds The number of seconds the Lottery is open for. From now till now + _lotteryDurationSeconds the lottery contract accepts wagers from anyone. This can be changed post-deployment by the contract owner.
    /// @param _rngContractAddress The contract address of the Random Number Generator (RNG) deployed contract. This can be changed post-deployment by the contract owner.
    constructor(uint256 _lotteryDurationSeconds, address _rngContractAddress) public {
        // Create the lottery contract by setting the initial duration from the creator and set the RNG contract address too
        assert(_lotteryDurationSeconds > 0);
        lotteryDurationSeconds = _lotteryDurationSeconds;
        lotteryEndTime = now + lotteryDurationSeconds;

        rngContractAddress = _rngContractAddress;
        RNGContract = RNGInterface(rngContractAddress);

        tree_key = getTreeKey();
        sumTreeFactory.createTree(tree_key, MAX_TREE_LEAVES);  // start our sortition sum tree
        assert(!paused());
    }

    /// @notice Anyone can send ether to the contract and will then automatically get entered into the contract if the Lottery is still active. Trigger an update to the Lottery by sending 0 eth.
    /// @dev the Lottery being active means it is not paused. Pausing it will mean that any eth sent to the contract are lost.
    receive() external payable {
        // handle all loterry contributions via payable
        finished = isLotteryFinished();

        if (finished) {
            // Pick a winner if relevant
            address payable winner;

            if (rng_request_id == 0) {
                // make a new request for a random number, and wait for it
                // (there will be one such request per lotterys)
                rng_request_id = RNGContract.request();
            }

            if (rng_request_id > 0) {
                // we have made the request, waiting for the random number now
                uint256 random_number = RNGContract.getRandomNumber(rng_request_id);

                // if the random number is ready, then draw winner
                // random_number = 0 means the number was not returned/the RNG contract is not ready
                if (random_number > 0) {
                    // we got it, so we can pick the winner now
                    winner = pickWinner(random_number);
                }
            }

            // did a winner get picked?
            if (winner != address(0)) {
                assert(paused());
                
                // reset internal state first
                _reset();

                // then send all of our funds to winner
                winner.transfer(address(this).balance);
                assert(address(this).balance == 0);
                return;
            }
        }

        if (finished)
            return;

        // accept the incoming wager into the lottery
        enter();
    }

    /// @dev make sure we cannot send ether *and* calldata
    fallback() external {
        // wagers should be submitted without calldata
        revert("Unknown error. Hint: Maybe submit wager without calldata?");
    }

    /*
    @notice Set a new lottery duration (only owner is allowed to call this function). Should only be called after the lottery is over and before the new lottery starts.
    @param newLotteryDurationSeconds The new Lottery duration in seconds. This does change the current ongoing Lottery as well so be careful!
    */
    function setLotteryDuration(uint256 newLotteryDurationSeconds) external onlyOwner {
        // set a new lottery duration
        lotteryDurationSeconds = newLotteryDurationSeconds;
    }

    /*
    @notice Set a new contract address of the RNG contract. Can be used to switch to a new random number generator.
    @dev The new RNG contract is instantiated against the interface in this file at the top.
    @param newRNGContractAddress The new RNG contract address to change to.
    */
    function setRNGContract(address newRNGContractAddress) external onlyOwner {
        // set a new random number generator contract
        rngContractAddress = newRNGContractAddress;
        RNGContract = RNGInterface(rngContractAddress);
    }

    /*
    @notice Allow the owner to pause this contract.
    */
    function pause() external onlyOwner {
        // in case the owner needs to pause for whatever reason
        _pause();
    }

    // *---------------------- PRIVATE ----------------------*

    /*
    @notice Enter the lottery. The caller is entered into the lottery by the amount sent to the contract.
    @dev this adds a leave to the Sortition Sum Tree.
    */
    function enter() private whenNotPaused {
        // Enter the sender into the lottery
        uint256 current_stake = sumTreeFactory.stakeOf(tree_key, bytes32(uint256(msg.sender)));
        uint256 new_stake = current_stake + msg.value;  // the same user can increase their stake

        sumTreeFactory.set(tree_key, new_stake, bytes32(uint256(msg.sender)));
    }

    function stakeOf(address _address) external view onlyOwner returns (uint256) {
        // Get the stake of any address
        return sumTreeFactory.stakeOf(tree_key, bytes32(uint256(_address)));
    }

    /*
    @notice A winner is picked at random. The more a person has contributed, the higher the chances of winning are.
    @param randomNumber The random number to pick a winner from.
    @return The winner of the Lottery. Will be 0x0 if no contributions have been made in the lottery.
    */
    function pickWinner(uint256 randomNumber) private view whenPaused returns (address payable) {
        uint256 bound = sumTreeFactory.total(tree_key);
        address payable selected;

        if (bound == 0)
            return address(0);
        
        uint256 token = UniformRandomNumber.uniform(randomNumber, bound);
        selected = payable(uint256(sumTreeFactory.draw(tree_key, token)));
        
        return selected;
    }

    /*
    @notice Check if the Lottery is finished. Finish it if relevant.
    @dev this can update the internal state to paused.
    @return True if the Lottery is finished.
    */
    function isLotteryFinished() private returns(bool) {
        // Check whether the lottery has ended
        if (paused())
            return true;
        
        // not paused, but should we pause?
        if (now > lotteryEndTime) {
            // pause it; no more wagers allowed, we are finished
            _pause();
            return true;
        }

        return false;
    }

    /*
    @notice Reset the Lottery state. Prepares for a new Lottery to start.
    @dev unpauses the Lottery contract.
    */
    function _reset() private whenPaused {
        // reset the lottery state
        rng_request_id = 0;
        lotteryEndTime = now + lotteryDurationSeconds;  // update the end time

        tree_key = getTreeKey();
        sumTreeFactory.createTree(tree_key, MAX_TREE_LEAVES);  // start our sortition sum tree

        _unpause();

        assert(!paused());

        // a new lottery has begun
    }

    /*
    @notice Compute and return a new tree key.
    @dev this key is what can start a new tree.
    @return the new sortition key
    */
    function getTreeKey() private returns(bytes32) {
        bytes32 curr_key = tree_key;

        lottery_number += 1;
        bytes32 new_tree_key = keccak256(abi.encodePacked("LotteryTest/Lottery", lottery_number));
        assert(curr_key != new_tree_key);
        
        return new_tree_key;
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

import "./Context.sol";

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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity ^0.6.0;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* internal */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* internal Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start
     *  @return values The values of the returned leaves
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) internal view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) internal view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

// SPDX-License-Identifier: MIT
/**
Copyright 2019 PoolTogether LLC

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.0;

/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 */
library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = (type(uint256).max - _upperBound + 1) % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
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