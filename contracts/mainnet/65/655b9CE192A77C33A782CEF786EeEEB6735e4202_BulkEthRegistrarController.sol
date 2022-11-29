// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

pragma solidity ^0.8.12; 
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IETHRegistrarController.sol";
import "./BulkQuery.sol";
import "./BulkResult.sol";

contract BulkEthRegistrarController is Ownable {
    using SafeMath for uint;

    event NameRegistered(string name, address indexed owner, uint256 cost, uint fee,  uint256 duration);
    event NameRenewed(string name, address indexed owner, uint256 cost, uint fee, uint256 duration);

    uint private _feeRatio = 10; 
      
    function getFeeRatio() public view returns(uint) {
        return _feeRatio;
    } 
    
    function setFeeRatio(uint feeRatio) external onlyOwner  {
        _feeRatio = feeRatio;
    } 

    function withdraw(address payee) external onlyOwner payable {
        payable(payee).transfer(address(this).balance);
    }
 
    function withdrawOf(address payee, address token) external onlyOwner payable {
        IERC20(token).transfer(payable(payee), IERC20(token).balanceOf(address(this)));
    } 

    function balance() external view returns(uint256) {
        return address(this).balance;
    }
 
    function balanceOf(address token) external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function available(address controller, string memory name) public view returns(bool) {
        return IETHRegistrarController(controller).available(name);
    }

    function rentPrice(address controller, string memory name, uint duration) public view returns(uint) {
        return IETHRegistrarController(controller).rentPrice(name, duration);
    }
    
    function makeCommitment(address controller, string memory name, address owner, bytes32 secret) public pure returns(bytes32) {
        return makeCommitmentWithConfig(controller, name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(address controller, string memory name, address owner, bytes32 secret, address resolver, address addr) public pure returns(bytes32) {
        return IETHRegistrarController(controller).makeCommitmentWithConfig(name, owner, secret, resolver, addr);
    }

    function commit(address controller, bytes32 commitment) public {
        IETHRegistrarController(controller).commit(commitment);
    }
  
    function register(address controller, string calldata name, address owner, uint duration, bytes32 secret) external payable {
        registerWithConfig(controller, name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(address controller, string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable {
        uint cost = rentPrice(controller, name, duration);
        uint fee = cost.div(100).mul(_feeRatio);
        uint costWithFee = cost.add(fee); 
        
        require(msg.value >= costWithFee, "BulkEthRegistrarController: Not enough ether sent.");
        require(available(controller, name), "BulkEthRegistrarController: Name has already been registered");

        IETHRegistrarController(controller).registerWithConfig{ value: cost }(name, owner, duration, secret, resolver, addr);

        emit NameRegistered(name, owner, cost, fee, duration);
    } 

    function renew(address controller, string calldata name, uint duration) external payable {
        uint cost = rentPrice(controller, name, duration);
        uint fee = cost.div(100).mul(_feeRatio);
        uint costWithFee = cost.add(fee); 

        require( msg.value >= costWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");

        IETHRegistrarController(controller).renew{ value: cost }(name, duration);

        emit NameRenewed(name, msg.sender, cost, fee, duration);
    }

    function getBytes(string calldata secret) public pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(secret)));
    }

    function bulkAvailable(address controller, string[] memory names) public view returns (bool[] memory) {
        bool[] memory _availables = new bool[](names.length);
        for (uint i = 0; i < names.length; i++) {
            _availables[i] = available(controller, names[i]);
        }
        return _availables;
    }

    function bulkRentPrice(address controller, BulkQuery[] memory query) public view returns(BulkResult[] memory result, uint totalPrice, uint totalPriceWithFee) {
        result = new BulkResult[](query.length);
        for (uint i = 0; i < query.length; i++) {
            BulkQuery memory q = query[i];
            bool _available = available(controller, q.name);
            uint _price = rentPrice(controller, q.name, q.duration);
            uint _fee = _price.div(100).mul(_feeRatio);
            totalPrice += _price;
            totalPriceWithFee += _price.div(100).mul(_feeRatio).add(_price);
            result[i] = BulkResult(q.name, _available, q.duration, _price, _fee);
        }
    } 
 
    function bulkCommit(address controller, BulkQuery[] calldata query, string calldata secret) public { 
        bytes32 _secret = getBytes(secret);
        for(uint i = 0; i < query.length; i++) { 
            BulkQuery memory q = query[i]; 
            bytes32 commitment = makeCommitmentWithConfig(controller, q.name, q.owner, _secret, q.resolver, q.addr);
            commit(controller, commitment);
        } 
    } 

    function bulkRegister(address controller, BulkQuery[] calldata query, string calldata secret) public payable {
        uint256 totalCost;
        uint256 totalCostWithFee;
        BulkResult[] memory result;
        (result, totalCost, totalCostWithFee) = bulkRentPrice(controller, query);

        require(msg.value >= totalCostWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");
 
        bytes32 _secret = getBytes(secret);
        
        for( uint i = 0; i < query.length; ++i ) {
            BulkQuery memory q = query[i];
            BulkResult memory r = result[i];
    
            IETHRegistrarController(controller).registerWithConfig{ value: r.price }(q.name, q.owner, q.duration, _secret, q.resolver, q.addr);

            emit NameRegistered(q.name, q.owner, r.price, r.fee, q.duration);
        }
    } 

    function bulkRenew(address controller, BulkQuery[] calldata query) external payable {
        uint256 totalCost;
        uint256 totalCostWithFee;
        BulkResult[] memory result;
        (result, totalCost, totalCostWithFee) = bulkRentPrice(controller, query); 
 
        require( msg.value >= totalCostWithFee, "BulkEthRegistrarController: Not enough ether sent. Expected: ");

        for( uint i = 0; i < query.length; ++i ) {
            BulkQuery memory q = query[i];
            BulkResult memory r = result[i];
             
            IETHRegistrarController(controller).renew{ value: r.price }(q.name, q.duration);

            emit NameRenewed(q.name, msg.sender, r.price, r.fee, q.duration);
        }  
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

struct BulkQuery {
    string name;  
    uint256 duration; 
    address owner;
    address resolver;
    address addr;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

struct BulkResult {
    string name;
    bool available; 
    uint256 duration;
    uint price;
    uint fee;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; 

interface IETHRegistrarController { 
    function available(string calldata name) external view returns(bool);
    function rentPrice(string calldata name, uint duration) external view returns(uint);
    function makeCommitment(string calldata name, address owner, bytes32 secret) pure external returns(bytes32);
    function makeCommitmentWithConfig(string calldata name, address owner, bytes32 secret, address resolver, address addr) pure external returns(bytes32);
    function commit(bytes32 commitment) external;
    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable;
    function registerWithConfig(string calldata name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable;
    function renew(string calldata name, uint duration) external payable;
}