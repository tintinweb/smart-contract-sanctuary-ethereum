/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/executable/[email protected]

pragma solidity ^0.8.0;


contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    // Get pending ownership transfer
    function pendingOwner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;

    function contractId() external pure returns (bytes32);
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

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


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/test/[email protected]

pragma solidity 0.8.9;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public name;
    string public symbol;

    uint8 public immutable decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, and {decimals}.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != type(uint256).max) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        _transfer(sender, recipient, amount);

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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0) || recipient == address(0)) revert InvalidAccount();

        _beforeTokenTransfer(sender, recipient, amount);

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
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
        if (account == address(0)) revert InvalidAccount();

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balanceOf[account] += amount;
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
        if (account == address(0)) revert InvalidAccount();

        _beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] -= amount;
        totalSupply -= amount;
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0) || spender == address(0)) revert InvalidAccount();

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/utils/[email protected]

pragma solidity ^0.8.0;

abstract contract Ownable is IOwnable {
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    // keccak256('ownership-transfer')
    bytes32 internal constant _OWNERSHIP_TRANSFER_SLOT =
        0x9855384122b55936fbfb8ca5120e63c6537a1ac40caf6ae33502b3c5da8c87d1;

    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();

        _;
    }

    function owner() public view returns (address owner_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    function pendingOwner() public view returns (address owner_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner_ := sload(_OWNERSHIP_TRANSFER_SLOT)
        }
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferStarted(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, newOwner)
        }
    }

    function acceptOwnership() external virtual {
        address newOwner = pendingOwner();
        if (newOwner != msg.sender) revert InvalidOwner();

        emit OwnershipTransferred(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
            sstore(_OWNER_SLOT, newOwner)
        }
    }
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/[email protected]

pragma solidity ^0.8.0;


abstract contract Upgradable is Ownable, IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    modifier onlyProxy() {
        // Prevent setup from being called on the implementation
        if (implementation() == address(0)) revert NotProxy();

        _;
    }

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId())
            revert InvalidImplementation();
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        if (params.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        emit Upgraded(newImplementation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function setup(bytes calldata data) external override onlyProxy {
        _setup(data);
    }

    // solhint-disable-next-line no-empty-blocks
    function _setup(bytes calldata data) internal virtual {}
}


// File contracts/interfaces/IERC20BurnableMintableCapped.sol

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableMintableCapped is IERC20 {
    error CapExceeded();

    function cap() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}


// File contracts/ERC20BurnableMintableCapped.sol

pragma solidity 0.8.9;



contract ERC20BurnableMintableCapped is ERC20, Ownable, IERC20BurnableMintableCapped{
    uint256 public immutable cap;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 cap_, address owner) ERC20(name_, symbol_, decimals_) {
        cap = cap_;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, owner)
        }
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        uint256 capacity = cap;

        _mint(account, amount);

        if (capacity != 0 && totalSupply > capacity) revert CapExceeded();
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        uint256 _allowance = allowance[account][msg.sender];
        if (_allowance != type(uint256).max) {
            _approve(account, msg.sender, _allowance - amount);
        }
        _burn(account, amount);
    }
}


// File @axelar-network/axelar-cgp-solidity/contracts/[email protected]

