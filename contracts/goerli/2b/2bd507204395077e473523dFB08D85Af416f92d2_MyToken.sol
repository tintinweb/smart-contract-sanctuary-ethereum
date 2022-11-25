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
pragma solidity ^0.8.13;

interface EventToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EventToken.sol";

// 1 ETH = 100 token
contract MyToken is Ownable, EventToken {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    // check ETH co trong contract cua ng chuyen
    mapping(address => uint256) private balancesEth;
    uint256 private totalSupply;

    string private name;
    string private symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    modifier checkBalances(address _account, uint256 _amount) {
        require(balances[_account] >= _amount, "Khong hop le");
        _;
    }

    function nameToken() public view returns (string memory) {
        return name;
    }

    function symbolToken() public view returns (string memory) {
        return symbol;
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }

    function swapEthToToken() internal pure returns (uint256) {
        return 100;
    }

    function freeToken() internal pure returns (uint256) {
        return 3;
    }

    function totalSupplyToken() public view returns (uint256) {
        return totalSupply;
    }

    // So du token cua account
    function getBalances(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function getBalancesContract() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalancesAccountInContract(address _account)
        public
        view
        returns (uint256)
    {
        return balancesEth[_account];
    }

    function getEtherAccount(address _account) public view returns (uint256) {
        return _account.balance;
    }

    // So luong token dc owner cung cap
    function mint(address _address, uint256 _amount) public onlyOwner {
        totalSupply = totalSupply.add(_amount);
        balances[_address] = balances[_address].add(_amount);
        emit Transfer(_address, _address, _amount);
    }

    // So luong token cua owner huy di bot
    function burn(address _address, uint256 _amount)
        public
        onlyOwner
        checkBalances(_address, _amount)
    {
        // require(balances[_address] >= _amount, "_amount lon hon luong token cua owner");
        require(totalSupply >= _amount, "_amount lon hon totalSupply");
        totalSupply = totalSupply.sub(_amount);
        balances[_address] = balances[_address].sub(_amount);
        emit Transfer(_address, _address, _amount);
    }

    // Tang nguoi dung token khi lan dau khi ket noi vi
    function sendFreeToken(address _to)
        public
        onlyOwner
        checkBalances(msg.sender, freeToken())
    {
        balances[msg.sender] = balances[msg.sender].sub(freeToken());
        balances[_to] = balances[msg.sender].add(freeToken());
    }

    // Chuyen ether den owner de mua hang
    function sendEthToAccounts(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    function sumAmount(uint256[] memory _amount)
        internal
        pure
        returns (uint256)
    {
        uint256 sum;
        for (uint256 i = 0; i < _amount.length; i++) {
            sum += _amount[i];
        }
        return sum;
    }

    // chuyen token cho nhau
    function transferToken(
        address _from,
        address _to,
        uint256 _amount
    ) public checkBalances(_from, _amount) {
        // require(balances[_from] >= _amount, "Ko hop le");
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    // chuyen token cho nhieu ng voi cung 1 so luong token
    function transfersToken(
        address _from,
        address[] memory _to,
        uint256 _amount
    ) public {
        require(balances[_from] >= (_amount * _to.length), "Ko hop le");
        for (uint i = 0; i < _to.length; i++) {
            balances[_from] = balances[_from].sub(_amount);
            balances[_to[i]] = balances[_to[i]].add(_amount);
        }
    }

    // Chuyen token cho nhieu nguoi khac so luong
    function transfersTokenAmounts(
        address _from,
        address[] memory _to,
        uint256[] memory _amount
    ) public {
        require(_to.length == _amount.length, "Ko hop le");
        require(balances[_from] >= sumAmount(_amount), "Khong hop le");
        for (uint i = 0; i < _to.length; i++) {
            balances[_from] = balances[_from].sub(_amount[i]);
            balances[_to[i]] = balances[_to[i]].add(_amount[i]);
        }
    }

    // gui tien contract
    function deposit(uint256 _amount) public payable {
        require(msg.value == _amount);
        balancesEth[msg.sender] = balancesEth[msg.sender].add(_amount);
        balances[msg.sender] = balances[msg.sender].add(
            (msg.value / 1 ether) * swapEthToToken()
        );
    }

    // rut tien tu contract
    function withdraw(address payable _account) public payable onlyOwner {
        _account.transfer(address(this).balance);
    }

    // // chuyen eth vao contract
    // fallback() external payable{
    //     balances[msg.sender] = balances[msg.sender].add((msg.value / 1 ether) * 100);
    //     balancesEth[msg.sender] = balancesEth[msg.sender].add(msg.value / 1 ether);
    // }

    // receive() external payable {}
}