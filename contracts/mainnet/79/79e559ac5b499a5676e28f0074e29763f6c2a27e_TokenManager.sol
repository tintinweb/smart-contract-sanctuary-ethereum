// $$$$$$$$\        $$\                                 $$\      $$\
// \__$$  __|       $$ |                                $$$\    $$$ |
//    $$ | $$$$$$\  $$ |  $$\  $$$$$$\  $$$$$$$\        $$$$\  $$$$ | $$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\
//    $$ |$$  __$$\ $$ | $$  |$$  __$$\ $$  __$$\       $$\$$\$$ $$ | \____$$\ $$  __$$\  \____$$\ $$  __$$\ $$  __$$\ $$  __$$\
//    $$ |$$ /  $$ |$$$$$$  / $$$$$$$$ |$$ |  $$ |      $$ \$$$  $$ | $$$$$$$ |$$ |  $$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|
//    $$ |$$ |  $$ |$$  _$$<  $$   ____|$$ |  $$ |      $$ |\$  /$$ |$$  __$$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$   ____|$$ |
//    $$ |\$$$$$$  |$$ | \$$\ \$$$$$$$\ $$ |  $$ |      $$ | \_/ $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ $$ |
//    \__| \______/ \__|  \__| \_______|\__|  \__|      \__|     \__| \_______|\__|  \__| \_______| \____$$ | \_______|\__|
//                                                                                                 $$\   $$ |
//                                                                                                 \$$$$$$  |
//                                                                                                  \______/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../security/Pausable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";
import "../interfaces/ITokenManager.sol";

