/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: decentraland/ClaimWearable.sol

/**
 *Submitted for verification at Etherscan.io on 2020-07-02
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/Donation.sol

pragma solidity ^0.5.11;





interface ERC721Collection {
    function issueToken(address _beneficiary, string calldata _wearableId) external;
    function getWearableKey(string calldata _wearableId) external view returns (bytes32);
    function issued(bytes32 _wearableKey) external view returns (uint256);
    function maxIssuance(bytes32 _wearableKey) external view returns (uint256);
    function issueTokens(address[] calldata _beneficiaries, bytes32[] calldata _wearableIds) external;
    function balanceOf(address _owner) external view returns (uint256);
}

contract ClaimWearable {
    using SafeMath for uint256;

    uint256 public maxSenderBalance;
    address public owner;

    event ClaimedNFT(
        address indexed _caller,
        address indexed _erc721Collection,
        string _wearable
    );

    constructor(uint256 _maxSenderBalance) public {
        maxSenderBalance = _maxSenderBalance;
        owner = msg.sender;
    }

    function changeMaxSenderBalance(uint256 _maxSenderBalance) external {
        require(msg.sender == owner, "Unauthorized sender");
        maxSenderBalance = _maxSenderBalance;
    }

    /**
    * @dev Claim an NFTs.
     * @notice Claim a `_wearableId` NFT.
     * @param _erc721Collection - collection address
     * @param _wearableId - wearable id
     */
    function claimNFT(ERC721Collection _erc721Collection, string calldata _wearableId) external payable {
        require(_erc721Collection.balanceOf(msg.sender) < maxSenderBalance, "The sender has already reached maxSenderBalance");
        require(
            canMint(_erc721Collection, _wearableId, 1),
            "The amount of wearables to issue is higher than its available supply"
        );

        _erc721Collection.issueToken(msg.sender, _wearableId);

        emit ClaimedNFT(msg.sender, address(_erc721Collection), _wearableId);
    }

    /**
    * @dev Returns whether the wearable can be minted.
    * @param _erc721Collection - collection address
    * @param _wearableId - wearable id
    * @return whether a wearable can be minted
    */
    function canMint(ERC721Collection _erc721Collection, string memory _wearableId, uint256 _amount) public view returns (bool) {
        uint256 balance = balanceOf(_erc721Collection, _wearableId);

        return balance >= _amount;
    }

    /**
     * @dev Returns a wearable's available supply .
     * Throws if the option ID does not exist. May return 0.
     * @param _erc721Collection - collection address
     * @param _wearableId - wearable id
     * @return wearable's available supply
     */
    function balanceOf(ERC721Collection _erc721Collection, string memory _wearableId) public view returns (uint256) {
        bytes32 wearableKey = _erc721Collection.getWearableKey(_wearableId);

        uint256 issued = _erc721Collection.issued(wearableKey);
        uint256 maxIssuance = _erc721Collection.maxIssuance(wearableKey);

        return maxIssuance.sub(issued);
    }
}