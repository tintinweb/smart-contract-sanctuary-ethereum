// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

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
    uint256 min = _upperBound % (~_upperBound + 1);
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

/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IGVRF {

    function getRandomNumber() external returns (bytes32 requestId);

    function getContractLinkBalance() external view returns (uint);

    function getContractBalance() external view returns (uint);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "Ownable.sol";
import "SafeMath.sol";
import "IERC20.sol";
import "IERC721.sol";
import "UniformRandomNumber.sol";
import "SortitionSumTreeFactory.sol";
import "IGVRF.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/*TODO:
upgrade to safemath
upgrade to upgradeable
*/

/*
CONTRACT GAMEDROP RAFFLE
*/

contract RaffleContract is Ownable {
    //libraries
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    //constansts and variables for sortition
    bytes32 private constant TREE_KEY = keccak256("Gamedrop/Raffle");
    uint256 private constant MAX_TREE_LEAVES = 5; //chose this constant to balance cost of read vs write. Could be optimized with data
    SortitionSumTreeFactory.SortitionSumTrees internal sortition_sum_trees;

    //structs
    struct NFT {
        IERC721 nft_contract;
        uint256 token_id;
    }
    struct NextEpochBalanceUpdate {
        address user;
        uint256 new_balance;
    }

    //contract interfaces
    IERC20 public gaming_test_token;
    IGVRF public gamedrop_vrf_contract;

    //variables for raffle
    uint256 total_token_entered;
    uint256 total_time_weighted_balance;
    uint256 last_raffle_time;
    bytes32 current_random_request_id;

    //variables for claimable prize
    address public most_recent_raffle_winner;
    NFT public most_recent_prize;

    //array for owned NFTs
    NFT[] public vaultedNFTs;
    mapping(IERC721 => mapping(uint256 => bool)) is_NFT_in_vault;
    mapping(IERC721 => mapping(uint256 => uint256)) index_of_nft_in_array;

    //array to hold instructions for updating balances post raffle and mappings
    address[] next_epoch_balance_instructions;
    mapping(address => bool) is_user_already_in_next_epoch_array;
    mapping(address => uint256) user_to_old_balance;
    mapping(address => uint256) user_to_new_balance;

    //token and time weighted balances
    mapping(address => uint256) public raw_balances;

    //whitelists
    mapping(address => bool) private _address_whitelist;
    mapping(IERC721 => bool) private _nft_whitelist;

    event depositMade(
        address sender,
        uint256 amount,
        uint256 total_token_entered
    );
    event withdrawMade(
        address sender,
        uint256 amount,
        uint256 total_token_entered
    );
    event NFTVaulted(address sender, IERC721 nft_contract, uint256 token_id);
    event AddressWhitelist(address whitelist_address);
    event NFTWhitelist(IERC721 nft_address);
    event NFTsent(
        address nft_recipient,
        IERC721 nft_contract_address,
        uint256 token_id
    );
    event raffleInitiated(uint256 time, bytes32 request_id, address initiator);
    event raffleCompleted(uint256 time, address winner, NFT prize);

    constructor(address _deposit_token) {
        //initiate countdown to raffle at deploy time
        last_raffle_time = block.timestamp;

        //initialize total_token_entered at 0
        total_token_entered = 0;

        //initialize ERC20 interface (in production this will be yield guild)
        gaming_test_token = IERC20(_deposit_token);

        //initialize sortition_sum_trees
        sortition_sum_trees.createTree(TREE_KEY, MAX_TREE_LEAVES);
    }

    modifier addRaffleBalance(uint256 amount) {
        // declare time_between_raffles in memory in two functions to save gas
        uint256 time_between_raffles = 604800;
        uint256 time_until_next_raffle = (time_between_raffles -
            (block.timestamp - last_raffle_time));
        uint256 updated_balance = time_until_next_raffle * amount;

        raw_balances[msg.sender] += amount;

        // creates or updates node in sortition tree for time weighted odds of user
        sortition_sum_trees.set(
            TREE_KEY,
            updated_balance,
            bytes32(uint256(uint160(msg.sender)))
        );

        _;

        uint256 next_balance = raw_balances[msg.sender] * time_between_raffles;

        user_to_old_balance[msg.sender] = updated_balance;
        user_to_new_balance[msg.sender] = next_balance;

        if (is_user_already_in_next_epoch_array[msg.sender] == false) {
            next_epoch_balance_instructions.push(msg.sender);
        }

        total_time_weighted_balance += time_until_next_raffle * amount;
    }

    modifier subtractRaffleBalance(uint256 amount) {
        // declare time_between_raffles in memory in two functions to save gas
        uint256 time_between_raffles = 604800;
        uint256 time_until_next_raffle = (time_between_raffles -
            (block.timestamp - last_raffle_time));
        uint256 updated_balance = time_until_next_raffle * amount;

        raw_balances[msg.sender] -= amount;

        // creates node in sortition tree for time weighted odds of user
        sortition_sum_trees.set(
            TREE_KEY,
            updated_balance,
            bytes32(uint256(uint160(msg.sender)))
        );

        _;

        uint256 next_balance = raw_balances[msg.sender] * time_between_raffles;

        user_to_old_balance[msg.sender] = updated_balance;
        user_to_new_balance[msg.sender] = next_balance;

        //if user is not already in list then add them
        if (is_user_already_in_next_epoch_array[msg.sender] == false) {
            next_epoch_balance_instructions.push(msg.sender);
        }

        total_time_weighted_balance -= time_until_next_raffle * amount;
    }

    function Deposit(uint256 amount) public payable addRaffleBalance(amount) {
        require(amount > 0, "Cannot stake 0");
        require(gaming_test_token.balanceOf(msg.sender) >= amount);

        // approval required on front end
        bool sent = gaming_test_token.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        total_token_entered += amount;

        emit depositMade(msg.sender, amount, total_token_entered);
    }

    function Withdraw(uint256 amount)
        public
        payable
        subtractRaffleBalance(amount)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(
            raw_balances[msg.sender] >= amount,
            "Cannot withdraw more than you own"
        );

        bool withdrawn = gaming_test_token.transfer(msg.sender, amount);
        require(withdrawn, "Failed to withdraw tokens from contract to user");

        total_token_entered -= amount;

        emit withdrawMade(msg.sender, amount, total_token_entered);
    }

    function vaultNFT(IERC721 nft_contract_address, uint256 token_id) public {
        require(
            _address_whitelist[msg.sender],
            "Address not whitelisted to contribute NFTS, to whitelist your address reach out to Joe"
        );
        require(
            _nft_whitelist[nft_contract_address],
            "This NFT type is not whitelisted currently, to add your NFT reach out to Joe"
        );

        IERC721 nft_contract = nft_contract_address;
        // here we need to request and send approval to transfer token
        nft_contract.transferFrom(msg.sender, address(this), token_id);

        NFT memory new_nft = NFT({
            nft_contract: nft_contract,
            token_id: token_id
        });
        vaultedNFTs.push(new_nft);

        //tracking
        uint256 index = vaultedNFTs.length - 1;
        is_NFT_in_vault[nft_contract][token_id] = true;
        index_of_nft_in_array[nft_contract][token_id] = index;

        emit NFTVaulted(msg.sender, nft_contract_address, token_id);
    }

    modifier isWinner() {
        require(msg.sender == most_recent_raffle_winner);
        _;
    }

    modifier prizeUnclaimed() {
        require(
            is_NFT_in_vault[most_recent_prize.nft_contract][
                most_recent_prize.token_id
            ],
            "prize already claimed"
        );
        _;
    }

    modifier removeNFTFromArray() {
        _;
        uint256 index = index_of_nft_in_array[most_recent_prize.nft_contract][
            most_recent_prize.token_id
        ];
        uint256 last_index = vaultedNFTs.length - 1;

        vaultedNFTs[index] = vaultedNFTs[last_index];
        vaultedNFTs.pop();
        is_NFT_in_vault[most_recent_prize.nft_contract][
            most_recent_prize.token_id
        ] = false;
    }

    function claimPrize() external isWinner prizeUnclaimed removeNFTFromArray {
        _sendNFTFromVault(
            most_recent_prize.nft_contract,
            most_recent_prize.token_id,
            msg.sender
        );
    }

    //make claimable so they have to pay the gas
    function _sendNFTFromVault(
        IERC721 nft_contract_address,
        uint256 token_id,
        address nft_recipient
    ) internal {
        IERC721 nft_contract = nft_contract_address;
        nft_contract.approve(nft_recipient, token_id);
        nft_contract.transferFrom(address(this), nft_recipient, token_id);

        emit NFTsent(nft_recipient, nft_contract_address, token_id);
    }

    function initiateRaffle() external returns (bytes32) {
        require(vaultedNFTs.length > 0, "no NFTs to raffle");

        current_random_request_id = gamedrop_vrf_contract.getRandomNumber();

        emit raffleInitiated(
            block.timestamp,
            current_random_request_id,
            msg.sender
        );

        return current_random_request_id;
    }

    modifier _updateBalancesAfterRaffle() {
        _;

        uint256 x;

        for (x = 0; x < next_epoch_balance_instructions.length; x++) {
            address user = next_epoch_balance_instructions[x];
            uint256 next_balance = user_to_new_balance[user];

            sortition_sum_trees.set(
                TREE_KEY,
                next_balance,
                bytes32(uint256(uint160(user)))
            );

            uint256 old_balance = user_to_old_balance[user];
            total_time_weighted_balance += next_balance - old_balance;
        }

        delete next_epoch_balance_instructions;
    }

    function _chooseWinner(uint256 random_number) internal returns (address) {
        //set range for the uniform random number
        uint256 bound = total_time_weighted_balance;
        address selected;

        if (bound == 0) {
            selected = address(0);
        } else {
            uint256 number = UniformRandomNumber.uniform(random_number, bound);
            selected = address(
                (uint160(uint256(sortition_sum_trees.draw(TREE_KEY, number))))
            );
        }
        return selected;
    }

    function _chooseNFT(uint256 random_number) internal returns (NFT memory) {
        uint256 bound = vaultedNFTs.length;
        uint256 index_of_nft;

        index_of_nft = UniformRandomNumber.uniform(random_number, bound);

        return vaultedNFTs[index_of_nft];
    }

    function completeRaffle(uint256 random_number)
        external
        _updateBalancesAfterRaffle
    {
        //updating these two variables makes the prize claimable by the winner
        most_recent_raffle_winner = _chooseWinner(random_number);
        most_recent_prize = _chooseNFT(random_number);

        emit raffleCompleted(
            block.timestamp,
            most_recent_raffle_winner,
            most_recent_prize
        );
    }

    function updateGamedropVRFContract(IGVRF new_vrf_contract)
        public
        onlyOwner
    {
        gamedrop_vrf_contract = new_vrf_contract;
    }

    function addAddressToWhitelist(address whitelist_address) public onlyOwner {
        _address_whitelist[whitelist_address] = true;

        emit AddressWhitelist(whitelist_address);
    }

    function addNFTToWhitelist(IERC721 nft_whitelist_address) public {
        require(msg.sender == owner(), "sender not owner");
        _nft_whitelist[nft_whitelist_address] = true;

        emit NFTWhitelist(nft_whitelist_address);
    }

    function view_raw_balance(address wallet_address)
        public
        view
        returns (uint256)
    {
        return raw_balances[wallet_address];
    }

    function is_address_whitelisted(address wallet_address)
        public
        view
        returns (bool)
    {
        return _address_whitelist[wallet_address];
    }

    function is_nft_whitelisted(IERC721 nft_contract)
        public
        view
        returns (bool)
    {
        return _nft_whitelist[nft_contract];
    }

    function view_odds_of_winning(address user) public view returns (uint256) {
        return
            sortition_sum_trees.stakeOf(
                TREE_KEY,
                bytes32(uint256(uint160(user)))
            );
    }

    function get_total_number_of_NFTS() public view returns (uint256) {
        return vaultedNFTs.length;
    }

    function check_if_NFT_in_vault(IERC721 nft_contract, uint256 token_id)
        public
        view
        returns (bool)
    {
        return is_NFT_in_vault[nft_contract][token_id];
    }
}