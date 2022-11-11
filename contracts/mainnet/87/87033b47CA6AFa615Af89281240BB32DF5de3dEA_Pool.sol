/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a.mul(BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.mul(BASE))});
    }

    function sub(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE), reason)});
    }

    function mul(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.mul(b)});
    }

    function div(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.div(b)});
    }

    function pow(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.value)});
    }

    function sub(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value, reason)});
    }

    function mul(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b)
        private
        pure
        returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 672; // 14 days
    uint256 private constant BOOTSTRAPPING_PRICE = 1078280614764947472; // Should be 0.1 difference between peg

    /* Oracle */
    address private constant CRV3 =
        address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // Anywhere the term CRV3 is refernenced, consider that as "peg", really
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 T

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 T -> 100M TS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START = 1667790000;
    uint256 private constant CURRENT_EPOCH_PERIOD = 1800;

    /* Forge */
    uint256 private constant ADVANCE_INCENTIVE_IN_3CRV = 75 * 10**18; // 75 3CRV
    uint256 private constant ADVANCE_INCENTIVE_IN_T_MAX = 5000 * 10**18; // 5000 T

    uint256 private constant FORGE_EXIT_LOCKUP_EPOCHS = 240; // 5 days fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 144; // 3 days fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 8640; // 180 days
    uint256 private constant DEBT_RATIO_CAP = 20e16; // 20%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 1e16; // 1%
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 2e16; // 2%
    uint256 private constant ORACLE_POOL_RATIO = 50; // 50%
    uint256 private constant TREASURY_RATIO = 0; // 0%

    /* Deployed */
    address private constant TREASURY_ADDRESS =
        address(0x0000000000000000000000000000000000000000);

    /**
     * Getters
     */

    function getCrv3Address() internal pure returns (address) {
        return CRV3;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getCurrentEpochStrategy()
        internal
        pure
        returns (EpochStrategy memory)
    {
        return
            EpochStrategy({
                offset: CURRENT_EPOCH_OFFSET,
                start: CURRENT_EPOCH_START,
                period: CURRENT_EPOCH_PERIOD
            });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_IN_3CRV;
    }

    function getMaxAdvanceTIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_IN_T_MAX;
    }

    function getForgeExitLockupEpochs() internal pure returns (uint256) {
        return FORGE_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getSupplyChangeLimit()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getCouponSupplyChangeLimit()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }
}

contract IDollar is IERC20 {
    function burn(uint256 amount) public;

    function burnFrom(address account, uint256 amount) public;

    function mint(address account, uint256 amount) public returns (bool);
}

contract IForge {
    function epoch() external view returns (uint256);
}

contract PoolAccount {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        uint256 fluidUntil;
    }
}

contract PoolStorage {
    struct Provider {
        IForge dao;
        IDollar dollar;
        IERC20 lpToken;
    }

    struct Balance {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
    }

    struct State {
        Balance balance;
        Provider provider;
        bool paused;
        mapping(address => PoolAccount.State) accounts;
    }
}

contract PoolState {
    PoolStorage.State _state;
}

