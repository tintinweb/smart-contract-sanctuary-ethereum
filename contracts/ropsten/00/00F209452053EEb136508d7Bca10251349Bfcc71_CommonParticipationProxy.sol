// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";


interface IRPGC {
    function transferToProxy(address exchanger, uint amount) external;

    function transferToExchange(address exchanger, uint amount) external;
}

contract CommonParticipationProxy is Initializable, OwnableUpgradeable, AdminRole, TokenProviderRole {

    using SafeMathUpgradeable for *;

    uint public totalTokensToDistribute;
    uint public totalTokensWithdrawn;
    string public name;

    struct Participation {
        uint256 totalParticipation;
        uint256 withdrawnAmount;
        uint256 lastWithdrawnPortionId;
    }

    IERC20 public token;

    mapping(address => Participation) private addressToParticipation;
    mapping(address => bool) public hasParticipated;

    uint public numberOfPortions;
    uint public timeBetweenPortions;
    uint[] distributionDates;
    uint[] portionsUnlockingPercents;

    event NewPercentages(uint[] portionPercents);
    event NewDates(uint[] distrDates);
    event Withdrawn(address to, uint amount, uint timestamp);

    /// Load initial distribution dates
    function initialize (
        uint _numberOfPortions,
        uint _timeBetweenPortions,
        uint[] memory _portionsUnlockingPercents,
        address _adminWallet,
        address _token,
        string memory _name
    ) external initializer
    {
        __Ownable_init();

        require(_numberOfPortions == _portionsUnlockingPercents.length, 
            "number of portions is not equal to number of percents");

        // Store number of portions
        numberOfPortions = _numberOfPortions;
        // Store time between portions
        timeBetweenPortions = _timeBetweenPortions;

        require(correctPercentages(_portionsUnlockingPercents), "total percent has to be equal to 100%");
        portionsUnlockingPercents = _portionsUnlockingPercents;

        // Set the token address
        token = IERC20(_token);
        name = _name;

        _addAdmin(_adminWallet);
    }

    /// Register participant
    function registerParticipant(
        address participant,
        uint participationAmount
    )
    public onlyTokenProvider
    {
        require(totalTokensToDistribute.sub(totalTokensWithdrawn).add(participationAmount) <= token.balanceOf(address(this)),
            "Safeguarding existing token buyers. Not enough tokens."
        );
        if (distributionDates.length != 0){
            require(distributionDates[0] > block.timestamp, "sales have ended");
        }


        totalTokensToDistribute = totalTokensToDistribute.add(participationAmount);

        // Create new participation object
        Participation storage p = addressToParticipation[participant];
        
        p.totalParticipation = p.totalParticipation.add(participationAmount);

        if (!hasParticipated[participant]){
            p.withdrawnAmount = 0;

            p.lastWithdrawnPortionId = ~uint256(0);

            // Mark that user have participated
            hasParticipated[participant] = true;
        }
    }

    // User will always withdraw everything available
    function withdraw()
    external
    {
        require(hasParticipated[msg.sender] == true, "(withdraw) the address is not a participant.");
        require(distributionDates.length != 0, "(withdraw) distribution dates are not set");

        _withdraw();
    }

    function _withdraw() private {
        address user = msg.sender;
        Participation storage p = addressToParticipation[user];

        uint remainLocked = p.totalParticipation.sub(p.withdrawnAmount);
        require(remainLocked > 0, "everything unlocked");
    
        uint256 toWithdraw = 0;
        uint256 amountPerPortion = 0;

        for(uint i = 0; i < distributionDates.length; i++) {
            if(isPortionUnlocked(i) == true) {
                if(p.lastWithdrawnPortionId < i || p.lastWithdrawnPortionId == ~uint256(0)) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.totalParticipation.mul(portionsUnlockingPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);

                    // Mark portion as withdrawn
                    p.lastWithdrawnPortionId = i;
                }
            }
            else {
                break;
            }
        }
        
        if (isPortionUnlocked(distributionDates.length-1)){
            uint remain = p.totalParticipation.sub(p.withdrawnAmount.add(toWithdraw));
            if (remain > 0){
                toWithdraw = toWithdraw.add(remain);
            }
        } 

        require(toWithdraw > 0, "nothing to withdraw");

        require(p.totalParticipation >= p.withdrawnAmount.add(toWithdraw), "(withdraw) impossible to withdraw more than vested");
        p.withdrawnAmount = p.withdrawnAmount.add(toWithdraw);
        // Account total tokens withdrawn.
        require(totalTokensToDistribute >= totalTokensWithdrawn.add(toWithdraw), "(withdraw) withdraw amount more than distribution");
        totalTokensWithdrawn = totalTokensWithdrawn.add(toWithdraw);
        // Transfer all tokens to user
        token.transfer(user, toWithdraw);

        emit Withdrawn(user, toWithdraw, block.timestamp);
    }

    function startDistribution(uint256 fromDate) external onlyOwner {
        require(distributionDates.length == 0, "(startDistribution) distribution dates already set");

        uint[] memory _distributionDates = new uint[](numberOfPortions);
        for (uint i = 0; i < numberOfPortions; i++){
            
            _distributionDates[i] = fromDate.add(timeBetweenPortions.mul(i));
        }

        distributionDates = _distributionDates;
    }

    function transfer(address recipient, uint256 amount) external onlyTokenProvider returns (bool) {
        IRPGC(address(token)).transferToProxy(msg.sender, amount);
        registerParticipant(recipient, amount);
        return true;
    }

    function withdrawUndistributedTokens() external onlyOwner {
        if(distributionDates.length != 0){
            require(block.timestamp > distributionDates[distributionDates.length - 1], 
                "(withdrawUndistributedTokens) only after distribution");
        }
        uint unDistributedAmount = token.balanceOf(address(this)).sub(totalTokensToDistribute.sub(totalTokensWithdrawn));
        require(unDistributedAmount > 0, "(withdrawUndistributedTokens) zero to withdraw");
        token.transfer(owner(), unDistributedAmount);
    }

    function setPercentages(uint256[] calldata _portionPercents) external onlyAdmin {
        require(_portionPercents.length == numberOfPortions, 
            "(setPercentages) number of percents is not equal to actual number of portions");
        require(correctPercentages(_portionPercents), "(setPercentages) total percent has to be equal to 100%");
        portionsUnlockingPercents = _portionPercents;

        emit NewPercentages(_portionPercents);
    }

    function updateOneDistrDate(uint index, uint newDate) external onlyAdmin {
        distributionDates[index] = newDate;

        emit NewDates(distributionDates);
    }

    function updateAllDistrDates(uint[] memory newDates) external onlyAdmin {
        require(portionsUnlockingPercents.length == newDates.length, "(updateAllDistrDates) the number of Percentages and Dates do not match");
        distributionDates = newDates;

        emit NewDates(distributionDates);
    }

    function setNewUnlockingSystem(uint[] memory newDates, uint[] memory newPercentages) external onlyAdmin {
        require(newPercentages.length == newDates.length, "(setNewUnlockingSystem) the number of Percentages and Dates do not match");
        require(correctPercentages(newPercentages), "(setNewUnlockingSystem) wrong percentages");
        distributionDates = newDates;
        portionsUnlockingPercents = newPercentages;
        numberOfPortions = newDates.length;

        emit NewDates(distributionDates);
        emit NewPercentages(portionsUnlockingPercents);
    }

    function updateToken(IERC20 _token) external onlyAdmin {
        token = _token;
    }

    function availableToClaim(address user) public view returns(uint) {
        if (distributionDates.length == 0) {
            return 0;
        }

        Participation memory p = addressToParticipation[user];
        uint256 toWithdraw = 0;
        uint256 amountPerPortion = 0;

        for(uint i = 0; i < distributionDates.length; i++) {
            if(isPortionUnlocked(i) == true) {
                if(p.lastWithdrawnPortionId < i || p.lastWithdrawnPortionId == ~uint256(0)) {
                    // Add this portion to withdraw amount
                    amountPerPortion = p.totalParticipation.mul(portionsUnlockingPercents[i]).div(10000);
                    toWithdraw = toWithdraw.add(amountPerPortion);

                }
            }
            else {
                break;
            }
        }
        
        if (isPortionUnlocked(distributionDates.length-1)){
            uint remain = p.totalParticipation.sub(p.withdrawnAmount.add(toWithdraw));
            if (remain > 0){
                toWithdraw = toWithdraw.add(remain);
            }
        }

        return toWithdraw;
    }

    function correctPercentages(uint[] memory portionsPercentages) internal pure returns(bool) {
        uint totalPercent = 0;
        for(uint i = 0 ; i < portionsPercentages.length; i++) {
            totalPercent = totalPercent.add(portionsPercentages[i]);
        }

        return totalPercent == 10000;
    }    

    function isPortionUnlocked(uint portionId) public view returns (bool) {
        return block.timestamp >= distributionDates[portionId];
    }

    function getParticipation(address account) public view returns (uint256, uint256, uint256) {
        Participation memory p = addressToParticipation[account];
        return (
            p.totalParticipation,
            p.withdrawnAmount,
            p.lastWithdrawnPortionId
        );
    }

    // Get all distribution dates
    function getDistributionDates() external view returns (uint256[] memory) {
        return distributionDates;
    }

    // Get all distribution percents
    function getDistributionPercents() external view returns (uint256[] memory) {
        return portionsUnlockingPercents;
    }

    function balance() external view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function addTokenProvider(address account) external onlyAdmin {
        require(!isTokenProvider(account), "[Token Provider Role]: account already has token provider role");
        _addTokenProvider(account);
    }

    function removeTokenProvider(address account) external onlyAdmin {
        require(isTokenProvider(account), "[Token Provider Role]: account has not token provider role");
        _removeTokenProvider(account);
    }

    function addAdmin(address account) external onlyOwner {
        require(!isAdmin(account), "[Admin Role]: account already has admin role");
        _addAdmin(account);
    }

    function removeAdmin(address account) external onlyOwner {
        require(isAdmin(account), "[Admin Role]: account has not admin role");
        _removeAdmin(account);
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

/**
 * @title AdminRole
 * @dev An operator role contract.
 */
abstract contract AdminRole is Initializable, ContextUpgradeable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    function __Admin_role_init() internal onlyInitializing {
    }

    function __Admin_role_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev Makes function callable only if sender is an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    /**
     * @dev Checks if the address is an admin.
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

/**
 * @title TokenProviderRole
 * @dev An operator role contract.
 */
abstract contract TokenProviderRole is Initializable, ContextUpgradeable {
    using Roles for Roles.Role;

    event TokenProviderAdded(address indexed account);
    event TokenProviderRemoved(address indexed account);

    Roles.Role private _providers;

    function __Provider_role_init() internal onlyInitializing {
    }

    function __Provider_role_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev Makes function callable only if sender is an token provider.
     */
    modifier onlyTokenProvider() {
        require(isTokenProvider(_msgSender()), "TokenProviderRole: caller does not have the Token Provider role");
        _;
    }

    /**
     * @dev Checks if the address is an token provider.
     */
    function isTokenProvider(address account) public view returns (bool) {
        return _providers.has(account);
    }

    function _addTokenProvider(address account) internal {
        _providers.add(account);
        emit TokenProviderAdded(account);
    }

    function _removeTokenProvider(address account) internal {
        _providers.remove(account);
        emit TokenProviderRemoved(account);
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
     * This empty reserved space is put in place to allow future versions to add new
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