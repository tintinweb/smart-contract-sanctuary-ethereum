// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISolution.sol";
import "./interfaces/IStarknetCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Evaluator is Ownable {
    IStarknetCore private starknetCore;
    uint256 private l2Evaluator;
    uint256 private ex3_b_selector;
    uint256 private ex4_a_selector;
    event HashCalculated(bytes32 msgHash_);

    constructor(address starknetCore_) {
        starknetCore = IStarknetCore(starknetCore_);
    }

    function setL2Evaluator(uint256 l2Evaluator_) external onlyOwner {
        l2Evaluator = l2Evaluator_;
    }

    function setEx3BSelector(uint256 ex3_b_selector_) external onlyOwner {
        ex3_b_selector = ex3_b_selector_;
    }

    function setEx4ASelector(uint256 ex4_a_selector_) external onlyOwner {
        ex4_a_selector = ex4_a_selector_;
    }

    function ex3(uint256 l2User, address playerContract) external {
        ISolution playerSolution = ISolution(playerContract);

        //Triger sending message from L2 (Send message to L2 evaluator)
        //Calcluate message Hash
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                l2Evaluator,
                uint256(uint160(playerContract)),
                payload.length,
                payload
            )
        );
        emit HashCalculated(msgHash);
        //Check if the the message is on the proxy
        uint256 consumed = starknetCore.l2ToL1Messages(msgHash);
        require(consumed > 0, "The message is not present on the proxy");
        playerSolution.consumeMessage(l2Evaluator, l2User);
        uint256 after_consumed = starknetCore.l2ToL1Messages(msgHash);
        require(
            after_consumed == (consumed - 1),
            "The message is not consumed yet !"
        );
        starknetCore.sendMessageToL2(l2Evaluator, ex3_b_selector, payload);
    }

    function ex4(uint256 l2ReceiverContract, uint256 solution_selector)
        external
    {
        uint256 rand_value = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        uint256[] memory payload = new uint256[](2);
        payload[0] = l2ReceiverContract;
        payload[1] = rand_value;
        uint256[] memory payload_receiver = new uint256[](1);
        payload_receiver[0] = rand_value;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2Evaluator, ex4_a_selector, payload);
        starknetCore.sendMessageToL2(
            l2ReceiverContract,
            solution_selector,
            payload_receiver
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ISolution {
    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external;
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