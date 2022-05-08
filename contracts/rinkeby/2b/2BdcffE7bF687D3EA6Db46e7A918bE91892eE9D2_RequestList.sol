// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "SafeMathChainlink.sol";

// This contract is the code for Domestic Proof of Work (DPoW).
// If you want children to help you for some work, you request it to them.
// And after they get the job done, they will get rewards.
contract RequestList {
    using SafeMathChainlink for uint256;

    // Don't show your parentAddress and familyId.
    // If you show them to people, people will get the right to operate your family's requests.

    struct RequestAndReward {
        string requestsList;
        uint256 EthRewardsAmount;
    }

    mapping(address => string) public addressToChildrenName;
    mapping(address => string) public addressToParentName;
    mapping(address => address[]) public parentToChildren;
    mapping(uint256 => address[]) public familyIdToFamily;
    uint256 public numberOfFamily;
    mapping(uint256 => RequestAndReward[]) public familyIdToRequestAndReward;

    modifier onlyParent(string memory _parentName) {
        require(
            keccak256(bytes(addressToParentName[msg.sender])) ==
                keccak256(bytes(_parentName))
        );

        _;
    }

    // for adding parent
    // return the index of the family.
    function addParent(address _parentAddress, string memory _parentName)
        public
        returns (uint256)
    {
        addressToParentName[_parentAddress] = _parentName;
        familyIdToFamily[numberOfFamily].push(_parentAddress);
        numberOfFamily += 1;
        return numberOfFamily - 1;
    }

    // for adding Children
    // return the index of the child
    function addChildren(
        string memory _parentName,
        uint256 _familyId,
        address _childAddress,
        string memory _childName
    ) public onlyParent(_parentName) returns (uint256) {
        parentToChildren[msg.sender].push(_childAddress);
        uint256 numberOfChildren = parentToChildren[msg.sender].length;
        addressToChildrenName[_childAddress] = _childName;
        familyIdToFamily[_familyId].push(_childAddress);
        return numberOfChildren - 1;
    }

    // for adding requests and rewards
    // return the index of the request
    function addRequest(
        string memory _parentName,
        uint256 _familyId,
        string memory _request,
        uint256 _rewards
    ) public onlyParent(_parentName) returns (uint256) {
        RequestAndReward memory requestAndReward = RequestAndReward(
            _request,
            _rewards
        );
        familyIdToRequestAndReward[_familyId].push(requestAndReward);
        uint256 numberOfRequests = familyIdToRequestAndReward[_familyId].length;
        return numberOfRequests - 1;
    }

    // getting the number of family member
    function getFamilyMemberNum(uint256 _familyId)
        public
        view
        returns (uint256)
    {
        return familyIdToFamily[_familyId].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}