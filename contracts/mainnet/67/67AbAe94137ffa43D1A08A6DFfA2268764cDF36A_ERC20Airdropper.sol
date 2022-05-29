/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;




/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/AccessWhitelist.sol

pragma solidity ^0.5.12;


contract AccessWhitelist is WhitelistedRole {
    constructor() public {
        super.addWhitelisted(msg.sender);
    }
}

// File: contracts/AccessControls.sol

pragma solidity ^0.5.12;


contract AccessControls {
    AccessWhitelist public accessWhitelist;

    constructor(AccessWhitelist _accessWhitelist) internal {
        accessWhitelist = _accessWhitelist;
    }

    modifier onlyWhitelisted() {
        require(accessWhitelist.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    modifier onlyWhitelistAdmin() {
        require(accessWhitelist.isWhitelistAdmin(msg.sender), "Caller not whitelist admin");
        _;
    }

    function updateAccessWhitelist(AccessWhitelist _accessWhitelist) external onlyWhitelistAdmin {
        accessWhitelist = _accessWhitelist;
    }
}

// File: contracts/CommissionSplitter.sol

pragma solidity ^0.5.12;



contract CommissionSplitter is AccessControls {
    using SafeMath for uint256;

    address public platform;
    uint256 public platformSplit;

    address public partner;
    uint256 public partnerSplit;

    constructor(AccessWhitelist _accessWhitelist, address _platform, uint256 _platformSplit, address _partner, uint256 _partnerSplit)
        AccessControls(_accessWhitelist) public {
        require(_platformSplit.add(_partnerSplit) == 100, "Split percentages are not setup correctly");
        platform = _platform;
        platformSplit = _platformSplit;
        partner = _partner;
        partnerSplit = _partnerSplit;
    }

    function () external payable {
        uint256 singleUnitOfValue = msg.value.div(100);

        uint256 amountToSendPlatform = singleUnitOfValue.mul(platformSplit);
        (bool platformSuccess,) = platform.call.value(amountToSendPlatform)("");
        require(platformSuccess, "Failed to send split to platform");

        uint256 amountToSendPartner = singleUnitOfValue.mul(partnerSplit);
        (bool partnerSuccess,) = partner.call.value(amountToSendPartner)("");
        require(partnerSuccess, "Failed to send split to partner");
    }

    function updatePlatform(address _platform) external onlyWhitelisted {
        platform = _platform;
    }

    function updatePartner(address _partner) external onlyWhitelisted {
        partner = _partner;
    }

    function updateSplit(uint256 _platformSplit, uint256 _partnerSplit) external onlyWhitelisted {
        require(_platformSplit.add(_partnerSplit) == 100, "Split percentages are not setup correctly");
        platformSplit = _platformSplit;
        partnerSplit = _partnerSplit;
    }
}

// File: contracts/ERC20Airdropper.sol

pragma solidity ^0.5.5;





contract ERC20Airdropper is AccessControls {
    using SafeMath for uint256;

    event Transfer(
        address indexed _token,
        address indexed _caller,
        uint256 _recipientCount,
        uint256 _totalTokensSent
    );

    event PricePerTxChanged(
        address indexed _caller,
        uint256 _oldPrice,
        uint256 _newPrice
    );

    event EtherMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event TokensMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event CreditsAdded(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event CreditsRemoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    mapping(address => uint256) public credits;

    uint256 public pricePerTx = 0.01 ether;

    CommissionSplitter public splitter;

    constructor(AccessWhitelist _accessWhitelist, CommissionSplitter _splitter)
        AccessControls(_accessWhitelist) public {
        splitter = _splitter;
    }

    // @notice will receive any eth sent to the contract
    function () external payable {}

    function transfer(address _token, address[] calldata _addresses, uint256[] calldata _values) payable external returns (bool) {
        require(_addresses.length == _values.length, "Address array and values array must be same length");

        require(credits[msg.sender] > 0 || msg.value >= pricePerTx, "Must have credit or min value");

        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");

            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
            totalTokensSent = totalTokensSent.add(_values[i]);
        }

        if (msg.value == 0 && credits[msg.sender] > 0) {
            credits[msg.sender] = credits[msg.sender].sub(1);
        } else {
            (bool splitterSuccess,) = address(splitter).call.value(msg.value)("");
            require(splitterSuccess, "Failed to transfer to the commission splitter");
        }

        emit Transfer(_token, msg.sender, _addresses.length, totalTokensSent);

        return true;
    }

    function moveEther(address payable _account) onlyWhitelistAdmin external returns (bool)  {
        uint256 contractBalance = address(this).balance;
        _account.transfer(contractBalance);
        emit EtherMoved(msg.sender, _account, contractBalance);
        return true;
    }

    function moveTokens(address _token, address _account) external onlyWhitelistAdmin returns (bool) {
        uint256 contractTokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_account, contractTokenBalance);
        emit TokensMoved(msg.sender, _account, contractTokenBalance);
        return true;
    }

    function addCredit(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        credits[_to] = credits[_to].add(_amount);
        emit CreditsAdded(msg.sender, _to, _amount);
        return true;
    }

    function reduceCredit(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        credits[_to] = credits[_to].sub(_amount);
        emit CreditsRemoved(msg.sender, _to, _amount);
        return true;
    }

    function setPricePerTx(uint256 _pricePerTx) external onlyWhitelisted returns (bool) {
        uint256 oldPrice = pricePerTx;
        pricePerTx = _pricePerTx;
        emit PricePerTxChanged(msg.sender, oldPrice, pricePerTx);
        return true;
    }

    function creditsOfOwner(address _owner) external view returns (uint256) {
        return credits[_owner];
    }

    function updateCommissionSplitter(CommissionSplitter _splitter) external onlyWhitelistAdmin {
        splitter = _splitter;
    }
}