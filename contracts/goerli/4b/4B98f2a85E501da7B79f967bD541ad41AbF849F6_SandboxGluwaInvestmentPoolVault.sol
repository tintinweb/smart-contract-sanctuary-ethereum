// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../GluwaInvestmentPoolVault.sol';

contract SandboxGluwaInvestmentPoolVault is GluwaInvestmentPoolVault {
    GluwaInvestmentModel.Balance[] private matureBalanceResultWhenWithdraw;
    GluwaInvestmentModel.Balance[] private unstartedBalanceResultWhenWithdraw;

    function getBalanceState(bytes32 balanceHash) external view returns (GluwaInvestmentModel.BalanceState) {
        return _getBalanceState(balanceHash);
    }

    function getMatureBalanceWhenWithdraw(bytes32[] calldata balancesHashList) external returns (GluwaInvestmentModel.Balance[] memory) {
        _withdrawBalances(balancesHashList, _msgSender(), 0);
        GluwaInvestmentModel.Balance[] memory tmp = _getMatureBalanceList(_msgSender());
        for (uint256 i = 0; i < tmp.length; i++) {
            matureBalanceResultWhenWithdraw.push(tmp[i]);
        }
    }

    function getMatureBalanceListResult() external view returns (GluwaInvestmentModel.Balance[] memory) {
        return matureBalanceResultWhenWithdraw;
    }

    function getUnstartedBalanceWhenWithdraw(bytes32[] calldata balancesHashList) external returns (GluwaInvestmentModel.Balance[] memory) {
        _withdrawUnstartedBalances(balancesHashList, _msgSender(), 0);
        GluwaInvestmentModel.Balance[] memory tmp = _getUnstartedBalanceList(_msgSender());
        for (uint256 i = 0; i < tmp.length; i++) {
            unstartedBalanceResultWhenWithdraw.push(tmp[i]);
        }
    }

    function getUnstartedBalanceListResult() external view returns (GluwaInvestmentModel.Balance[] memory) {
        return unstartedBalanceResultWhenWithdraw;
    }

    function createAccountLockSameBlock(
        address account,
        uint256 amount,
        bytes32 identityHash,
        bytes32 poolHash,
        uint256 gluwaNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        _lockPool(poolHash);
        bytes32 _CREATEACCOUNT_TYPEHASH = keccak256(
            'createAccountBySig(address account,uint256 amount,bytes32 identityHash,bytes32 poolHash,uint256 gluwaNonce)'
        );
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_CREATEACCOUNT_TYPEHASH, account, amount, identityHash, poolHash, gluwaNonce))),
            v,
            r,
            s
        );
        require(isController(signer), 'GluwaInvestment: Unauthorized access');
        _useNonce(signer, gluwaNonce);
        _createAccount(account, amount, 0, uint64(block.timestamp), identityHash, poolHash);

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';

import './libs/GluwaInvestmentModel.sol';
import './abstracts/SignerNonce.sol';
import './abstracts/VaultControl.sol';
import './abstracts/GluwaInvestment.sol';

