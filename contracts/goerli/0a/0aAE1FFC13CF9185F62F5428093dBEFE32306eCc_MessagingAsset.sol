// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStarknetCore.sol";

contract MessagingAsset is Ownable {
    IStarknetCore starknetCore;
    uint256 private l2NftFactoryContractAddress;
    uint256 private l2TokenContractAddress;
    uint256 private mint_selector;

    function setMintedSelector(uint256 _mint_selector) external onlyOwner {
        mint_selector = _mint_selector;
    }

    function setL2NftFactoryContractAddress(uint256 _l2NftFactoryContractAddress) external onlyOwner {
        l2NftFactoryContractAddress = _l2NftFactoryContractAddress;
    }

    function setL2TokenContractAddress(uint256 _l2TokenContractAddress) external onlyOwner {
        l2TokenContractAddress = _l2TokenContractAddress;
    }

    constructor(address _starknetCore) public{ 
        starknetCore = IStarknetCore(_starknetCore);
    }

    function mintAssetFromL2(
        uint256 l2_user,
        string memory _product_key,
        string memory _area,
        string memory _surface,
        uint256 _price,
        string memory _name_token,
        string memory _symbol_token
    ) external {
        uint256[] memory sender_payload = new uint256[](7);
        //sender_payload[0] = l2TokenContractAddress;
        sender_payload[0] = l2_user;
        sender_payload[1] = uint256(keccak256(abi.encodePacked(_product_key)));
        sender_payload[2] = uint256(keccak256(abi.encodePacked(_area)));
        sender_payload[3] = uint256(keccak256(abi.encodePacked(_surface)));
        sender_payload[4] = _price;
        sender_payload[5] = uint256(keccak256(abi.encodePacked(_name_token)));
        sender_payload[6] = uint256(keccak256(abi.encodePacked(_symbol_token)));

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        // starknetCore.consumeMessageFromL2(l2TokenContractAddress, payload);

        // Send the message to the Starknet core contract.
        starknetCore.sendMessageToL2(
            l2NftFactoryContractAddress, 
            mint_selector, 
            sender_payload
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.
      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
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