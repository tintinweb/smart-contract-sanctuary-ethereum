// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

import "AccessControlUpgradeable.sol";
import "Initializable.sol";
import "AutomationCompatible.sol";
import "AggregatorV3Interface.sol";

import "IPreSendAffiliate.sol";

/**
 * @title Upgradeable PreSend Payments Smart Contract
 * @dev Payment contract that is integrated with the PreSend verification system and Affiliate smart contract
 */
contract PreSendPayments is AutomationCompatibleInterface, Initializable, AccessControlUpgradeable  {
    // Addresses with this role can update user payment information.
    bytes32 public constant PAYMENT_ADMIN = keccak256("PAYMENT_ADMIN");

    // Addresses with this role can extract token fees.
    bytes32 public constant FEE_ADMIN = keccak256("FEE_ADMIN");

    // Mapping to determine how much each address can transfer with PreSend services for each token address.
    // mapping (address (user address) => mapping(address (token address) => uint256 (currency amount fees have been paid for)))
    mapping (address => mapping(address => uint256)) public addressToApprovedAmount;

    // Mapping to determine how much of the fees from this contract can be attributed to each affiliate.
    // This mapping is here instead of the PreSendAffiliate contract since it's dividing the funds stored here by affiliate.
    mapping (address => uint256) public affiliateToPreSendRevenue;

    // Total gross revenue - accounts for all funds that come into this contract.
    uint256 public grossRevenue;

    // Net revenue - fee funds minus what is sent to affiliates.
    uint256 public netRevenue;

    // Affiliate smart contract reference.
    IPreSendAffiliate public preSendAffiliate;

    // Address of the treasury where affiliate payments will go.
    address public treasuryAddress;

    // The divisor to charge a certain percentage of the total currency being transferred as a part of the fee.
    uint256 public feeDivisor;

    // Aggregator to get the price of the native coin in USD.
    // Example - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0 for Matic / USD
    AggregatorV3Interface public aggregator;

    // The interval for sending payment fees to the treasury address with the Chainlink Keeper
    uint256 public sendPaymentFeesInterval;

    // The timestamp for the last time payment fees were sent to the treasury address with the Chainlink Keeper
    uint256 public lastPaymentFeeSendTimeStamp;

    // Number of seconds an affiliate registration lasts for before they need to reregister to get fees again.
    uint256 public affiliateRegistrationTime;

    // Why 10 ** 26? - 10 ** 18 to convert to wei, divide by 100 since it's 2 cents, and then multiple by 10**8 since the aggregator returns the coin price in USD * 10**8.
    uint256 constant aggregatorCoinPriceMult = 10 ** 26;

    // Buffer value - subtract 10**5 from the fee amount in case the price of the native coin updated since the msg.value was calculated in the frontend.
    uint256 constant aggregatorCoinPriceSub = 10 ** 5;

    // Event emitted each time a user pays the fee to use the PreSend service.
    event paymentMade(address indexed user, address currency, uint256 fee, uint256 amountToTransfer, uint256 currencyPrice, address affiliate);

    // Event emitted whenever the PreSendAffiliate contract reference is updated.
    event preSendAffiliateContractUpdated(address indexed newPreSendAffiliateContractAddress);

    // Event emitted whenever the treasury address is updated.
    event treasuryAddressUpdated(address indexed newTreasuryAddress);

    // Event emitted whenever the reference to the aggregator contract is updated.
    event aggregatorReferenceUpdated(address indexed newAggregatorAddress);

    // Event emitted whenever the native coin from fee payments stored in the contract is sent out to the treasury either through the Chainlink keeper or manually.
    event fundsSentToTreasury(address indexed currTreasuryAddress, uint256 amountTransferred);

    // Event emitted whenever the fee divisor is updated.
    event feeDivisorUpdated(uint256 newFeeDivisor);

    // Event emitted whenever the send funds to treasury interval is updated.
    event sendPaymentFeesIntervalUpdated(uint256 indexed newInterval);

    // Event emitted whenever the transfer allowance of a currency is decreased for a user.
    event currencyAllowanceDecreased(address indexed user, address indexed currency, uint256 amount);

    // Event emitted whenever the transfer allowance of a currency is increased for a user.
    event currencyAllowanceIncreased(address indexed user, address indexed currency, uint256 amount);

    // Event emitted whenever the affiliate registration time is updated.
    event affiliateRegistrationTimeUpdated(uint256 newAffiliateRegistrationTime);

    /**
    @dev Initializer function that sets the address of the native dollar token used for fees and the aggregator address. Used in place of constructor since this is an upgradeable contract.
    @param _treasuryAddress the address to send affiliate funds to where they are stored until distributed to the affiliate contract for claiming
    @param _aggregatorAddress the aggregator address for getting native coin prices in USD
    @param _sendPaymentFeesInterval the initial interval for sending payment fees to the treasury address with the Chainlink Keeper
    */
    function initialize(address _treasuryAddress, address _aggregatorAddress, uint256 _sendPaymentFeesInterval) initializer external {
        require(_treasuryAddress != address(0), "Treasury address can't be the 0 address.");
        require(_aggregatorAddress != address(0), "Aggregator address can't be the 0 address.");

        affiliateRegistrationTime = 31536000;
        treasuryAddress = _treasuryAddress;
        aggregator = AggregatorV3Interface(_aggregatorAddress);
        sendPaymentFeesInterval = _sendPaymentFeesInterval;
        lastPaymentFeeSendTimeStamp = block.timestamp;
        feeDivisor = 500;
        netRevenue = 0;
        grossRevenue = 0;

        _setupRole(PAYMENT_ADMIN, msg.sender);
        _setupRole(FEE_ADMIN, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit treasuryAddressUpdated(_treasuryAddress);
        emit aggregatorReferenceUpdated(_aggregatorAddress);
        emit sendPaymentFeesIntervalUpdated(_sendPaymentFeesInterval);
    }

    /**
    @dev Only owner function to set the reference to the PreSend Affiliate smart contract.
    @param _preSendAffiliateAddress the address of the PreSend Affiliate smart contract
    */
    function setPreSendAffiliate(address payable _preSendAffiliateAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_preSendAffiliateAddress != address(0), "PreSend Affiliate address can't be the 0 address.");

        preSendAffiliate = IPreSendAffiliate(_preSendAffiliateAddress);
        emit preSendAffiliateContractUpdated(_preSendAffiliateAddress);
    }

    /**
    @dev Only owner function to set the treasury address.
    @param newTreasuryAddress the address of the treasury
    */
    function setTreasuryAddress(address newTreasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasuryAddress != address(0), "Treasury address can't be the 0 address.");

        treasuryAddress = newTreasuryAddress;
        emit treasuryAddressUpdated(newTreasuryAddress);
    }

    /**
    @dev Only owner function to set the aggregator to determine the native coin price in USD.
    @param newAggregatorAddress the address of the new aggregator
    */
    function setAggregator(address newAggregatorAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAggregatorAddress != address(0), "Aggregator address can't be the 0 address.");

        aggregator = AggregatorV3Interface(newAggregatorAddress);
        emit aggregatorReferenceUpdated(newAggregatorAddress);
    }

    /**
    @dev Private function called by both versions of the payPreSendFee function that handles the logic for charging the PreSend payment fee.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param payment the amount of the native coin the user paid into the smart contract to cover the fee
    @param currencyPrice The price of the currency being transfered with PreSend
    @param affiliate The address of the affiliate wallet that the paying user is tied to
    @param affiliatePercentage the percentage of the fee sent to the affiliate
    */
    function _payPreSendFee(address user, address currency, uint256 amount, uint256 payment, uint256 currencyPrice, address affiliate, uint256 affiliatePercentage) private {
        // Affiliate percentage can be anywhere between 0 and 100 percent, including 0 or 100 percent.
        require(affiliatePercentage <= 100, "Affiliate percentage must be less than or equal to 100.");

        uint256 feeAmount = currencyPrice * amount / 10**18 / feeDivisor;

        // aggregator.latestRoundData returns the coin price in USD * 10**8 hence the 10**26 instead of 10**18
        (, int256 coinPrice, , ,) = aggregator.latestRoundData();

        require(uint256(coinPrice) != 0, "Unable to fetch price of the native coin.");

        // aggregatorCoinPriceMult - Why 10 ** 26? - 10 ** 18 to convert to wei and then multiple by 10**8 since the aggregator returns the coin price in USD * 10**8.
        // aggregatorCoinPriceSub - Subtract 10**5 from the fee amount in case the price of the native coin updated since the msg.value was calculated in the frontend.
        uint256 nativeCoinToDollar = (aggregatorCoinPriceMult / uint256(coinPrice)) - aggregatorCoinPriceSub;

        if (feeAmount < nativeCoinToDollar) {
            feeAmount = nativeCoinToDollar;
        }

        require(payment >= feeAmount, "Payment not enough to cover the fee of the transfer!");

        addressToApprovedAmount[user][currency] += amount;
        grossRevenue += payment;

        if (affiliate != address(0) && preSendAffiliate.affiliateToRegisteredTimestamp(affiliate) > block.timestamp - affiliateRegistrationTime) {
            if (affiliatePercentage > 0) {
                // Step 1 - Update the affiliate balance in the affiliate smart contract to what is was before + the percentage just calculated
                uint256 affiliateAmount = payment * affiliatePercentage / 100;
                affiliateToPreSendRevenue[affiliate] += payment - affiliateAmount;
                netRevenue += payment - affiliateAmount;
                preSendAffiliate.increaseAffiliateAmount(affiliate, affiliateAmount);

                // Step 2 - send the affiliate fee (based on the affiliatePercentage value computed above) to the affiliate in the affiliate contract if they are registered
                // The rest of the native coin just stays in this contract and can be withdrawn by fee admins
                (bool success, ) = address(preSendAffiliate).call{value: affiliateAmount}("");
                require(success, "Failed to send funds to the affiliate.");
            }
            else {
                netRevenue += payment;
            }
        }
        else {
            netRevenue += payment;
        }

        emit paymentMade(user, currency, payment, amount, currencyPrice, affiliate);
    }

    /**
    @dev Payment function without an affiliate address.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param currencyPrice The price of the curreny being transfered with PreSend
    */
    function payPreSendFee(address currency, uint256 amount, uint256 currencyPrice) external payable {
        _payPreSendFee(msg.sender, currency, amount, msg.value, currencyPrice, address(0), 0);
    }

    /**
    @dev Payment function with an affiliate address.
    @param currency The address of the currency the user wants to transfer with PreSend
    @param amount The amount of the currency the user wants to transfer
    @param currencyPrice The price of the curreny being transfered with PreSend
    @param affiliate The address of the affiliate wallet that the paying user is tied to
    @param affiliatePercentage The percentage of the fee that goes to the affiliate
    */
    function payPreSendFee(address currency, uint256 amount, uint256 currencyPrice, address affiliate, uint256 affiliatePercentage) external payable {
        _payPreSendFee(msg.sender, currency, amount, msg.value, currencyPrice, affiliate, affiliatePercentage);
    }

    /**
    @dev Chainlink Keeper function to determine if upkeep needs to be performed (payment fees need to be sent to the treasury address).
    @return upkeepNeeded boolean to determine if upkeep is necessary (i.e. it's time to send the payment fees to the treasury address)
    */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastPaymentFeeSendTimeStamp) > sendPaymentFeesInterval;
    }

    /**
    @dev Chainlink Keeper function to perform upkeep (sending payment fees to the treasury address).
    */
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastPaymentFeeSendTimeStamp) > sendPaymentFeesInterval) {
            lastPaymentFeeSendTimeStamp = block.timestamp;
            uint256 currBalance = address(this).balance;
            (bool success, ) = treasuryAddress.call{value: currBalance}("");
            require(success, "Failed to send native coin to treasury address");
            emit fundsSentToTreasury(treasuryAddress, currBalance);
        }
    }    

    /**
    @dev Payment admin only function to decrease the allowance of a currency a user can transfer.
    @param user the address of the user to decrease the allowance of a currency for
    @param currency the address of the currency to decrease the allowance of
    @param amount the amount to decrease the allowance by
    */
    function decreaseCurrencyAllowance(address user, address currency, uint256 amount) external onlyRole(PAYMENT_ADMIN) {
        require(user != address(0), "User cannot be the zero address.");
        require(addressToApprovedAmount[user][currency] >= amount, "The user doesn't have the allowance for the specified currency to decrease the allowance by the amount given.");
        addressToApprovedAmount[user][currency] -= amount;
        emit currencyAllowanceDecreased(user, currency, amount);
    }

    /**
    @dev Payment admin only function to increase the allowance of a currency a user can transfer.
    @param user the address of the user to increase the allowance of a currency for
    @param currency the address of the currency to increase the allowance of
    @param amount the amount to increase the allowance by
    */
    function increaseCurrencyAllowance(address user, address currency, uint256 amount) external onlyRole(PAYMENT_ADMIN) {
        require(user != address(0), "User cannot be the zero address.");
        addressToApprovedAmount[user][currency] += amount;
        emit currencyAllowanceIncreased(user, currency, amount);
    }

    /**
    @dev Payment admin only function to update the amount of seconds an affiliate is registered for.
    @param newAffiliateRegistrationTime the new registration time in seconds for affiliates before they need to reregister
    */
    function setAffiliateRegistrationTime(uint256 newAffiliateRegistrationTime) external onlyRole(PAYMENT_ADMIN) {
        require(newAffiliateRegistrationTime > 0, "Affiliate registration time must be greater than zero seconds.");
        affiliateRegistrationTime = newAffiliateRegistrationTime;
        emit affiliateRegistrationTimeUpdated(newAffiliateRegistrationTime);
    }

    /**
    @dev Fee admin only function to manually send PreSend transaction fees from the contract to the treasury address (usually the Chainlink Keeper will take care of this).
    */
    function extractFees() external onlyRole(FEE_ADMIN) {
        uint256 currBalance = address(this).balance;
        (bool success, ) = treasuryAddress.call{value: currBalance}("");
        require(success, "Failed to send native coin to the treasury address");
        emit fundsSentToTreasury(treasuryAddress, currBalance);
    }

    /**
    @dev Only owner function to change the payment admin.
    @param newAdmin address of the user to make a payment admin so they can update the addressToApprovedAmount mapping
    @param oldAdmin address of the user to remove from the payment admin role
    */
    function changePaymentAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(PAYMENT_ADMIN, newAdmin);
        _revokeRole(PAYMENT_ADMIN, oldAdmin);
    }

    /**
    @dev Only owner function to change the fee admin.
    @param newAdmin address of the user to make a fee admin so they can take fees from the contract
    @param oldAdmin address of the user to remove from the fee admin role
    */
    function changeFeeAdmin(address newAdmin, address oldAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "New admin address cannot be the zero address.");
        require(oldAdmin != address(0), "Old admin address cannot be the zero address.");
        _grantRole(FEE_ADMIN, newAdmin);
        _revokeRole(FEE_ADMIN, oldAdmin);
    }

    /**
    @dev Only owner function to set the divisor for the token percentage part of the PreSend transfer fee.
    @param newFeeDivisor the new divisor for the token percentage part of the fee
    */
    function setFeeDivisor(uint256 newFeeDivisor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDivisor = newFeeDivisor;
        emit feeDivisorUpdated(newFeeDivisor);
    }

    /**
    @dev Only owner function to set the interval that determines how often the native coin stored in the contract from fee payments is sent to the treasury.
    @param newInternval the interval to determine how often funds are sent to the treasury from this contract
    */
    function setSendPaymentFeesInternval(uint256 newInternval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sendPaymentFeesInterval = newInternval;
        emit sendPaymentFeesIntervalUpdated(newInternval);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControlUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AutomationBase.sol";
import "AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

/**
 * @title PreSend Affiliate Contract Interface
 */
interface IPreSendAffiliate {
    // Addresses with this role can update affiliate balances and deposit amounts.
    function AFFILIATE_ADMIN() external view returns (bytes32);

    // Role for the payment smart contract.
    function PAYMENT_CONTRACT() external view returns (bytes32);

    // Mapping to determine the block timestamp for when an affiliate registered.
    function affiliateToRegisteredTimestamp(address affiliate) external view returns (uint256);

    // Mapping to determine the claimable balance for each affiliate.
    function affiliateToClaimableAmount(address affiliate) external view returns (uint256);

    // Mapping to determine the total amount raised by an affiliate.
    function affiliateToTotalRaised(address affiliate) external view returns (uint256);

    // The address of the PreSend payments smart contract.
    function paymentsAddress() external view returns (address);

    // Event to emit whenever an affiliate claims.
    event affiliateClaimed(address indexed affiliate, uint256 amount);

    // Event to emit whenever the amount an affiliate can claim is increased.
    event affiliateAmountIncreased(address indexed affiliate, uint256 amountIncreasedBy);

    // Event to emit whenever the amount an affiliate can claim is decreased.
    event affiliateAmountDecreased(address indexed affiliate, uint256 amountDecreasedBy);

    // Event to emit whenever the PreSend Payment contract address is updated.
    event paymentContractAddressUpdated(address indexed newPaymentContractAddress);

    // Event to emit whenever an affiliate is added.
    event affiliateAdded(address indexed affiliate);

    /**
    @dev Initializer function that sets the address of the payments contract. Used in place of constructor since this is an upgradeable contract.
    @param _paymentsAddress the address of the PreSend payments contract
    */
    function initialize(address _paymentsAddress) external;

    /**
    @dev Function for affiliates to claim their cut of their affiliate partners paying for PreSend transfers.
    */
    function affiliateClaim() external;

    /**
    @dev Function to add an affiliate at 5% - anyone can call this to make themselves an affiliate at 5%
    @param affiliate the address of the affiliate
    */
    function addAffiliate(address affiliate) external;

    /** 
    @dev Function for the payment smart contract to invoke whenever someone pays a fee and part of it goes to an affiliate.
    @param affiliate the address of the affiliate receiving funds
    @param amount the amount of the native coin going to the affiliate
    */
    function increaseAffiliateAmount(address affiliate, uint256 amount) external;

    /** 
    @dev Function for the payment smart contract to decrease the next deposit amount for an affiliate.
    @param affiliate the address of the affiliate funds are being decreased for
    @param amount the amount of the native coin to remove from an affiliate's next deposit
    */
    function decreaseAffiliateAmount(address affiliate, uint256 amount) external;

    /**
    @dev Affiliate admin only function to update the payment smart contract address.
    @param newPaymentAddress the new payment address
    */
    function updatePaymentAddress(address newPaymentAddress) external;

    /**
    @dev Only owner function to change the affiliate admin for depositing funds. This is the role given to the address the Chainlink keeper uses.
    @param newAdmin address of the user to make an affiliate admin
    @param oldAdmin address of the user to remove from the affiliate admin role
    */
    function changeAffiliateAdmin(address newAdmin, address oldAdmin) external;

    /**
    @dev Only owner function to change the payment contract admin in case any of the payment functions need to be called manually (such as increaseAffiliateAmount).
    @param newAdmin address of the user to make a payment admin
    @param oldAdmin address of the user to remove from the payment admin role
    */
    function changePaymentAdmin(address newAdmin, address oldAdmin) external;

    receive() external payable;
}