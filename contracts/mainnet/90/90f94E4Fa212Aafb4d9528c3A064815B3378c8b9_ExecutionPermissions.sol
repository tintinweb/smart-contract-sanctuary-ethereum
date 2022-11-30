// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

/* prettier-ignore */
import {
    IExecutionPermissions_Events,
    IExecutionPermissions_Functions,
    BatchPermissionEntry
} from "./interfaces/IExecutionPermissions.sol";

import { IOwnable } from "./interfaces/IOwnable.sol";

/// @title Utility contract for setting/enforcing execution permissions per function
/// @author S0AndS0
/// @custom:link https://github.com/solidity-utilities/execution-permissions
/// @dev See {IExecutionPermissions}
contract ExecutionPermissions is
    IExecutionPermissions_Events,
    IExecutionPermissions_Functions
{
    /// Map contract to function target to caller to permission
    /// @dev See {IExecutionPermissions_Variables-permissions}
    mapping(address => mapping(bytes4 => mapping(address => bool)))
        public permissions;

    /// Map contract to registered state
    /// @dev See {IExecutionPermissions_Variables-registered}
    mapping(address => bool) public registered;

    /// Store current owner of this contract instance
    /// @dev See {IExecutionPermissions_Variables-owner}
    address public owner;

    /// Store address of possible new owner of this contract instance
    /// @dev See {IExecutionPermissions_Variables-nominated_owner}
    address public nominated_owner;

    ///
    constructor() {
        owner = msg.sender;
        emit OwnershipClaimed(address(0), msg.sender);
    }

    /*************************************************************************/
    /* Modifiers */
    /*************************************************************************/

    modifier onlyRegistered() {
        require(
            registered[msg.sender],
            "ExecutionPermissions: instance not registered"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "ExecutionPermissions: caller not owner");
        _;
    }

    /*************************************************************************/
    /* Views */
    /*************************************************************************/

    /// @dev See {IExecutionPermissions_Functions-isPermitted}
    /// @inheritdoc IExecutionPermissions_Functions
    function isPermitted(bytes4 target, address caller)
        external
        view
        virtual
        override
        onlyRegistered
        returns (bool)
    {
        return permissions[msg.sender][target][caller];
    }

    /// @dev See {IExecutionPermissions_Functions-isPermitted}
    /// @inheritdoc IExecutionPermissions_Functions
    function isPermitted(string memory target, address caller)
        external
        view
        virtual
        override
        onlyRegistered
        returns (bool)
    {
        return
            permissions[msg.sender][bytes4(keccak256(bytes(target)))][caller];
    }

    /*************************************************************************/
    /* Mutations */
    /*************************************************************************/

    /// @dev See {IExecutionPermissions_Functions-setBatchPermission}
    /// @inheritdoc IExecutionPermissions_Functions
    function setBatchPermission(BatchPermissionEntry[] memory entries)
        external
        payable
        virtual
        override
        onlyRegistered
    {
        uint256 length = entries.length;
        BatchPermissionEntry memory entry;
        for (uint256 i; i < length; ) {
            entry = entries[i];
            permissions[msg.sender][entry.target][entry.caller] = entry.state;

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IExecutionPermissions_Functions-setTargetPermission}
    /// @inheritdoc IExecutionPermissions_Functions
    function setTargetPermission(
        bytes4 target,
        address caller,
        bool state
    ) external payable virtual override onlyRegistered {
        permissions[msg.sender][target][caller] = state;
    }

    /// @dev See {IExecutionPermissions_Functions-setRegistered}
    /// @inheritdoc IExecutionPermissions_Functions
    function setRegistered(bool state) external payable virtual override {
        require(
            msg.sender.code.length > 0,
            "ExecutionPermissions: instance not initialized"
        );

        registered[msg.sender] = state;
    }

    /// @dev See {IExecutionPermissions_Functions-setRegistered}
    /// @inheritdoc IExecutionPermissions_Functions
    function setRegistered(address ref, bool state)
        external
        payable
        virtual
        override
    {
        require(
            ref.code.length > 0,
            "ExecutionPermissions: instance not initialized"
        );

        address refOwner;
        try IOwnable(ref).owner() returns (address result) {
            refOwner = result;
        } catch {
            revert(
                "ExecutionPermissions: instance does not implement `.owner()`"
            );
        }

        require(
            msg.sender == refOwner,
            "ExecutionPermissions: not instance owner"
        );

        registered[ref] = state;
    }

    /// @dev See {IExecutionPermissions_Functions-tip}
    /// @inheritdoc IExecutionPermissions_Functions
    function tip() external payable virtual override {}

    /*************************************************************************/
    /* Administration */
    /*************************************************************************/

    /// @dev See {IExecutionPermissions_Functions-withdraw}
    /// @inheritdoc IExecutionPermissions_Functions
    function withdraw(address to, uint256 amount)
        external
        payable
        virtual
        override
        onlyOwner
    {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "ExecutionPermissions: transfer failed");
    }

    /// @dev See {IExecutionPermissions_Functions-nominateOwner}
    /// @dev See {IExecutionPermissions_Events-OwnerNominated}
    /// @inheritdoc IExecutionPermissions_Functions
    function nominateOwner(address newOwner)
        external
        payable
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "ExecutionPermissions: new owner cannot be zero address"
        );

        nominated_owner = newOwner;
        emit OwnerNominated(owner, newOwner);
    }

    /// @dev See {IExecutionPermissions_Functions-claimOwnership}
    /// @dev See {IExecutionPermissions_Events-OwnershipClaimed}
    /// @inheritdoc IExecutionPermissions_Functions
    function claimOwnership() external payable virtual override {
        require(
            nominated_owner != address(0),
            "ExecutionPermissions: new owner cannot be zero address"
        );

        require(
            nominated_owner == msg.sender,
            "ExecutionPermissions: sender not nominated"
        );

        address previousOwner = owner;
        owner = msg.sender;
        emit OwnershipClaimed(previousOwner, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @dev See {@openzeppelin/contracts/access/Ownable.sol}
interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev See {Ownable-owner}
    function owner() external view returns (address);

    /// @dev See {Ownable-renounceOwnership}
    function renounceOwnership() external payable;

    /// @dev See {Ownable-transferOwnership}
    function transferOwnership(address newOwner) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

/// @custom:property target Function ID to check
/// @custom:property caller Original `msg.sender` of targeted function
/// @custom:property state Value to assign for function caller interaction
struct BatchPermissionEntry {
    bytes4 target;
    address caller;
    bool state;
}

/// @title Describe events contract may produce
/// @dev See {IExecutionPermissions}
interface IExecutionPermissions_Events {
    /// Log attempt to transfer ownership of contract instance
    ///
    /// @param from Current owner of contract
    /// @param to Address of possible new contract owner
    event OwnerNominated(address indexed from, address indexed to);

    /// Log ownership transfer completion
    ///
    /// @param from Previous owner of contract
    /// @param to New owner of contract
    event OwnershipClaimed(address indexed from, address indexed to);
}

/// @title Describe available functions
/// @dev See {IExecutionPermissions}
interface IExecutionPermissions_Functions {
    /*************************************************************************/
    /* Views on-chain */
    /*************************************************************************/

    /// Check execution permissions of target function for given caller
    ///
    /// @param target Function ID to check
    /// @param caller Original `msg.sender` of targeted function
    ///
    /// @custom:throws "ExecutionPermissions: instance not registered"
    ///
    /// @custom:examples
    ///
    /// ```solidity
    /// import {
    ///     IExecutionPermissions
    /// } from "./contracts/interfaces/IExecutionPermissions.sol";
    ///
    /// contract ExampleUsage {
    ///     /* ... */
    ///
    ///     address public refPermissions;
    ///
    ///     /* ... */
    ///
    ///     constructor(address _refPermissions) {
    ///         /* ... */
    ///         refPermissions = _refPermissions;
    ///     }
    ///
    ///     modifier onlyPermitted() {
    ///         require(
    ///             IExecutionPermissions(refPermissions).isPermitted(
    ///                 bytes4(msg.data),
    ///                 msg.sender
    ///             ),
    ///             "ExampleUsage: sender not permitted"
    ///         );
    ///         _;
    ///     }
    ///
    ///     function restricted() external onlyPermitted {
    ///         /* ... */
    ///     }
    ///
    ///     /* ... */
    /// }
    /// ```
    function isPermitted(bytes4 target, address caller)
        external
        view
        returns (bool);

    /// Check execution permissions of target function for given caller
    ///
    /// @param target Function signature to check
    /// @param caller Original `msg.sender` of targeted function
    ///
    /// @dev Note will cost more gas than `isPermitted(bytes4,address)` due to
    ///      implicit conversion of function signature string to ID
    ///
    /// @custom:throws "ExecutionPermissions: instance not registered"
    ///
    /// @custom:examples
    ///
    /// ```solidity
    /// import {
    ///     IExecutionPermissions
    /// } from "./contracts/interfaces/IExecutionPermissions.sol";
    ///
    /// contract ExampleUsage {
    ///     /* ... */
    ///
    ///     address public refPermissions;
    ///
    ///     /* ... */
    ///
    ///     constructor(address _refPermissions) {
    ///         /* ... */
    ///         refPermissions = _refPermissions;
    ///     }
    ///
    ///     function restricted() external {
    ///         string memory target = "restricted()";
    ///         address caller = msg.sender;
    ///         require(isPermitted(target, caller), "Not permitted");
    ///         /* ... */
    ///     }
    ///
    ///     /* ... */
    /// }
    /// ```
    function isPermitted(string memory target, address caller)
        external
        view
        returns (bool);

    /*************************************************************************/
    /* Mutations */
    /*************************************************************************/

    /// Assign multiple permission entries in one transaction
    ///
    /// @param entries List of permissions to assign
    ///
    /// @dev Note may cost less gas due to fewer initialization transaction
    ///      fees of multiple `setTargetPermission(bytes4,address,bool)` calls
    ///
    /// @custom:throws "ExecutionPermissions: instance not registered"
    ///
    /// @custom:examples
    ///
    /// ```solidity
    /// import {
    ///     IExecutionPermissions,
    ///     BatchPermissionEntry
    /// } from "./contracts/interfaces/IExecutionPermissions.sol";
    ///
    /// contract ExampleUsage {
    ///     /* ... */
    ///
    ///     address public owner;
    ///     address public refPermissions;
    ///
    ///     /* ... */
    ///
    ///     constructor(address _refPermissions) {
    ///         owner = msg.sender;
    ///         refPermissions = _refPermissions;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     modifier onlyOwner() {
    ///         require(msg.sender == owner, "ExampleUsage: sender not permitted");
    ///         _;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     function setBatchPermission(BatchPermissionEntry[] memory entries)
    ///         external
    ///         onlyOwner
    ///     {
    ///         IExecutionPermissions(refPermissions).setBatchPermission(entries);
    ///     }
    /// }
    /// ```
    function setBatchPermission(BatchPermissionEntry[] memory entries)
        external
        payable;

    /// Assign single function caller permission state
    ///
    /// @param target Function ID to set caller permission
    /// @param caller Original `msg.sender` of targeted function
    /// @param state Value to assign for function caller interaction
    ///
    /// @custom:throws "ExecutionPermissions: instance not registered"
    ///
    /// @custom:examples
    ///
    /// ```solidity
    /// import {
    ///     IExecutionPermissions,
    ///     BatchPermissionEntry
    /// } from "./contracts/interfaces/IExecutionPermissions.sol";
    ///
    /// contract ExampleUsage {
    ///     /* ... */
    ///
    ///     address public owner;
    ///     address public refPermissions;
    ///
    ///     /* ... */
    ///
    ///     constructor(address _refPermissions) {
    ///         owner = msg.sender;
    ///         refPermissions = _refPermissions;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     modifier onlyOwner() {
    ///         require(msg.sender == owner, "ExampleUsage: sender not permitted");
    ///         _;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     function setTargetPermission(
    ///         bytes4 target,
    ///         address caller,
    ///         bool state
    ///     ) external onlyOwner {
    ///         IExecutionPermissions(refPermissions).setTargetPermission(
    ///             target,
    ///             caller,
    ///             state
    ///         );
    ///     }
    /// }
    /// ```
    function setTargetPermission(
        bytes4 target,
        address caller,
        bool state
    ) external payable;

    /// Set registration state for calling contract instance
    ///
    /// @param state Set `true` for registered and `false` for unregistered (default)
    ///
    /// @dev Note upgrade `refPermissions` features _should_ consider calling
    ///      this with `false` before calling new reference with `true`
    ///
    /// @custom:throws "ExecutionPermissions: instance not initialized"
    ///
    /// @custom:examples
    ///
    /// ```solidity
    /// import {
    ///     IExecutionPermissions
    /// } from "./contracts/interfaces/IExecutionPermissions.sol";
    ///
    /// contract ExampleUsage {
    ///     /* ... */
    ///
    ///     address public owner;
    ///     address public refPermissions;
    ///
    ///     /* ... */
    ///
    ///     constructor(address _refPermissions) {
    ///         owner = msg.sender;
    ///         refPermissions = _refPermissions;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     modifier onlyOwner() {
    ///         require(msg.sender == owner, "ExampleUsage: sender not permitted");
    ///         _;
    ///     }
    ///
    ///     /* ... */
    ///
    ///     function setRegistered(bool state) external onlyOwner {
    ///         IExecutionPermissions(refPermissions).setRegistered(state);
    ///     }
    /// }
    /// ```
    function setRegistered(bool state) external payable;

    /// Set registration state for referenced contract instance
    ///
    /// @param ref Contract instance owned by `msg.sender`
    /// @param state Set `true` for registered and `false` for unregistered (default)
    ///
    /// @custom:throws "ExecutionPermissions: instance not initialized"
    /// @custom:throws "ExecutionPermissions: instance does not implement `.owner()`"
    /// @custom:throws "ExecutionPermissions: not instance owner"
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:examples
    ///
    /// ### Node Web3JS set state for owned contract
    ///
    /// ```javascript
    /// const { PRIVATE_KEY } = process.env;
    ///
    /// if (PRIVATE_KEY) {
    ///   const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    ///
    ///   ExecutionPermissions
    ///     .methods
    ///     .setRegistered("0x0...DEADBEEF", true)
    ///     .send({ from: account.address })
    ///     .then((receipt) => {
    ///       console.log("tip ->", JSON.stringify({ receipt }, null, 2));
    ///     });
    /// }
    /// ```
    function setRegistered(address ref, bool state) external payable;

    /// Show some support developers of this contract
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:examples
    ///
    /// ### Node Web3JS show appreciation for owner of `ExecutionPermissions`
    ///
    /// ```javascript
    /// const { PRIVATE_KEY } = process.env;
    ///
    /// if (PRIVATE_KEY) {
    ///   const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    ///
    ///   ExecutionPermissions
    ///     .methods
    ///     .tip()
    ///     .send({
    ///       from: account.address,
    ///       value: web3.utils.toWei("0.1"),
    ///     }).then((receipt) => {
    ///       console.log("tip ->", JSON.stringify({ receipt }, null, 2));
    ///     });
    /// }
    /// ```
    function tip() external payable;

    /*************************************************************************/
    /* Administration */
    /*************************************************************************/

    /// Allow owner of `ExecutionPermissions` to receive tips
    ///
    /// @param to Where to send Ethereum
    /// @param amount Measured in Wei
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:throws "ExecutionPermissions: caller not owner"
    /// @custom:throws "ExecutionPermissions: transfer failed"
    ///
    /// @custom:examples
    ///
    /// ### Node Web3JS transfer contract balance to owner
    ///
    /// ```javascript
    /// const { PRIVATE_KEY } = process.env;
    ///
    /// if (PRIVATE_KEY) {
    ///   const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    ///
    ///   web3.eth.getBalance(ExecutionPermissions.address).then((balance) => {
    ///     const parameters = {
    ///       to: account.address,
    ///       amount: balance,
    ///     };
    ///
    ///     return ExecutionPermissions
    ///       .methods
    ///       .withdraw(...Object.values(parameters))
    ///       .send({ from: account.address });
    ///   }).then((receipt) => {
    ///     console.log("withdraw ->", JSON.stringify({ receipt }, null, 2));
    ///   });
    /// }
    /// ```
    function withdraw(address to, uint256 amount) external payable;

    /// Initiate transfer of contract ownership
    ///
    /// @param newOwner Account that may claim ownership of contract
    ///
    /// @dev See {IExecutionPermissions}
    /// @dev See {IExecutionPermissions_Events-OwnerNominated}
    ///
    /// @custom:throws "ExecutionPermissions: caller not owner"
    /// @custom:throws "ExecutionPermissions: new owner cannot be zero address"
    ///
    /// @custom:examples
    ///
    /// ### Node Web3JS nominate new owner
    ///
    /// ```javascript
    /// const { PRIVATE_KEY } = process.env;
    /// const { NEW_OWNER_ADDRESS } = process.env;
    ///
    /// if (PRIVATE_KEY && NEW_OWNER_ADDRESS) {
    ///   const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    ///
    ///   web3.eth.getBalance(ExecutionPermissions.address).then((balance) => {
    ///     return ExecutionPermissions
    ///       .methods
    ///       .nominateOwner(NEW_OWNER_ADDRESS)
    ///       .send({ from: account.address });
    ///   }).then((receipt) => {
    ///     console.log("nominateOwner ->", JSON.stringify({ receipt }, null, 2));
    ///   });
    /// }
    /// ```
    function nominateOwner(address newOwner) external payable;

    /// Accept transfer of contract ownership
    ///
    /// @dev See {IExecutionPermissions}
    /// @dev See {IExecutionPermissions_Events-OwnershipClaimed}
    ///
    /// @custom:throws "ExecutionPermissions: new owner cannot be zero address"
    /// @custom:throws "ExecutionPermissions: sender not nominated"
    ///
    /// @custom:examples
    ///
    /// ### Node Web3JS assume ownership of contract
    ///
    /// ```javascript
    /// const { PRIVATE_KEY } = process.env;
    ///
    /// if (PRIVATE_KEY) {
    ///   const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
    ///
    ///   web3.eth.getBalance(ExecutionPermissions.address).then((balance) => {
    ///     return ExecutionPermissions
    ///       .methods
    ///       .claimOwnership()
    ///       .send({ from: account.address });
    ///   }).then((receipt) => {
    ///     console.log("claimOwnership ->", JSON.stringify({ receipt }, null, 2));
    ///   });
    /// }
    /// ```
    function claimOwnership() external payable;
}

/// @title Describe public storage getter functions
/// @dev See {IExecutionPermissions}
interface IExecutionPermissions_Variables {
    /// Check execution permissions of referenced contract function for given caller
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @param ref Contract address with `target` function
    /// @param target Function ID to check
    /// @param caller Original `msg.sender` of targeted function
    ///
    /// @custom:examples
    ///
    /// ### Web3JS check permissions of contract function caller
    ///
    /// ```javascript
    /// function getTargetPermission({
    ///   ExecutionPermissions,
    ///   ref,
    ///   target,
    ///   caller,
    /// } = {}) {
    ///   if (target.length !== 10) {
    ///     target = web3.eth.abi.encodeFunctionSignature(target);
    ///   }
    ///   return ExecutionPermissions.methods.permissions(ref, target, caller).call();
    /// }
    ///
    /// getTargetPermission({
    ///   ExecutionPermissions,
    ///   ref: "0x0...1",
    ///   target: "someFunctionName(address,string,uint256)",
    ///   caller: "0x0...2",
    /// }).then((response) => {
    ///   console.assert(typeof response === "boolean", "Unexpected response type");
    ///   console.log("getTargetPermission ->", { response });
    /// });
    /// ```
    function permissions(
        address ref,
        bytes4 target,
        address caller
    ) external view returns (bool);

    /// Check registration status of referenced contract
    ///
    /// @param ref Contract address to check registration state
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:examples
    ///
    /// ### Web3JS check registration status of contract
    ///
    /// ```javascript
    /// function getRegistrationStatus({
    ///   ExecutionPermissions,
    ///   ref,
    /// } = {}) {
    ///   return ExecutionPermissions.methods.registered(ref).call();
    /// }
    ///
    /// getTargetPermission({
    ///   ExecutionPermissions,
    ///   ref: '0x0...1',
    ///   target: "setBatchPermission(BatchPermissionEntry[])",
    ///   caller: ADDRESS,
    /// }).then((response) => {
    ///   console.assert(typeof response === "boolean", "Unexpected response type");
    ///   console.log("getTargetPermission ->", { response });
    /// });
    /// ```
    function registered(address ref) external view returns (bool);

    /// Obtain current owner address
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:examples
    ///
    /// ### Web3JS check what address owns contract instance
    ///
    /// ```javascript
    /// ExecutionPermissions.methods.owner().then((response) => {
    ///   console.assert(typeof response === "string", "Unexpected response type");
    ///   console.log("owner ->", { response });
    /// })
    /// ```
    function owner() external view returns (address);

    /// Obtain new owner nominated address
    ///
    /// @dev See {IExecutionPermissions}
    ///
    /// @custom:examples
    ///
    /// ### Web3JS check what address is nominated to own contract
    ///
    /// ```javascript
    /// ExecutionPermissions.methods.nominated_owner().then((response) => {
    ///   console.assert(typeof response === "string", "Unexpected response type");
    ///   console.log("nominated_owner ->", { response });
    /// })
    /// ```
    function nominated_owner() external view returns (address);
}

/// @title Describe all functions available to third-parties
/// @author S0AndS0
/// @custom:link https://github.com/solidity-utilities/execution-permissions
///
/// @custom:examples
///
/// ### Node Web3JS initialize contract instance
///
/// ```javascript
/// const Web3 = require('web3');
///
/// const { abi } = require('./build/contracts/IExecutionPermissions.json');
///
/// const { ADDRESS } = process.env;
///
/// const web3 = new Web3('http://localhost:8545');
///
/// const ExecutionPermissions = new web3.eth.Contract(abi, ADDRESS);
/// ```
interface IExecutionPermissions is
    IExecutionPermissions_Events,
    IExecutionPermissions_Functions,
    IExecutionPermissions_Variables
{

}