contract PoolGetters is PoolState {
    using SafeMath for uint256;

    /**
     * Global
     */

    function crv3() public view returns (address) {
        return Constants.getCrv3Address();
    }

    function dao() public view returns (IForge) {
        return _state.provider.dao;
    }

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function lpToken() public view returns (IERC20) {
        return _state.provider.lpToken;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable() public view returns (uint256) {
        return _state.balance.claimable;
    }

    function totalPhantom() public view returns (uint256) {
        return _state.balance.phantom;
    }

    function totalRewarded() public view returns (uint256) {
        return dollar().balanceOf(address(this)).sub(totalClaimable());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable(address account) public view returns (uint256) {
        return _state.accounts[account].claimable;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom(address account) public view returns (uint256) {
        return _state.accounts[account].phantom;
    }

    function balanceOfRewarded(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom
            .mul(balanceOfBonded(account))
            .div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function fluidUntil(address account) public view returns (uint256) {
        return _state.accounts[account].fluidUntil;
    }

    function statusOf(address account)
        public
        view
        returns (PoolAccount.Status)
    {
        return
            epoch() >= _state.accounts[account].fluidUntil
                ? PoolAccount.Status.Frozen
                : PoolAccount.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }
}

contract PoolSetters is PoolState, PoolGetters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function pause() internal {
        _state.paused = true;
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address account, uint256 amount)
        internal
    {
        _state.accounts[account].bonded = _state.accounts[account].bonded.add(
            amount
        );
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementBalanceOfBonded(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.sub(
            amount,
            reason
        );
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementBalanceOfStaged(address account, uint256 amount)
        internal
    {
        _state.accounts[account].staged = _state.accounts[account].staged.add(
            amount
        );
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(
            amount,
            reason
        );
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfClaimable(address account, uint256 amount)
        internal
    {
        _state.accounts[account].claimable = _state
            .accounts[account]
            .claimable
            .add(amount);
        _state.balance.claimable = _state.balance.claimable.add(amount);
    }

    function decrementBalanceOfClaimable(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].claimable = _state
            .accounts[account]
            .claimable
            .sub(amount, reason);
        _state.balance.claimable = _state.balance.claimable.sub(amount, reason);
    }

    function incrementBalanceOfPhantom(address account, uint256 amount)
        internal
    {
        _state.accounts[account].phantom = _state.accounts[account].phantom.add(
            amount
        );
        _state.balance.phantom = _state.balance.phantom.add(amount);
    }

    function decrementBalanceOfPhantom(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.sub(
            amount,
            reason
        );
        _state.balance.phantom = _state.balance.phantom.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(
            Constants.getPoolExitLockupEpochs()
        );
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

interface IMetaPool {
    event Transfer(
        address indexed sender,
        address indexed receiver,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TokenExchange(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event TokenExchangeUnderlying(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 token_supply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_amount,
        uint256 token_supply
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);
    event CommitNewFee(
        uint256 indexed deadline,
        uint256 fee,
        uint256 admin_fee
    );
    event NewFee(uint256 fee, uint256 admin_fee);
    event RampA(
        uint256 old_A,
        uint256 new_A,
        uint256 initial_time,
        uint256 future_time
    );
    event StopRampA(uint256 A, uint256 t);

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _coin,
        uint256 _decimals,
        uint256 _A,
        uint256 _fee,
        address _admin
    ) external;

    function decimals() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function get_previous_balances() external view returns (uint256[2] memory);

    function get_balances() external view returns (uint256[2] memory);

    function get_twap_balances(
        uint256[2] calldata _first_balances,
        uint256[2] calldata _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[2] memory);

    function get_price_cumulative_last()
        external
        view
        returns (uint256[2] memory);

    function admin_fee() external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(
        uint256[2] calldata _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] calldata _balances
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] calldata _balances
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts,
        address _receiver
    ) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _previous
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        address _receiver
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function admin() external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract Liquidity is PoolGetters {
    function addLiquidity(uint256 dollarAmount, uint256 expectedReturn)
        internal
        returns (uint256, uint256)
    {
        IERC20 crv3Token = IERC20(crv3());
        address lpAddress = address(lpToken());
        uint256 balanceWas = lpToken().balanceOf(address(this));

        crv3Token.transferFrom(msg.sender, address(this), dollarAmount);

        if (crv3Token.allowance(address(this), lpAddress) < dollarAmount)
            dollar().approve(lpAddress, 2**256 - 1);

        uint256 crv3Allowed = crv3Token.allowance(address(this), lpAddress);

        if (crv3Allowed > 0 && crv3Allowed < dollarAmount)
            crv3Token.approve(lpAddress, 0);

        if (crv3Allowed == 0 || crv3Allowed < dollarAmount)
            crv3Token.approve(lpAddress, 2**256 - 1);

        IMetaPool(lpAddress).add_liquidity(
            [dollarAmount, dollarAmount],
            expectedReturn
        );

        return (
            dollarAmount,
            lpToken().balanceOf(address(this)).sub(balanceWas)
        );
    }
}

contract Pool is PoolSetters, Liquidity {
    using SafeMath for uint256;

    constructor(address dollar, address lpToken) public {
        _state.provider.dao = IForge(msg.sender);
        _state.provider.dollar = IDollar(dollar);
        _state.provider.lpToken = IERC20(lpToken);
    }

    bytes32 private constant FILE = "Pool";

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Claim(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value);
    event Unbond(
        address indexed account,
        uint256 start,
        uint256 value,
        uint256 newClaimable
    );
    event Provide(
        address indexed account,
        uint256 value,
        uint256 lessCrv3,
        uint256 lpAmount
    );

    function deposit(uint256 value) external onlyFrozen(msg.sender) notPaused {
        lpToken().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        balanceCheck();

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozen(msg.sender) {
        lpToken().transfer(msg.sender, value);
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Pool: insufficient staged balance"
        );

        balanceCheck();

        emit Withdraw(msg.sender, value);
    }

    function claim(uint256 value) external onlyFrozen(msg.sender) {
        dollar().transfer(msg.sender, value);
        decrementBalanceOfClaimable(
            msg.sender,
            value,
            "Pool: insufficient claimable balance"
        );

        balanceCheck();

        emit Claim(msg.sender, value);
    }

    function bond(uint256 value) external notPaused {
        unfreeze(msg.sender);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 newPhantom = totalBonded() == 0
            ? totalRewarded() == 0
                ? Constants.getInitialStakeMultiple().mul(value)
                : 0
            : totalRewardedWithPhantom.mul(value).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, value);
        incrementBalanceOfPhantom(msg.sender, newPhantom);
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Pool: insufficient staged balance"
        );

        balanceCheck();

        emit Bond(msg.sender, epoch().add(1), value);
    }

    function unbond(uint256 value) external {
        unfreeze(msg.sender);

        uint256 balanceOfBonded = balanceOfBonded(msg.sender);
        Require.that(balanceOfBonded > 0, FILE, "insufficient bonded balance");

        uint256 newClaimable = balanceOfRewarded(msg.sender).mul(value).div(
            balanceOfBonded
        );
        uint256 lessPhantom = balanceOfPhantom(msg.sender).mul(value).div(
            balanceOfBonded
        );

        incrementBalanceOfStaged(msg.sender, value);
        incrementBalanceOfClaimable(msg.sender, newClaimable);
        decrementBalanceOfBonded(
            msg.sender,
            value,
            "Pool: insufficient bonded balance"
        );
        decrementBalanceOfPhantom(
            msg.sender,
            lessPhantom,
            "Pool: insufficient phantom balance"
        );

        balanceCheck();

        emit Unbond(msg.sender, epoch().add(1), value, newClaimable);
    }

    function provide(uint256 value, uint256 expectedReturn)
        external
        onlyFrozen(msg.sender)
        notPaused
    {
        Require.that(totalBonded() > 0, FILE, "insufficient total bonded");

        Require.that(totalRewarded() > 0, FILE, "insufficient total rewarded");

        Require.that(
            balanceOfRewarded(msg.sender) >= value,
            FILE,
            "insufficient rewarded balance"
        );

        (uint256 lessCrv3, uint256 lpAmount) = addLiquidity(
            value,
            expectedReturn
        );

        uint256 totalRewardedWithPhantom = totalRewarded()
            .add(totalPhantom())
            .add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom
            .mul(lpAmount)
            .div(totalBonded());

        incrementBalanceOfBonded(msg.sender, lpAmount);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));

        balanceCheck();

        emit Provide(msg.sender, value, lessCrv3, lpAmount);
    }

    function setDao(IForge _dao) external onlyDao {
        _state.provider.dao = _dao;
    }

    function emergencyWithdraw(address token, uint256 value) external onlyDao {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause() external onlyDao {
        pause();
    }

    function balanceCheck() private {
        Require.that(
            lpToken().balanceOf(address(this)) >=
                totalStaged().add(totalBonded()),
            FILE,
            "Inconsistent UNI-V2 balances"
        );
    }

    modifier onlyFrozen(address account) {
        Require.that(
            statusOf(account) == PoolAccount.Status.Frozen,
            FILE,
            "Not frozen"
        );

        _;
    }

    modifier onlyDao() {
        Require.that(msg.sender == address(dao()), FILE, "Not dao");

        _;
    }

    modifier notPaused() {
        Require.that(!paused(), FILE, "Paused");

        _;
    }
}