contract GluwaInvestmentPoolVault is SignerNonce, EIP712Upgradeable, VaultControl, GluwaInvestment {
    bytes32 private constant _CREATEACCOUNT_TYPEHASH =
        keccak256('createAccountBySig(address account,uint256 amount,bytes32 identityHash,bytes32 poolHash,uint256 gluwaNonce)');

    bytes32 private constant _CREATEBALANCE_TYPEHASH = keccak256('createBalanceBySig(address account,uint256 amount,bytes32 poolHash,uint256 gluwaNonce)');

    function initialize(address adminAccount, address token) external initializer {
        _VaultControl_Init(adminAccount);
        _GluwaInvestment_init(token);
    }

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Invest(address indexed recipient, uint256 amount);

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712NameHash() internal pure override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    function version() public pure returns (string memory) {
        return '2.0.0';
    }

    function name() public pure returns (string memory) {
        return 'Gluwa-Investor-DAO';
    }

    function updateRewardSettings(
        address rewardToken,
        uint16 rewardOnPrincipal,
        uint16 rewardOnInterest
    ) external onlyOperator returns (bool) {
        _updateRewardSettings(rewardToken, rewardOnPrincipal, rewardOnInterest);
        return true;
    }

    function setAccountState(bytes32 accountHash, GluwaInvestmentModel.AccountState state) external onlyController returns (bool) {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        require(account.startingDate > 0, 'GluwaInvestmentPoolVault: Invalid hash');
        account.state = state;
        return true;
    }

    function invest(address recipient, uint256 amount) external onlyOperator returns (bool) {
        require(recipient != address(0), 'GluwaInvestmentPoolVault: Recipient address for investment must be defined');
        require(_token.balanceOf(address(this)) >= amount, 'GluwaInvestmentPoolVault: the investment amount must be lower than the contract balance');
        _token.transfer(recipient, amount);
        emit Invest(recipient, amount);
        return true;
    }

    /// @dev The controller creates an account for users, the user need to pay fee for that.
    function createAccount(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 identityHash,
        bytes32 poolHash
    )
        external
        virtual
        onlyController
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        return _createAccount(account, amount, fee, uint64(block.timestamp), identityHash, poolHash);
    }

    /// @dev The controller can sign to allow anyone to create an account. The sender will pay for gas
    function createAccountBySig(
        address account,
        uint256 amount,
        bytes32 identityHash,
        bytes32 poolHash,
        uint256 gluwaNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_CREATEACCOUNT_TYPEHASH, account, amount, identityHash, poolHash, gluwaNonce))),
            v,
            r,
            s
        );
        require(isController(signer), 'GluwaInvestment: Unauthorized access');
        _useNonce(signer, gluwaNonce);
        return _createAccount(account, amount, 0, uint64(block.timestamp), identityHash, poolHash);
    }

    /// @dev The controller creates a balance for users, the user need to pay fee for that.
    function createBalance(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 poolHash
    ) external virtual onlyController returns (bool, bytes32) {
        return (true, _createBalance(account, amount, fee, poolHash));
    }

    /// @dev The controller can sign to allow anyone to create a balance. The sender will pay for gas
    function createBalanceBySig(
        address account,
        uint256 amount,
        bytes32 poolHash,
        uint256 gluwaNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (bool, bytes32) {
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_CREATEBALANCE_TYPEHASH, account, amount, poolHash, gluwaNonce))),
            v,
            r,
            s
        );
        require(isController(signer), 'GluwaInvestment: Unauthorized access');
        _useNonce(signer, gluwaNonce);
        return (true, _createBalance(account, amount, 0, poolHash));
    }

    function withdrawUnstartedBalances(bytes32[] calldata balanceHashList) external returns (bool) {
        uint256 totalWithdrawal = _withdrawUnstartedBalances(balanceHashList, _msgSender(), 0);
        _token.transfer(_msgSender(), totalWithdrawal);
        emit Withdraw(_msgSender(), totalWithdrawal);
        return true;
    }

    function withdrawUnstartedBalancesFor(
        bytes32[] calldata balanceHashList,
        address account,
        uint256 fee
    ) external onlyController returns (bool) {
        uint256 totalWithdrawal = _withdrawUnstartedBalances(balanceHashList, account, fee);
        _token.transfer(account, totalWithdrawal);
        emit Withdraw(account, totalWithdrawal);
        return true;
    }

    function withdrawUnclaimedMatureBalances(
        bytes32[] calldata balanceHashList,
        address account,
        address recipient,
        uint256 fee
    ) external onlyAdmin {
        require(_token.transfer(recipient, _withdrawBalances(balanceHashList, account, fee)), 'GluwaInvestment: Unable to send amount to withdraw balance');
    }

    function withdrawBalancesFor(
        bytes32[] calldata balanceHashList,
        address ownerAddress,
        uint256 fee
    ) external onlyController returns (bool) {
        require(
            _token.transfer(ownerAddress, _withdrawBalances(balanceHashList, ownerAddress, fee)),
            'GluwaInvestment: Unable to send amount to withdraw balance'
        );
        return true;
    }

    function withdrawBalances(bytes32[] calldata balanceHashList) external returns (bool) {
        require(
            _token.transfer(_msgSender(), _withdrawBalances(balanceHashList, _msgSender(), 0)),
            'GluwaInvestment: Unable to send amount to withdraw balance'
        );
        return true;
    }

    function _withdrawBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress,
        uint256 fee
    ) internal override(GluwaInvestment) returns (uint256) {
        uint256 totalWithdrawableAmount = super._withdrawBalances(balanceHashList, ownerAddress, fee);
        require(totalWithdrawableAmount > 0, 'GluwaInvestmentPoolVault: No balance is withdrawable.');
        emit Withdraw(ownerAddress, totalWithdrawableAmount);
        return totalWithdrawableAmount;
    }

    function createPool(
        uint32 interestRate,
        uint32 tenor,
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) external onlyOperator returns (bytes32) {
        return _createPool(interestRate, tenor, openDate, closeDate, startDate, minimumRaise, maximumRaise);
    }

    function addPoolRepayment(
        address source,
        bytes32 poolHash,
        uint256 amount
    ) external onlyOperator returns (bool) {
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

        require(
            amount + pool.totalRepayment <= _calculateTotalExpectedPoolWithdrawal(pool.interestRate, pool.tenor, pool.totalDeposit),
            'GluwaInvestment: Repayment exceeds total expected withdrawal amount'
        );

        require(_token.transferFrom(source, address(this), amount), 'GluwaInvestment: Unable to send for pool repayment');

        unchecked {
            pool.totalRepayment += amount;
        }

        return true;
    }

    function lockPool(bytes32 poolHash) external onlyOperator {
        _lockPool(poolHash);
    }

    function unlockPool(bytes32 poolHash) external onlyOperator {
        _unlockPool(poolHash);
    }

    function cancelPool(bytes32 poolHash) external onlyOperator {
        _cancelPool(poolHash);
    }

    function getUserBalanceList(address account) external view onlyController returns (uint64[] memory) {
        return _getUserBalanceList(account);
    }

    function getUnstartedBalances(address owner) external view returns (GluwaInvestmentModel.Balance[] memory) {
        require(owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        return _getUnstartedBalanceList(owner);
    }

    function getMatureBalances(address owner) external view returns (GluwaInvestmentModel.Balance[] memory) {
        require(owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        return _getMatureBalanceList(owner);
    }

    function getBalance(bytes32 balanceHash)
        external
        view
        returns (
            uint64,
            bytes32,
            bytes32,
            address,
            uint32,
            uint32,
            uint256,
            uint256,
            uint256,
            uint64,
            uint64,
            GluwaInvestmentModel.BalanceState
        )
    {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        require(balance.owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        GluwaInvestmentModel.BalanceState balanceState = _getBalanceState(balanceHash);
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];

        return (
            balance.idx,
            balance.accountHash,
            balance.poolHash,
            balance.owner,
            pool.interestRate,
            INTEREST_DENOMINATOR,
            _calculateYield(pool.interestRate, pool.tenor, balance.principal),
            balance.totalWithdrawal,
            balance.principal,
            pool.startingDate,
            pool.startingDate + pool.tenor,
            balanceState
        );
    }

    function getUserAccount(bytes32 accountHash)
        external
        view
        onlyController
        returns (
            uint64,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        return (account.idx, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function getAccountFor(address account)
        external
        view
        onlyController
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        return _getAccountFor(account);
    }

    function getAccountHashByIdx(uint64 idx) external view onlyController returns (bytes32) {
        return _getAccountHashByIdx(idx);
    }

    function getBalanceHashByIdx(uint64 idx) external view onlyController returns (bytes32) {
        return _getBalanceHashByIdx(idx);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/** @title Library functions used by contracts within this ecosystem.*/
library GluwaInvestmentModel {
    /**
     * @dev Enum of the different states a Pool can be in.
     */
    enum PoolState {
        /*0*/
        Pending,
        /*1*/
        Scheduled,
        /*2*/
        Open,
        /*3*/
        Closed,
        /*4*/
        Mature,
        /*5*/
        Rejected,
        /*6*/
        Canceled,
        /*7*/
        Locked
    }

    /**
     * @dev Enum of the different states an Account can be in.
     */
    enum AccountState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Locked,
        /*3*/
        Closed
    }

    /**
     * @dev Enum of the different states a Balance can be in.
     */
    enum BalanceState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Mature,
        /*3*/
        Closed /* The balance is matured and winthdrawn */
    }

    struct Pool {
        uint32 interestRate;
        uint32 tenor;
        // Index of this Pool
        uint64 idx;
        uint64 openingDate;
        uint64 closingDate;
        uint64 startingDate;
        uint128 minimumRaise;
        uint256 maximumRaise;
        uint256 totalDeposit;
        uint256 totalRepayment;
    }

    struct Account {
        // Different states an account can be in
        AccountState state;
        // Index of this Account
        uint64 idx;
        uint64 startingDate;
        uint256 totalDeposit;
        bytes32 securityReferenceHash;
    }

    struct Balance {
        // Index of this balance
        uint64 idx;
        // address of the owner
        address owner;
        uint256 principal;
        uint256 totalWithdrawal;
        bytes32 accountHash;
        bytes32 poolHash;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

contract SignerNonce is ContextUpgradeable {
    mapping(bytes32 => bool) private _nonceUsed;

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function isNonceUsed(uint256 nonce) public view virtual returns (bool) {
        return _isNonceUsed(_msgSender(), nonce);
    }

    /**
     * @dev Check whether a nonce is used for a signer.
     */
    function _isNonceUsed(address signer, uint256 nonce) private view returns (bool) {
        return _nonceUsed[keccak256(abi.encodePacked(signer, nonce))];
    }

    function revokeSignature(uint256 nonce) external virtual returns (bool) {
        _nonceUsed[keccak256(abi.encodePacked(_msgSender(), nonce))] = true;
        return true;
    }

    /**
     * @dev Register a nonce for a signer.
     */
    function _useNonce(address signer, uint256 nonce) internal {
        require(!_isNonceUsed(signer, nonce), 'SignerNonce: Invalid Nonce');
        _nonceUsed[keccak256(abi.encodePacked(signer, nonce))] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

contract VaultControl is AccessControlEnumerableUpgradeable {
    bytes32 private constant _OPERATOR_ROLE = keccak256('OPERATOR');
    bytes32 private constant _CONTROLLER_ROLE = keccak256('CONTROLLER');

    function _VaultControl_Init(address account) internal onlyInitializing {
        __AccessControl_init();
        _setRoleAdmin(_OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_CONTROLLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(_OPERATOR_ROLE, account);
        _setupRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), 'Restricted to Admins.');
        _;
    }

    /// @dev Restricted to members of the Controller role.
    modifier onlyController() {
        require(isController(_msgSender()), 'Restricted to Controllers.');
        _;
    }

    /// @dev Restricted to members of the Operator role.
    modifier onlyOperator() {
        require(isOperator(_msgSender()), 'Restricted to Operators.');
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the operator role.
    function isOperator(address account) public view returns (bool) {
        return hasRole(_OPERATOR_ROLE, account);
    }

    /// @dev Add an account to the operator role. Restricted to admins.
    function addOperator(address account) external onlyAdmin {
        grantRole(_OPERATOR_ROLE, account);
    }

    /// @dev Remove an account from the Operator role. Restricted to admins.
    function removeOperator(address account) external onlyAdmin {
        revokeRole(_OPERATOR_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the Controller role.
    function isController(address account) public view returns (bool) {
        return hasRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Add an account to the Controller role. Restricted to admins.
    function addController(address account) external onlyAdmin {
        grantRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Remove an account from the Controller role. Restricted to Admins.
    function removeController(address account) external onlyAdmin {
        revokeRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Remove oneself from the Admin role thus all other roles.
    function renounceAdmin() external {
        address sender = _msgSender();
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
        renounceRole(_OPERATOR_ROLE, sender);
        renounceRole(_CONTROLLER_ROLE, sender);
    }

    /// @dev Remove oneself from the Operator role.
    function renounceOperator() external {
        renounceRole(_OPERATOR_ROLE, _msgSender());
    }

    /// @dev Remove oneself from the Controller role.
    function renounceController() external {
        renounceRole(_CONTROLLER_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './IERC20MintUpgradeable.sol';

import '../libs/GluwaInvestmentModel.sol';
import '../libs/HashMapIndex.sol';
import '../libs/Uint64ArrayUtil.sol';

error AccountIsLocked();

contract GluwaInvestment is ContextUpgradeable {
    using HashMapIndex for HashMapIndex.HashMapping;
    using Uint64ArrayUtil for uint64[];

    uint32 public constant INTEREST_DENOMINATOR = 100_000_000;

    /// @dev The supported token which can be deposited to an account.
    IERC20Upgradeable internal _token;

    /// @dev The reward token which will be sent to users upon balance maturity.
    IERC20MintUpgradeable private _rewardToken;

    uint16 private _rewardOnPrincipal;
    uint16 private _rewardOnInterest;

    HashMapIndex.HashMapping private _poolIndex;
    HashMapIndex.HashMapping private _accountIndex;
    HashMapIndex.HashMapping private _balanceIndex;

    mapping(address => bytes32) private _addressAccountMapping;
    mapping(address => uint64[]) private _addressBalanceMapping;
    mapping(bytes32 => bool) private _usedIdentityHash;
    mapping(bytes32 => uint8) private _poolManualState;

    mapping(bytes32 => bool) internal _balancePrematureClosed;
    mapping(bytes32 => GluwaInvestmentModel.Pool) internal _poolStorage;
    mapping(bytes32 => GluwaInvestmentModel.Account) internal _accountStorage;
    mapping(bytes32 => GluwaInvestmentModel.Balance) internal _balanceStorage;

    event LogPool(bytes32 indexed poolHash);

    event LogAccount(bytes32 indexed accountHash, address indexed owner);

    event LogBalance(bytes32 indexed balanceHash, address indexed owner, uint256 deposit, uint256 fee);

    function _GluwaInvestment_init(address tokenAddress) internal onlyInitializing {
        _token = IERC20Upgradeable(tokenAddress);
    }

    function _updateRewardSettings(
        address rewardToken,
        uint16 rewardOnPrincipal,
        uint16 rewardOnInterest
    ) internal {
        _rewardToken = IERC20MintUpgradeable(rewardToken);
        _rewardOnPrincipal = rewardOnPrincipal;
        _rewardOnInterest = rewardOnInterest;
    }

    function _getBalanceState(bytes32 balanceHash) internal view returns (GluwaInvestmentModel.BalanceState) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        unchecked {
            if (
                _balancePrematureClosed[balanceHash] ||
                balance.totalWithdrawal == balance.principal + _calculateYield(pool.interestRate, pool.tenor, balance.principal)
            ) {
                return GluwaInvestmentModel.BalanceState.Closed;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Mature;
            }

            /// @dev it implies pool.startingDate + pool.tenor > block.timestamp based on the previous if
            if (pool.startingDate <= block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Active;
            }
        }
        return GluwaInvestmentModel.BalanceState.Pending;
    }

    function _getPoolState(bytes32 poolHash) internal view returns (GluwaInvestmentModel.PoolState) {
        unchecked {
            if (_poolManualState[poolHash] > 0) {
                return GluwaInvestmentModel.PoolState(_poolManualState[poolHash]);
            }

            GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

            if (pool.openingDate > block.timestamp) {
                return GluwaInvestmentModel.PoolState.Scheduled;
            }

            if (pool.minimumRaise > pool.totalDeposit && block.timestamp >= pool.closingDate) {
                return GluwaInvestmentModel.PoolState.Rejected;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Mature;
            }

            /// @dev it implies pool.startingDate + pool.tenor > block.timestamp based on the previous if
            if (pool.closingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Closed;
            }

            /// @dev since pool.closingDate > pool.openingDate, therfore this condition implies currentTime < pool.closingDate
            if (pool.openingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Open;
            }
        }

        return GluwaInvestmentModel.PoolState.Pending;
    }

    /// @dev as it is for a read function, we still return the list of balances when the account is locked so that we can help users to plan for fund retrieval
    function _getUnstartedBalanceList(address owner) internal view returns (GluwaInvestmentModel.Balance[] memory) {
        uint64[] storage balanceIds = _addressBalanceMapping[owner];
        GluwaInvestmentModel.Balance[] memory balanceList = new GluwaInvestmentModel.Balance[](balanceIds.length);
        GluwaInvestmentModel.Balance memory temp;
        GluwaInvestmentModel.PoolState poolStateTemp;
        for (uint256 i; i < balanceIds.length; ) {
            temp = _balanceStorage[_balanceIndex.get(balanceIds[i])];
            poolStateTemp = _getPoolState(temp.poolHash);
            if (
                (poolStateTemp == GluwaInvestmentModel.PoolState.Rejected || poolStateTemp == GluwaInvestmentModel.PoolState.Canceled) &&
                !_balancePrematureClosed[_balanceIndex.get(balanceIds[i])]
            ) {
                balanceList[i] = temp;
            }
            unchecked {
                ++i;
            }
        }
        return balanceList;
    }

    /// @dev as it is for a read function, we still return the list of balances when the account is locked so that we can help users to plan for fund retrieval
    function _getMatureBalanceList(address owner) internal view returns (GluwaInvestmentModel.Balance[] memory) {
        uint64[] storage balanceIds = _addressBalanceMapping[owner];
        GluwaInvestmentModel.Balance[] memory balanceList = new GluwaInvestmentModel.Balance[](balanceIds.length);
        GluwaInvestmentModel.Balance memory temp;
        for (uint256 i; i < balanceIds.length; ) {
            temp = _balanceStorage[_balanceIndex.get(balanceIds[i])];
            if (
                _getBalanceState(_balanceIndex.get(balanceIds[i])) == GluwaInvestmentModel.BalanceState.Mature &&
                _getPoolState(temp.poolHash) == GluwaInvestmentModel.PoolState.Mature
            ) {
                balanceList[i] = temp;
            }
            unchecked {
                ++i;
            }
        }
        return balanceList;
    }

    function getPool(bytes32 poolHash) external view returns (GluwaInvestmentModel.Pool memory, GluwaInvestmentModel.PoolState) {
        return (_poolStorage[poolHash], _getPoolState(poolHash));
    }

    function getAccount()
        external
        view
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        return _getAccountFor(_msgSender());
    }

    function _getUserBalanceList(address account) internal view returns (uint64[] memory) {
        return _addressBalanceMapping[account];
    }

    function _getAccountHashByIdx(uint64 idx) internal view returns (bytes32) {
        return _accountIndex.get(idx);
    }

    function _getBalanceHashByIdx(uint64 idx) internal view returns (bytes32) {
        return _balanceIndex.get(idx);
    }

    function _getAccountFor(address owner)
        internal
        view
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        bytes32 accountHash = _addressAccountMapping[owner];
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        return (account.idx, owner, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function _createAccount(
        address owner,
        uint256 initialDeposit,
        uint256 fee,
        uint64 startDate,
        bytes32 identityHash,
        bytes32 poolHash
    )
        internal
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        require(owner != address(0), 'GluwaInvestment: Account owner address must be defined');

        /// @dev ensure one address only have one account by using account hash (returned by addressAccountMapping[account]) to check
        if (_addressAccountMapping[owner] != 0x0) {
            require(_accountStorage[_addressAccountMapping[owner]].startingDate == 0, 'GluwaInvestment: Each address should have only 1 account only');
        }

        require(_usedIdentityHash[identityHash] == false, 'GluwaInvestment: Identity hash is already used');

        bytes32 accountHash = keccak256(abi.encodePacked(_accountIndex.nextIdx, 'Account', address(this), owner));

        /// @dev Add the account to the data storage
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        unchecked {
            account.idx = _accountIndex.nextIdx;
            account.startingDate = startDate;
            /// @dev set the account's initial status
            account.state = GluwaInvestmentModel.AccountState.Active;
            account.securityReferenceHash = identityHash;

            _addressAccountMapping[owner] = accountHash;
            _usedIdentityHash[identityHash] = true;
        }
        _accountIndex.add(accountHash);

        emit LogAccount(accountHash, owner);

        return (true, accountHash, _createBalance(owner, initialDeposit, fee, poolHash));
    }

    function _createPool(
        uint32 interestRate,
        uint32 tenor,
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) internal returns (bytes32) {
        require(openDate < closeDate && closeDate < startDate && minimumRaise < maximumRaise, 'GluwaInvestment: Invalid argument value(s)');

        bytes32 poolHash = keccak256(abi.encodePacked(_poolIndex.nextIdx, openDate, closeDate, startDate, interestRate, tenor, minimumRaise, maximumRaise));

        /// @dev Add the pool to the data storage
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];
        unchecked {
            pool.idx = _poolIndex.nextIdx;
            pool.interestRate = interestRate;
            pool.tenor = tenor;
            pool.openingDate = openDate;
            pool.closingDate = closeDate;
            pool.startingDate = startDate;
            pool.minimumRaise = minimumRaise;
            pool.maximumRaise = maximumRaise;
        }
        _poolIndex.add(poolHash);

        emit LogPool(poolHash);

        return poolHash;
    }

    function _unlockPool(bytes32 poolHash) internal {
        require(_getPoolState(poolHash) == GluwaInvestmentModel.PoolState.Locked, 'GluwaInvestment: Pool is not locked');
        _poolManualState[poolHash] = 0;
    }

    function _lockPool(bytes32 poolHash) internal {
        require(_poolManualState[poolHash] == 0, 'GluwaInvestment: Cannot lock pool');
        _poolManualState[poolHash] = uint8(GluwaInvestmentModel.PoolState.Locked);
    }

    function _cancelPool(bytes32 poolHash) internal {
        require(_poolStorage[poolHash].startingDate > block.timestamp, 'GluwaInvestment: Cannot cancel the pool');
        _poolManualState[poolHash] = uint8(GluwaInvestmentModel.PoolState.Canceled);
    }

    function _createBalance(
        address owner,
        uint256 deposit,
        uint256 fee,
        bytes32 poolHash
    ) internal returns (bytes32) {
        require(deposit > 0, 'GluwaInvestment: Deposit must be > 0');

        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

        require(
            pool.totalDeposit + deposit <= pool.maximumRaise && _getPoolState(poolHash) == GluwaInvestmentModel.PoolState.Open,
            'GluwaInvestment: the pool does not allow more deposit'
        );

        bytes32 balanceHash = keccak256(abi.encodePacked(_balanceIndex.nextIdx, 'Balance', address(this), owner));

        bytes32 hashOfReferenceAccount = _addressAccountMapping[owner];

        require(
            _accountStorage[hashOfReferenceAccount].state == GluwaInvestmentModel.AccountState.Active,
            "GluwaInvestment: The user's account must be active to create more balance"
        );

        require(_token.transferFrom(owner, address(this), deposit + fee), 'GluwaInvestment: Unable to send amount to create balance');

        /// @dev Add the balance to the data storage
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        unchecked {
            balance.idx = _balanceIndex.nextIdx;
            balance.owner = owner;
            balance.principal = deposit;
            balance.accountHash = hashOfReferenceAccount;
            balance.poolHash = poolHash;
            _accountStorage[hashOfReferenceAccount].totalDeposit += deposit;
            pool.totalDeposit += deposit;
        }
        _addressBalanceMapping[owner].add(_balanceIndex.nextIdx);
        _balanceIndex.add(balanceHash);

        emit LogBalance(balanceHash, owner, deposit, fee);

        return balanceHash;
    }

    function _withdrawBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress_,
        uint256 fee
    ) internal virtual returns (uint256 totalWithdrawalAmount) {
        for (uint256 i; i < balanceHashList.length; ) {
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHashList[i]];
            require(balance.owner == ownerAddress_, 'GluwaInvestment: The balance is not owned by the owner');
            unchecked {
                totalWithdrawalAmount += _matureBalance(balanceHashList[i], balance);
                ++i;
            }
        }
        totalWithdrawalAmount -= fee;
    }

    function _withdrawUnstartedBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress_,
        uint256 fee
    ) internal virtual returns (uint256 totalWithdrawalAmount) {
        GluwaInvestmentModel.Account storage account = _accountStorage[_addressAccountMapping[ownerAddress_]];
        if (account.state == GluwaInvestmentModel.AccountState.Locked) {
            revert AccountIsLocked();
        }
        GluwaInvestmentModel.PoolState poolStateTemp;
        for (uint256 i; i < balanceHashList.length; ) {
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHashList[i]];
            poolStateTemp = _getPoolState(balance.poolHash);

            require(
                (poolStateTemp == GluwaInvestmentModel.PoolState.Rejected || poolStateTemp == GluwaInvestmentModel.PoolState.Canceled) &&
                    balance.owner == ownerAddress_ &&
                    !_balancePrematureClosed[balanceHashList[i]],
                'GluwaInvestmentPoolVault: Unable to withdraw the balance'
            );
            unchecked {
                _balancePrematureClosed[balanceHashList[i]] = true;
                balance.totalWithdrawal = balance.principal;
                account.totalDeposit -= balance.principal;
                totalWithdrawalAmount += balance.principal;
                ++i;
            }
        }
        totalWithdrawalAmount -= fee;
    }

    function _matureBalance(bytes32 balanceHash, GluwaInvestmentModel.Balance storage balance) private returns (uint256) {
        GluwaInvestmentModel.Account storage account = _accountStorage[balance.accountHash];
        if (account.state == GluwaInvestmentModel.AccountState.Locked) {
            revert AccountIsLocked();
        }
        require(
            _getBalanceState(balanceHash) == GluwaInvestmentModel.BalanceState.Mature &&
                _getPoolState(balance.poolHash) == GluwaInvestmentModel.PoolState.Mature,
            'GluwaInvestment: The balance is not avaiable to withdraw'
        );
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        uint256 withdrawalAmount = ((balance.principal + _calculateYield(pool.interestRate, pool.tenor, balance.principal)) * pool.totalRepayment) /
            _calculateTotalExpectedPoolWithdrawal(pool.interestRate, pool.tenor, pool.totalDeposit) -
            balance.totalWithdrawal;

        unchecked {
            /// @dev Reduce total deposit for the holding account
            if (balance.principal >= balance.totalWithdrawal) {
                if (withdrawalAmount + balance.totalWithdrawal <= balance.principal) {
                    account.totalDeposit -= withdrawalAmount;
                } else {
                    account.totalDeposit -= (balance.principal - balance.totalWithdrawal);
                }
            }

            /// @dev we only give reward when the pool repayment enough to cover more than pricipal amount
            if (_rewardToken != IERC20MintUpgradeable(address(0)) && withdrawalAmount + balance.totalWithdrawal > balance.principal) {
                if (balance.totalWithdrawal <= balance.principal) {
                    _rewardToken.mint(
                        balance.owner,
                        _calculateReward(_rewardOnPrincipal, balance.principal) +
                            _calculateReward(_rewardOnInterest, withdrawalAmount + balance.totalWithdrawal - balance.principal)
                    );
                } else {
                    _rewardToken.mint(balance.owner, _calculateReward(_rewardOnInterest, withdrawalAmount));
                }
            }

            balance.totalWithdrawal += withdrawalAmount;
        }
        return withdrawalAmount;
    }

    /**
     * @return all the contract's settings;.
     */
    function settings() external view returns (uint32, IERC20Upgradeable, IERC20MintUpgradeable, uint16, uint16) {
        return (INTEREST_DENOMINATOR, _token, _rewardToken, _rewardOnPrincipal, _rewardOnInterest);
    }

    /// @dev calculate yield for given amount based on term and interest rate.
    function _calculateYield(
        uint32 interestRate,
        uint32 tenor,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * uint256(interestRate) * uint256(tenor)) / (uint256(INTEREST_DENOMINATOR) * 365 days);
    }

    /// @dev calculate the total withdrawal amount for a pool
    function _calculateTotalExpectedPoolWithdrawal(
        uint32 interestRate,
        uint32 tenor,
        uint256 poolTotalDeposit
    ) internal pure returns (uint256) {
        return poolTotalDeposit + _calculateYield(interestRate, tenor, poolTotalDeposit);
    }

    /// @dev calculate the reward
    function _calculateReward(uint256 rewardRate, uint256 amount) private pure returns (uint256) {
        return (amount * rewardRate) / 10000;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IERC20MintUpgradeable is IERC20Upgradeable {
    function mint(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/** @title Library functions used by contracts within this ecosystem.*/
library HashMapIndex {
    /**
     * @dev Enum to store the states of HashMapping entries
     */
    enum HashState {
        /*0*/
        Invalid,
        /*1*/
        Active,
        /*2*/
        Archived
    }

    /**
     * @dev Efficient storage container for active and archived hashes enabling iteration
     */
    struct HashMapping {
        mapping(bytes32 => HashState) hashState;
        mapping(uint64 => bytes32) itHashMap;
        uint64 firstIdx;
        uint64 nextIdx;
        uint64 count;
    }

    /**
     * @dev Add a new hash to the storage container if it is not yet part of it
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to add to the struct
     */
    function add(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the hash has not been previously already been added (is still in an invalid state)
        assert(self.hashState[_hash] == HashState.Invalid);
        // Set the state of hash to Active
        self.hashState[_hash] = HashState.Active;
        // Index the hash with the next idx
        self.itHashMap[self.nextIdx] = _hash;
        self.nextIdx++;
        self.count++;
    }

    /**
     * @dev Archives an existing hash if it is an active hash part of the struct
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to archive in the struct
     */
    function archive(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the state of the hash is active
        assert(self.hashState[_hash] == HashState.Active);
        // Set the State of hash to Archived
        self.hashState[_hash] = HashState.Archived;
        // Reduce the size of the number of active hashes
        self.count--;

        // Check if the first hash in the active list is in an archived state
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }

        // Repeat one more time to allowing for 'catch up' of firstIdx;
        // Check if the first hash in the active list is still active or has it already been archived
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }
    }

    /**
     * @dev Verifies if the hash provided is a currently active hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is active (and part of the mapping)
     */
    function isActive(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Active;
    }

    /**
     * @dev Verifies if the hash provided is an archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is archived (and part of the mapping)
     */
    function isArchived(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Archived;
    }

    /**
     * @dev Verifies if the hash provided is either an active or archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is either active or archived (part of the mapping)
     */
    function isValid(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] != HashState.Invalid;
    }

    /**
     * @dev Retrieve the specified (_idx) hash from the struct
     * @param self Struct storage container pointing to itself
     * @param _idx Index of the hash to retrieve
     * @return Hash specified by the _idx value (returns 0x0 if _idx is an invalid index)
     */
    function get(HashMapping storage self, uint64 _idx)
        internal
        view
        returns (bytes32)
    {
        return self.itHashMap[_idx];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/** @title Library functions used by contracts within this ecosystem.*/
library Uint64ArrayUtil {
    function removeByIndex(uint64[] storage self, uint64 index) internal {
        if (index >= self.length) return;

        for (uint64 i = index; i < self.length - 1; ) {
            unchecked {
                self[i] = self[++i];
            }
        }
        self.pop();
    }

    /// @dev the value for each item in the array must be unique
    function removeByValue(uint64[] storage self, uint64 val) internal {
        if (self.length == 0) return;
        uint64 j;
        for (uint64 i; i < self.length - 1; ) {
            unchecked {
                if (self[i] == val) {
                    j = i + 1;
                }
                self[i] = self[j];
                ++j;
                ++i;
            }
        }
        self.pop();
    }

    /// @dev add new item into the array
    function add(uint64[] storage self, uint64 val) internal {
        self.push(val);
    }
}