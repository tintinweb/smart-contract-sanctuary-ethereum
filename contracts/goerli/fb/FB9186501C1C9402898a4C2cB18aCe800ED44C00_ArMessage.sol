/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

interface IInbox {
    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}
interface IBridge {
    function activeOutbox() external view returns (address);
}

interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}
interface IArbSys {
    function sendTxToL1(
        address destAddr,
        bytes calldata calldataForL1
    ) external payable;
}

contract ArMessage {
    event MessageReceived(bytes);
    event MessageSend(bytes);
    event RetryableTicketCreated(uint256 indexed ticketId);

    constructor() {}

    function sendMsgToL1(
        address l2Addr,
        address l1Addr,
        bytes memory _data
    ) public {
        bytes memory newData = abi.encodeWithSignature("hello(bytes)", _data);
        bytes[2] memory dataArray = [newData, _data];
        IArbSys(l2Addr).sendTxToL1(l1Addr, newData);
        emit MessageSend(_data);
    }

    function hello(bytes memory _data) public {
        emit MessageReceived(_data);
    }

    function sendMsgToL2(
        address l1Addr,
        address l2Target,
        bytes memory _data,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable {
        bytes memory newData = abi.encodeWithSignature("hello(bytes)", _data);
        IInbox inbox = IInbox(l1Addr);
        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            newData
        );
        emit RetryableTicketCreated(ticketID);
        emit MessageSend(_data);
    }
}