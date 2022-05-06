/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract HealthChangeCFRequest {

    enum RequestStatus {
        COMPLETED,
        PARTIAL_RAISE,
        FAILED,
        IN_PROGRESS
    }

    struct User {
        string firstName;
        string lastName;
        address userAddress;
        string userID;
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

    struct Donations {
        uint256 donationAmount;
        uint256 donationDateTime;
    }
    mapping (address => User) users;
    mapping (address => Donations) donations;

    uint256 public creationDateTime;
    uint256 public  expiryDateTime;
    uint256 public requiredEth;
    RequestStatus public status = RequestStatus.IN_PROGRESS;
    uint256 public collectedEth;
    uint256 public minimumEthRequired;

    Requester public caseRequester;

    modifier isRequester() {
        require (msg.sender == caseRequester.payOutAddress, "Caller is not the funds requester");
        _;
    }
    
    modifier isNotRequester() {
        require (msg.sender != caseRequester.payOutAddress, "Requester cannot donate money!");
        _;
    }

    constructor (uint256 _creationDateTime, uint256 _expiryDateTime, uint256 _requiredEth, uint256 _minimumEthRequired, string memory _firstName, 
    string memory _lastName, 
    address _userAddress, 
    string memory _userID, 
    string memory _caseReferenceIPFS, 
    string memory _caseReferenceWebsite, 
    address _payoutAddress) {
        creationDateTime = _creationDateTime;
        expiryDateTime = _expiryDateTime;
        requiredEth = _requiredEth;
        minimumEthRequired = _minimumEthRequired;
        caseRequester = Requester(_firstName, _lastName, _userAddress, _userID, _caseReferenceIPFS, _caseReferenceWebsite, _payoutAddress);
    }

    function donate() payable public isNotRequester {
        require(block.timestamp < expiryDateTime, "Request timeperiod ended");
        require(status == RequestStatus.IN_PROGRESS, "Request currently not accepting donations");
        if (collectedEth < requiredEth) {
            collectedEth = collectedEth + msg.value;
            Donations memory newDonation = Donations(msg.value, block.timestamp);
            donations[msg.sender] = newDonation;
            if (collectedEth > requiredEth) {
                (bool sent, bytes memory data) = payable(msg.sender).call{value: collectedEth - requiredEth}("");
                require(sent, "Failed to send Ether");
                (bool _sent, bytes memory _data) = payable(caseRequester.payOutAddress).call{value: address(this).balance}("");
                require(_sent, "Failed to send Ether");
                status = RequestStatus.COMPLETED;
            }
        }
    }

    function withdraw() public isRequester {
        if (collectedEth >= requiredEth) {
            (bool sent, bytes memory data) = payable(caseRequester.payOutAddress).call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
            status = RequestStatus.COMPLETED;
        }
        if (block.timestamp >= expiryDateTime && collectedEth >= minimumEthRequired) {
            (bool sent, bytes memory data) = payable(caseRequester.payOutAddress).call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
            status = RequestStatus.PARTIAL_RAISE;
        }
        if (block.timestamp >= expiryDateTime && collectedEth < minimumEthRequired) {
            // Refund code here
            status = RequestStatus.FAILED;
        }
        revert("Funding request still active and target not reached");
    }

    fallback() external payable {
        donate();
    } 

    receive() external payable {
        donate();
    } 

    function registerUser(string memory _firstName, string memory _lastName, address _userAddress, string memory _userID) public {
        // Will change it to v,r,s signature
        User memory newUser = User(_firstName, _lastName, _userAddress, _userID);
        users[msg.sender] = newUser;
    }

}