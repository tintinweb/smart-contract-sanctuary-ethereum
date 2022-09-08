// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";



interface IBank {
    function deposit() external payable;
}




/// @title A title that should describe the contract/interface
/// @author developeruche
contract MultiSigWallet is Initializable {


    // CUSTOM ERRORS


    /// Wallet has not been Intialized
    error HasNotBeenInitialized();

    /// A base wallet contract cannot call Initalize
    error CannotCallInitalized();

    /// Invalid Number Of Comfirmation
    error InvalidNumberOfComfirmation();

    /// Owners Cannot Be Empty
    error OwnersCannotBeEmpty();

    /// Invalid Owner Address
    error InvalidOwnerAddress();

    /// Owners must be unique
    error OwnersMustBeUnique();

    /// Contract Already Initialized 
    error ContractAlreadyInitailized();

    /// You are not a owner in this wallet
    error NotPartOfOwners();

    /// Transaction Does not exist
    error TransactionDoesNotExist();

    /// Transaction has been excecuted
    error TransactionHasBeenExcecuted();

    /// You have already confirmed this transaction
    error YouHaveAlreadyConfirmedThisTransaction();

    /// Invalid amount of ether was passed to the function
    error InvalidAmountOfEther();

    /// Cannot perform this transaction consensus has not been raised
    error ConsensusHasNotBeenRaised(); 

    /// Oops... Transaction failed
    error TransactionFailed();

    /// Transaction has not been signed
    error TransactionHasNotBeenSigned();





    // EVENTS



    /// @dev this event would be logged when a deposit is  made
    event Deposit(address indexed sender, uint256 amount);
    /// @dev this event would be logged when a transaction is submitted by any of the owner
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data,
        string topic
    );
    /// @dev this event would be logged when a tranaction is confirmed
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    /// @dev this event would be logged when a transaction is terminated
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    /// @dev this would be logged when a transaction is finally excuted
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex, bytes data);


    //STATE VARIABLES



    /// @dev this is the nubmer of comfirmations need before a transaction would go through
    uint256 public numConfirmationsRequired;    
    bool public isBase;
    bool private isInitialized;
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
        string topic;
    }

    /// @dev this array hold the list of owner in this contract
    address[] public owners;
    /// @dev this mapping would be used to see if an address is part of the user (i am using a mapping because it is EFFICENT)
    mapping(address => bool) public isOwner;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    /// @dev storing all the transaction in an array
    Transaction[] public transactions;
    /// @dev this variable holds the contract address of the bank contract used to manage funds
    address bank;


    // MODIFERS


    modifier onlyOwner() {
        if(!isOwner[msg.sender]){
            revert NotPartOfOwners();
        }
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if(_txIndex >= transactions.length){
            revert TransactionDoesNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if(transactions[_txIndex].executed) {
            revert TransactionHasBeenExcecuted();
        }
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if(isConfirmed[_txIndex][msg.sender]) {
            revert YouHaveAlreadyConfirmedThisTransaction();
        }
        _;
    }

    modifier shouldBeInit() {
        if(!isInitialized) {
            revert HasNotBeenInitialized();
        }
        _;
    }

    modifier cantInitBase() {
        if(isBase) {
            revert CannotCallInitalized();
        }
        _;
    }



    // CONSTRUCTOR

    constructor() {
        isBase = true;
    }



    /// @dev this function would push new transactions to the transactons array 
    /// @param _to: this is the address that the low level call would be sent to
    /// @param _value: this is the amount of ether that would be passed to the low level transaction call when the transaction have been excecuted
    /// @param _data: this is the low level representation of the transaction which would be passed to the .call method to the _to address
    function submitTransaction (
        address _to,
        uint256 _value,
        bytes memory _data, // this would be a function signature
        string memory _topic
    ) shouldBeInit public payable onlyOwner {

        uint256 txIndex = transactions.length;

        if(msg.value != _value) {
            revert InvalidAmountOfEther();
        }

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                topic: _topic
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data, _topic);
    }

    /// @dev using this function, a user can consent to a transaction that has been submited
    /// @param _txIndex: this is the transaction index
    function confirmTransaction(uint256 _txIndex)
        public
        shouldBeInit
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// @dev here the transaction would be excuted
    /// @notice the transaction can only be excecuted is the number of quorum is satified!!
    /// @param _txIndex: this is the index of the transaction that is to be excecuted
    function executeTransaction(uint256 _txIndex)
        public
        payable
        shouldBeInit
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        returns (bytes memory)
    {
        Transaction storage transaction = transactions[_txIndex];


        if(transaction.numConfirmations < numConfirmationsRequired) {
            revert ConsensusHasNotBeenRaised();
        }


        transaction.executed = true;

        (bool success, bytes memory data) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        if(!success) {
            revert TransactionFailed();
        }
        

        emit ExecuteTransaction(msg.sender, _txIndex, data);

        return data;
    }

    /// @dev using this function, the user can cancel the revoke his/her vote given to a transaction
    /// @param _txIndex: this is the index of the tranaction to be revoked
    function revokeConfirmation(uint256 _txIndex)
        public
        shouldBeInit
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {

        if(!isConfirmed[_txIndex][msg.sender]) {
            revert TransactionHasNotBeenSigned();
        }

        Transaction storage transaction = transactions[_txIndex];        

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /// @dev this is a function to return all the owners in a wallet quorum
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @dev obtaining the length of the transactions of the wallet
    function getTransactionCount() public view shouldBeInit returns (uint256) {
        return transactions.length;
    }

    /// @dev this function would return a transaction on input of the transaction id
    /// @param _txIndex: this is the id of the transaction to be returned
    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }


    /// @dev this function is meant for owners to qurey the balance of the contract
    function getWalletBalance()
        public
        view
        returns (
            uint256
        )
    {
        return address(this).balance;
    }


    /// @dev this function would return all the transaction
    function returnTransaction() 
        public
        view  
        returns (
            Transaction[] memory
        ) {
            return transactions;
        }

    /// @dev this is acting as the constructor (because this contract is implemented using the EIP-1167) (this function can only run once and it must be on deployment)
    function initialize(address[] memory _owners, uint256 _numConfirmationsRequired, address _bank) 
        public 
        cantInitBase 
    {

        // the input owner must be more than zero
        if (_owners.length <= 0) {
            revert OwnersCannotBeEmpty();
        }

        // require the number of comfirmation is not greater than the number of owners
        if(_numConfirmationsRequired < 0 || _numConfirmationsRequired >= _owners.length) {
            revert InvalidNumberOfComfirmation();
        }

        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];


            if(owner == address(0)) {
                revert InvalidOwnerAddress();
            }

            if(isOwner[owner]) {
                revert OwnersMustBeUnique();
            }

            isOwner[owner] = true;
            owners.push(owner);
        }

        if(isInitialized) {
            revert ContractAlreadyInitailized();
        }

        numConfirmationsRequired = _numConfirmationsRequired;

        bank = _bank;

        isInitialized = true;
    }

        /// @dev I am creating a function that would enable the contract recieve ether: Note: because this function is not supposed to recieve ether when funds is transfered to this contract, it would be redirected to the bank contract where anything related to money would be done 
    receive() external payable {
      // sending the funds to the bank contract
      IBank(bank).deposit{value: msg.value}();
    }
}
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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