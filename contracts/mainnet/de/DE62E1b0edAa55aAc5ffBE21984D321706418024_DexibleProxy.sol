// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IPausable {

    event Paused();
    event Resumed();

    function pause() external;
    function resume() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./DexibleStorage.sol";
import "./ProxyStorage.sol";

contract DexibleProxy {

    modifier onlyAdmin() {
        require(DexibleStorage.load().adminMultiSig == msg.sender, "Unauthorized");
        _;
    }

    event UpgradeProposed(address newLogic, uint upgradeAfter);
    event UpgradedLogic(address newLogic);

    constructor(address _logic, uint32 timelock, bytes memory initData) {
        if(initData.length > 0) {
            (bool s, ) = _logic.delegatecall(initData);
            if(!s) {
                revert("Failed to initialize implementation");
            }
        }
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        pd.logic = _logic;
        pd.timelockSeconds = timelock;
    }

    function proposeUpgrade(address _logic, bytes calldata upgradeInit) public onlyAdmin {
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        require(_logic != address(0), "Invalid logic");
        pd.pendingUpgrade = ProxyStorage.PendingUpgrade({
            newLogic: _logic,
            initData: upgradeInit,
            upgradeAfter:  block.timestamp + pd.timelockSeconds
        });
        emit UpgradeProposed(_logic, pd.pendingUpgrade.upgradeAfter);
    }

    function canUpgrade() public view returns (bool) {
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        return pd.pendingUpgrade.newLogic != address(0) && pd.pendingUpgrade.upgradeAfter < block.timestamp;
    }

    function logic() public view returns (address) {
        return ProxyStorage.load().logic;
    }

    //anyone can call or it will be called when next call is made to the contract after upgrade
    //is allowed
    function upgradeLogic() public {
        require(canUpgrade(), "Cannot upgrade yet");
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        pd.logic = pd.pendingUpgrade.newLogic;
        if(pd.pendingUpgrade.initData.length > 0) {
            (bool s, ) = pd.logic.delegatecall(pd.pendingUpgrade.initData);
            if(!s) {
                revert("Failed to initialize new implementation");
            }
        }
        delete pd.pendingUpgrade;
        emit UpgradedLogic(pd.logic);
    }

    //call impl using proxy's state data
    fallback() external {
        
        //if an upgrade can happen, upgrade
        if(canUpgrade()) {
            upgradeLogic();
        }

        //get the logic from storage
        address addr = ProxyStorage.load().logic;
        assembly {
            //and call it
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), addr, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../token/IDXBL.sol";
import "./oracles/IArbitrumGasOracle.sol";
import "../vault/interfaces/ICommunityVault.sol";
import "./oracles/IStandardGasAdjustments.sol";

library DexibleStorage {
    bytes32 constant DEXIBLE_STORAGE_KEY = 0x949817a987a8e038ef345d3c9d4fd28e49d8e4e09456e57c05a8b2ce2e62866c;

    //primary initialization config settings
    struct DexibleConfig {
        
        //percent to split to revshare
        uint8 revshareSplitRatio;

        //std bps rate to apply to all trades
        uint16 stdBpsRate;

        //minimum bps rate regardless of tokens held
        uint16 minBpsRate;

        //multi sig allowed to change settings
        address adminMultiSig;

        //the vault contract
        address communityVault;

        //treasury for Dexible team
        address treasury;

        //the DXBL token address
        address dxblToken;

        //arbitrum gas oracle contract address
        address arbGasOracle;

        //contract that manages the standard gas adjustment types
        address stdGasAdjustment;

        //minimum flat fee to charge if bps fee is too low
        uint112 minFeeUSD;

        //whitelisted relays to allow
        address[] initialRelays;

    }

    /**
     * This is the primary storage for Dexible operations.
     */
    struct DexibleData {

        //whether contract has been paused
        bool paused;

        //how much of fee goes to revshare vault
        uint8 revshareSplitRatio;
         
        //standard bps fee rate
        uint16 stdBpsRate;

        //minimum fee applied regardless of tokens held
        uint16 minBpsRate;

        //min fee to charge if bps too low
        uint112 minFeeUSD;
        
        //vault address
        ICommunityVault communityVault;

        //treasury address
        address treasury;

        //multi-sig that manages this contract
        address adminMultiSig;

        //the DXBL token
        IDXBL dxblToken;

        //gas oracle for arb network
        IArbitrumGasOracle arbitrumGasOracle;

        IStandardGasAdjustments stdGasAdjustment;

        //whitelisted relay wallets
        mapping(address => bool) relays;
    }

    function load() internal pure returns (DexibleData storage ds) {
        assembly { ds.slot := DEXIBLE_STORAGE_KEY }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IArbitrumGasOracle {
    function calculateGasCost(uint callDataSize, uint l2GasUsed) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IStandardGasAdjustments {

    function adjustment(string memory adjType) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

library ProxyStorage {

    bytes32 constant DATA_KEY = 0x21b00fb42ba9970a2143fc9fb216ce19c58db008c8d83ff3a715bbc79598d7f0;

    struct PendingUpgrade {
        address newLogic;
        bytes initData;
        uint upgradeAfter;
    }

    struct ProxyData {
        address logic;
        uint32 timelockSeconds;
        PendingUpgrade pendingUpgrade;
    }

    function load() internal pure returns (ProxyData storage ds) {
        assembly { ds.slot := DATA_KEY }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDXBL is IERC20, IERC20Metadata {
    struct FeeRequest {
        bool referred;
        address trader;
        uint amt;
        uint dxblBalance;
        uint16 stdBpsRate;
        uint16 minBpsRate;
    }

    function minter() external view returns (address);
    function discountPerTokenBps() external view returns(uint32);

    function mint(address acct, uint amt) external;
    function burn(address holder, uint amt) external;
    function setDiscountRate(uint32 discount) external;
    function setNewMinter(address minter) external;
    function computeDiscountedFee(FeeRequest calldata request) external view returns(uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ICommunityVaultEvents.sol";
import "./V1Migrateable.sol";
import "./IStorageView.sol";
import "./IComputationalView.sol";
import "./IRewardHandler.sol";
import "../../common/IPausable.sol";

interface ICommunityVault is IStorageView, IComputationalView, IRewardHandler, ICommunityVaultEvents, IPausable, V1Migrateable {
    function redeemDXBL(address feeToken, uint dxblAmount, uint minOutAmount, bool unwrapNative) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ICommunityVaultEvents {

    event DXBLRedeemed(address holder, uint dxblAmount, address rewardToken, uint rewardAmount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IComputationalView {

    struct AssetInfo {
        address token;
        uint balance;
        uint usdValue;
        uint usdPrice;
    }

    function convertGasToFeeToken(address feeToken, uint gasCost) external view returns (uint);
    function estimateRedemption(address feeToken, uint dxblAmount) external view returns(uint);
    function feeTokenPriceUSD(address feeToken) external view returns (uint);
    function aumUSD() external view returns(uint);
    function currentNavUSD() external view returns(uint);
    function assets() external view returns (AssetInfo[] memory);
    function currentMintRateUSD() external view returns (uint);
    function computeVolumeUSD(address feeToken, uint amount) external view returns(uint);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * Interface for Chainlink oracle feeds
 */
interface IPriceFeed {
    function latestRoundData() external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IRewardHandler {

    /**
     * Modification functions
     */
    function rewardTrader(address trader, address feeToken, uint amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IStorageView {

    /**
     * Storage variable view functions
     */
    function isFeeTokenAllowed(address tokens) external view returns (bool);
    function discountBps() external view returns(uint32);
    function dailyVolumeUSD() external view returns(uint);
    function paused() external view returns (bool);
    function adminMultiSig() external view returns (address);
    function dxblToken() external view returns (address);
    function dexibleContract() external view returns (address);
    function wrappedNativeToken() external view returns (address);
    function timelockSeconds() external view returns (uint32);
    function baseMintThreshold() external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../VaultStorage.sol";

interface V1MigrationTarget {
    /**
     * Call from current vault to migrate the state of the old vault to the new one. 
     */
    function migrationFromV1(VaultStorage.VaultMigrationV1 memory data) external;
}

interface V1Migrateable {

    event MigrationScheduled(address indexed newVault, uint afterTime);
    event MigrationCancelled(address indexed newVault);
    event VaultMigrated(address indexed newVault);

    function scheduleMigration(V1MigrationTarget target) external;

    function cancelMigration() external;

    function canMigrate() external view returns (bool);

    /**
     * Migrate the vault to a new vault address that implements the target interface
     * to receive this vault's state. This will transfer all fee token assets to the 
     * new vault. This can only be called after timelock is expired.
     */
    function migrateV1() external;
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../token/IDXBL.sol";
import "./interfaces/IPriceFeed.sol";

library VaultStorage {

    bytes32 constant VAULT_STORAGE_KEY = 0xbfa76ec2967ed7f8d3d40cd552f1451ab03573b596bfce931a6a016f7733078c;

    
    //mint rate bucket
    struct MintRateRangeConfig {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
    }

    //fee token and its associated chainlink feed
    struct FeeTokenConfig {
        address[] feeTokens;
        address[] priceFeeds;
    }

    //initialize config to intialize storage
    struct VaultConfig {

        //the address of the wrapped native token
        address wrappedNativeToken;

        //address of the multisig that will administer this vault
        address adminMultiSig;


        //seconds for any timelock-based changes
        uint32 timelockSeconds;

        //starting volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //initial rate ranges to apply
        MintRateRangeConfig[] rateRanges;

        //set of fee token/price feed pairs to initialize with
        FeeTokenConfig feeTokenConfig;
    }

    //stored mint rate range
    struct MintRateRange {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
        uint index;
    }

    //price feed for a fee token
    struct PriceFeed {
        IPriceFeed feed;
        uint8 decimals;
    }

    /*****************************************************************************************
     * STORAGE
    ******************************************************************************************/
    
    
    struct VaultData {
        //whether the vault is paused
        bool paused;

        //admin multi sig
        address adminMultiSig;

        //token address
        IDXBL dxbl;

        //dexible settlement contract that is allowed to call the vault
        address dexible;

        //wrapped native asset address for gas computation
        address wrappedNativeToken;

        //pending migration to new vault
        address pendingMigrationTarget;

        //time before migration allowed
        uint32 timelockSeconds;

        //base volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //current daily volume adjusted each hour
        uint currentVolume;

        //to compute what hourly slots to deduct from 24hr window
        uint lastTradeTimestamp;

        //can migrate the contract to a new vault after this time
        uint migrateAfterTime;

        //all known fee tokens. Some may be inactive
        IERC20[] feeTokens;

        //the current volume range we're operating in for mint rate
        MintRateRange currentMintRate;

        //The ranges of 24hr volume and their percentage-per-MM increase to 
        //mint a single token
        MintRateRange[] mintRateRanges;

        //hourly volume totals to adjust current volume every 24 hr slot
        uint[24] hourlyVolume;

        //fee token decimals
        mapping(address => uint8) tokenDecimals;

        //all allowed fee tokens mapped to their price feed address
        mapping(address => PriceFeed) allowedFeeTokens;
    }

    /**
     * If a migration occurs from the V1 vault to a new vault, this structure is forwarded
     * after all fee token balances are transferred. It is expected that the new vault will have
     * its fee token, minting rates, and starting mint rates mapped out as part of its deployment.
     * The migration is intended to get the new vault into a state where it knows the last 24hrs
     * of volume and can pick up where this vault leaves off but with new settings and capabilities.
     */
    struct VaultMigrationV1 {
        //current daily volume adjusted each hour
        uint currentVolume;

        //to compute what hourly slots to deduct from 24hr window
        uint lastTradeTimestamp;

        //hourly volume totals to adjust in new contract
        uint[24] hourlyVolume;

        //the current volume range we're operating in for mint rate
        MintRateRange currentMintRate;
    }

    function load() internal pure returns (VaultData storage ds) {
        assembly { ds.slot := VAULT_STORAGE_KEY }
    }
}