// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    uint16 private sourceChainId;
    mapping(address => mapping(uint16 => address))
        private sourceTokenToTargetToken;
    mapping(address => mapping(uint16 => address))
        private targetTokenToSourceToken;

    event TokenConnectionRegistered(
        address indexed sourceToken,
        address indexed targetToken,
        uint16 sourceChainId,
        uint16 targetChainId
    );

    constructor() {
        sourceChainId = uint16(block.chainid);
    }

    /**
     * @notice lookup target token address by source token and target chain id
     */
    function lookupTargetTokenAddress(
        address _sourceToken,
        uint16 _targetChainId
    ) external view returns (address) {
        return sourceTokenToTargetToken[_sourceToken][_targetChainId];
    }

    /**
     * @notice lookup source token by target token and source chain id
     */
    function lookupSourceTokenAddress(
        address _targetToken,
        uint16 _sourceChainId
    ) external view returns (address) {
        return targetTokenToSourceToken[_targetToken][_sourceChainId];
    }

    /**
     * @notice registers a token connection between the source and target oken addreses
     */
    function registerTargetTokenAddress(
        address _sourceToken,
        uint16 _targetChainId,
        address _targetToken
    ) external onlyOwner {
        require(_sourceToken != address(0), "Invalid source address");
        require(_targetToken != address(0), "Invalid target address");

        sourceTokenToTargetToken[_sourceToken][_targetChainId] = _targetToken;
        targetTokenToSourceToken[_targetToken][sourceChainId] = _sourceToken;

        emit TokenConnectionRegistered(
            _sourceToken,
            _targetToken,
            sourceChainId,
            _targetChainId
        );
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