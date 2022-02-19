/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

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
    function transferFrom(
        address sender,
        address recipient,
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

// TODO: refactor
// TODO: add require(if they need)
// TODO: add comments
// TODO: add emits

contract CryptoStribe is Context, Ownable {
    using Address for address;

    modifier paymentIdCheck(uint256 payment_id) {
        require(
            0 < payment_id && payment_id < GetPaymentsLength(),
            "Incorrect payment id"
        );
        _;
    }

    modifier paymentActiveCheck(uint256 payment_id) {
        require(
            _payments[payment_id].is_active,
            "This payment not active now"
        );
        _;
    }

    event PaymentCreated(
        address indexed service_provider_address,
        address ERC20_address,
        bool is_native_token,
        uint256 price,
        PaymentType indexed payment_type,
        uint256 creation_timestamp,
        uint256 trial_time,
        uint256 payment_period,
        uint256 indexed payment_id
    );

    event PaymentDeactivated(
        uint256 indexed payment_id
    );

    event PaymentActivated(
        uint256 indexed payment_id
    );

    event PaymentApproved(
        uint256 indexed payment_id,
        address indexed billing_address,
        uint256 indexed billing_id,
        uint256 creation_timestamp,
        uint256 last_payment_timestamp,
        PaymentStatus payment_status
    );

    event PaymentExecuted(
        uint256 indexed payment_id,
        address indexed billing_address,
        uint256 indexed billing_id
    );

    event SubscriptionCanceled(
        uint256 indexed payment_id,
        address indexed billing_address,
        uint256 indexed billing_id
    );

    event WithdrawSuccessful(
        address indexed recipient,
        bool is_native_token,
        uint256 timestamp
    );

    enum PaymentType {
        SUBSCRIPTION,
        ONE_TIME_PAYMENT
    }

    struct Payment {
        address service_provider_address;
        address ERC20_address;
        bool is_native_token;
        uint256 price;
        PaymentType payment_type; 
        uint256 creation_timestamp;
        uint256 trial_time;
        uint256 payment_period;
        uint256 payment_id;
        bool is_active;
    }

    enum PaymentStatus {
        CREATED,
        TRIAL,  
        ACTIVE,
        DECLINE,
        CANCELED
    }

    struct Payer {
        uint256 payment_id;
        address billing_address;
        uint256 billing_id;
        uint256 creation_timestamp;
        uint256 last_payment_timestamp;
        PaymentStatus payment_status;
        uint256 payer_id;
    }

    Payment[] private _payments;

    Payer[] private _payers;
    mapping(uint256 => mapping(uint256 => uint256)) private _payment_id_billing_id_to_payer_id;
    mapping(address => mapping(address => uint256)) private _service_provider_ERC20_earnings;
    mapping(address => uint256) private _service_provider_native_earnings;
    
    uint256 public comission_precent = 10;
    mapping(address => uint256) private _commission_ERC20_earnings;
    uint256 private _commission_native_earnings;

    constructor() {
        _payers.push({});
        _payments.push({});
    }

    receive() payable external {
        _service_provider_native_earnings[owner()] += msg.value;
    }

    function _AmountWithCommission(
        uint256 amount
    ) private view returns (uint256, uint256) {
        uint256 commission = amount * comission_precent / 100;
        return (amount - commission, commission);
    }

    function _GetPayerId(
        uint256 payment_id,
        uint256 billing_id
    ) private view returns (uint256) {
        require(
            _payment_id_billing_id_to_payer_id[payment_id][billing_id] != 0,
            "Payer not found"
        );
        return _payment_id_billing_id_to_payer_id[payment_id][billing_id];
    }

    function GetPaymentsLength() public view returns (uint256) {
        return _payments.length;
    }

    function GetPayersLength() public view returns (uint256) {
        return _payers.length;
    }

    function IsPaymentActive(uint256 payment_id) public view returns (bool) {
        return _payments[payment_id].is_active;
    }

    function GetPayment(uint256 payment_id) public view paymentIdCheck(payment_id) returns (Payment memory) {
        return _payments[payment_id];
    }

    function GetPayments(
        uint256[] memory payment_ids
    ) public view returns (Payment[] memory) {
        Payment[] memory payments = new Payment[](payment_ids.length);

        for (uint256 i = 0; i < payment_ids.length; i++) {
            payments[i] = GetPayment(payment_ids[i]);
        }

        return payments;
    }

    function GetPayer(
        uint256 payment_id,
        uint256 billing_id
    ) public view returns(Payer memory) {   
        return _payers[_GetPayerId(payment_id, billing_id)];
    }

    function GetPayers(
        uint256[] memory payment_ids,
        uint256[] memory billing_ids
    ) public view returns(Payer[] memory) {
        require(
            payment_ids.length == billing_ids.length,
            "Arrays must have the same length"
        );
        Payer[] memory payers = new Payer[](payment_ids.length);

        for (uint256 i = 0; i < payment_ids.length; i++) {
            payers[i] =  _payers[_GetPayerId(payment_ids[i], billing_ids[i])];
        }

        return payers;
    }

    function GetPayerByPayerId(
        uint256 payer_id
    ) public view returns(Payer memory) {
        require(
            0 <= payer_id && payer_id < GetPayersLength(),
            "Payer id incorrect"
        );
        return _payers[payer_id];
    }

    function GetPayersByPayersIds(
        uint256[] memory payer_ids
    ) public view returns(Payer[] memory) {
        Payer[] memory payers = new Payer[](payer_ids.length);

        for (uint256 i = 0; i < payer_ids.length; i++) {
            payers[i] = GetPayerByPayerId(payer_ids[i]);
        }

        return payers;
    }

    function GetPayerStatus(
        uint256 payment_id,
        uint256 billing_id
    ) public view returns(PaymentStatus) {
        return _payers[_GetPayerId(payment_id, billing_id)].payment_status;
    }

    function GetServiceProviderEarnings(
        uint256 payment_id
    ) public view paymentIdCheck(payment_id) returns (uint256) {        
        address service_provider_address = _payments[payment_id].service_provider_address;

        if (_payments[payment_id].is_native_token) {
            return _service_provider_native_earnings[service_provider_address];
        }
        
        return _service_provider_ERC20_earnings[service_provider_address][_payments[payment_id].ERC20_address];
    }

    function GetCommissions(
        bool is_native_token,
        address ERC20_address
    ) public view returns (uint256) {
        require(
            is_native_token && ERC20_address == address(0) ||
            !is_native_token && ERC20_address != address(0) && ERC20_address.isContract(),
            "Payment is possible only in native tokens, or only in ERC20"
        );
        
        if (is_native_token) {
            return _commission_native_earnings;
        }
        
        return _commission_ERC20_earnings[ERC20_address];
    }

    function CreatePayment(
        address ERC20_address,
        bool is_native_token,
        uint256 price,
        PaymentType payment_type,
        uint256 trial_time,
        uint256 payment_period
    ) public returns (uint256 payment_id) {
        require(
            is_native_token && ERC20_address == address(0) ||
            !is_native_token && ERC20_address != address(0) && ERC20_address.isContract(),
            "Payment is possible only in native tokens, or only in ERC20"
        );

        address service_provider_address = _msgSender();
        payment_id = _payments.length;
        _payments.push(
            Payment(
                service_provider_address,
                ERC20_address,
                is_native_token,
                price,
                payment_type,
                block.timestamp,
                trial_time,
                payment_period,
                payment_id,
                true
            )
        );

        emit PaymentCreated(
            service_provider_address,
            ERC20_address,
            is_native_token,
            price,
            payment_type,
            block.timestamp,
            trial_time,
            payment_period,
            payment_id
        );

        return payment_id;
    }

    function DeactivatePayment(uint256 payment_id) public onlyOwner paymentIdCheck(payment_id) returns (bool) {
        require(
            IsPaymentActive(payment_id) == true,
            "This payment already deactivated"
        );

        _payments[payment_id].is_active = false;

        emit PaymentDeactivated(payment_id);

        return true;
    }

    function ActivatePayment(uint256 payment_id) public onlyOwner paymentIdCheck(payment_id) returns (bool) {
        require(
            IsPaymentActive(payment_id) == false,
            "This payment already active"
        );
        _payments[payment_id].is_active = true;

        emit PaymentActivated(payment_id);

        return true;
    }

    function SendERC20Tokens(
        address ERC20_address,
        address sender,
        address recipient,
        uint256 amount,
        address service_provider_address
    ) private returns (bool) {
        bool complite = IERC20(ERC20_address).transferFrom(
                sender,
                recipient,
                amount
        );

        if (complite) {
            uint256 pay;
            uint256 commission;
            (pay, commission) = _AmountWithCommission(amount);
            _service_provider_ERC20_earnings[service_provider_address][ERC20_address] += pay;
            _commission_ERC20_earnings[ERC20_address] += commission;
        }

        return complite;
    }

    function ApprovePayment(
        uint256 payment_id,
        uint256 billing_id
    ) public payable paymentIdCheck(payment_id) paymentActiveCheck(payment_id) returns (bool) {
        require(
            _payment_id_billing_id_to_payer_id[payment_id][billing_id] == 0,
            "This payment all ready approved"
        );
        require(
            _payments[payment_id].is_native_token && msg.value ==_payments[payment_id].price ||
            !_payments[payment_id].is_native_token &&
            IERC20(_payments[payment_id].ERC20_address).allowance(_msgSender(), address(this)) >=
            _payments[payment_id].price,
            "Not enough approved tokens"
        );

        uint256 payer_id = _payers.length;

        _payers.push(
            Payer(
                payment_id,
                _msgSender(),
                billing_id,
                block.timestamp,
                block.timestamp,
                _payments[payment_id].trial_time > 0 ? PaymentStatus.TRIAL : PaymentStatus.ACTIVE,
                payer_id
            )
        );

        _payment_id_billing_id_to_payer_id[payment_id][billing_id] = payer_id;

        emit PaymentApproved(
            payment_id,
            _msgSender(),
            billing_id,
            block.timestamp,
            block.timestamp,
            _payments[payment_id].trial_time > 0 ? PaymentStatus.TRIAL : PaymentStatus.ACTIVE
        );

        if (
            _payments[payment_id].payment_type == PaymentType.ONE_TIME_PAYMENT &&
            _payments[payment_id].is_native_token
        ) {
            uint256 pay;
            uint256 commission;
            (pay, commission) = _AmountWithCommission(_payments[payment_id].price);
            _service_provider_native_earnings[_payments[payment_id].service_provider_address] += pay;
            _commission_native_earnings += commission;

            return true;
        }

        if (
            !_payments[payment_id].is_native_token &&
            _payments[payment_id].trial_time == 0
        ) {
            return SendERC20Tokens(
                _payments[payment_id].ERC20_address,
                _msgSender(),
                address(this),
                _payments[payment_id].price,
                _payments[payment_id].service_provider_address
            );
        }

        if (
             _payments[payment_id].payment_type == PaymentType.SUBSCRIPTION &&
             _payments[payment_id].trial_time > 0
        ) {
            return true;
        }

        revert();
    }

    function ExecuteSubscription(
        uint256 payment_id,
        uint256 billing_id
    ) public paymentActiveCheck(payment_id) returns (bool) {
        uint256 payer_id = _GetPayerId(payment_id, billing_id);
        require(
            _payers[payer_id].payment_status == PaymentStatus.ACTIVE &&
            _payers[payer_id].last_payment_timestamp + _payments[payment_id].payment_period <=
            block.timestamp ||
            _payers[payer_id].payment_status == PaymentStatus.TRIAL &&
            _payers[payer_id].last_payment_timestamp + _payments[payment_id].trial_time <=
            block.timestamp ||
            _payers[payer_id].payment_status == PaymentStatus.DECLINE,
            "Payment time has not yet arrived"
        );

        bool complite = SendERC20Tokens(
            _payments[payment_id].ERC20_address,
            _payers[payer_id].billing_address,
            address(this),
            _payments[payment_id].price,
            _payments[payment_id].service_provider_address
        );

        if (complite) {
            _payers[payer_id].last_payment_timestamp = block.timestamp;
            _payers[payer_id].payment_status = PaymentStatus.ACTIVE;
        } else {
            _payers[payer_id].payment_status = PaymentStatus.DECLINE;
        }

        emit PaymentExecuted(
            payment_id,
            _payers[payer_id].billing_address,
            billing_id
        );

        return true;
    }

    function ExecuteSubscriptions(
        uint256[] memory payment_ids,
        uint256[] memory billing_ids
    ) public returns (bool) {
        require(
            payment_ids.length == billing_ids.length,
            "Arrays must have the same length"
        );
        require(
            payment_ids.length <= 20,
            "Length must be less than 20"
        );

        for (uint256 i = 0; i < payment_ids.length; i++) {
            ExecuteSubscription(payment_ids[i], billing_ids[i]);
        }

        return true;
    }

    function CancelSubscription(
        uint256 payment_id,
        uint256 billing_id
    ) public returns (bool) {
        uint256 payer_id = _GetPayerId(payment_id, billing_id);
        require(
            _payers[payer_id].billing_address == _msgSender(),
            "You are not this payer"
        );
        
        _payers[payer_id].payment_status = PaymentStatus.CANCELED;

        emit SubscriptionCanceled(
            payment_id,
            _payers[payer_id].billing_address,
            billing_id
        );

        return true;
    }

    function Withdraw(
        bool is_native_token,
        address ERC20_address
    ) public returns (bool) {
        require(
            is_native_token &&
            _service_provider_native_earnings[_msgSender()] > 0 ||
            !is_native_token &&
            _service_provider_ERC20_earnings[_msgSender()][ERC20_address] > 0,
            "No tokens"
        );

        if (is_native_token && _service_provider_native_earnings[_msgSender()] > 0) {
            uint256 balance = _service_provider_native_earnings[_msgSender()];
            payable(_msgSender()).transfer(balance);
            _service_provider_native_earnings[_msgSender()] = 0;
        }
        if (!is_native_token && _service_provider_ERC20_earnings[_msgSender()][ERC20_address] > 0) {
            IERC20(ERC20_address).transfer(
                _msgSender(),
                _service_provider_ERC20_earnings[_msgSender()][ERC20_address]
            );
            _service_provider_ERC20_earnings[_msgSender()][ERC20_address] = 0;
        }

        emit WithdrawSuccessful(_msgSender(), is_native_token, block.timestamp);

        return true;
    }

    function WithdrawCommission(
        address ERC20_address,
        bool is_native_token
    ) public onlyOwner returns (bool) {
        require(
            is_native_token && _commission_native_earnings > 0 ||
            !is_native_token && _commission_ERC20_earnings[ERC20_address] > 0,
            "No tokens"
        );

        if (is_native_token) {
            uint256 balance = _commission_native_earnings;
            payable(_msgSender()).transfer(balance);
            _commission_native_earnings = 0;
        } else {
            IERC20(ERC20_address).transfer(
                _msgSender(),
                _commission_ERC20_earnings[ERC20_address]
            );
            _commission_ERC20_earnings[ERC20_address] = 0;
        }

        emit WithdrawSuccessful(_msgSender(), is_native_token, block.timestamp);

        return true;
    }
}