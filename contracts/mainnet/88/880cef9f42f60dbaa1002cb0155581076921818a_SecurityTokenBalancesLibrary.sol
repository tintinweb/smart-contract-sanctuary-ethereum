/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// File: contracts/libraries/IterableBalances.sol

pragma solidity 0.6.7;

/// @dev Models a address -> uint mapping where it is possible to iterate over all keys.
library IterableBalances {
    struct iterableBalances {
        mapping(address => Balances) balances;
        KeyFlag[] keys;
        uint256 size;
    }

    struct Balances {
        uint256 keyIndex;
        uint256 balance;
        uint256 locked;
    }
    struct KeyFlag {
        address key;
        bool deleted;
    }

    function insert(
        iterableBalances storage self,
        address key,
        uint256 balance
    ) public {
        uint256 keyIndex = self.balances[key].keyIndex;
        self.balances[key].balance = balance;

        if (keyIndex == 0) {
            keyIndex = self.keys.length;
            self.keys.push();
            self.balances[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
        }
    }

    function remove(iterableBalances storage self, address key) public {
        uint256 keyIndex = self.balances[key].keyIndex;

        require(
            keyIndex != 0,
            "Cannot remove balance : key is not in balances"
        );

        delete self.balances[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(iterableBalances storage self, address key)
        public
        view
        returns (bool)
    {
        return self.balances[key].keyIndex > 0;
    }

    function iterate_start(iterableBalances storage self)
        public
        view
        returns (uint256 keyIndex)
    {
        return iterate_next(self, uint256(-1));
    }

    function iterate_valid(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (bool)
    {
        return keyIndex < self.keys.length;
    }

    function iterate_next(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (uint256 r_keyIndex)
    {
        keyIndex++;

        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted) {
            keyIndex++;
        }

        return keyIndex;
    }

    function iterate_get(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (
            address key,
            uint256 balance,
            uint256 locked
        )
    {
        key = self.keys[keyIndex].key;
        balance = self.balances[key].balance;
        locked = self.balances[key].locked;
    }

    event Dummy(); // Needed otherwise typechain has no output
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/libraries/SecurityTokenBalancesLibrary.sol

pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;


/// @dev Models a address -> uint mapping where it is possible to iterate over all keys.
library SecurityTokenBalancesLibrary {
    using IterableBalances for IterableBalances.iterableBalances;
    using SafeMath for uint256;

    struct SecurityTokenBalances {
        address issuer;
        IterableBalances.iterableBalances iterableBalances;
    }

    struct Balance {
        address _address;
        uint256 _balance;
        uint256 _locked;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value); // Only for erc20 explorer

    function setIssuer(SecurityTokenBalances storage self, address key) public {
        self.issuer = key;
    }

    function mint(
        SecurityTokenBalances storage self,
        address key,
        uint256 balance
    ) public {
        require(key == self.issuer, "Only issuer balance can be minted");
        self.iterableBalances.insert(key, balance);
    }

    function lock(
        SecurityTokenBalances storage self,
        address key,
        uint256 valueToLock
    ) public {
        require(
            self.iterableBalances.balances[key].balance -
                self.iterableBalances.balances[key].locked >=
                valueToLock,
            "Can not lock value : insufficient disposable balance"
        );

        self.iterableBalances.balances[key].locked += valueToLock;
    }

    function unlock(
        SecurityTokenBalances storage self,
        address key,
        uint256 valueToUnlock
    ) public {
        require(
            self.iterableBalances.balances[key].balance >= valueToUnlock,
            "Can not unlock value : insufficient balance"
        );
        require(
            self.iterableBalances.balances[key].locked >= valueToUnlock,
            "Can not unlock value : insufficient locked balance"
        );

        self.iterableBalances.balances[key].locked -= valueToUnlock;
    }

    function burn(
        SecurityTokenBalances storage self,
        address _from,
        uint256 _value
    ) public {
        require(
            self.iterableBalances.balances[_from].balance -
                self.iterableBalances.balances[_from].locked >=
                _value,
            "Can not burn value : insufficient disposable balance"
        );

        self.iterableBalances.balances[_from].balance -= _value;

        emit Transfer(_from, address(0), _value);
    }

    function transferLocked(
        SecurityTokenBalances storage self,
        address _from,
        address _to,
        uint256 _value
    ) external {
        unlock(self, _from, _value);

        self.iterableBalances.balances[_from].balance -= _value;

        self.iterableBalances.insert(
            _to,
            self.iterableBalances.balances[_to].balance + _value
        );

        emit Transfer(_from, _to, _value);
    }

    function getBalance(SecurityTokenBalances storage self, address _address)
        external
        view
        returns (uint256 balance)
    {
        return self.iterableBalances.balances[_address].balance;
    }

    function getFullBalance(
        SecurityTokenBalances storage self,
        address _address
    ) external view returns (Balance memory value) {
        return
            Balance(
                _address,
                self.iterableBalances.balances[_address].balance,
                self.iterableBalances.balances[_address].locked
            );
    }

    function getFullBalances(SecurityTokenBalances storage self)
        public
        view
        returns (Balance[] memory value)
    {
        address tokenHolder = address(0);
        uint256 balance;
        uint256 locked;
        uint256 balancesSize = self.iterableBalances.size;
        Balance[] memory addressBalanceArray = new Balance[](balancesSize);
        for (
            uint256 index = self.iterableBalances.iterate_start();
            self.iterableBalances.iterate_valid(index);
            index = self.iterableBalances.iterate_next(index)
        ) {
            (tokenHolder, balance, locked) = self.iterableBalances.iterate_get(
                index
            );
            addressBalanceArray[index] = Balance(tokenHolder, balance, locked);
        }

        return addressBalanceArray;
    }

    function totalSupply(SecurityTokenBalances storage self)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        uint256 balance;
        uint256 locked;

        for (
            uint256 index = self.iterableBalances.iterate_start();
            self.iterableBalances.iterate_valid(index);
            index = self.iterableBalances.iterate_next(index)
        ) {
            (, balance, locked) = self.iterableBalances.iterate_get(index);

            total += balance + locked;
        }

        return total;
    }
}