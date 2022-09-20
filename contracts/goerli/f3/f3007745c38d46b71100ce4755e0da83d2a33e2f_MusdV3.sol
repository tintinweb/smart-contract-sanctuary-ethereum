/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma abicoder v2;


interface MassetStructs {
    struct BassetPersonal {
        // Address of the bAsset
        address addr;
        // Address of the bAsset
        address integrator;
        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        bool hasTxFee; // takes a byte in storage
        // Status of the bAsset
        BassetStatus status;
    }

    struct BassetData {
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        // If ratio == 10e8 then 1 bAsset = 10 mAssets
        // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        uint128 ratio;
        // Amount of the Basset that is held in Collateral
        uint128 vaultBalance;
    }

    // Status of the Basset - has it broken its peg?
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    struct BasketState {
        bool undergoingRecol;
        bool failed;
    }

    struct InvariantConfig {
        uint256 a;
        WeightLimits limits;
    }

    struct WeightLimits {
        uint128 min;
        uint128 max;
    }

    struct AmpData {
        uint64 initialA;
        uint64 targetA;
        uint64 rampStartTime;
        uint64 rampEndTime;
    }
}

abstract contract IInvariantValidator is MassetStructs {
    // Mint
    function computeMint(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint256 _rawInput,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    function computeMintMulti(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawInputs,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    // Swap
    function computeSwap(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint8 _o,
        uint256 _rawInput,
        uint256 _feeRate,
        InvariantConfig memory _config
    ) external view virtual returns (uint256, uint256);

    // Redeem
    function computeRedeem(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint256 _mAssetQuantity,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    function computeRedeemExact(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawOutputs,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);
}

contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    // constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract ERC205 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

abstract contract InitializableERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return "mStable USD";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return "mUSD";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

abstract contract InitializableToken is ERC205, InitializableERC20Detailed {
    /**
     * @dev Initialization function for implementing contract
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(string memory _nameArg, string memory _symbolArg) internal {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
    }
}

contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
}

interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }



    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Staking Module address from the Nexus
     * @return Address of the Staking Module contract
     */
    function _staking() internal view returns (address) {
        return nexus.getModule(KEY_STAKING);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }

    /**
     * @dev Return MetaToken Module address from the Nexus
     * @return Address of the MetaToken Module contract
     */
    function _metaToken() internal view returns (address) {
        return nexus.getModule(KEY_META_TOKEN);
    }

    /**
     * @dev Return OracleHub Module address from the Nexus
     * @return Address of the OracleHub Module contract
     */
    function _oracleHub() internal view returns (address) {
        return nexus.getModule(KEY_ORACLE_HUB);
    }

    /**
     * @dev Return Manager Module address from the Nexus
     * @return Address of the Manager Module contract
     */
    function _manager() internal view returns (address) {
        return nexus.getModule(KEY_MANAGER);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }
}

contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initializeReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

abstract contract IMasset is MassetStructs {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);
}

abstract contract Deprecated_BasketManager is MassetStructs {}

library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e38 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x * ratio;
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled + RATIO_SCALE - 1;
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil / RATIO_SCALE;
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        // return 1e22 / 1e12 = 1e10
        return (x * RATIO_SCALE) / ratio;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

interface IPlatformIntegration {
    /**
     * @dev Deposit the given bAsset to Lending platform
     * @param _bAsset bAsset address
     * @param _amount Amount to deposit
     */
    function deposit(
        address _bAsset,
        uint256 _amount,
        bool isTokenFeeCharged
    ) external returns (uint256 quantityDeposited);

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        uint256 _totalAmount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from the cache
     */
    function withdrawRaw(
        address _receiver,
        address _bAsset,
        uint256 _amount
    ) external;

    /**
     * @dev Returns the current balance of the given bAsset
     */
    function checkBalance(address _bAsset) external returns (uint256 balance);

    /**
     * @dev Returns the pToken
     */
    function bAssetToPToken(address _bAsset) external returns (address pToken);
}

interface IBasicToken {
    function decimals() external view returns (uint8);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library MassetHelpers {
    using SafeERC20 for IERC20;

    function transferReturnBalance(
        address _sender,
        address _recipient,
        address _bAsset,
        uint256 _qty
    ) internal returns (uint256 receivedQty, uint256 recipientBalance) {
        uint256 balBefore = IERC20(_bAsset).balanceOf(_recipient);
        IERC20(_bAsset).safeTransferFrom(_sender, _recipient, _qty);
        recipientBalance = IERC20(_bAsset).balanceOf(_recipient);
        receivedQty = recipientBalance - balBefore;
    }

    function safeInfiniteApprove(address _asset, address _spender) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, 2**256 - 1);
    }
}

library Manager {
    using SafeERC20 for IERC20;
    using StableMath for uint256;

    event BassetsMigrated(address[] bAssets, address newIntegrator);
    event TransferFeeEnabled(address indexed bAsset, bool enabled);
    event BassetAdded(address indexed bAsset, address integrator);
    event BassetStatusChanged(address indexed bAsset, MassetStructs.BassetStatus status);
    event BasketStatusChanged();
    event StartRampA(uint256 currentA, uint256 targetA, uint256 startTime, uint256 rampEndTime);
    event StopRampA(uint256 currentA, uint256 time);

    uint256 private constant MIN_RAMP_TIME = 1 days;
    uint256 private constant MAX_A = 1e6;

    /**
     * @notice Adds a bAsset to the given personal, data and mapping, provided it is valid
     * @param _bAssetPersonal   Basset data storage array
     * @param _bAssetData       Basset data storage array
     * @param _bAssetIndexes    Mapping of bAsset address to their index
     * @param _maxBassets       Max size of the basket
     * @param _bAsset           Address of the ERC20 token to add to the Basket
     * @param _integration      Address of the Platform Integration
     * @param _mm               Base 1e8 var to determine measurement ratio
     * @param _hasTxFee         Are transfer fees charged on this bAsset (e.g. USDT)
     */
    function addBasset(
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        MassetStructs.BassetData[] storage _bAssetData,
        mapping(address => uint8) storage _bAssetIndexes,
        uint8 _maxBassets,
        address _bAsset,
        address _integration,
        uint256 _mm,
        bool _hasTxFee
    ) external {
        require(_bAsset != address(0), "bAsset address must be valid");
        uint8 bAssetCount = uint8(_bAssetPersonal.length);
        require(bAssetCount < _maxBassets, "Max bAssets in Basket");

        uint8 idx = _bAssetIndexes[_bAsset];
        require(
            bAssetCount == 0 || _bAssetPersonal[idx].addr != _bAsset,
            "bAsset already exists in Basket"
        );

        // Should fail if bAsset is not added to integration
        // Programmatic enforcement of bAsset validity should service through decentralised feed
        if (_integration != address(0)) {
            IPlatformIntegration(_integration).checkBalance(_bAsset);
        }

        uint256 bAssetDecimals = IBasicToken(_bAsset).decimals();
        require(
            bAssetDecimals >= 4 && bAssetDecimals <= 18,
            "Token must have sufficient decimal places"
        );

        uint256 delta = uint256(18) - bAssetDecimals;
        uint256 ratio = _mm * (10**delta);

        _bAssetIndexes[_bAsset] = bAssetCount;

        _bAssetPersonal.push(
            MassetStructs.BassetPersonal({
                addr: _bAsset,
                integrator: _integration,
                hasTxFee: _hasTxFee,
                status: MassetStructs.BassetStatus.Normal
            })
        );
        _bAssetData.push(
            MassetStructs.BassetData({ ratio: SafeCast.toUint128(ratio), vaultBalance: 0 })
        );

        emit BassetAdded(_bAsset, _integration);
    }

    /**
     * @dev Collects the interest generated from the Basket, minting a relative
     *      amount of mAsset and sending it over to the SavingsManager.
     * @param _bAssetPersonal   Basset personal storage array
     * @param _bAssetData       Basset data storage array
     * @param _forgeValidator   Link to the current InvariantValidator
     * @return mintAmount       Lending market interest collected
     * @return rawGains         Raw increases in vault Balance
     */
    function collectPlatformInterest(
        MassetStructs.BassetPersonal[] memory _bAssetPersonal,
        MassetStructs.BassetData[] storage _bAssetData,
        IInvariantValidator _forgeValidator,
        MassetStructs.InvariantConfig memory _config
    ) external returns (uint256 mintAmount, uint256[] memory rawGains) {
        // Get basket details
        MassetStructs.BassetData[] memory bAssetData_ = _bAssetData;
        uint256 count = bAssetData_.length;
        uint8[] memory indices = new uint8[](count);
        rawGains = new uint256[](count);
        // 1. Calculate rawGains in each bAsset, in comparison to current vault balance
        for (uint256 i = 0; i < count; i++) {
            indices[i] = uint8(i);
            MassetStructs.BassetPersonal memory bPersonal = _bAssetPersonal[i];
            MassetStructs.BassetData memory bData = bAssetData_[i];
            // If there is no integration, then nothing can have accrued
            if (bPersonal.integrator == address(0)) continue;
            uint256 lending =
                IPlatformIntegration(bPersonal.integrator).checkBalance(bPersonal.addr);
            uint256 cache = 0;
            if (!bPersonal.hasTxFee) {
                cache = IERC20(bPersonal.addr).balanceOf(bPersonal.integrator);
            }
            uint256 balance = lending + cache;
            uint256 oldVaultBalance = bData.vaultBalance;
            if (
                balance > oldVaultBalance && bPersonal.status == MassetStructs.BassetStatus.Normal
            ) {
                _bAssetData[i].vaultBalance = SafeCast.toUint128(balance);
                uint256 interestDelta = balance - oldVaultBalance;
                rawGains[i] = interestDelta;
            } else {
                rawGains[i] = 0;
            }
        }
        mintAmount = _forgeValidator.computeMintMulti(bAssetData_, indices, rawGains, _config);
    }

    /**
     * @dev Update transfer fee flag for a given bAsset, should it change its fee practice
     * @param _bAssetPersonal   Basset data storage array
     * @param _bAssetIndexes    Mapping of bAsset address to their index
     * @param _bAsset   bAsset address
     * @param _flag         Charge transfer fee when its set to 'true', otherwise 'false'
     */
    function setTransferFeesFlag(
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        mapping(address => uint8) storage _bAssetIndexes,
        address _bAsset,
        bool _flag
    ) external {
        uint256 index = _getAssetIndex(_bAssetPersonal, _bAssetIndexes, _bAsset);
        _bAssetPersonal[index].hasTxFee = _flag;

        if (_flag) {
            // if token has tx fees, it can no longer operate with a cache
            address integration = _bAssetPersonal[index].integrator;
            if (integration != address(0)) {
                uint256 bal = IERC20(_bAsset).balanceOf(integration);
                if (bal > 0) {
                    IPlatformIntegration(integration).deposit(_bAsset, bal, true);
                }
            }
        }

        emit TransferFeeEnabled(_bAsset, _flag);
    }

    /**
     * @dev Transfers all collateral from one lending market to another - used initially
     *      to handle the migration between Aave V1 and Aave V2. Note - only supports non
     *      tx fee enabled assets. Supports going from no integration to integration, but
     *      not the other way around.
     * @param _bAssetPersonal   Basset data storage array
     * @param _bAssetIndexes    Mapping of bAsset address to their index
     * @param _bAssets          Array of basket assets to migrate
     * @param _newIntegration   Address of the new platform integration
     */
    function migrateBassets(
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        mapping(address => uint8) storage _bAssetIndexes,
        address[] calldata _bAssets,
        address _newIntegration
    ) external {
        uint256 len = _bAssets.length;
        require(len > 0, "Must migrate some bAssets");

        for (uint256 i = 0; i < len; i++) {
            // 1. Check that the bAsset is in the basket
            address bAsset = _bAssets[i];
            uint256 index = _getAssetIndex(_bAssetPersonal, _bAssetIndexes, bAsset);
            require(!_bAssetPersonal[index].hasTxFee, "A bAsset has a transfer fee");

            // 2. Withdraw everything from the old platform integration
            address oldAddress = _bAssetPersonal[index].integrator;
            require(oldAddress != _newIntegration, "Must transfer to new integrator");
            (uint256 cache, uint256 lendingBal) = (0, 0);
            if (oldAddress == address(0)) {
                cache = IERC20(bAsset).balanceOf(address(this));
            } else {
                IPlatformIntegration oldIntegration = IPlatformIntegration(oldAddress);
                cache = IERC20(bAsset).balanceOf(address(oldIntegration));
                // 2.1. Withdraw from the lending market
                lendingBal = oldIntegration.checkBalance(bAsset);
                if (lendingBal > 0) {
                    oldIntegration.withdraw(address(this), bAsset, lendingBal, false);
                }
                // 2.2. Withdraw from the cache, if any
                if (cache > 0) {
                    oldIntegration.withdrawRaw(address(this), bAsset, cache);
                }
            }
            uint256 sum = lendingBal + cache;

            // 3. Update the integration address for this bAsset
            _bAssetPersonal[index].integrator = _newIntegration;

            // 4. Deposit everything into the new
            //    This should fail if we did not receive the full amount from the platform withdrawal
            // 4.1. Deposit all bAsset
            IERC20(bAsset).safeTransfer(_newIntegration, sum);
            IPlatformIntegration newIntegration = IPlatformIntegration(_newIntegration);
            if (lendingBal > 0) {
                newIntegration.deposit(bAsset, lendingBal, false);
            }
            // 4.2. Check balances
            uint256 newLendingBal = newIntegration.checkBalance(bAsset);
            uint256 newCache = IERC20(bAsset).balanceOf(address(newIntegration));
            uint256 upperMargin = 10001e14;
            uint256 lowerMargin = 9999e14;

            require(
                newLendingBal >= lendingBal.mulTruncate(lowerMargin) &&
                    newLendingBal <= lendingBal.mulTruncate(upperMargin),
                "Must transfer full amount"
            );
            require(
                newCache >= cache.mulTruncate(lowerMargin) &&
                    newCache <= cache.mulTruncate(upperMargin),
                "Must transfer full amount"
            );
        }

        emit BassetsMigrated(_bAssets, _newIntegration);
    }

    /**
     * @dev Executes the Auto Redistribution event by isolating the bAsset from the Basket
     * @param _basket          Struct containing core basket info
     * @param _bAssetPersonal  Basset data storage array
     * @param _bAsset          Address of the ERC20 token to isolate
     * @param _belowPeg        Bool to describe whether the bAsset deviated below peg (t)
     *                         or above (f)
     */
    function handlePegLoss(
        MassetStructs.BasketState storage _basket,
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        mapping(address => uint8) storage _bAssetIndexes,
        address _bAsset,
        bool _belowPeg
    ) external {
        require(!_basket.failed, "Basket must be alive");

        uint256 i = _getAssetIndex(_bAssetPersonal, _bAssetIndexes, _bAsset);

        MassetStructs.BassetStatus newStatus =
            _belowPeg
                ? MassetStructs.BassetStatus.BrokenBelowPeg
                : MassetStructs.BassetStatus.BrokenAbovePeg;
        _bAssetPersonal[i].status = newStatus;

        _basket.undergoingRecol = true;

        emit BassetStatusChanged(_bAsset, newStatus);
    }

    /**
     * @dev Negates the isolation of a given bAsset
     * @param _basket          Struct containing core basket info
     * @param _bAssetPersonal  Basset data storage array
     * @param _bAssetIndexes    Mapping of bAsset address to their index
     * @param _bAsset Address of the bAsset
     */
    function negateIsolation(
        MassetStructs.BasketState storage _basket,
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        mapping(address => uint8) storage _bAssetIndexes,
        address _bAsset
    ) external {
        uint256 i = _getAssetIndex(_bAssetPersonal, _bAssetIndexes, _bAsset);

        _bAssetPersonal[i].status = MassetStructs.BassetStatus.Normal;

        bool undergoingRecol = false;
        for (uint256 j = 0; j < _bAssetPersonal.length; j++) {
            if (_bAssetPersonal[j].status != MassetStructs.BassetStatus.Normal) {
                undergoingRecol = true;
                break;
            }
        }
        _basket.undergoingRecol = undergoingRecol;

        emit BassetStatusChanged(_bAsset, MassetStructs.BassetStatus.Normal);
    }

    /**
     * @dev Starts changing of the amplification var A
     * @param _targetA      Target A value
     * @param _rampEndTime  Time at which A will arrive at _targetA
     */
    function startRampA(
        MassetStructs.AmpData storage _ampData,
        uint256 _targetA,
        uint256 _rampEndTime,
        uint256 _currentA,
        uint256 _precision
    ) external {
        require(
            block.timestamp >= (_ampData.rampStartTime + MIN_RAMP_TIME),
            "Sufficient period of previous ramp has not elapsed"
        );
        require(_rampEndTime >= (block.timestamp + MIN_RAMP_TIME), "Ramp time too short");
        require(_targetA > 0 && _targetA < MAX_A, "A target out of bounds");

        uint256 preciseTargetA = _targetA * _precision;

        if (preciseTargetA > _currentA) {
            require(preciseTargetA <= _currentA * 10, "A target increase too big");
        } else {
            require(preciseTargetA >= _currentA / 10, "A target decrease too big");
        }

        _ampData.initialA = SafeCast.toUint64(_currentA);
        _ampData.targetA = SafeCast.toUint64(preciseTargetA);
        _ampData.rampStartTime = SafeCast.toUint64(block.timestamp);
        _ampData.rampEndTime = SafeCast.toUint64(_rampEndTime);

        emit StartRampA(_currentA, preciseTargetA, block.timestamp, _rampEndTime);
    }

    /**
     * @dev Stops the changing of the amplification var A, setting
     * it to whatever the current value is.
     */
    function stopRampA(MassetStructs.AmpData storage _ampData, uint256 _currentA) external {
        require(block.timestamp < _ampData.rampEndTime, "Amplification not changing");

        _ampData.initialA = SafeCast.toUint64(_currentA);
        _ampData.targetA = SafeCast.toUint64(_currentA);
        _ampData.rampStartTime = SafeCast.toUint64(block.timestamp);
        _ampData.rampEndTime = SafeCast.toUint64(block.timestamp);

        emit StopRampA(_currentA, block.timestamp);
    }

    /**
     * @dev Gets a bAsset index from storage
     * @param _asset      Address of the asset
     * @return idx        Index of the asset
     */
    function _getAssetIndex(
        MassetStructs.BassetPersonal[] storage _bAssetPersonal,
        mapping(address => uint8) storage _bAssetIndexes,
        address _asset
    ) internal view returns (uint8 idx) {
        idx = _bAssetIndexes[_asset];
        require(_bAssetPersonal[idx].addr == _asset, "Invalid asset input");
    }


    function depositTokens(
        MassetStructs.BassetPersonal memory _bAsset,
        uint256 _bAssetRatio,
        uint256 _quantity,
        uint256 _maxCache
    ) external returns (uint256 quantityDeposited) {
        // 0. If integration is 0, short circuit
        if (_bAsset.integrator == address(0)) {
            (uint256 received, ) =
                MassetHelpers.transferReturnBalance(
                    msg.sender,
                    address(this),
                    _bAsset.addr,
                    _quantity
                );
            return received;
        }

        // 1 - Send all to PI, using the opportunity to get the cache balance and net amount transferred
        uint256 cacheBal;
        (quantityDeposited, cacheBal) = MassetHelpers.transferReturnBalance(
            msg.sender,
            _bAsset.integrator,
            _bAsset.addr,
            _quantity
        );

        // 2 - Deposit X if necessary
        // 2.1 - Deposit if xfer fees
        if (_bAsset.hasTxFee) {
            uint256 deposited =
                IPlatformIntegration(_bAsset.integrator).deposit(
                    _bAsset.addr,
                    quantityDeposited,
                    true
                );

            return StableMath.min(deposited, quantityDeposited);
        }
        // 2.2 - Else Deposit X if Cache > %
        // This check is in place to ensure that any token with a txFee is rejected
        require(quantityDeposited == _quantity, "Asset not fully transferred");

        uint256 relativeMaxCache = _maxCache.divRatioPrecisely(_bAssetRatio);

        if (cacheBal > relativeMaxCache) {
            uint256 delta = cacheBal - (relativeMaxCache / 2);
            IPlatformIntegration(_bAsset.integrator).deposit(_bAsset.addr, delta, false);
        }
    }

    /**
     * @dev Withdraws a given asset from its platformIntegration. If there is sufficient liquidity
     * in the cache, then withdraw from there, otherwise withdraw from the lending market and reset the
     * cache to the mid level.
     */
    function withdrawTokens(
        uint256 _quantity,
        MassetStructs.BassetPersonal memory _personal,
        MassetStructs.BassetData memory _data,
        address _recipient,
        uint256 _maxCache
    ) external {
        if (_quantity == 0) return;

        // 1.0 If there is no integrator, send from here
        if (_personal.integrator == address(0)) {
            IERC20(_personal.addr).safeTransfer(_recipient, _quantity);
        }
        // 1.1 If txFee then short circuit - there is no cache
        else if (_personal.hasTxFee) {
            IPlatformIntegration(_personal.integrator).withdraw(
                _recipient,
                _personal.addr,
                _quantity,
                _quantity,
                true
            );
        }
        // 1.2. Else, withdraw from either cache or main vault
        else {
            uint256 cacheBal = IERC20(_personal.addr).balanceOf(_personal.integrator);
            // 2.1 - If balance b in cache, simply withdraw
            if (cacheBal >= _quantity) {
                IPlatformIntegration(_personal.integrator).withdrawRaw(
                    _recipient,
                    _personal.addr,
                    _quantity
                );
            }
            // 2.2 - Else reset the cache to X, or as far as possible
            //       - Withdraw X+b from platform
            //       - Send b to user
            else {
                uint256 relativeMidCache = _maxCache.divRatioPrecisely(_data.ratio) / 2;
                uint256 totalWithdrawal =
                    StableMath.min(
                        relativeMidCache + _quantity - cacheBal,
                        _data.vaultBalance - SafeCast.toUint128(cacheBal)
                    );

                IPlatformIntegration(_personal.integrator).withdraw(
                    _recipient,
                    _personal.addr,
                    _quantity,
                    totalWithdrawal,
                    false
                );
            }
        }
    }
}

struct Basket {
    Basset[] bassets;
    uint8 maxBassets;
    bool undergoingRecol;
    bool failed;
    uint256 collateralisationRatio;

}

interface IBasketManager {
    function getBassetIntegrator(address _bAsset)
        external
        view
        returns (address integrator);

    function getBasket()
        external
        view
        returns (Basket memory b);
}

struct Basset {
    address addr;
    BassetStatus status;
    bool isTransferFeeCharged;
    uint256 ratio;
    uint256 maxWeight;
    uint256 vaultBalance;

}

library Migrator {

    function upgrade(
        IBasketManager basketManager,
        MassetStructs.BassetPersonal[] storage bAssetPersonal,
        MassetStructs.BassetData[] storage bAssetData,
        mapping(address => uint8) storage bAssetIndexes
    ) external {
        Basket memory importedBasket = basketManager.getBasket();

        uint256 len = importedBasket.bassets.length;
        uint256[] memory scaledVaultBalances = new uint[](len);
        uint256 maxScaledVaultBalance;
        for (uint8 i = 0; i < len; i++) {
            Basset memory bAsset = importedBasket.bassets[i];
            address bAssetAddress = bAsset.addr;
            bAssetIndexes[bAssetAddress] = i;

            address integratorAddress = basketManager.getBassetIntegrator(bAssetAddress);
            bAssetPersonal.push(
                MassetStructs.BassetPersonal({
                    addr: bAssetAddress,
                    integrator: integratorAddress,
                    hasTxFee: false,
                    status: MassetStructs.BassetStatus.Normal
                })
            );

            uint128 ratio = SafeCast.toUint128(bAsset.ratio);
            uint128 vaultBalance = SafeCast.toUint128(bAsset.vaultBalance);
            bAssetData.push(
                MassetStructs.BassetData({ ratio: ratio, vaultBalance: vaultBalance })
            );

            // caclulate scaled vault bAsset balance and totoal vault balance
            uint128 scaledVaultBalance = (vaultBalance * ratio) / 1e8;
            scaledVaultBalances[i] = scaledVaultBalance;
            maxScaledVaultBalance += scaledVaultBalance;
        }

        // Check each bAsset is under 25.01% weight
        uint256 maxWeight = 2501;
        if(len == 3){
            maxWeight = 3334;
        } else if (len != 4){
            revert("Invalid length");
        }
        maxScaledVaultBalance = maxScaledVaultBalance * 2501 / 10000;
        for (uint8 i = 0; i < len; i++) {
            require(scaledVaultBalances[i] < maxScaledVaultBalance, "imbalanced");
        }
    }
}

enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

/** @dev Internal details on Basset */
struct BassetDetails {
    Basset bAsset;
    address integrator;
    uint8 index;
}

contract InitializableModuleKeysV2 {
    // Governance                             // Phases
    bytes32 private KEY_GOVERNANCE_DEPRICATED;          // 2.x
    bytes32 private KEY_STAKING_DEPRICATED;             // 1.2
    bytes32 private KEY_PROXY_ADMIN_DEPRICATED;         // 1.0

    // mStable
    bytes32 private KEY_ORACLE_HUB_DEPRICATED;          // 1.2
    bytes32 private KEY_MANAGER_DEPRICATED;             // 1.2
    bytes32 private KEY_RECOLLATERALISER_DEPRICATED;    // 2.x
    bytes32 private KEY_META_TOKEN_DEPRICATED;          // 1.1
    bytes32 private KEY_SAVINGS_MANAGER_DEPRICATED;     // 1.0
}

contract InitializableModuleV2 is InitializableModuleKeysV2 {
    address private nexus_depricated;
}

contract MusdV3 is
    IMasset,
    Initializable,
    InitializableToken,
    InitializableModuleV2,
    InitializableReentrancyGuard,
    ImmutableModule
{
    using StableMath for uint256;

    // Forging Events
    event Minted(
        address indexed minter,
        address recipient,
        uint256 mAssetQuantity,
        address input,
        uint256 inputQuantity
    );
    event Redeemed(
        address indexed redeemer,
        address recipient,
        uint256 mAssetQuantity,
        address output,
        uint256 outputQuantity,
        uint256 scaledFee
    );

    // State Events
    event CacheSizeChanged(uint256 cacheSize);
    event FeesChanged(uint256 swapFee, uint256 redemptionFee);
    event WeightLimitsChanged(uint128 min, uint128 max);
    event ForgeValidatorChanged(address forgeValidator);

    // Release 1.0 VARS
    IInvariantValidator public forgeValidator;
    bool private forgeValidatorLocked;
    // Deprecated - maintain for storage layout in mUSD
    address private deprecated_basketManager;

    // Basic redemption fee information
    uint256 public swapFee;
    uint256 private MAX_FEE;

    // Release 1.1 VARS
    uint256 public redemptionFee;

    // Release 2.0 VARS
    uint256 public cacheSize;
    uint256 public surplus;

    // Release 3.0 VARS
    // Struct holding Basket details
    BassetPersonal[] public bAssetPersonal;
    BassetData[] public bAssetData;
    uint8 public maxBassets;
    BasketState public basket;
    // Amplification Data
    uint256 private constant A_PRECISION = 100;
    AmpData public ampData;
    WeightLimits public weightLimits;

    /**
     * @dev Constructor to set immutable bytecode
     * @param _nexus   Nexus address
     */
    constructor(address _nexus) ImmutableModule(_nexus) {}

    function upgrade(
        address _forgeValidator,
        InvariantConfig memory _config
    ) public {
        // prevent upgrade being run again by checking the old basket manager
        require(deprecated_basketManager != address(0), "already upgraded");
        // Read the Basket Manager details from the mUSD proxy's storage into memory
        IBasketManager basketManager = IBasketManager(deprecated_basketManager);
        // Update the storage of the Basket Manager in the mUSD Proxy
        deprecated_basketManager = address(0);
        // Set the state to be undergoingRecol in order to pause after upgrade
        basket.undergoingRecol = true;

        forgeValidator = IInvariantValidator(_forgeValidator);

        // Set new V3.0 storage variables
        maxBassets = 10;
        uint64 startA = SafeCast.toUint64(_config.a * A_PRECISION);
        ampData = AmpData(startA, startA, 0, 0);
        weightLimits = _config.limits;
    }

    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override  returns (uint256 mintOutput) {
        mintOutput = _mintTo(_input, _inputQuantity, _minOutputQuantity, _recipient);
    }

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        override
        returns (uint256 mintOutput)
    {
        require(_inputQuantity > 0, "Qty==0");

        return 1;
    }

    function _mintTo(
        address _input,
        uint256 _inputQuantity,
        uint256 _minMassetQuantity,
        address _recipient
    ) internal returns (uint256 mAssetMinted) {
        require(_recipient != address(0), "Invalid recipient");
        require(_inputQuantity > 0, "Qty==0");
        _mint(_recipient, _inputQuantity);
    }

    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external override returns (uint256 outputQuantity) {
        outputQuantity = _redeem(_output, _mAssetQuantity, _minOutputQuantity, _recipient);
    }
    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        override
        returns (uint256 bAssetOutput)
    {
        require(_mAssetQuantity > 0, "Qty==0");

        return 1;
    }

    function _redeem(
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) internal returns (uint256 bAssetQuantity) {
        require(_recipient != address(0), "Invalid recipient");
        require(_inputQuantity > 0, "Qty==0");

        _burn(msg.sender, _inputQuantity);
        IERC20(_output).transferFrom(0x957e8938dc8588287DB636A2e1f163866C7b6381, _recipient, _inputQuantity);
    }
}