pragma solidity 0.8.9;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) private _uintStorage;
    mapping(bytes32 => string) private _stringStorage;
    mapping(bytes32 => address) private _addressStorage;
    mapping(bytes32 => bytes) private _bytesStorage;
    mapping(bytes32 => bool) private _boolStorage;
    mapping(bytes32 => int256) private _intStorage;

    // *** Getter Methods ***
    function getUint(bytes32 key) public view returns (uint256) {
        return _uintStorage[key];
    }

    function getString(bytes32 key) public view returns (string memory) {
        return _stringStorage[key];
    }

    function getAddress(bytes32 key) public view returns (address) {
        return _addressStorage[key];
    }

    function getBytes(bytes32 key) public view returns (bytes memory) {
        return _bytesStorage[key];
    }

    function getBool(bytes32 key) public view returns (bool) {
        return _boolStorage[key];
    }

    function getInt(bytes32 key) public view returns (int256) {
        return _intStorage[key];
    }

    // *** Setter Methods ***
    function _setUint(bytes32 key, uint256 value) internal {
        _uintStorage[key] = value;
    }

    function _setString(bytes32 key, string memory value) internal {
        _stringStorage[key] = value;
    }

    function _setAddress(bytes32 key, address value) internal {
        _addressStorage[key] = value;
    }

    function _setBytes(bytes32 key, bytes memory value) internal {
        _bytesStorage[key] = value;
    }

    function _setBool(bytes32 key, bool value) internal {
        _boolStorage[key] = value;
    }

    function _setInt(bytes32 key, int256 value) internal {
        _intStorage[key] = value;
    }

    // *** Delete Methods ***
    function _deleteUint(bytes32 key) internal {
        delete _uintStorage[key];
    }

    function _deleteString(bytes32 key) internal {
        delete _stringStorage[key];
    }

    function _deleteAddress(bytes32 key) internal {
        delete _addressStorage[key];
    }

    function _deleteBytes(bytes32 key) internal {
        delete _bytesStorage[key];
    }

    function _deleteBool(bytes32 key) internal {
        delete _boolStorage[key];
    }

    function _deleteInt(bytes32 key) internal {
        delete _intStorage[key];
    }
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService {
    error NothingReceived();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeExpressGasAdded(
        bytes32 indexed txHash,
        uint256 indexed logIndex,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function addExpressGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}


// File @axelar-network/axelar-gmp-sdk-solidity/contracts/utils/[email protected]

pragma solidity ^0.8.0;

library StringToBytes32 {
    error InvalidStringLength();

    function toBytes32(string memory str) internal pure returns (bytes32) {
        // Converting a string to bytes32 for immutable storage
        bytes memory stringBytes = bytes(str);

        // We can store up to 31 bytes of data as 1 byte is for encoding length
        if (stringBytes.length == 0 || stringBytes.length > 31) revert InvalidStringLength();

        uint256 stringNumber = uint256(bytes32(stringBytes));

        // Storing string length as the last byte of the data
        stringNumber |= 0xff & stringBytes.length;
        return bytes32(stringNumber);
    }
}

library Bytes32ToString {
    function toTrimmedString(bytes32 stringData) internal pure returns (string memory converted) {
        // recovering string length as the last byte of the data
        uint256 length = 0xff & uint256(stringData);

        // restoring the string with the correct length
        // solhint-disable-next-line no-inline-assembly
        assembly {
            converted := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(converted, 0x40))
            // store length in memory
            mstore(converted, length)
            // write actual data
            mstore(add(converted, 0x20), stringData)
        }
    }
}


// File contracts/interfaces/IERC20Named.sol

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Named is IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);
}


// File contracts/interfaces/ITokenDeployer.sol

pragma solidity 0.8.9;

interface ITokenDeployer {
    function test() external returns (address addr);

    function deployToken(
        address owner,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 cap,
        bytes32 salt
    ) external payable returns (address tokenAddress);
}


// File contracts/interfaces/IInterchainTokenLinker.sol

pragma solidity 0.8.9;

interface IInterchainTokenLinker {
    error TokenLinkerZeroAddress();
    error TransferFailed();
    error TransferFromFailed();
    error MintFailed();
    error BurnFailed();
    error NotOriginToken();
    error AlreadyRegistered();
    error NotGatewayToken();
    error GatewayToken();
    error LengthMismatch();
    error SupportedByGateway();
    error NotSelf();
    error ExecutionFailed();
    error ExceedMintLimit(bytes32 tokenId);
    error TokenDeploymentFailed();

    event Sending(string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event SendingWithData(string destinationChain, bytes destinationAddress, uint256 indexed amount, address indexed from, bytes data);
    event Receiving(string sourceChain, address indexed destinationAddress, uint256 indexed amount);
    event ReceivingWithData(
        string sourceChain,
        address indexed destinationAddress,
        uint256 indexed amount,
        address indexed from,
        bytes data
    );
    event TokenRegistered(bytes32 indexed tokenId, address indexed tokenAddress, bool native, bool gateway, bool remoteGateway);
    event TokenDeployed(address indexed tokenAddress, string name, string symbol, uint8 decimals, uint256 cap, address indexed owner);
    event RemoteTokenRegisterInitialized(bytes32 indexed tokenId, string destinationChain, uint256 gasValue);

    function getTokenData(bytes32 tokenId) external view returns (bytes32 tokenData);

    function getOriginalChain(bytes32 tokenId) external view returns (string memory origin);

    function getTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function getTokenMintLimit(bytes32 tokenId) external view returns (uint256 mintLimit);

    function getTokenMintAmount(bytes32 tokenId) external view returns (uint256 amount);

    function tokenDeployer() external view returns (ITokenDeployer);

    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress);

