//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Wormhole/IWormhole.sol";
import "./Encoder.sol";

contract Messenger is Encoder{
    string private solana_msg;
    address private wormhole_core_bridge_address = address(0x706abc4E45D419950511e474C7B9Ed348A4a716c);
    IWormhole core_bridge = IWormhole(wormhole_core_bridge_address);
    uint32 nonce = 0;
    mapping(uint16 => bytes32) _applicationContracts;
    address owner;
    mapping(bytes32 => bool) _completedMessages;


    uint16 public constant CHAIN_ID = 2; //3
    uint8 public constant CONSISTENCY_LEVEL = 1; //15

    constructor(){
        owner = msg.sender;

    }

    function sendMsg(bytes memory str) public returns (uint64 sequence) {
        sequence = core_bridge.publishMessage(nonce, str, 1);
        nonce = nonce+1;
    }


    function recieveEncodedMsg(bytes memory encodedMsg) public {
        (IWormhole.VM memory vm, bool valid, string memory reason) = core_bridge.parseAndVerifyVM(encodedMsg);
        
        //1. Check Wormhole Guardian Signatures
        //  If the VM is NOT valid, will return the reason it's not valid
        //  If the VM IS valid, reason will be blank
        require(valid, reason);

        //2. Check if the Emitter Chain contract is registered
        require(_applicationContracts[vm.emitterChainId] == vm.emitterAddress, "Invalid Emitter Address!");
    
        //3. Check that the message hasn't already been processed
        require(!_completedMessages[vm.hash], "Message already processed");
        _completedMessages[vm.hash] = true;

        //Do the thing
        solana_msg = string(vm.payload);
    }

    function getSolanaMsg() public view returns (string memory){
        return solana_msg;
    }
    /**
        Registers it's sibling applications on other chains as the only ones that can send this instance messages
     */
    function registerApplicationContracts(uint16 chainId, bytes32 applicationAddr) public {
        require(msg.sender == owner, "Only owner can register new chains!");
        _applicationContracts[chainId] = applicationAddr;
    }



    function process_sol_stream(uint64 start_time, uint64 end_time, uint64 amount, address receiver) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_sol_stream(Messages.ProcessStream({
            start_time : start_time,
            end_time : end_time,
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender,
            receiver : receiver
        }));
        // bytes memory sol_stream = abi.encode(msg.sender);
        sequence = core_bridge.publishMessage(nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_token_stream(uint64 start_time, uint64 end_time, uint64 amount, address receiver) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_token_stream(Messages.ProcessStream({
            start_time : start_time,
            end_time : end_time,
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender,
            receiver : receiver
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_sol_withdraw_stream(uint64 amount, address withdrawer) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_sol_withdraw_stream(Messages.ProcessWithdrawStream({
            amount : amount,
            toChain : CHAIN_ID,
            withdrawer : withdrawer
        }));

        sequence = core_bridge.publishMessage(nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_token_withdraw_stream(uint64 amount, address withdrawer) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_token_withdraw_stream(Messages.ProcessWithdrawStream({
            amount : amount,
            toChain : CHAIN_ID,
            withdrawer : withdrawer
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_deposit_sol(uint64 amount, address depositor) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_process_deposit_sol(Messages.ProcessDeposit({
            amount : amount,
            toChain : CHAIN_ID,
            depositor : depositor
        }));

        sequence = core_bridge.publishMessage(nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_deposit_token(uint64 amount, address depositor) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_process_deposit_token(Messages.ProcessDeposit({
            amount : amount,
            toChain : CHAIN_ID,
            depositor : depositor
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_fund_sol(uint64 end_time, uint64 amount) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_process_fund_sol(Messages.ProcessFund({
            end_time : end_time,
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender
        }));

        sequence = core_bridge.publishMessage
            
        (nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_fund_token(uint64 end_time, uint64 amount) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_process_fund_token(Messages.ProcessFund({
            end_time : end_time,
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_withdraw_sol(uint64 amount) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_process_withdraw_sol(Messages.ProcessWithdraw({
            amount : amount,
            toChain : CHAIN_ID,
            withdrawer : msg.sender
        }));

        sequence = core_bridge.publishMessage(nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_withdraw_token(uint64 amount) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_process_withdraw_token(Messages.ProcessWithdraw({
            amount : amount,
            toChain : CHAIN_ID,
            withdrawer : msg.sender
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function process_swap_sol(uint64 amount) public payable returns (uint64 sequence) {
        bytes memory sol_stream = Encoder.encode_process_swap_sol(Messages.ProcessSwap({
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender
        }));

        sequence = core_bridge.publishMessage(nonce, sol_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }

    function encode_process_swap_token(uint64 amount) public payable returns (uint64 sequence) {
        bytes memory token_stream = Encoder.encode_process_swap_token(Messages.ProcessSwap({
            amount : amount,
            toChain : CHAIN_ID,
            sender : msg.sender
        }));

        sequence = core_bridge.publishMessage(nonce, token_stream, CONSISTENCY_LEVEL);
        nonce = nonce+1;
    }


}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./Structs.sol";

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;

    function getCurrentGuardianSetIndex() external view returns (uint32) ;

    function getGuardianSetExpiry() external view returns (uint32) ;

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;

    function isInitialized(address impl) external view returns (bool) ;

    function chainId() external view returns (uint16) ;

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256) ;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "./Messages.sol";

contract Encoder is Messages {
    uint8 public constant SOL_STREAM = 1;
    uint8 public constant TOKEN_STREAM = 2;
    uint8 public constant SOL_WITHDRAW_STREAM = 3;
    uint8 public constant TOKEN_WITHDRAW_STREAM = 4;
    uint8 public constant DEPOSIT_SOL = 5;
    uint8 public constant DEPOSIT_TOKEN = 6;
    uint8 public constant FUND_SOL = 7;
    uint8 public constant FUND_TOKEN = 8;
    uint8 public constant WITHDRAW_SOL = 9;
    uint8 public constant WITHDRAW_TOKEN = 10;
    uint8 public constant SWAP_SOL = 11;
    uint8 public constant SWAP_TOKEN = 12;

    function encode_sol_stream(Messages.ProcessStream memory processStream) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            SOL_STREAM,
            processStream.start_time,
            processStream.end_time,
            processStream.amount,
            processStream.toChain,
            processStream.sender,
            processStream.receiver
        );
    }

    function encode_token_stream(Messages.ProcessStream memory processStream) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            TOKEN_STREAM,
            processStream.start_time,
            processStream.end_time,
            processStream.amount,
            processStream.toChain,
            processStream.sender,
            processStream.receiver
        );
    }

    function encode_sol_withdraw_stream(Messages.ProcessWithdrawStream memory processWithdrawStream) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            SOL_WITHDRAW_STREAM,
            processWithdrawStream.amount,
            processWithdrawStream.toChain,
            processWithdrawStream.withdrawer
        );
    }

    function encode_token_withdraw_stream(Messages.ProcessWithdrawStream memory processWithdrawStream) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            TOKEN_WITHDRAW_STREAM,
            processWithdrawStream.amount,
            processWithdrawStream.toChain,
            processWithdrawStream.withdrawer
        );
    }

    function encode_process_deposit_sol(Messages.ProcessDeposit memory processDeposit) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            DEPOSIT_SOL,
            processDeposit.amount,
            processDeposit.toChain,
            processDeposit.depositor
        );
    }

    function encode_process_deposit_token(Messages.ProcessDeposit memory processDeposit) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            DEPOSIT_TOKEN,
            processDeposit.amount,
            processDeposit.toChain,
            processDeposit.depositor
        );
    }

    function encode_process_fund_sol(Messages.ProcessFund memory processFund) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            FUND_SOL,
            processFund.end_time,
            processFund.amount,
            processFund.toChain,
            processFund.sender
        );
    }

    function encode_process_fund_token(Messages.ProcessFund memory processFund) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            FUND_TOKEN,
            processFund.end_time,
            processFund.amount,
            processFund.toChain,
            processFund.sender
        );
    }

    function encode_process_withdraw_sol(Messages.ProcessWithdraw memory processWithdraw) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            WITHDRAW_SOL,
            processWithdraw.amount,
            processWithdraw.toChain,
            processWithdraw.withdrawer
        );
    }

    function encode_process_withdraw_token(Messages.ProcessWithdraw memory processWithdraw) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            WITHDRAW_TOKEN,
            processWithdraw.amount,
            processWithdraw.toChain,
            processWithdraw.withdrawer
        );
    }

    function encode_process_swap_sol(Messages.ProcessSwap memory processSwap) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            SWAP_SOL,
            processSwap.amount,
            processSwap.toChain,
            processSwap.sender
        );
    }

    function encode_process_swap_token(Messages.ProcessSwap memory processSwap) public pure returns (bytes memory encoded){
        encoded = abi.encodePacked(
            SWAP_TOKEN,
            processSwap.amount,
            processSwap.toChain,
            processSwap.sender
        );
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
		uint16 governanceChainId;
		bytes32 governanceContract;
	}

	struct GuardianSet {
		address[] keys;
		uint32 expirationTime;
	}

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}

	struct RegisterChain {
        // Governance Header
        // module: "NFTBridge" left-padded
        bytes32 module;
        // governance action: 1
        uint8 action;
        // governance paket chain id: this or 0
        uint16 chainId;

        // Chain ID
        uint16 emitterChainID;
        // Emitter address. Left-zero-padded if shorter than 32 bytes
        bytes32 emitterAddress;
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @title Messages
 */
contract Messages {
    struct ProcessStream {
        uint64 start_time;
        uint64 end_time;
        uint64 amount;
        uint16 toChain;
        address sender;
        address receiver;
    }

    struct ProcessWithdrawStream {
        uint64 amount;
        uint16 toChain;
        address withdrawer;
    }

    struct ProcessDeposit {
        uint64 amount;
        uint16 toChain;
        address depositor;
    }

    struct ProcessFund {
        uint64 end_time;
        uint64 amount;
        uint16 toChain;
        address sender;
    }

    struct ProcessWithdraw {
        uint64 amount;
        uint16 toChain;
        address withdrawer;
    }

    struct ProcessSwap {
        uint64 amount;
        uint16 toChain;
        address sender;
    }
}