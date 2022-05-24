//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoreRef.sol";
import "./interfaces/IKeysManager.sol";
import { IStakingPool } from "./interfaces/IStakingPool.sol";

/// @title Keys manager contract
/// @author ...
/// @notice Contract for on managing public keys, signatures
contract KeysManager is IKeysManager, CoreRef {
    mapping(bytes => Validator) public _validators;

    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant SIGNATURE_LENGTH = 96;
    uint256 public constant VALIDATOR_DEPOSIT = 31e18;

    event AddValidator(bytes publicKey, bytes signature, address nodeOperator);
    event ActivateValidator(bytes[] publicKey);
    event DepositValidator(bytes publicKey);

    mapping (address => uint256) public override nodeOperatorValidatorCount;



    /// @notice constructor to initialize Core
    /// @param _core address of the core
    constructor(address _core) public CoreRef(_core) {}



    /// @notice function that returns public key of a particular validator.
    /// @param publicKey public key of the validator.
    function validators(bytes calldata publicKey)
        external
        view
        override
        returns (Validator memory)
    {
        return _validators[publicKey];
    }


    /// @notice function to add a new validator
    /// @param publicKey public key of the validator
    /// @param signature signature with private key needed for eth2 deposit
    /// @param nodeOperator address of the node operator
    function addValidator(
        bytes calldata publicKey,
        bytes calldata signature,
        address nodeOperator
    ) external override onlyNodeOperator {
        Validator memory _validator = _validators[publicKey];
        require(
            _validator.state == State.INVALID,
            "KeysManager: validator already exist"
        );

        _validator.state = State.VALID;
        _validator.signature = signature;
        _validator.nodeOperator = nodeOperator;
        _validator.deposit_root = calculateDepositDataRoot(publicKey, signature);

        _validators[publicKey] = _validator;
        emit AddValidator(publicKey, signature, nodeOperator);
    }




    /// @notice function for activating the status of an array of validator public keys
    /// @param publicKeys public keys array of validators.
    function activateValidator(bytes[] memory publicKeys) external override {
        require(
            msg.sender == core().oracle(),
            "KeysManager: Only oracle can activate"
        );
        for (uint256 i = 0; i < publicKeys.length; i++) {
            Validator storage validator = _validators[publicKeys[i]];
            require(validator.state == State.VALID, "KeysManager: Validator not in valid state");
            validator.state = State.ACTIVATED;
        }
        emit ActivateValidator(publicKeys);
    }



    /// @notice set status of validator to deposited
    /// @param publicKey public key of the validator.
    function depositValidator(bytes memory publicKey) external override {
        require(
            msg.sender == core().issuer(),
            "KeysManager: Only issuer can activate"
        );

        Validator storage validator = _validators[publicKey];
        
        require(
            IStakingPool(core().validatorPool()).numOfValidatorAllowed(validator.nodeOperator) > 
            nodeOperatorValidatorCount[validator.nodeOperator],
            "KeysManager: validator deposit not added by node operator"
        );
        
        require(
            validator.state == State.ACTIVATED,
            "KeysManager: Key not activated"
        );
        validator.state = State.DEPOSITED;
        nodeOperatorValidatorCount[validator.nodeOperator] += 1;

        IStakingPool(core().validatorPool()).claimAndUpdateRewardDebt(validator.nodeOperator);

        emit DepositValidator(publicKey);
    }


    /// @notice function to return the deposit data root node
    /// @return depositRoot is deposit root node 
    function calculateDepositDataRoot(
        bytes calldata pubKey,
        bytes calldata signature
    ) internal returns (bytes32 depositRoot) {
        uint256 deposit_amount = VALIDATOR_DEPOSIT / 1 gwei;
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));

        bytes32 withdrawal_credentials = core().withdrawalCredential();
        bytes32 pubkey_root = sha256(abi.encodePacked(pubKey, bytes16(0)));
        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature[:64])),
                sha256(abi.encodePacked(signature[64:], bytes32(0)))
            )
        );
        depositRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
                sha256(abi.encodePacked(amount, bytes24(0), signature_root))
            )
        );
        require(pubKey.length == 48, "DepositContract: invalid pubkey length");
        require(
            signature.length == 96,
            "DepositContract: invalid signature length"
        );
        require(
            withdrawal_credentials.length == 32,
            "DepositContract: invalid withdrawal_credentials length"
        );
        
    }


    /// @notice function to convert address to Bytes
    /// @param a address to be converted to bytes.
    function toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }


    /// @notice function to convert to integer to little endian 64 bytes format.
    /// @param value is the integer number.
    /// @return ret is 8 byte array.
    function to_little_endian_64(uint64 value)
        internal
        pure
        returns (bytes memory ret)
    {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
    

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICoreRef.sol";
import "./interfaces/ICore.sol";
import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract CoreRef is ICoreRef, Pausable {

    ICore private _core;

    constructor(address core){
        require(core != address(0), "CoreRef: Zero address");
        _core = ICore(core);
        emit SetCore(core);
    }

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

    modifier onlyKeyAdmin() {
        require(_core.isKeyAdmin(msg.sender), "Permissions: Caller is not a key admin");
        _;
    }

    modifier onlyNodeOperator() {
        require(_core.isNodeOperator(msg.sender), "Permissions: Caller is not a Node Operator");
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGovernor {
        _unpause();
    }

    /// @notice set new Core reference address
    /// @param core the new core address
    function setCore(address core) external override onlyGovernor {
        _core = ICore(core);
        emit SetCore(core);
    }

    function stkEth() public view override returns (IStkEth) {
        return _core.stkEth();
    }

    function core() public view override returns (ICore) {
        return _core;
    }

    function oracle() public view override returns (IOracle) {
        return IOracle(_core.oracle());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KeysManager interface
/// @author Ankit Parashar
interface IKeysManager {

    enum State { INVALID, VALID, ACTIVATED, DEPOSITED }

    struct Validator {
        State state;
        bytes signature;
        address nodeOperator;
        bytes32 deposit_root;
    }

    function validators(bytes calldata publicKey) external view returns (Validator memory);

    function addValidator(bytes calldata publicKey, bytes calldata signature,  address nodeOperator) external;

    function activateValidator(bytes[] memory publicKey) external;

    function depositValidator(bytes memory publicKey) external;

    function nodeOperatorValidatorCount(address usr) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Staking Pool interface
/// @author Ankit Parashar
interface IStakingPool {
    
    function slash(uint256 amount) external;

    function numOfValidatorAllowed(address usr) external returns (uint256);

    function claimAndUpdateRewardDebt(address usr) external;

    function updateRewardPerValidator(uint256 newReward) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICore.sol";
import "./IStkEth.sol";
import "./IOracle.sol";

/// @title CoreRef interface
/// @author Ankit Parashar
interface ICoreRef {

    event SetCore(address _core);

    function setCore(address core) external;

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function stkEth() external view returns (IStkEth);

    function oracle() external view returns (IOracle);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPermissions.sol";
import "./IStkEth.sol";

/// @title Core interface
/// @author Ankit Parashar
interface ICore is IPermissions {

    event SetCoreContract(bytes32 _key, address indexed _address);

    event SetWithdrawalCredential(bytes32 _withdrawalCreds);

    function stkEth() external view returns(IStkEth);

    function oracle() external view returns(address);

    function withdrawalCredential() external view returns(bytes32);

    function keysManager() external view returns(address);

    function pstakeTreasury() external view returns(address);

    function validatorPool() external view returns(address);

    function issuer() external view returns(address);

    function set(bytes32 _key, address _address) external;

    function coreContract(bytes32 key) external view returns (address);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Oracle interface
/// @author Ankit Parashar
interface IOracle {

    event Distribute(uint256 amount,uint256 pricePerShare,uint256 timestamp);
    event Slash(uint256 amount,uint256 pricePerShare,uint256 timestamp);

    function pricePerShare() external view returns (uint256);

    function activatedValidators() external view returns (uint256);

    function addOracleMember(address newOracleMember) external;

    function removeOracleMember(address oracleMeberToDelete) external;

    function pushData(
        uint256 latestEthBalance,
        uint256 latestNonce,
        uint32 numberOfValidators
    ) external;

    function activateValidator(bytes[] calldata _publicKeys) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICoreRef.sol";

/// @title Oracle interface
/// @author Ankit Parashar
interface IStkEth is IERC20{

    function pricePerShare() external view returns (uint256 amount);

    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Permissions interface
/// @author Ankit Parashar
interface IPermissions {

    // ----------- Governor only state changing functions -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantNodeOperator(address nodeOperator) external;

    function grantKeyAdmin(address keyAdmin) external;

    function revokeGovernor(address governor) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokeNodeOperator(address nodeOperator) external;

    function revokeKeyAdmin(address keyAdmin) external;

    // ----------- Getters -----------

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isBurner(address _address) external view returns (bool);

    function isNodeOperator(address _address) external view returns (bool);

    function isKeyAdmin(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

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