/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title ShareholderMeeting
* @dev ShareholderMeeting enables the organisation of the voting part of a shareholder meeting
*
* Error messages
* VO01: names length is not the same as urls length
* VO02: names length is not the same as proposals length
* VO03: voters length is not the same as weights length
* VO04: delegate cannot be 0x0
* VO05: caller not allowed has delegate
* VO06: voter has not been invited to vote
* VO07: Resolution id overflow
* VO08: Proposal id overflow
* VO09: Resolution already voted
* VO10: Resolution is not open for vote
* VO11: Voting session has already been open
*/


contract ShareholderMeeting is Ownable {
  using SafeMath for uint256;

  uint256 public constant VERSION = 2;
          
  event ResolutionAdded(bytes32 indexed name, bytes32 url, uint256 proposalCount);
  event ResolutionOpen(uint256 votingEnd);
  event VoterRegistered(bytes32 indexed voterId, uint256 weight);
  event Vote(bytes32 indexed voterId, uint256 indexed resolutionId, uint256 indexed proposalId, uint256 weight);
  event VoteDelegated(bytes32 indexed voterId, address indexed delegate);

  struct Resolution {
    bytes32 name;
    bytes32 url;
    uint256[] proposals;
    uint256 votingEnd;
  }

  struct Voter {
    uint256 weight;
    mapping(uint256 => bool) voted;
  }

  struct VoterId {
    bytes32 main;
    bytes32[] delegates;
  }

  bool votingStarted;
  mapping(address => VoterId) public voterIds;
  mapping(bytes32 => Voter) public voters;
  Resolution[] public resolutions;

  constructor() public {
  }


  /**
   * @dev Throws VO11 if called after voting session starts
   */
  modifier beforeVotingSession {
    require(!votingStarted, "VO11");
    _;
  }

  /**
  * @dev Throws VO14 if caller is not voter
  */
  modifier isVoter {
    bytes32 voterId = voterIds[msg.sender].main;
    require(voterId != 0x0, "VO06");
    require(voters[voterId].weight > 0, "VO06");
    _;
  }

  /**
  * @dev Adds a new set of resolutions to the voting session
  * @dev Throws VO01 if names length is not the same as urls length
  * @dev Throws VO02 if names length is not the same as proposal counts length
  * @dev Throws VO11 if the voting session has already started
  * @param _names Array of vote names
  * @param _urls Array of bytes where each vote details can be found
  * @param _proposalCounts Array containing the count of proposals for each vote (proposals should be detailed in the vote url)
  */
  function addResolutions(bytes32[] calldata _names, bytes32[] calldata _urls, uint256[] calldata _proposalCounts) external onlyOwner beforeVotingSession {
    require(_names.length == _urls.length, "VO01");
    require(_names.length == _proposalCounts.length, "VO02");
    for (uint256 i = 0; i < _names.length; i++) {
      resolutions.push(Resolution(_names[i], _urls[i], new uint256[](_proposalCounts[i]), 0));
      emit ResolutionAdded(_names[i], _urls[i], _proposalCounts[i]);
    }
  }

  /**
  * @dev Sets a resolution a open for voting
  * @dev Throws VO07 if resolution id overflows
  * @param resolutionId the id of the resolution to open
  * @param voteDuration the duration in seconds during which the vote is possible
  */
  function openResolutionVote(uint256 resolutionId, uint256 voteDuration) external onlyOwner {
    require(resolutionId < resolutions.length, "VO07");
    if (!votingStarted) {
      votingStarted = true;
    }
    resolutions[resolutionId].votingEnd = now.add(voteDuration);
    emit ResolutionOpen(resolutions[resolutionId].votingEnd);
  }

  /**
  * @dev Returns the number of resolutions in the voting session
  * @return resolutionCount Number of resolutions in the voting session
  */
  function resolutionCount() public view returns (uint256) {
    return resolutions.length;
  }

  /**
  * @dev Set the addresses allowed to vote with their respective voter id
  * @dev Throws VO03 if voters length is not the same as voter ids length
  * @dev Throws VO11 if the voting session has already started
  * @param _voters array of addresses allowed to vote
  * @param _voterIds array of weigths, each weight corresponding to a voter
  */
  function registerVoters(address[] calldata _voters, bytes32[] calldata _voterIds) external onlyOwner beforeVotingSession {
    require(_voters.length == _voterIds.length, "VO03");
    for (uint256 i = 0; i < _voters.length; i++) {
      voterIds[_voters[i]].main = _voterIds[i];
    }
  }

  /**
  * @dev Set the addresses allowed to vote with their respective weight
  * @dev Throws VO03 if voters length is not the same as weights length
  * @dev Throws VO11 if the voting session has already started
  * @param _voterIds array of ids allowed to vote
  * @param _weights array of weigths, each weight corresponding to a voter
  */
  function registerWeights(bytes32[] calldata _voterIds, uint256[] calldata _weights) external onlyOwner beforeVotingSession {
    require(_voterIds.length == _weights.length, "VO03");
    for (uint256 i = 0; i < _voterIds.length; i++) {
      voters[_voterIds[i]].weight = _weights[i];
      emit VoterRegistered(_voterIds[i], _weights[i]);
    }
  }

  /**
  * @dev Allows a voter or potential voter to delegate their vote to another address
  * @dev Throws VO03 if the delegate is 0x0
  * @dev Throws VO11 if the voting session has already started
  * @param delegate The address of the delegate
  */
  function delegateVote(address delegate) public isVoter beforeVotingSession {
    require(delegate != address(0), "VO04");
    if (!_isAlreadyDelegate(delegate, voterIds[msg.sender].main)) {
      voterIds[delegate].delegates.push(voterIds[msg.sender].main);
      emit VoteDelegated(voterIds[msg.sender].main, delegate);
    }
  }

  /**
  * @dev Returns if delegate address has been delegated vote for voterId
  * @param delegate The address of the delegate
  * @param voterId The voter id
  * @return true if the vote for voterId has been delegated to the address, false otherwise
  */
  function isDelegate(address delegate, bytes32 voterId) public view returns (bool) {
    return _isAlreadyDelegate(delegate, voterId);
  }

  /**
  * @dev Allows a voter (or his delegate) to vote for a proposal in a vote
  * @dev Throws VO05 if function caller is not allowed to vote for voter (not voter or not delegate)
  * @dev Throws VO06 if voter has not been registered
  * @dev Throws VO07 if resolution id overflows
  * @dev Throws VO08 if proposal id overflows
  * @dev Throws VO09 if voter has already voted for this resolution
  * @param resolutionId Id of the resolution to vote for
  * @param proposalId Id of the proposal to vote for
  */
  function vote(uint256 resolutionId, uint256 proposalId) public {
    require(resolutionId < resolutions.length, "VO07");
    require(proposalId < resolutions[resolutionId].proposals.length, "VO08");
    require(resolutions[resolutionId].votingEnd > 0 && resolutions[resolutionId].votingEnd > now, "VO10");
    /* Main vote */
    bytes32 voterId = voterIds[msg.sender].main;
    if (voterId != 0x0) {
      require(voters[voterId].voted[resolutionId] == false, "VO09");
      voters[voterId].voted[resolutionId] = true;
      resolutions[resolutionId].proposals[proposalId] = resolutions[resolutionId].proposals[proposalId].add(voters[voterId].weight);
      emit Vote(voterId, resolutionId, proposalId, voters[voterId].weight);
    }
    /* Delegate votes */
    for (uint256 i = 0; i < voterIds[msg.sender].delegates.length; i++) {
      voterId = voterIds[msg.sender].delegates[i];
      if (voterId != 0x0 && voters[voterId].voted[resolutionId] == false) {
        voters[voterId].voted[resolutionId] = true;
        resolutions[resolutionId].proposals[proposalId] = resolutions[resolutionId].proposals[proposalId].add(voters[voterId].weight);
        emit Vote(voterId, resolutionId, proposalId, voters[voterId].weight);
      }
    }
  }

  /**
  * @dev Returns the proposals results for a vote
  * @dev Throws VO07 if resolution id overflows
  * @param resolutionId Id of the resolution
  * @return array of result for each proposal
  */
  function getResolutionResults(uint256 resolutionId) public view returns (uint256[] memory) {
    require(resolutionId < resolutions.length, "VO07");
    return resolutions[resolutionId].proposals;
  }

  /**
  * @dev Returns if a voter has voted for a specific resolution
  * @dev Throws VO07 if resolution id overflows
  * @param voter Address of the voter
  * @param resolutionId Id of the resolution
  * @return true if the voter has voted, false otherwise
  */
  function hasVotedForResolution(address voter, uint256 resolutionId) public view returns (bool) {
    require(resolutionId < resolutions.length, "VO07");
    bytes32 voterId = voterIds[voter].main;
    return voters[voterId].voted[resolutionId];
  }

  receive() external payable {
  }

  function _isAlreadyDelegate(address voter, bytes32 voterId) internal view returns (bool) {
    for (uint256 i = 0; i < voterIds[voter].delegates.length; i++) {
      if (voterIds[voter].delegates[i] == voterId) {
        return true;
      }
    }
    return false;
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