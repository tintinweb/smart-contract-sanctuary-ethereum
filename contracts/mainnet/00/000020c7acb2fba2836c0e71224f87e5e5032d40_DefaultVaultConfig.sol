//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { IVaultConfig } from "./interfaces/IVaultConfig.sol";
import { RPVault } from "./RPVault.sol";

contract DefaultVaultConfig is Auth, IVaultConfig {
    bool public _isFeeEnabled = true;
    uint256 public _entryFeeBps = 100;
    uint256 public _exitFeeBps = 100;

    uint256 public minimumStoredValueBeforeFees = 10_000 * 1e6; // 25k USDC
    uint256 public minimumRefiHeld = 1_000_000 * 1e18; // 1 million REFI

    address public refiAddress;
    address public vaultAddress;

    struct UserOverride {
        bool shouldOverrideCanDeposit;
        bool canDeposit;
        bool hasCustomMinimum;
        uint256 customMinimum;
    }
    mapping(address => UserOverride) public userOverrides;

    error VaultNotSetup();

    modifier onlyAfterVaultSetup() {
        if (!isVaultSetup()) {
            revert VaultNotSetup();
        }
        _;
    }

    constructor(
        address _owner,
        address _refiAddress,
        address _vaultAddress
    ) Auth(msg.sender, Authority(address(0))) {
        refiAddress = _refiAddress;
        setVaultAddress(_vaultAddress);

        // transactions from https://etherscan.io/address/0x00000997e18087b2477336fe87b0c486c6a2670d
        setUserOverride(0xad55d623201C26Ac599A4F6898fdD519d98D1070, true);
        setUserOverride(0x00d16F998e1f62fB2a58995dd2042f108eB800d1, true);
        setUserOverride(0x7e849911b62B91eb3623811A42b9820a4a78755b, true);
        setUserOverride(0x82D746d7d53515B22Ad058937EE4D139bA09Ff07, true);
        setUserOverride(0x9F58E312F9efFF3e055e75A154Df8C624D07Cde9, true);
        setUserOverride(0x5189d4978504CfB245D3ed918a6C2629Cac7b0df, true);
        setUserOverride(0xf4d430dD8EaA0412c802fFb450250cC8B6117895, true);
        setUserOverride(0xb6Aa99C580A5203A6C0d7FA40b88d09cb5D65911, true);
        setUserOverride(0x29b7e5E20820ec9A27896AE25f768B8F3B3Bc263, true);

        // new
        setUserOverride(0xf3782301916F56598dDBE5c74C91fd1Aa52B4CC3, true);

        setOwner(_owner);
    }

    ///////////////////////////////////////////////////////////////////////////
    // IVaultConfig ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    function canDeposit(address _user, uint256 _assets) external view onlyAfterVaultSetup returns (bool) {
        if (userOverrides[_user].shouldOverrideCanDeposit) {
            return userOverrides[_user].canDeposit;
        }
        if (userOverrides[_user].hasCustomMinimum) {
            return _assets + getAlreadyStoredValue(_user) >= userOverrides[_user].customMinimum;
        }
        if (isRefiHolder(_user)) {
            return true;
        }
        return _assets + getAlreadyStoredValue(_user) >= minimumStoredValueBeforeFees;
    }

    function isFeeEnabled(address) external view onlyAfterVaultSetup returns (bool) {
        return _isFeeEnabled;
    }

    function entryFeeBps(address) external view onlyAfterVaultSetup returns (uint256) {
        if (vaultAddress != address(0)) {
            return RPVault(vaultAddress).entryFeeBps();
        }
        return _entryFeeBps;
    }

    function exitFeeBps(address) external view onlyAfterVaultSetup returns (uint256) {
        if (vaultAddress != address(0)) {
            return RPVault(vaultAddress).exitFeeBps();
        }
        return _entryFeeBps;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Helpers ////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    function isRefiHolder(address _user) internal view returns (bool) {
        ERC20 refi = ERC20(refiAddress);
        return refi.balanceOf(_user) >= minimumRefiHeld;
    }

    function getAlreadyStoredValue(address _user) internal view returns (uint256) {
        RPVault vault = RPVault(vaultAddress);
        return vault.getStoredValue(_user);
    }

    function isVaultSetup() internal view returns (bool) {
        return vaultAddress != address(0);
    }

    function setVaultAddress(address _vaultAddress) public requiresAuth {
        vaultAddress = _vaultAddress;
    }

    function setMinimumRefiHeld(uint256 _minimumRefiHeld) external requiresAuth {
        minimumRefiHeld = _minimumRefiHeld;
    }

    function setRefiAddress(address _refiAddress) external requiresAuth {
        refiAddress = _refiAddress;
    }

    function setMinimumDeposit(uint256 _assetAmount) external requiresAuth {
        minimumStoredValueBeforeFees = _assetAmount;
    }

    function removeUserOverride(address _user) external requiresAuth {
        userOverrides[_user].shouldOverrideCanDeposit = false;
    }

    function setUserOverride(address _user, bool _canDeposit) public requiresAuth {
        userOverrides[_user].shouldOverrideCanDeposit = true;
        userOverrides[_user].canDeposit = _canDeposit;
    }

    function setUserCustomMinimum(address _user, uint256 _minimum) external requiresAuth {
        userOverrides[_user].hasCustomMinimum = true;
        userOverrides[_user].customMinimum = _minimum;
    }

    function removeUserCustomMinimum(address _user) external requiresAuth {
        userOverrides[_user].hasCustomMinimum = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IVaultConfig {
    function canDeposit(address _user, uint256 _assets) external view returns (bool);

    function isFeeEnabled(address _user) external view returns (bool);

    function entryFeeBps(address _user) external view returns (uint256);

    function exitFeeBps(address _user) external view returns (uint256);

    /// @dev management fee is the same for everyone
    // function managementFeeBps() external view returns (uint256);
}

//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Auth, Authority } from "solmate/auth/Auth.sol";
import { ERC4626Accounting } from "./ERC4626Accounting.sol";
import { IVaultConfig } from "./interfaces/IVaultConfig.sol";

/// @title RPVault
/// @notice epoch-based fund management contract that uses ERC4626 accounting logic.
/// @dev in this version, the contract does not actually use ERC4626 base functions.
/// @dev all vault tokens are stored in-contract, owned by farmer address.
/// @dev all assets are sent to farmer address each epoch change;
/// @dev except for: stored fee, pending withdrawals, & pending deposits.
/// @author mathdroid (https://github.com/mathdroid)
contract RPVault is ERC4626Accounting, Auth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// ██████████████ vault metadata ████████████████████████████████████████

    /// @notice aum = **external** assets under management
    uint256 public aum = 0;
    /// @notice aumCap = maximum aum allowed to be stored in the contract
    uint256 public aumCap = 0;
    /// @notice epoch = period of time where aum is being managed
    uint256 public epoch = 0;
    /// @notice farmer = administrative address, responsible for managing aum
    /// @dev the address where funds will go from/to the contract
    address public immutable farmer;
    /// @notice managementBlocksDuration = number of blocks where farmer can make amendments to the contract
    /// @dev this is to prevent mistakes when progressing epoch
    uint256 public managementBlocksDuration = 6000; // avg block time is 15 seconds, so this is ~24 hours
    /// @notice vault config contract
    address public vaultConfigAddress;

    /// ██████████████ fees ███████████████████████████████████████████████████

    /// @notice isFeeEnabled = flag to enable/disable fees
    bool public isFeeEnabled = false;
    /// @notice feeDistributor = address to receive fees from the contract
    address public feeDistributor;
    /// @notice managementFeeBps = management fee in basis points per second
    /// @dev only charged when delta AUM is positive in an epoch
    /// @dev management fee = (assetsExternalEnd - assetsExternalStart) * managementFeeBps / 1e5
    uint256 public managementFeeBps = 2000;
    /// @notice entry/exit fees are charged when a user enters/exits the contract
    uint256 public entryFeeBps = 100;
    /// @notice entry/exit fees are charged when a user enters/exits the contract
    uint256 public exitFeeBps = 100;
    /// @notice storedFee = the amount of stored fee in the contract
    uint256 public storedFee;
    /// @notice helper for fee calculation
    uint256 private constant BASIS = 10000;

    /// ██████████████ vault state per epoch ██████████████████████████████████
    struct VaultState {
        /// @dev starting AUM this epoch
        uint256 assetsExternalStart;
        /// @dev assets deposited by users during this epoch
        uint256 assetsToDeposit;
        /// @dev shares unlocked during this epoch
        uint256 sharesToRedeem;
        /// @dev the number of external AUM at the end of epoch (after fees)
        uint256 assetsExternalEnd;
        /// @dev management fee captured this epoch. maybe 0 if delta AUM <= 0
        /// @dev managementFee + assetsExternalEnd == aum input by farmer
        uint256 managementFee;
        /// @dev total vault tokens supply
        /// @dev no difference start/end of the epoch
        uint256 totalSupply;
        /// @dev last block number where farmer can edit the aum
        /// @dev only farmer can interact with contract before this blocknumber
        uint256 lastManagementBlock;
    }
    /// @notice vaultState = array of vault states per epoch
    mapping(uint256 => VaultState) public vaultStates;

    /// ██████████████ user balances ██████████████████████████████████████████
    struct VaultUser {
        /// @dev assets currently deposited, not yet included in aum
        /// @dev should be zeroed after epoch change (shares minted)
        uint256 assetsDeposited;
        /// @dev last epoch where user deposited assets
        uint256 epochLastDeposited;
        /// @dev glorified `balanceOf`
        uint256 vaultShares;
        /// @dev shares to be unlocked next epoch
        uint256 sharesToRedeem;
        /// @dev the epoch where user can start withdrawing the unlocked shares
        /// @dev use this epoch's redemption rate (aum/totalSupply) to calculate the amount of assets to be withdrawn
        uint256 epochToRedeem;
    }
    /// @notice vaultUsers = array of user balances per address
    mapping(address => VaultUser) public vaultUsers;

    /// ██████████████ errors █████████████████████████████████████████████████

    /// ░░░░░░░░░░░░░░ internal ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice transaction will result in zero shares given
    error DepositReturnsZeroShares();
    /// @notice transaction will result in zero assets given
    error RedeemReturnsZeroAssets();
    /// ░░░░░░░░░░░░░░ epoch ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice vault is still initializing
    error VaultIsInitializing();
    /// @notice vault has been initialized
    error VaultAlreadyInitialized();

    /// ░░░░░░░░░░░░░░ management phase ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice farmer function called outside management phase
    error OnlyAtManagementPhase();
    /// @notice public function called during management phase
    error OnlyOutsideManagementPhase();

    /// ░░░░░░░░░░░░░░ farmer ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice wrong aum cap value (lower than current aum, etc)
    error AumCapInvalid();
    /// @notice wrong ending aum value (infinite growth)
    error AumInvalid();
    /// @notice farmer asset allowance insufficient
    error FarmerInsufficientAllowance();
    /// @notice farmer asset balance insufficient
    error FarmerInsufficientBalance();

    /// ░░░░░░░░░░░░░░ fee ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice error setting fee config
    error FeeSettingsInvalid();
    /// @notice stored fees = 0;
    error FeeIsZero();

    /// ░░░░░░░░░░░░░░ deposit ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice deposit > aum cap
    error DepositExceedsAumCap();
    /// @notice deposit negated by config contract
    error DepositRequirementsNotMet();
    /// @notice deposit fees larger than sent amount
    error DepositFeeExceedsAssets();
    /// @notice has a pending withdrawal
    error DepositBlockedByWithdrawal();

    /// ░░░░░░░░░░░░░░ unlock ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice has a pending withdrawal already
    error UnlockBlockedByWithdrawal();
    /// @notice invalid amount e.g. 0
    error UnlockSharesAmountInvalid();
    /// @notice
    error UnlockExceedsShareBalance();

    /// ░░░░░░░░░░░░░░ withdraw ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice not the epoch to withdraw
    error WithdrawNotAvailableYet();

    /// ██████████████ events █████████████████████████████████████████████████
    /// @notice user events
    event UserDeposit(address indexed user, uint256 amount);
    event UserUnlock(address indexed user, uint256 amount);
    event UserWithdraw(address indexed user, address withdrawalAddress, uint256 amount);

    /// @notice vault events
    event EpochEnd(uint256 epoch, uint256 endingAssets);
    event EpochUpdated(uint256 epoch, uint256 endingAssets);
    event AumCapUpdated(uint256 aumCap);

    /// @notice fee events
    event StoredFeeSent(uint256 amount);
    event FeeUpdated(bool isFeeEnabled, uint256 entryFee, uint256 exitFee, uint256 managementFee);
    event FeeReceiverUpdated(address feeDistributor);

    /// ██████████████ modifiers ██████████████████████████████████████████████

    /// requiresAuth -> from solmate/Auth

    modifier onlyEpochZero() {
        if (epoch != 0) revert VaultAlreadyInitialized();
        _;
    }

    modifier exceptEpochZero() {
        if (epoch < 1) revert VaultIsInitializing();
        _;
    }

    modifier onlyManagementPhase() {
        if (!isManagementPhase()) {
            revert OnlyAtManagementPhase();
        }
        _;
    }

    modifier exceptManagementPhase() {
        if (isManagementPhase()) {
            revert OnlyOutsideManagementPhase();
        }
        _;
    }

    modifier canDeposit(address _user, uint256 _assets) {
        if (userHasPendingWithdrawal(_user)) {
            revert DepositBlockedByWithdrawal();
        }
        // cap must be higher than current AUM + pending deposit + incoming deposit
        if (_assets + getEffectiveAssets() > aumCap) {
            revert DepositExceedsAumCap();
        }

        if (vaultConfigAddress != address(0) && !IVaultConfig(vaultConfigAddress).canDeposit(_user, _assets)) {
            revert DepositRequirementsNotMet();
        }
        _;
    }

    modifier canUnlock(address _user, uint256 _shares) {
        if (_shares < 1) revert UnlockSharesAmountInvalid();
        if (msg.sender != _user) {
            uint256 allowed = allowance[_user][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[_user][msg.sender] = allowed - _shares;
        }

        if (userHasPendingWithdrawal(_user)) revert UnlockBlockedByWithdrawal();
        _;
    }

    modifier canWithdraw(address _user) {
        if (!userHasPendingWithdrawal(_user)) {
            revert WithdrawNotAvailableYet();
        }
        _;
    }

    modifier updatesPendingDeposit(address _user) {
        updatePendingDepositState(_user);
        _;
    }

    /// ██████████████ ERC4626 ████████████████████████████████████████████████
    /// ░░░░░░░░░░░░░░ constructor ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice create an RPVault
    /// @param _name token name, also used as vault name in the UI, omitting `Token` postfix
    /// @param _symbol token symbol, also used as vault symbol in the UI
    /// @param _farmer farmer address, responsible for managing aum
    /// @param _feeDistributor address to receive fees from the contract
    /// @param _underlying asset to be used as underlying asset for the vault
    /// @param _vaultConfig contract address to be used as vault config contract. if 0x0, default config will be used
    constructor(
        string memory _name,
        string memory _symbol,
        address _farmer,
        address _feeDistributor,
        address _underlying,
        address _vaultConfig
    ) ERC4626Accounting(ERC20(_underlying), _name, _symbol) Auth(_farmer, Authority(address(0))) {
        farmer = _farmer;
        feeDistributor = _feeDistributor;
        vaultConfigAddress = _vaultConfig;
    }

    /// @notice Get the amount of productive underlying tokens
    /// @dev used at self deposits/redeems at epoch change
    /// @return aum, total external productive assets
    function totalAssets() public view override returns (uint256) {
        return aum;
    }

    /// ██████████████ farmer functions ███████████████████████████████████████
    /*
        farmer's actions:
            - [x] starts vault with initial settings
            - [x] progress epoch
            - [x] update aum (management phase only)
            - [x] end management phase (management phase only)
            - [x] update aum cap
            - [x] enable/disable fees
            - [x] update fees
            - [x] update fee distributor
            - [x] update vault config address
    */

    /// @notice starts the vault with a custom initial aum
    /// @dev in most cases, initial aum = 0
    /// @param _initialExternalAsset initial aum, must be held by farmer
    /// @param _aumCap maximum asset that can be stored
    function startVault(uint256 _initialExternalAsset, uint256 _aumCap) external onlyEpochZero requiresAuth {
        if (_aumCap < _initialExternalAsset) {
            revert AumCapInvalid();
        }
        if (_initialExternalAsset != 0) {
            uint256 initialShare = _selfDeposit(_initialExternalAsset);
            vaultUsers[msg.sender].vaultShares = initialShare;
        }
        aumCap = _aumCap;
        epoch = 1;
        vaultStates[epoch].assetsExternalStart = aum;
        vaultStates[epoch].totalSupply = totalSupply;
        vaultStates[epoch].lastManagementBlock = block.number;
        emit EpochEnd(0, aum);
    }

    /// @notice Increment epoch from n to (n + 1)
    /// @dev goes to management phase after this function is called
    /// @param _assetsExternalEndBeforeFees current external asset (manual counting by farmer)
    /// @return newAUM (external asset)
    function progressEpoch(uint256 _assetsExternalEndBeforeFees) public requiresAuth exceptEpochZero returns (uint256) {
        // end epoch n
        (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        ) = previewProgress(_assetsExternalEndBeforeFees, epoch);

        storedFee += managementFee;
        vaultStates[epoch].managementFee = managementFee;

        aum = assetsExternalEnd;
        vaultStates[epoch].assetsExternalEnd = assetsExternalEnd;

        emit EpochEnd(epoch, aum);
        epoch++;

        // start epoch n + 1
        // transfer assets
        if (totalAssetsToTransfer > 0) {
            if (shouldTransferToFarm) {
                // if there are assets to be transferred to the farm, do it
                transferAssetToFarmer(totalAssetsToTransfer);
            } else {
                // transfer back to contract
                // msg.sender is farmer address
                transferAssetToContract(totalAssetsToTransfer);
            }
        }

        // self deposit/redeem delta
        if (deltaAssets > 0) {
            if (shouldDepositDelta) {
                // self-deposit, update aum
                _selfDeposit(deltaAssets);
            } else {
                // self-redeem, update aum
                _selfRedeem(convertToShares(deltaAssets));
            }
        }

        // if new aum is higher than the cap, increase the cap
        if (aum > aumCap) {
            aumCap = aum;
            emit AumCapUpdated(aumCap);
        }

        //  update vault state
        vaultStates[epoch].assetsExternalStart = aum;
        vaultStates[epoch].totalSupply = totalSupply;
        vaultStates[epoch].lastManagementBlock = block.number + managementBlocksDuration;
        return aum;
    }

    /// @notice amends last epoch's aum update
    /// @dev callable at management phase only
    /// @param _assetsExternalEndBeforeFees current external asset (manual counting by farmer)
    /// @return newAUM (external asset)
    // solhint-disable-next-line code-complexity
    function editAUM(uint256 _assetsExternalEndBeforeFees)
        public
        onlyManagementPhase
        requiresAuth
        returns (uint256 newAUM)
    {
        uint256 lastEpoch = epoch - 1;
        uint256 lastAssetsExternalEnd = vaultStates[lastEpoch].assetsExternalEnd;
        uint256 lastManagementFee = vaultStates[lastEpoch].managementFee;
        uint256 lastTotalSupply = vaultStates[lastEpoch].totalSupply;

        if (_assetsExternalEndBeforeFees == lastAssetsExternalEnd + lastManagementFee) {
            // no change in aum
            return lastAssetsExternalEnd;
        }
        (
            bool didTransferToFarm,
            uint256 totalAssetsTransferred, // bool didDepositDelta,
            ,
            ,
            ,

        ) = previewProgress(lastAssetsExternalEnd + lastManagementFee, lastEpoch);

        /// @dev rather than saving gas by combining these into 1 transfers but with overflow handling, we do it in 2
        /// @dev gas is paid by farmer (upkeep)

        // revert transfers
        if (totalAssetsTransferred > 0) {
            if (didTransferToFarm) {
                // revert
                transferAssetToContract(totalAssetsTransferred);
            } else {
                transferAssetToFarmer(totalAssetsTransferred);
            }
        }

        // // revert deposit/redeem using latest rate, update aum automatically
        if (totalSupply > lastTotalSupply) {
            _burn(address(this), totalSupply - lastTotalSupply);
        }

        if (totalSupply < lastTotalSupply) {
            _mint(address(this), lastTotalSupply - totalSupply);
        }

        // /// @dev by this point, aum should be the same as last epoch's aum
        storedFee -= lastManagementFee;
        epoch = lastEpoch;
        return progressEpoch(_assetsExternalEndBeforeFees);
    }

    /// @notice ends management phase, allow users to deposit/unlock/withdraw
    function endManagementPhase() public requiresAuth onlyManagementPhase {
        vaultStates[epoch].lastManagementBlock = block.number;
    }

    /// @notice change AUM cap
    /// @param _aumCap new AUM cap
    function updateAumCap(uint256 _aumCap) public requiresAuth {
        if (aumCap < getEffectiveAssets()) {
            revert AumCapInvalid();
        }
        aumCap = _aumCap;
    }

    /// @notice toggle fees on/off
    /// @param _isFeeEnabled true to enable fees, false to disable fees
    function setIsFeeEnabled(bool _isFeeEnabled) public requiresAuth {
        if (isFeeEnabled == _isFeeEnabled) {
            revert FeeSettingsInvalid();
        }
        isFeeEnabled = _isFeeEnabled;
    }

    /// @notice update fees
    function setFees(
        uint256 _managementFeeBps,
        uint256 _entryFeeBps,
        uint256 _exitFeeBps
    ) public requiresAuth {
        if (_managementFeeBps > BASIS || _entryFeeBps > BASIS || _exitFeeBps > BASIS) {
            revert FeeSettingsInvalid();
        }
        managementFeeBps = _managementFeeBps;
        entryFeeBps = _entryFeeBps;
        exitFeeBps = _exitFeeBps;
    }

    /// @notice update fee distributor
    function setFeeDistributor(address _feeDistributor) public requiresAuth {
        if (_feeDistributor == address(0)) {
            revert FeeSettingsInvalid();
        }
        feeDistributor = _feeDistributor;
    }

    function setVaultConfigAddress(address _vaultConfigAddress) public requiresAuth {
        vaultConfigAddress = _vaultConfigAddress;
    }

    /// ██████████████ user functions █████████████████████████████████████████
    /*
        A user can only do:
            - [x] deposit (not to be confused with ERC4626 deposit)
                - minimum/maximum rule set in the vaultConfig contract
            - [x] unlock
            - [x] withdraw (not to be confused with ERC4626 withdraw)

    */

    /// ░░░░░░░░░░░░░░ deposit ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice a user stores assets in the contract to enter in the next epoch
    /// @dev funds should be withdrawable before epoch progresses
    /// @dev actual share minting happens at the epoch progression
    /// @dev share minting uses next epoch's starting exchange rate
    function deposit(uint256 _assets) external exceptEpochZero exceptManagementPhase returns (uint256) {
        return deposit(_assets, msg.sender);
    }

    function deposit(uint256 _assets, address _for)
        public
        exceptEpochZero
        exceptManagementPhase
        canDeposit(_for, _assets)
        updatesPendingDeposit(_for)
        returns (uint256)
    {
        uint256 depositFee = getDepositFee(_assets, _for);
        if (depositFee >= _assets) {
            revert DepositFeeExceedsAssets();
        }
        uint256 netAssets = _assets - depositFee;

        storedFee += depositFee;

        /// last deposit epoch = 0
        /// assetDeposited = 0

        vaultUsers[_for].epochLastDeposited = epoch;
        vaultUsers[_for].assetsDeposited += netAssets;

        // update vault state
        vaultStates[epoch].assetsToDeposit += netAssets;

        // transfer asset to vault
        asset.safeTransferFrom(msg.sender, address(this), _assets);
        emit UserDeposit(_for, netAssets);
        return netAssets;
    }

    /// ░░░░░░░░░░░░░░ unlock (withdraw 1/2) ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice unlock _shares for withdrawal at next available epoch
    function unlock(uint256 _shares) external exceptEpochZero exceptManagementPhase returns (uint256) {
        return unlock(_shares, msg.sender);
    }

    function unlock(uint256 _shares, address _owner)
        public
        exceptEpochZero
        exceptManagementPhase
        canUnlock(_owner, _shares)
        updatesPendingDeposit(_owner)
        returns (uint256)
    {
        // updatePendingDepositState(msg.sender);

        if (vaultUsers[_owner].vaultShares < vaultUsers[_owner].sharesToRedeem + _shares) {
            revert UnlockExceedsShareBalance();
        }

        vaultUsers[_owner].sharesToRedeem += _shares;
        vaultUsers[_owner].epochToRedeem = epoch + 1;
        vaultStates[epoch].sharesToRedeem += _shares;

        emit UserUnlock(_owner, _shares);
        return _shares;
    }

    /// ░░░░░░░░░░░░░░ finalize (withdraw 2/2) ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    /// @notice withdraw all available asset for user
    function withdraw() external exceptEpochZero exceptManagementPhase returns (uint256) {
        return withdraw(msg.sender);
    }

    function withdraw(address _to)
        public
        exceptEpochZero
        exceptManagementPhase
        canWithdraw(msg.sender)
        updatesPendingDeposit(msg.sender)
        returns (uint256)
    {
        (uint256 totalAssetValue, uint256 withdrawalFee) = getWithdrawalAmount(msg.sender);

        vaultUsers[msg.sender].vaultShares -= vaultUsers[msg.sender].sharesToRedeem;
        vaultUsers[msg.sender].sharesToRedeem = 0;
        vaultUsers[msg.sender].epochToRedeem = 0;
        storedFee += withdrawalFee;

        if (withdrawalFee == totalAssetValue) {
            // @dev for really small values, we can't afford to lose precision
            return 0;
        }

        uint256 transferValue = totalAssetValue - withdrawalFee;
        asset.transfer(_to, transferValue);

        emit UserWithdraw(msg.sender, _to, transferValue);
        return transferValue;
    }

    /// ██████████████ public functions ███████████████████████████████████████
    /*
        public functions:
            - [x] preview funds flow from/to contract next epoch
            - [x] check if user can deposit/unlock/withdraw
            - [x] send stored fees to fee distributor
            - [x] get maximum deposit amount
    */
    /// @notice preview funds flow from/to contract next epoch
    /// @dev assets to transfer = deltaAssets - managementFee
    /// @dev sign shows direction of transfer (true = to farm, false = to contract)
    /// @param _assetsExternalEndBeforeFees amount of external aum before fees
    /// @return shouldTransferToFarm direction of funds to transfer
    /// @return totalAssetsToTransfer amount of assets to transfer
    /// @return shouldDepositDelta true if deltaAssets should be deposited, false if deltaAssets should be redeemed
    /// @return deltaAssets amount of assets to deposit/redeem
    /// @return managementFee amount of management fee for next epoch
    /// @return assetsExternalEnd amount of vault ending aum. assetsExternalEnd = _assetsExternalEndBeforeFees - fees
    function previewProgress(uint256 _assetsExternalEndBeforeFees)
        public
        view
        returns (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        )
    {
        return previewProgress(_assetsExternalEndBeforeFees, epoch);
    }

    function previewProgress(uint256 _assetsExternalEndBeforeFees, uint256 _epoch)
        public
        view
        returns (
            bool shouldTransferToFarm,
            uint256 totalAssetsToTransfer,
            bool shouldDepositDelta,
            uint256 deltaAssets,
            uint256 managementFee,
            uint256 assetsExternalEnd
        )
    {
        uint256 epochTotalSupply = _epoch == epoch ? totalSupply : vaultStates[_epoch].totalSupply;

        uint256 assetsExternalStart = vaultStates[_epoch].assetsExternalStart;
        uint256 assetsToDeposit = vaultStates[_epoch].assetsToDeposit;
        uint256 sharesToRedeem = vaultStates[_epoch].sharesToRedeem;

        if (assetsExternalStart == 0 && _assetsExternalEndBeforeFees > 0) {
            revert AumInvalid();
        }

        managementFee = getManagementFee(assetsExternalStart, _assetsExternalEndBeforeFees);
        assetsExternalEnd = _assetsExternalEndBeforeFees - managementFee;

        /// @dev at 0 supply, rate is 1:1
        uint256 redeemAssetValue = epochTotalSupply == 0
            ? sharesToRedeem
            : sharesToRedeem.mulDivDown(assetsExternalEnd, epochTotalSupply);

        /// @dev if true, the delta (deltaAssets) will be used in selfDeposit.
        /// @dev if false, the delta will be "soft-used" in selfRedeem(shares);

        shouldDepositDelta = assetsToDeposit > redeemAssetValue;
        deltaAssets = shouldDepositDelta ? assetsToDeposit - redeemAssetValue : redeemAssetValue - assetsToDeposit;

        if (shouldDepositDelta) {
            // if deposit is bigger, transfer to farm
            // subtract by management fee
            if (managementFee > deltaAssets) {
                // reverse if fee > delta
                totalAssetsToTransfer = managementFee - deltaAssets;
                shouldTransferToFarm = false;
            } else {
                totalAssetsToTransfer = deltaAssets - managementFee;
                shouldTransferToFarm = true;
            }
        } else {
            // if redeem value is bigger, transfer to contract
            // add management fee
            totalAssetsToTransfer = deltaAssets + managementFee;
            shouldTransferToFarm = false;
        }

        return (
            shouldTransferToFarm,
            totalAssetsToTransfer,
            shouldDepositDelta,
            deltaAssets,
            managementFee,
            assetsExternalEnd
        );
    }

    function isManagementPhase() public view returns (bool) {
        return block.number <= vaultStates[epoch].lastManagementBlock;
    }

    /// @notice sends stored fee to fee distributor
    function sendFee() public exceptManagementPhase {
        if (storedFee == 0) {
            revert FeeIsZero();
        }
        uint256 amount = storedFee;
        storedFee = 0;
        asset.transfer(feeDistributor, amount);
        emit StoredFeeSent(storedFee);
    }

    /// @notice get maximum deposit amount
    function getMaxDeposit() public view returns (uint256) {
        return aumCap - getEffectiveAssets();
    }

    /// @notice preview deposit on epoch
    function previewDepositEpoch(uint256 _assets, uint256 _epoch) public view returns (uint256) {
        if (vaultStates[_epoch].totalSupply == 0 || vaultStates[_epoch].assetsExternalStart == 0) {
            return _assets;
        }
        return _assets.mulDivDown(vaultStates[_epoch].totalSupply, vaultStates[_epoch].assetsExternalStart);
    }

    /// ██████████████ internals ██████████████████████████████████████████████
    // TODO: internalize before deploy
    /// @notice self-deposit, uses ERC4626 calculations, without actual transfer
    /// @dev updates AUM
    /// @param _assets number of assets to deposit
    /// @return shares minted
    function _selfDeposit(uint256 _assets) internal returns (uint256) {
        uint256 shares;
        if ((shares = previewDeposit(_assets)) == 0) revert DepositReturnsZeroShares();

        _mint(address(this), shares);
        aum += _assets;

        emit Deposit(msg.sender, address(this), _assets, shares);

        return shares;
    }

    /// @notice self-redeem, uses ERC4626 calculations, without actual transfer
    /// @dev updates AUM
    /// @param _shares number of shares to redeem
    /// @return assets value of burned shares
    function _selfRedeem(uint256 _shares) internal returns (uint256) {
        uint256 assets;
        // Check for rounding error since we round down in previewRedeem.
        if ((assets = previewRedeem(_shares)) == 0) revert RedeemReturnsZeroAssets();

        _burn(address(this), _shares);
        aum -= assets;

        emit Withdraw(msg.sender, address(this), address(this), assets, _shares);
        return assets;
    }

    /// @notice calculate management fee based on aum change
    /// @param _assetsExternalStart assets at start of epoch
    /// @param _assetsExternalEndBeforeFees assets at end of epoch
    /// @return managementFee management fees in asset
    function getManagementFee(uint256 _assetsExternalStart, uint256 _assetsExternalEndBeforeFees)
        internal
        view
        returns (uint256)
    {
        if (!isFeeEnabled) {
            return 0;
        }
        return
            (_assetsExternalEndBeforeFees > _assetsExternalStart && managementFeeBps > 0)
                ? managementFeeBps.mulDivUp(_assetsExternalEndBeforeFees - _assetsExternalStart, BASIS)
                : 0;
    }

    function transferAssetToFarmer(uint256 _assets) internal returns (bool) {
        return asset.transfer(farmer, _assets);
    }

    function transferAssetToContract(uint256 _assets) internal {
        if (asset.allowance(msg.sender, address(this)) < _assets) {
            revert FarmerInsufficientAllowance();
        }
        if (asset.balanceOf(msg.sender) < _assets) {
            revert FarmerInsufficientBalance();
        }
        return asset.safeTransferFrom(msg.sender, address(this), _assets);
    }

    function getEffectiveAssets() internal view returns (uint256) {
        return aum + vaultStates[epoch].assetsToDeposit;
    }

    /// @notice update VaultUser's data if they have pending deposits
    /// @param _user address of the VaultUser
    /// @dev after this, last deposit epoch = 0, assetDeposited = 0
    /// @dev can be manually called
    function updatePendingDepositState(address _user) public {
        // @dev check if user has already stored assets
        if (userHasPendingDeposit(_user)) {
            // @dev user should already have shares here, let's increment
            vaultUsers[_user].vaultShares += previewDepositEpoch(
                vaultUsers[_user].assetsDeposited,
                vaultUsers[_user].epochLastDeposited + 1
            );

            vaultUsers[_user].assetsDeposited = 0;
            vaultUsers[_user].epochLastDeposited = 0;
        }
    }

    /// @notice check if user has pending deposits
    /// @param _user address of the VaultUser
    /// @return true if user has pending deposits
    function userHasPendingDeposit(address _user) public view returns (bool) {
        uint256 userEpoch = vaultUsers[_user].epochLastDeposited;
        return userEpoch != 0 && epoch > userEpoch;
    }

    /// @notice get deposit fee for user
    function getDepositFee(uint256 _assets, address _user) public view returns (uint256) {
        if (vaultConfigAddress != address(0) && IVaultConfig(vaultConfigAddress).isFeeEnabled(_user)) {
            return _assets.mulDivUp(IVaultConfig(vaultConfigAddress).entryFeeBps(_user), BASIS);
        } else {
            return isFeeEnabled ? _assets.mulDivUp(entryFeeBps, BASIS) : 0;
        }
    }

    /// @notice check if a user has pending, unlocked funds to withdraw
    function userHasPendingWithdrawal(address _user) public view returns (bool) {
        return vaultUsers[_user].epochToRedeem > 0 && vaultUsers[_user].epochToRedeem <= epoch;
    }

    function getStoredValue(address _user) public view returns (uint256 userAssetValue) {
        VaultUser memory user = vaultUsers[_user];

        uint256 userShares = user.vaultShares;

        if (userHasPendingDeposit(_user)) {
            // shares has been minted, user state not yet updated
            userShares += previewDepositEpoch(user.assetsDeposited, user.epochLastDeposited + 1);
        } else {
            // still currently pending (no minted shares yet)
            userAssetValue += user.assetsDeposited;
        }

        userAssetValue += convertToAssets(userShares);
    }

    function getWithdrawalFee(uint256 _assets, address _user) public view returns (uint256) {
        if (vaultConfigAddress != address(0) && IVaultConfig(vaultConfigAddress).isFeeEnabled(_user)) {
            return _assets.mulDivUp(IVaultConfig(vaultConfigAddress).exitFeeBps(_user), BASIS);
        } else {
            return isFeeEnabled ? _assets.mulDivUp(exitFeeBps, BASIS) : 0;
        }
    }

    function getWithdrawalAmount(address _owner) public view returns (uint256, uint256) {
        if (!userHasPendingWithdrawal(_owner)) return (0, 0);
        uint256 epochToRedeem = vaultUsers[_owner].epochToRedeem;
        uint256 sharesToRedeem = vaultUsers[_owner].sharesToRedeem;
        uint256 assetsExternalStart = vaultStates[epochToRedeem].assetsExternalStart;
        uint256 totalSupplyAtRedeem = vaultStates[epochToRedeem].totalSupply;

        if (assetsExternalStart == 0 || totalSupplyAtRedeem == 0) {
            return (0, 0);
        }

        uint256 totalAssetValue = sharesToRedeem.mulDivDown(
            vaultStates[epochToRedeem].assetsExternalStart,
            vaultStates[epochToRedeem].totalSupply
        );
        uint256 fee = getWithdrawalFee(totalAssetValue, _owner);

        return (totalAssetValue, fee);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4 <0.9.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @dev derived from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626Accounting is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /* None! Ta da! */

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }
}