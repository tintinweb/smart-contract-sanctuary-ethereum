/**
* ENGA Federation Initial-Sale.
* @author Mehdikovic
* Date created: 2022.06.03
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IController } from "../interfaces/fundraising/IController.sol";
import { SaleState } from "../interfaces/fundraising/IPreSale.sol";
import { TimeHelper } from "../common/TimeHelper.sol";
import { Utils } from "../lib/Utils.sol";


contract SeedSale is TimeHelper, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
    bytes32 public constant OPEN_ROLE         = keccak256("OPEN_ROLE");
    */
    bytes32 public constant OPEN_ROLE         = 0xefa06053e2ca99a43c97c4a4f3d8a394ee3323a8ff237e625fba09fe30ceb0a4;

    uint32 public constant PPM = 1000000;
    
    string private constant ERROR_CONTRACT_IS_ZERO               = "ERROR_CONTRACT_IS_ZERO";
    string private constant ERROR_INVALID_CONTRACT               = "ERROR_INVALID_CONTRACT";
    string private constant ERROR_INVALID_INDEX                  = "ERROR_INVALID_INDEX";
    string private constant ERROR_INVALID_TIME_PERIOD            = "ERROR_INVALID_TIME_PERIOD";
    string private constant ERROR_NOT_KYC                        = "ERROR_NOT_KYC";
    string private constant ERROR_INVALID_GOAL                   = "ERROR_INVALID_GOAL";
    string private constant ERROR_INVALID_MINIMUM_REQUIRED_TOKEN = "ERROR_INVALID_MINIMUM_REQUIRED_TOKEN";
    string private constant ERROR_INVALID_CONTRIBUTE_VALUE       = "ERROR_INVALID_CONTRIBUTE_VALUE";
    string private constant ERROR_INVALID_AMOUNT                 = "ERROR_INVALID_AMOUNT";
    string private constant ERROR_INSUFFICIENT_BALANCE           = "ERROR_INSUFFICIENT_BALANCE";
    string private constant ERROR_INSUFFICIENT_ALLOWANCE         = "ERROR_INSUFFICIENT_ALLOWANCE";
    string private constant ERROR_NO_VESTING_FOUND               = "ERROR_NO_VESTING_FOUND";

    struct Vesting {
        bool initialized;
        
        address beneficiary; // beneficiary of tokens after they are released
        uint256 amountTotal; // total amount of tokens to be released at the end of the vesting
        uint256 released; // amount of tokens released
        
        uint256 start; // start time of the vesting period
        uint256 cliff; // cliff (start time is added before) in seconds
        uint256 end; // end (start time is added before) of the vesting in seconds
    }

    address public contributionToken;
    address public engaToken;
    address public spaceRhinoBeneficiary;
    IController public controller;

    uint256 public daiGoal;
    uint256 public engaGoal;
    uint256 public vestingCliffPeriod;
    uint256 public vestingCompletePeriod;

    uint256 public minimumRequiredToken;

    bool public isOpen;
    uint256 public totalRaised;

    bytes32[] internal vestingsIds;
    mapping(bytes32 => Vesting) internal vestings;
    mapping(address => uint256) internal vestingsCount;
    
    event SaleOpened();
    event VestingCreated(address indexed beneficiary, bytes32 id, uint256 amount);
    event VestingReleased(address indexed beneficiary, bytes32 id, uint256 amount);

    /***** EXTERNAL *****/

    /**
    * @notice Initialize presale
    * @param _owner                     The address of the multisig contract as the owner
    * @param _daiGoal                  The daiGoal to be reached by the end of that presale [in contribution token wei]
    * @param _engaGoal                 The engaGoal to be reached by the end of that presale [in contribution token wei]
    * @param _vestingCliffPeriod       The period during which purchased [bonded] tokens are to be cliffed
    * @param _vestingCompletePeriod    The complete period during which purchased [bonded] tokens are to be vested
    * @param _minimumRequiredToken     The minimum amount required to let users contribute in sell
    */
    constructor(
        address _owner,
        uint256 _daiGoal,
        uint256 _engaGoal,
        uint256 _vestingCliffPeriod,
        uint256 _vestingCompletePeriod,
        uint256 _minimumRequiredToken
    ) {
        Utils.enforceHasContractCode(_owner, ERROR_INVALID_CONTRACT);
        
        require(_daiGoal > 0, ERROR_INVALID_GOAL);
        require(_engaGoal > 0, ERROR_INVALID_GOAL);
        require(_vestingCliffPeriod > 0, ERROR_INVALID_TIME_PERIOD);
        require(_vestingCompletePeriod > _vestingCliffPeriod, ERROR_INVALID_TIME_PERIOD);
        require(_minimumRequiredToken != 0, ERROR_INVALID_MINIMUM_REQUIRED_TOKEN);

        daiGoal = _daiGoal;
        engaGoal = _engaGoal;
        spaceRhinoBeneficiary = _owner;
        vestingCliffPeriod = _vestingCliffPeriod;
        vestingCompletePeriod = _vestingCompletePeriod;
        minimumRequiredToken = _minimumRequiredToken;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPEN_ROLE, _owner);
        _grantRole(OPEN_ROLE, _msgSender());
    }

    /* STATE MODIFIERS */

    /**
    * @notice set initilizing addresses of other contracts
    * @param _controller                The address of the controller contract
    * @param _contributionToken         The address of the contributionToken contract (dai)
    */
    function initializeAddresses(address _controller, address _contributionToken) external onlyRole(OPEN_ROLE) {
        require(isOpen == false);
        require(address(controller) == address(0));
        require(engaToken == address(0));
        Utils.enforceHasContractCode(_contributionToken, ERROR_INVALID_CONTRACT);
        Utils.enforceHasContractCode(_controller, ERROR_INVALID_CONTRACT);
        
        controller = IController(_controller);
        engaToken = controller.engaToken();
        contributionToken = _contributionToken;
    }

    /**
    * @notice Open presale [enabling users to contribute]
    */
    function openNow() external onlyRole(OPEN_ROLE) {
        require(isOpen == false);
        Utils.enforceValidAddress(contributionToken, ERROR_CONTRACT_IS_ZERO);
        Utils.enforceValidAddress(engaToken, ERROR_CONTRACT_IS_ZERO);
        Utils.enforceValidAddress(address(controller), ERROR_CONTRACT_IS_ZERO);
        require(IERC20(engaToken).balanceOf(address(this)) >= engaGoal, ERROR_INSUFFICIENT_BALANCE);
        
        isOpen = true;
        emit SaleOpened();
    }

    /**
    * @notice Contribute to the presale up to `@tokenAmount(self.contributionToken(): address, _value)`
    * @param _value       The amount of contribution token to be spent
    */
    function contribute(uint256 _value) external nonReentrant onlyOpen {
        require(controller.getKycOfUser(_msgSender()), ERROR_NOT_KYC);
        require(_value >= minimumRequiredToken, ERROR_INVALID_CONTRIBUTE_VALUE);
        require(totalRaised < daiGoal);

        _contribute(_msgSender(), _value);
    }

    /**
    * @notice let users release their tokens in their vesting
    * @param vestingId           The id of the vesting
    */
    function release(bytes32 vestingId)
        external
        onlyVestingExists(vestingId)
        nonReentrant
        onlyOpen
    {
        Vesting storage vesting = vestings[vestingId];
        
        uint256 amount = _releaseVesting(vesting);

        require(amount > 0, ERROR_INVALID_AMOUNT);

        IERC20(engaToken).safeTransfer(vesting.beneficiary, amount);
        
        emit VestingReleased(vesting.beneficiary, vestingId, amount);
    }

    /* PUBLIC VIEWS */

    /**
    * @dev indicates what state the presale is in
    * @return the status of the sale [Pending, Funding, Closed]
    */
    function state() public view returns (SaleState) {
        if (!isOpen)
            return SaleState.Pending;
        if (totalRaised >= daiGoal)
            return SaleState.Closed;
        return SaleState.Funding;
    }

    /**
    * @dev Returns the number of vesting associated to a beneficiary.
    * @return the number of vesting
    */
    function getHolderVestingCount(address _beneficiary) external view returns(uint256) {
        return vestingsCount[_beneficiary];
    }

    /**
    * @dev Returns the vesting id at the given index.
    * @return the vesting id
    */
    function getVestingIdAtIndex(uint256 index) external view returns(bytes32) {
        require(index < getVestingCount(), ERROR_INVALID_INDEX);
        return vestingsIds[index];
    }

    /**
    * @notice Returns the vesting information for a given holder and index.
    * @return the vesting  structure information
    */
    function getVestingByAddressAndIndex(address holder, uint256 index) external view returns(Vesting memory) {
        return getVesting(computeId(holder, index));
    }

    /**
    * @dev Returns the number of vesting  managed by this contract.
    * @return the number of vesting 
    */
    function getVestingCount() public view returns(uint256) {
        return vestingsIds.length;
    }

    /**
    * @notice Computes the amount of [bonded] tokens that would be purchased for `@tokenAmount(self.contributionToken(): address, _value)`
    * @param _contribution The amount of contribution tokens to be used in that computation
    */
    function contributionToTokens(uint256 _contribution) public view returns (uint256) {
        return (_contribution * _exchangeRatePPM()) / PPM;
    }

    /**
    * @notice Computes the amount of `@tokenAmount(self.contributionToken(): address, _value)` that had been paid for `@tokenAmount(self.contributionToken(): address, _value)
    * @param _engaToken The amount of enga tokens that are bought by contribution
    */
    function tokenToContributions(uint256 _engaToken) public view returns (uint256) {
        return (_engaToken * PPM) / _exchangeRatePPM();
    }

    function getExchangeRate() external view returns(uint256) {
        return _exchangeRatePPM();
    }

    function computeNextId(address holder) public view returns(bytes32) {
        return computeId(holder, vestingsCount[holder]);
    }

    function computeId(address holder, uint256 index) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
    * @dev Returns the last vesting for a given holder address.
    */
    function getLastVestingForHolder(address holder) public view returns(Vesting memory) {
        require(vestingsCount[holder] > 0, ERROR_NO_VESTING_FOUND);
        return vestings[computeId(holder, vestingsCount[holder] - 1)];
    }

    /**
    * @notice Returns the vesting  information for a given identifier.
    * @return the vesting  structure information
    */
    function getVesting(bytes32 vestingId) public view returns(Vesting memory) {
        return vestings[vestingId];
    }

    /**
    * @notice Returns the owner of the vesting
    * @return the address of beneficiary
    */
    function getVestingOwner(bytes32 vestingId) external view returns(address) {
        return vestings[vestingId].beneficiary;
    }

    /* MODIFIERS */
    modifier onlyVestingExists(bytes32 vestingId) {
        require(vestings[vestingId].initialized == true);
        _;
    }

    modifier onlyOpen() {
        require(isOpen == true);
        _;
    }

    /***** INTERNAL *****/

    function _contribute(address _contributor, uint256 _value) internal {
        uint256 value = totalRaised + _value > daiGoal ? daiGoal - totalRaised : _value;

        require(IERC20(contributionToken).balanceOf(_contributor) >= value, ERROR_INSUFFICIENT_BALANCE);
        require(IERC20(contributionToken).allowance(_contributor, address(this)) >= value, ERROR_INSUFFICIENT_ALLOWANCE);
        _transfer(contributionToken, _contributor, spaceRhinoBeneficiary, value);
        
        uint256 tokensToSell = contributionToTokens(value);

        bytes32 vestingId = computeNextId(_contributor);
        vestings[vestingId] = Vesting(
            true,
            _contributor,
            tokensToSell,
            0,
            getTimeNow(),
            getTimeNow() + vestingCliffPeriod, 
            getTimeNow() + vestingCompletePeriod
        );

        totalRaised += value;
        vestingsIds.push(vestingId);
        vestingsCount[_contributor]++;
        
        emit VestingCreated(_contributor, vestingId, tokensToSell);
    }

    function _releaseVesting(Vesting storage vesting) internal returns(uint256 amount) {
        amount = _computeReleasableAmount(vesting);
        
        if (amount == 0) return 0;
        
        vesting.released += amount;
    }

    function _computeReleasableAmount(Vesting storage vesting)
        internal
        view
        returns(uint256)
    {
        uint256 currentTime = getTimeNow();
        if (currentTime < vesting.cliff) {
            return 0;
        } else if (currentTime >= vesting.end) {
            return vesting.amountTotal - vesting.released;
        } else {
            uint256 start = vesting.cliff; // start from cliff date
            uint256 duration = vesting.end - vesting.cliff; // duration between cliff and end time
            uint256 pastTime = currentTime - start; // how much time has passed from cliff until now
            uint256 vestedAmount = (vesting.amountTotal * pastTime) / duration;
            return vestedAmount - vesting.released;
        }
    }

    function _exchangeRatePPM() internal view returns(uint256) {
        return engaGoal * PPM / daiGoal;
    }

    function _transfer(address _token, address _from, address _to, uint256 _amount) internal {
        if (_from == address(this)) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
* ENGA Federation Controller Interface.
* @author Mehdikovic
* Date created: 2022.04.05
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IController {
    enum ControllerState {
        Constructed,
        ContractsDeployed,
        Initialized
    }
    
    function setNewSaleAddress(address _newSale) external;
    
    function state() external view returns (ControllerState);
    function engaToken() external view returns(address);
    function tokenManager() external view returns(address);
    function marketMaker() external view returns(address);
    function bancorFormula() external view returns(address);
    function beneficiary() external view returns(address);
    function tap() external view returns(address);
    function reserve() external view returns(address);
    function treasury() external view returns(address);
    function kyc() external view returns(address);
    //function preSale() external view returns(address);

    /************************************/
    /**** PRESALE SPECIFIC INTERFACE ****/
    /************************************/
    function closeSale() external;
    function openSaleByDate(uint256 _openDate) external;
    function openSaleNow() external;
    function contribute(uint256 _value) external;
    function refund(address _contributor, bytes32 _vestedPurchaseId) external;
    
    /************************************/
    /****** KYC SPECIFIC INTERFACE ******/
    /************************************/
    function enableKyc() external;
    function disableKyc() external;
    function addKycUser(address _user) external;
    function removeKycUser(address _user) external;
    function getKycOfUser(address _user) external view returns (bool);

    /************************************/
    /*** Treasury SPECIFIC INTERFACE ****/
    /************************************/
    function treasuryTransfer(address _token, address _to, uint256 _value) external;

    /************************************/
    /* TokenManager SPECIFIC INTERFACE **/
    /************************************/
    function createVesting(address _beneficiary, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _end, bool _revocable) external returns (bytes32);
    function revoke(bytes32 vestingId) external;
    function release(bytes32 vestingId) external;
    function closeVestingProcess() external;
    function withdrawTokenManger(address _token, address _receiver, uint256 _amount) external;

    /************************************/
    /** MarketMaker SPECIFIC INTERFACE **/
    /************************************/
    function collateralsToBeClaimed(address _collateral) external view returns(uint256);
    function openPublicTrading(address[] memory collaterals) external;
    function suspendMarketMaker(bool _value) external;
    function updateBancorFormula(address _bancor) external;
    function updateTreasury(address payable _treasury) external;
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external;
    function addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32  _reserveRatio, uint256 _slippage, uint256 _rate, uint256 _floor) external;
    function reAddCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32  _reserveRatio, uint256 _slippage) external;
    function removeCollateralToken(address _collateral) external;
    function updateCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage) external;
    function openBuyOrder(address _collateral, uint256 _value) external;
    function openSellOrder(address _collateral, uint256 _amount) external;
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external;
    function claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) external;
    function claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) external;

    /************************************/
    /****** TAP SPECIFIC INTERFACE ******/
    /************************************/
    function updateBeneficiary(address payable _beneficiary) external;
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external;
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external;
    function removeTappedToken(address _token) external;
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external;
    function updateTappedAmount(address _token) external;
    function withdrawTap(address _collateral) external;
    function getMaximumWithdrawal(address _token) external view returns (uint256);
}

