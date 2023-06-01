/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
/*
  ______           _         ____  _         _     
 |  ____|         | |       |  _ \(_)       | |    
 | |__   __ _ _ __| |_   _  | |_) |_ _ __ __| |___ 
 |  __| / _` | '__| | | | | |  _ <| | '__/ _` / __|
 | |___| (_| | |  | | |_| | | |_) | | | | (_| \__ \
 |______\__,_|_|  |_|\__, | |____/|_|_|  \__,_|___/
                      __/ |                        
                     |___/      
              By Devko.dev#7286
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contract.sol

pragma solidity ^0.8.18;

interface IEB {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface ISC {
    struct token {
        uint256 stakeDate;
        address stakerAddress;
        uint256 tierId;
        uint256 collected;
        uint256 boost;
    }

    function tokensDetails(
        uint256[] memory tokens
    ) external view returns (token[] memory);
}

contract EarlyBirds_Staking is Ownable {
    using SafeMath for uint256;

    IEB public EB_Contract = IEB(0x3D84cbDC126B1d9DCA50bfFe0c7bb1940A4D029D);
    ISC public oldSC = ISC(0x8e9A7F848eaf0deE5d89ba9d22f6eED56f778e53);
    struct token {
        uint256 stakeDate;
        address stakerAddress;
        uint256 tierId;
        uint256 collected;
        uint256 boost;
    }
    mapping(uint256 => token) public stakedTokens;
    mapping(uint256 => uint256) public tiersRate;
    mapping(uint256 => uint256) public tiersDays;
    bool private allowEditing = true;
    bool private allowTransfers = true;

    constructor() {}

    modifier editingAllowed() {
        require((allowEditing), "EDITING_NOT_ALLOWED");
        _;
    }

    modifier transfersAllowed() {
        require((allowTransfers), "TRANSFERS_NOT_ALLOWED");
        _;
    }

    modifier notContract() {
        require(
            (!_isContract(msg.sender)) && (msg.sender == tx.origin),
            "Contracts not allowed"
        );
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // THIS CAN BE DISABLED
    function transferOwnershipOfTokens(
        uint256[] memory tokenIds,
        address newOwner
    ) external notContract transfersAllowed {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (stakedTokens[tokenIds[index]].stakerAddress == msg.sender) {
                stakedTokens[tokenIds[index]].stakerAddress = newOwner;
            }
        }
    }

    function toggleTransfers() external onlyOwner {
        allowTransfers = !allowTransfers;
    }

    function disableEditing() external onlyOwner {
        allowEditing = false;
    }

    // THIS CAN BE DISABLED
    function changeStakersAddresses(
        uint256[] memory tokenIds,
        address[] memory newStakers
    ) external onlyOwner editingAllowed {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            stakedTokens[tokenIds[index]].stakerAddress = newStakers[index];
        }
    }

    // THIS CAN BE DISABLED
    function changeStakingDetails(
        token[] memory tokensAdded,
        uint256[] memory tokenIds
    ) external onlyOwner editingAllowed {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            stakedTokens[tokenIds[index]].stakeDate = tokensAdded[index]
                .stakeDate;
            stakedTokens[tokenIds[index]].stakerAddress = tokensAdded[index]
                .stakerAddress;
            stakedTokens[tokenIds[index]].tierId = tokensAdded[index].tierId;
            stakedTokens[tokenIds[index]].collected = tokensAdded[index]
                .collected;
            stakedTokens[tokenIds[index]].boost = tokensAdded[index].boost;
        }
    }

    // THIS CAN BE DISABLED
    function changeMainContract(
        address newContract
    ) external onlyOwner editingAllowed {
        EB_Contract = IEB(newContract);
    }

    // THIS CAN BE DISABLED
    function clone(
        uint256 idFrom,
        uint256 count
    ) external onlyOwner editingAllowed {
        uint256[] memory tokendIds = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            tokendIds[index] = idFrom + index;
        }
        ISC.token[] memory tokenDetails = oldSC.tokensDetails(tokendIds);

        for (uint256 index = 0; index < tokenDetails.length; index++) {
            stakedTokens[idFrom + index].stakeDate = tokenDetails[index]
                .stakeDate;
            stakedTokens[idFrom + index].stakerAddress = tokenDetails[index]
                .stakerAddress;
            stakedTokens[idFrom + index].tierId = tokenDetails[index].tierId;
            stakedTokens[idFrom + index].collected = tokenDetails[index]
                .collected;
            stakedTokens[idFrom + index].boost = tokenDetails[index].boost;
        }
    }

    function changeTierRate(
        uint256 tierId,
        uint256 newRate
    ) external onlyOwner {
        tiersRate[tierId] = newRate;
    }

    function changeTierDays(
        uint256 tierId,
        uint256 newDaysCount
    ) external onlyOwner {
        tiersDays[tierId] = newDaysCount;
    }

    function stake(
        uint256[] calldata tokenIds,
        uint256 tierId
    ) external notContract {
        require(tiersRate[tierId] > 0, "TIER_NOT_VALID");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (EB_Contract.ownerOf(tokenIds[index]) == msg.sender) {
                EB_Contract.transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[index]
                );
                stakedTokens[tokenIds[index]].stakeDate = block.timestamp;
                stakedTokens[tokenIds[index]].tierId = tierId;
                stakedTokens[tokenIds[index]].stakerAddress = msg.sender;
            }
        }
    }

    function unstake(uint256[] calldata tokenIds) external notContract {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (
                stakedTokens[tokenIds[index]].stakerAddress == msg.sender &&
                (stakedTokens[tokenIds[index]].stakeDate +
                    tiersDays[stakedTokens[tokenIds[index]].tierId]) <
                block.timestamp
            ) {
                EB_Contract.transferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[index]
                );
                stakedTokens[tokenIds[index]].collected = this
                    .claimableWormsForId(tokenIds[index]);
                stakedTokens[tokenIds[index]].stakeDate = 0;
                stakedTokens[tokenIds[index]].tierId = 0;
                stakedTokens[tokenIds[index]].stakerAddress = address(0);
            }
        }
    }

    function restake(
        uint256[] calldata tokenIds,
        uint256 tierId
    ) external notContract {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (
                stakedTokens[tokenIds[index]].stakerAddress == msg.sender &&
                (stakedTokens[tokenIds[index]].stakeDate +
                    tiersDays[stakedTokens[tokenIds[index]].tierId]) <
                block.timestamp
            ) {
                stakedTokens[tokenIds[index]].collected = this
                    .claimableWormsForId(tokenIds[index]);
                stakedTokens[tokenIds[index]].stakeDate = block.timestamp;
                stakedTokens[tokenIds[index]].tierId = tierId;
            }
        }
    }

    function changeBoostsBulk(
        uint256[] memory tokenIds,
        uint256 boost
    ) external onlyOwner {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            stakedTokens[tokenIds[index]].boost = boost;
        }
    }

    function changeBoosts(
        uint256[] memory tokenIds,
        uint256[] memory boosts
    ) external onlyOwner {
        require(tokenIds.length == boosts.length, "LENGTH_NOT_MATCHED");

        for (uint256 index = 0; index < tokenIds.length; index++) {
            stakedTokens[tokenIds[index]].boost = boosts[index];
        }
    }

    function claimableWormsFor(
        uint256[] memory tokenIds
    ) external view returns (uint256) {
        uint256 totalClaimable = 0;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 timePassed = block.timestamp -
                stakedTokens[tokenIds[index]].stakeDate;
            uint256 noBoostAmount;
            if (timePassed > tiersDays[stakedTokens[tokenIds[index]].tierId]) {
                noBoostAmount =
                    tiersDays[stakedTokens[tokenIds[index]].tierId] *
                    tiersRate[stakedTokens[tokenIds[index]].tierId];
            } else {
                noBoostAmount =
                    timePassed *
                    tiersRate[stakedTokens[tokenIds[index]].tierId];
            }

            if (stakedTokens[tokenIds[index]].boost == 0) {
                totalClaimable +=
                    stakedTokens[tokenIds[index]].collected +
                    noBoostAmount;
            } else {
                totalClaimable +=
                    stakedTokens[tokenIds[index]].collected +
                    noBoostAmount +
                    ((noBoostAmount * stakedTokens[tokenIds[index]].boost) /
                        1000);
            }
        }
        return totalClaimable;
    }

    function claimableWormsForId(
        uint256 tokenId
    ) external view returns (uint256) {
        uint256 timePassed = block.timestamp - stakedTokens[tokenId].stakeDate;
        uint256 noBoostAmount;
        if (timePassed > tiersDays[stakedTokens[tokenId].tierId]) {
            noBoostAmount =
                tiersDays[stakedTokens[tokenId].tierId] *
                tiersRate[stakedTokens[tokenId].tierId];
        } else {
            noBoostAmount =
                timePassed *
                tiersRate[stakedTokens[tokenId].tierId];
        }

        if (stakedTokens[tokenId].boost == 0) {
            return stakedTokens[tokenId].collected + noBoostAmount;
        } else {
            return
                stakedTokens[tokenId].collected +
                noBoostAmount +
                ((noBoostAmount * stakedTokens[tokenId].boost) / 1000);
        }
    }

    function balanceOf(address owner) external view returns (uint256) {
        return EB_Contract.balanceOf(owner) + this.totalStakedBy(owner);
    }

    function tokensDetails(
        uint256[] memory tokens
    ) external view returns (token[] memory) {
        token[] memory tokensList = new token[](tokens.length);

        for (uint256 index = 0; index < tokens.length; index++) {
            tokensList[index] = stakedTokens[tokens[index]];
        }
        return tokensList;
    }

    function totalStakedBy(address owner) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 tokenId = 1; tokenId < 1000; tokenId++) {
            if (stakedTokens[tokenId].stakerAddress == owner) {
                total++;
            }
        }
        return total;
    }

    function tokensHeldBy(
        address owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokensList = new uint256[](
            EB_Contract.balanceOf(owner) + this.totalStakedBy(owner)
        );
        uint256 currentIndex;
        for (uint256 tokenId = 1; tokenId < 1000; tokenId++) {
            try EB_Contract.ownerOf(tokenId) {
                if (EB_Contract.ownerOf(tokenId) == owner) {
                    tokensList[currentIndex] = uint256(tokenId);
                    currentIndex++;
                }
            } catch {}
            if (stakedTokens[tokenId].stakerAddress == owner) {
                tokensList[currentIndex] = uint256(tokenId);
                currentIndex++;
            }
        }
        return tokensList;
    }

    function tokensOwnedBy(
        address owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokensList = new uint256[](
            EB_Contract.balanceOf(owner)
        );
        uint256 currentIndex;
        for (uint256 index = 1; index < 1000; index++) {
            try EB_Contract.ownerOf(index) {
                if (EB_Contract.ownerOf(index) == owner) {
                    tokensList[currentIndex] = uint256(index);
                    currentIndex++;
                }
            } catch {}
        }
        return tokensList;
    }

    function tokensStakedBy(
        address owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokensList = new uint256[](this.totalStakedBy(owner));
        uint256 currentIndex = 0;
        for (uint256 tokenId = 1; tokenId < 1000; tokenId++) {
            if (stakedTokens[tokenId].stakerAddress == owner) {
                tokensList[currentIndex] = uint256(tokenId);
                currentIndex++;
            }
        }
        return tokensList;
    }
}