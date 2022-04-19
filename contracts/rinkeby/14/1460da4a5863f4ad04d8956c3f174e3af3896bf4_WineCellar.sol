/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity ^0.8.11;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
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

// 
interface IWineCellar {

    function owner() external view returns (address);

    function getCurrency() external view returns (string memory);

    function getNumberOfBottles(uint256 tokenId_, address owner_) external view returns (uint256);

    function depositBottles(address owner_, uint256 tokenId_, uint256 amount_) external;

    function transferBottles(address from_, address to_, uint256 tokenId_, uint256 amount_) external;

    function removeBottles(address owner_, uint256 tokenId_, uint256 amount_) external;
}

// 
interface IWineEnums {

//    enum BottleSize {NotSelected, Piccolo, Demi, Standard, Magnum, DoubleMagnum, Jeroboam, Rehoboam, Imperial, Salmanazar, Balthazar, Nebuchadnezzar, Solomon}
//    enum WineType {NotSelected, Red, White, Rose, Sparkling, Dessert, Fortified}

//    struct Wine {
//        uint256 tokenId;
//        address brand;
//        string title;
//        WineType wineType;
//        BottleSize bottleSize;
//        string classification;
//        string vintage;
//        string country;
//        string region;
//        string composition;
//        string volume;
//        //https://www.winespectator.com/articles/what-do-ph-and-ta-numbers-mean-to-a-wine-5035
//        uint256 totalAcidity18;
//        uint256 ph18;
//        uint256 alcohol18;
//        uint256 timeInBarrelSec;
//        string condition;
//        string label;
//        string imageUrl;
//        uint256 datePublished;
//    }

//    struct Location {
//        string addressLine1;
//        string addressLine2;
//        string city;
//        string province;
//        string countryCode;
//        string postalCode;
//        uint256 lng;
//        uint256 lat;
//    }

    //enum Currency {EUR, USD, ETH, MATIC}
}

// 
interface IWineOracle {

    function getLatestPrice() external view returns (int, uint8);
}

