// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './2.ShunaV2-Staking_Admin.sol';

contract ShunaV2_Staking is ShunaV2Staking_Admin {
    using SafeMath for uint256;

    constructor(address _nftAddr, uint256[5] memory _rewardPercentsArr) {
        nftAddr = _nftAddr;
        rewardPercentsArr = _rewardPercentsArr;
    }

    event RewardsClaimed(
        uint256 indexed poolId,
        uint256 indexed nftId,
        uint256 rewardAmount,
        address nftOwner,
        uint256 claimTime
    );

    function _claimRewardOf(uint256 _tokenId) private {
        address _tokenOwner = IERC721(nftAddr).ownerOf(_tokenId);
        require(msg.sender == _tokenOwner, 'Only NFT-owner can claim rewards');

        uint256 _totalRwds;
        for (uint256 i = 0; i < totalPools(); i++) {
            NFTRewardInfo memory _rwdsInfo = rewardsOf(i, _tokenId);

            // reward amount == 0 if pool does not exist or reward amount already claimed
            if (_rwdsInfo.tokenAmt == 0) continue;

            _totalRwds = _totalRwds.add(_rwdsInfo.tokenAmt);

            ClaimsTable[i][_tokenId] = true;

            if (_rwdsInfo.tokenAddr == address(0))
                payable(_tokenOwner).transfer(_rwdsInfo.tokenAmt);
            else
                IERC20(_rwdsInfo.tokenAddr).transfer(
                    _tokenOwner,
                    _rwdsInfo.tokenAmt
                );
            emit RewardsClaimed(
                i,
                _tokenId,
                _rwdsInfo.tokenAmt,
                _tokenOwner,
                block.timestamp
            );
        }
    }

    function claimRewardsOf(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _claimRewardOf(_tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './1.ShunaV2-Staking_View.sol';

contract ShunaV2Staking_Admin is ShunaV2Staking_View, Ownable {
    using SafeMath for uint256;

    event RewardsDeposited(
        address indexed tokenAddr,
        string tokenSymbol,
        uint8 tokenDecimals,
        uint256[5] rewardsArr,
        uint256 depositTime
    );

    function depositRewards(address _tokenAddr, uint256 _tokenAmt)
        external
        payable
        onlyOwner
    {
        string memory _tokenSymbol = 'ETH';
        uint8 _tokenDecimals = 18;
        if (_tokenAddr == address(0)) {
            require(msg.value >= _tokenAmt, 'Insufficent ETH sent');
        } else {
            _tokenSymbol = IERC20(_tokenAddr).symbol();
            _tokenDecimals = IERC20(_tokenAddr).decimals();
            IERC20(_tokenAddr).transferFrom(
                msg.sender,
                address(this),
                _tokenAmt
            );
        }

        uint256 _commonAmt = _tokenAmt.mul(rewardPercentsArr[1]).div(100);
        uint256 _rareAmt = _tokenAmt.mul(rewardPercentsArr[2]).div(100);
        uint256 _legendaryAmt = _tokenAmt.mul(rewardPercentsArr[3]).div(100);
        uint256 _mythicAmt = _tokenAmt.mul(rewardPercentsArr[4]).div(100);
        PoolsArr.push(
            PoolInfo(
                _tokenAddr,
                _tokenSymbol,
                _tokenDecimals,
                [_tokenAmt, _commonAmt, _rareAmt, _legendaryAmt, _mythicAmt],
                block.timestamp
            )
        );

        emit RewardsDeposited(
            _tokenAddr,
            _tokenSymbol,
            _tokenDecimals,
            [_tokenAmt, _commonAmt, _rareAmt, _legendaryAmt, _mythicAmt],
            block.timestamp
        );
    }

    function updateRewardPercents(uint256[5] calldata _rwdPercents)
        external
        onlyOwner
    {
        rewardPercentsArr = _rwdPercents;
    }

    event RewardsWithdrawn(address tokenAddress, uint256 amount);

    function withdrawRewards(address _tokenAddr, uint256 _amount)
        external
        onlyOwner
    {
        if (_tokenAddr == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            IERC20(_tokenAddr).transfer(owner(), _amount);
        }
        emit RewardsWithdrawn(_tokenAddr, _amount);
    }

    event PoolAmountsUpdated(uint256 poolId, uint256[5] rarityAmounts);

    function updatePoolAmounts(uint256 _poolId, uint256[5] memory _rarityAmts)
        external
        onlyOwner
    {
        PoolsArr[_poolId].rarityAmts = _rarityAmts;
        emit PoolAmountsUpdated(_poolId, _rarityAmts);
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
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract ShunaV2Staking_View {
    using SafeMath for uint256;

    address public nftAddr;

    struct NFTRewardInfo {
        address tokenAddr;
        uint256 tokenAmt;
        string tokenSymbol;
    }

    struct PoolInfo {
        address tokenAddr;
        string tokenSymbol;
        uint256 tokenDecimals;
        uint256[5] rarityAmts;
        uint256 depositTime;
    }
    PoolInfo[] PoolsArr;

    uint256[5] public rewardPercentsArr;
    uint256[5] public rarityAmountsArr = [0, 500, 400, 97, 3];

    // poolIdx => nftId => true/false
    mapping(uint256 => mapping(uint256 => bool)) public ClaimsTable;

    function totalPools() public view returns (uint256) {
        return PoolsArr.length;
    }

    function poolInfoOfId(uint256 _poolId)
        public
        view
        returns (PoolInfo memory)
    {
        return PoolsArr[_poolId];
    }

    function rarityOf(uint256 _tokenId) public pure returns (uint256) {
        // First 3 mythic, Next 97 are legendary
        // Next 400 rare, Last 500 common
        if (_tokenId >= 1 && _tokenId <= 3) return 4;
        else if (_tokenId >= 4 && _tokenId <= 100) return 3;
        else if (_tokenId >= 101 && _tokenId <= 500) return 2;
        else if (_tokenId >= 501 && _tokenId <= 1000) return 1;
        return 5;
    }

    function rewardsOf(uint256 _poolId, uint256 _nftId)
        public
        view
        returns (NFTRewardInfo memory)
    {
        address _rwdToken = poolInfoOfId(_poolId).tokenAddr;
        string memory _rwdTokeSymbol = poolInfoOfId(_poolId).tokenSymbol;
        if (ClaimsTable[_poolId][_nftId] == true) {
            return NFTRewardInfo(_rwdToken, 0, _rwdTokeSymbol); // already claimed
        }

        uint256 _rarityIdx = rarityOf(_nftId);
        uint256 _nftRwd2 = poolInfoOfId(_poolId).rarityAmts[_rarityIdx].div(
            rarityAmountsArr[_rarityIdx]
        );

        return NFTRewardInfo(_rwdToken, _nftRwd2, _rwdTokeSymbol);
    }
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