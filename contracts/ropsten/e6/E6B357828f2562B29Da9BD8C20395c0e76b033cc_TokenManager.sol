// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../metatx/ERC2771Context.sol";
import "../interfaces/ITokenManager.sol";

contract TokenManager is ITokenManager, ERC2771Context, Ownable, Pausable {

    mapping(address => TokenInfo) public tokensInfo;

    event FeeChanged(address indexed tokenAddress, uint256 indexed equilibriumFee, uint256 indexed maxFee);

    modifier tokenChecks(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(tokensInfo[tokenAddress].supportedToken, "Token not supported");

        _;
    }

    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {
        // Empty Constructor
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
        tokensInfo[tokenAddress].equilibriumFee = _equilibriumFee;
        tokensInfo[tokenAddress].maxFee = _maxFee;
        emit FeeChanged(tokenAddress, tokensInfo[tokenAddress].equilibriumFee, tokensInfo[tokenAddress].maxFee);
    }

    function setTokenTransferOverhead(address tokenAddress, uint256 gasOverhead)
        external
        tokenChecks(tokenAddress)
        onlyOwner
    {
        tokensInfo[tokenAddress].transferOverhead = gasOverhead;
    }

    function addSupportedToken(
        address tokenAddress,
        uint256 minCapLimit,
        uint256 maxCapLimit,
        uint256 equilibriumFee,
        uint256 maxFee
    ) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be 0");
        require(maxCapLimit > minCapLimit, "maxCapLimit > minCapLimit");
        tokensInfo[tokenAddress].supportedToken = true;
        tokensInfo[tokenAddress].minCap = minCapLimit;
        tokensInfo[tokenAddress].maxCap = maxCapLimit;
        tokensInfo[tokenAddress].equilibriumFee = equilibriumFee;
        tokensInfo[tokenAddress].maxFee = maxFee;
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
        tokensInfo[tokenAddress].minCap = minCapLimit;
        tokensInfo[tokenAddress].maxCap = maxCapLimit;
    }

    function getTokensInfo(address tokenAddress) public view override returns (TokenInfo memory) {
        TokenInfo memory tokenInfo = TokenInfo(
            tokensInfo[tokenAddress].transferOverhead,
            tokensInfo[tokenAddress].supportedToken,
            tokensInfo[tokenAddress].minCap,
            tokensInfo[tokenAddress].maxCap, 
            tokensInfo[tokenAddress].equilibriumFee,
            tokensInfo[tokenAddress].maxFee
        );
        return tokenInfo;
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address internal _trustedForwarder;

    constructor(address trustedForwarder) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenManager {

    struct TokenInfo {
        uint256 transferOverhead;
        bool supportedToken;
        uint256 minCap;
        uint256 maxCap;
        uint256 equilibriumFee; // Percentage fee Represented in basis points
        uint256 maxFee; // Percentage fee Represented in basis points
    }
    
    function getEquilibriumFee(address tokenAddress) external view returns (uint256);

    function getMaxFee(address tokenAddress) external view returns (uint256);

    function changeFee(
        address tokenAddress,
        uint256 _equilibriumFee,
        uint256 _maxFee
    ) external;

    function getTokensInfo(address tokenAddress) external view returns (TokenInfo memory);
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