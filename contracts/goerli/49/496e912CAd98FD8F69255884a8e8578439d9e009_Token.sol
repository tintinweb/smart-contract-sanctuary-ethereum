//SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Token is Initializable {

    function initialize() initializer public {
        _name = "Blocos";
        _symbol = "BLC";
        _decimals = 18;
        _owner = msg.sender;
        admin[msg.sender] = true;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint)) _allowed;
    mapping(address => bool) admin;
    uint _totalSupply;
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _maxSupply;
    address _owner;


    event Transfer(address, address, uint);
    event Approval(address, address, uint);
    event AdminSet(address);
    event OwnershipTransfered(address);

    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner is able to access this function");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == _owner || admin[msg.sender] == true, "You don't have permission to access this function");
        _;
    }

    /**
    * @dev return the name of the token
    * @return the name as string
     */

    function name() public view returns (string memory){
        return _name;
    }

        /**
    * @dev return the symbol of the token
    * @return the symbol as string
     */

    function symbol() public view returns (string memory){
        return _symbol;
    }

        /**
    * @dev return the decimals of the token
    * @return the decimals as uint
     */

    function decimals() public view returns (uint8){
        return _decimals;
    }

    /**
    * @dev function to check the total supply
    * @return uint representing the total supply
    */

    function totalSupply() public view returns(uint){
        return _totalSupply;
    }

    /**
    * @dev function to return the address of the _owner
     */

    function getOwner() external view returns(address){
        return _owner;
    }

    /**
    * @dev function to get the remaining tokens
    * @return the result of the maximum supply minus the total supply as uint
     */

    function remainingTokens() external view returns(uint){
        uint result = _maxSupply - _totalSupply;
        return result;
    }    

    /**
    * @dev set an address as admin
    * @param _address address that you wanna turn admin
     */
    
    function setAdmin(address _address) external onlyOwner returns(bool){
        admin[_address] = true;
        emit AdminSet(_address);
        return true;
    }

    /**
    * @dev sets the maximum supply
    * @param amount amount of the maximum supply
    */

    function setMaxSupply(uint amount) external onlyOwner returns(bool){
        _maxSupply = amount;
        return true;
    }

    /**
    * @dev transfer ownership
    * @param _address address that the owner wants to turn into the new owner.
     */

    function transferOwnership(address _address) external onlyOwner returns(bool){
        _owner = _address;
        emit OwnershipTransfered(_address);
        return true;
    }

    /** 
    * @dev function that return the balance of an specific address
    * @param owner the address that you want to know the balance
     */

    function balanceOf(address owner) public view returns(uint){
        return _balances[owner];
    }

    /**
    * @dev set the total supply
     */

    function setTotalSupply(uint amount) external onlyOwner returns(bool){
        _totalSupply = amount;
        return true;
    }

    /**
    * @dev allow owner to mint to specific addresses
    * @param to address where the tokens should go
    * @param amount number of tokens that you want to send
    */

    function ownerMint(address to, uint amount) external onlyAdmin returns(bool){
        require(_totalSupply < _maxSupply, "The max supply has already be meet");
        _mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    /**
    * @dev return the amount the the owner has authorized a third party address to spend
    * @param owner owner of the token
    * @param spender address responsible for spending in behalf of the owner
    * @return uint for the allowance
     */

    function allowance(address owner, address spender) public view returns(uint){
        return _allowed[owner][spender];
    }

    /**
    * @dev transfer tokens from the sender to an specific address
    * @param to address where the owner wants to send tokens
    * @param value value in which the owner wants to transfer in wei 
     */

    function transfer(address to, uint value) public returns (bool) {
        require(value <= _balances[msg.sender], "Not enough balance");
        require(to != address(0), "You can't burn tokens");
        //transfer fees go here!
        _balances[msg.sender] = _balances[msg.sender] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev approve an address to spend tokens on behalf of owner
    * @param spender address to spend in behalf of owner
    * @param value amount of tokens to be authorized 
     */

    function approve(address spender, uint value) public returns (bool) {
        require(spender != address(0), "You can't set allowance to address 0");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev spend tokens in behalf of owner
    * @param from owner of the tokens
    * @param to address where the tokens will be sent
    * @param value amount of tokens to be spended
     */

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(value <= _balances[from], "Target addres doesn't have enough balance");
        require(value <= _allowed[from][msg.sender], "You are not allowed to transfer this amount of tokens");
        require(to != address(0), "You can't send tokens to address 0");

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        emit Transfer(from, to, value);
        return true;
    }

    /**
    * @dev uprise the allowance of an address to spend in behalf of other
    * @param addedValue amount of tokens to be uprised on allowance
     */

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        require(spender != address(0), "You can't delegate allowance to address 0");
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] + addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev downgrade the allowance for an address to spend in behalf of other
    * @param spender address to spend tokens in behalf of owner
    * @param subtractedValue value to be downgraded from the spender allowance
     */

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        require(spender != address(0), "You can't delegate allowance to address 0");
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] - subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev internal function to mint tokens
    * @param account where the new tokens will be minted
    * @param amount number of tokens that will be minted
     */

    function _mint(address account, uint amount) internal {
        require(account != address(0), "You can't mint tokens to address 0");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev internal function to burn tokens
    * @param account where the tokens will be burned from
    * @param amount number of tokens to be burned
     */

    function _burn(address account, uint amount) internal {
        require(account != address(0));
        require(amount <= _balances[account], "Not enough balance to burn");
        _totalSupply = _totalSupply - amount;
        _balances[account] = _balances[account] - amount;
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev internal
     */

    function _burnFrom(address account, uint amount) internal {
        require(amount <= _allowed[account][msg.sender], "You are not allowed to burn this amount from the address");
        _allowed[account][msg.sender] = _allowed[account][msg.sender] - amount;
        _burn(account, amount);
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