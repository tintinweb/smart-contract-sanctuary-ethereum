// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISolution.sol";
import "./interfaces/IStarknetCore.sol";

contract Evaluator {
    mapping(address => address) private playerContarcts;
    address private proxyAddress;
    IStarknetCore private starknetCore;
    uint256 private l2Evaluator;
    event HashCalculated(bytes32 msgHash_);

    constructor(
        address proxyAddress_,
        address starknetCore_,
        uint256 l2Evaluator_
    ) {
        proxyAddress = proxyAddress_;
        starknetCore = IStarknetCore(starknetCore_);
        l2Evaluator = l2Evaluator_;
    }

    function submitExercice(address playerContract) external {
        playerContarcts[msg.sender] = playerContract;
    }

    function ex3(uint256 l2User) external {
        address playerContract = playerContarcts[msg.sender];
        ISolution playerSolution = ISolution(playerContract);

        //Triger sending message from L2 (Send message to L2 evaluator)
        //Calcluate message Hash
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        bytes32 msgHash = keccak256(
            abi.encodePacked(l2Evaluator, playerContract, "0x1", payload)
        );
        emit HashCalculated(msgHash);
        //Check if the the message is on the proxy
        require(
            starknetCore.l2ToL1Messages(msgHash) > 0,
            "The message is not present on the proxy"
        );
        //playerSolution.consumeMessage(l2Evaluator, l2User);
        /*require(
            starknetCore.l2ToL1Messages(msgHash) == 0,
            "The message is not consumed !"
        );*/
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