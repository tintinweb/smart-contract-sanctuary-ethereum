/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT
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

contract Organization is Ownable {
    using SafeMath for uint256;

    // Values
    uint256 public MIN_MONTHLY_TRANSACTION = 591666666666666 wei;
    uint256 public MAX_DAYS = 365;
    uint256 private COMMISSION_RATE = 1000; // 0.1% commission rate
    uint256 private MIN_PRICE_PER_DAY = MIN_MONTHLY_TRANSACTION.div(30);

    // Orgnization events
    event OrganizationAdded(string name, string key, string supportUrl, address manager, uint256 pricePerDay);
    event OrganizationEdited(string name, string key, string supportUrl, address manager, uint256 pricePerDay);
    event OrganizationDeleted(string key);
    event OrganizationSaved(string name, string key, string supportUrl, address manager, uint256 pricePerDay);

    // Member account events
    event MemberAccountAdded(
        address indexed userAddress,
        string userName,
        string imgUrl,
        string description,
        uint256 expirationDate
    );
    event MemberAccountEdited(address indexed userAddress, string userName, string imgUrl, string description);
    event MemberAccountDeleted(address indexed userAddress);
    event MemberAccountSaved(
        address indexed userAddress,
        string userName,
        string imgUrl,
        string description,
        uint256 expirationDate,
        string organizationKey
    );

    // Transaction events
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Structs
    struct MemberAccount {
        address userAddress;
        string userName;
        string imgUrl;
        string description;
        uint256 expirationDate;
    }
    struct OrganizationData {
        string name;
        string key;
        string supportUrl;
        address manager;
        mapping(address => MemberAccount) accounts;
        uint256 pricePerDay;
    }

    mapping(string => OrganizationData) public organizations;

    // Modifiers
    modifier organizationNotNull(string memory _key) {
        require(organizations[_key].manager != address(0), "Organization key does not exist.");
        _;
    }

    modifier organizationManager(string memory _key) {
        require(
            organizations[_key].manager == _msgSender(),
            "Only the manager has permission to edit an organization."
        );
        _;
    }

    modifier accountOwner(string memory _key) {
        require(organizations[_key].accounts[_msgSender()].userAddress == _msgSender(), "Not authorized");
        _;
    }

    modifier validateOrganizationParams(
        string memory _name,
        string memory _key,
        string memory _supportUrl
    ) {
        require(bytes(_name).length > 0, "Name is required.");
        require(bytes(_key).length > 0, "Key is required.");
        require(bytes(_supportUrl).length > 0, "Support URL is required.");
        _;
    }

    modifier memberAccountAlreadyExists(string memory _key) {
        require(
            organizations[_key].accounts[_msgSender()].userAddress != _msgSender(),
            "Member account already exists."
        );
        _;
    }

    modifier minTransaction(uint256 _amount) {
        require(_amount >= MIN_MONTHLY_TRANSACTION, "Minimum transaction not met");
        _;
    }

    modifier minPricePerDay(uint256 _pricePerDay) {
        require(_pricePerDay >= MIN_PRICE_PER_DAY, "Minimum required price per month not met");
        _;
    }

    modifier transactionRangeForAccount(string memory _key) {
        require(msg.value >= MIN_PRICE_PER_DAY, "Minimum transaction not met");
        require(msg.value >= organizations[_key].pricePerDay, "Not enough ETH sent for a day.");
        require(
            msg.value <= organizations[_key].pricePerDay.mul(MAX_DAYS),
            "Maximum days exceeded. You can't subscribe for more than a year."
        );
        _;
    }

    // View Functions
    function getOrganizationByManagerAndKey(
        address _manager,
        string memory _key
    ) public view organizationNotNull(_key) returns (string memory, string memory, string memory, address, uint256) {
        require(organizations[_key].manager == _manager, "Organization not found.");
        return (
            organizations[_key].name,
            organizations[_key].key,
            organizations[_key].supportUrl,
            organizations[_key].manager,
            organizations[_key].pricePerDay
        );
    }

    function getAccountByOrganizationAndUserAddress(
        string memory _organizationKey,
        address _userAddress
    )
        public
        view
        organizationNotNull(_organizationKey)
        returns (address, string memory, string memory, string memory, uint256)
    {
        require(
            organizations[_organizationKey].accounts[_userAddress].userAddress == _userAddress,
            "Member account not found."
        );
        return (
            organizations[_organizationKey].accounts[_userAddress].userAddress,
            organizations[_organizationKey].accounts[_userAddress].userName,
            organizations[_organizationKey].accounts[_userAddress].imgUrl,
            organizations[_organizationKey].accounts[_userAddress].description,
            organizations[_organizationKey].accounts[_userAddress].expirationDate
        );
    }

    // Edit Functions
    function addOrganization(
        string memory _name,
        string memory _key,
        string memory _supportUrl,
        uint256 _pricePerDay
    ) public validateOrganizationParams(_name, _key, _supportUrl) minPricePerDay(_pricePerDay) {
        require(organizations[_key].manager == address(0), "Organization key already exists.");
        emit OrganizationAdded(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        emit OrganizationSaved(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        organizations[_key].name = _name;
        organizations[_key].key = _key;
        organizations[_key].supportUrl = _supportUrl;
        organizations[_key].manager = _msgSender();
        organizations[_key].pricePerDay = _pricePerDay;
    }

    function editOrganization(
        string memory _key,
        string memory _name,
        string memory _supportUrl,
        uint256 _pricePerDay
    ) public organizationNotNull(_key) organizationManager(_key) minPricePerDay(_pricePerDay) {
        emit OrganizationEdited(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        emit OrganizationSaved(_name, _key, _supportUrl, _msgSender(), _pricePerDay);
        organizations[_key].name = _name;
        organizations[_key].supportUrl = _supportUrl;
        organizations[_key].manager = _msgSender();
        organizations[_key].pricePerDay = _pricePerDay;
    }

    function deleteOrganization(string memory _key) public organizationNotNull(_key) organizationManager(_key) {
        emit OrganizationSaved(
            organizations[_key].name,
            organizations[_key].key,
            organizations[_key].supportUrl,
            _msgSender(),
            0
        );
        emit OrganizationDeleted(_key);
        delete organizations[_key];
    }

    function addAccount(
        string memory _organizationKey,
        string memory _userName,
        string memory _imgUrl,
        string memory _description
    )
        public
        payable
        organizationNotNull(_organizationKey)
        memberAccountAlreadyExists(_organizationKey)
        transactionRangeForAccount(_organizationKey)
    {
        uint256 pricePerDay = organizations[_organizationKey].pricePerDay;
        uint256 availableDays = msg.value.div(pricePerDay);
        uint256 expirationDate = block.timestamp.add(availableDays.mul(1 days));
        emit MemberAccountAdded(_msgSender(), _userName, _imgUrl, _description, expirationDate);
        emit MemberAccountSaved(_msgSender(), _userName, _imgUrl, _description, expirationDate, _organizationKey);
        emit Transfer(_msgSender(), owner(), msg.value.div(1000));
        emit Transfer(_msgSender(), organizations[_organizationKey].manager, msg.value.sub(msg.value.div(1000)));
        organizations[_organizationKey].accounts[_msgSender()].userAddress = _msgSender();
        organizations[_organizationKey].accounts[_msgSender()].userName = _userName;
        organizations[_organizationKey].accounts[_msgSender()].imgUrl = _imgUrl;
        organizations[_organizationKey].accounts[_msgSender()].description = _description;
        organizations[_organizationKey].accounts[_msgSender()].expirationDate = expirationDate;
        payable(owner()).transfer(msg.value.div(1000));
        payable(organizations[_organizationKey].manager).transfer(msg.value.sub(msg.value.div(1000)));
    }

    function addAmountToAccount(
        string memory _organizationKey
    )
        public
        payable
        organizationNotNull(_organizationKey)
        accountOwner(_organizationKey)
        transactionRangeForAccount(_organizationKey)
    {
        uint256 pricePerDay = organizations[_organizationKey].pricePerDay;
        uint256 availableDays = msg.value.div(pricePerDay);
        uint256 expirationDate = organizations[_organizationKey].accounts[_msgSender()].expirationDate.add(
            availableDays.mul(1 days)
        );
        require(
            expirationDate <= block.timestamp.add(MAX_DAYS.mul(1 days)),
            "Maximum days exceeded. You can't subscribe for more than a year."
        );
        organizations[_organizationKey].accounts[_msgSender()].expirationDate = expirationDate;
        emit Transfer(_msgSender(), owner(), msg.value.div(1000));
        emit Transfer(_msgSender(), organizations[_organizationKey].manager, msg.value.sub(msg.value.div(1000)));
        emit MemberAccountSaved(
            _msgSender(),
            organizations[_organizationKey].accounts[_msgSender()].userName,
            organizations[_organizationKey].accounts[_msgSender()].imgUrl,
            organizations[_organizationKey].accounts[_msgSender()].description,
            expirationDate,
            _organizationKey
        );
        payable(owner()).transfer(msg.value.div(1000));
        payable(organizations[_organizationKey].manager).transfer(msg.value.sub(msg.value.div(1000)));
    }

    function editAccount(
        string memory _organizationKey,
        string memory _userName,
        string memory _imgUrl,
        string memory _description
    ) public organizationNotNull(_organizationKey) accountOwner(_organizationKey) {
        emit MemberAccountEdited(_msgSender(), _userName, _imgUrl, _description);
        emit MemberAccountSaved(
            _msgSender(),
            _userName,
            _imgUrl,
            _description,
            organizations[_organizationKey].accounts[_msgSender()].expirationDate,
            _organizationKey
        );
        organizations[_organizationKey].accounts[_msgSender()].userName = _userName;
        organizations[_organizationKey].accounts[_msgSender()].imgUrl = _imgUrl;
        organizations[_organizationKey].accounts[_msgSender()].description = _description;
    }

    function deleteMyAccount(
        string memory _organizationKey
    ) public organizationNotNull(_organizationKey) accountOwner(_organizationKey) {
        emit MemberAccountDeleted(_msgSender());
        emit MemberAccountSaved(
            _msgSender(),
            organizations[_organizationKey].accounts[_msgSender()].userName,
            organizations[_organizationKey].accounts[_msgSender()].imgUrl,
            organizations[_organizationKey].accounts[_msgSender()].description,
            block.timestamp,
            _organizationKey
        );
        delete organizations[_organizationKey].accounts[_msgSender()];
    }

    function editMinTransaction(uint256 _minTransactionValue) public onlyOwner {
        MIN_MONTHLY_TRANSACTION = _minTransactionValue;
    }

    function editMaxDays(uint256 _maxDaysValue) public onlyOwner {
        MAX_DAYS = _maxDaysValue;
    }

    // Backup Functions
    function exportExceed() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}