/**
* ENGA Federation PreSale Interface.
* @author Mehdikovic
* Date created: 2022.03.06
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

enum SaleState {
    Pending,     // presale is idle and pending to be started
    Funding,     // presale has started and contributors can purchase tokens
    Refunding,   // presale has not reached goal within period and contributors can claim refunds
    GoalReached, // presale has reached goal within period and trading is ready to be open
    Closed       // presale has reached goal within period, has been closed and trading has been open
}

interface IPreSale {

    function openByDate(uint256 _openDate) external;
    function openNow() external;
    function close() external;
    function state() external view returns (SaleState);
    function getController() external view returns(address);
    function contribute(address _contributor, uint256 _value) external;
    function refund(address _contributor, bytes32 _vestedPurchaseId) external;
    function contributionToTokens(uint256 _contribution) external view returns (uint256);
    function tokenToContributions(uint256 _engaToken) external view returns (uint256);
}

/**
* ENGA Federation TimeHelper.
* @author Mehdikovic
* Date created: 2022.03.08
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

/** NOTE 
* functions are marked as virtual to let tests be written 
* more easily with mock contracts as their parent contracts 
*/

pragma solidity ^0.8.0;

contract TimeHelper {
    function getTimeNow() internal virtual view returns(uint256) {
        return block.timestamp;
    }

    function getBlockNumber() internal virtual view returns(uint256) {
        return block.number;
    }

    function getBatchId(uint256 batchBlocks) internal virtual view returns (uint256) {
        return (block.number / batchBlocks) * batchBlocks;
    }
}

/**
* ENGA Federation Utility contract.
* @author Mehdikovic
* Date created: 2022.03.01
* Github: mehdikovic
* SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

library Utils {
    function getSig(string memory _fullSignature) internal pure returns(bytes4 _sig) {
        _sig = bytes4(keccak256(bytes(_fullSignature)));
    }

    function transferNativeToken(address _to, uint256 _value) internal returns (bool) {
        // solhint-disable avoid-low-level-calls
        (bool sent, ) = payable(_to).call{value: _value}("");
        return sent;
    }

    function enforceHasContractCode(address _target, string memory _errorMsg) internal view {
        require(_target != address(0), _errorMsg);

        uint256 size;
        // solhint-disable-next-line
        assembly { size := extcodesize(_target) }
        require(size > 0, _errorMsg);
    }

    function enforceValidAddress(address _target, string memory _errorMsg) internal pure {
        require(_target != address(0), _errorMsg);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}