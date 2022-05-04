// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FxBaseRootTunnel} from "./tunnel/FxBaseRootTunnel.sol";
import "../Crayons/Ownable.sol";

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

contract RootTunnel is FxBaseRootTunnel, IStateSender, Ownable {
    constructor(address _checkpointManager, address _fxRoot)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {}

    address public collection;

    function setFxChildTunnel(address _fxChildTunnel) public onlyOwner {
        _setFxChildTunnel(_fxChildTunnel);
    }

    function setCollection(address _collection) public onlyOwner {
        collection = _collection;
    }

    // TODO: Set permissions at some point
    function sendMessageToChild(bytes memory message) public {
        _sendMessageToChild(message);
    }

    function syncState(address, bytes calldata data) public override {
        require(
            msg.sender == collection,
            "RootTunnel#syncState: INVALID_SENDER"
        );
        sendMessageToChild(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}


contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}


abstract contract FxBaseRootTunnel {
    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(
        address _checkpointManager,
        address _fxRoot
    ) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function _setFxChildTunnel(address _fxChildTunnel) internal {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
        require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}