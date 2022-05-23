// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "./BaseBridge.sol";
import "./Validator.sol";
import "./extensions/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title BridgeBank
 * @dev Bank contract which coordinates asset-related functionality.
 *      EthBank manages locking and unlocking of tokenToomics assets
 *      based on eth/bsc.
 **/

contract ToomicsBridge is
    Initializable,
    BaseBridge,
    PausableUpgradeable,
    OwnableUpgradeable,
    Validator,
    ReentrancyGuardUpgradeable
{
    address public timeLockContract;

    /*
     * @dev: Constructor, sets operator
     */
    function initialize(
        address _timeLockAddress,
        address[] memory _validator,
        address _tooAddress
    ) public initializer {
        timeLockContract = _timeLockAddress;
        tooAddr = _tooAddress;
        for (uint256 i; i < _validator.length; i++) {
            addValidator(_validator[i]);
        }
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
    }

    /*
     * @dev: Modifier to restrict state change to timeLock smart contract
     */
    modifier isTimeLock() {
        require(msg.sender == timeLockContract, "Must be timeLock");
        _;
    }

    /*
     * @dev: Add validator
     *
     */
    function addValidator(address _newValidator) public isTimeLock {
        _addValidator(_newValidator);
    }

    /*
     * @dev: Remove validator
     *
     */
    function removeValidator(address _validator) public isTimeLock {
        _removeValidator(_validator);
    }

    /*
     * @dev: Fallback function allows anyone to send funds to the bank directly
     *
     */

    /**
     * @dev Pauses all functions.
     * Set timestamp for current pause
     * No need to reset pausedAt when pausing it will automatically increase
     */
    function pause() public isTimeLock {
        _pause();
    }

    /**
     * @dev Unpauses all functions.
     */
    function unpause() public isTimeLock {
        _unpause();
    }

    /*
     * @dev: Locks received EVRY funds.
     *
     * @param _recipient: representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function lock(
        address _recipient,
        uint256 _amount,
        uint256 _targetChainId
    ) public whenNotPaused nonReentrant {
        // ERC20 deposit
        address thisadd = address(this);
        uint256 beforeLock = IERC20(tooAddr).balanceOf(thisadd);

        IERC20(tooAddr).transferFrom(msg.sender, thisadd, _amount);

        uint256 afterLock = IERC20(tooAddr).balanceOf(thisadd);

        lockFunds(
            msg.sender,
            _recipient,
            afterLock - beforeLock,
            _targetChainId
        );
    }

    /*
     * @dev: Unlocks TOON tokens held on the contract.
     *
     * @param _recipient: recipient's is an evry address
     * @param _token: token contract address
     * @param _amount: wei amount or ERC20 token count
     *
     * This functions is use for unlock IBC assets
     * - Operator send the
     */

    function unlock(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _recipient,
        uint256 _amount,
        bytes32 _interchainTX
    ) public whenNotPaused nonReentrant validatorPrecheck(sigV, sigR, sigS) {
        require(
            _checkUnlockSig(
                sigV,
                sigR,
                sigS,
                _recipient,
                _amount,
                _interchainTX
            ),
            "Invalid signature"
        );

        require(
            unlockCompleted[_interchainTX].isUnlocked == false,
            "Processed before"
        );

        // Check if it is EVRY
        address thisadd = address(this);

        require(
            IERC20(tooAddr).balanceOf(thisadd) >= _amount,
            "Insufficient ERC20 balance."
        );

        unlockFunds(_recipient, _amount, _interchainTX);
    }

    function emergencyWithdraw(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address tokenAddress,
        uint256 _amount
    )
        public
        isTimeLock
        whenPaused
        nonReentrant
        validatorPrecheck(sigV, sigR, sigS)
    {
        require(
            _checkEmergencySig(sigV, sigR, sigS, _amount),
            "Invalid signature"
        );
        // Check if it is EVRY
        address thisadd = address(this);
        if (tokenAddress == address(0)) {
            require(thisadd.balance >= _amount, "Insufficient balance.");
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                IERC20(tokenAddress).balanceOf(thisadd) >= _amount,
                "Insufficient ERC20 balance."
            );
            IERC20(tokenAddress).transfer(owner(), _amount);
        }
    }

    /*
     * @dev: refunds TOON tokens held on the contract.
     *
     * @param _recipient: recipient's is an evry address
     * @param _token: token contract address
     * @param _amount: wei amount or ERC20 token count
     */
    function refund(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _recipient,
        uint256 _amount,
        uint256 _nonce
    ) public whenNotPaused nonReentrant validatorPrecheck(sigV, sigR, sigS) {
        require(
            _checkRefundSig(sigV, sigR, sigS, _recipient, _amount, _nonce),
            "Invalid signature"
        );
        require(
            refundCompleted[_nonce].isRefunded == false,
            "Processed before"
        );
        require(
            refundCompleted[_nonce].sender == _recipient,
            "Invalid recipient"
        );
        require(refundCompleted[_nonce].amount == _amount, "Invalid amount");

        address thisadd = address(this);

        require(
            IERC20(tooAddr).balanceOf(thisadd) >= _amount,
            "Insufficient erc20 for delivery."
        );

        refunds(_recipient, _amount, _nonce);
    }

    /*
     * @dev: For validators to get the lock data in order to verify
     *       if it is correct data that they need to verify with signature
     *
     * @param _recipient: Nonce Number
     * @return lockData
     */
    function getLockData(uint256 _nonce)
        public
        view
        returns (
            bool,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        return _getLockData(_nonce);
    }

    // This function check the mapping to see if the transaction  is unlockeds
    function checkIsUnlocked(bytes32 _interchainTX) public view returns (bool) {
        return unlockCompleted[_interchainTX].isUnlocked;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "./extensions/SafeERC20.sol";

/*
 *  @title: EvrnetBank
 *  @dev: Eth bank which locks ETH/ERC20 token deposits, and unlocks
 *        ETH/ERC20 tokens once the prophecy has been successfully processed.
 */
contract BaseBridge {
    using SafeERC20 for IERC20;

    address public tooAddr;

    uint256 public lockBurnNonce;

    struct RefundData {
        bool isRefunded;
        uint256 nonce;
        address sender;
        uint256 amount;
        uint256 targetChainId;
    }
    struct UnlockData {
        bool isUnlocked;
        address operator;
        address recipient;
        uint256 amount;
    }
    // Mapping and check if the refunds transaction is completed
    mapping(uint256 => RefundData) internal refundCompleted;
    // Mapping and check if the unlock transaction is completed
    mapping(bytes32 => UnlockData) internal unlockCompleted;

    // For erc20
    /*
     * @dev: Event declarations
     */
    event LogLock(
        address _from,
        address _to,
        uint256 _value,
        uint256 _nonce,
        uint256 _targetChainId
    );

    event LogUnlock(
        address _to,
        uint256 _value,
        bytes32 _interchainTX
    );

    event LogRefund(
        address _to,
        uint256 _value,
        uint256 _nonce
    );

    /*
     * @dev: Gets the amount of locked/funded tokens by address.
     *
     * @param _symbol: The asset's symbol.
     */
    function getLockedFunds() public view returns (uint256) {
        address thisadd = address(this);
        return IERC20(tooAddr).balanceOf(thisadd);
    }

    /*
     * @dev: Creates a new Evrynet deposit with a unique id.
     *
     * @param _sender: The sender's ethereum address.
     * @param _recipient: The intended recipient's evrnet address.
     * @param _token: The currency type, either erc20 or ethereum.
     * @param _amount: The amount of erc20 tokens/ ethereum (in wei) to be itemized.
     */
    function lockFunds(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint256 _targetChainId
    ) internal {
        lockBurnNonce++;

        refundCompleted[lockBurnNonce] = RefundData(
            false,
            lockBurnNonce,
            _sender,
            _amount,
            _targetChainId
        );

        emit LogLock(
            _sender,
            _recipient,
            _amount,
            lockBurnNonce,
            _targetChainId
        );
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _amount: wei amount or ERC20 token count
     */
    function unlockFunds(
        address _recipient,
        uint256 _amount,
        bytes32 _interchainTX
    ) internal {
        // Transfer funds to intended recipient
        IERC20(tooAddr).safeTransfer(_recipient, _amount);
        unlockCompleted[_interchainTX] = UnlockData(
            true,
            address(this),
            _recipient,
            _amount
        );

        emit LogUnlock(_recipient, _amount, _interchainTX);
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _amount: wei amount or ERC20 token count
     */
    function refunds(
        address _recipient,
        uint256 _amount,
        uint256 _nonce
    ) internal {
        // Transfer funds to intended recipient

        IERC20(tooAddr).safeTransfer(_recipient, _amount);

        refundCompleted[_nonce].isRefunded = true;

        emit LogRefund(_recipient, _amount, _nonce);
    }

    // For validator to check if evrything in data is correct
    function _getLockData(uint256 _nonce)
        internal
        view
        returns (
            bool,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        return (
            refundCompleted[_nonce].isRefunded,
            refundCompleted[_nonce].nonce,
            refundCompleted[_nonce].sender,
            refundCompleted[_nonce].amount,
            refundCompleted[_nonce].targetChainId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

/**
 * @title Validator
 * @dev To handle the multisig
 * Author: luc.vu
 * Company: sotatek.com
 **/

contract Validator {
    address[] private validators;
    // Fixed threshold to validate unlock/refund/emergency withdraw equal or more than 2/3 signatures
    uint256 private constant threshold = 66;

    function getValidators() public view returns (address[] memory) {
        return validators;
    }

    event LogAddValidator(address _validator);

    function _addValidator(address _validator) internal {
        require(_validator != address(0), "Null address");
        for (uint256 index = 0; index < validators.length; index++) {
            require(_validator != validators[index], "Already added");
        }
        validators.push(_validator);

        emit LogAddValidator(_validator);
    }

    event LogRemoveValidator(address _validator);

    function _removeValidator(address _validator) internal {
        for (uint256 index = 0; index < validators.length; index++) {
            if (_validator == validators[index]) {
                validators[index] = validators[validators.length - 1];
                validators.pop();
                emit LogRemoveValidator(_validator);
                return;
            }
        }
        require(false, "Could not find validator to remove");
    }

    function _checkSignature(
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _inputHash
    ) private view returns (bool) {
        address checkAdress = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _inputHash)
            ),
            _sigV,
            _sigR,
            _sigS
        );
        for (uint256 index = 0; index < validators.length; index++) {
            if (checkAdress == validators[index]) {
                return true;
            }
        }
        return false;
    }

    function _checkUnlockSig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _recipient,
        uint256 _amount,
        bytes32 _interchainTX
    ) internal view returns (bool) {
        bytes32 funcHash = keccak256("unlock");

        // digest the data to transactionHash
        bytes32 inputHash = keccak256(
            abi.encode(
                funcHash,
                _recipient,
                _amount,
                _interchainTX
            )
        );
        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    function _checkRefundSig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _recipient,
        uint256 _amount,
        uint256 _nonce
    ) internal view returns (bool) {
        bytes32 funcHash = keccak256("refund");

        // digest the data to transactionHash
        bytes32 inputHash = keccak256(
            abi.encode(
                funcHash,
                _recipient,
                _amount,
                _nonce
            )
        );
        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    function _checkEmergencySig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 _amount
    ) internal view returns (bool) {
        bytes32 funcHash = keccak256("emergencyWithdraw");
        // digest the data to transactionHash
        bytes32 inputHash = keccak256(
            abi.encode(funcHash, _amount)
        );
        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    modifier validatorPrecheck(
        uint8[] memory _sigV,
        bytes32[] memory _sigR,
        bytes32[] memory _sigS
    ) {
        require(
            _sigV.length == _sigR.length &&
                _sigR.length == _sigS.length &&
                _sigV.length > 0,
            "validator(s) is empty"
        );

        require(
            (_sigV.length * 100) / validators.length >= threshold,
            "Threshold not reached"
        );

        if (_sigV.length >= 2) {
            for (uint256 i = 0; i < _sigV.length; i++) {
                for (uint256 j = i + 1; j < _sigV.length; j++) {
                    require(
                        keccak256(
                            abi.encodePacked(_sigV[i], _sigR[i], _sigS[i])
                        ) !=
                            keccak256(
                                abi.encodePacked(_sigV[j], _sigR[j], _sigS[j])
                            ),
                        "Can not be the same signature"
                    );
                }
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function symbol() external view returns (string memory);

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IERC20.sol";

library SafeERC20 {
    using AddressUpgradeable for address;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}