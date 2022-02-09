// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WebacyProxy.sol";
import "./interfaces/IWebacyProxyFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./WebacyBusiness.sol";

contract WebacyProxyFactory is IWebacyProxyFactory, AccessControl {
    uint8 public version;
    WebacyBusiness public webacyBusiness;
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(address => WebacyProxy) memberToContract;

    constructor(uint8 _version) {
        version = _version;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EXECUTOR_ROLE, address(0));
    }

    function createProxyContract(address _memberAddress) external override {
        require(!(address(webacyBusiness) == address(0)), "WebacyBusiness needs to be set");
        WebacyProxy webacyProxy = new WebacyProxy(_memberAddress, address(webacyBusiness));
        memberToContract[_memberAddress] = webacyProxy;
    }

    function deployedContractFromMember(address _memberAddress) external view override returns (WebacyProxy) {
        return memberToContract[_memberAddress];
    }

    function updateWebacyAddress(address _webacyAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(EXECUTOR_ROLE, address(webacyBusiness));
        grantRole(EXECUTOR_ROLE, _webacyAddress);
        webacyBusiness = WebacyBusiness(_webacyAddress);
    }

    // For testing only
    function removeProxy(address _address) external override {
        delete memberToContract[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract WebacyProxy is AccessControl {
    bool public isUnlock = true;
    address public webacyAddress;
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    constructor(address _memberAddress, address _webacyAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _memberAddress);
        _setupRole(EXECUTOR_ROLE, _memberAddress);
        _setupRole(EXECUTOR_ROLE, _webacyAddress);
        webacyAddress = _webacyAddress;
    }

    modifier onlyWhenUnlocked {
        require(isUnlock, "Contract is blocked");
        _;
    }

    function transferERC20TokensAllowed(address _contractAddress, address _ownerAddress, address _recipentAddress, uint256 _amount) external onlyRole(EXECUTOR_ROLE) onlyWhenUnlocked {
        IERC20(_contractAddress).transferFrom(_ownerAddress, _recipentAddress, _amount);
    }

    function transferERC721TokensAllowed(address _contractAddress, address _ownerAddress, address _recipentAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) onlyWhenUnlocked {
        IERC721(_contractAddress).safeTransferFrom(_ownerAddress, _recipentAddress, _tokenId);
    }

    function updateExecutorRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) onlyWhenUnlocked {
        revokeRole(EXECUTOR_ROLE, webacyAddress);
        grantRole(EXECUTOR_ROLE, _address);
        webacyAddress = _address;
    }

    function lockContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isUnlock = false;
    }

    function unlockContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isUnlock = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../WebacyProxy.sol";

interface IWebacyProxyFactory {
    function createProxyContract(address _memberAddress) external;

    function deployedContractFromMember(address _memberAddress) external view returns (WebacyProxy);

    function updateWebacyAddress(address _webacyAddress) external;

