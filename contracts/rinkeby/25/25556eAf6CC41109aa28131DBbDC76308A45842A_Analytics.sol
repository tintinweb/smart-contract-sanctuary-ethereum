// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Analytics is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct PodsInfo {
        uint256 podsCount;
    }

    struct AppsInfo {
        uint256 appsCount;
    }

    struct InfoOne {
        uint256 cpuCoresUnits;
        uint256 diskSpaceUnits;
        uint256 bandwidthUnits;
        uint256 memoryUnits;
        uint256 totalDeposit;
        uint256 numOfDeployments;
        uint256 podCount;
        uint256 appCount;
        string clusterLocation;
    }

    struct InfoTwo {
        uint256 infoEight;
        uint256 infoNine;
        uint256 infoTen;
        uint256 infoEleven;
        uint256 infoTwelve;
        uint256 infoThirteen;
        uint256 infoFourteen;
        uint256 infoFifteen;
    }

    struct InfoThree {
        string infoSixteen;
        string infoSeventeen;
        string infoEighteen;
        string infoNineteen;
        string infoTwenty;
        string infoTwentyOne;
        string infoTwentyTwo;
        string infoTwentyThree;
    }

    struct GetInfo {
        uint256 cpuCoresUnits;
        uint256 diskSpaceUnits;
        uint256 bandwidthUnits;
        uint256 memoryUnits;
        uint256 numOfDeployments;
        uint256 totalDeposit;
    }

    mapping(bytes32 => InfoOne) public clusterInfoOne;
    mapping(bytes32 => InfoTwo) public clusterInfoTwo;
    mapping(bytes32 => InfoThree) public clusterInfoThree;

    mapping(address => bool) public isWhitelisted;

    constructor() {}

    // appsCount

    function setClusterAppCount(uint256 _appCount, bytes32 _clusterDns) public {
        if (this.owner() != msg.sender) {
            require(isWhitelisted[msg.sender], "Not allowed to update");
        }
        clusterInfoOne[_clusterDns].appCount = _appCount;
    }

    function getClusterAppCount(bytes32[] memory _clusterDns)
        public
        view
        returns (AppsInfo memory)
    {
        AppsInfo memory getAppInfo = AppsInfo({
            appsCount: clusterInfoOne[_clusterDns[0]].appCount
        });

        for (uint16 i = 1; i < _clusterDns.length; i++) {
            getAppInfo.appsCount += clusterInfoOne[_clusterDns[i]].appCount;
        }

        return getAppInfo;
    }

    function setClusterPodCount(uint256 _podCount, bytes32 _clusterDns) public {
        if (this.owner() != msg.sender) {
            require(isWhitelisted[msg.sender], "Not allowed to update");
        }
        clusterInfoOne[_clusterDns].podCount = _podCount;
    }

    function getClusterPodCount(bytes32[] memory _clusterDns)
        public
        view
        returns (PodsInfo memory)
    {
        PodsInfo memory getPodInfo = PodsInfo({
            podsCount: clusterInfoOne[_clusterDns[0]].podCount
        });

        for (uint16 i = 1; i < _clusterDns.length; i++) {
            getPodInfo.podsCount += clusterInfoOne[_clusterDns[i]].podCount;
        }

        return getPodInfo;
    }

    function setClusterInfoOne(
        bytes32 _clusterDns,
        uint256 _cpuCoresUnits,
        uint256 _diskSpaceUnits,
        uint256 _bandwidthUnits,
        uint256 _memoryUnits,
        uint256 _totalDeposit,
        uint256 _numOfDeployments,
        string memory _clusterLocation
    ) public {
        if (this.owner() != msg.sender) {
            require(isWhitelisted[msg.sender], "Not allowed to update");
        }
        clusterInfoOne[_clusterDns].cpuCoresUnits = _cpuCoresUnits;
        clusterInfoOne[_clusterDns].diskSpaceUnits = _diskSpaceUnits;
        clusterInfoOne[_clusterDns].bandwidthUnits = _bandwidthUnits;
        clusterInfoOne[_clusterDns].memoryUnits = _memoryUnits;
        clusterInfoOne[_clusterDns].totalDeposit = _totalDeposit;
        clusterInfoOne[_clusterDns].numOfDeployments = _numOfDeployments;
        clusterInfoOne[_clusterDns].clusterLocation = _clusterLocation;
    }

    function setClusterInfoTwo(
        bytes32 _clusterDns,
        uint256 _infoEight,
        uint256 _infoNine,
        uint256 _infoTen,
        uint256 _infoEleven,
        uint256 _infoTwelve,
        uint256 _infoThirteen,
        uint256 _infoFourteen,
        uint256 _infoFifteen
    ) public {
        if (this.owner() != msg.sender) {
            require(isWhitelisted[msg.sender], "Not allowed to update");
        }
        clusterInfoTwo[_clusterDns].infoEight = _infoEight;
        clusterInfoTwo[_clusterDns].infoNine = _infoNine;
        clusterInfoTwo[_clusterDns].infoTen = _infoTen;
        clusterInfoTwo[_clusterDns].infoEleven = _infoEleven;
        clusterInfoTwo[_clusterDns].infoTwelve = _infoTwelve;
        clusterInfoTwo[_clusterDns].infoThirteen = _infoThirteen;
        clusterInfoTwo[_clusterDns].infoFourteen = _infoFourteen;
        clusterInfoTwo[_clusterDns].infoFifteen = _infoFifteen;
    }

    function setClusterInfoThree(
        bytes32 _clusterDns,
        string memory _infoSixteen,
        string memory _infoSeventeen,
        string memory _infoEighteen,
        string memory _infoNineteen,
        string memory _infoTwenty,
        string memory _infoTwentyOne,
        string memory _infoTwentyTwo,
        string memory _infoTwentyThree
    ) public {
        if (this.owner() != msg.sender) {
            require(isWhitelisted[msg.sender], "Not allowed to update");
        }
        clusterInfoThree[_clusterDns].infoSixteen = _infoSixteen;
        clusterInfoThree[_clusterDns].infoSeventeen = _infoSeventeen;
        clusterInfoThree[_clusterDns].infoEighteen = _infoEighteen;
        clusterInfoThree[_clusterDns].infoNineteen = _infoNineteen;
        clusterInfoThree[_clusterDns].infoTwenty = _infoTwenty;
        clusterInfoThree[_clusterDns].infoTwentyOne = _infoTwentyOne;
        clusterInfoThree[_clusterDns].infoTwentyTwo = _infoTwentyTwo;
        clusterInfoThree[_clusterDns].infoTwentyThree = _infoTwentyThree;
    }

    function getAllClusterInfoOne(bytes32[] memory _clusterDns)
        public
        view
        returns (GetInfo memory)
    {
        GetInfo memory getClusterInfo = GetInfo({
            cpuCoresUnits: clusterInfoOne[_clusterDns[0]].cpuCoresUnits,
            diskSpaceUnits: clusterInfoOne[_clusterDns[0]].diskSpaceUnits,
            bandwidthUnits: clusterInfoOne[_clusterDns[0]].bandwidthUnits,
            memoryUnits: clusterInfoOne[_clusterDns[0]].memoryUnits,
            totalDeposit: clusterInfoOne[_clusterDns[0]].totalDeposit,
            numOfDeployments: clusterInfoOne[_clusterDns[0]].numOfDeployments
        });
        for (uint16 i = 1; i < _clusterDns.length; i++) {
            getClusterInfo.cpuCoresUnits += clusterInfoOne[_clusterDns[i]]
                .cpuCoresUnits;
            getClusterInfo.diskSpaceUnits += clusterInfoOne[_clusterDns[i]]
                .diskSpaceUnits;
            getClusterInfo.bandwidthUnits += clusterInfoOne[_clusterDns[i]]
                .bandwidthUnits;
            getClusterInfo.memoryUnits += clusterInfoOne[_clusterDns[i]]
                .memoryUnits;
            getClusterInfo.totalDeposit += clusterInfoOne[_clusterDns[i]]
                .totalDeposit;
            getClusterInfo.numOfDeployments += clusterInfoOne[_clusterDns[i]]
                .numOfDeployments;
        }
        return getClusterInfo;
    }

    function getAllClusterInfoTwo(bytes32[] memory _clusterDns)
        public
        view
        returns (InfoTwo memory)
    {
        InfoTwo memory getClusterInfo = InfoTwo({
            infoEight: clusterInfoTwo[_clusterDns[0]].infoEight,
            infoNine: clusterInfoTwo[_clusterDns[0]].infoNine,
            infoTen: clusterInfoTwo[_clusterDns[0]].infoTen,
            infoEleven: clusterInfoTwo[_clusterDns[0]].infoEleven,
            infoTwelve: clusterInfoTwo[_clusterDns[0]].infoTwelve,
            infoThirteen: clusterInfoTwo[_clusterDns[0]].infoThirteen,
            infoFourteen: clusterInfoTwo[_clusterDns[0]].infoFourteen,
            infoFifteen: clusterInfoTwo[_clusterDns[0]].infoFifteen
        });
        for (uint16 i = 1; i < _clusterDns.length; i++) {
            getClusterInfo.infoEight += clusterInfoTwo[_clusterDns[i]]
                .infoEight;
            getClusterInfo.infoNine += clusterInfoTwo[_clusterDns[i]].infoNine;
            getClusterInfo.infoTen += clusterInfoTwo[_clusterDns[i]].infoTen;
            getClusterInfo.infoEleven += clusterInfoTwo[_clusterDns[i]]
                .infoEleven;
            getClusterInfo.infoTwelve += clusterInfoTwo[_clusterDns[i]]
                .infoTwelve;
            getClusterInfo.infoThirteen += clusterInfoTwo[_clusterDns[i]]
                .infoThirteen;
            getClusterInfo.infoFourteen += clusterInfoTwo[_clusterDns[i]]
                .infoFourteen;
            getClusterInfo.infoFifteen += clusterInfoTwo[_clusterDns[i]]
                .infoFifteen;
        }
        return getClusterInfo;
    }

    function getAllClusterInfoThree(bytes32 _clusterDns)
        public
        view
        returns (InfoThree memory)
    {
        InfoThree memory getClusterInfo = InfoThree({
            infoSixteen: clusterInfoThree[_clusterDns].infoSixteen,
            infoSeventeen: clusterInfoThree[_clusterDns].infoSeventeen,
            infoEighteen: clusterInfoThree[_clusterDns].infoEighteen,
            infoNineteen: clusterInfoThree[_clusterDns].infoNineteen,
            infoTwenty: clusterInfoThree[_clusterDns].infoTwenty,
            infoTwentyOne: clusterInfoThree[_clusterDns].infoTwentyOne,
            infoTwentyTwo: clusterInfoThree[_clusterDns].infoTwentyTwo,
            infoTwentyThree: clusterInfoThree[_clusterDns].infoTwentyThree
        });
        return getClusterInfo;
    }

    function whitelistAddress(address _toWhitelist) public onlyOwner {
        isWhitelisted[_toWhitelist] = true;
    }

    function removeWhitelistAddress(address _toWhitelist) public onlyOwner {
        isWhitelisted[_toWhitelist] = false;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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