// 
contract WineCellar is IWineCellar, IWineEnums, Ownable {

    using Address for address;
    using SafeMath for uint256;

    using Counters for Counters.Counter;

    Counters.Counter private _storagePlanIdTracker;
    Counters.Counter private _leaseAgreementIdTracker;

    enum LeaseStatus{NotAssigned, Open, Closed, Paid}

    struct StoragePlan {
        string displayName;
        uint256 rent30days18;
        uint256 vat30days18;
        uint256 activeSince; // seconds since unix epoch
        bool valid;
    }

    struct LeaseAgreement {
        uint256 leaseId;
        uint256 dealId;
        uint256 wineTokenId;
        uint256 amount;
        uint256 storagePlanId;
        uint256 started; // seconds since unix epoch
        uint256 paidTill;   // last time paid in seconds since unix epoch
        uint256 ended;
        LeaseStatus status;
    }

    string private _displayName;

    string private _currency;

    string private _location;

    address private _brand;

    address private _marketplace;

    uint256 private _latestEURtoUSDRate18 = 1e18;

    uint256 private _latestETHtoUSDRate18 = 1e18;

    // Storage Plan ID => Storage Plan
    mapping(uint256 => StoragePlan) private _storagePlans;

    // todo bind token ID to storage plan

    // Tenant => Balance in ETH
    mapping(address => uint256) private _balance;

    // Tenant => Balance in current cellar currency
    mapping(address => uint256) private _fiatBalance;

    // Tenant => Lease Agreements
    mapping(address => LeaseAgreement[]) private _leaseAgreements;

    mapping(uint256 => mapping(address => uint256)) private _wineOwnedNumber;

    event PLAN(StoragePlan plan_);
    event WARNING(string message_, uint256 val1_, uint256 val2_);
    event AGREEMENTS(LeaseAgreement[] leaseAgreements_);

    address _ethOracle = address(0);
    address _eurOracle = address(0);

    constructor(address marketplace_, address brand_,  string memory currency_, address ethOracle_, address eurOracle_){
        require(strcmp(currency_, "USD") || strcmp(currency_, "EUR"), "WineCellar: only USD and EUR are supported");

        _marketplace = marketplace_;
        _brand = brand_;

        _currency = currency_;

        _ethOracle = ethOracle_;
        _eurOracle = eurOracle_;

        // start with 1
        _storagePlanIdTracker.increment();
        _leaseAgreementIdTracker.increment();
    }

    modifier onlyBrandOrMarketplace() {
        require(_brand == _msgSender() || _marketplace == _msgSender(), "WineToken: only brand or marketplace can call this function");
        _;
    }

    modifier onlyMarketplace() {
        require(_marketplace == _msgSender(), "WineToken: only marketplace call this function");
        _;
    }

    /**
 * @dev Returns the address of the current owner.
     */
    function owner() public view override (IWineCellar, Ownable) returns (address) {
        return super.owner();
    }

    function getDisplayName() external view returns (string memory) {
        return _displayName;
    }

    function setDisplayName(string memory displayName_) external onlyOwner {
        _displayName = displayName_;
    }

    function getCurrency() external view returns (string memory) {
        return _currency;
    }

    function getLocation() external view returns (string memory) {
        return _location;
    }

    function setLocation(string memory location_) external onlyOwner {
        _location = location_;
    }

    function addStoragePlan(StoragePlan memory plan_) external onlyOwner {
        plan_.activeSince = block.timestamp;

        _storagePlans[_storagePlanIdTracker.current()] = plan_;
        _storagePlanIdTracker.increment();
    }

    function deleteStoragePlan(uint256 planId_) external onlyOwner {
        delete _storagePlans[planId_];
    }

    function setStoragePlanIsValid(uint256 planId_, bool valid_) external onlyOwner {
        _storagePlans[planId_].valid = valid_;
    }

    function getStoragePlan(uint256 planId_) external {
        emit PLAN(_storagePlans[planId_]);
    }

    function getNumberOfBottles(uint256 tokenId_, address owner_) external view returns (uint256) {
        return _wineOwnedNumber[tokenId_][owner_];
    }

    function updateRates() internal {
        // ETH/USD oracle
        (int price, uint8 decimals) = IWineOracle(_ethOracle).getLatestPrice();
        _latestETHtoUSDRate18 = uint256(price).mul(1e18).div(10 ** decimals);

        // EUR/USD oracle
        (price, decimals) = IWineOracle(_eurOracle).getLatestPrice();
        _latestEURtoUSDRate18 = uint256(price).mul(1e18).div(10 ** decimals);
    }


    function registerLeaseAgreement(uint256 dealId_, address tenant_, uint256 planId_, uint256 wineTokenId_, uint256 amount_) external {
        LeaseAgreement memory leaseAgreement = LeaseAgreement({
        leaseId : _leaseAgreementIdTracker.current(),
        dealId : dealId_,
        storagePlanId : planId_,
        started : block.timestamp,
        paidTill : block.timestamp,
        ended : 0,
        wineTokenId : wineTokenId_,
        amount : amount_,
        status : LeaseStatus.Open
        });

        _leaseAgreementIdTracker.increment();

        _leaseAgreements[tenant_].push(leaseAgreement);
    }

    function calculateLeasePayment(address tenant_, uint256 date_) public view returns (uint256, string memory) {
        LeaseAgreement[] memory leaseAgreements = _leaseAgreements[tenant_];

        uint256 totalRent18 = 0;

        for (uint i = 0; i < leaseAgreements.length; i++) {
            LeaseAgreement memory leaseAgreement = leaseAgreements[i];

            if (leaseAgreement.status == LeaseStatus.Paid) {
                continue;
            }

            uint256 duration = 0;

            if (leaseAgreement.status == LeaseStatus.Open) {
                if (date_ > leaseAgreement.paidTill) {
                    duration = date_ - leaseAgreement.paidTill;
                }
            }

            if (leaseAgreement.status == LeaseStatus.Closed && leaseAgreement.paidTill < min(leaseAgreement.ended, date_)) {
                duration = min(leaseAgreement.ended, date_) - leaseAgreement.paidTill;
            }

            uint256 rentPerSecond18 = _storagePlans[leaseAgreement.storagePlanId].rent30days18.div(2592000);
            uint256 rent18 = rentPerSecond18.mul(duration).mul(leaseAgreement.amount);

            totalRent18 = totalRent18.add(rent18);
        }

        return (totalRent18, _currency);
    }

    function updateLeaseAgreementsDates(address tenant_, uint256 date_) internal {
        LeaseAgreement[] storage leaseAgreements = _leaseAgreements[tenant_];

        for (uint i = 0; i < leaseAgreements.length; i++) {
            LeaseAgreement storage leaseAgreement = leaseAgreements[i];

            if (leaseAgreement.status == LeaseStatus.Paid) {
                continue;
            }

            if (leaseAgreement.status == LeaseStatus.Open) {
                leaseAgreement.paidTill = date_;
            }

            if (leaseAgreement.status == LeaseStatus.Closed) {
                if(date_ < leaseAgreement.ended){
                    leaseAgreement.paidTill = date_;
                }else{
                    leaseAgreement.paidTill = leaseAgreement.ended;
                    leaseAgreement.status = LeaseStatus.Paid;
                }
            }
        }
    }

    function getLeaseAgreements(address tenant_) public {
        emit AGREEMENTS(_leaseAgreements[tenant_]);
    }

    function getLeaseAgreement(address tenant_, uint256 leaseId_) internal view returns (uint256, LeaseAgreement storage) {
        LeaseAgreement[] storage leaseAgreements = _leaseAgreements[tenant_];

        uint256 idx = 0;

        for (idx = 0; idx < leaseAgreements.length; idx++) {
            if (leaseAgreements[idx].leaseId == leaseId_) {
                return (idx, leaseAgreements[idx]);
            }
        }

        revert("WineCellar: agreement is not found");
    }

    function deleteLeaseAgreement(address tenant_, uint256 leaseId_) external onlyOwner {
        (uint256 idx,) = getLeaseAgreement(tenant_, leaseId_);
        delete _leaseAgreements[tenant_][idx];
    }

    function setLeaseAgreementStatus(address tenant_, uint256 leaseId_, LeaseStatus status_) external onlyOwner {
        (, LeaseAgreement storage leaseAgreement) = getLeaseAgreement(tenant_, leaseId_);
        leaseAgreement.status = status_;
    }

    function payment(uint256 date_) external payable {
        (uint256 rentUSD18, string memory currency) = calculateLeasePayment(_msgSender(), date_);

        if (strcmp(currency, "EUR") == true) {
            rentUSD18 = rentUSD18.mul(1e18).div(_latestEURtoUSDRate18);
        }

        uint256 rentETH18 = rentUSD18.mul(1e18).div(_latestETHtoUSDRate18);
        require(rentETH18 < _balance[_msgSender()] + msg.value, "WineCellar: insufficient amount");

        _balance[_msgSender()] = _balance[_msgSender()] + msg.value - rentETH18;
        updateLeaseAgreementsDates(_msgSender(), date_);
    }

    function strcmp(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function depositBottles(address owner_, uint256 tokenId_, uint256 amount_) external onlyBrandOrMarketplace{
        _wineOwnedNumber[tokenId_][owner_] = amount_;

        // todo report to marketplace when this happens
    }

    function transferBottles(address from_, address to_, uint256 tokenId_, uint256 amount_) external onlyBrandOrMarketplace{
        require(_wineOwnedNumber[tokenId_][from_] > amount_, "WineCellar: not enough bottles");

        // todo report to marketplace when this happens

        // todo leasing agreements

        _wineOwnedNumber[tokenId_][from_] = _wineOwnedNumber[tokenId_][from_] - amount_;
        _wineOwnedNumber[tokenId_][to_] = _wineOwnedNumber[tokenId_][to_] + amount_;
    }

    function removeBottles(address owner_, uint256 tokenId_, uint256 amount_) external onlyBrandOrMarketplace{
        require(_wineOwnedNumber[tokenId_][owner_] > amount_, "WineCellar: not enough bottles");

        // todo report to marketplace when this happens

        // todo leasing agreements

        _wineOwnedNumber[tokenId_][owner_] = _wineOwnedNumber[tokenId_][owner_] - amount_;
    }


    function withdrawAmount(uint256 amount) external onlyOwner {
        require(amount <= getBalance());
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}