pragma solidity ^0.5.0;

import "Ownable.sol";
//import "Ownable.sol";
import "IFeatured.sol";
import "Pausable.sol";
import "Freezable.sol";

/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract Featured is IFeatured, Pausable, Freezable, Ownable {
    uint8 public _enabledFeatures;

    modifier enabled(uint8 feature) {
        require(isEnabled(feature), "Token feature is not enabled");
        _;
    }

    constructor (address owner, uint8 features) public {
        _enable(features);
        _transferOwnership(owner);
    }

    /**
     * @dev Enable features. Call from SRC20 token constructor.
     * @param features ORed features to enable.
     */
    function _enable(uint8 features) internal {
        _enabledFeatures = features;
    }

    /**
     * @dev Returns if feature is enabled.
     * @param feature Feature constant to check if enabled.
     * @return True if feature is enabled.
     */
    function isEnabled(uint8 feature) public view returns (bool) {
        return _enabledFeatures & feature > 0;
    }

    /**
     * @dev Call to check if transfer will pass from feature contract stand point.
     *
     * @param from The address to transfer from.
     * @param to The address to send tokens to.
     *
     * @return True if the transfer is allowed
     */
    function checkTransfer(address from, address to) external view returns (bool) {
        return !_isAccountFrozen(from) && !_isAccountFrozen(to) && !paused();
    }

    /**
    * @dev Check if specified account is frozen. Token issuer can
    * freeze any account at any time and stop accounts making
    * transfers.
    *
    * @return True if account is frozen.
    */
    function isAccountFrozen(address account) external view returns (bool) {
        return _isAccountFrozen(account);
    }

    /**
     * @dev Freezes account.
     * Emits AccountFrozen event.
     */
    function freezeAccount(address account)
    external
    enabled(AccountFreezing)
    onlyOwner
    {
        _freezeAccount(account);
    }

    /**
     * @dev Unfreezes account.
     * Emits AccountUnfrozen event.
     */
    function unfreezeAccount(address account)
    external
    enabled(AccountFreezing)
    onlyOwner
    {
        _unfreezeAccount(account);
    }

    /**
     * @dev Check if token is frozen. Token issuer can freeze token
     * at any time and stop all accounts from making transfers. When
     * token is frozen, isFrozen(account) returns true for every
     * account.
     *
     * @return True if token is frozen.
     */
    function isTokenPaused() external view returns (bool) {
        return paused();
    }

    /**
     * @dev Pauses token.
     * Emits TokenPaused event.
     */
    function pauseToken()
    external
    enabled(Pausable)
    onlyOwner
    {
        _pause();
    }

    /**
     * @dev Unpause token.
     * Emits TokenUnPaused event.
     */
    function unPauseToken()
    external
    enabled(Pausable)
    onlyOwner
    {
        _unpause();
    }
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "IFreezable.sol";
import "IPausable.sol";

/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract IFeatured is IPausable, IFreezable {
    
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event TokenFrozen();
    event TokenUnfrozen();
    
    uint8 public constant ForceTransfer = 0x01;
    uint8 public constant Pausable = 0x02;
    uint8 public constant AccountBurning = 0x04;
    uint8 public constant AccountFreezing = 0x08;

    function _enable(uint8 features) internal;
    function isEnabled(uint8 feature) public view returns (bool);

    function checkTransfer(address from, address to) external view returns (bool);
    function isAccountFrozen(address account) external view returns (bool);
    function freezeAccount(address account) external;
    function unfreezeAccount(address account) external;
    function isTokenPaused() external view returns (bool);
    function pauseToken() external;
    function unPauseToken() external;
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available events
 * `AccountFrozen` and `AccountUnfroze` and it will make sure that any child
 * that implements all necessary functionality.
 */
contract IFreezable {
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    function _freezeAccount(address account) internal;
    function _unfreezeAccount(address account) internal;
    function _isAccountFrozen(address account) internal view returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the functions are implemented.
 */
contract IPausable{
    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool);

    function _pause() internal;
    function _unpause() internal;
}

pragma solidity ^0.5.0;

import "IPausable.sol";

/**
 * @title Pausable token feature
 * @dev Base contract providing implementation for token pausing and
 * checking if token is paused.
 */
contract Pausable is IPausable {
    bool private _paused;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Sets stopped state.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.0;

import "IFreezable.sol";

/**
 * @title Freezable account
 * @dev Base contract providing internal methods for freezing,
 * unfreezing and checking accounts' status.
 */
contract Freezable is IFreezable {
    mapping (address => bool) private _frozen;

    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    /**
     * @dev Freeze an account
     */
    function _freezeAccount(address account) internal {
        _frozen[account] = true;
        emit AccountFrozen(account);
    }

    /**
     * @dev Unfreeze an account
     */
    function _unfreezeAccount(address account) internal {
         _frozen[account] = false;
         emit AccountUnfrozen(account);
    }

    /**
     * @dev Check if an account is frozen. If token is frozen, all
     * of accounts are frozen also.
     * @return bool
     */
    function _isAccountFrozen(address account) internal view returns (bool) {
         return _frozen[account];
    }
}