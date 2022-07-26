/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// File: contracts/libraries/IterableBalances.sol

pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

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

// File: contracts/libraries/BasicTokenLibrary.sol

pragma solidity 0.6.7;

library BasicTokenLibrary {
    struct BasicToken {
        address owner;
        uint256 initialSupply;
        uint256 currentSupply;
        string name;
        string symbol;
        string isinCode;
        address settler;
        address registrar;
        SecurityTokenBalancesLibrary.SecurityTokenBalances securityTokenBalances;
    }
    event Dummy(); // Needed otherwise typechain has no output

    struct BasicTokenInput {
        uint256 initialSupply;
        string isinCode;
        string name;
        string symbol;
        uint256 denomination;
        uint256 divisor;
        uint256 startDate;
        uint256 initialMaturityDate;
        uint256 firstCouponDate;
        uint256 couponFrequencyInMonths;
        uint256 interestRateInBips;
        bool callable;
        bool isSoftBullet;
        uint256 softBulletPeriodInMonths;
        string currency;
        address registrarAddress;
        address settlerAgentAddress;
        address issuerAddress;
    }

    struct Bond {
        uint256 denomination;
        uint256 divisor;
        uint256 startDate;
        uint256 maturityDate;
        uint256 currentMaturityDate;
        uint256 firstCouponDate;
        uint256 couponFrequencyInMonths;
        uint256 interestRateInBips;
        bool callable;
        bool isSoftBullet;
        uint256 softBulletPeriodInMonths;
        string termsheetUrl;
        string currency;
        mapping(address => uint256) tokensToBurn;
        uint256 state;
    }
}

// File: contracts/libraries/SettlementRepositoryLibrary.sol

pragma solidity 0.6.7;



library SettlementRepositoryLibrary {
    using SecurityTokenBalancesLibrary for SecurityTokenBalancesLibrary.SecurityTokenBalances;
    using SettlementRepositoryLibrary for SettlementRepositoryLibrary.SettlementTransactionRepository;

    using BasicTokenLibrary for BasicTokenLibrary.BasicToken;

    uint256 private constant CREATED = 0x01;
    uint256 private constant TOKEN_LOCKED = 0x02;
    uint256 private constant CASH_RECEIVED = 0x03;
    uint256 public constant CASH_TRANSFERRED = 0x04;
    uint256 private constant ERROR = 0xFF;

    struct SettlementTransactionRepository {
        mapping(uint256 => SettlementTransaction) settlementTransactionById; // mapping ( settlementtransactionId => settlementtransaction)
        mapping(uint256 => uint256) operationTypeByOperationId; // operationId -> operationType
    }

    struct SettlementTransaction {
        uint256 txId;
        uint256 operationId;
        address deliverySenderAccountNumber;
        address deliveryReceiverAccountNumber;
        uint256 deliveryQuantity;
        uint256 status;
        string txHash;
    }

    struct PartialSettlementTransaction {
        uint256 txId;
        uint256 operationId;
        address deliverySenderAccountNumber; // redemption investor - subscription issuer
        address deliveryReceiverAccountNumber; // redemption issuer - subscription investor
        uint256 deliveryQuantity;
        string txHash;
    }

    function getSettlementTransactionById(
        SettlementTransactionRepository storage settlementTransactionRepository,
        uint256 id
    ) public view returns (SettlementTransaction memory) {
        SettlementTransaction storage settlementTransaction =
            settlementTransactionRepository.settlementTransactionById[id];

        return settlementTransaction;
        // the return will be copied on memory to ensure no unwanted mutation
        // can be done. This have an impact on gas consumption as memory
        // expansion cost gas.
    }

    function setSettlementTransactionStatus(
        SettlementTransactionRepository storage settlementTransactionRepository,
        uint256 txId,
        uint256 status
    ) internal {
        require(
            status == CREATED ||
                status == TOKEN_LOCKED ||
                status == CASH_RECEIVED ||
                status == CASH_TRANSFERRED ||
                status == ERROR,
            "Can not set status : Invalid Status"
        );

        SettlementTransaction storage settlementTransaction =
            settlementTransactionRepository.settlementTransactionById[txId];
        settlementTransaction.status = status;
    }

    function createSettlementTransaction(
        SettlementTransactionRepository storage settlementTransactionRepository,
        PartialSettlementTransaction memory partialSettlementTransaction
    ) internal {
        require(
            settlementTransactionRepository.settlementTransactionById[
                partialSettlementTransaction.txId
            ]
                .txId != partialSettlementTransaction.txId,
            "Settlement Transaction already exist with this id"
        );

        SettlementTransaction memory newSettlementTransaction =
            SettlementTransaction({
                txId: partialSettlementTransaction.txId,
                operationId: partialSettlementTransaction.operationId,
                deliverySenderAccountNumber: partialSettlementTransaction
                    .deliverySenderAccountNumber,
                deliveryReceiverAccountNumber: partialSettlementTransaction
                    .deliveryReceiverAccountNumber,
                deliveryQuantity: partialSettlementTransaction.deliveryQuantity,
                txHash: partialSettlementTransaction.txHash,
                status: CREATED
            });
        settlementTransactionRepository.settlementTransactionById[
            partialSettlementTransaction.txId
        ] = newSettlementTransaction;
    }

    // Operation type management

    function getOperationType(
        SettlementTransactionRepository storage settlementTransactionRepository,
        uint256 _operationId
    ) external view returns (uint256) {
        return
            settlementTransactionRepository.operationTypeByOperationId[
                _operationId
            ];
    }

    function getOperationTypeForSettlementTransaction(
        SettlementTransactionRepository storage settlementTransactionRepository,
        uint256 _settlementTransactionId
    ) external view returns (uint256) {
        return
            settlementTransactionRepository.operationTypeByOperationId[
                settlementTransactionRepository.settlementTransactionById[
                    _settlementTransactionId
                ]
                    .operationId
            ];
    }

    function setOperationType(
        SettlementTransactionRepository storage settlementTransactionRepository,
        uint256 _operationId,
        uint256 _operationType
    ) internal {
        settlementTransactionRepository.operationTypeByOperationId[
            _operationId
        ] = _operationType;
    }
}

