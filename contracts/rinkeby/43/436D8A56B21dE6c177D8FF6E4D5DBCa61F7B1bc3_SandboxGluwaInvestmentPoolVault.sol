// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../GluwaInvestmentPoolVault.sol';

contract SandboxGluwaInvestmentPoolVault is GluwaInvestmentPoolVault {   
    function getTotalNonMaturedBalance() external view returns (uint32) {
        return _totalNonMaturedBalance;
    }
   
    function getBalanceState(bytes32 balanceHash) external view returns (GluwaInvestmentModel.BalanceState) {
        return _getBalanceState(balanceHash);
    }

    function getWithdrawableMatureBalance(bytes32 balanceHash) external view returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import './libs/GluwaInvestmentModel.sol';
import './abstracts/VaultControl.sol';
import './abstracts/GluwaInvestment.sol';

contract GluwaInvestmentPoolVault is VaultControl, GluwaInvestment {
    function initialize(address adminAccount, address token) external initializer {
        _VaultControl_Init(adminAccount);
        _GluwaInvestment_init(token);
    }

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Invest(address indexed recipient, uint256 amount);

    function version() external pure returns (string memory) {
        return '2.0.0';
    }

    function setAccountState(bytes32 accountHash, GluwaInvestmentModel.AccountState state) public onlyController returns (bool) {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        require(account.startingDate > 0, 'GluwaInvestmentPoolVault: Invalid hash');
        account.state = state;
        return true;
    }

    function invest(address recipient, uint256 amount) external onlyOperator returns (bool) {
        require(recipient != address(0), 'GluwaInvestmentPoolVault: Recipient address for investment must be defined');
        require(_token.balanceOf(address(this)) <= amount, 'GluwaInvestmentPoolVault: the investment amount is lower than the contract balance');
        _token.transfer(recipient, amount);
        emit Invest(recipient, amount);
        return true;
    }

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
        (bytes32 accountHash, bytes32 balanceHash) = _createAccount(account, amount, fee, uint64(block.timestamp), identityHash, poolHash);
        return (true, accountHash, balanceHash);
    }

    function createBalance(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 poolHash
    ) external virtual onlyController returns (bool, bytes32) {
        return (true, _createBalance(account, amount, fee, poolHash));
    }

    function withdrawMatureBalanceFor(address account, uint256 fee) external onlyController returns (bool) {
        /// @dev get the withdrawal amount and do the transfer to user's address
        _token.transfer(account, _withdrawMatureBalance(account) - fee);
        return true;
    }

    function withdrawUnstartedBalance(bytes32 balanceHash) external onlyController returns (bool) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        /// @dev we only withdraw the balance which is not closed and its term hasn't started yet
        require(
            _getBalanceState(balanceHash) == GluwaInvestmentModel.BalanceState.Pending && balance.owner == _msgSender(),
            'GluwaInvestmentPoolVault: Unable to withdraw the balance'
        );
        balance.isPrematureClosed = true;
        _token.transfer(balance.owner, balance.principal);       
        emit Withdraw(balance.owner, balance.principal);
        return true;
    }

    function withdrawUnstartedBalanceFor(bytes32 balanceHash, uint256 fee) external onlyController returns (bool) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        /// @dev we only withdraw the balance which is not closed and its term hasn't started yet
        require(
            _getBalanceState(balanceHash) == GluwaInvestmentModel.BalanceState.Pending && balance.principal > fee,
            'GluwaInvestmentPoolVault: Unable to withdraw the balance'
        );
        balance.isPrematureClosed = true;
        _token.transfer(balance.owner, balance.principal - fee);
        emit Withdraw(balance.owner, balance.principal);
        return true;
    }

    function withdrawUnclaimedMatureBalance(
        address account,
        address recipient,
        uint256 fee
    ) external onlyAdmin {
        _token.transfer(recipient, _withdrawMatureBalance(account) - fee);
    }

    function withdrawMatureBalance() external {
        _token.transfer(_msgSender(), _withdrawMatureBalance(_msgSender()));
    }

    function _withdrawMatureBalance(address account) internal override(GluwaInvestment) returns (uint256) {
        uint256 totalWithdrawableAmount = super._withdrawMatureBalance(account);
        require(totalWithdrawableAmount > 0, 'GluwaInvestmentPoolVault: No balance is withdrawable.');
        emit Withdraw(account, totalWithdrawableAmount);
        return totalWithdrawableAmount;
    }

    function withdrawBalancesFor(bytes32[] calldata balanceHash, address ownerAddress, uint256 fee) external onlyController returns (bool) {
        require(_token.transfer(ownerAddress, _withdrawBalances(balanceHash, ownerAddress, fee)), 'GluwaInvestment: Unable to send amount to withdraw balance');
        return true;
    }

    function withdrawBalances(bytes32[] calldata balanceHash) external returns (bool) {
        require(_token.transfer(_msgSender(), _withdrawBalances(balanceHash, _msgSender(), 0)), 'GluwaInvestment: Unable to send amount to withdraw balance');
        return true;
    }

    function _withdrawBalances(bytes32[] calldata balanceHash, address ownerAddress, uint256 fee) internal override(GluwaInvestment) returns (uint256) {
        uint256 totalWithdrawableAmount = super._withdrawBalances(balanceHash, ownerAddress, fee);
        require(totalWithdrawableAmount > 0, 'GluwaInvestmentPoolVault: No balance is withdrawable.');
        emit Withdraw(ownerAddress, totalWithdrawableAmount);
        return totalWithdrawableAmount;
    }

    function createPool(
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint32 interestRate,
        uint64 tenor,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) external onlyOperator returns (bytes32) {
        return _createPool(openDate, closeDate, startDate, interestRate, tenor, minimumRaise, maximumRaise);
    }

    function lockOrUnlockPool(bytes32 poolHash, bool isLocked) external onlyOperator {
        _lockOrUnlockPool(poolHash, isLocked);
    }

    function getUserBalanceList(address account) external view onlyController returns (uint64[] memory) {
        return _getUserBalanceList(account);
    }

    function getBalance(bytes32 balanceHash)
        external
        view
        returns (
            uint256,
            bytes32,
            bytes32,
            address,
            uint32,
            uint32,
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
            balance.yield,
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
            uint256,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        return (account.idx, account.owner, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function getAccountFor(address account)
        external
        view
        onlyController
        returns (
            uint256,
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
        Upcoming,
        /*2*/
        Open,
        /*3*/
        Closed,
        /*4*/
        Mature,
        /*5*/
        Canceled,
        /*6*/
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
        // Index of this Pool
        uint64 idx;
        uint64 openingDate;
        uint64 closingDate;
        uint64 startingDate;
        uint64 tenor;
        uint128 minimumRaise;
        uint256 totalDeposit;
        uint256 maximumRaise;
    }

    struct Account {
        // Different states an account can be in
        AccountState state;
        // Index of this Account
        uint64 idx;
        uint64 startingDate;
        // address of the owner
        address owner;
        uint256 totalDeposit;
        bytes32 securityReferenceHash;
    }

    struct Balance {
        bool isPrematureClosed;
        // Index of this balance
        uint64 idx;
        // address of the owner
        address owner;
        uint256 yield;
        uint256 principal;
        bytes32 accountHash;
        bytes32 poolHash;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

contract VaultControl is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR');
    bytes32 public constant CONTROLLER_ROLE = keccak256('CONTROLLER');

    function _VaultControl_Init(address account) internal onlyInitializing {
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONTROLLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(OPERATOR_ROLE, account);
        _setupRole(CONTROLLER_ROLE, account);
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
        return hasRole(OPERATOR_ROLE, account);
    }

    /// @dev Add an account to the operator role. Restricted to admins.
    function addOperator(address account) public onlyAdmin {
        grantRole(OPERATOR_ROLE, account);
    }

    /// @dev Remove an account from the Operator role. Restricted to admins.
    function removeOperator(address account) public onlyAdmin {
        revokeRole(OPERATOR_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the Controller role.
    function isController(address account) public view returns (bool) {
        return hasRole(CONTROLLER_ROLE, account);
    }

    /// @dev Add an account to the Controller role. Restricted to admins.
    function addController(address account) public onlyAdmin {
        grantRole(CONTROLLER_ROLE, account);
    }

    /// @dev Remove an account from the Controller role. Restricted to Admins.
    function removeController(address account) public onlyAdmin {
        revokeRole(CONTROLLER_ROLE, account);
    }

    /// @dev Remove oneself from the Admin role thus all other roles.
    function renounceAdmin() public {
        address sender = _msgSender();
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
        renounceRole(OPERATOR_ROLE, sender);
        renounceRole(CONTROLLER_ROLE, sender);
    }

    /// @dev Remove oneself from the Operator role.
    function renounceOperator() public {
        renounceRole(OPERATOR_ROLE, _msgSender());
    }

    /// @dev Remove oneself from the Controller role.
    function renounceController() public {
        renounceRole(CONTROLLER_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../test/utils/console.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '../libs/GluwaInvestmentModel.sol';
import '../libs/HashMapIndex.sol';
import '../libs/Uint64ArrayUtil.sol';

contract GluwaInvestment is Initializable, ContextUpgradeable {
    using HashMapIndex for HashMapIndex.HashMapping;
    using Uint64ArrayUtil for uint64[];

    uint32 public constant INTEREST_DENOMINATOR = 100_000_000;

    uint32 internal _totalNonMaturedBalance;

    HashMapIndex.HashMapping private _poolIndex;
    HashMapIndex.HashMapping private _accountIndex;
    HashMapIndex.HashMapping private _balanceIndex;

    /// @dev The total amount users deposit to this contract minus the withdrawn principal
    uint256 internal _currentTotalContractDeposit;

    /// @dev The supported token which can be deposited to an account.
    IERC20Upgradeable internal _token;
    /// @dev The total holding balance is SUM of all principal and yeild of non-matured balance.
    mapping(bytes32 => bool) private _usedIdentityHash;
    mapping(bytes32 => bool) private _poolLocked;
    mapping(address => bytes32) private _addressAccountMapping;
    mapping(address => uint64[]) private _addressNonMatureBalanceMapping;

    mapping(bytes32 => GluwaInvestmentModel.Pool) internal _poolStorage;
    mapping(bytes32 => GluwaInvestmentModel.Account) internal _accountStorage;
    mapping(bytes32 => GluwaInvestmentModel.Balance) internal _balanceStorage;

    event LogPool(bytes32 indexed poolHash);

    event LogAccount(bytes32 indexed accountHash, address indexed owner);

    event LogBalance(bytes32 indexed balanceHash, address indexed owner, uint256 deposit, uint256 fee);

    /**
     * @return the total amount of token put into the contract.
     */
    function getCurrentTotalDeposit() public view returns (uint256) {
        return _currentTotalContractDeposit;
    }

    function _GluwaInvestment_init(address tokenAddress) internal onlyInitializing {
        _token = IERC20Upgradeable(tokenAddress);
        unchecked {
            _accountIndex.firstIdx = 1;
            _accountIndex.nextIdx = 1;
            _accountIndex.count = 0;
            _accountIndex.firstIdx = 1;
            _accountIndex.nextIdx = 1;
            _accountIndex.count = 0;
            _balanceIndex.firstIdx = 1;
            _balanceIndex.nextIdx = 1;
            _balanceIndex.count = 0;
        }
    }

    function _getBalanceState(bytes32 balanceHash) internal view returns (GluwaInvestmentModel.BalanceState) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        unchecked {
            if (balance.yield > 0 || balance.isPrematureClosed) {
                return GluwaInvestmentModel.BalanceState.Closed;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Mature;
            }

            if (pool.startingDate <= block.timestamp && pool.startingDate + pool.tenor > block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Active;
            }
        }
        return GluwaInvestmentModel.BalanceState.Pending;
    }

    function _getPoolState(bytes32 poolHash) internal view returns (GluwaInvestmentModel.PoolState) {
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];
        unchecked {
            if (_poolLocked[poolHash]) {
                return GluwaInvestmentModel.PoolState.Locked;
            }

            if (pool.minimumRaise > pool.totalDeposit && block.timestamp >= pool.startingDate) {
                return GluwaInvestmentModel.PoolState.Canceled;
            }

            if (pool.openingDate > block.timestamp) {
                return GluwaInvestmentModel.PoolState.Upcoming;
            }

            if (pool.startingDate + pool.tenor > block.timestamp && pool.closingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Closed;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Mature;
            }

            /// @dev since pool.closingDate > pool.openingDate, therfore this condition implies currentTime < pool.closingDate
            if (pool.openingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Open;
            }
        }

        return GluwaInvestmentModel.PoolState.Pending;
    }

    function getNonMatureBalanceList() external view returns (GluwaInvestmentModel.Balance[] memory) {
        uint64[] storage balanceIds = _addressNonMatureBalanceMapping[_msgSender()];
        GluwaInvestmentModel.Balance[] memory balanceList = new GluwaInvestmentModel.Balance[](balanceIds.length);
        for (uint256 i; i < balanceIds.length; ) {
            balanceList[i] = _balanceStorage[_balanceIndex.get(balanceIds[i])];
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
        return _addressNonMatureBalanceMapping[account];
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
        return (account.idx, account.owner, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function _createAccount(
        address owner,
        uint256 initialDeposit,
        uint256 fee,
        uint64 startDate,
        bytes32 identityHash,
        bytes32 poolHash
    ) internal returns (bytes32, bytes32) {
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
            account.owner = owner;
            account.startingDate = startDate;
            /// @dev set the account's initial status
            account.state = GluwaInvestmentModel.AccountState.Active;
            account.securityReferenceHash = identityHash;

            _addressAccountMapping[owner] = accountHash;
            _usedIdentityHash[identityHash] = true;
        }
        _accountIndex.add(accountHash);

        bytes32 balanceHash = _createBalance(owner, initialDeposit, fee, poolHash);

        emit LogAccount(accountHash, owner);

        return (accountHash, balanceHash);
    }

    function _createPool(
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint32 interestRate,
        uint64 tenor,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) internal returns (bytes32) {
        require(openDate < closeDate && closeDate < startDate && minimumRaise < maximumRaise, 'GluwaInvestment: Invalid argument value(s)');

        bytes32 poolHash = keccak256(abi.encodePacked(_poolIndex.nextIdx, openDate, closeDate, startDate, interestRate, tenor, minimumRaise, maximumRaise));

        /// @dev Add the pool to the data storage
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];
        unchecked {
            pool.idx = _poolIndex.nextIdx;
            pool.openingDate = openDate;
            pool.closingDate = closeDate;
            pool.startingDate = startDate;
            pool.interestRate = interestRate;
            pool.tenor = tenor;
            pool.minimumRaise = minimumRaise;
            pool.maximumRaise = maximumRaise;
        }
        _poolIndex.add(poolHash);

        emit LogPool(poolHash);

        return poolHash;
    }

    function _lockOrUnlockPool(bytes32 poolHash, bool isLocked) internal {
        _poolLocked[poolHash] = isLocked;
    }

    function _createBalance(
        address owner,
        uint256 deposit,
        uint256 fee,
        bytes32 poolHash
    ) internal returns (bytes32) {
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

        require(
            pool.totalDeposit + deposit <= pool.maximumRaise && _getPoolState(poolHash) == GluwaInvestmentModel.PoolState.Open,
            'GluwaInvestment: the pool does not allow more deposit'
        );

        require(
            deposit > 0,
            'GluwaInvestment: Deposit must be > 0'
        );

        require(_token.transferFrom(owner, address(this), deposit + fee), 'GluwaInvestment: Unable to send amount to create account');

        bytes32 balanceHash = keccak256(abi.encodePacked(_balanceIndex.nextIdx, 'Balance', address(this), owner));

        bytes32 hashOfReferenceAccount = _addressAccountMapping[owner];

        require(
            _accountStorage[hashOfReferenceAccount].state == GluwaInvestmentModel.AccountState.Active,
            "GluwaInvestment: The user's account must be active to get more balance"
        );

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
        _addressNonMatureBalanceMapping[owner].add(_balanceIndex.nextIdx);
        _balanceIndex.add(balanceHash);

        emit LogBalance(balanceHash, owner, deposit, fee);

        return balanceHash;
    }

    function _withdrawMatureBalance(address owner) internal virtual returns (uint256) {
        uint64[] storage allBalance = _addressNonMatureBalanceMapping[owner];
        uint64[] memory maturedList = new uint64[](allBalance.length);
        uint32 j;
        uint256 totalWithdrawalAmount;
        bytes32 balanceHash;
        for (uint256 i; i < allBalance.length; ) {
            balanceHash = _balanceIndex.get(allBalance[i]);
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
            if (_getPoolState(balance.poolHash) == GluwaInvestmentModel.PoolState.Open) {
                _matureBalance(balanceHash, balance);
                unchecked {
                    totalWithdrawalAmount += balance.yield + balance.principal;
                    maturedList[j++] = allBalance[i];
                }
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < maturedList.length; ) {
            if (maturedList[i] > 0) {
                allBalance.removeByValue(maturedList[i]);
            }
            unchecked {
                ++i;
            }
        }
        return totalWithdrawalAmount;
    }

    function _withdrawBalances(bytes32[] calldata balanceHash, address ownerAddress_, uint256 fee) internal virtual returns (uint256 totalWithdrawalAmount) {
        for (uint256 i; i < balanceHash.length; ) {
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash[i]];
            require(balance.owner == ownerAddress_, 'GluwaInvestment: The balance is not owned by the owner');
            unchecked {
                if (_getPoolState(balance.poolHash) != GluwaInvestmentModel.PoolState.Locked) {
                    _matureBalance(balanceHash[i], balance);
                    totalWithdrawalAmount += balance.yield + balance.principal;
                    _accountStorage[balance.accountHash].totalDeposit -= balance.principal;
                }
                ++i;
            }
        }
        totalWithdrawalAmount -= fee;
    }

    function _matureBalance(bytes32 balanceHash, GluwaInvestmentModel.Balance storage balance) internal {
        require(_getBalanceState(balanceHash) == GluwaInvestmentModel.BalanceState.Mature, 'GluwaInvestment: The balance is not matured yet');
        GluwaInvestmentModel.Account storage account = _accountStorage[balance.accountHash];
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];

        require(account.state != GluwaInvestmentModel.AccountState.Locked, "GluwaInvestment: The user's account must not be locked");

        unchecked {
            balance.yield = _calculateYield(pool.tenor, pool.interestRate, INTEREST_DENOMINATOR, balance.principal);

            /// @dev Reduce total deposit for the holding account
            account.totalDeposit -= balance.principal;
        }
    }

    /**
     * @return all the contract's settings;.
     */
    function settings() external view returns (uint32, IERC20Upgradeable) {
        return (INTEREST_DENOMINATOR, _token);
    }

    /// @dev calculate yield for given amount based on term and interest rate.
    function _calculateYield(
        uint64 term,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint256 amount
    ) private pure returns (uint256) {
        return (amount * uint256(interestRate) * uint256(term)) / (uint256(interestRatePercentageBase) * 365 days);
    }

    uint256[50] private __gap;
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
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature('log()'));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(int)', p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint)', p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string)', p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool)', p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address)', p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes)', p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes1)', p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes2)', p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes3)', p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes4)', p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes5)', p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes6)', p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes7)', p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes8)', p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes9)', p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes10)', p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes11)', p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes12)', p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes13)', p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes14)', p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes15)', p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes16)', p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes17)', p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes18)', p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes19)', p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes20)', p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes21)', p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes22)', p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes23)', p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes24)', p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes25)', p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes26)', p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes27)', p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes28)', p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes29)', p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes30)', p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes31)', p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bytes32)', p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint)', p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string)', p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool)', p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address)', p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint)', p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string)', p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool)', p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address)', p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint)', p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string)', p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool)', p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address)', p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint)', p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string)', p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool)', p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address)', p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint)', p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string)', p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool)', p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address)', p0, p1));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,uint)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,string)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,bool)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,address)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,uint)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,string)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,bool)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,address)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,uint)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,string)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,bool)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,address)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,uint)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,string)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,bool)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,address)', p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,uint)', p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,string)', p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,bool)', p0, p1, p2));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,address)', p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,uint)', p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,string)', p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,bool)', p0, p1, p2));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,address)', p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,uint)', p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,string)', p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,bool)', p0, p1, p2));
    }

    function log(
        string memory p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,address)', p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,uint)', p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,string)', p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,bool)', p0, p1, p2));
    }

    function log(
        string memory p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,address)', p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,uint)', p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,string)', p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,bool)', p0, p1, p2));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,address)', p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,uint)', p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,string)', p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,bool)', p0, p1, p2));
    }

    function log(
        bool p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,address)', p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,uint)', p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,string)', p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,bool)', p0, p1, p2));
    }

    function log(
        bool p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,address)', p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,uint)', p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,string)', p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,bool)', p0, p1, p2));
    }

    function log(
        bool p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,address)', p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,uint)', p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,string)', p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,bool)', p0, p1, p2));
    }

    function log(
        address p0,
        uint256 p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,address)', p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,uint)', p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,string)', p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,bool)', p0, p1, p2));
    }

    function log(
        address p0,
        string memory p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,address)', p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,uint)', p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,string)', p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,bool)', p0, p1, p2));
    }

    function log(
        address p0,
        bool p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,address)', p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        uint256 p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,uint)', p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        string memory p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,string)', p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        bool p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,bool)', p0, p1, p2));
    }

    function log(
        address p0,
        address p1,
        address p2
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,address)', p0, p1, p2));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,uint,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,uint,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,string,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,string,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,string,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,string,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,bool,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,bool,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,address,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,address,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,address,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,uint,address,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,uint,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,uint,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,string,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,string,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,string,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,string,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,bool,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,bool,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,address,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,address,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,address,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,string,address,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,uint,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,uint,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,string,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,string,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,string,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,string,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,bool,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,bool,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,address,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,address,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,address,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,bool,address,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,uint,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,uint,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,string,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,string,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,string,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,string,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,bool,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,bool,address)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,address,uint)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,address,string)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,address,bool)', p0, p1, p2, p3));
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(uint,address,address,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,uint,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,uint,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,string,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,string,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,string,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,string,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,bool,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,bool,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,address,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,address,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,address,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,uint,address,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,uint,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,uint,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,string,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,string,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,string,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,string,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,bool,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,bool,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,address,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,address,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,address,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,string,address,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,uint,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,uint,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,string,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,string,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,string,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,string,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,bool,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,bool,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,address,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,address,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,address,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,bool,address,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,uint,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,uint,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,string,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,string,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,string,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,string,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,bool,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,bool,address)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,address,uint)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,address,string)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,address,bool)', p0, p1, p2, p3));
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(string,address,address,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,uint,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,uint,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,string,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,string,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,string,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,string,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,bool,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,bool,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,address,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,address,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,address,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,uint,address,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,uint,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,uint,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,string,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,string,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,string,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,string,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,bool,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,bool,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,address,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,address,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,address,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,string,address,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,uint,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,uint,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,string,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,string,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,string,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,string,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,bool,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,bool,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,address,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,address,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,address,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,bool,address,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,uint,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,uint,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,string,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,string,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,string,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,string,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,bool,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,bool,address)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,address,uint)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,address,string)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,address,bool)', p0, p1, p2, p3));
    }

    function log(
        bool p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(bool,address,address,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,uint,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,uint,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,string,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,string,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,string,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,string,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,bool,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,bool,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,address,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,address,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,address,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,uint,address,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,uint,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,uint,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,string,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,string,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,string,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,string,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,bool,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,bool,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,address,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,address,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,address,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,string,address,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,uint,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,uint,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,string,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,string,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,string,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,string,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,bool,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,bool,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,address,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,address,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,address,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,bool,address,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,uint,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,uint,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,uint,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,uint,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,string,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,string,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,string,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,string,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,bool,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,bool,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,bool,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,bool,address)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,address,uint)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,address,string)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,address,bool)', p0, p1, p2, p3));
    }

    function log(
        address p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(abi.encodeWithSignature('log(address,address,address,address)', p0, p1, p2, p3));
    }
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