contract TokenManager is ITokenManager, ERC2771ContextUpgradeable, OwnableUpgradeable, Pausable {
    mapping(address => TokenInfo) public override tokensInfo;

    // Excess State Transfer Fee Percentage
    mapping(address => uint256) public override excessStateTransferFeePerc;

    event FeeChanged(address indexed tokenAddress, uint256 indexed equilibriumFee, uint256 indexed maxFee);
    event ExcessStateTransferFeePercChanged(address indexed tokenAddress, uint256 indexed fee);

    modifier tokenChecks(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(tokensInfo[tokenAddress].supportedToken, "Token not supported");

        _;
    }

    /**
     * First key is toChainId and second key is token address being deposited on current chain
     */
    mapping(uint256 => mapping(address => TokenConfig)) public depositConfig;

    /**
     * Store min/max amount of token to transfer based on token address
     */
    mapping(address => TokenConfig) public transferConfig;

    function initialize(address trustedForwarder, address pauser) external initializer {
        __ERC2771Context_init(trustedForwarder);
        __Ownable_init();
        __Pausable_init(pauser);
    }

    function getEquilibriumFee(address tokenAddress) public view override returns (uint256) {
        return tokensInfo[tokenAddress].equilibriumFee;
    }

    function getMaxFee(address tokenAddress) public view override returns (uint256) {
        return tokensInfo[tokenAddress].maxFee;
    }

    function changeFee(
        address tokenAddress,
        uint256 _equilibriumFee,
        uint256 _maxFee
    ) external override onlyOwner whenNotPaused {
        require(_equilibriumFee != 0, "Equilibrium Fee cannot be 0");
        require(_maxFee != 0, "Max Fee cannot be 0");
        require(_equilibriumFee <= _maxFee && _maxFee <= 10000000000, "Max Fee cannot be greater than 100%");
        tokensInfo[tokenAddress].equilibriumFee = _equilibriumFee;
        tokensInfo[tokenAddress].maxFee = _maxFee;
        emit FeeChanged(tokenAddress, tokensInfo[tokenAddress].equilibriumFee, tokensInfo[tokenAddress].maxFee);
    }

    function changeExcessStateFee(address _tokenAddress, uint256 _excessStateFeePer)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(_tokenAddress != address(0), "Token address cannot be 0");
        require(_excessStateFeePer != 0, "Excess State Fee Percentage cannot be 0");
        excessStateTransferFeePerc[_tokenAddress] = _excessStateFeePer;
        emit ExcessStateTransferFeePercChanged(_tokenAddress, _excessStateFeePer);
    }

    function setTokenTransferOverhead(address tokenAddress, uint256 gasOverhead)
        external
        tokenChecks(tokenAddress)
        onlyOwner
    {
        tokensInfo[tokenAddress].transferOverhead = gasOverhead;
    }

    /**
     * Set DepositConfig for the given combination of toChainId, tokenAddress.
     * This is used while depositing token in Liquidity Pool. Based on the destination chainid
     * min and max deposit amount is checked.
     */
    function setDepositConfig(
        uint256[] memory toChainId,
        address[] memory tokenAddresses,
        TokenConfig[] memory tokenConfig
    ) external onlyOwner {
        require(
            (toChainId.length == tokenAddresses.length) && (tokenAddresses.length == tokenConfig.length),
            " ERR_ARRAY_LENGTH_MISMATCH"
        );
        uint256 length = tokenConfig.length;
        for (uint256 index; index < length; ) {
            depositConfig[toChainId[index]][tokenAddresses[index]].min = tokenConfig[index].min;
            depositConfig[toChainId[index]][tokenAddresses[index]].max = tokenConfig[index].max;
            unchecked {
                ++index;
            }
        }
    }

    function addSupportedToken(
        address tokenAddress,
        uint256 minCapLimit,
        uint256 maxCapLimit,
        uint256 equilibriumFee,
        uint256 maxFee,
        uint256 transferOverhead
    ) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(maxCapLimit > minCapLimit, "maxCapLimit > minCapLimit");
        tokensInfo[tokenAddress].supportedToken = true;
        transferConfig[tokenAddress].min = minCapLimit;
        transferConfig[tokenAddress].max = maxCapLimit;
        tokensInfo[tokenAddress].tokenConfig = transferConfig[tokenAddress];
        tokensInfo[tokenAddress].equilibriumFee = equilibriumFee;
        tokensInfo[tokenAddress].maxFee = maxFee;
        tokensInfo[tokenAddress].transferOverhead = transferOverhead;
    }

    function removeSupportedToken(address tokenAddress) external tokenChecks(tokenAddress) onlyOwner {
        tokensInfo[tokenAddress].supportedToken = false;
    }

    function updateTokenCap(
        address tokenAddress,
        uint256 minCapLimit,
        uint256 maxCapLimit
    ) external tokenChecks(tokenAddress) onlyOwner {
        require(maxCapLimit > minCapLimit, "maxCapLimit > minCapLimit");
        transferConfig[tokenAddress].min = minCapLimit;
        transferConfig[tokenAddress].max = maxCapLimit;
    }

    function getTokensInfo(address tokenAddress) public view override returns (TokenInfo memory) {
        TokenInfo memory tokenInfo = TokenInfo(
            tokensInfo[tokenAddress].transferOverhead,
            tokensInfo[tokenAddress].supportedToken,
            tokensInfo[tokenAddress].equilibriumFee,
            tokensInfo[tokenAddress].maxFee,
            transferConfig[tokenAddress]
        );
        return tokenInfo;
    }

    function getDepositConfig(uint256 toChainId, address tokenAddress)
        public
        view
        override
        returns (TokenConfig memory)
    {
        return depositConfig[toChainId][tokenAddress];
    }

    function getTransferConfig(address tokenAddress) public view override returns (TokenConfig memory) {
        return transferConfig[tokenAddress];
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function setTrustedForwarder(address _tf) external onlyOwner {
        _setTrustedForwarder(_tf);
    }
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable, PausableUpgradeable {
    address private _pauser;

    event PauserChanged(address indexed previousPauser, address indexed newPauser);

    /**
     * @dev The pausable constructor sets the original `pauser` of the contract to the sender
     * account & Initializes the contract in unpaused state..
     */
    function __Pausable_init(address pauser) internal initializer {
        require(pauser != address(0), "Pauser Address cannot be 0");
        __Pausable_init();
        _pauser = pauser;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isPauser(address pauser) public view returns (bool) {
        return pauser == _pauser;
    }

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(isPauser(msg.sender), "Only pauser is allowed to perform this operation");
        _;
    }

    /**
     * @dev Allows the current pauser to transfer control of the contract to a newPauser.
     * @param newPauser The address to transfer pauserShip to.
     */
    function changePauser(address newPauser) public onlyPauser whenNotPaused {
        _changePauser(newPauser);
    }

    /**
     * @dev Transfers control of the contract to a newPauser.
     * @param newPauser The address to transfer ownership to.
     */
    function _changePauser(address newPauser) internal {
        require(newPauser != address(0));
        emit PauserChanged(_pauser, newPauser);
        _pauser = newPauser;
    }

    function renouncePauser() external virtual onlyPauser whenNotPaused {
        emit PauserChanged(_pauser, address(0));
        _pauser = address(0);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Here _trustedForwarder is made internal instead of private
 * so it can be changed via Child contracts with a setter method.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    event TrustedForwarderChanged(address indexed _tf);

    address internal _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function _setTrustedForwarder(address _tf) internal virtual {
        require(_tf != address(0), "TrustedForwarder can't be 0");
        _trustedForwarder = _tf;
        emit TrustedForwarderChanged(_tf);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../structures/TokenConfig.sol";

interface ITokenManager {
    function getEquilibriumFee(address tokenAddress) external view returns (uint256);

    function getMaxFee(address tokenAddress) external view returns (uint256);

    function changeFee(
        address tokenAddress,
        uint256 _equilibriumFee,
        uint256 _maxFee
    ) external;

    function tokensInfo(address tokenAddress)
        external
        view
        returns (
            uint256 transferOverhead,
            bool supportedToken,
            uint256 equilibriumFee,
            uint256 maxFee,
            TokenConfig memory config
        );

    function excessStateTransferFeePerc(address tokenAddress) external view returns (uint256);

    function getTokensInfo(address tokenAddress) external view returns (TokenInfo memory);

    function getDepositConfig(uint256 toChainId, address tokenAddress) external view returns (TokenConfig memory);

    function getTransferConfig(address tokenAddress) external view returns (TokenConfig memory);

    function changeExcessStateFee(address _tokenAddress, uint256 _excessStateFeePer) external;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

struct TokenInfo {
    uint256 transferOverhead;
    bool supportedToken;
    uint256 equilibriumFee; // Percentage fee Represented in basis points
    uint256 maxFee; // Percentage fee Represented in basis points
    TokenConfig tokenConfig;
}

struct TokenConfig {
    uint256 min;
    uint256 max;
}