    function getOriginTokenId(address tokenAddress) external view returns (bytes32 tokenId);

    function deployInterchainToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        uint256 cap,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable;

    function registerOriginToken(address tokenAddress) external returns (bytes32 tokenId);

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable returns (bytes32 tokenId);

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable;

    function setTokenMintLimit(bytes32 tokenId, uint256 mintLimit) external;

    function sendToken(bytes32 tokenId, string memory destinationChain, bytes memory to, uint256 amount) external payable;

    function callContractWithInterToken(
        bytes32 tokenId,
        string memory destinationChain,
        bytes memory to,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function registerOriginGatewayToken(string calldata symbol) external returns (bytes32 tokenId);

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external;

    function selfDeployToken(
        bytes32 tokenId,
        string memory origin,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        bool isGateway
    ) external;

    function selfGiveToken(bytes32 tokenId, bytes calldata destinationAddress, uint256 amount) external;

    function selfGiveTokenWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external;

    function selfSendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata destinationAddress, uint256 amount) external;

    function selfSendTokenWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IInterTokenExecutable.sol

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface IInterTokenExecutable {
    function exectuteWithInterToken(
        address tokenAddress,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        uint256 amount,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/ILinkerRouter.sol

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface ILinkerRouter {
    error ZeroAddress();
    error LengthMismatch();
    error ZeroStringLength();

    function validateSender(string calldata sourceChain, string calldata sourceAddress) external view returns (bool);

    function addTrustedAddress(string calldata sourceChain, string calldata sourceAddress) external;

    function removeTrustedAddress(string calldata sourceChain) external;

    function getRemoteAddress(string calldata chainName) external view returns (string memory remoteAddress);

    function supportedByGateway(string calldata chainName) external view returns (bool);

    function addGatewaySupportedChains(string[] calldata chainNames) external;

    function removeGatewaySupportedChains(string[] calldata chainNames) external;
}


// File contracts/libraries/AddressBytesUtils.sol

pragma solidity 0.8.9;

library AddressBytesUtils {
    function toAddress(bytes memory bytesAddress) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bytesAddress, 20))
        }
    }

    function toBytes(address addr) internal pure returns (bytes memory bytesAddress) {
        bytesAddress = new bytes(20);
        assembly {
            mstore(add(bytesAddress, 20), addr)
        }
    }
}


// File contracts/libraries/LinkedTokenData.sol

pragma solidity 0.8.9;

library LinkedTokenData {
    bytes32 public constant IS_ORIGIN_MASK = bytes32(uint256(0x80 << 248));
    bytes32 public constant IS_GATEWAY_MASK = bytes32(uint256(0x40 << 248));
    bytes32 public constant IS_REMOTE_GATEWAY_MASK = bytes32(uint256(0x20 << 248));
    bytes32 public constant LENGTH_MASK = bytes32(uint256(0x0f << 248));

    function getAddress(bytes32 tokenData) internal pure returns (address) {
        return address(uint160(uint256((tokenData))));
    }

    function isOrigin(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_ORIGIN_MASK == IS_ORIGIN_MASK;
    }

    function isGateway(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_GATEWAY_MASK == IS_GATEWAY_MASK;
    }

    function isRemoteGateway(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_REMOTE_GATEWAY_MASK == IS_REMOTE_GATEWAY_MASK;
    }

    function getSymbolLength(bytes32 tokenData) internal pure returns (uint256) {
        return uint256((tokenData & LENGTH_MASK) >> 248);
    }

    function getSymbol(bytes32 tokenData) internal pure returns (string memory symbol) {
        uint256 length = getSymbolLength(tokenData);
        symbol = new string(length);
        bytes32 stringData = tokenData << 8;
        assembly {
            mstore(add(symbol, 0x20), stringData)
        }
    }

    function createTokenData(address tokenAddress, bool origin) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress)));
        if (origin) tokenData |= IS_ORIGIN_MASK;
    }

    error SymbolTooLong();

    function createGatewayTokenData(address tokenAddress, bool origin, string memory symbol) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress))) | IS_GATEWAY_MASK;
        if (origin) tokenData |= IS_ORIGIN_MASK;
        uint256 length = bytes(symbol).length;
        if (length > 11) revert SymbolTooLong();

        tokenData |= bytes32(length) << 248;
        bytes32 symbolData = bytes32(bytes(symbol)) >> 8;
        tokenData |= symbolData;
    }

    function createRemoteGatewayTokenData(address tokenAddress) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress))) | IS_REMOTE_GATEWAY_MASK;
    }
}


