// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RareShoeHpprsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RareShoeHpprsOrchestrator is Ownable {
    address public secret = 0x9C17E0f19f6480747436876Cee672150d39426A5;
    address public main = 0xE5f8fb26FdEe365589c622ac89d39e93625D6c09;
    address public shipping = 0xa8c3e79E3C62655Ae556C2C207E3DA1A64a2acF5;

    RareShoeHpprsInterface public rareShoe = RareShoeHpprsInterface(0x0370Ef59e3e77Bb517F2AB68dc58EC224f38a1eb);

    uint public startAt = 1679504400;

    event OrderConfirmed(uint256 orderId);

    function setSettings(
        address _rareShoe,
        address _secret,
        address _main,
        address _shipping,
        uint _startAt
    ) external onlyOwner {
        secret = _secret;
        main = _main;
        shipping = _shipping;
        rareShoe = RareShoeHpprsInterface(_rareShoe);
        startAt = _startAt;
    }

    function setStartAt(uint _startAt) external onlyOwner {
        startAt = _startAt;
    }

    function mintItems(
        uint256 orderId,
        uint256 itemsPrice,
        uint256 shippingPrice,
        uint256 timeOut,
        uint256[] calldata itemsIds,
        uint256[] calldata itemsQuantities,
        bytes calldata signature
    ) external payable {
        require(block.timestamp > startAt, "Mint is closed");
        require(timeOut > block.timestamp, "Order is expired");
        require(msg.value == itemsPrice + shippingPrice, "Wrong ETH amount");
        require(
            _verifyHashSignature(keccak256(abi.encode(
                msg.sender,
                orderId,
                itemsPrice,
                shippingPrice,
                timeOut,
                itemsIds,
                itemsQuantities
            )), signature),
            "Invalid signature"
        );

        payable(main).transfer(itemsPrice);
        payable(shipping).transfer(shippingPrice);

        rareShoe.airdrop(msg.sender, itemsIds, itemsQuantities);
        emit OrderConfirmed(orderId);
    }

      function withdraw() external onlyOwner {
        payable(main).transfer(address(this).balance);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature) internal view returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
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

pragma solidity ^0.8.0;

interface RareShoeHpprsInterface {
    function airdrop(address to, uint[] calldata ids, uint[] calldata amounts) external;
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