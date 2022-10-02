/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: AGPL-3.0-only
// File: @openzeppelin/contracts/utils/Address.sol
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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/OwnableKeepable.sol


// Based on OpenZeppelin's Ownable contract. Adds 'keeper' for non-multisig tasks.
pragma solidity >=0.8.0;

abstract contract Ownable is Context {
    address private _owner;
    address public keeper;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event KeeperTransferred(address indexed previousKeeper, address indexed newKeeper);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
	//transfer to non 0 addy during constructor when deploying 4real to prevent our base contracts being taken over. Ensures only our proxy is usable
    //Since proxies are not initialized
        //_transferOwnership(address(~uint160(0)));
        _transferOwnership(address(uint160(0)));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "TipsyOwnable: caller is not the owner");
        _;
    }

    modifier onlyOwnerOrKeeper()
    {
      require(owner() == _msgSender() || keeper == _msgSender(), "TipsyOwnable: caller is not the owner or not a keeper");   
      _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0x000000000000000000000000000000000000dEaD));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferKeeper(address _newKeeper) external virtual onlyOwner {
        require(_newKeeper != address(0), "Ownable: new Keeper is the zero address");
        emit KeeperTransferred(keeper, _newKeeper);
        keeper = _newKeeper;
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

    function initOwnership(address newOwner) public virtual {
        require(_owner == address(0), "Ownable: owner already set");
        require(newOwner != address(0), "Ownable: new owner can't be 0 address");
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }
}
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
// File: contracts/Solmate_modified.sol


pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Gin (https://github.com/TipsyCoin/TipsyGin/), modified from Solmate
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @author CheckNSignature function and SplitsSigs from Gnosis Safe. (https://github.com/safe-global/safe-contracts/blob/main/contracts/GnosisSafe.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
/// In the interests of general openness, we prefer vars that are safe to be made public, are

abstract contract SolMateERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, address indexed from, uint256 amount);
    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    string public constant name = "Gin";
    string public constant symbol = "$gin";
    uint8 public constant decimals = 18;
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 internal INITIAL_CHAIN_ID;
    //These can't be immutable in upgradeable proxy pattern
    //We also want to reuse contract address accross multiple chain ...
    //So deployed bytecode must be identical == can't do consts for init chain id, etc
    bytes32 public INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;
    /*//////////////////////////////////////////////////////////////
                            GIN EXTRA
    //////////////////////////////////////////////////////////////*/
    mapping(address => bool) public mintSigners;
    mapping(address => bool) public contractMinters;
    uint8 public constant MIN_SIGS = 2;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    //Changed to initialize for upgrade purposes.

    /*//////////////////////////////////////////////////////////////
                             EXTRA GIN STUFF
    //////////////////////////////////////////////////////////////*/
    function _addContractMinter(address _newSigner) internal virtual returns (bool) {
        //require (msg.sender == address(this), "Only internal calls, please"); 
        uint size;
        assembly {
            size := extcodesize(_newSigner)
        }
        require(size > 0, "CONTRACTMINTER_NOT_CONTRACT");
        contractMinters[_newSigner] = true;
        return true;
    }

    function _removeContractMinter(address _removedSigner) internal virtual returns (bool) {
        contractMinters[_removedSigner] = false;
        return true;
    }

        function _addMintSigner(address _newSigner) internal virtual returns (bool) {
        //require (msg.sender == address(this), "Only internal calls, please"); 
        uint size;
        assembly {
            size := extcodesize(_newSigner)
        }
        require(size == 0, "SIGNER_NOT_EOA");
        mintSigners[_newSigner] = true;
        return true;
    }

    function _removeMintSigner(address _removedSigner) internal virtual returns (bool) {
        mintSigners[_removedSigner] = false;
        return true;
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

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
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
                            GNOSIS-SAFE MULTISIG CHECK
                            Modified from here:
    (https://github.com/safe-global/safe-contracts/blob/main/contracts/GnosisSafe.sol)
    //////////////////////////////////////////////////////////////*/
    function checkNSignatures(address minter, bytes32 dataHash, uint8 _requiredSigs, bytes memory signatures) public view returns (bool) {
        // Check that the provided signature data is not too short
        require(signatures.length == _requiredSigs * 65, "SIG_LENGTH_COUNT_MISMATCH");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        uint8 minterCount = 0;

        for (i = 0; i < _requiredSigs; i++) {
            //Split the bytes into signature data. v is only 1 byte long. r and s are 32 bytes
            (v, r, s) = signatureSplit(signatures, i);
            require (v == 27 || v == 28, "ZIPD_OR_CONTRACT_KEY_UNSUPPORTED");
            currentOwner = ecrecover(dataHash, v, r, s);
            //Keys must be supplied in increasing public key order. Gas savings.
            require(currentOwner > lastOwner && mintSigners[currentOwner] == true, "SIG_CHECK_FAILED");

            if (currentOwner == minter) minterCount++;
            lastOwner = currentOwner;
            
            }

        require(minterCount == 1, "MINTER_NOT_IN_SIG_SET");
        return true;
        }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    /// Sourced from here: https://github.com/safe-global/safe-contracts/blob/main/contracts/GnosisSafe.sol
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns
            (uint8 v,
            bytes32 r,
            bytes32 s) {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 PERMIT
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
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

    function computeDomainSeparator() public view virtual returns (bytes32) {
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
// File: contracts/final_gin.sol


pragma solidity >=0.8.0;





//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Gin is SolMateERC20, Ownable, Pausable, Initializable
{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event ChainSupport(uint indexed chainId, bool indexed supported);
    event ContractPermission(address indexed contractAddress, bool indexed permitted);
    event SignerPermission(address indexed signerAddress, bool indexed permitted);
    event RequiredSigs(uint8 indexed oldAmount, uint8 indexed newAmount);
    event Deposit(address indexed from, uint256 indexed amount, uint256 sourceChain, uint256 indexed toChain);
    event Withdrawal(address indexed to, uint256 indexed amount, bytes32 indexed depositID);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => bool) public supportedChains;
    uint8 public requiredSigs;

    /*//////////////////////////////////////////////////////////////
                                INITILALIZATION
    //////////////////////////////////////////////////////////////*/

    //Testing Only
    /*
    function _testInit() external {
        initialize(msg.sender, msg.sender, address(this));
        permitSigner(address(msg.sender));
        permitSigner(address(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf));//this is the address for the 0x000...1 priv key
        permitSigner(address(0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF));//this is the address for the 0x000...2 priv key
    }*/

    function initialize(address _keeper, address _stakingContract) public initializer {
            require(decimals == 18, "Init: Const check DECIMALS");
            require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Gin")), "Init: Const check NAME");
            require(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("$gin")), "Init: Const check SYMBOL");
            require(MIN_SIGS == 2, "Init: Const check SIGS");
            require(_keeper != address(0), "Init: keeper can't be 0 address");
            keeper = _keeper;
            //Owner will be sent to the gnosis safe listed in readme multisig once contract is configured
            initOwnership(msg.sender);
            INITIAL_CHAIN_ID = block.chainid;
            INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
            setRequiredSigs(MIN_SIGS);
            //Use address 0 for chains that don't have staking contract deployed
            if (_stakingContract != address(0)) permitContract(_stakingContract);
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVILAGED
    //////////////////////////////////////////////////////////////*/

    function permitContract(address _newSigner) public onlyOwner returns (bool) {
        emit ContractPermission(_newSigner, true);
        return _addContractMinter(_newSigner);
    }

    function permitSigner(address _newSigner) public onlyOwner returns (bool) {
        emit SignerPermission(_newSigner, true);
        return _addMintSigner(_newSigner);
    }

    function revokeSigner(address _newSigner) public onlyOwnerOrKeeper returns (bool) {
        emit SignerPermission(_newSigner, false);
        return _removeMintSigner(_newSigner);
    }
    //This one is only owner, because it could break Tipsystake.
    function revokeContract(address _newSigner) public onlyOwner returns (bool) {
        emit ContractPermission(_newSigner, false);
        return _removeContractMinter(_newSigner);
    }

    function setRequiredSigs(uint8 _numberSigs) public onlyOwner returns (uint8) {
        require(_numberSigs >= MIN_SIGS, "SIGS_BELOW_MINIMUM");
        emit RequiredSigs(requiredSigs, _numberSigs);
        requiredSigs = _numberSigs;
        return _numberSigs;
    }

    function setSupportedChain(uint256 _chainId, bool _supported) external onlyOwnerOrKeeper returns(uint256, bool) {
        require(_chainId != block.chainid, "TO_FROM_CHAIN_IDENTICTAL");
        supportedChains[_chainId] = _supported;
        emit ChainSupport(_chainId, _supported);
        return (_chainId, _supported);
    }

    function setPause(bool _paused) external onlyOwnerOrKeeper {
        if (_paused == true) _pause();
        else _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                TIPSYSTAKE INTEGRATION
    //////////////////////////////////////////////////////////////*/
    function mintTo(address _to, uint256 _amount) public whenNotPaused returns (bool) {
        require(contractMinters[msg.sender] == true, "MINTTO_FOR_TIPSYSTAKE_CONTRACTS_ONLY");
        _mint(_to, _amount);
        emit Mint(msg.sender, _to, _amount);
        return true; //return bool required for our staking contract to function
    }

    /*//////////////////////////////////////////////////////////////
                                BRIDGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    //Deposit from address to the given chainId. Our bridge will pick the Deposit event up and MultisigMint on the associated chain
    //Checks to ensure chainId is supported (ensure revent when no supported chainIds before bridge is live)
    //Does a standard transferFrom to ensure user approves this contract first. (Prevent accidental deposit, since this method is destructive to tokens)
    //Likely to use ChainID 0 to indicate tokens should be transfered to our game server
    function deposit(uint256 _amount, uint256 toChain) external whenNotPaused returns (bool) {
        require(supportedChains[toChain], "CHAIN_NOTYET_SUPPORTED");
        require(transferFrom(msg.sender, address(this), _amount), "DEPOSIT_FAILED_CHECK_BAL_APPROVE");
        _burn(address(this), _amount);
        emit Deposit(msg.sender, _amount, block.chainid, toChain);
        return true;
    }

    //MultiSig Mint. Used so server/bridge can sign messages off-chain, and transmit via relay network
    //Also used by the game. So tokens can be minted from the game without user paying gas
    function multisigMint(address minter, address to, uint256 amount, uint256 deadline, bytes32 _depositHash, bytes memory signatures) external whenNotPaused returns(bool) {
        require(deadline >= block.timestamp, "MINT_DEADLINE_EXPIRED");
        bytes32 dataHash;
        dataHash =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "multisigMint(address minter,address to,uint256 amount,uint256 nonce,uint256 deadline,bytes32 _depositHash,bytes signatures)"
                            ),
                            minter,
                            to,
                            amount,
                            nonces[minter]++,
                            deadline,
                            _depositHash
                        )
                    )
                )
            );
        checkNSignatures(minter, dataHash, requiredSigs, signatures);
        _mint(to, amount);
        emit Withdrawal(to, amount, _depositHash);
        return true;
    }

}