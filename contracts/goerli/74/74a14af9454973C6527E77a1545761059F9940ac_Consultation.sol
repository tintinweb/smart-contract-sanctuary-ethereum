/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

contract Consultation {
    address deployer;
    uint256 favourable;
    uint256 against;
    bool consultationStatus;
    mapping(address => bool) walletAuthorized;
    mapping(address => bool) hasVoted;
    event ConsultationClosed(bool _consultationStatus);
    event AddAuthorizedWallet(address _authorizedWallet);
    event ThankyouForYourVote(string _thankyout);
    constructor () {
        deployer = msg.sender;
        consultationStatus = false;
        favourable = 0;
        against = 0;
    }
    function changeConsultationState () public onlyDeployer() {
        consultationStatus = !consultationStatus;
        emit ConsultationClosed(consultationStatus);
    }
    function transferAdmin (address _wallet) public onlyDeployer() {
        deployer = _wallet;
    }
    function getStatusConsultation () public view returns(bool) {
        return consultationStatus;
    }
    function authorizeWallet (address _wallet) public onlyDeployer() {
        walletAuthorized[_wallet] = true;
        emit AddAuthorizedWallet(_wallet);
    }
    function vote (bool _vote) public isAuthorized() {
        require(consultationStatus != false, "Consultation is closed");
        require(msg.sender != deployer, "Address deployer Can't emmit vote");
        require(hasVoted[msg.sender] == false, "You have already voted");
        if (_vote == true) {
            favourable++;
        } else {
            against++;
        }
        hasVoted[msg.sender] = true;
        uint256 totalVotes = favourable + against;
        if (totalVotes == 5) {
            consultationStatus = false;
        }
        emit ThankyouForYourVote("thank you for your vote");
    }
    function getAllVotes () public view returns(uint256 _allVotes) {
        _allVotes = favourable + against;
        return _allVotes;
    }
    function getFavourable () public view returns(uint256) {
        return favourable;
    }
    function getAgainst () public view returns(uint256) {
        return against;
    }
    modifier onlyDeployer () {
        require(msg.sender == deployer, "Only deployer can do this action");
        _;
    }
    modifier isAuthorized () {
        require(walletAuthorized[msg.sender] == true, "You are not authorized");
        _;
    }
}