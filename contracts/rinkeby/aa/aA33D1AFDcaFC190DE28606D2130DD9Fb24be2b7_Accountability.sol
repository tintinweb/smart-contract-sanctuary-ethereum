// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '../structures/MetaDataStructure.sol';
import '../../shared/Signatures.sol';
import '../../interfaces/IAccessibilitySettings.sol';
import '../../interfaces/IERC20_PDN.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';


contract Accountability is Signatures, MetaDataStructure, Initializable {
 
    using SafeMathUpgradeable for uint256;

    uint public securityDelay;
    uint public MIN_MINT_AMOUNT;
    uint public MAX_PERC_TO_MINT;
    uint public MAX_PERC_TO_BURN; 
    
    address public accessibilitySettingsAddress;
    
    mapping(address => mapping(address => uint)) public accountability; // TOKEN -> ADDRESS -> BALANCE
    mapping(address => address) public tokenReferreal; //TOKEN => ADDRESS (user reference that is "owner" of the token)
    mapping(address => tokenManagementMetaData) public tokenManagement;

    event ChangeAccessibilitySettingsAddressEvent(address owner, address accessibilitySettingsAddress);
    event ChangeBalanceEvent(address indexed caller, address indexed token, address indexed user, uint oldBalance, uint newBalance);
    event ApproveDistributionEvent(address indexed referee, address indexed token, uint amount);
    event RedeemEvent(address indexed caller, address indexed token, uint redeemAmount);
    event RegisterERC20UpgradeableEvent(address tokenUpgradeableAddress, address referee);
    event SecurityTokenMovements(address indexed caller, address token, uint opID, uint amount);

    struct tokenManagementMetaData {
        uint lastBlockChange;
        mapping(address => uint) lastBlockUserOp;
        uint decimals;
    }

    enum opID {
        NONE,
        CREATE,
        BURN,
        MINT,
        APPROVE,
        REDEEM
    }

    modifier onlyDAOCreator(){
        require(IAccessibilitySettings(accessibilitySettingsAddress).getDAOCreator() == msg.sender, "LIMITED_FUNCTION_FOR_DAO_CREATOR");
        _;
    }

    modifier checkAccessibility(bytes4 _signature, bool _expectedValue){
        require(IAccessibilitySettings(accessibilitySettingsAddress).getAccessibility(_signature, msg.sender) == _expectedValue, "ACCESS_DENIED");
        _;
    }

    modifier temporaryLockSecurity(address _token){
        require(block.number.sub(securityDelay.add(tokenManagement[_token].lastBlockChange)) >= 0, "SECURITY_LOCK");
        _;
    }

    modifier securityFreeze(){
        require(IAccessibilitySettings(accessibilitySettingsAddress).getIsFrozen() == false, "FROZEN");
        _;
    }

    function initialize(address _accessibilitySettingsAddress, uint _securityDelay) public initializer {
        require(_accessibilitySettingsAddress != address(0), "NO_NULL_ADD");
        accessibilitySettingsAddress = _accessibilitySettingsAddress;
        IAccessibilitySettings IAS = IAccessibilitySettings(accessibilitySettingsAddress);

        address[] memory adminAddresses = new address[](uint(2));         
        uint[] memory adminAddressesRefGroup = new uint[](uint(2));    

        adminAddresses[0] = IAS.getDAOCreator();
        adminAddresses[1] = address(this);

        adminAddressesRefGroup[0] = uint(UserGroup.ADMIN);
        adminAddressesRefGroup[1] = uint(UserGroup.ADMIN);

        IAS.setUserListRole(adminAddresses, adminAddressesRefGroup);     // Who create the contract is admin

        // ------------------------------------------------------------ List of function signatures

        bytes4[] memory signatures = new bytes4[](uint(8));         // Number of signatures
        uint[] memory userGroupAdminArray = new uint[](uint(1));    // Number of Group Admin
        uint index = 0;
        signatures[index++] = FUNCTION_ADDBALANCE_SIGNATURE;
        signatures[index++] = FUNCTION_SUBBALANCE_SIGNATURE;
        signatures[index++] = FUNCTION_SETUSERROLE_SIGNATURE;
        signatures[index++] = FUNCTION_CREATEERC20_SIGNATURE;
        signatures[index++] = FUNCTION_APPROVEERC20DISTR_SIGNATURE;
        signatures[index++] = FUNCTION_BURNERC20_SIGNATURE;
        signatures[index++] = FUNCTION_MINTERC20_SIGNATURE;

        userGroupAdminArray[0] = uint(UserGroup.ADMIN);

        IAS.enableSignature(signatures, userGroupAdminArray);   

        // ------------------------------------------------------------ Setting default constant

        // PARAMETRIZZARE
        securityDelay = _securityDelay;
        MIN_MINT_AMOUNT = uint(1000);
        MAX_PERC_TO_MINT = uint(5);  
        MAX_PERC_TO_BURN = uint(5);
    }

    function enableListOfSignaturesForGroupUser(bytes4[] memory _signatures, uint[] memory _userGroup) public onlyDAOCreator securityFreeze returns(bool){
        IAccessibilitySettings(accessibilitySettingsAddress).enableSignature(_signatures, _userGroup);
        return true;
    }

    function disableListOfSignaturesForGroupUser(bytes4[] memory _signatures, uint[] memory _userGroup) public onlyDAOCreator securityFreeze returns(bool){
        IAccessibilitySettings(accessibilitySettingsAddress).disableSignature(_signatures, _userGroup);
        return true;
    }

    function changeSecurityDelay(uint _securityDelay) public onlyDAOCreator securityFreeze returns(bool){
        require(securityDelay != _securityDelay, "CANT_SET_THE_SAME_VALUE");
        securityDelay = _securityDelay;
        return true;
    }

    // PUBLIC FUNCTIONS WITH CHECK ACCESSIBILITY

    function addBalance(address _token, address _user, uint _amount) external checkAccessibility(FUNCTION_ADDBALANCE_SIGNATURE, true) securityFreeze returns(bool){
        require(_user != address(0), "NULL_ADD_NOT_ALLOWED");
        require(_token != address(0), "NULL_ADD_NOT_ALLOWED");
        tokenManagement[_token].lastBlockUserOp[_user] = block.number;  // Sender can't redeem for one day this token
        uint oldbalance = accountability[_token][_user];
        uint newBalance = oldbalance.add(_amount);
        accountability[_token][_user] = newBalance;
        emit ChangeBalanceEvent(msg.sender, _token, _user, oldbalance, newBalance);
        return true;
    }

    function subBalance(address _token, address _user, uint _amount) external checkAccessibility(FUNCTION_SUBBALANCE_SIGNATURE, true) securityFreeze returns(bool){
        require(_user != address(0), "NULL_ADD_NOT_ALLOWED");
        require(_token != address(0), "NULL_ADD_NOT_ALLOWED");
        tokenManagement[_token].lastBlockUserOp[_user] = block.number;  // Sender can't redeem for one day this token
        uint oldbalance = accountability[_token][_user];
        uint newBalance = oldbalance.sub(_amount);
        accountability[_token][_user] = newBalance;
        emit ChangeBalanceEvent(msg.sender, _token, _user, oldbalance, newBalance);
        return true;
    }

    function setUserListRole(address[] memory _userAddress, uint[] memory _userGroup) public checkAccessibility(FUNCTION_SETUSERROLE_SIGNATURE, true) securityFreeze returns(bool){
        require(_userAddress.length == _userGroup.length, "DATA_LENGTH_DISMATCH");
        IAccessibilitySettings(accessibilitySettingsAddress).setUserListRole(_userAddress,_userGroup);
        return true;
    }

    function approveERC20Distribution(address _token, uint _amount) public checkAccessibility(FUNCTION_APPROVEERC20DISTR_SIGNATURE, true) temporaryLockSecurity(_token) securityFreeze returns(bool){
        require(_token != address(0), "NULL_ADD_NOT_ALLOWED");
        require(_amount > 0, "NULL_AMOUNT_NOT_ALLOWED");
        require(tokenReferreal[_token] == msg.sender, "REFEREE_DISMATCH");
        uint decimals = tokenManagement[_token].decimals;
        IERC20Upgradeable(_token).approve(address(this), _amount.mul(uint(10) ** decimals));
        tokenManagement[_token].lastBlockChange = block.number;
        emit SecurityTokenMovements(msg.sender, _token, uint(opID.APPROVE), _amount.mul(uint(10) ** decimals));
        return true;
    }

    function redeemListOfERC20(address[] memory _tokenList) public securityFreeze returns(bool){
        uint userBalance;
        address token;
        bool result;
        result = false;
        for(uint index; index < _tokenList.length; index++){
            tokenManagement[_tokenList[index]].lastBlockUserOp[msg.sender] = block.number;
            token = _tokenList[index];
            userBalance = accountability[token][msg.sender];
            if(userBalance > 0 && securityDelay > block.number.sub(tokenManagement[token].lastBlockUserOp[msg.sender])){
                tokenManagement[_tokenList[index]].lastBlockUserOp[msg.sender] = block.number;  // Sender can't redeem again for one day this token after setting this
                accountability[token][msg.sender] = uint(0);
                require(IERC20Upgradeable(token).balanceOf(address(this)) >= userBalance, "NO_DAO_FUND");
                IERC20Upgradeable(token).transferFrom(address(this), msg.sender, userBalance);
                emit SecurityTokenMovements(msg.sender, token, uint(opID.REDEEM), userBalance);
                emit ChangeBalanceEvent(msg.sender, token, msg.sender, userBalance, uint(0));
                emit RedeemEvent(msg.sender, token, userBalance);
                result = true;
            }
        }
        require(result, "NO_TOKENS");
        return true;
    }

    function registerUpgradeableERC20Token(address _referree, uint _decimals) external securityFreeze returns(bool){
        tokenReferreal[msg.sender] = _referree;                                // msg.sender has to be DUERC20
        tokenManagement[msg.sender].lastBlockChange = block.number;            // No one can't burn, mint or approve for one day this token
        tokenManagement[msg.sender].lastBlockUserOp[_referree] = block.number; // Referee can't redeem for one day this token
        tokenManagement[msg.sender].decimals = _decimals; // Referee can't redeem for one day this token
        emit RegisterERC20UpgradeableEvent(msg.sender, _referree);
        emit SecurityTokenMovements(_referree, msg.sender, uint(opID.CREATE), uint(0));
        return true;
    }

    function burnUpgradeableERC20Token(address _token, uint _amount) public checkAccessibility(FUNCTION_BURNERC20_SIGNATURE, true) temporaryLockSecurity(_token) securityFreeze returns(bool){
        require(_amount > 0, "INSUFFICIENT_AMOUNT"); ///////////////////////////////TO CHECK
        require(tokenReferreal[_token] == msg.sender, "REFEREE_DISMATCH");
        IERC20Upgradeable IERC20U = IERC20Upgradeable(_token);
        uint tokenBalance = IERC20U.balanceOf(address(this));
        uint decimals = tokenManagement[_token].decimals;
        require(tokenBalance > 0 && _amount <= uint(MAX_PERC_TO_BURN).mul(tokenBalance.div(uint(10) ** (decimals + uint(2)))), "SECURITY_DISMATCH"); 
        tokenManagement[_token].lastBlockChange = block.number;             // No one can't burn, mint or approve for one day this token
        tokenManagement[_token].lastBlockUserOp[msg.sender] = block.number; // Sender can't redeem for one day
        IERC20_PDN(_token).burn(_amount.mul(uint(10) ** decimals));
        emit SecurityTokenMovements(msg.sender, _token, uint(opID.BURN), _amount.mul(uint(10) ** decimals));
        return true;
    }

    function getLastBlockUserOp(address _token, address _referree) public view returns(uint){
        return tokenManagement[_token].lastBlockUserOp[_referree];
    }

    function getAccessibility(bytes4 _functionSignature) public view returns(bool){
        return IAccessibilitySettings(accessibilitySettingsAddress).getAccessibility(_functionSignature, msg.sender);
    }

    function getBalance(address _token, address _user) public view returns(uint){
        return accountability[_token][_user];
    }
    
    function getAccessibilitySettingsAddress() public view returns(address){
        return accessibilitySettingsAddress;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract MetaDataStructure {

  enum UserGroup{
        HIDDEN,
        ADMIN,
        USER1,
        USER2,
        USER3,
        USER4,
        USER5,
        USER6,
        USER7,
        USER8,
        USER9,
        USER10,
        USER11,
        USER12,
        USER13,
        USER14,
        USER15,
        USER16,
        USER17,
        USER18,
        USER19,
        USER20,
        USER21,
        USER22,
        USER23,
        USER24,
        USER25,
        USER26,
        USER27,
        USER28,
        USER29,
        USER30
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Signatures {
    bytes4 FUNCTION_ADDBALANCE_SIGNATURE = bytes4(keccak256("addBalance(address,address,uint))"));
    bytes4 FUNCTION_SUBBALANCE_SIGNATURE = bytes4(keccak256("subBalance(address,address,uint)"));
    bytes4 FUNCTION_SETUSERROLE_SIGNATURE = bytes4(keccak256("setUserRole(address,uint)")); 
    bytes4 FUNCTION_CREATEERC20_SIGNATURE = bytes4(keccak256("createERC20(string memory,string memory,uint,uint)"));
    bytes4 FUNCTION_APPROVEERC20DISTR_SIGNATURE = bytes4(keccak256("approveERC20Distribution(address,uint)"));
    bytes4 FUNCTION_BURNERC20_SIGNATURE = bytes4(keccak256("burnUpgradeableERC20Token(address,uint)"));
    bytes4 FUNCTION_MINTERC20_SIGNATURE = bytes4(keccak256("mintUpgradeableERC20Token(address,uint)"));
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAccessibilitySettings {
    function getAccessibility(bytes4 _functionSignature, address _userAddress) external view returns(bool);
    function getUserGroup(address _userAddress) external view returns(uint);
    function enableSignature(bytes4[] memory _functionSignatureList, uint[] memory _userRoles) external returns(bool);
    function disableSignature(bytes4[] memory _functionSignatureList, uint[] memory _userRoles) external returns(bool);
    function setUserListRole(address[] memory _userAddress, uint[] memory _userGroup) external returns(bool);
    function getDAOCreator() external view returns(address);
    function getIsFrozen() external view returns(bool);
    function changeDAOCreator(address _newDAOCreator) external returns(bool);
    function restoreIsFrozen() external returns(bool);
    function multiSigInitialize(address _multiSigRefAddress) external returns(bool);
    function getMultiSigRefAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20_PDN {
    function mint(address _to, uint _totalSupply, uint _decimals) external returns(bool);
    function burn(uint _amount) external returns(bool);
    function changeOwnerWithMultisigDAO(address _newOwner) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
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