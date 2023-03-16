// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "Ownable.sol";

contract FranklinTokenWhitelist is Ownable {
    /// ============ EVENTS ============
    /// @notice Emits address of the ERC20 token approved
    event TokenApproved(address _token);
    /// @notice Emits address of the ERC20 token removed
    event TokenRemoved(address _token);

    /// ============ STORAGE VARIABLES ============

    /** @dev
      The approvedTokens array and registeredToken mapping are used to manage
      the tokens approved for payroll. This is used to ensure that tokens in
      the treasury which are not allocated to Payroll are not accidentally
      used in a payroll run */
    address[] private approvedTokens;

    /// @dev Mapping manages registerdTokens and indicates if a _token is registered
    mapping(address => bool) private registeredToken;

    constructor(address[] memory initially_approved_tokens) {
        for (uint256 i = 0; i < initially_approved_tokens.length; ) {
            addApprovedToken(initially_approved_tokens[i]);
            unchecked {
                i++;
            }
        }
    }

    /// Protect owner by overriding renounceOwnership
    function renounceOwnership() public virtual override {
        revert("Cant renounce");
    }

    /// ============ MODIFIERS ============

    modifier onlyApprovedTokens(address _token) {
        require(registeredToken[_token], "Token not approved");
        _;
    }

    /// ============ VIEW FUNCTIONS ============

    function getApprovedTokens() external view returns (address[] memory) {
        return (approvedTokens);
    }

    function isApprovedToken(address _token) external view returns (bool) {
        return (registeredToken[_token]);
    }

    /// ============ TOKEN MANAGEMENT FUNCTIONS ============

    /** @notice
      Adds the ERC20 token address to the registeredToken array and creates a
      mapping that returns a boolean showing the token is approved. */
    /// @dev This function is public because it is called by the initializer
    /// @param _token The ERC20 token to be approved
    function addApprovedToken(address _token) public onlyOwner {
        require(!registeredToken[_token], "Token already approved");
        require(_token != address(0), "No 0x0 address");

        registeredToken[_token] = true;
        approvedTokens.push(_token);

        emit TokenApproved(_token);
    }

    /** @notice
      Removes the ERC20 token from the registeredToken array and
      deletes the mapping used to confirm a token is approved */
    /// @param _token The ERC20 token to be removed
    function removeApprovedToken(address _token)
        external
        onlyOwner
        onlyApprovedTokens(_token)
    {
        // set mapping to false
        registeredToken[_token] = false;

        // remove from approved token array
        for (uint256 i = 0; i < approvedTokens.length; ) {
            if (approvedTokens[i] == _token) {
                // replace deleted _token with last _token in array
                approvedTokens[i] = approvedTokens[approvedTokens.length - 1];
                // remove last spot in array
                approvedTokens.pop();
                break;
            }
            unchecked {
                i++;
            }
        }

        emit TokenRemoved(_token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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