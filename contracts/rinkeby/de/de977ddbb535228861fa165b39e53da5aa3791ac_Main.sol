/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// import "hardhat/console.sol";
pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external pure returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract Main is IBEP20, Auth, Initializable {
    address constant DEAD = address(0xdead);
    address constant ZERO = address(0);

    string constant _name = "TTH";
    string constant _symbol = "TTH";
    uint8 constant _decimals = 18;

    uint256 constant _totalSupply = 1 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount;

    //max wallet holding of 2%
    uint256 public _maxWalletToken;

    mapping (address => bool) public whitelisted;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 public totalFee; //Total Fee
    uint256 public constant feeDenominator = 100;

    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public developmentFee;
    uint256 public burnFee;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public developmentFeeReceiver;

    bool public tradingOpen;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize ()  external initializer  {

        owner = msg.sender;
        authorizations[msg.sender] = true;

        _maxTxAmount = ( _totalSupply * 1 )  / 200;
        _maxWalletToken = ( _totalSupply * 2 ) / 100;

        liquidityFee = 0;
        marketingFee = 0;
        developmentFee = 0;
        burnFee = 0;

        totalFee = 0; //Total Fee
        tradingOpen = false;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        developmentFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) public view override returns (uint256) { return _allowances[holder][spender]; }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue );
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return _transferFrom(sender, recipient, amount);
    }

    event OnSetMaxWalletPercent(uint256 maxWallPercent);
    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
        emit OnSetMaxWalletPercent(_maxWalletToken);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        // max wallet code
        if (!authorizations[sender]
        && !whitelisted[sender]
        && !whitelisted[recipient]
        && recipient != address(this)
        && recipient != address(DEAD)
        && recipient != marketingFeeReceiver
        && recipient != developmentFeeReceiver
        && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);

            uint256 maxWalletCheck = amount - amount*totalFee/feeDenominator;
            require((heldTokens + maxWalletCheck) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");

            // Checks max transaction limit
            _checkTxLimit(sender, amount);
        }

        //Exchange tokens
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = _shouldTakeFee(sender) ? _takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;



        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function _shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function _takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount*totalFee/feeDenominator;
        uint256 burnAmount = amount*burnFee/feeDenominator;
        uint256 tToMarketing = amount*marketingFee/feeDenominator;
        uint256 tToDevelopment = amount*developmentFee/feeDenominator;
        uint256 tToLiquidity = amount*liquidityFee/feeDenominator;

        _balances[address(marketingFeeReceiver)] = _balances[address(marketingFeeReceiver)] + tToMarketing;
        _balances[address(developmentFeeReceiver)] = _balances[address(developmentFeeReceiver)] + tToDevelopment;
        _balances[address(autoLiquidityReceiver)] = _balances[address(autoLiquidityReceiver)] + tToLiquidity;
        _balances[address(DEAD)] = _balances[address(DEAD)] + burnAmount;

        emit Transfer(sender, address(this), feeAmount);
        emit Transfer(address(this), address(DEAD), burnAmount);
        emit Transfer(address(this), autoLiquidityReceiver, tToLiquidity);
        emit Transfer(address(this), developmentFeeReceiver, tToDevelopment);
        emit Transfer(address(this), marketingFeeReceiver, tToMarketing);

        return amount - feeAmount;
    }

    // switch Trading
    event OnTradingStatus(bool _status);
    function tradingStatus(bool _status) external onlyOwner {
        tradingOpen = _status;
        emit OnTradingStatus(_status);
    }

    event OnSetTxLimit(uint256 amount);
    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
        emit OnSetTxLimit(amount);
    }

    event OnSetIsFeeExempt(address holder, bool exempt);
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
        emit OnSetIsFeeExempt(holder, exempt);
    }

    event OnSetIsTxLimitExempt(address holder, bool exempt);
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
        emit OnSetIsTxLimitExempt(holder, exempt);
    }


    event OnSetFees(uint256 _liquidityFee,
        uint256 _marketingFee,uint256 _developmentFee,uint256 _burnFee);
    function setFees(uint256 _liquidityFee,
        uint256 _marketingFee,uint256 _developmentFee,uint256 _burnFee) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        developmentFee = _developmentFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee+_marketingFee+_developmentFee+_burnFee;
        require(totalFee < feeDenominator, "invalid amount of fee");
        require(totalFee < 10, "invalid amount of totalFee");
        emit OnSetFees(_liquidityFee, _marketingFee, _developmentFee, _burnFee);
    }

    event OnSetFeeReceivers(address _marketingFeeReceiver, address _developmentFeeReceiver);
    function setFeeReceivers(address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _developmentFeeReceiver
    ) external authorized {
        require( _autoLiquidityReceiver != address(0), "invalid address");
        require( _marketingFeeReceiver != address(0), "invalid address");
        require( _developmentFeeReceiver != address(0), "invalid address");
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        developmentFeeReceiver = _developmentFeeReceiver;
        emit OnSetFeeReceivers(_marketingFeeReceiver, _developmentFeeReceiver);
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply-balanceOf(DEAD)-balanceOf(ZERO);
    }

    /* Airdrop Begins */
    event onAirdrop();
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {

        uint256 SCCC = 0;

        require(addresses.length == amounts.length,"Mismatch between Address and token count");

        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + amounts[i];
        }

        require(balanceOf(msg.sender) >= SCCC, "Not enough tokens to airdrop");

        for(uint i=0; i < addresses.length; i++){
            transferFrom(msg.sender, addresses[i], amounts[i]);
        }
        emit onAirdrop();
    }

    event OnRescueToken(address tokenAddress, uint256 tokens);
    function rescueToken(address tokenAddress, uint256 tokens)
    external
    onlyOwner
    returns (bool success)
    {
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
        emit OnRescueToken(tokenAddress, tokens);
    }

    event OnClearStuckBalance(uint256 amountPercentage, address adr);
    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        require( adr != address(0), "invalid address");
        payable(adr).call{value: address(this).balance}("");
        emit OnClearStuckBalance(amountPercentage, adr);
    }

    event OnSetWhitelisted(address _wallet, bool status);
    function setWhitelisted(address _wallet, bool status) external onlyOwner {
        whitelisted[_wallet] = status;
        emit OnSetWhitelisted(_wallet, status);
    }

}