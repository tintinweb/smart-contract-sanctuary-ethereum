/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface MemberInterface {
    function isMember(address _member) external view returns (bool);
}

/// @title A contract for authorized members to rate recipients
/// @author PoJu Chen
contract RatingToken {

    struct RT {
        address issuer;
        address recipient;
        string comment;
        uint256 score;
        uint256 timestamp;
    }

    mapping (address => mapping(address => RT)) private recipients;
    mapping (address => RT[]) private recipientToIssuers;
    mapping (address => RT[]) private issuerToRecipients;

    string public name;
    address public operator;
    address public memberContractAddress;
    address private nullAddress = 0x0000000000000000000000000000000000000000;
    bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    
    event Rate(address _issuer, address _recipient);
    event Burn(address _issuer, address _recipient);
    event Update(address _issuer, address _recipient);

    MemberInterface memberContract;

    constructor(string memory _name, address _memberContractAddress) {
      name = _name;
      memberContract = MemberInterface(_memberContractAddress);
      memberContractAddress = _memberContractAddress;
      operator = msg.sender;
    }

    modifier onlyMember() {
        require(memberContract.isMember(msg.sender), "You are not a member");
        _;
    }

    function setMemberContractAddress(address _address) external {
        require(msg.sender == operator, "Only operator can set the member contract address");
        memberContract = MemberInterface(_address);
        memberContractAddress = _address;
    }

    function _mintRT(address _issuer, address _recipient, string memory _comment, uint256 _score, uint256 _timestamp) private pure returns (RT memory) {
        return RT(_issuer, _recipient, _comment, _score, _timestamp);
    }

    function rate(address _recipient, string memory _comment, uint256 _score, uint256 _timestamp) external onlyMember() {
        // If token already exists, burn the original token and update a new one
        if (recipients[_recipient][msg.sender].issuer != nullAddress) {
            _burn(_recipient);
        }
        RT memory newToekn = _mintRT(msg.sender, _recipient, _comment, _score, _timestamp);
        recipients[_recipient][msg.sender] = newToekn;
        recipientToIssuers[_recipient].push(newToekn);
        issuerToRecipients[msg.sender].push(newToekn);
        emit Rate(msg.sender, _recipient);
    }

    function _burn(address _recipient) private {
        delete recipients[_recipient][msg.sender];
        for(uint i=0; i<recipientToIssuers[_recipient].length; i++){
            if (recipientToIssuers[_recipient][i].issuer == msg.sender) {
                // Move the last element into the place to delete
                recipientToIssuers[_recipient][i] = recipientToIssuers[_recipient][recipientToIssuers[_recipient].length - 1];
                // Remove the last element
                recipientToIssuers[_recipient].pop();
                break;
            }
        }
        for(uint i=0; i<issuerToRecipients[msg.sender].length; i++){
            if (issuerToRecipients[msg.sender][i].recipient == _recipient) {
                issuerToRecipients[msg.sender][i] = issuerToRecipients[msg.sender][issuerToRecipients[msg.sender].length - 1];
                issuerToRecipients[msg.sender].pop();
                break;
            }
        }
        emit Burn(msg.sender, _recipient);
    }

    function burn(address _recipient) external onlyMember() {
        _burn(_recipient);
    }

    function getRatings(address _recipient) external view onlyMember() returns (RT[] memory)  {
        return recipientToIssuers[_recipient];
    }

    function myRatings() external view onlyMember() returns (RT[] memory) {
        return issuerToRecipients[msg.sender];
    }

    function inspectSender() public view returns(address) {
        return msg.sender;
    }
}