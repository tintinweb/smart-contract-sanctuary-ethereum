// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ETHDonLolo {
    struct donationRequest {
        string name;
        string github;
        string reason;
        uint256 ethAmount;
        bool isAlreadyRequester;
    }
    address payable[] public requesters;
    donationRequest[] public donationRequests;
    mapping(address => donationRequest) public requesterToDonationRequest;

    function sendDonationRequest(
        string memory _name,
        string memory _github,
        string memory _reason,
        uint256 _ethAmount
    ) public payable {
        // Requester can modify his latest request but can not add a new request
        if (!requesterToDonationRequest[msg.sender].isAlreadyRequester) {
            requesters.push(payable(msg.sender));
        }
        setDonationRequest(_name, _github, _reason, _ethAmount);
    }

    function removeDonationRequest() public payable {
        require(
            requesterToDonationRequest[msg.sender].isAlreadyRequester,
            "Error: You never requested donation!"
        );
        initDonationRequest(payable(msg.sender));
        removeRequester(payable(msg.sender));
    }

    function setDonationRequest(
        string memory _name,
        string memory _github,
        string memory _reason,
        uint256 _ethAmount
    ) public payable {
        requesterToDonationRequest[msg.sender].name = _name;
        requesterToDonationRequest[msg.sender].github = _github;
        requesterToDonationRequest[msg.sender].reason = _reason;
        requesterToDonationRequest[msg.sender].ethAmount = _ethAmount;
        requesterToDonationRequest[msg.sender].isAlreadyRequester = true;
    }

    function initDonationRequest(address payable requester) public payable {
        setDonationRequest("", "", "", 0);
        requesterToDonationRequest[requester].isAlreadyRequester = false;
    }

    function removeRequester(address payable requester) public payable {
        for (uint256 i; i < requesters.length; i++) {
            if (requesters[i] == payable(requester)) {
                requesters[i] = requesters[requesters.length - 1];
                requesters.pop();
            }
        }
    }

    function isAddressRequester(address payable requester)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < requesters.length; i++) {
            if (requesters[i] == requester) {
                return true;
            }
        }
        return false;
    }

    function donateToRequester(address payable requester) public payable {
        require(
            isAddressRequester(requester),
            "Error: address is not part of requester."
        );
        requester.transfer(msg.value);
        updateEthAmount(requester, msg.value);
    }

    function donateToAll() public payable {
        uint256 ethAmountForAll;
        if (requesters.length > 0) {
            ethAmountForAll = (msg.value / requesters.length);
        }

        for (uint256 i; i < requesters.length; i++) {
            requesters[i].transfer(ethAmountForAll);
            updateEthAmount(requesters[i], ethAmountForAll);
        }
    }

    function updateEthAmount(
        address payable requester,
        uint256 ethDonationAmount
    ) public payable {
        if (
            requesterToDonationRequest[requester].ethAmount > ethDonationAmount
        ) {
            requesterToDonationRequest[requester]
                .ethAmount -= ethDonationAmount;
        } else {
            requesterToDonationRequest[requester].ethAmount = 0;
            initDonationRequest(requester);
            removeRequester(requester);
        }
    }
}