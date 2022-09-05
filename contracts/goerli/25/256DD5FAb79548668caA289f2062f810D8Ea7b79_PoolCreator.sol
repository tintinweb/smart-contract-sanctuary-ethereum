// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../interfaces/IFlashloanFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolCreator is Ownable {
    address public immutable factory;

    uint256 public oneTimeMintFee;
    uint256 public multiMintFee;

    mapping(address => bool) public isFeeExempt;

    event ChangeFees(uint256 oneTimeMintFee, uint256 multiMintFee);
    event SetFeeExempt(address user, bool exemption);

    modifier requirePayment(uint256 value) {
        if (!isFeeExempt[msg.sender]) {
            require(msg.value == value, "PoolCreator: Invalid msg.value");
        } else {
            require(msg.value == 0, "PoolCreator: Caller is fee exempt");
        }
        _;
    }

    constructor(address _factory, uint256 _oneTimeMintFee, uint256 _multiMintFee) {
        factory = _factory;

        oneTimeMintFee = _oneTimeMintFee;
        multiMintFee = _multiMintFee;
        emit ChangeFees(_oneTimeMintFee, _multiMintFee);
    }

    function setFees(uint256 _oneTimeMintFee, uint256 _multiMintFee) external onlyOwner {
        oneTimeMintFee = _oneTimeMintFee;
        multiMintFee = _multiMintFee;
        emit ChangeFees(_oneTimeMintFee, _multiMintFee);
    }

    function setFeeExemption(address user, bool exemption) external onlyOwner {
        isFeeExempt[user] = exemption;
        emit SetFeeExempt(user, exemption);
    }

    function createPool(address token) external payable requirePayment(oneTimeMintFee) returns (address pool) {
        return _createPool(token);
    }

    function _createPool(address token) internal returns (address pool) {
        return IFlashloanFactory(factory).createPool(token);
    }

    function createPools(address[] calldata tokens) external payable requirePayment(tokens.length * multiMintFee) returns (address[] memory pools) {
        require(tokens.length > 1, "PoolCreator: Must provide multiple tokens");
        pools = new address[](tokens.length);
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            pools[i] = _createPool(tokens[i]);
        }
    }

    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

abstract contract IFlashloanFactory {
    
    event CreatePool(
        address indexed creator,
        address indexed token,
        address pool
    );

    event ChangeDeveloper(address developer);

    /// @dev the address of the owner ERC721 token
    function OWNER_TOKEN() external view virtual returns (address);
    /// @dev gets the address of the developer fee receiver
    function getDeveloper() external view virtual returns (address);
    /// @dev sets the address of the developer fee receiver
    function setDeveloper(address _developer) external virtual;

    /// @dev creates a pool for {token}
    /// @param token the token for the pool that will be created
    /// @return pool the address of the new pool
    function createPool(address token) external virtual returns (address pool);

    /// @dev initiates a transaction for {token}. Sets the initiator of the 
    /// flashloan to the caller of this function, as opposed to this contract.
    /// See {IFlashloanPool-initiateTransaction}
    /// @param token the token loaned in the flashloan
    /// @param amount the amount loaned
    /// @param target the target of the flashloan
    /// @param params the parameters to be passed when executing the function
    function initiateTransaction(
        address token, 
        uint256 amount, 
        address target, 
        bytes memory params
    ) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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