// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PCVDeposit} from "../pcv/PCVDeposit.sol";
import {CTokenFuse, CEtherFuse} from "../external/fuse/CToken.sol";
import {CoreRef} from "../refs/CoreRef.sol";
import {TribeRoles} from "../core/TribeRoles.sol";

/// @title Utility contract for repaying the bad debt in fuse
/// @author Fei Protocol
contract FuseFixer is PCVDeposit {
    address public constant DEBTOR = address(0x32075bAd9050d4767018084F0Cb87b3182D36C45);

    address[] public UNDERLYINGS = [
        address(0x0000000000000000000000000000000000000000), // ETH
        address(0x956F47F50A910163D8BF957Cf5846D573E7f87CA), // FEI
        address(0x853d955aCEf822Db058eb8505911ED77F175b99e), // FRAX
        address(0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919), // RAI
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F), // DAI
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), // USDC
        address(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0), // LUSD
        address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0), // wstETH
        address(0xa693B19d2931d498c5B318dF961919BB4aee87a5), // USTw
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7) // USDT
    ];

    address[] public CTOKENS = [
        address(0xd8553552f8868C1Ef160eEdf031cF0BCf9686945), // Pool 8: FEI
        address(0xbB025D470162CC5eA24daF7d4566064EE7f5F111), // Pool 8: ETH
        address(0x7e9cE3CAa9910cc048590801e64174957Ed41d43), // Pool 8: DAI
        address(0x7259eE19D6B5e755e7c65cECfd2466C09E251185), // Pool 8: wstETH
        address(0x647A36d421183a0a9Fa62717a64B664a24E469C7), // Pool 8: LUSD
        address(0xFA1057d02A0C1a4885851e3F4fD496Ee7D38F56e), // Pool 18: ETH
        address(0x8E4E0257A4759559B4B1AC087fe8d80c63f20D19), // Pool 18: DAI
        address(0x6f95d4d251053483f41c8718C30F4F3C404A8cf2), // Pool 18: USDC
        address(0x3E5C122Ffa75A9Fe16ec0c69F7E9149203EA1A5d), // Pool 18: FRAX
        address(0x17b1A2E012cC4C31f83B90FF11d3942857664efc), // Pool 18: FEI
        address(0x51fF03410a0dA915082Af444274C381bD1b4cDB1), // Pool 18: RAI
        address(0xB7FE5f277058b3f9eABf6e0655991f10924BFA54), // Pool 18: USTw
        address(0x9de558FCE4F289b305E38ABe2169b75C626c114e), // Pool 27: FRAX
        address(0xda396c927e3e6BEf77A98f372CE431b49EdEc43D), // Pool 27: FEI
        address(0xF148cDEc066b94410d403aC5fe1bb17EC75c5851), // Pool 27: ETH
        address(0x0C402F06C11c6e6A6616C98868A855448d4CfE65), // Pool 27: USTw
        address(0x26267e41CeCa7C8E0f143554Af707336f27Fa051), // Pool 127: ETH
        address(0xEbE0d1cb6A0b8569929e062d67bfbC07608f0A47), // Pool 127: USDC
        address(0x4B68ef5AB32261082DF1A6C9C6a89FFD5eF168B1), // Pool 127: DAI
        address(0xe097783483D1b7527152eF8B150B99B9B2700c8d), // Pool 127: USDT
        address(0x0F0d710911FB37038b3AD88FC43DDAd4Edbe16A5), // Pool 127: USTw
        address(0x8922C1147E141C055fdDfc0ED5a119f3378c8ef8), // Pool 127: FRAX
        address(0x7DBC3aF9251756561Ce755fcC11c754184Af71F7), // Pool 144: ETH
        address(0x3a2804ec0Ff521374aF654D8D0daA1d1aE1ee900), // Pool 144: FEI
        address(0xA54c548d11792b3d26aD74F5f899e12CDfD64Fd6), // Pool 144: FRAX
        address(0xA6C25548dF506d84Afd237225B5B34F2Feb1aa07), // Pool 144: DAI
        address(0xfbD8Aaf46Ab3C2732FA930e5B343cd67cEA5054C), // Pool 146: ETH
        address(0x49dA42a1EcA4AC6cA0C6943d9E5dc64e4641e0E3), // Pool 146: wstETH
        address(0xe14c2e156A3f310d41240Ce8760eB3cb8a0dDBE3), // Pool 156: USTw
        address(0x001E407f497e024B9fb1CB93ef841F43D645CA4F), // Pool 156: FEI
        address(0x5CaDc2a04921213DE60B237688776e0F1A7155E6), // Pool 156: FRAX
        address(0x9CD060A4855290bf0c5aeD266aBe119FF3b01966), // Pool 156: DAI
        address(0x74897C0061ADeec84D292e8900c7BDD00b3388e4), // Pool 156: LUSD
        address(0x88d3557eB6280CC084cA36e425d6BC52d0A04429), // Pool 156: USDC
        address(0xe92a3db67e4b6AC86114149F522644b34264f858) // Pool 156: ETH
    ];

    mapping(address => address[]) public underlyingsToCTokens;

    constructor(address core) CoreRef(core) {
        _buildCTokenMapping();

        // check mappings lengths - hand calculated
        assert(underlyingsToCTokens[UNDERLYINGS[0]].length == 7);
        assert(underlyingsToCTokens[UNDERLYINGS[1]].length == 5);
        assert(underlyingsToCTokens[UNDERLYINGS[2]].length == 5);
        assert(underlyingsToCTokens[UNDERLYINGS[3]].length == 1);
        assert(underlyingsToCTokens[UNDERLYINGS[4]].length == 5);
        assert(underlyingsToCTokens[UNDERLYINGS[5]].length == 3);
        assert(underlyingsToCTokens[UNDERLYINGS[6]].length == 2);
        assert(underlyingsToCTokens[UNDERLYINGS[7]].length == 2);
        assert(underlyingsToCTokens[UNDERLYINGS[8]].length == 4);
        assert(underlyingsToCTokens[UNDERLYINGS[9]].length == 1);

        // send out token approvals
        _approveCTokens();
    }

    /// @dev Repay all debt
    function repayAll() public hasAnyOfTwoRoles(TribeRoles.PCV_SAFE_MOVER_ROLE, TribeRoles.GUARDIAN) {
        _repayETH();

        // we skip index 0 because that's ETH
        for (uint256 i = 1; i < UNDERLYINGS.length; i++) {
            _repayERC20(UNDERLYINGS[i]);
        }
    }

    /// @dev Repay the underlying asset on all ctokens up to the maximum provide
    /// @notice reverts if the total bad debt is beyond the provided maximum
    /// @param underlying the asset to repay in
    /// @param maximum the maximum amount of underlying asset to repay
    function repay(address underlying, uint256 maximum)
        public
        hasAnyOfTwoRoles(TribeRoles.PCV_SAFE_MOVER_ROLE, TribeRoles.GUARDIAN)
    {
        require(getTotalDebt(underlying) < maximum, "Total debt is greater than maximum");

        if (underlying == address(0)) {
            _repayETH();
        } else {
            _repayERC20(underlying);
        }
    }

    /// @dev Gets the total debt for the provided underlying asset
    /// @notice This is not a view function! Use .staticcall in ethers to get the return value
    /// @param underlying the asset to get the debt for; pass in 0x0 for ETH
    /// @return debt the total debt for the asset
    function getTotalDebt(address underlying) public returns (uint256 debt) {
        for (uint256 i = 0; i < CTOKENS.length; i++) {
            CTokenFuse token = CTokenFuse(CTOKENS[i]);
            if (token.underlying() == underlying) {
                debt += CTokenFuse(CTOKENS[i]).borrowBalanceCurrent(DEBTOR);
            }
        }
    }

    /* Helper Functions */

    // Creates mappings of underlyings to all applicable ctokens
    function _buildCTokenMapping() internal {
        for (uint256 i = 0; i < CTOKENS.length; i++) {
            address token = CTOKENS[i];
            address underlying = CTokenFuse(token).underlying();
            underlyingsToCTokens[underlying].push(token);
        }
    }

    // Approves all underlyings to their respective ctokens
    function _approveCTokens() internal {
        for (uint256 i = 0; i < UNDERLYINGS.length; i++) {
            address underlying = UNDERLYINGS[i];

            // Don't approve to the 0x0 address
            if (underlying == address(0)) continue;

            address[] memory ctokens = underlyingsToCTokens[underlying];

            for (uint256 j = 0; j < ctokens.length; j++) {
                address ctoken = ctokens[j];
                SafeERC20.safeApprove(IERC20(underlying), ctoken, type(uint256).max);
            }
        }
    }

    // Repays ETH to all cether-tokens
    function _repayETH() internal {
        address[] memory cEtherTokens = underlyingsToCTokens[address(0)];

        for (uint256 i = 0; i < cEtherTokens.length; i++) {
            CEtherFuse token = CEtherFuse(cEtherTokens[i]);
            uint256 debtAmount = token.borrowBalanceCurrent(DEBTOR);
            if (debtAmount > 0) {
                token.repayBorrowBehalf{value: debtAmount}(DEBTOR);
            }
        }
    }

    // Repays the provided erc20 to the applicable ctokens
    function _repayERC20(address underlying) internal {
        address[] memory cERC20Tokens = underlyingsToCTokens[underlying];

        for (uint256 i = 0; i < cERC20Tokens.length; i++) {
            CTokenFuse token = CTokenFuse(cERC20Tokens[i]);
            uint256 debtAmount = token.borrowBalanceCurrent(DEBTOR);
            token.repayBorrowBehalf(DEBTOR, debtAmount);
        }
    }

    /* Required Functions from PCVDeposit */

    function deposit() external override {
        // no-op
    }

    function withdraw(address to, uint256 amount) external override {
        // no-op, use withdrawERC20 or withdrawETH
    }

    function balance() public view virtual override returns (uint256) {
        return 0;
    }

    function balanceReportedIn() public view virtual override returns (address) {
        return address(0);
    }

    /* Make this contract able to receive ETH */

    receive() external payable {}

    fallback() external payable {}
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "./IPCVDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title abstract contract for withdrawing ERC-20 tokens using a PCV Controller
/// @author Fei Protocol
abstract contract PCVDeposit is IPCVDeposit, CoreRef {
    using SafeERC20 for IERC20;

    /// @notice withdraw ERC20 from the contract
    /// @param token address of the ERC20 to send
    /// @param to address destination of the ERC20
    /// @param amount quantity of ERC20 to send
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) public virtual override onlyPCVController {
        _withdrawERC20(token, to, amount);
    }

    function _withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(msg.sender, token, to, amount);
    }

    /// @notice withdraw ETH from the contract
    /// @param to address to send ETH
    /// @param amountOut amount of ETH to send
    function withdrawETH(address payable to, uint256 amountOut) external virtual override onlyPCVController {
        Address.sendValue(to, amountOut);
        emit WithdrawETH(msg.sender, to, amountOut);
    }

    function balance() public view virtual override returns (uint256);

    function balanceReportedIn() public view virtual override returns (address);

    function resistantBalanceAndFei() public view virtual override returns (uint256, uint256) {
        uint256 tokenBalance = balance();
        return (tokenBalance, balanceReportedIn() == address(fei()) ? tokenBalance : 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

abstract contract CToken {
    function getCash() external view virtual returns (uint256);

    function underlying() external view virtual returns (address);

    function borrowBalanceCurrent() external virtual returns (uint256);
}

abstract contract CTokenFuse {
    function getCash() external view virtual returns (uint256);

    function underlying() external view virtual returns (address);

    function borrowBalanceCurrent(address debtor) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);
}

abstract contract CEtherFuse {
    function getCash() external view virtual returns (uint256);

    function underlying() external view virtual returns (address);

    function borrowBalanceCurrent(address debtor) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower) external payable virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private immutable _core;
    IFei private immutable _fei;
    IERC20 private immutable _tribe;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    constructor(address coreAddress) {
        _core = ICore(coreAddress);

        _fei = ICore(coreAddress).fei();
        _tribe = ICore(coreAddress).tribe();

        _setContractAdminRole(ICore(coreAddress).GOVERN_ROLE());
    }

    function _initialize(address) internal {} // no-op for backward compatibility

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(_core.isPCVController(msg.sender), "CoreRef: Caller is not a PCV controller");
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) || isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef: Caller is not a governor");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier isGovernorOrGuardianOrAdmin() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender) || isContractAdmin(msg.sender),
            "CoreRef: Caller is not governor or guardian or admin"
        );
        _;
    }

    // Named onlyTribeRole to prevent collision with OZ onlyRole modifier
    modifier onlyTribeRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }

    // Modifiers to allow any combination of roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(_core.hasRole(role1, msg.sender) || _core.hasRole(role2, msg.sender), "UNAUTHORIZED");
        _;
    }

    modifier hasAnyOfThreeRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _core.hasRole(role1, msg.sender) || _core.hasRole(role2, msg.sender) || _core.hasRole(role3, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFourRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFiveRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4,
        bytes32 role5
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender) ||
                _core.hasRole(role5, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfSixRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4,
        bytes32 role5,
        bytes32 role6
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender) ||
                _core.hasRole(role5, msg.sender) ||
                _core.hasRole(role6, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyFei() {
        require(msg.sender == address(_fei), "CoreRef: Caller is not FEI");
        _;
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole) external override onlyGovernor {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin) public view override returns (bool) {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function fei() public view override returns (IFei) {
        return _fei;
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function tribe() public view override returns (IERC20) {
        return _tribe;
    }

    /// @notice fei balance of contract
    /// @return fei amount held
    function feiBalance() public view override returns (uint256) {
        return _fei.balanceOf(address(this));
    }

    /// @notice tribe balance of contract
    /// @return tribe amount held
    function tribeBalance() public view override returns (uint256) {
        return _tribe.balanceOf(address(this));
    }

    function _burnFeiHeld() internal {
        _fei.burn(feiBalance());
    }

    function _mintFei(address to, uint256 amount) internal virtual {
        if (amount != 0) {
            _fei.mint(to, amount);
        }
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(oldContractAdminRole, newContractAdminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 @title Tribe DAO ACL Roles
 @notice Holds a complete list of all roles which can be held by contracts inside Tribe DAO.
         Roles are broken up into 3 categories:
         * Major Roles - the most powerful roles in the Tribe DAO which should be carefully managed.
         * Admin Roles - roles with management capability over critical functionality. Should only be held by automated or optimistic mechanisms
         * Minor Roles - operational roles. May be held or managed by shorter optimistic timelocks or trusted multisigs.
 */
library TribeRoles {
    /*///////////////////////////////////////////////////////////////
                                 Major Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the ultimate role of Tribe. Controls all other roles and protocol functionality.
    bytes32 internal constant GOVERNOR = keccak256("GOVERN_ROLE");

    /// @notice the protector role of Tribe. Admin of pause, veto, revoke, and minor roles
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /// @notice the role which can arbitrarily move PCV in any size from any contract
    bytes32 internal constant PCV_CONTROLLER = keccak256("PCV_CONTROLLER_ROLE");

    /// @notice can mint FEI arbitrarily
    bytes32 internal constant MINTER = keccak256("MINTER_ROLE");

    /// @notice Manages lower level - Admin and Minor - roles. Able to grant and revoke these
    bytes32 internal constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    /*///////////////////////////////////////////////////////////////
                                 Admin Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice has access to all admin functionality on pods
    bytes32 internal constant POD_ADMIN = keccak256("POD_ADMIN");

    /// @notice capable of granting and revoking other TribeRoles from having veto power over a pod
    bytes32 internal constant POD_VETO_ADMIN = keccak256("POD_VETO_ADMIN");

    /// @notice can manage the majority of Tribe protocol parameters
    bytes32 internal constant PARAMETER_ADMIN = keccak256("PARAMETER_ADMIN");

    /// @notice manages the Collateralization Oracle as well as other protocol oracles.
    bytes32 internal constant ORACLE_ADMIN = keccak256("ORACLE_ADMIN_ROLE");

    /// @notice manages TribalChief incentives and related functionality.
    bytes32 internal constant TRIBAL_CHIEF_ADMIN = keccak256("TRIBAL_CHIEF_ADMIN_ROLE");

    /// @notice admin of the Tokemak PCV deposits
    bytes32 internal constant TOKEMAK_DEPOSIT_ADMIN_ROLE = keccak256("TOKEMAK_DEPOSIT_ADMIN_ROLE");

    /// @notice admin of PCVGuardian
    bytes32 internal constant PCV_GUARDIAN_ADMIN = keccak256("PCV_GUARDIAN_ADMIN_ROLE");

    /// @notice admin of the Fuse protocol
    bytes32 internal constant FUSE_ADMIN = keccak256("FUSE_ADMIN");

    /// @notice admin of minting Fei for specific scoped contracts
    bytes32 internal constant FEI_MINT_ADMIN = keccak256("FEI_MINT_ADMIN");

    /// @notice capable of admin functionality on PCVDeposits
    bytes32 internal constant PCV_MINOR_PARAM_ROLE = keccak256("PCV_MINOR_PARAM_ROLE");

    /// @notice capable of setting FEI Minters within global rate limits and caps
    bytes32 internal constant RATE_LIMITED_MINTER_ADMIN = keccak256("RATE_LIMITED_MINTER_ADMIN");

    /// @notice manages meta-governance actions, like voting & delegating.
    /// Also used to vote for gauge weights & similar liquid governance things.
    bytes32 internal constant METAGOVERNANCE_VOTE_ADMIN = keccak256("METAGOVERNANCE_VOTE_ADMIN");

    /// @notice allows to manage locking of vote-escrowed tokens, and staking/unstaking
    /// governance tokens from a pre-defined contract in order to eventually allow voting.
    /// Examples: ANGLE <> veANGLE, AAVE <> stkAAVE, CVX <> vlCVX, CRV > cvxCRV.
    bytes32 internal constant METAGOVERNANCE_TOKEN_STAKING = keccak256("METAGOVERNANCE_TOKEN_STAKING");

    /// @notice manages whitelisting of gauges where the protocol's tokens can be staked
    bytes32 internal constant METAGOVERNANCE_GAUGE_ADMIN = keccak256("METAGOVERNANCE_GAUGE_ADMIN");

    /// @notice capable of performing swaps on Balancer LBP Swapper
    bytes32 internal constant SWAP_ADMIN_ROLE = keccak256("SWAP_ADMIN_ROLE");

    /// @notice capable of setting properties on Balancer BasePool utility wrapper
    bytes32 internal constant BALANCER_MANAGER_ADMIN_ROLE = keccak256("BALANCER_MANAGER_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                                 Minor Roles
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant POD_METADATA_REGISTER_ROLE = keccak256("POD_METADATA_REGISTER_ROLE");

    /// @notice capable of engaging with Votium for voting incentives.
    bytes32 internal constant VOTIUM_ADMIN_ROLE = keccak256("VOTIUM_ADMIN_ROLE");

    /// @notice capable of adding an address to multi rate limited
    bytes32 internal constant ADD_MINTER_ROLE = keccak256("ADD_MINTER_ROLE");

    /// @notice capable of changing PCV Deposit and Global Rate Limited Minter in the PSM
    bytes32 internal constant PSM_ADMIN_ROLE = keccak256("PSM_ADMIN_ROLE");

    /// @notice capable of moving PCV between safe addresses on the PCVGuardian
    bytes32 internal constant PCV_SAFE_MOVER_ROLE = keccak256("PCV_SAFE_MOVER_ROLE");
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositBalances.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(address indexed _caller, address indexed _to, uint256 _amount);

    event WithdrawERC20(address indexed _caller, address indexed _token, address indexed _to, uint256 _amount);

    event WithdrawETH(address indexed _caller, address indexed _to, uint256 _amount);

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(bytes32 indexed oldContractAdminRole, bytes32 indexed newContractAdminRole);

    // ----------- Governor only state changing api -----------

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);

    function feiBalance() external view returns (uint256);

    function tribeBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPermissions.sol";
import "../fei/IFei.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event FeiUpdate(address indexed _fei);
    event TribeUpdate(address indexed _tribe);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event TribeAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setFei(address token) external;

    function setTribe(address token) external;

    function allocateTribe(address to, uint256 amount) external;

    // ----------- Getters -----------

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPermissionsRead.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl, IPermissionsRead {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IFei is IERC20 {
    // ----------- Events -----------

    event Minting(address indexed _to, address indexed _minter, uint256 _amount);

    event Burning(address indexed _to, address indexed _burner, uint256 _amount);

    event IncentiveContractUpdate(address indexed _incentivized, address indexed _incentiveContract);

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address account, address incentive) external;

    // ----------- Getters -----------

    function incentiveContract(address account) external view returns (address);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title Permissions Read interface
/// @author Fei Protocol
interface IPermissionsRead {
    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Deposit interface for only balance getters
/// @author Fei Protocol
interface IPCVDepositBalances {
    // ----------- Getters -----------

    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndFei() external view returns (uint256, uint256);
}