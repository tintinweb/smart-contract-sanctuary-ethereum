// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import '../library/Errors.sol';

contract SendETH {
    struct SendRequest {
        uint256 requestId;
        address from;
        address payable to;
        uint256 amount;
        uint256 fee;
        uint256 indexInRequestIds;
        uint256 indexInRequestsFromSender;
        Password password;
    }

    struct Password {
        bytes32 hashedPassword;
        bool passwordIsSet;
        string salt;
    }

    struct RequestsForRecipient {
        mapping(uint256 => SendRequest) requests;
        uint256[] requestIds;
    }

    struct RequestFromSender {
        address to;
        uint256 requestId;
    }

    mapping(address => RequestsForRecipient) internal requestsForRecipients;
    mapping(address => RequestFromSender[]) internal requestsFromSender;

    uint256 internal requestIdCounter = 0;

    address public owner;
    bool public createSendRequestsEnabled = true;

    uint256 public feeBasisPointsOutOf10000 = 0;
    uint256 public feesCollected;

    constructor() {
        owner = msg.sender;
    }

    function createSendRequest(address payable _to) external payable {
        Password memory noPassword;
        _createSendRequest(_to, noPassword);
    }

    function createSendRequestWithPassword(address payable _to, bytes32 doubleHashedPassword, string memory salt) external payable {
        _createSendRequest(_to, Password(doubleHashedPassword, true, salt));
    }

    function _createSendRequest(address payable _to, Password memory password) internal {
        require(createSendRequestsEnabled, Errors.CREATE_SEND_REQUEST_DISABLED);

        uint256 fee = msg.value * feeBasisPointsOutOf10000 / 10000;

        uint256 indexInRequestIds = requestsForRecipients[_to].requestIds.length;
        requestsForRecipients[_to].requestIds.push(requestIdCounter);

        uint256 indexInRequestsFromSender = requestsFromSender[msg.sender].length;
        requestsFromSender[msg.sender].push(RequestFromSender(_to, requestIdCounter));

        requestsForRecipients[_to].requests[requestIdCounter] = SendRequest(requestIdCounter, msg.sender, _to, msg.value, fee, indexInRequestIds, indexInRequestsFromSender, password);

        requestIdCounter++;
    }

    function getSendRequestsForRecipient(address _to) external view returns (SendRequest[] memory) {
        if (requestsForRecipients[_to].requestIds.length == 0) return new SendRequest[](0);

        SendRequest[] memory allRequestsForRecipient = new SendRequest[](requestsForRecipients[_to].requestIds.length);

        for (uint256 i = 0; i < allRequestsForRecipient.length; i++) {
            uint256 currentRequestId = requestsForRecipients[_to].requestIds[i];

            allRequestsForRecipient[i] = requestsForRecipients[_to].requests[currentRequestId];
        }

        return allRequestsForRecipient;
    }

    function getSendRequestsSentByMe() external view returns (SendRequest[] memory) {
        if (requestsFromSender[msg.sender].length == 0) return new SendRequest[](0);

        SendRequest[] memory sendRequestsSentBySender = new SendRequest[](requestsFromSender[msg.sender].length);

        for (uint256 i = 0; i < sendRequestsSentBySender.length; i++) {
            RequestFromSender storage currentRequestFromSender = requestsFromSender[msg.sender][i];

            sendRequestsSentBySender[i] = requestsForRecipients[currentRequestFromSender.to].requests[currentRequestFromSender.requestId];
        }

        return sendRequestsSentBySender;
    }

    function acceptSendRequest(uint256 requestId) external {
        require(requestsForRecipients[msg.sender].requestIds.length > 0, Errors.NO_SEND_REQUESTS_AVAILABLE);
        require(requestsForRecipients[msg.sender].requests[requestId].from != address(0), Errors.SEND_REQUEST_DOES_NOT_EXIST);

        _acceptSendRequest(requestsForRecipients[msg.sender].requests[requestId].amount,
            requestsForRecipients[msg.sender].requests[requestId].from, requestId, requestsForRecipients[msg.sender].requests[requestId].fee);
    }

    function acceptSendRequestWithPassword(uint256 requestId, bytes32 passwordToHash) external {
        require(requestsForRecipients[msg.sender].requestIds.length > 0, Errors.NO_SEND_REQUESTS_AVAILABLE);
        require(requestsForRecipients[msg.sender].requests[requestId].from != address(0), Errors.SEND_REQUEST_DOES_NOT_EXIST);
        require(requestsForRecipients[msg.sender].requests[requestId].password.passwordIsSet == true, Errors.SEND_REQUEST_NOT_PASSWORD_PROTECTED);
        require(requestsForRecipients[msg.sender].requests[requestId].password.hashedPassword == keccak256(abi.encodePacked(passwordToHash)), Errors.WRONG_PASSWORD);

        _acceptSendRequest(requestsForRecipients[msg.sender].requests[requestId].amount,
            requestsForRecipients[msg.sender].requests[requestId].from, requestId, requestsForRecipients[msg.sender].requests[requestId].fee);
    }

    function _acceptSendRequest(uint256 amount, address from, uint256 requestId, uint256 fee) internal {
        _removeRequest(from, msg.sender, requestId);

        feesCollected += fee;
        payable(msg.sender).transfer(amount - fee);
    }

    function retractSendRequest(address to, uint256 requestId) external {
        require(requestsForRecipients[to].requests[requestId].from != address(0), Errors.SEND_REQUEST_DOES_NOT_EXISTS_OR_YOU_ARE_NOT_THE_SENDER);
        require(requestsForRecipients[to].requests[requestId].from == msg.sender, Errors.SEND_REQUEST_DOES_NOT_EXISTS_OR_YOU_ARE_NOT_THE_SENDER);

        uint256 amount = requestsForRecipients[to].requests[requestId].amount;
        _removeRequest(msg.sender, to, requestId);
        payable(msg.sender).transfer(amount);
    }

    function _removeRequest(address from, address to, uint256 requestId) internal {
        SendRequest memory requestToRemove = requestsForRecipients[to].requests[requestId];

        // remove requestId
        uint256 lastRequestIndexInRequestIds = requestsForRecipients[to].requestIds.length - 1;
        uint256 lastRequestId = requestsForRecipients[to].requestIds[lastRequestIndexInRequestIds];

        requestsForRecipients[to].requestIds[requestToRemove.indexInRequestIds] = lastRequestId;
        requestsForRecipients[to].requests[lastRequestId].indexInRequestIds = requestToRemove.indexInRequestIds;
        requestsForRecipients[to].requestIds.pop();
    
        // remove request from requestsFromSenderToRecipient
        uint256 lastRequestFromSenderRequestsIndex = requestsFromSender[from].length - 1;
        RequestFromSender memory lastRequestFromSenderRequests = requestsFromSender[from][lastRequestFromSenderRequestsIndex];

        requestsFromSender[from][requestToRemove.indexInRequestsFromSender] = lastRequestFromSenderRequests;
        requestsForRecipients[to].requests[lastRequestFromSenderRequests.requestId].indexInRequestsFromSender = requestToRemove.indexInRequestsFromSender;
        requestsFromSender[from].pop();

        // delete request
        delete requestsForRecipients[to].requests[requestId];
    }

    function setFees(uint256 _fees) external {
        require(msg.sender == owner, Errors.NOT_OWNER);
        feeBasisPointsOutOf10000 = _fees;
    }

    function withdrawCollectedFees() external {
        require(msg.sender == owner, Errors.NOT_OWNER);

        uint256 feesCollectedAmount = feesCollected;
        feesCollected = 0;
        payable(msg.sender).transfer(feesCollectedAmount);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, Errors.NOT_OWNER);
        owner = newOwner;
    }

    function setCreateSendRequestsEnabled(bool enable) external {
        require(msg.sender == owner, Errors.NOT_OWNER);
        createSendRequestsEnabled = enable;
    }

    function donate() external payable {
        feesCollected += msg.value;
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

library Errors {
    string constant NOT_OWNER = "NOT_OWNER";
    string constant SEND_REQUEST_DOES_NOT_EXISTS_OR_YOU_ARE_NOT_THE_SENDER = "SEND_REQUEST_DOES_NOT_EXISTS_OR_YOU_ARE_NOT_THE_SENDER";
    string constant NO_SEND_REQUESTS_AVAILABLE = "NO_SEND_REQUESTS_AVAILABLE";
    string constant SEND_REQUEST_DOES_NOT_EXIST = "SEND_REQUEST_DOES_NOT_EXIST";
    string constant SEND_REQUEST_NOT_PASSWORD_PROTECTED = "SEND_REQUEST_NOT_PASSWORD_PROTECTED";
    string constant WRONG_PASSWORD = "WRONG_PASSWORD";
    string constant CREATE_SEND_REQUEST_DISABLED = "CREATE_SEND_REQUEST_DISABLED";
}