// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./DecentradsCounter.sol";
// import "hardhat/console.sol";

contract DecentradsApplication {
    constructor(address[] memory _whitelistedAddress, address _owner, address _decentrads){
        uint256 i;
        totalVoters = 0;
        for(i = 0; i < _whitelistedAddress.length; i++) {
            if(!whitelistedAddress[_whitelistedAddress[i]])
            {
                whitelistedAddress[_whitelistedAddress[i]] = true;
                totalVoters += 1;
            }
        }
        decentradAppOwner = _owner;
        decentrads = _decentrads;
    }

    using Counters for Counters.Counter;
    Counters.Counter public addId;

    struct Ad {
        uint256 budget;
        address adOwner;
        string adTitle;
        string description;
        uint256 totalVoted;
        uint256 startDate;
        uint256 numberOfDays;
        uint256 submissionTime;
        bool appovedByApp;
        bool claimedFundsByDapp;
        uint256 voterShare;
    }

    address public decentradAppOwner;
    address public decentrads;
    uint256 public totalVoters;
    uint256 public decentradsFee = 10;
    uint256 public voterIncentiveFee = 10;
    bool public isReported;

    mapping (address => bool) public whitelistedAddress;
    mapping (uint256 => Ad) public adInfo;
    mapping (address => mapping(uint256 => bool)) public isVoted;
    mapping (address => uint256) public totalUserIncentive;

    modifier onlyOwner() {
        require(decentradAppOwner == msg.sender, "Only owner can call this function");
        _;
    }

    modifier isNotReported() {
        require(!isReported, "Dapp is reported");
        _;
    }

    function postAd(string calldata _title, string calldata _decription, uint256 _startDate, uint256 _numberOfDays) external payable isNotReported() {
        require(msg.value > 0, "Budget should be greater than 0 ether");
        require(_startDate - block.timestamp > 2 days , "Time should be 2 days ahead of now due to voting reasons");        

            uint256 currentId = addId.current();
            adInfo[currentId].adOwner = msg.sender;
            adInfo[currentId].adTitle = _title;
            adInfo[currentId].description = _decription;
            adInfo[currentId].budget = msg.value;
            adInfo[currentId].startDate = _startDate;
            adInfo[currentId].numberOfDays = _numberOfDays;
            adInfo[currentId].submissionTime = block.timestamp;
            addId.increment();
    }

    function approveAd(uint256 _adId) external onlyOwner isNotReported() {
        require(adInfo[_adId].adOwner != address(0), "Ad not found");
        require(adInfo[_adId].budget != 0, "your ad is already approved by dapp");
        require(adInfo[_adId].startDate > block.timestamp, "you cannot approve an ad after start time");
        adInfo[_adId].appovedByApp = true;

    }

    function retrieveAd(uint256 _adId) external {
        require(adInfo[_adId].adOwner == msg.sender, "only ad owner can retreive ad");
        require(!adInfo[_adId].appovedByApp, "your ad is already approved by dapp");
        // require(block.timestamp - adInfo[_adId].submissionTime > 2 days, "");
        uint256 adBudget = adInfo[_adId].budget;
        adInfo[_adId].budget = 0;
        //transfer back ad owners funds
        payable(msg.sender).transfer(adBudget);
    }

    function claimFunds(uint256 _adId) external onlyOwner {
        require(adInfo[_adId].appovedByApp, "ad is not approved by dapp or Ad does not exist with given id");
        require(!adInfo[_adId].claimedFundsByDapp, "You already claimed your funds");
        //if ad is ended
        // require(block.timestamp > (adInfo[_adId].startDate + adInfo[_adId].numberOfDays * 86400) ,"ad is not ended yet to claim funds");
        //funds transfer to dapp owner
        uint256 adBudget = adInfo[_adId].budget;
        uint256 decentradsShare = (adBudget * decentradsFee)/100;
        adInfo[_adId].claimedFundsByDapp = true;
        (bool sentToDecentrads,) = payable(decentrads).call{value: decentradsShare}("");
        require(sentToDecentrads, "Transfer failed");
        (bool sentToDappOwner,) = payable(msg.sender).call{value: adBudget - decentradsShare - adInfo[_adId].voterShare}("");
        require(sentToDappOwner, "Transfer failed");

    }

    function voteOnAd(uint256 _adId) external {
        require(whitelistedAddress[msg.sender] == true,"Only Whitelisted Addresses allows to vote");
        // require(adInfo[_adId].budget != 0, "Ad does not exist with given id");
        require(adInfo[_adId].appovedByApp, "ad is not approved by dapp or Ad does not exist with given id");
        require(!isVoted[msg.sender][_adId], "Already voted");
        require(block.timestamp - adInfo[_adId].submissionTime <= 2 days, "Voting time passed");
        adInfo[_adId].totalVoted += 1;
        isVoted[msg.sender][_adId] = true;
        uint256 voterShare = ((adInfo[_adId].budget*voterIncentiveFee)/100)/totalVoters;
        totalUserIncentive[msg.sender] += voterShare;
        adInfo[_adId].voterShare += voterShare;
    }

    function claimFundsByVoter() external {
        require(whitelistedAddress[msg.sender], "you are not a whitelisted voter");
        require(totalUserIncentive[msg.sender] > 0, "you do not have any reward to claim");
        uint256 userReward = totalUserIncentive[msg.sender];
        totalUserIncentive[msg.sender] = 0;
        (bool sentToVoter,) = payable(msg.sender).call{value: userReward}("");
        require(sentToVoter, "Transfer failed");
    }

    function isValidAd(uint256 _adId) view external returns(bool, uint256) {
        uint256 votedPercent = (adInfo[_adId].totalVoted*100/totalVoters);
        if( votedPercent < 49) {
            return (true,votedPercent);
        }
        return (false,votedPercent);
    }

    function reportDapp() external {
        require(msg.sender == decentrads, "only Factory contract can remove this appliction");
        isReported = true;
    }

    function whitelistAddress(address _user) external onlyOwner() isNotReported() {
        require(!whitelistedAddress[_user], "user is already whitelisted");

        whitelistedAddress[_user] = true;
        totalVoters +=1;
    }

    function blockAddress(address _user) external onlyOwner() isNotReported() {
        require(whitelistedAddress[_user], "user is already blocked");

        whitelistedAddress[_user] = false;
        totalVoters-=1;
    }
}