// File contracts/TokenDeployer.sol

pragma solidity 0.8.9;

contract TokenDeployer is ITokenDeployer {
    function test() external view returns (address addr) {
        addr = address(this);
    }

    function deployToken(
        address owner,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 cap,
        bytes32 salt
    ) external payable returns (address tokenAddress) {
        tokenAddress = address(new ERC20BurnableMintableCapped{ salt: salt }(name, symbol, decimals, cap, owner));
    }
}


// File contracts/InterchainTokenLinker.sol

pragma solidity 0.8.9;













contract InterchainTokenLinker is IInterchainTokenLinker, AxelarExecutable, Upgradable, EternalStorage {
    using LinkedTokenData for bytes32;
    using StringToBytes32 for string;
    using Bytes32ToString for bytes32;

    IAxelarGasService public immutable gasService;
    ILinkerRouter public immutable linkerRouter;
    ITokenDeployer public immutable tokenDeployer;
    // bytes32(uint256(keccak256('token-linker')) - 1)
    bytes32 public constant contractId = 0x6ec6af55bf1e5f27006bfa01248d73e8894ba06f23f8002b047607ff2b1944ba;

    bytes32 internal constant PREFIX_TOKEN_DATA = keccak256('itl-token-data');
    bytes32 internal constant PREFIX_ORIGINAL_CHAIN = keccak256('itl-original-chain');
    bytes32 internal constant PREFIX_TOKEN_ID = keccak256('itl-token-id');
    bytes32 internal constant PREFIX_TOKEN_MINT_LIMIT = keccak256('itl-token-mint-limit');
    bytes32 internal constant PREFIX_TOKEN_MINT_AMOUNT = keccak256('itl-token-mint-amount');

    bytes32 public immutable chainNameHash;
    bytes32 public immutable chainName;

    constructor(
        address gatewayAddress_,
        address gasServiceAddress_,
        address linkerRouterAddress_,
        address tokenDeployerAddress_,
        string memory chainName_
    ) AxelarExecutable(gatewayAddress_) {
        if (gatewayAddress_ == address(0) || gasServiceAddress_ == address(0) || linkerRouterAddress_ == address(0))
            revert TokenLinkerZeroAddress();
        gasService = IAxelarGasService(gasServiceAddress_);
        linkerRouter = ILinkerRouter(linkerRouterAddress_);
        tokenDeployer = ITokenDeployer(tokenDeployerAddress_);
        chainName = chainName_.toBytes32();
        chainNameHash = keccak256(bytes(chainName_));
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    /* KEY GETTERS */

    function _getTokenDataKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_DATA, tokenId));
    }

    function _getOriginalChainKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_ORIGINAL_CHAIN, tokenId));
    }

    function _getTokenIdKey(address tokenAddress) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_ID, tokenAddress));
    }

    function _getTokenMintLimitKey(bytes32 tokenId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_MINT_LIMIT, tokenId));
    }

    function _getTokenMintAmountKey(bytes32 tokenId, uint256 epoch) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_TOKEN_MINT_AMOUNT, tokenId, epoch));
    }

    /* GETTERS AND SETTERS*/

    function getTokenData(bytes32 tokenId) public view returns (bytes32 tokenData) {
        tokenData = bytes32(getUint(_getTokenDataKey(tokenId)));
    }

    function _setTokenData(bytes32 tokenId, bytes32 tokenData) internal {
        _setUint(_getTokenDataKey(tokenId), uint256(tokenData));
    }

    function getOriginalChain(bytes32 tokenId) public view returns (string memory originalChain) {
        bytes32 originalChainBytes = bytes32(getUint(_getOriginalChainKey(tokenId)));
        originalChain = originalChainBytes.toTrimmedString();
    }

    function _setOriginalChain(bytes32 tokenId, string memory originalChain) internal {
        _setUint(_getOriginalChainKey(tokenId), uint256(originalChain.toBytes32()));
    }

    function getTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        tokenId = bytes32(getUint(_getTokenIdKey(tokenAddress)));
    }

    function _setTokenId(address tokenAddress, bytes32 tokenId) internal {
        _setUint(_getTokenIdKey(tokenAddress), uint256(tokenId));
    }

    function getTokenMintLimit(bytes32 tokenId) public view returns (uint256 mintLimit) {
        mintLimit = getUint(_getTokenMintLimitKey(tokenId));
    }

    function _setTokenMintLimit(bytes32 tokenId, uint256 mintLimit) internal {
        _setUint(_getTokenMintLimitKey(tokenId), mintLimit);
    }

    function getTokenMintAmount(bytes32 tokenId) public view returns (uint256 amount) {
        amount = getUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours));
    }

    function _setTokenMintAmount(bytes32 tokenId, uint256 amount) internal {
        uint256 limit = getTokenMintLimit(tokenId);
        if (limit > 0 && amount > limit) revert ExceedMintLimit(tokenId);

        _setUint(_getTokenMintAmountKey(tokenId, block.timestamp / 6 hours), amount);
    }

    function getTokenAddress(bytes32 tokenId) public view returns (address) {
        return getTokenData(tokenId).getAddress();
    }

    function getOriginTokenId(address tokenAddress) public view returns (bytes32) {
        return keccak256(abi.encode(chainNameHash, tokenAddress));
    }

    /* REGISTER AND DEPLOY TOKENS */

    function deployInterchainToken(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals,
        uint256 cap,
        address owner,
        bytes32 salt,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable {
        salt = keccak256(abi.encode(msg.sender, salt));
        address tokenAddress = _deployToken(tokenName, tokenSymbol, decimals, cap, salt, owner);
        (bytes32 tokenId, bytes32 tokenData) = _registerToken(tokenAddress);
        string memory symbol = _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
        if (gateway.tokenAddresses(symbol) == tokenAddress) revert GatewayToken();
    }

    function registerOriginToken(address tokenAddress) external returns (bytes32 tokenId) {
        (, string memory symbol, ) = _validateOriginToken(tokenAddress);
        if (gateway.tokenAddresses(symbol) == tokenAddress) revert GatewayToken();
        (tokenId, ) = _registerToken(tokenAddress);
    }

    function registerOriginGatewayToken(string calldata symbol) external onlyOwner returns (bytes32 tokenId) {
        address tokenAddress = gateway.tokenAddresses(symbol);
        if (tokenAddress == address(0)) revert NotGatewayToken();
        tokenId = getOriginTokenId(tokenAddress);
        _setTokenData(tokenId, LinkedTokenData.createGatewayTokenData(tokenAddress, true, symbol));
        _setTokenId(tokenAddress, tokenId);
        emit TokenRegistered(tokenId, tokenAddress, true, true, false);
    }

    function registerRemoteGatewayToken(string calldata symbol, bytes32 tokenId, string calldata origin) external onlyOwner {
        address tokenAddress = gateway.tokenAddresses(symbol);
        if (tokenAddress == address(0)) revert NotGatewayToken();
        _setTokenData(tokenId, LinkedTokenData.createGatewayTokenData(tokenAddress, false, symbol));
        _setTokenId(tokenAddress, tokenId);
        _setOriginalChain(tokenId, origin);
        emit TokenRegistered(tokenId, tokenAddress, false, true, false);
    }

    function registerOriginTokenAndDeployRemoteTokens(
        address tokenAddress,
        string[] calldata destinationChains,
        uint256[] calldata gasValues
    ) external payable override returns (bytes32 tokenId) {
        bytes32 tokenData;
        (tokenId, tokenData) = _registerToken(tokenAddress);
        string memory symbol = _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
        if (gateway.tokenAddresses(symbol) == tokenAddress) revert GatewayToken();
    }

    function deployRemoteTokens(bytes32 tokenId, string[] calldata destinationChains, uint256[] calldata gasValues) external payable {
        bytes32 tokenData = getTokenData(tokenId);
        if (!tokenData.isOrigin()) revert NotOriginToken();
        _deployRemoteTokens(destinationChains, gasValues, tokenId, tokenData);
    }

    function setTokenMintLimit(bytes32 tokenId, uint256 mintLimit) external onlyOwner {
        _setTokenMintLimit(tokenId, mintLimit);
    }

    /* SEND TOKENS */

    function sendToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) external payable {
        _takeToken(tokenId, msg.sender, amount);
        _sendToken(tokenId, destinationChain, destinationAddress, amount);
    }

    function callContractWithInterToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) external payable {
        _takeToken(tokenId, msg.sender, amount);
        _sendTokenWithData(
            tokenId,
            chainName.toTrimmedString(),
            AddressBytesUtils.toBytes(msg.sender),
            destinationChain,
            destinationAddress,
            amount,
            data
        );
    }

    /* EXECUTE AND EXECUTE WITH TOKEN */

    function _execute(string calldata sourceChain, string calldata sourceAddress, bytes calldata payload) internal override {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) return;
        (bool success, ) = address(this).call(payload);
        if (!success) revert ExecutionFailed();
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata /*symbol*/,
        uint256 /*amount*/
    ) internal override {
        if (!linkerRouter.validateSender(sourceChain, sourceAddress)) return;
        (bool success, ) = address(this).call(payload);
        if (!success) revert ExecutionFailed();
    }

    /* ONLY SELF FUNCTIONS */

    function selfDeployToken(
        bytes32 tokenId,
        string memory origin,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 decimals,
        bool isGateway
    ) public onlySelf {
        {
            bytes32 tokenData = getTokenData(tokenId);
            if (tokenData != bytes32(0)) {
                if (isGateway && !tokenData.isGateway()) {
                    _setTokenData(tokenId, LinkedTokenData.createRemoteGatewayTokenData(tokenData.getAddress()));
                    return;
                }
                revert AlreadyRegistered();
            }
        }
        address tokenAddress = _deployToken(tokenName, tokenSymbol, decimals, 0, tokenId, address(this));
        if (isGateway) {
            _setTokenData(tokenId, LinkedTokenData.createRemoteGatewayTokenData(tokenAddress));
        } else {
            _setTokenData(tokenId, LinkedTokenData.createTokenData(tokenAddress, false));
        }
        _setTokenId(tokenAddress, tokenId);
        _setOriginalChain(tokenId, origin);
        emit TokenRegistered(tokenId, tokenAddress, false, false, isGateway);
    }

    function selfGiveToken(bytes32 tokenId, bytes calldata destinationAddress, uint256 amount) public onlySelf {
        _giveToken(tokenId, AddressBytesUtils.toAddress(destinationAddress), amount);
    }

    function selfGiveTokenWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) public onlySelf {
        _giveTokenWithData(tokenId, AddressBytesUtils.toAddress(destinationAddress), amount, sourceChain, sourceAddress, data);
    }

    function selfSendToken(
        bytes32 tokenId,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount
    ) public onlySelf {
        _sendToken(tokenId, destinationChain, destinationAddress, amount);
    }

    function selfSendTokenWithData(
        bytes32 tokenId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata data
    ) public onlySelf {
        _sendTokenWithData(tokenId, sourceChain, sourceAddress, destinationChain, destinationAddress, amount, data);
    }

    /* HELPER FUNCTIONS */

    function _registerToken(address tokenAddress) internal returns (bytes32 tokenId, bytes32 tokenData) {
        if (getTokenId(tokenAddress) != bytes32(0)) revert AlreadyRegistered();
        tokenId = getOriginTokenId(tokenAddress);
        if (getTokenData(tokenId) != bytes32(0)) revert AlreadyRegistered();
        tokenData = LinkedTokenData.createTokenData(tokenAddress, true);
        _setTokenData(tokenId, tokenData);
        _setTokenId(tokenAddress, tokenId);
        emit TokenRegistered(tokenId, tokenAddress, true, false, false);
    }

    function _deployRemoteTokens(
        string[] calldata destinationChains,
        uint256[] calldata gasValues,
        bytes32 tokenId,
        bytes32 tokenData
    ) internal returns (string memory) {
        (string memory name, string memory symbol, uint8 decimals) = _validateOriginToken(tokenData.getAddress());
        uint256 length = destinationChains.length;
        if (gasValues.length != length) revert LengthMismatch();
        for (uint256 i; i < length; ++i) {
            uint256 gasValue = gasValues[i];
            if (tokenData.isGateway() && linkerRouter.supportedByGateway(destinationChains[i])) revert SupportedByGateway();
            bytes memory payload = abi.encodeWithSelector(
                this.selfDeployToken.selector,
                tokenId,
                chainName.toTrimmedString(),
                name,
                symbol,
                decimals,
                tokenData.isGateway()
            );
            _callContract(destinationChains[i], payload, gasValues[i]);
            emit RemoteTokenRegisterInitialized(tokenId, destinationChains[i], gasValue);
        }
        return symbol;
    }

    function _deployToken(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals,
        uint256 cap,
        bytes32 salt,
        address owner
    ) internal returns (address tokenAddress) {
        (bool success, bytes memory data) = address(tokenDeployer).delegatecall(abi.encodeWithSelector(
            tokenDeployer.deployToken.selector, owner, tokenName, tokenSymbol, decimals, cap, salt)
        );
        if (!success) revert TokenDeploymentFailed();
        tokenAddress = abi.decode(data, (address));
        //tokenAddress = tokenDeployer.deployToken(owner, tokenName, tokenSymbol, decimals, cap, salt);

        emit TokenDeployed(tokenAddress, tokenName, tokenSymbol, decimals, cap, owner);
    }

    function _validateOriginToken(address tokenAddress) internal returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    function _sendToken(bytes32 tokenId, string calldata destinationChain, bytes calldata destinationaddress, uint256 amount) internal {
        bytes32 tokenData = getTokenData(tokenId);
        bytes memory payload;
        if (tokenData.isGateway()) {
            if (linkerRouter.supportedByGateway(destinationChain)) {
                payload = abi.encodeWithSelector(this.selfGiveToken.selector, tokenId, destinationaddress, amount);
                _callContractWithToken(destinationChain, tokenData, amount, payload);
            } else if (tokenData.isOrigin()) {
                payload = abi.encodeWithSelector(this.selfGiveToken.selector, tokenId, destinationaddress, amount);
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(this.selfSendToken.selector, tokenId, destinationChain, destinationaddress, amount);
                _callContractWithToken(getOriginalChain(tokenId), tokenData, amount, payload);
            }
        } else if (tokenData.isRemoteGateway()) {
            if (keccak256(bytes(destinationChain)) == keccak256(bytes(getOriginalChain(tokenId)))) {
                payload = abi.encodeWithSelector(this.selfGiveToken.selector, tokenId, destinationaddress, amount);
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(this.selfSendToken.selector, tokenId, destinationChain, destinationaddress, amount);
                _callContract(getOriginalChain(tokenId), payload, msg.value);
            }
        } else {
            payload = abi.encodeWithSelector(this.selfGiveToken.selector, tokenId, destinationaddress, amount);
            _callContract(destinationChain, payload, msg.value);
        }
        emit Sending(destinationChain, destinationaddress, amount);
    }

    function _sendTokenWithData(
        bytes32 tokenId,
        string memory sourceChain,
        bytes memory sourceAddress,
        string calldata destinationChain,
        bytes calldata destinationaddress,
        uint256 amount,
        bytes calldata data
    ) internal {
        bytes32 tokenData = getTokenData(tokenId);
        bytes memory payload;
        if (tokenData.isGateway()) {
            if (linkerRouter.supportedByGateway(destinationChain)) {
                payload = abi.encodeWithSelector(
                    this.selfGiveTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContractWithToken(destinationChain, tokenData, amount, payload);
            } else if (tokenData.isOrigin()) {
                payload = abi.encodeWithSelector(
                    this.selfGiveTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(
                    this.selfSendTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationChain,
                    destinationaddress,
                    amount,
                    data
                );
                _callContractWithToken(getOriginalChain(tokenId), tokenData, amount, payload);
            }
        } else if (tokenData.isRemoteGateway()) {
            if (keccak256(bytes(destinationChain)) == keccak256(bytes(getOriginalChain(tokenId)))) {
                payload = abi.encodeWithSelector(
                    this.selfGiveTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(destinationChain, payload, msg.value);
            } else {
                payload = abi.encodeWithSelector(
                    this.selfSendTokenWithData.selector,
                    tokenId,
                    sourceChain,
                    sourceAddress,
                    destinationChain,
                    destinationaddress,
                    amount,
                    data
                );
                _callContract(getOriginalChain(tokenId), payload, msg.value);
            }
        } else {
            payload = abi.encodeWithSelector(this.selfGiveTokenWithData.selector, tokenId, sourceChain, sourceAddress, destinationaddress, amount, data);
            _callContract(destinationChain, payload, msg.value);
        }
        emit SendingWithData(destinationChain, destinationaddress, amount, msg.sender, data);
    }

    function _callContract(string memory destinationChain, bytes memory payload, uint256 gasValue) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        if (gasValue > 0) {
            gasService.payNativeGasForContractCall{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _callContractWithToken(string memory destinationChain, bytes32 tokenData, uint256 amount, bytes memory payload) internal {
        string memory destinationAddress = linkerRouter.getRemoteAddress(destinationChain);
        uint256 gasValue = msg.value;
        string memory symbol = tokenData.getSymbol();
        if (gasValue > 0) {
            gasService.payNativeGasForContractCallWithToken{ value: gasValue }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                symbol,
                amount,
                msg.sender
            );
        }
        IERC20Named(tokenData.getAddress()).approve(address(gateway), amount);
        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }

    function _transfer(address tokenAddress, address destinationaddress, uint256 amount) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(abi.encodeWithSelector(IERC20.transfer.selector, destinationaddress, amount));
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }

    function _transferFrom(address tokenAddress, address from, uint256 amount) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFromFailed();
    }

    function _mint(address tokenAddress, address destinationaddress, uint256 amount) internal {
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintableCapped.mint.selector, destinationaddress, amount));

        if (!success || tokenAddress.code.length == 0) revert MintFailed();
    }

    function _burn(address tokenAddress, address from, uint256 amount) internal {
        (bool success, ) = tokenAddress.call(abi.encodeWithSelector(IERC20BurnableMintableCapped.burnFrom.selector, from, amount));

        if (!success || tokenAddress.code.length == 0) revert BurnFailed();
    }

    function _giveToken(bytes32 tokenId, address destinationaddress, uint256 amount) internal {
        _setTokenMintAmount(tokenId, getTokenMintAmount(tokenId) + amount);

        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();

        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transfer(tokenAddress, destinationaddress, amount);
        } else {
            _mint(tokenAddress, destinationaddress, amount);
        }
    }

    function _takeToken(bytes32 tokenId, address from, uint256 amount) internal {
        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transferFrom(tokenAddress, from, amount);
        } else {
            _burn(tokenAddress, from, amount);
        }
    }

    function _giveTokenWithData(
        bytes32 tokenId,
        address destinationaddress,
        uint256 amount,
        string calldata sourceChain,
        bytes memory sourceAddress,
        bytes memory data
    ) internal {
        _setTokenMintAmount(tokenId, getTokenMintAmount(tokenId) + amount);

        bytes32 tokenData = getTokenData(tokenId);
        address tokenAddress = tokenData.getAddress();
        if (tokenData.isOrigin() || tokenData.isGateway()) {
            _transfer(tokenAddress, destinationaddress, amount);
        } else {
            _mint(tokenAddress, destinationaddress, amount);
        }
        IInterTokenExecutable(destinationaddress).exectuteWithInterToken(tokenAddress, sourceChain, sourceAddress, amount, data);
    }
}