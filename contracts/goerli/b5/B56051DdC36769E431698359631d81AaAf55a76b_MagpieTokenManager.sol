// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './security/Pausable.sol';
import './interfaces/IMagpieTokenManager.sol';

contract MagpieTokenManager is IMagpieTokenManager, Ownable, Pausable {
  mapping(address => TokenInfo) public override tokensInfo;

  event FeeChanged(
    address indexed tokenAddress,
    uint256 indexed equilibriumFee,
    uint256 indexed maxFee
  );

  modifier tokenChecks(address tokenAddress) {
    require(tokenAddress != address(0), 'Token address cannot be 0');
    require(tokensInfo[tokenAddress].supportedToken, 'Token not supported');

    _;
  }

  /**
     First key: toChainId
     second key: token address
     */
  mapping(uint256 => mapping(address => TokenConfig)) public depositConfig;

  /**
   * Store min/max amount of token to transfer based on token address
   */
  mapping(address => TokenConfig) public transferConfig;

  constructor(address pauserAddress) Pausable(pauserAddress) {}

  function getStableStateFee(address tokenAddress) public view override returns (uint256) {
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
    require(_equilibriumFee != 0, 'Equilibrium Fee cannot be 0');
    require(_maxFee != 0, 'Max Fee cannot be 0');
    tokensInfo[tokenAddress].equilibriumFee = _equilibriumFee;
    tokensInfo[tokenAddress].maxFee = _maxFee;
    emit FeeChanged(
      tokenAddress,
      tokensInfo[tokenAddress].equilibriumFee,
      tokensInfo[tokenAddress].maxFee
    );
  }

  function setTokenTransferOverhead(address tokenAddress, uint256 gasOverhead)
    external
    tokenChecks(tokenAddress)
    onlyOwner
  {
    tokensInfo[tokenAddress].transferOverhead = gasOverhead;
  }

  /**
   * This is used while depositing token in Magpie Pool.
   * Based on the destination chainid the min and max deposit amount is checked.
   */
  function setDepositConfig(
    uint256[] memory toChainId,
    address[] memory tokenAddresses,
    TokenConfig[] memory tokenConfig
  ) external onlyOwner {
    require(
      (toChainId.length == tokenAddresses.length) && (tokenAddresses.length == tokenConfig.length),
      ' ERR_ARRAY_LENGTH_MISMATCH'
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
    require(tokenAddress != address(0), 'Token address cannot be 0');
    require(maxCapLimit > minCapLimit, 'maxCapLimit > minCapLimit');
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
    require(maxCapLimit > minCapLimit, 'maxCapLimit > minCapLimit');
    transferConfig[tokenAddress].min = minCapLimit;
    transferConfig[tokenAddress].max = maxCapLimit;
  }

  function getTokensConfig(address tokenAddress) public view override returns (TokenInfo memory) {
    TokenInfo memory tokenInfo = TokenInfo(
      tokensInfo[tokenAddress].transferOverhead,
      tokensInfo[tokenAddress].supportedToken,
      tokensInfo[tokenAddress].equilibriumFee,
      tokensInfo[tokenAddress].maxFee,
      transferConfig[tokenAddress]
    );
    return tokenInfo;
  }

  function getDepositInfo(uint256 toChainId, address tokenAddress)
    public
    view
    override
    returns (TokenConfig memory)
  {
    return depositConfig[toChainId][tokenAddress];
  }

  function getTransferInfo(address tokenAddress) public view override returns (TokenConfig memory) {
    return transferConfig[tokenAddress];
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import {Pausable as OpenZeppelinPausable} from '@openzeppelin/contracts/security/Pausable.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is OpenZeppelinPausable {
  address private _pauser;

  event PauserChanged(address indexed previousPauser, address indexed newPauser);

  /**
   * @dev The pausable constructor sets the original `pauser` of the contract to the sender
   * account & Initializes the contract in unpaused state..
   */
  constructor (address pauser) {
    require(pauser != address(0), 'Pauser Address cannot be 0');
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
    require(isPauser(msg.sender), 'Only pauser is allowed to perform this operation');
    _;
  }

  /**
   * @dev Allows the current pauser to transfer control of the contract to a newPauser.
   * @param newPauser The address to transfer pauserShip to.
   */
  function changePauser(address newPauser) public onlyPauser {
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

  function renouncePauser() external virtual onlyPauser {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieTokenManager {
  
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

  function getStableStateFee(address tokenAddress) external view returns (uint256);

  function getMaxFee(address tokenAddress) external view returns (uint256);

  function changeFee(
    address tokenAddress,
    uint256 _equilibriumFee,
    uint256 _maxFee
  ) external; /* updateFee */

  function tokensInfo(address tokenAddress)
    external
    view
    returns (
      uint256 transferOverhead,
      bool supportedToken,
      uint256 equilibriumFee,
      uint256 maxFee,
      TokenConfig memory config
    ); /*tokensConfig */

  function getTokensConfig(address tokenAddress) external view returns (TokenInfo memory);

  function getDepositInfo(uint256 toChainId, address tokenAddress)
    external
    view
    returns (TokenConfig memory);

  function getTransferInfo(address tokenAddress) external view returns (TokenConfig memory);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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