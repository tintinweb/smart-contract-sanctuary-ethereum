// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IShareDistribute.sol";

contract ExchangePool is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant Owner_ROLE = keccak256("Owner_ROLE");

    IERC20 public LEVA;
    IShareDistribute partner;

    struct PartnersAccountDetails {
        address partnersAddress;
        uint256 partnersTokenAmount;
    }

    struct PartnerInfo {
        uint256 amountOfLEVAReturn;
        uint256 amountOfUSDTOrUSDCRecieved;
        bool status;
    }

    mapping(uint256 => PartnersAccountDetails) partnersList;
    mapping(address => PartnerInfo) transactionRecords;
    mapping(uint256 => bool) oneTimeTransferToPartners;
    mapping(address => bool) whiteListAddress;

    uint256 public constant decimal = 1e18;
    uint256 public constant level1percentage = 25;
    uint256 public constant level2percentage = 9;
    uint256 public constant percentage = 1e2;
    uint256 public limitedUSDTOrUSDCAmountForPartner = 85846154;
    uint256 public level1Amount = 1.2e9;
    uint256 public level2Amount = 7.167e9;
    uint256 public exchangeRate;
    uint256 public exchangeRate1;

    address public mainOwner;
    address public partnerContract;

    bool oneTimeTransfer;
    bool reverseSwapStart;
    bool pause;

    event TransferLEVA(address from, address to, uint256 amount);
    event TransferUSDCOrUSDT(address from, address to, uint256 amount);

    modifier onlyOwner() {
        require(hasRole(Owner_ROLE, msg.sender), "Caller is not a owner");
        _;
    }

    modifier paused() {
        require(pause, "contract is paused");
        _;
    }

    constructor(
        address _token,
        address _owner,
        address _partnerContract,
        uint256 _exchangeRate,
        uint256 _exchangeRate1,
        address[] memory _partnerAddress // only 0-2 partner address
    ) {
        LEVA = IERC20(_token);

        mainOwner = _owner;
        partnerContract = _partnerContract;
        partner = IShareDistribute(_partnerContract);
        oneTimeTransfer = true;

        exchangeRate = _exchangeRate;
        exchangeRate1 = _exchangeRate1;

        partnersList[0].partnersTokenAmount = 81658537; //1.Jonathan
        partnersList[1].partnersTokenAmount = 1e7; //2.	PCS
        partnersList[2].partnersTokenAmount = 1e6; //3.	JBR
        _setupRole(Owner_ROLE, mainOwner);
        _setpartnersAddress(_partnerAddress);
    }

    function pausedContract(bool _status) external nonReentrant onlyOwner {
        pause = _status;
    }

    function _partnerAirdrop() external nonReentrant onlyOwner paused {
        require(oneTimeTransfer, "participation token send");
        uint256 _amount = limitedUSDTOrUSDCAmountForPartner.mul(decimal);
        require(
            LEVA.allowance(mainOwner, address(this)) >= _amount,
            "allowance is not enough for LEVA"
        );
        LEVA.transferFrom(mainOwner, partnerContract, _amount);
        oneTimeTransfer = false;
    }

    function partnersAirdrop(uint256 _index)
        external
        nonReentrant
        onlyOwner
        paused
    {
        require(!oneTimeTransferToPartners[_index], "participation token send");
        uint256 _amount = partnersList[_index].partnersTokenAmount.mul(decimal);

        require(
            LEVA.allowance(mainOwner, address(this)) >= _amount,
            "allowance is not enough for LEVA"
        );
        LEVA.transferFrom(
            mainOwner,
            partnersList[_index].partnersAddress,
            _amount
        );
    }

    function setExchangeRate(uint256 _exchangeRate)
        external
        nonReentrant
        onlyOwner
        paused
    {
        exchangeRate = _exchangeRate;
    }

    function setExchangeRate1(uint256 _exchangeRate)
        external
        nonReentrant
        onlyOwner
        paused
    {
        exchangeRate1 = _exchangeRate;
    }

    function changeTokenAddress(address _token)
        external
        nonReentrant
        onlyOwner
        paused
    {
        LEVA = IERC20(_token);
    }

    function withdrawLEVAToken(uint256 _amount)
        external
        nonReentrant
        onlyOwner
        paused
    {
        LEVA.transfer(mainOwner, _amount);
    }

    function changeOwnerAddress(address _owner)
        external
        nonReentrant
        onlyOwner
        paused
    {
        mainOwner = _owner;
        _setupRole(Owner_ROLE, mainOwner);
    }

    function withdrawUSDCOrUSDTToken(uint256 _amount, address _swapTokenAddress)
        external
        nonReentrant
        onlyOwner
        paused
    {
        IERC20(_swapTokenAddress).transfer(mainOwner, _amount);
    }

    function TokenBalance(address _address) external view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    function allowReverseSwap(bool _value)
        external
        nonReentrant
        onlyOwner
        paused
    {
        reverseSwapStart = _value;
    }

    function getRecords(address _address)
        external
        view
        returns (uint256, uint256)
    {
        return (
            transactionRecords[_address].amountOfUSDTOrUSDCRecieved,
            transactionRecords[_address].amountOfLEVAReturn
        );
    }

    function swapUSDCOrUSDTToToken(uint256 _amount, address _swapTokenAddress)
        external
        nonReentrant
        paused
    {
        require(
            IERC20(_swapTokenAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "allowance is not enough"
        );

        IERC20(_swapTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _transferringUSDCOrUSDTToOwnerAndPartners(_amount, _swapTokenAddress);

        uint256 tokenAmount = tokenPriceCalculation(_amount);
        // require(LEVA.balanceOf(address(this)) >= tokenAmount,"contract don't have enough LEVA token");

        LEVA.transferFrom(mainOwner, msg.sender, tokenAmount);
        transactionRecords[mainOwner].amountOfLEVAReturn = transactionRecords[
            mainOwner
        ].amountOfLEVAReturn.add(tokenAmount);

        emit TransferLEVA(address(this), msg.sender, tokenAmount);
    }

    function swapTokenToUSDCOrUSDT(uint256 _amount, address _swapTokenAddress)
        external
        nonReentrant
        paused
    {
        require(
            LEVA.allowance(msg.sender, address(this)) >= _amount,
            "allowance is not enough"
        );

        if (!whiteListAddress[msg.sender]) {
            require(reverseSwapStart, "reverse swap not allowed");
        }

        uint256 ExchangeTokenAmount = _amount.mul(exchangeRate1);
        ExchangeTokenAmount = ExchangeTokenAmount.div(1e2);

        IERC20(_swapTokenAddress).transferFrom(
            mainOwner,
            msg.sender,
            ExchangeTokenAmount
        );

        LEVA.transferFrom(msg.sender, mainOwner, _amount);
    }

    function tokenPriceCalculation(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 tokenAmount = _amount.div(exchangeRate);
        tokenAmount = tokenAmount.mul(1e2);
        return tokenAmount;
    }

    function _transferringUSDCOrUSDTToOwnerAndPartners(
        uint256 _amount,
        address _swapTokenAddress
    ) internal {
        uint256 _mainOwner = transactionRecords[mainOwner]
            .amountOfUSDTOrUSDCRecieved;
        uint256 _partner = transactionRecords[partnerContract]
            .amountOfUSDTOrUSDCRecieved;

        if ((_partner + _mainOwner + _amount) <= (level1Amount.mul(decimal))) {
            _transferringUSDCOrUSDT(
                _amount,
                level1percentage,
                _swapTokenAddress
            );
        } else if (
            (_partner + _mainOwner) < (level1Amount.mul(decimal)) &&
            (_partner + _mainOwner + _amount) > (level1Amount.mul(decimal))
        ) {
            uint256 _levelTwoAmount = (_partner + _mainOwner + _amount) -
                (level1Amount.mul(decimal));
            uint256 _levelOneAmount = _amount.sub(_levelTwoAmount);
            _transferringUSDCOrUSDT(
                _levelOneAmount,
                level1percentage,
                _swapTokenAddress
            );
            _transferringUSDCOrUSDT(
                _levelTwoAmount,
                level2percentage,
                _swapTokenAddress
            );
        } else if (
            (_partner + _mainOwner + _amount) <= (level2Amount.mul(decimal))
        ) {
            _transferringUSDCOrUSDT(
                _amount,
                level2percentage,
                _swapTokenAddress
            );
        } else if (
            (_partner + _mainOwner) < (level2Amount.mul(decimal)) &&
            (_partner + _mainOwner + _amount) > (level2Amount.mul(decimal))
        ) {
            uint256 _levellastAmount = (_partner + _mainOwner + _amount) -
                (level2Amount.mul(decimal));
            uint256 _levelTwoAmount = _amount.sub(_levellastAmount);
            _transferringUSDCOrUSDT(
                _levelTwoAmount,
                level2percentage,
                _swapTokenAddress
            );
            _transferringUSDCOrUSDTToOwner(_levellastAmount, _swapTokenAddress);
        } else {
            _transferringUSDCOrUSDTToOwner(_amount, _swapTokenAddress);
        }
    }

    function _transferringUSDCOrUSDTToOwner(
        uint256 _amount,
        address _swapTokenAddress
    ) internal {
        IERC20(_swapTokenAddress).transfer(mainOwner, _amount);

        transactionRecords[mainOwner]
            .amountOfUSDTOrUSDCRecieved = transactionRecords[mainOwner]
            .amountOfUSDTOrUSDCRecieved
            .add(_amount);

        emit TransferUSDCOrUSDT(address(this), mainOwner, _amount);
    }

    function _transferringUSDCOrUSDT(
        uint256 _amount,
        uint256 _percentage,
        address _swapTokenAddress
    ) internal {
        uint256 calculatingPartnerAmount = _amount.mul(_percentage).div(
            percentage
        );
        uint256 ownerAmount = _amount.sub(calculatingPartnerAmount);

        uint256 balanceOfPartnerContract = partner.balanceOf(); 

        uint256 tokenAmount = calculatingPartnerAmount.div(exchangeRate1);
        tokenAmount = tokenAmount.mul(1e2);

        if(balanceOfPartnerContract<tokenAmount)
        {
            uint256 lastAmount = balanceOfPartnerContract.mul(exchangeRate1).div(1e2);
            ownerAmount = ownerAmount + (calculatingPartnerAmount-lastAmount);
            calculatingPartnerAmount =  lastAmount;
        }      

        transactionRecords[partnerContract]
            .amountOfUSDTOrUSDCRecieved = transactionRecords[partnerContract]
            .amountOfUSDTOrUSDCRecieved
            .add(calculatingPartnerAmount);

        transactionRecords[mainOwner]
            .amountOfUSDTOrUSDCRecieved = transactionRecords[mainOwner]
            .amountOfUSDTOrUSDCRecieved
            .add(ownerAmount);

        IERC20(_swapTokenAddress).transfer(mainOwner, ownerAmount);
        IERC20(_swapTokenAddress).transfer(
            partnerContract,
            calculatingPartnerAmount
        );

        partner.distributingUSDTOrUSDC(
            calculatingPartnerAmount,
            _swapTokenAddress,
            exchangeRate1
        );
        _returnLEVAFromPartners(calculatingPartnerAmount);

        emit TransferUSDCOrUSDT(address(this), mainOwner, ownerAmount);
        emit TransferUSDCOrUSDT(
            address(this),
            partnerContract,
            calculatingPartnerAmount
        );
    }

    function _returnLEVAFromPartners(uint256 _amount) internal {
        uint256 tokenAmount = _amount.div(exchangeRate1);
        tokenAmount = tokenAmount.mul(1e2); // calculate with exchange rate 1
        require(
            LEVA.balanceOf(address(this)) >= tokenAmount,
            "contract don't have enough LEVA token"
        );

        require(LEVA.transfer(mainOwner, tokenAmount), "tokens not return");
        transactionRecords[partnerContract]
            .amountOfLEVAReturn = transactionRecords[partnerContract]
            .amountOfLEVAReturn
            .add(tokenAmount);
    }

    function _setpartnersAddress(address[] memory _address) internal onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            partnersList[i].partnersAddress = _address[i];
            whiteListAddress[(_address[i])] = true;
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
pragma solidity ^0.8.4;

interface IShareDistribute
{
    function distributingUSDTOrUSDC(uint256 _amount,address _swapTokenAddress,uint256 _exchangeRate) external;
    function balanceOf() external view returns(uint256);
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