/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GNU GPLv3

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


pragma solidity ^0.8.0;


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


pragma solidity 0.8.4;

abstract contract ERC20Clone {
    function initializer(
        address _minter,
        string memory _wrappedTokenName,
        string memory _wrappedTokenTicker,
        uint8 _wrappedTokenDecimals,
        uint256 _vestEndTime
    ) public virtual;
}

pragma solidity 0.8.4;

/// @title ERC20Factory contract for mass deployment of WVTs
/// @author Capx Team
/// @notice Only the controller contract can call the function which deploys cheap copy of ERC20 contracts
/// @dev This contract uses EIP-1167: Minimal Proxy Contract
contract ERC20Factory is Ownable {
    address public implementation;
    address public controller;
    address public lender;

    constructor(address _implementaiton, address _controller) {
        require(
            _implementaiton != address(0) && _controller != address(0),
            "Invalid input"
        );
        implementation = _implementaiton;
        controller = _controller;
    }

    /// @notice Function which can only be called by owner and used to set lender contract address.
    /// @param _lender The address of the lender contract.
    function setLender(address _lender) external onlyOwner {
        require(_lender != address(0), "Invalid input");
        lender = _lender;
    }

    /// @notice Function called by controller contract to deploy new ERC20 token
    function createStorage(
        string memory _wrappedTokenName,
        string memory _wrappedTokenTicker,
        uint8 _wrappedTokenDecimals,
        uint256 _vestEndTime
    ) public returns (address) {
        require(msg.sender == controller, "Only controller can access");
        address clone = createClone(implementation);
        // Handling low level exception
        assert(clone != address(0));
        ERC20Clone(clone).initializer(
            controller,
            _wrappedTokenName,
            _wrappedTokenTicker,
            _wrappedTokenDecimals,
            _vestEndTime
        );
        return (clone);
    }

    /// @notice Function uses EIP-1167 implementation
    function createClone(address _target) internal returns (address result) {
        bytes20 targetBytes = bytes20(_target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}