    // For testing only
    function removeProxy(address _address) external;
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./WebacyProxyFactory.sol";
import "./interfaces/IWebacy.sol";

contract WebacyBusiness is AccessControl {
    uint8 public version;
    WebacyProxyFactory public proxyFactory;

    constructor(uint8 _version) {
        version = _version;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct BackupWallet {
        address bpAddress;
        string bpAlias;
    }

    struct AssetBeneficiary {
        address desAddress;
        string desAlias;
        uint8 tokenId;
    }

    struct TokenBeneficiary {
        address desAddress;
        string desAlias;
        uint8 percent;
    }

    struct TokenStatus {
        address newOwner;
        uint256 amountTransferred;
        bool status;
    }
    struct AssetStatus {
        address newOwner;
        uint256 tokenIdTransferred;
        bool status;
    }

    //* Asset Beneficiary section
    mapping(address => uint256) private beneficiaryToERC721SCVersion; //set
    mapping(address => uint256) private _memberToERC721SCVersion;
    mapping(address => mapping(uint256 => address[])) private _memberToVersionToERC721Contracts;
    mapping(address => mapping(uint256 => mapping(address => AssetBeneficiary[])))
        private _memberToVersionToContractToAssetBeneficiary;

    mapping(address => mapping(address => mapping(uint256 => address)))
        private assetBeneficiaryToContractToVersionToMember;

    //Asset transfer
    mapping(address => mapping(uint256 => mapping(address => AssetStatus[])))
        private memberToVersionToContractToAssetStatus;

    //Asset Beneficiary section *

    //* Token Beneficiary section
    mapping(address => uint256) private beneficiaryToERC20SCVersion;
    mapping(address => uint256) private _memberToERC20SCVersion;
    mapping(address => mapping(uint256 => address[])) private _memberToVersionToERC20Contracts;
    mapping(address => mapping(uint256 => mapping(address => TokenBeneficiary[])))
        private _memberToVersionToContractToTokenBeneficiary;
    mapping(address => mapping(address => mapping(uint256 => address)))
        private tokenBeneficiaryToContractToVersionToMember;
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private _memberToVersionToContractToAllowableAmount;

    //Token transfer
    mapping(address => mapping(uint256 => mapping(address => TokenStatus)))
        private memberToVersionToContractToTokenStatus;
    //Token Beneficiary section *

    //* Backup data strucutre section
    mapping(address => uint256) private backupWalletToMemberVersion;
    mapping(address => uint256) private _memberToBackupWalletsVersion;
    mapping(address => mapping(uint256 => BackupWallet[])) private _memberToVersionToBackupWallets;
    mapping(address => mapping(uint256 => address)) private backupWalletToVersionToMember;

    //Backup data strucutre section *

    function getMemberFromBackup() external view returns (address) {
        uint256 backupWalletsVersion = backupWalletToMemberVersion[msg.sender];
        return backupWalletToVersionToMember[msg.sender][backupWalletsVersion];
    }

    function aprovedERC20Tokens(
        address contractAddress,
        address[] memory destinationAddresses,
        string[] memory destinationAliases,
        uint8[] memory destinationPercents,
        uint256 amount,
        address[] memory backupAddresses,
        string[] memory backupAliases
    ) external {
        _checkERC20EquallySizeLength(destinationAddresses, destinationAliases, destinationPercents);

        _saveBackupWallet(backupAddresses, backupAliases);

        uint256 ERC20Version = _memberToERC20SCVersion[msg.sender];

        // enable to force smart contract unicity per member
        _validateERC20SCNotExists(ERC20Version, contractAddress);

        _memberToVersionToERC20Contracts[msg.sender][ERC20Version].push(contractAddress);
        _memberToVersionToContractToAllowableAmount[msg.sender][ERC20Version][contractAddress] = amount;

        for (uint256 i = 0; i < destinationAddresses.length; i++) {
            require(
                destinationPercents[i] >= uint8(0) && destinationPercents[i] <= 100,
                "Percent values must be between 0 and 100"
            );
            TokenBeneficiary memory tokenB;
            tokenB.desAddress = destinationAddresses[i];
            tokenB.desAlias = destinationAliases[i];
            tokenB.percent = destinationPercents[i];

            _validateTokenBeneficiaryNotExists(tokenB.desAddress, contractAddress, ERC20Version);
            tokenBeneficiaryToContractToVersionToMember[tokenB.desAddress][contractAddress][ERC20Version] = msg.sender;

            _memberToVersionToContractToTokenBeneficiary[msg.sender][ERC20Version][contractAddress].push(tokenB);
        }
    }

    function aprovedERC721Tokens(
        address contractAddress,
        address[] memory destinationAddresses,
        string[] memory destinationAlias,
        uint8[] memory destinationTokenIds,
        address[] memory backupAddresses,
        string[] memory backupAliases
    ) external {
        _checkERC721EquallySizeLength(destinationAddresses, destinationAlias, destinationTokenIds);

        _saveBackupWallet(backupAddresses, backupAliases);

        uint256 ERC721SCVersion = _memberToERC721SCVersion[msg.sender];

        // enable to force smart contract unicity per member
        _validateERC721SCNotExists(ERC721SCVersion, contractAddress);

        _memberToVersionToERC721Contracts[msg.sender][ERC721SCVersion].push(contractAddress);

        for (uint256 i = 0; i < destinationAddresses.length; i++) {
            //TODO validate tokenId exist and the tokenOwner
            AssetBeneficiary memory assetB;
            assetB.desAddress = destinationAddresses[i];
            assetB.desAlias = destinationAlias[i];
            assetB.tokenId = destinationTokenIds[i];
            _validateAssetBeneficiaryNotExists(assetB.desAddress, contractAddress, ERC721SCVersion);
            _memberToVersionToContractToAssetBeneficiary[msg.sender][ERC721SCVersion][contractAddress].push(assetB);
            assetBeneficiaryToContractToVersionToMember[destinationAddresses[i]][contractAddress][ERC721SCVersion] = msg
                .sender;
        }
    }

    struct ERC20 {
        address scAddress;
        TokenBeneficiary[] tokenBeneficiaries;
        uint256 amount;
    }

    struct ERC721 {
        address scAddress;
        AssetBeneficiary[] assetBeneficiaries;
    }

    struct TransferredERC20 {
        address scAddress;
        address newOwner;
        uint256 amountTransferred;
        bool status;
    }
    struct TransferredERC721 {
        address scAddress;
        AssetStatus[] assetsStatus;
    }

    struct Assets {
        ERC721[] erc721;
        BackupWallet[] backupWallets;
        ERC20[] erc20;
        TransferredERC20[] transferredErc20;
        TransferredERC721[] transferredErc721;
    }

    function getApprovedAssets(address owner) public view returns (Assets memory) {
        // INIT ERC20Contracts
        uint256 ERC20SCVersion = _memberToERC20SCVersion[owner];
        address[] memory ERC20Contracts = _memberToVersionToERC20Contracts[owner][ERC20SCVersion];
        // END ERC20Contracts

        // INIT BackupWallets
        uint256 BackupWalletsVersion = _memberToBackupWalletsVersion[owner];
        BackupWallet[] memory backupWallets = _memberToVersionToBackupWallets[owner][BackupWalletsVersion];
        // END BackupWallets

        // INIT ERC721Contracts
        uint256 ERC721SCVersion = _memberToERC721SCVersion[owner];
        address[] memory ERC721Contracts = _memberToVersionToERC721Contracts[owner][ERC721SCVersion];
        // END ERC721Contracts

        Assets memory assets = Assets(
            new ERC721[](ERC721Contracts.length),
            new BackupWallet[](backupWallets.length),
            new ERC20[](ERC20Contracts.length),
            new TransferredERC20[](ERC20Contracts.length),
            new TransferredERC721[](ERC721Contracts.length)
        );

        // INIT FULLFILL ERC721 BENEFICIARIES
        for (uint256 i = 0; i < ERC721Contracts.length; i++) {
            AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[owner][
                ERC721SCVersion
            ][ERC721Contracts[i]];
            assets.erc721[i].assetBeneficiaries = assetBeneficiaries;
            assets.erc721[i].scAddress = ERC721Contracts[i];

            AssetStatus[] memory assetsStatus = memberToVersionToContractToAssetStatus[owner][ERC721SCVersion][
                ERC721Contracts[i]
            ];
            assets.transferredErc721[i].scAddress = ERC721Contracts[i];
            assets.transferredErc721[i].assetsStatus = assetsStatus;
        }
        // END FULLFILL ERC721 BENEFICIARIES

        // INIT FULLFILL BACKUPWALLETS
        for (uint256 i = 0; i < backupWallets.length; i++) {
            assets.backupWallets[i].bpAddress = backupWallets[i].bpAddress;
            assets.backupWallets[i].bpAlias = backupWallets[i].bpAlias;
        }
        // END FULLFILL BACKUPWALLETS

        for (uint256 i = 0; i < ERC20Contracts.length; i++) {
            //FULLFILL ERC20 BENEFICIARIES
            TokenBeneficiary[] memory tokenBeneficiaries = _memberToVersionToContractToTokenBeneficiary[owner][
                ERC20SCVersion
            ][ERC20Contracts[i]];
            assets.erc20[i].tokenBeneficiaries = tokenBeneficiaries;
            assets.erc20[i].scAddress = ERC20Contracts[i];
            assets.erc20[i].amount = _memberToVersionToContractToAllowableAmount[owner][ERC20SCVersion][
                ERC20Contracts[i]
            ];
            //FULLFILL TRANSFERRED ERC20
            TokenStatus memory tokenStatus = memberToVersionToContractToTokenStatus[owner][ERC20SCVersion][
                ERC20Contracts[i]
            ];
            if (!(tokenStatus.newOwner == address(0))) {
                assets.transferredErc20[i].scAddress = ERC20Contracts[i];
                assets.transferredErc20[i].newOwner = tokenStatus.newOwner;
                assets.transferredErc20[i].amountTransferred = tokenStatus.amountTransferred;
                assets.transferredErc20[i].status = tokenStatus.status;
            }
        }
        // END FULLFILL ERC20 BENEFICIARIES

        return assets;
    }

    //In order to aviod deletion, this version will be updated if a new stored version of the different assets, beneficiaries and backups must be created
    function updateStoredAssetsVersion(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 memberToERC721SCVersion = _memberToERC721SCVersion[_address];
        uint256 memberToBackupWalletsVersion = _memberToBackupWalletsVersion[_address];
        uint256 memberToERC20SCVersion = _memberToERC20SCVersion[_address];

        //UPDATING DIRECT RELATION
        _memberToERC721SCVersion[_address] = memberToERC721SCVersion + 1;
        _memberToBackupWalletsVersion[_address] = memberToBackupWalletsVersion + 1;
        _memberToERC20SCVersion[_address] = memberToERC20SCVersion + 1;
        //TODO update beneficiaries and backups versions in order to have inverse relation

        //UPDATING INVERSE RELATION VERSION
        BackupWallet[] memory backupWallets = _memberToVersionToBackupWallets[_address][memberToBackupWalletsVersion];
        for (uint256 i = 0; i < backupWallets.length; i++) {
            backupWalletToMemberVersion[backupWallets[i].bpAddress] = memberToBackupWalletsVersion + 1;
        }
    }

    function updateBackupWalletsVersion(address _address) private {
        //This or just sending one time backupwallets from frontend
        uint256 memberToBackupWalletsVersion = _memberToBackupWalletsVersion[_address];
        _memberToBackupWalletsVersion[_address] = memberToBackupWalletsVersion + 1;
        //UPDATING INVERSE RELATION VERSION
        BackupWallet[] memory backupWallets = _memberToVersionToBackupWallets[_address][memberToBackupWalletsVersion];
        for (uint256 i = 0; i < backupWallets.length; i++) {
            backupWalletToMemberVersion[backupWallets[i].bpAddress] = memberToBackupWalletsVersion + 1;
        }
    }

    function _checkERC721EquallySizeLength(
        address[] memory destinationAddresses,
        string[] memory destinationAlias,
        uint8[] memory destinationTokenIds
    ) internal pure {
        require(
            destinationAddresses.length == destinationAlias.length &&
                destinationAlias.length == destinationTokenIds.length,
            "Equally size arrays required"
        );
    }

    function _checkERC20EquallySizeLength(
        address[] memory destinationAddresses,
        string[] memory destinationAliases,
        uint8[] memory destinationPercents
    ) internal pure {
        require(
            destinationAddresses.length == destinationAliases.length &&
                destinationAliases.length == destinationPercents.length,
            "Equally size arrays required"
        );
    }

    function _saveBackupWallet(address[] memory backupAddresses, string[] memory backupAliases) private {
        if (backupAddresses.length == 0) {
            return;
        }

        require(backupAddresses.length == backupAliases.length, "Equally size arrays required");

        uint256 backupWalletsVersion = _memberToBackupWalletsVersion[msg.sender];

        // uncomment to force smart contract to fail transaction when backupwallets want to be set more than once
        // require(
        //     _memberToVersionToBackupWallets[msg.sender][backupWalletsVersion].length == 0,
        //     "Backupwallets already been set"
        // );

        if (!(_memberToVersionToBackupWallets[msg.sender][backupWalletsVersion].length == 0)) {
            updateBackupWalletsVersion(msg.sender);
        }

        if (_memberToVersionToBackupWallets[msg.sender][backupWalletsVersion].length == 0) {
            for (uint256 i = 0; i < backupAddresses.length; i++) {
                BackupWallet memory backupwallet = BackupWallet(backupAddresses[i], backupAliases[i]);
                _validateBackupNotExists(backupAddresses[i], backupWalletsVersion);
                uint256 memberVersion = backupWalletToMemberVersion[backupAddresses[i]];
                backupWalletToVersionToMember[backupAddresses[i]][memberVersion] = msg.sender;
                _memberToVersionToBackupWallets[msg.sender][backupWalletsVersion].push(backupwallet);
            }
        }
    }

    function _validateERC721SCNotExists(uint256 ERC721SCVersion, address contractAddress) internal view {
        AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[msg.sender][
            ERC721SCVersion
        ][contractAddress];

        //TODO CHECK ALSO desAddress and tokenId
        require(assetBeneficiaries.length == 0, "Contract address already exists");
    }

    function _validateERC20SCNotExists(uint256 ERC20SCVersion, address contractAddress) internal view {
        TokenBeneficiary[] memory tokenBeneficiaries = _memberToVersionToContractToTokenBeneficiary[msg.sender][
            ERC20SCVersion
        ][contractAddress];

        //TODO CHECK ALSO desAddress and tokenId
        require(tokenBeneficiaries.length == 0, "Contract address already exists");
    }

    function _validateAssetBeneficiaryNotExists(
        address _destinationAddress,
        address _contractAddress,
        uint256 _contractVersion
    ) internal view {
        require(
            assetBeneficiaryToContractToVersionToMember[_destinationAddress][_contractAddress][_contractVersion] ==
                address(0),
            "Beneficiary address already exists"
        );
    }

    function _validateTokenBeneficiaryNotExists(
        address _destinationAddress,
        address _contractAddress,
        uint256 _contractVersion
    ) internal view {
        require(
            tokenBeneficiaryToContractToVersionToMember[_destinationAddress][_contractAddress][_contractVersion] ==
                address(0),
            "Beneficiary address already exists"
        );
    }

    function _validateBackupNotExists(address _backupAddress, uint256 _contractVersion) internal view {
        require(
            backupWalletToVersionToMember[_backupAddress][_contractVersion] == address(0),
            "Backup address already exists"
        );
    }

    function _validateERC20SCExists(
        uint256 _erc20SCVersion,
        address _contractAddress,
        address _owner
    ) internal view {
        TokenBeneficiary[] memory tokenBeneficiaries = _memberToVersionToContractToTokenBeneficiary[_owner][
            _erc20SCVersion
        ][_contractAddress];
        require(tokenBeneficiaries.length > 0, "ERC20 address not exists");
    }

    function _validateERC721SCExists(
        uint256 _erc721SCVersion,
        address _contractAddress,
        address _owner
    ) internal view {
        AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[_owner][
            _erc721SCVersion
        ][_contractAddress];
        require(assetBeneficiaries.length > 0, "ERC721 address not exists");
    }

    function _validateERC721CollectibleExists(
        uint256 _erc721SCVersion,
        address _contractAddress,
        address _owner,
        uint8 _tokenId
    ) internal view {
        AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[_owner][
            _erc721SCVersion
        ][_contractAddress];
        bool exists = false;
        for (uint256 i = 0; i < assetBeneficiaries.length; i++) {
            if (assetBeneficiaries[i].tokenId == _tokenId) {
                exists = true;
                // TODO: break for cycle to optimize
            }
        }
        require(exists == true, "ERC721 tokenId not exists");
    }

    /**
     * @dev Transfers ERC20 and ERC721 tokens approved.
     * If _erc20contracts is empty it will transfer all approved ERC20 assets.
     * If _erc721contracts is empty it will transfer all approved ERC721 assets.
     *
     * Requirements:
     *
     * - `sender` must be a stored backup of some member.
     * - `_erc20contracts` must contain stored ERC20 contract addresses.
     * - `_erc721contracts` must contain stored ERC721 contract addresses.
     * - `_erc721tokensId` must be same length of `_erc721contracts`.
     */
    function transferAssets(
        address[] memory _erc20contracts,
        address[] memory _erc721contracts,
        uint8[][] memory _erc721tokensId
    ) external {
        require(
            !(backupWalletToVersionToMember[msg.sender][backupWalletToMemberVersion[msg.sender]] == address(0)),
            "Associated member not found"
        );

        address member = backupWalletToVersionToMember[msg.sender][backupWalletToMemberVersion[msg.sender]];

        // Iterate over erc20 and erc721 assets
        uint256 erc20SCVersion = _memberToERC20SCVersion[member];
        address[] memory erc20Contracts = _memberToVersionToERC20Contracts[member][erc20SCVersion];

        uint256 erc721SCVersion = _memberToERC721SCVersion[member];
        address[] memory erc721Contracts = _memberToVersionToERC721Contracts[member][erc721SCVersion];

        address webacyProxyForMember = address(proxyFactory.deployedContractFromMember(member));

        if (_erc20contracts.length != 0) {
            // Partial transfer
            for (uint256 i = 0; i < _erc20contracts.length; i++) {
                _validateERC20SCExists(erc20SCVersion, _erc20contracts[i], member);
                uint256 amount = _memberToVersionToContractToAllowableAmount[member][erc20SCVersion][
                    _erc20contracts[i]
                ];
                WebacyProxy(webacyProxyForMember).transferERC20TokensAllowed(
                    _erc20contracts[i],
                    member,
                    msg.sender,
                    amount
                );
                memberToVersionToContractToTokenStatus[member][erc20SCVersion][_erc20contracts[i]] = TokenStatus(
                    msg.sender,
                    amount,
                    true
                );
            }
        } else {
            // Total transfer
            for (uint256 i = 0; i < erc20Contracts.length; i++) {
                uint256 amount = _memberToVersionToContractToAllowableAmount[member][erc20SCVersion][erc20Contracts[i]];
                WebacyProxy(webacyProxyForMember).transferERC20TokensAllowed(
                    erc20Contracts[i],
                    member,
                    msg.sender,
                    amount
                );
                memberToVersionToContractToTokenStatus[member][erc20SCVersion][_erc20contracts[i]] = TokenStatus(
                    msg.sender,
                    amount,
                    true
                );
            }
        }

        if (_erc721contracts.length != 0) {
            require(_erc721contracts.length == _erc721tokensId.length, "ERC721 equally arrays required");
            // Partial transfer
            for (uint256 iContracts = 0; iContracts < _erc721contracts.length; iContracts++) {
                _validateERC721SCExists(erc721SCVersion, _erc721contracts[iContracts], member);
                AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[member][
                    erc721SCVersion
                ][_erc721contracts[iContracts]];
                for (uint256 iAssets = 0; iAssets < assetBeneficiaries.length; iAssets++) {
                    for (uint256 iTokensId = 0; iTokensId < _erc721tokensId[iContracts].length; iTokensId++) {
                        _validateERC721CollectibleExists(
                            erc721SCVersion,
                            _erc721contracts[iContracts],
                            member,
                            _erc721tokensId[iContracts][iTokensId]
                        );
                        WebacyProxy(webacyProxyForMember).transferERC721TokensAllowed(
                            _erc721contracts[iContracts],
                            member,
                            msg.sender,
                            assetBeneficiaries[iAssets].tokenId
                        );
                        memberToVersionToContractToAssetStatus[member][erc721SCVersion][_erc721contracts[iContracts]]
                            .push(AssetStatus(msg.sender, assetBeneficiaries[iAssets].tokenId, true));
                    }
                }
            }
        } else {
            // Total transfer
            for (uint256 iContracts = 0; iContracts < erc721Contracts.length; iContracts++) {
                AssetBeneficiary[] memory assetBeneficiaries = _memberToVersionToContractToAssetBeneficiary[member][
                    erc721SCVersion
                ][erc721Contracts[iContracts]];
                for (uint256 iAssets = 0; iAssets < assetBeneficiaries.length; iAssets++) {
                    WebacyProxy(webacyProxyForMember).transferERC721TokensAllowed(
                        erc721Contracts[iContracts],
                        member,
                        msg.sender,
                        assetBeneficiaries[iAssets].tokenId
                    );
                    memberToVersionToContractToAssetStatus[member][erc721SCVersion][_erc721contracts[iContracts]].push(
                        AssetStatus(msg.sender, assetBeneficiaries[iAssets].tokenId, true)
                    );
                }
            }
        }
    }

    function setProxyFactory(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proxyFactory = WebacyProxyFactory(_address);
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWebacy {

  function subscribeNewAddress(address _account) external;

  function transferERC20TokensAllowed(address contractAddress, address ownerAddress, address recipentAddress, uint256 amount) external;

  function transferERC721TokensAllowed(address contractAddress, address ownerAddress, address recipentAddress, uint256 tokenId) external;

}