/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract TenderProcess {
    struct Bidder {
        uint financialScore;
        uint technicalScore;
        uint bidPrice;
        uint qualityScore;
        uint TenderScore;
        bool isQualified;
        string bidDocumentlinke;
        string bidDocumenthash;
        address bidderAddress;
    }

    struct Tender {
        address BidManagerAddress; // Bid Manager address
        string tenderInformation; // Tender information
        string link; // Tender file Link
        string hash; // Tender file hash
        uint estimatedCost; // Estimated cost
        string prequalificationStartDate; // Prequalification start date
        string prequalificationEndDate; // Prequalification end date
        uint minScore; // Minimum acceptable Prequalification score
        string bidSubmissionStartDate; // Bid submission start date
        string bidSubmissionEndDate; // Bid submission end date
        string contractAwardDate; // Contract award date

    }

    address public BidManager;
    address public winner; // winner address
    bool public isAwarded; // contract status
    bool public isSigned; // contract signed status
    uint public minScore;
    mapping(address => Bidder) public bidders;
    mapping(address => bool) public prequalificationStatus;
    address[] public bidderAddress;
    Tender public tender; // Tender details

    constructor() {
    BidManager = msg.sender;
    minScore = 80;
    isAwarded = false;
    isSigned = false;  
}




modifier notAwarded() {
    require(!isAwarded, "Contract has been awarded already");
    _;
}



function initiateTender(
    string memory _tenderInformation,
    string memory _link,
    string memory _hash,
    uint _estimatedCost,
    string memory _prequalificationStartDate,
    string memory _prequalificationEndDate,
    uint _minScore,
    string memory _bidSubmissionStartDate,
    string memory _bidSubmissionEndDate,
    string memory _contractAwardDate,
    address _BidManagerAddress
) public  {
    BidManager = _BidManagerAddress;
    
    tender = Tender({
        BidManagerAddress: _BidManagerAddress,
        tenderInformation: _tenderInformation,
        link: _link,
        hash: _hash,
        estimatedCost: _estimatedCost,
        prequalificationStartDate: _prequalificationStartDate,
        prequalificationEndDate: _prequalificationEndDate,
        minScore: _minScore,
        bidSubmissionStartDate: _bidSubmissionStartDate,
        bidSubmissionEndDate: _bidSubmissionEndDate,
        contractAwardDate: _contractAwardDate
        });
    }


    // 1. Prequalification Submission
    function submitPrequalification(address _bidderAddress, uint _cashReserve, uint _currentRatio, uint _equityCapitalRatio, uint _debtToEquityRatio, uint _totalTurnover, uint _workCompletedValue,
        uint _similarProjects, uint _completionRecord, uint _yearsCertified) public {

        uint _financialScore = getFinancialScore(_cashReserve, _currentRatio, _equityCapitalRatio, _debtToEquityRatio, _totalTurnover, _workCompletedValue);
        uint _technicalScore = getTechnicalScore(_similarProjects, _completionRecord, _yearsCertified);

        bool isQualified = (_financialScore + _technicalScore) >= minScore;

        bidders[_bidderAddress] = Bidder({
    financialScore: _financialScore,
    technicalScore: _technicalScore,
    bidPrice: 0,
    qualityScore: 0,
    TenderScore: 0,
    isQualified: isQualified,
    bidDocumentlinke: "",
    bidDocumenthash: "",
    bidderAddress: _bidderAddress 
});
        prequalificationStatus[_bidderAddress] = isQualified;
        bidderAddress.push(_bidderAddress);
    }

    // 2. Calculate Prequalification Scores
    function calculatePrequalificationScores() public  {
        for (uint i = 0; i < bidderAddress.length; i++) {
            Bidder storage bidder = bidders[bidderAddress[i]];
            if(bidder.financialScore + bidder.technicalScore >= minScore) {
                bidder.isQualified = true;
            } else {
                bidder.isQualified = false; 
            }
        }
    }

    // 3. Submit Bid
    function submitBid(
    address _bidderAddress,
    string memory _bidDocumentlinke, 
    string memory _bidDocumenthash, 
    uint _bidPrice, 
    uint _completedProjects, 
    uint _issuesPercent, 
    uint _equipmentProvision, 
    uint _technicalSkills
) 
public {
    require(prequalificationStatus[_bidderAddress], "Bidder is not qualified to submit a bid");
    bidders[_bidderAddress].bidDocumentlinke = _bidDocumentlinke;
    bidders[_bidderAddress].bidDocumenthash = _bidDocumenthash;
    bidders[_bidderAddress].bidderAddress = _bidderAddress; 
    bidders[_bidderAddress].bidPrice = _bidPrice;
    bidders[_bidderAddress].qualityScore = getQualityScore(_completedProjects, _issuesPercent, _equipmentProvision, _technicalSkills);
}

    // 4. Calculate Score
    function calculateScore() public  {
        for (uint i = 0; i < bidderAddress.length; i++) {
            Bidder storage bidder = bidders[bidderAddress[i]];
            if(bidder.bidPrice > 0 && bidder.qualityScore > 0) {
                uint bidPriceScore = getBidPriceScore(bidder.bidPrice);
                bidder.TenderScore = 7 * bidPriceScore + 3 * bidder.qualityScore;
            }
        }
    }

    // 5. Determine Winner
    function getWinner() public view  returns (address _bidderAddress, uint _BidPrice, uint _TenderScore) {
        require(bidderAddress.length > 0, "No bidders present");

        address highestBidder = bidderAddress[0];
        uint highestScore = bidders[highestBidder].TenderScore;
        uint highestBid = bidders[highestBidder].bidPrice;

        for (uint i = 1; i < bidderAddress.length; i++) {
            if (bidders[bidderAddress[i]].TenderScore > highestScore) {
                highestBidder = bidderAddress[i];
                highestScore = bidders[highestBidder].TenderScore;
                highestBid = bidders[highestBidder].bidPrice;
            }
        }

        return (highestBidder, highestBid, highestScore);
    }

    // 6. Award Contract
    function awardContract() public  notAwarded {
    require(bidderAddress.length > 0, "No bidders present");

       (winner, , ) = getWinner();
       isAwarded = true;
}

    // 7. Bid Records
function BidRecords() public view  returns (address[] memory, uint256[] memory, uint256[] memory) {
    require(isAwarded, "Contract has not been awarded yet");

    address[] memory addresses = new address[](bidderAddress.length);
    uint256[] memory bidPrices = new uint256[](bidderAddress.length);
    uint256[] memory tenderScores = new uint256[](bidderAddress.length);

    for (uint256 i = 0; i < bidderAddress.length; i++) {
        Bidder storage bidder = bidders[bidderAddress[i]];
        addresses[i] = bidder.bidderAddress;
        bidPrices[i] = bidder.bidPrice;
        tenderScores[i] = bidder.TenderScore;
    }

    return (addresses, bidPrices, tenderScores);
}

   // 8. Sign Contract
      function SignContract(address _bidderAddress) public {
          require(_bidderAddress == winner, "Only the winner can execute this");
          require(isAwarded == true, "Contract has not been awarded yet");
          if (_bidderAddress == winner) {
          isSigned = true;
    }
            }

    function getBidPriceScore(uint bidPrice) private pure returns(uint) {
        if(bidPrice < 15000000 || bidPrice > 30000000) {
            revert("Bid price out of acceptable range");
        } else if(bidPrice >= 15000000 && bidPrice <= 20000000) {
            return 30;
        } else if(bidPrice > 20000000 && bidPrice <= 25000000) {
            return 15;
        } else if( bidPrice > 25000000 && bidPrice <= 30000000) {
            return 5;
        } else {
            return 0;
        }
    }

    function getFinancialScore(uint _cashReserve, uint _currentRatio, uint _equityCapitalRatio, uint _debtToEquityRatio, uint _totalTurnover, uint _workCompletedValue) private pure returns (uint) {
        uint score = 0;
        if(_cashReserve >= 750000) {
            score += 10;
        } else if(_cashReserve >= 275000 && _cashReserve < 750000) {
            score += 5;
        } else if(_cashReserve < 275000) {  
            score += 0;
        }
        
        if(_currentRatio >= 160) {
            score += 10;
        } else if(_currentRatio >= 90 && _currentRatio < 160) {
            score += 5;
        } else if(_currentRatio < 90) {
           score += 0; 
        }    
        if(_equityCapitalRatio >= 20000) { 
            score += 10;
        } else if(_equityCapitalRatio >= 15000 && _equityCapitalRatio < 20000) {
            score += 5;
        } else if(_equityCapitalRatio < 15000) {
           score += 0; 
        }    
        if(_debtToEquityRatio <= 50) { 
            score += 10;
        } else if(_debtToEquityRatio >= 50 && _debtToEquityRatio <= 200) {
            score += 5;
        } else if(_debtToEquityRatio > 200) {
           score += 0; 
        }
        if(_totalTurnover >= 30000000) { 
            score += 10;
        } else if(_totalTurnover >=15000000 && _totalTurnover < 30000000) {
            score += 5;
        } else if(_totalTurnover < 15000000) {
           score += 0; 
        }
        if(_workCompletedValue >= 50000000) { 
            score += 10;
        } else if(_workCompletedValue >=30000000 && _workCompletedValue < 50000000) {
            score += 5;
        } else if(_workCompletedValue < 30000000) {
           score += 0; 
        }
        return score;
    }

    function getTechnicalScore(uint _similarProjects, uint _completionRecord, uint _yearsCertified) private pure returns (uint) {
        uint score = 0;
        if(_similarProjects > 6) {
            score += 10;
        } else if(_similarProjects >= 4 && _similarProjects <= 6) {    
            score += 5;
        } else if(_similarProjects < 4) {
            score += 0;
        }
        if(_completionRecord == 10000) {
            score += 10;
        } else if(_completionRecord >= 9000 && _completionRecord < 10000) {
            score += 5;
        } else if(_completionRecord < 9000) {
           score += 0;
        }
        if(_yearsCertified >= 10) {
            score += 10;
        } else if(_yearsCertified >=5 && _yearsCertified < 10) {
            score += 5;
        } else if(_yearsCertified < 5) {
           score += 0;
        }
        return score;
    }

    function getQualityScore(uint _completedProjects, uint _issuesPercent, uint _equipmentProvision, uint _technicalSkills) private pure returns (uint) {
    uint score = 0;
    if(_completedProjects >= 10) {
        score += 10;
    } else if(_completedProjects >= 5 && _completedProjects < 10) {
        score += 5;
    } else if(_completedProjects < 5) {
        score += 0;
    }
    if(_issuesPercent == 0) {
        score += 5;
    } else if(_issuesPercent > 0 && _issuesPercent <= 5) {
        score += 2;
    } else if(_issuesPercent > 5) {
        score += 0;    
    }
    if(_equipmentProvision == 100) {
        score += 5;
    } else if(_equipmentProvision > 0 && _equipmentProvision < 100) {
        score += 3;
    } else if(_equipmentProvision == 0) {
        score += 0; 
    }
    if(_technicalSkills >= 8000) {
        score += 10;
    } else if(_technicalSkills >= 5000 && _technicalSkills < 8000) {
        score += 5;
    } else if(_technicalSkills < 5000) {
        score += 0;     

    }
    return score;
    }
}