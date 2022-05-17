// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ICharityFactory.sol";
import "./Organization.sol";

contract CharityFactory is Initializable, ContextUpgradeable, ICharityFactory, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20 public charityToken;

    address[] public allOrganizations;
    mapping(address => address) public getOrganization;
    mapping(address => uint256) public organizationEthBalance;
    mapping(address => uint256) public organizationTokenBalance;

    uint256 public totalEthDonations;
    uint256 public totalTokenDonations;

    modifier validateSymbol(string calldata _symbol) {
        require(
            keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(charityToken.symbol())),
            "CharityFactory: Only CharityToken is allowed for ERC20 transacitons"
        );
        _;
    }

    modifier validateEthAmount() {
        require(msg.value > 0, "CharityFactory: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateAmount(uint256 _amount) {
        require(_amount > 0, "CharityFactory: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateOrganization(address _organizationOwner) {
        require(getOrganization[_organizationOwner] != address(0), "CharityFactory: Organization not found.");
        _;
    }

    function initialize(IERC20 _charityToken) public initializer {
        __Ownable_init();
        charityToken = _charityToken;
    }

    function createOrganization(
        address payable _orgOwner,
        string calldata _orgName,
        string calldata _orgDesc
    ) external onlyOwner returns (address) {
        require(getOrganization[_orgOwner] == address(0), "CharityFactory: ORGANIZATION_EXISTS");

        Organization organization = new Organization(charityToken, _orgOwner, _orgName, _orgDesc);

        // bytes memory bytecode = type(Organization).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(charityToken, _orgOwner, _orgName, _orgDesc));

        // assembly {
        //     organization := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        //     if iszero(extcodesize(organization)) {
        //         revert(0, 0)
        //     }
        // }

        //IOrganization(organization).initialize(address(charityToken), _orgOwner, _orgName, _orgDesc);

        getOrganization[_orgOwner] = address(organization);
        organizationEthBalance[address(organization)] = 0;
        organizationTokenBalance[address(organization)] = 0;
        allOrganizations.push(address(organization));

        emit OrganizationCreated(_orgOwner, address(organization), allOrganizations.length);

        return address(organization);
    }

    function allOrganizationsLength() external view returns (uint256) {
        return allOrganizations.length;
    }

    receive() external payable validateEthAmount {
        totalEthDonations += msg.value;
        _updateEthBalances(msg.value);
        emit Donation(msg.sender, msg.value, "MATIC", address(this));
    }

    function donateTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transferFrom(msg.sender, address(this), _amount);
        totalTokenDonations += _amount;
        _updateTokenBalances(_amount);
        emit Donation(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function _updateEthBalances(uint256 _amount) internal {
        uint256 _organizationAmount = _amount.div(allOrganizations.length);
        for (uint256 i = 0; i < allOrganizations.length; i++) {
            organizationEthBalance[allOrganizations[i]] += _organizationAmount;
        }
    }

    function _updateTokenBalances(uint256 _amount) internal {
        uint256 _organizationAmount = _amount.div(allOrganizations.length);
        for (uint256 i = 0; i < allOrganizations.length; i++) {
            organizationTokenBalance[allOrganizations[i]] += _organizationAmount;
        }
    }

    function ethBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function tokenBalance(string calldata _symbol) external view onlyOwner validateSymbol(_symbol) returns (uint256) {
        return charityToken.balanceOf(address(this));
    }

    function withdrawEth(uint256 _amount) external payable validateOrganization(_msgSender()) validateAmount(_amount) {
        require(address(this).balance >= _amount);

        uint256 balance = organizationEthBalance[getOrganization[_msgSender()]];
        require(balance >= _amount);

        organizationEthBalance[getOrganization[_msgSender()]] -= _amount;
        payable(_msgSender()).transfer(_amount);
        emit Withdraw(_msgSender(), _amount, "MATIC", address(this));
    }

    function withdrawTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        validateOrganization(_msgSender())
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        require(charityToken.balanceOf(address(this)) >= _amount);

        uint256 balance = organizationTokenBalance[getOrganization[_msgSender()]];
        require(balance >= _amount);

        organizationTokenBalance[getOrganization[_msgSender()]] -= _amount;
        charityToken.transfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount, charityToken.symbol(), address(this));
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

import "./IERC20.sol";

interface IOrganization {
    event Donation(address indexed _from, uint256 _value, string _currency, address indexed _to);
    event Withdraw(address indexed _to, uint256 _value, string _currency, address indexed _from);

    function charityToken() external view returns (IERC20);

    function factory() external view returns (address);

    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function totalEthDonations() external view returns (uint256);

    function totalTokenDonations() external view returns (uint256);

    // function initialize(
    //     address payable owner,
    //     string calldata name,
    //     string calldata desc
    // ) external;

    //function destroy() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function rate() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

import "./IERC20.sol";

interface ICharityFactory {
    event OrganizationCreated(address indexed organizationOwner, address organization, uint256 count);
    event Donation(address indexed _from, uint256 _value, string _currency, address indexed _to);
    event Withdraw(address indexed _to, uint256 _value, string _currency, address indexed _from);

    function charityToken() external view returns (IERC20);

    function getOrganization(address) external view returns (address);

    function organizationEthBalance(address) external view returns (uint256);

    function organizationTokenBalance(address) external view returns (uint256);

    function allOrganizations(uint256) external view returns (address);

    function allOrganizationsLength() external view returns (uint256);

    function totalEthDonations() external view returns (uint256);

    function totalTokenDonations() external view returns (uint256);

    function createOrganization(
        address payable owner,
        string calldata name,
        string calldata desc
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOrganization.sol";

contract Organization is Initializable, ContextUpgradeable, IOrganization, OwnableUpgradeable {
    IERC20 public charityToken;

    address public factory;

    string public name;
    string public description;

    uint256 public totalEthDonations;
    uint256 public totalTokenDonations;

    modifier validateSymbol(string calldata _symbol) {
        require(
            keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(charityToken.symbol())),
            "Organization: Only CharityToken is allowed for ERC20 transacitons"
        );
        _;
    }

    modifier validateEthAmount() {
        require(msg.value > 0, "Organization: Transfer amount has to be greater than 0.");
        _;
    }

    modifier validateAmount(uint256 _amount) {
        require(_amount > 0, "Organization: Transfer amount has to be greater than 0.");
        _;
    }

    constructor(
        IERC20 _charityToken,
        address payable _owner,
        string memory _name,
        string memory _desc
    ) initializer {
        __Ownable_init();
        transferOwnership(_owner);

        factory = _msgSender();
        charityToken = _charityToken;

        name = _name;
        description = _desc;
        totalEthDonations = 0;
        totalTokenDonations = 0;
    }

    // called once by the factory at time of deployment
    // function initialize(
    //     address payable _owner,
    //     string calldata _name,
    //     string calldata _desc
    // ) external {
    //     require(_msgSender() == factory, "Organization: FORBIDDEN");

    //     totalEthDonations = 0;
    //     totalTokenDonations = 0;
    //     owner = _owner;
    //     name = _name;
    //     description = _desc;
    // }

    receive() external payable validateEthAmount {
        totalEthDonations += msg.value;
        emit Donation(msg.sender, msg.value, "ETH", address(this));
    }

    function donateTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transferFrom(msg.sender, address(this), _amount);

        totalTokenDonations += _amount;
        emit Donation(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function withdrawEth(uint256 _amount) external payable onlyOwner validateAmount(_amount) {
        payable(owner()).transfer(_amount);
        emit Withdraw(msg.sender, _amount, "ETH", address(this));
    }

    function withdrawTokens(string calldata _symbol, uint256 _amount)
        external
        payable
        onlyOwner
        validateSymbol(_symbol)
        validateAmount(_amount)
    {
        charityToken.transfer(owner(), _amount);
        emit Withdraw(msg.sender, _amount, charityToken.symbol(), address(this));
    }

    function ethBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function tokensBalance(string calldata _symbol) external view onlyOwner validateSymbol(_symbol) returns (uint256) {
        return charityToken.balanceOf(address(this));
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}