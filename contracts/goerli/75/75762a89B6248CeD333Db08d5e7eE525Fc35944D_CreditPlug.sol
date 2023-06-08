pragma solidity 0.8.16;

import {ISocket} from "./ISocket.sol";
import {ISpigot} from "../credit/ISpigot.sol";

contract CreditPlug {
    ISocket public socket;
    address public owner;
    uint256 public destGasLimit = 100000;

    // CHAIN A
    address public spitgotedLine;

    // CHAIN B
    uint32 public remoteChainSlug;
    address public spigotedLineOnChainA;
    ISpigot public spigot;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Chain A
    modifier onlySpigottedLine() {
        require(msg.sender == spitgotedLine, "Not spigotedLine");
        _;
    }

    // Chain B
    modifier onlySocket() {
        require(msg.sender == address(socket), "Not Socket");
        _;
    }

    event AddSpigotInitiated(address indexed revenueContract);
    event SpigotNotAdded();

    constructor(
        address socket_,
        address spigotedLineOnChainA_,
        address spigot_
    ) {
        owner = msg.sender;
        socket = ISocket(socket_);
        spigot = ISpigot(spigot_);
        spigotedLineOnChainA = spigotedLineOnChainA_;
    }

    /************************************************************************
        Config Functions 
    ************************************************************************/

    /**
     * see LineOfCredit._init and Securedline.init
     * @notice requires this Line is owner of the Escrowed collateral else Line will not init
     */
    function connectToSocket(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        remoteChainSlug = siblingChainSlug_;
        ISocket(socket).connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function setDestChainLimit(uint256 _limit) public onlyOwner {
        destGasLimit = _limit;
    }

    function setSpigotedLine(address _sl) public onlyOwner {
        spigotedLineOnChainA = _sl;
    }

    function setSpigot(address _s) public onlyOwner {
        spigot = ISpigot(_s);
    }

    /************************************************************************
        SocketDL Functions 
    ************************************************************************/

    // SK_WIP check where msg.value comes from
    function sendSocketMessage(bytes memory payload_) internal returns (bool) {
        try
            socket.outbound{value: msg.value}(
                remoteChainSlug,
                destGasLimit, // SK_WIP gasLimit assumed so far
                bytes32(0),
                payload_
            )
        {
            return true;
        } catch {
            return false;
        }
    }

    function inbound(
        uint32 siblingChainSlug_,
        bytes calldata payload_
    ) public onlySocket {
        (
            address _sender,
            address _revenueContract,
            ISpigot.Setting memory _setting
        ) = abi.decode(payload_, (address, address, ISpigot.Setting));

        require(
            _sender == spigotedLineOnChainA,
            "Sender of message not spigotedLine"
        );

        addSpigotChainB(_revenueContract, _setting);
    }

    /************************************************************************
        Chain A Functions -- SpigotedLine.sol
    ************************************************************************/

    function addSpigot(
        address revenueContract,
        ISpigot.Setting calldata setting
    ) public payable onlySpigottedLine returns (bool) {
        bytes memory payload = abi.encode(msg.sender, revenueContract, setting);

        bool success = sendSocketMessage(payload);
        if (success) emit AddSpigotInitiated(revenueContract);
        return success;
    }

    /************************************************************************
        Chain B Functions -- Spigoted.sol
    ************************************************************************/

    function addSpigotChainB(
        address _revenueContract,
        ISpigot.Setting memory _setting
    ) internal {
        try spigot.addSpigot(_revenueContract, _setting) {} catch {
            emit SpigotNotAdded();
        }
    }
}

pragma solidity 0.8.16;

interface ISpigot {
    struct Setting {
        uint8 ownerSplit; // x/100 % to Owner, rest to Operator
        bytes4 claimFunction; // function signature on contract to call and claim revenue
        bytes4 transferOwnerFunction; // function signature on contract to call and transfer ownership
    }

    // Spigot Events
    event AddSpigot(address indexed revenueContract, uint256 ownerSplit, bytes4 claimFnSig, bytes4 trsfrFnSig);

    event RemoveSpigot(address indexed revenueContract, address token);

    event UpdateWhitelistFunction(bytes4 indexed func, bool indexed allowed);

    event UpdateOwnerSplit(address indexed revenueContract, uint8 indexed split);

    event ClaimRevenue(address indexed token, uint256 indexed amount, uint256 escrowed, address revenueContract);

    event ClaimOwnerTokens(address indexed token, uint256 indexed amount, address owner);

    event ClaimOperatorTokens(address indexed token, uint256 indexed amount, address operator);

    // Stakeholder Events

    event UpdateOwner(address indexed newOwner);

    event UpdateOperator(address indexed newOperator);

    // Errors
    error BadFunction();

    error OperatorFnNotWhitelisted();

    error OperatorFnNotValid();

    error OperatorFnCallFailed();

    error ClaimFailed();

    error NoRevenue();

    error UnclaimedRevenue();

    error CallerAccessDenied();

    error BadSetting();

    error InvalidRevenueContract();

    // ops funcs

    function claimRevenue(
        address revenueContract,
        address token,
        bytes calldata data
    ) external returns (uint256 claimed);

    function operate(address revenueContract, bytes calldata data) external returns (bool);

    // owner funcs

    function claimOwnerTokens(address token) external returns (uint256 claimed);

    function claimOperatorTokens(address token) external returns (uint256 claimed);

    function addSpigot(address revenueContract, Setting memory setting) external returns (bool);

    function removeSpigot(address revenueContract) external returns (bool);

    // stakeholder funcs

    function updateOwnerSplit(address revenueContract, uint8 ownerSplit) external returns (bool);

    function updateOwner(address newOwner) external returns (bool);

    function updateOperator(address newOperator) external returns (bool);

    function updateWhitelistedFunction(bytes4 func, bool allowed) external returns (bool);

    // Getters
    function owner() external view returns (address);

    function operator() external view returns (address);

    function isWhitelisted(bytes4 func) external view returns (bool);

    function getOwnerTokens(address token) external view returns (uint256);

    function getOperatorTokens(address token) external view returns (uint256);

    function getSetting(
        address revenueContract
    ) external view returns (uint8 split, bytes4 claimFunc, bytes4 transferFunc);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes32 extraParams_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param msgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_,
        bytes32 extraParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);
}