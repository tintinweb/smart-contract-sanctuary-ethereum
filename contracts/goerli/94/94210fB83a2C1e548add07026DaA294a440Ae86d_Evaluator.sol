// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISolution.sol";
import "./interfaces/IStarknetCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Evaluator is Ownable {
    
    ////////////////////////////////
    // Storage
    ////////////////////////////////
    IStarknetCore private starknetCore;
    uint256 public l2Evaluator;
    uint256 public ex01_selector;
    uint256 public genericValidatorSelector;
    uint256 public ex05b_selector;

    event MessageReceived(uint256 msgInDecimal);

    ////////////////////////////////
    // Constructor
    ////////////////////////////////

    constructor(address starknetCore_) {
        starknetCore = IStarknetCore(starknetCore_);
    }

    ////////////////////////////////
    // External Functions
    ////////////////////////////////

    function ex01SendMessageToL2(uint256 player_l2_address, uint256 message) external payable{
        // Sending a message to L2
        // To validate this exercice, you need to successfully call this function on L1
        // It will then send a message to the evaluator on L2, which will credit you points.
        // Be careful! There is a constraint on the value of "message". Check out the L2 evaluator to find out which...

        // This function call requires money to send L2 messages, we check there is enough 
        require(msg.value>=10000000000, "Message fee missing");

        // Sending the message to the evaluator
        // Creating the payload
        uint256[] memory payload = new uint256[](3);
        // Adding player address on L2
        payload[0] = player_l2_address;
        // Adding player address on L1 
        payload[1] = uint256(uint160(msg.sender));
        // Adding player message 
        payload[2] = message;
        // Sending the message
        starknetCore.sendMessageToL2{value: 10000000000}(l2Evaluator, ex01_selector, payload);
    }

    function ex02ReceiveMessageFromL2(uint256 player_l2_address, uint256 message) external payable{
        // Receiving a message from L2
        // To validate this exercice, you need to:
        // - Use the evaluator on L2 to send a message to this contract on L1
        // - Call this function on L1 to consume the message 
        // - This function will then send back a message to L2 to credit points on player_l2_address

        // This function call requires money to send L2 messages, we check there is enough 
        require(msg.value>=10000000000, "Message fee missing");
        // Consuming the message 
        // Reconstructing the payload of the message we want to consume
        uint256[] memory payload = new uint256[](2);
        // Adding the address of the player on L2
        payload[0] = player_l2_address;
        // Adding the message
        payload[1] = message;
        // Adding a constraint on the message, to make sure players read BOTH contracts ;-)
        require(message>3121906, 'Message too small');
        require(message<4230938, 'Message too big');

        // If the message constructed above was indeed sent by starknet, this returns the hash of the message
        // If the message was NOT sent by starknet, the cal will revert 
        starknetCore.consumeMessageFromL2(l2Evaluator, payload);
       
        // Firing an event, for fun
        emit MessageReceived(message);

        // Crediting points to the player, on L2
        // Creating the payload
        uint256[] memory payload2 = new uint256[](2);
        // Adding player address on L2
        payload2[0] = player_l2_address;
        // Adding exercice number
        payload2[1] = 2;
        // Sending the message, with 0.00000001eth fee. Be sure to include it in your call!
        starknetCore.sendMessageToL2{value: 10000000000}(l2Evaluator, genericValidatorSelector, payload2);
    }

    function ex04ReceiveMessageFromAnL2Contract(uint256 player_l2_address, uint256 player_l2_contract) external payable {
        // Receiving a message from an L2 contract
        // To collect points, you need to deploy an L2 contract that uses send_message_to_l1_syscall() correctly.
        // To validate this exercice, you need to:
        // - Deploy an L2 contract (address player_l2_contract) that uses send_message_to_l1_syscall()
        // - Use that L2 contract to send a message to this contract on L1
        // - Call this function on L1 to consume the message. Be careful, the address from which you trigger this function matters!
        // - This function will then send back a message to L2 to credit points on player_l2_address

        // This function call requires money to send L2 messages, we check there is enough 
        require(msg.value>=10000000000, "Message fee missing");
        // Consuming the message
        // Reconstructing the payload of the message we want to consume
        uint256[] memory payload = new uint256[](2);
        // Adding the address of the player account on L2
        payload[0] = player_l2_address;
        // Adding the address of the player on L1. This means the L1->L2 message needs to specify
        // which EOA is going to trigger this function
        payload[1] = uint256(uint160(msg.sender));
        // If the message constructed above was indeed sent by starknet, this returns the hash of the message
        // If the message was NOT sent by starknet, the cal will revert 
        starknetCore.consumeMessageFromL2(player_l2_contract, payload);
        
        // Crediting points to the player, on L2
        // Creating the payload
        uint256[] memory payload2 = new uint256[](2);
        // Adding player address on L2
        payload2[0] = player_l2_address;
        // Adding exercice number
        payload2[1] = 4;
        // Sending the message
        starknetCore.sendMessageToL2{value: 10000000000}(l2Evaluator, genericValidatorSelector, payload2);

    }

    function ex05SendMessageToAnL2CustomContract(uint256 playerL2MessageReceiver, uint256 functionSelector, uint256 player_l2_address) external payable{
        // Sending a message to a custom L2 contract
        // To collect points, you need to deploy an L2 contract that includes an l1 handler that can receive messages from L1.
        // To get point on this exercice you need to
        // - Deploy an L2 contract that will receive message sent from this function
        // - Call this function on L1
        // - A message is sent to your contract, as well as to the evaluator
        // - On L2, you call the evaluator to show that both values match
        // In order to call this function you need to specify:
        // - The address of your receiver contract on L2
        // - The function selector of your l1 handler in your L2 contract
        // - The L2 wallet on which you want to collect points

        // This function call requires money to send L2 messages, we check there is enough 
        require(msg.value>=20000000000, "Message fee missing");
        // Creating an arbitrary random value
        uint256 rand_value = uint160(
            uint256(
                keccak256(abi.encodePacked(block.prevrandao, block.timestamp))
            )
        );
       
        // Sending a message to you l2 contract
        uint256[] memory payload_receiver = new uint256[](1);
        payload_receiver[0] = rand_value;
        starknetCore.sendMessageToL2{value: 10000000000}(
            playerL2MessageReceiver,
            functionSelector,
            payload_receiver
        );

        // Sending a message to the evaluator 
        uint256[] memory payload_evaluator = new uint256[](3);
        payload_evaluator[0] = playerL2MessageReceiver;
        payload_evaluator[1] = rand_value;
        payload_evaluator[2] = player_l2_address;
        starknetCore.sendMessageToL2{value: 10000000000}(l2Evaluator, ex05b_selector, payload_evaluator);
    }

    function ex06ReceiveMessageFromAnL2CustomContract(address playerL1MessageReceiver, uint256 player_l2_address) external payable{
        // Receiving a message from L2 on a custom L1 contract
        // To collect points, you need to deploy an L1 contract that is able to consume a message from L2
        // Step by step:
        // - Deploy an L1 contract that can consume messages from L2. 
        //      - Message consumption should happen in a function called consumeMessage(), callable by anyone
        // - Use the L2 evaluator to send a message to you L1 contract  
        // - Wait for the message to arrive on Ethereum
        // - Call this function ex05ReceiveMessageFromAnL2CustomContract to trigger the message consumption on your contract
        // - Points are sent back to your account contract on L2

        // This function call requires money to send L2 messages, we check there is enough 
        require(msg.value>=10000000000, "Message fee missing");
        // No shenanigans, checking that player's contract is not the evaluator :) 
        require(playerL1MessageReceiver != address(this));
        // Connecting to the player's L1 contract        
        ISolution playerSolution = ISolution(playerL1MessageReceiver);
        // Calculating the message Hash
        uint256[] memory payload = new uint256[](1);
        payload[0] = player_l2_address;
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                l2Evaluator, // Who sent the message
                uint256(uint160(playerL1MessageReceiver)), // To whom was it sent
                payload.length, // Data length
                payload // Data
            )
        );
        // Checking if the the message reached Ethereum
        uint256 isMessagePresent = starknetCore.l2ToL1Messages(msgHash);
        require(isMessagePresent > 0, "The message is not present on the proxy");
        // Calling player's L1 contract to consume the message
        playerSolution.consumeMessage(l2Evaluator, player_l2_address);
        // Checking if the the message was consumed
        uint256 wasMessageConsumed = starknetCore.l2ToL1Messages(msgHash);
        require(
            wasMessageConsumed == (isMessagePresent - 1),
            "The message was  not consumed"
        );
        // Crediting points on L2
        // Building the payload
        uint256[] memory payload2 = new uint256[](2);
        // Adding player address on L2
        payload2[0] = player_l2_address;
        // Adding exercice number
        payload2[1] = 6;
        // Sending the message
        starknetCore.sendMessageToL2{value: 10000000000}(l2Evaluator, genericValidatorSelector, payload2);
    }

    ////////////////////////////////
    // External functions - Administration
    // Only admins can call these. You don't need to understand them to finish the exercise.
    ////////////////////////////////

    function setL2Evaluator(uint256 l2Evaluator_) external onlyOwner {
        l2Evaluator = l2Evaluator_;
    }
    function setEx01Selector(uint256 ex01_selector_) external onlyOwner {
        ex01_selector = ex01_selector_;
    }
    function setEx05bSelector(uint256 ex05b_selector_) external onlyOwner {
        ex05b_selector = ex05b_selector_;
    }
    function setGenericValidatorSelector(uint256 genericValidatorSelector_) external onlyOwner {
        genericValidatorSelector = genericValidatorSelector_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);

    /**
      Read if a message is present on starknet core

      Returns how many instances of the message are present
    */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);


}