// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
pragma experimental ABIEncoderV2;

import "./HealthChange.sol";

contract HealthChangeFactory {
    address public owner;

    HealthChangeCFRequest[] public fundingRequests;

    constructor() {
        owner = msg.sender;
    }

    struct Requester {
        string firstName;
        string lastName;
        address userAddress;
        string userID;
        string caseReferenceIPFS;
        string caseReferenceWebsite;
        address payOutAddress;
    }
    mapping (address => Requester) requesters;

    uint256 gweiConverter = 1000000000000000000;

    function createFundingRequest( 
    uint256 _expiryDateTime, 
    uint256 _requiredEth, 
    uint256 _minimumEthRequired, 
    string memory _firstName, 
    string memory _lastName, 
    string memory _userID, 
    string memory _caseReferenceIPFS, 
    string memory _caseReferenceWebsite, 
    address _payoutAddress) public {
        HealthChangeCFRequest newRequest = new HealthChangeCFRequest(block.timestamp, 
        _expiryDateTime, 
        _requiredEth * gweiConverter,
        _minimumEthRequired * gweiConverter, 
        _firstName, 
        _lastName, msg.sender, _userID, _caseReferenceIPFS, _caseReferenceWebsite, _payoutAddress);
    Requester memory newRequester = Requester(_firstName, _lastName, msg.sender, _userID, _caseReferenceWebsite, _caseReferenceIPFS, _payoutAddress);
    requesters[msg.sender] = newRequester;
    fundingRequests.push(newRequest);
    }

}