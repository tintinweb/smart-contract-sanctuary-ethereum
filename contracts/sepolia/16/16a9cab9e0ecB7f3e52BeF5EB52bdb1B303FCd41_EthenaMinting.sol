pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/IeUSD.sol";
import "./interfaces/IEthenaMinting.sol";


/// @title EthenaMinting
/// @notice Ethena minting is a contract that allows users to mint and redeem eUSD stablecoin in exchange for supported assets.
/// @notice The contract follows a two phase commit protocol to ensure that the minting and redemption of eUSD is handled correctly and system stability is maintained.
/// @notice The first phase is deposit where users deposit a supported asset into the contract.
/// @notice The second phase is minting phase where users are minted eUSD by a minter role in exchange for the deposited asset.
/// @notice Another two phase pairing is the discharge and withdrawal where users are able to withdraw their deposited asset after a discharge transaction is submitted.
/// @dev EthenaMinting is Ownable, Pausable, ReentrancyGuard and implements the IEthenaMinting interface
contract EthenaMinting is IEthenaMinting, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // @notice eUSD stablecoin
    IeUSD public eUSD;
    // @notice Supported assets
    EnumerableSetUpgradeable.AddressSet internal supportedAssets;

    // @notice holds computable chain id
    uint256 private _chainId;
    // @notice holds computable domain separator
    bytes32 private _domainSeparator;
    // @notice holds EIP712 revision
    uint private constant EIP712_REVISION = 1;

    // @notice EIP712 domain
    string constant public EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    // @notice Mint order type
    string constant public MINT_ORDER_TYPE = "Mint(uint256 depositId,uint256 expiry,address beneficiary,address asset,uint256 amount)";
    // @notice Withdraw order type
    string constant public WITHDRAW_ORDER_TYPE = "Withdraw(uint256 dischargeId,uint256 expiry,address beneficiary,address asset,uint256 amount)";
    // @notice Rollback order type
    string constant public ROLLBACK_ORDER_TYPE = "Rollback(uint256 eventId,uint256 expiry,address beneficiary,address asset,uint256 amount)";

    // @notice EIP712 domain hash
    bytes32 constant public EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

    // @notice roll registry to record addresses that have roles and their status'
    mapping(Role => mapping(address => mapping(address => bool))) private roleRegistry;
    // @notice roll active signer count records the number of active signers for a role
    mapping(Role => mapping(address => uint256)) private roleActiveSignerCount;

    // @notice deposits per address
    mapping(address => mapping(uint256 => Deposit)) public deposits;
    // @notice discharges per address
    mapping(address => mapping(uint256 => Discharge)) public discharges;

    // @notice deposit counter ids per address
    mapping(address => uint256) public depositIds;
    // @notice discharge counter ids per address
    mapping(address => uint256) public dischargeIds;

    // @notice off exchange custody wallets and their status
    mapping(address => bool) public custodyWallets;

    error InvalidAddress();
    error InvalidEUSDAddress();
    error InvalidAssetAddress();
    error InvalidWalletAddress();
    error InvalidAmount();
    error InvalidRole();
    error UnsupportedAsset();
    error UnsupportedCustodyWallet();
    error UnAuthorizedRole();
    error NoAssetsProvided();
    error InvalidSignature();
    error InvalidSignatureLength();
    error SignatureExpired();
    error AlreadyMinted();
    error AlreadyRolled();
    error AlreadyWithdrawn();

    constructor(
        IeUSD _eUSD,
        IERC20[] memory _assets
    ) {
        if(address(_eUSD) == address(0)) revert InvalidEUSDAddress();
        if(_assets.length == 0) revert NoAssetsProvided();
        eUSD = _eUSD;

        for (uint256 i = 0; i < _assets.length; i++) {
            if(address(_assets[i]) == address(0)) revert InvalidAssetAddress();
            supportedAssets.add(address(_assets[i]));
        }

        _chainId = _getChainID();

        emit eUSDSet(address(_eUSD));
    }

    modifier onlyRoleOrOwner(Role role) {
        if(
            !(msg.sender == owner() ||
            (role == Role.Minter && !isMinter(msg.sender)) ||
            (role == Role.Withdrawer && !isWithdrawer(msg.sender)) ||
            (role == Role.Roller && !isRoller(msg.sender)))
        ) revert UnAuthorizedRole();
        _;
    }

    // @notice Compute the current domain separator
    // @return The domain separator for the token
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(_EIP712BaseId())),
                EIP712_REVISION,
                _chainId,
                address(this)
            )
        );
    }

    function _EIP712BaseId() internal pure returns (string memory) {
        return "EthenaMinting";
    }

    // @notice returns the chain id
    function _getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // @notice Get the domain separator for the token
    // @dev Return cached value if chainId matches cache, otherwise recomputes separator
    // @return The domain separator of the token at current chain
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (_getChainID() == _chainId) {
            return _domainSeparator;
        }
        return _computeDomainSeparator();
    }

    // @notice transfer supported asset to depositor address
    function _transferToDepositor(address depositor, address asset, uint256 amount) internal {
        if(!supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20(asset).transfer(depositor, amount);
    }

    // @notice deposit request to mint eUSD, for the beneficiary
    // @param asset the asset to deposited.
    // @param amount the amount of asset to deposited
    // @param beneficiary the beneficiary of the ultimate mint.
    function deposit(address beneficiary, address asset, uint256 amount) nonReentrant public {
        if(amount == 0) revert InvalidAmount();
        if(!supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        deposits[beneficiary][depositIds[beneficiary]] = Deposit({
            minted: false,
            rolled: false,
            beneficiary: beneficiary,
            asset: asset,
            amount: amount
        });
        emit Deposited(depositIds[beneficiary], beneficiary, asset, amount);
        ++depositIds[beneficiary];
    }

    // @notice deposit with permit EIP-2612
    // @param asset address of the asset to deposit
    // @param amount amount of the asset to deposit
    // @param beneficiary address of the beneficiary
    // @param value amount of the asset to deposit
    // @param deadline deadline of the permit
    // @param v,r,s of the permit signature
    function depositWithPermit(
        address asset,
        uint256 amount,
        address beneficiary,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) nonReentrant override public {
        IERC20Permit(asset).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        if(amount == 0) revert InvalidAmount();
        if(!supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        deposits[beneficiary][depositIds[beneficiary]] = Deposit({
            minted: false,
            rolled: false,
            beneficiary: beneficiary,
            asset: asset,
            amount: amount
        });
        emit PermitDeposited(depositIds[beneficiary], msg.sender, asset, amount);
        ++depositIds[beneficiary];
    }

    // @notice discharge request for assets, for the beneficiary
    // @param asset the asset to discharge / to be withdrawn
    // @param amount the amount of asset to discharge / to be withdrawn
    // @param beneficiary the beneficiary of the discharge
    function discharge(address beneficiary, address asset, uint256 amount) nonReentrant public {
        if(amount == 0) revert InvalidAmount();
        if(!supportedAssets.contains(asset)) revert UnsupportedAsset();
        eUSD.burnFrom(msg.sender, amount);
        discharges[beneficiary][dischargeIds[beneficiary]] = Discharge({
            withdrawn: false,
            rolled: false,
            beneficiary: beneficiary,
            asset: asset,
            amount: amount
        });
        emit Discharged(dischargeIds[beneficiary], beneficiary, asset, amount);
        dischargeIds[beneficiary]++;
    }

    // @notice mint eUSD to the beneficiary
    // @param minting the minting struct containing the event details
    // @param sig the signature of the minting struct
    // @dev the signature must be signed by approved account with minter role
    function mint(Mint memory minting, Signature memory sig) nonReentrant onlyRoleOrOwner(Role.Minter) override external {
        verifyMint(minting, sig);
        Deposit storage receipt = deposits[minting.beneficiary][minting.depositId];
        receipt.minted = true;
        eUSD.mint(receipt.beneficiary, minting.amount);
        emit Minted(msg.sender, receipt.beneficiary, minting.asset, minting.amount);
    }

    // @notice withdraw user assets from the contract
    // @param withdrawing the withdrawing struct containing the event details
    // @param sig the signature of the withdrawing struct
    // @dev the signature must be signed by approved account with withdrawer role
    function withdraw(Withdraw memory withdrawing, Signature memory sig) nonReentrant onlyRoleOrOwner(Role.Withdrawer) whenNotPaused override external {
        verifyWithdraw(withdrawing, sig);
        Discharge storage receipt = discharges[withdrawing.beneficiary][withdrawing.dischargeId];
        receipt.withdrawn = true;
        _transferToDepositor(withdrawing.beneficiary, withdrawing.asset, withdrawing.amount);
        emit Withdrawn(msg.sender, withdrawing.beneficiary, withdrawing.asset, withdrawing.amount);
    }

    // @notice rollback a user deposit (mint) or discharge (withdraw) event.
    // @param rolling the rolling struct containing the event details
    // @param rollbackType the type of event to rollback
    // @param sig the signature of the rolling struct
    // @dev the signature must be signed by account with roller role
    function rollback(Rollback memory rolling, RollbackType rollbackType, Signature memory sig) nonReentrant onlyRoleOrOwner(Role.Roller) whenNotPaused override external {
        verifyRollback(rolling, rollbackType, sig);
        if (rollbackType == RollbackType.MINT) {
            Deposit storage receipt = deposits[rolling.beneficiary][rolling.eventId];
            receipt.rolled = true;
            _transferToDepositor(rolling.beneficiary, rolling.asset, rolling.amount);
        } else if (rollbackType == RollbackType.WITHDRAW) {
            Discharge storage receipt = discharges[rolling.beneficiary][rolling.eventId];
            receipt.rolled = true;
            eUSD.mint(receipt.beneficiary, rolling.amount);
        }
        emit RolledBack(msg.sender, rolling.beneficiary, rolling.asset, rolling.amount);
    }

    // @notice hash a mint order
    function hashMint(Mint memory minting) public view override returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        MINT_ORDER_TYPE,
                        minting.depositId,
                        minting.expiry,
                        minting.beneficiary,
                        minting.asset,
                        minting.amount
                    )
                )
            )
        );
    }

    // @notice Hash a withdraw order
    function hashWithdraw(Withdraw memory withdrawing) public view override returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        WITHDRAW_ORDER_TYPE,
                        withdrawing.dischargeId,
                        withdrawing.expiry,
                        withdrawing.beneficiary,
                        withdrawing.asset,
                        withdrawing.amount
                    )
                )
            )
        );
    }

    // @notice Hash a rollback order
    function hashRollback(Rollback memory rolling) public view override returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        ROLLBACK_ORDER_TYPE,
                        rolling.eventId,
                        rolling.expiry,
                        rolling.beneficiary,
                        rolling.asset,
                        rolling.amount
                    )
                )
            )
        );
    }

    // @notice Verify a mint signature
    // @param minting The minting order
    // @param sig The signature
    // @return The hash of the minting order if the signature is valid otherwise revert
    // @dev can be called before submission of mint transaction.
    function verifyMint(Mint memory minting, Signature memory sig) onlyRoleOrOwner(Role.Minter) public view override returns (bytes32) {
        Deposit storage receipt = deposits[minting.beneficiary][minting.depositId];
        bytes32 mintHash = hashMint(minting);
        if(sig.signatureBytes.length != 65) revert InvalidSignatureLength();
        (bytes32 R, bytes32 S, uint8 V) = getRsv(sig.signatureBytes);
        address minter = ecrecover(mintHash, V, R, S);
        if(msg.sender != minter) revert InvalidSignature();
        if(!supportedAssets.contains(minting.asset)) revert UnsupportedAsset();
        if(receipt.minted) revert AlreadyMinted();
        if(receipt.rolled) revert AlreadyRolled();
        if(block.timestamp > minting.expiry) revert SignatureExpired();
        return mintHash;
    }

    // @notice Verify a withdraw signature
    // @param withdrawing The withdraw order
    // @param sig The signature
    // @return The hash of the withdraw order if the signature is valid otherwise revert
    // @dev can be called before submission of withdraw transaction.
    function verifyWithdraw(Withdraw memory withdrawing, Signature memory sig) onlyRoleOrOwner(Role.Withdrawer) public view override returns (bytes32) {
        Discharge storage receipt = discharges[withdrawing.beneficiary][withdrawing.dischargeId];
        bytes32 withdrawHash = hashWithdraw(withdrawing);
        if(sig.signatureBytes.length != 65) revert InvalidSignatureLength();
        (bytes32 R, bytes32 S, uint8 V) = getRsv(sig.signatureBytes);
        address withdrawer = ecrecover(withdrawHash, V, R, S);
        if(msg.sender != withdrawer) revert InvalidSignature();
        if(!supportedAssets.contains(withdrawing.asset)) revert UnsupportedAsset();
        if(receipt.withdrawn) revert AlreadyWithdrawn();
        if(receipt.rolled) revert AlreadyRolled();
        if(block.timestamp > withdrawing.expiry) revert SignatureExpired();
        return withdrawHash;
    }

    // @notice Verify a rollback signature
    // @param rolling The rollback order
    // @param rollbackType The type of rollback
    // @param sig The signature
    // @return The hash of the rollback order if the signature is valid otherwise revert
    // @dev can be called before submission of rollback transaction.
    function verifyRollback(Rollback memory rolling, RollbackType rollbackType, Signature memory sig) onlyRoleOrOwner(Role.Roller) public view override returns (bytes32) {
        bytes32 rollbackHash = hashRollback(rolling);
        if(sig.signatureBytes.length != 65) revert InvalidSignatureLength();
        (bytes32 R, bytes32 S, uint8 V) = getRsv(sig.signatureBytes);
        address roller = ecrecover(rollbackHash, V, R, S);
        if(msg.sender != roller) revert InvalidSignature();
        if (rollbackType == RollbackType.MINT) {
            if(!supportedAssets.contains(rolling.asset)) revert UnsupportedAsset();
            Deposit storage receipt = deposits[rolling.beneficiary][rolling.eventId];
            if(receipt.rolled) revert AlreadyRolled();
            if(receipt.minted) revert AlreadyMinted();
        } else if (rollbackType == RollbackType.WITHDRAW) {
            Discharge storage receipt = discharges[rolling.beneficiary][rolling.eventId];
            if(receipt.rolled) revert AlreadyRolled();
            if(receipt.withdrawn) revert AlreadyWithdrawn();
        }
        if(block.timestamp > rolling.expiry) revert SignatureExpired();
        return rollbackHash;
    }

    // @notice unpacks r, s, v from signature bytes
    function getRsv(bytes memory sig) public pure returns (bytes32, bytes32, uint8) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        return (r, s, v);
    }

    // @notice packs r, s, v into signature bytes
    function packRsv(bytes32 r, bytes32 s, uint8 v) public pure returns (bytes memory) {
        bytes memory sig = new bytes(65);
        assembly {
            mstore(add(sig, 32), r)
            mstore(add(sig, 64), s)
            mstore8(add(sig, 96), v)
        }
        return sig;
    }

    // @notice adds a custody wallet
    function addCustodyWallet(address wallet) nonReentrant onlyOwner whenNotPaused public {
        if(wallet == address(0)) revert InvalidWalletAddress();
        custodyWallets[wallet] = true;
        emit CustodyWalletAdded(wallet);
    }

    // @notice removes a custody wallet
    function removeCustodyWallet(address wallet) public onlyOwner {
        if(wallet == address(0)) revert InvalidWalletAddress();
        if(!custodyWallets[wallet]) revert UnsupportedCustodyWallet();
        custodyWallets[wallet] = false;
        emit CustodyWalletRemoved(wallet);
    }

    // @notice transfers an asset to a custody wallet
    function transferToCustody(address wallet, address asset, uint256 amount) nonReentrant onlyRoleOrOwner(Role.Minter) public {
        if(!custodyWallets[wallet]) revert UnsupportedCustodyWallet();
        if(!supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20(asset).transfer(wallet, amount);
        emit CustodyTransfer(wallet, asset, amount);
    }

    // @notice checks if an address is a minter
    function isMinter(address minter) public view returns (bool) {
        return roleActiveSignerCount[Role.Minter][minter] >= 1;
    }

    // @notice checks if an address is a withdrawer
    function isWithdrawer(address withdrawer) public view returns (bool) {
        return roleActiveSignerCount[Role.Withdrawer][withdrawer] >= 1;
    }

    // @notice checks if an address is a roller
    function isRoller(address roller) public view returns (bool) {
        return roleActiveSignerCount[Role.Roller][roller] >= 1;
    }

    // @notice register full new role for an account
    function registerAllowedRole(Role role, address account, address signer, bool allowed) nonReentrant onlyOwner external override {
        if(account == address(0) || signer == address(0)) revert InvalidAssetAddress();
        roleRegistry[role][account][signer] = allowed;
        roleActiveSignerCount[role][account] += 1;
        emit RoleRegistered(role, msg.sender, account, allowed);
    }

    // @notice Adds a signer to the allowed signers list for senders role.
    function registerAllowedSigner(Role role, address signer, bool allowed) nonReentrant onlyRoleOrOwner(role) external override {
        if(signer == address(0)) revert InvalidAddress();
        roleRegistry[role][msg.sender][signer] = allowed;
        roleActiveSignerCount[role][msg.sender] += 1;
        emit RoleRegistered(role, msg.sender, msg.sender, allowed);
    }

    // @notice Removes a signer from the allowed signers list for senders role.
    function removeRole(Role role, address signer) nonReentrant onlyRoleOrOwner(role) public {
        if(!roleRegistry[role][msg.sender][signer]) revert InvalidRole();
        delete roleRegistry[role][msg.sender][signer];
        roleActiveSignerCount[role][msg.sender] -= 1;
        emit RoleRemoved(role, signer);
    }

    // @notice Adds an asset to the supported assets list.
    function addSupportedAsset(IERC20 _asset) nonReentrant onlyOwner public {
        supportedAssets.add(address(_asset));
    }

    // @notice Removes an asset from the supported assets list.
    function removeSupportedAsset(IERC20 _asset) nonReentrant onlyOwner public {
        supportedAssets.remove(address(_asset));
    }

    // @notice Checks if an asset is supported.
    function isSupportedAsset(IERC20 _asset) public view returns (bool) {
        return supportedAssets.contains(address(_asset));
    }

    // @notice Sets the eUSD contract address.
    function setEUSD(IeUSD _eUSD) external nonReentrant onlyOwner {
        if(address(_eUSD) == address(0)) revert InvalidAddress();
        address oldEUSD = address(eUSD);
        eUSD = _eUSD;
        emit eUSDChanged(oldEUSD, address(eUSD));
    }

    // @notice Pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    // @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IeUSD is IERC20, IERC20Metadata {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../EthenaMinting.sol";


interface IEthenaMinting {

    enum Role {
        Minter,
        Withdrawer,
        Roller
    }

    enum SignatureType {
        EIP712
    }

    enum RollbackType {
        MINT,
        WITHDRAW
    }

    struct Signature {
        SignatureType signatureType;
        bytes signatureBytes;
    }

    struct Deposit {
        bool minted;
        bool rolled;
        address beneficiary;
        address asset;
        uint256 amount;
    }

    struct Discharge {
        bool withdrawn;
        bool rolled;
        address beneficiary;
        address asset;
        uint256 amount;
    }

    struct Mint {
        uint256 depositId;
        uint256 expiry;
        address beneficiary;
        address asset;
        uint256 amount;
    }

    struct Withdraw {
        uint256 dischargeId;
        uint256 expiry;
        address beneficiary;
        address asset;
        uint256 amount;
    }

    struct Rollback {
        uint256 eventId;
        uint256 expiry;
        address beneficiary;
        address asset;
        uint256 amount;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // @notice Event emitted when an asset is deposited
    event Deposited(uint256 indexed depositId, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when an asset is deposited via ERC2612 permit mechanism
    event PermitDeposited(uint256 indexed depositId, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when a stable is discharged
    event Discharged(uint256 indexed dischargeId, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when a deposit is minted
    event Minted(address indexed minter, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when funds are withdrawn
    event Withdrawn(address indexed withdrawer, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when a deposit is rolled back
    event RolledBack(address indexed roller, address indexed beneficiary, address indexed asset, uint256 amount);

    // @notice Event emitted when custody wallet is added
    event CustodyWalletAdded(address wallet);

    // @notice Event emitted when a custody wallet is removed
    event CustodyWalletRemoved(address wallet);

    // @notice Event emitted when assets are moved to custody provider wallet
    event CustodyTransfer(address indexed wallet, address indexed asset, uint256 amount);

    // @notice Event emitted when new role is added
    event RoleRegistered(Role indexed role, address indexed registerer, address indexed account, bool allowed);

    // @notice Event emitted when a role is removed
    event RoleRemoved(Role indexed role, address indexed account);

    // @notice Event emitted when eUSD is set
    event eUSDSet(address indexed eUSD);

    // @notice Event emitted when eUSD is changed
    event eUSDChanged(address indexed oldEUSD, address indexed newEUSD);

    function registerAllowedRole(Role role, address account, address signer, bool allowed) external;

    function registerAllowedSigner(Role role, address signer, bool allowed) external;

    function removeRole(Role role, address account) external;

    function hashMint(Mint memory minting) external view returns (bytes32);

    function hashRollback(Rollback memory rolling) external view returns (bytes32);

    function hashWithdraw(Withdraw memory withdrawing) external view returns (bytes32);

    function verifyMint(
        Mint memory minting,
        Signature memory signature
    ) external view returns (bytes32);

    function verifyRollback(
        Rollback memory rolling,
        RollbackType rollbackType,
        Signature memory signature
    ) external view returns (bytes32);

    function verifyWithdraw(
        Withdraw memory withdrawing,
        Signature memory signature
    ) external view returns (bytes32);

    function deposit(
        address beneficiary,
        address asset,
        uint256 amount
    ) external;

    function depositWithPermit(
        address asset,
        uint256 amount,
        address beneficiary,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(
        Mint memory minting,
        Signature memory signature
    ) external;

    function rollback(
        Rollback memory rolling,
        RollbackType rollbackType,
        Signature memory sig
    ) external;

    function withdraw(
        Withdraw memory withdrawing,
        Signature memory sig
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}