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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

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
pragma solidity ^0.8.9;

import "./interfaces/IStarknetCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReceiveMessageFromL2 is Ownable {
    IStarknetCore starknetCore;

    uint256 private EvaluatorContractAddress;
    uint256 public Ex02Selector;

    //set evaluator contract
    //it's the core contract to handle the messages call
    //command to get the current contract address:
    //starknet get_contract_addresses --network alpha-goerli
    function setStarknetCoreContract(address starknetCore_) external onlyOwner {
        starknetCore = IStarknetCore(starknetCore_);
    }

    //set evaluator contract
    //it's a L2 contract
    function setEvaluatorContractAddress(
        uint256 _evaluatorContractAddress
    ) external onlyOwner {
        EvaluatorContractAddress = _evaluatorContractAddress;
    }

    //sets selector
    //selector is the selector for the handler to be invoked, it determines what function to call in the corresponding L2 contract
    //the selector can found by passing the function name (ex2 in this case) to https://util.turbofish.co/ or using a script (ex.: python get_selector.py)
    //(selector for ex2 is: 897827374043036985111827446442422621836496526085876968148369565281492581228)
    function setSelector(uint256 _selector) external onlyOwner {
        Ex02Selector = _selector;
    }

    //it sends a message calling sendMessageToL2() from Starknet Core Contract
    function sendFromThisContractToL2(uint256 l2_user) public {
        uint256[] memory payload = new uint256[](1);

        payload[0] = l2_user;

        //send the message to the StarkNet core contract
        //sendMessageToL2() arguments:
        //sendMessageToL2(uint256 to_address, uint256 selector, uint256[] calldata payload)
        //  to_address is the L2 contract address
        //  selector is the selector for the handler to be invoked, it determines what function to call in the corresponding L2 contract
        //  payload
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            Ex02Selector,
            payload
        );
    }
}