// File: contracts/libraries/SettlementWorkflowLibrary.sol

pragma solidity 0.6.7;

library SettlementWorkflowLibrary {
    uint256 private constant CREATED = 0x01;
    uint256 private constant TOKEN_LOCKED = 0x02;
    uint256 private constant CASH_RECEIVED = 0x03;
    uint256 public constant CASH_TRANSFERRED = 0x04;
    uint256 private constant ERROR = 0xFF;

    uint256 private constant SUBSCRIPTION = 0x01;
    uint256 private constant REDEMPTION = 0x02;
    uint256 private constant TRADE = 0x03;

    using SettlementRepositoryLibrary for SettlementRepositoryLibrary.SettlementTransactionRepository;
    using SecurityTokenBalancesLibrary for SecurityTokenBalancesLibrary.SecurityTokenBalances;

    function initiateDVP(
        SettlementRepositoryLibrary.SettlementTransactionRepository
            storage settlementTransactionRepository,
        BasicTokenLibrary.BasicToken storage token,
        uint256 settlementTransactionId
    ) public {
        SettlementRepositoryLibrary.SettlementTransaction memory st =
            settlementTransactionRepository.getSettlementTransactionById(
                settlementTransactionId
            );

        token.securityTokenBalances.lock(
            st.deliverySenderAccountNumber,
            st.deliveryQuantity
        );

        settlementTransactionRepository.setSettlementTransactionStatus(
            settlementTransactionId,
            TOKEN_LOCKED
        );
    }

    function initiateSubscription(
        SettlementRepositoryLibrary.SettlementTransactionRepository
            storage settlementTransactionRepository,
        BasicTokenLibrary.BasicToken storage token,
        SettlementRepositoryLibrary.PartialSettlementTransaction
            memory partialSettlementTransaction
    ) public {
        settlementTransactionRepository.createSettlementTransaction(
            partialSettlementTransaction
        );

        initiateDVP(
            settlementTransactionRepository,
            token,
            partialSettlementTransaction.txId
        );

        settlementTransactionRepository.setOperationType(
            partialSettlementTransaction.operationId,
            SUBSCRIPTION
        );
    }

    function initiateTrade(
        SettlementRepositoryLibrary.SettlementTransactionRepository
            storage settlementTransactionRepository,
        BasicTokenLibrary.BasicToken storage token,
        SettlementRepositoryLibrary.PartialSettlementTransaction
            memory partialSettlementTransaction
    ) public {
        settlementTransactionRepository.createSettlementTransaction(
            partialSettlementTransaction
        );

        initiateDVP(
            settlementTransactionRepository,
            token,
            partialSettlementTransaction.txId
        );

        settlementTransactionRepository.setOperationType(
            partialSettlementTransaction.operationId,
            TRADE
        );
    }

    function initiateRedemption(
        SettlementRepositoryLibrary.SettlementTransactionRepository
            storage settlementTransactionRepository,
        BasicTokenLibrary.BasicToken storage token,
        SettlementRepositoryLibrary.PartialSettlementTransaction[]
            memory partialSettlementTransactions
    ) public {
        for (uint256 i = 0; i < partialSettlementTransactions.length; i++) {
            settlementTransactionRepository.createSettlementTransaction(
                partialSettlementTransactions[i]
            );

            initiateDVP(
                settlementTransactionRepository,
                token,
                partialSettlementTransactions[i].txId
            );
        }

        settlementTransactionRepository.setOperationType(
            partialSettlementTransactions[0].operationId,
            REDEMPTION
        );
    }
}