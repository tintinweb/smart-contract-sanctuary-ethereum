//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ReferrioEscrow {
    using SafeMath for uint256;
    using Address for address;

    //VARIABLES
    address public referrioMasterAddress; // contract owner
    address payable public referrioTaxAddress; // where to transfer tax
    mapping(string => Account) public account;
    mapping(string => mapping(string => Opportunity)) public opportunity;
    mapping(string => string) public opportunityAccountId;

    uint256 public defaultAccountFee = 0; // percentage
    uint256 public defaultOpportunityFee = 0; // percentage
    TaxType public defaultTaxType = TaxType.ACCOUNT;
    bool public publicCreateOpportunityToggle = false;
    bool public publicCreateOpportunityWithFeeToggle = false;

    PayType public payType;

    //ENUM
    enum PayType {
        REFERRER,
        REFEREE,
        BOTH
    }

    enum TaxType {
        ACCOUNT,
        OPPORTUNITY
    }

    enum AccountStatus {
        NONE,
        ACTIVE,
        DISABLED
    }
    //STRUCT
    struct Account {
        uint256 balance;
        uint256 fee;
        AccountStatus status;
        TaxType taxType;
    }

    struct Opportunity {
        uint256 amount;
        bool cancelled;
        bool paid;
        bool active;
        uint256 fee;
    }

    //EVENTS
    event Received(address recipient, uint256 amount);
    event Withdrawed(address recipient, uint256 amount);
    event SetMapping(string opportunityId);
    event Deposited(address fromAddress, uint256 amount, string accountId);
    event CreateOpportunity(
        string accountId,
        string opportunityId,
        uint256 opportunityReward,
        address walletAddress,
        uint256 fee
    );
    event CreateOpportunityWithFee(
        string accountId,
        string opportunityId,
        uint256 opportunityReward,
        address walletAddress,
        uint256 fee
    );
    event TakeTax(
        string accountId,
        uint256 taxAmount,
        uint256 payoutAmount,
        uint256 amount,
        TaxType TaxType
    );
    event PaidReferrer(
        string accountId,
        string opportunityId,
        address recipient,
        uint256 amount
    );
    event PaidReferee(
        string accountId,
        string opportunityId,
        address recipient,
        uint256 amount
    );
    event CancelledOpportunity(
        string accountId,
        string opportunityId,
        uint256 amountCancelled
    );

    //MODIFIERS
    modifier onlyReferrio() {
        require(
            referrioMasterAddress == msg.sender,
            "onlyReferrio: Must be a Refferio Address"
        );
        _;
    }

    modifier publicCreateOpportunity() {
        require(
            publicCreateOpportunityToggle == true ||
                referrioMasterAddress == msg.sender,
            "publicCreateOpportunity: cannot create opportunity, publicCreateOpportunityToggle is false or use the master address"
        );
        _;
    }

    modifier publicCreateOpportunityWithFee() {
        require(
            publicCreateOpportunityWithFeeToggle == true ||
                referrioMasterAddress == msg.sender,
            "publicCreateOpportunity: cannot create opportunity with fee, publicCreateOpportunityWithFeeToggle is false or use the master address"
        );
        _;
    }

    constructor(
        address _referrioMasterAddress,
        address payable _referrioTaxAddress
    ) {
        referrioMasterAddress = _referrioMasterAddress;
        referrioTaxAddress = _referrioTaxAddress;
    }

    //FUNCTIONS
    // fall-back logic - direct transfers of ETH or ERC20
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    //
    // Business Functions
    //

    // Depeosit to account
    function deposit(string memory _accountId) external payable {
        // check if account is locked
        require(
            account[_accountId].status != AccountStatus.DISABLED,
            "deposit: Account is disabled"
        );

        account[_accountId].balance = account[_accountId].balance.add(
            msg.value
        );

        // if statement - if first time create
        account[_accountId].fee = defaultAccountFee;

        // if first time creation
        if (account[_accountId].status == AccountStatus.NONE) {
            account[_accountId].status = AccountStatus.ACTIVE;
            account[_accountId].taxType = defaultTaxType;
        }

        emit Deposited(msg.sender, msg.value, _accountId);
    }

    // Deposit tx need to complete first before being able to create
    // As this creates an account
    function createOpportunity(
        string memory _accountId,
        string memory _opportunityId,
        uint256 _opportunityReward
    ) external payable publicCreateOpportunity {
        // check if account is disbled or doesnt exists
        require(
            account[_accountId].status == AccountStatus.ACTIVE,
            "createOpportunity: Account not active or does not exists"
        );

        require(
            _opportunityReward > 0,
            "createOpportunity: Reward must be greater than 0"
        );

        // prevents duplicate opps
        require(
            opportunity[_accountId][_opportunityId].active == false,
            "createOpportunity: Opportunity already exists"
        );

        // Opportunity settings
        opportunity[_accountId][_opportunityId].amount = opportunity[
            _accountId
        ][_opportunityId].amount.add(_opportunityReward);
        opportunity[_accountId][_opportunityId].active = true;
        opportunity[_accountId][_opportunityId].fee = defaultOpportunityFee;

        // Others
        opportunityAccountId[_opportunityId] = _accountId;

        // Event
        emit CreateOpportunity(
            _accountId,
            _opportunityId,
            _opportunityReward,
            msg.sender,
            defaultOpportunityFee
        );
    }

    function createOpportunityWithFee(
        string memory _accountId,
        string memory _opportunityId,
        uint256 _opportunityReward,
        uint256 _fee
    ) external payable publicCreateOpportunityWithFee {
        // check if account is disbled or doesnt exists
        require(
            account[_accountId].status == AccountStatus.ACTIVE,
            "createOpportunity: Account not active or does not exists"
        );

        // prevents duplicate opps
        require(
            opportunity[_accountId][_opportunityId].active == false,
            "createOpportunity: Opportunity already exists"
        );

        require(
            _opportunityReward > 0,
            "createOpportunity: Reward must be greater than 0"
        );

        require(_fee > 0, "createOpportunity: Fee must be greater than 0");
        // Opportunity settings
        opportunity[_accountId][_opportunityId].amount = opportunity[
            _accountId
        ][_opportunityId].amount.add(_opportunityReward);
        opportunity[_accountId][_opportunityId].active = true;
        opportunity[_accountId][_opportunityId].fee = _fee;

        // Others
        opportunityAccountId[_opportunityId] = _accountId;

        // Event
        emit CreateOpportunityWithFee(
            _accountId,
            _opportunityId,
            _opportunityReward,
            msg.sender,
            _fee
        );
    }

    function pay(
        string memory _opportunityId,
        address payable _recipient,
        PayType _payType
    ) external onlyReferrio {
        string memory accountId = opportunityAccountId[_opportunityId];
        require(
            account[accountId].balance >=
                opportunity[accountId][_opportunityId].amount,
            "pay: Insufficient balance on account"
        );
        // check if account is disbled or doesnt exists
        require(
            account[accountId].status == AccountStatus.ACTIVE,
            "pay: Account not active or does not exists"
        );

        require(
            opportunity[accountId][_opportunityId].active == true,
            "pay: opportunity not active"
        );

        uint256 afterTax = _takeTax(
            _opportunityId,
            opportunity[accountId][_opportunityId].amount
        );

        (bool success, ) = _recipient.call{value: afterTax}("");
        require(
            success,
            "pay: unable to send value, recipient may have reverted"
        );

        account[accountId].balance = account[accountId].balance.sub(
            opportunity[accountId][_opportunityId].amount
        );

        if (_payType == PayType.REFERRER) {
            emit PaidReferrer(accountId, _opportunityId, _recipient, afterTax);
        } else {
            emit PaidReferee(accountId, _opportunityId, _recipient, afterTax);
        }
    }

    function _takeTax(string memory _opportunityId, uint256 _amount)
        private
        returns (uint256)
    {
        uint256 taxAmount;
        uint256 payoutAmount;

        string memory accountId = opportunityAccountId[_opportunityId];
        TaxType taxType = account[accountId].taxType;

        uint256 fee = taxType == TaxType.OPPORTUNITY
            ? opportunity[accountId][_opportunityId].fee
            : account[accountId].fee;

        if (fee > 0) {
            taxAmount = _amount.mul(fee).div(10**2);
            payoutAmount = _amount.sub(taxAmount);

            // transfer tax
            referrioTaxAddress.transfer(taxAmount);
        } else {
            payoutAmount = _amount;
        }

        emit TakeTax(accountId, taxAmount, payoutAmount, _amount, taxType);

        return payoutAmount;
    }

    function cancelOpportunity(string memory _opportunityId)
        external
        onlyReferrio
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        Opportunity memory _opportunity = opportunity[accountId][
            _opportunityId
        ];
        Account memory _account = account[accountId];
        require(
            _opportunity.active == true,
            "cancel: opportunity is not active"
        );
        // check if account is disbled or doesnt exists
        require(
            _account.status == AccountStatus.ACTIVE,
            "cancel: Account not active or does not exists"
        );
        require(
            _opportunity.cancelled == false,
            "cancel: opportunity already cancelled"
        );
        require(_opportunity.paid == false, "cancel: opportunity already paid");

        opportunity[accountId][_opportunityId].cancelled = true;
        opportunity[accountId][_opportunityId].active = false;
        opportunity[accountId][_opportunityId].paid = false;

        emit CancelledOpportunity(
            accountId,
            _opportunityId,
            _opportunity.amount
        );
    }

    //
    // GET FUNCTIONS
    //
    function getAccountBalance(string memory _accountId)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        return account[_accountId].balance;
    }

    function getAccountFee(string memory _accountId)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        return account[_accountId].fee;
    }

    function getAccountStatus(string memory _accountId)
        external
        view
        onlyReferrio
        returns (AccountStatus)
    {
        return account[_accountId].status;
    }

    function getAccountTaxType(string memory _accountId)
        external
        view
        onlyReferrio
        returns (TaxType)
    {
        return account[_accountId].taxType;
    }

    function getOpportunityFee(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        return opportunity[accountId][_opportunityId].fee;
    }

    function getOpportunityActiveStatus(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (bool)
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        return opportunity[accountId][_opportunityId].active;
    }

    function getOpportunityPaidStatus(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (bool)
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        return opportunity[accountId][_opportunityId].paid;
    }

    function getOpportunityAmount(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        return opportunity[accountId][_opportunityId].amount;
    }

    function getOpportunityCancelledStatus(string memory _opportunityId)
        external
        view
        onlyReferrio
        returns (bool)
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        return opportunity[accountId][_opportunityId].cancelled;
    }

    //
    // SET FUNCTIONS
    //
    function setAccountTaxType(string memory _accountId, TaxType _taxType)
        external
        onlyReferrio
    {
        account[_accountId].taxType = _taxType;
    }

    function setAccountTaxFee(string memory _accountId, uint256 _taxFee)
        external
        onlyReferrio
    {
        require(_taxFee >= 0, "setAccountTaxFee: Tax fee must be 0 or greater");
        account[_accountId].fee = _taxFee;
    }

    function setAccountStatus(string memory _accountId, AccountStatus _status)
        external
        onlyReferrio
    {
        account[_accountId].status = _status;
    }

    function setOpportunityTaxFee(string memory _opportunityId, uint256 _taxFee)
        external
        onlyReferrio
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        opportunity[accountId][_opportunityId].fee = _taxFee;
    }

    function setOpportunityActiveStatus(
        string memory _opportunityId,
        bool _state
    ) external onlyReferrio {
        string memory accountId = opportunityAccountId[_opportunityId];
        opportunity[accountId][_opportunityId].active = _state;
    }

    function setOpportunityPaidStatus(string memory _opportunityId, bool _state)
        external
        onlyReferrio
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        opportunity[accountId][_opportunityId].paid = _state;
    }

    function setOpportunityCancelledStatus(
        string memory _opportunityId,
        bool _state
    ) external onlyReferrio {
        string memory accountId = opportunityAccountId[_opportunityId];
        opportunity[accountId][_opportunityId].cancelled = _state;
    }

    function setOpportunityAmount(string memory _opportunityId, uint256 _amount)
        external
        onlyReferrio
    {
        string memory accountId = opportunityAccountId[_opportunityId];
        opportunity[accountId][_opportunityId].amount = _amount;
    }

    function setOpportunityAccount(
        string memory _opportunityId,
        string memory _accountId
    ) external onlyReferrio {
        opportunityAccountId[_opportunityId] = _accountId;
    }

    function setReferrioMasterAddress(address _address) external onlyReferrio {
        referrioMasterAddress = _address;
    }

    function setReferrioTaxAddress(address payable _address)
        external
        onlyReferrio
    {
        referrioTaxAddress = _address;
    }

    function setDefaultAccountTaxFee(uint256 _fee) external onlyReferrio {
        defaultAccountFee = _fee;
    }

    function setDefaultOpportunityTaxFee(uint256 _fee) external onlyReferrio {
        defaultOpportunityFee = _fee;
    }

    function setPublicCreateOpportunity(bool _toggle) external onlyReferrio {
        publicCreateOpportunityToggle = _toggle;
    }

    function setPublicCreateOpportunityWithFee(bool _toggle)
        external
        onlyReferrio
    {
        publicCreateOpportunityWithFeeToggle = _toggle;
    }

    //
    // MIGRATION HELPERS
    //
    function withdrawETH(address payable _recipient, uint256 _amount)
        external
        onlyReferrio
    {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(
            success,
            "withdrawETH: unable to send value, recipient may have reverted"
        );
        emit Withdrawed(_recipient, _amount);
    }

    function getBalanceETH() external view returns (uint256) {
        return address(this).balance;
    }

    // ERC20 Accidental Transfers
    function withdrawERC20(
        ERC20 _tokenAddress,
        address payable _recipient,
        uint256 _amount
    ) external onlyReferrio {
        ERC20 token = ERC20(_tokenAddress);
        token.transfer(_recipient, _amount);
    }

    function getBalanceERC20(ERC20 _tokenAddress)
        external
        view
        onlyReferrio
        returns (uint256)
    {
        ERC20 token = ERC20(_tokenAddress);
        return token.balanceOf(address(this));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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