contract DecentradsFactory {
    using Counters for Counters.Counter;
    Counters.Counter public dappId;
    Counters.Counter public dappReportId;


    uint256 dappCollatoralAmount = 1000000000000000;
    uint256 voterCollatoralAmount = 1000000000000000;

    struct DecentradsAppInfo {
        uint256 id;
        DecentradsApplication application;
        bool reported;
        mapping(uint256 => ReportProposal) dappReport;
    }

    struct Voter {
        address voterAddress;
        uint256 collateral;
    }

    struct ReportProposal {
        address dappAddress;
        string reportReason;
        uint256 numberOfVotes;
        bool isPassed;
    }

    mapping (address => DecentradsAppInfo) public dappInfo;
    mapping (address => Voter) public voterInfo;
    mapping(address => DecentradsApplication) private decentradsApp;

    uint256 public totalVoters;
    

    modifier onlyVoter () {
        require(msg.sender == voterInfo[msg.sender].voterAddress, "only voter can execute this function");
        require(voterInfo[msg.sender].collateral != 0, "only voter can execute this function");
        _;
    }

    function viewDappAddress() external view returns(address) {
        return address(dappInfo[msg.sender].application);    
    }

    function registerApplication(address[] calldata _whitelistedAddress) external payable {
        require(msg.value == dappCollatoralAmount, "Collateral Amount is not 0.01 ETH");
        require(_whitelistedAddress.length >= 0, "Please provide an array as whitelisted Addresses");
        require(address(dappInfo[msg.sender].application) == address(0), "Application Already Registered");
        DecentradsApplication dapp = new DecentradsApplication(_whitelistedAddress, msg.sender, address(this));
        dappInfo[msg.sender].id = dappId.current();
        dappInfo[msg.sender].application = dapp;
        decentradsApp[msg.sender] = DecentradsApplication(dapp);
        dappId.increment();
    }

    function registerVoter() external payable {
        //voter removed condition is not handled yet
        require(voterInfo[msg.sender].voterAddress == address(0), "already registered as Voter");
        require(msg.value == voterCollatoralAmount, "Collateral Amount is not 0.001 ETH");
        voterInfo[msg.sender].collateral = msg.value;
        voterInfo[msg.sender].voterAddress = msg.sender;
        totalVoters +=1;
    }

    function ReportDapp(address _dappAddress, string calldata _reportReason) external onlyVoter {
        require(!decentradsApp[_dappAddress].isReported(), "Dapp already reported");
        ReportProposal memory report;
        report.dappAddress = _dappAddress;
        report.reportReason = _reportReason;
        dappInfo[_dappAddress].dappReport[dappReportId.current()] = report;
        dappReportId.increment();
    }

    function voteOnReport(address _dappAddress, uint256 _reportId) external onlyVoter {
        require(dappInfo[_dappAddress].dappReport[_reportId].dappAddress != address(0), "This proposal does not exist");
        dappInfo[_dappAddress].dappReport[_reportId].numberOfVotes += 1;
    }

    function applyReportDapp(address _dappAddress, uint256 _reportId) external onlyVoter {
        //calculations here
        (bool reported, ) = isProposalSuccess(_dappAddress, _reportId);
        require(reported, "Dapp is not reported by proposal");
        decentradsApp[_dappAddress].reportDapp();
    }

    function isProposalSuccess(address _dappAddress, uint256 _reportId) view internal returns(bool, uint256) {
        uint256 votedPercent = (dappInfo[_dappAddress].dappReport[_reportId].numberOfVotes*100/totalVoters);
        if( votedPercent > 49) {
            return (true,votedPercent);
        }
        return (false,votedPercent);
    }

    receive() external payable {
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}