// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Proxy is Ownable {
    string public constant name = "SagittariusBoy Proxy";

    string public constant version = "0.1";

    constructor() {
        _trustedAddress[msg.sender] = true;
    }

    mapping(address => bool) internal _trustedAddress;

    event CallResponse(bool success, bytes data);

    function addTrustedAddress(address addr) public onlyOwner {
        require(addr != address(0), "INVALID_ADDRESS");
        _trustedAddress[addr] = true;
    }

    function removeTrustedAddress(address addr) public onlyOwner {
        require(addr != address(0), "INVALID_ADDRESS");
        _trustedAddress[addr] = false;
    }

    function isTrustedAddress(address addr)
        public
        view
        onlyOwner
        returns (bool)
    {
        require(addr != address(0), "INVALID_ADDRESS");
        return _trustedAddress[addr];
    }

    function ownerOf(address target, uint256 tokenId)
        external
        returns (address)
    {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("ownerOf(uint256)", tokenId)
        );
        require(success, "ownerOf_Proxy_CALL_FAIL");
        emit CallResponse(success, result);
        return abi.decode(result, (address));
    }

    function safeTransferFrom(
        address target,
        address from,
        address to,
        uint256 tokenID
    ) external payable {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                from,
                to,
                tokenID
            )
        );
        emit CallResponse(success, result);
        require(success, "safeTransferFrom_Proxy_CALL_FAIL");
    }

    function balanceOf(address target, address owner)
        external
        returns (uint256)
    {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("balanceOf(address)", owner)
        );
        emit CallResponse(success, result);
        require(success, "balanceOf_Proxy_CALL_FAIL");
        return abi.decode(result, (uint256));
    }

    function safeMint(
        address target,
        address to,
        uint256 tokenID
    ) external payable {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("safeMint(address,uint256)", to, tokenID)
        );
        emit CallResponse(success, result);
        require(success, "safeMint_Proxy_CALL_FAIL");
    }

    function burn(address target, uint256 tokenID) external payable {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("burn(uint256)", tokenID)
        );
        emit CallResponse(success, result);
        require(success, "burn_Proxy_CALL_FAIL");
    }

    function totalSupply(address target) external returns (uint256) {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature("totalSupply()")
        );
        emit CallResponse(success, result);
        require(success, "totalSupply_Proxy_CALL_FAIL");
        return abi.decode(result, (uint256));
    }

    function tokenOfOwnerByIndex(
        address target,
        address owner,
        uint256 index
    ) external returns (uint256) {
        require(_trustedAddress[msg.sender], "NO_TRUSTED_SENDER");
        (bool success, bytes memory result) = target.call(
            abi.encodeWithSignature(
                "tokenOfOwnerByIndex(address,uint256)",
                owner,
                index
            )
        );
        emit CallResponse(success, result);
        require(success, "tokenOfOwnerByIndex_Proxy_CALL_FAIL");
        return abi.decode(result, (uint256));
    }

    
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