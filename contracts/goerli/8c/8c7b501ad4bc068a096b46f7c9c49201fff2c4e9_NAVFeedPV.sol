// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity >=0.5.15;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-math/math.sol";
import "tinlake-auth/auth.sol";

interface ShelfLike {
    function shelf(uint256 loan) external view returns (address registry, uint256 tokenId);
    function nftlookup(bytes32 nftID) external returns (uint256 loan);
    function loanCount() external view returns (uint256);
}

interface PileLike {
    function setRate(uint256 loan, uint256 rate) external;
    function debt(uint256 loan) external view returns (uint256);
    function pie(uint256 loan) external returns (uint256);
    function changeRate(uint256 loan, uint256 newRate) external;
    function loanRates(uint256 loan) external view returns (uint256);
    function file(bytes32, uint256, uint256) external;
    function rates(uint256 rate) external view returns (uint256, uint256, uint256, uint48, uint256);
    function rateDebt(uint256 rate) external view returns (uint256);
    function accrue(uint256 loan) external;
}

contract NAVFeedPV is Auth, Math {
    PileLike public pile;
    ShelfLike public shelf;

    struct NFTDetails {
        uint128 nftValues;
        uint128 risk;
    }

    struct LoanDetails {
        uint128 borrowed;
    }

    struct RiskGroup {
        // denominated in (10^27)
        uint128 ceilingRatio;
        // denominated in (10^27)
        uint128 thresholdRatio;
        // denominated in (10^27)
        uint128 recoveryRatePD;
    }

    // nft => details
    mapping(bytes32 => NFTDetails) public details;
    // loan => details
    mapping(uint256 => LoanDetails) public loanDetails;
    // risk => riskGroup
    mapping(uint256 => RiskGroup) public riskGroup;

    uint256 public latestNAV;
    uint256 public lastNAVUpdate;

    uint256 public constant WRITEOFF_RATE_GROUP = 1000;

    // events
    event Depend(bytes32 indexed name, address addr);
    event File(bytes32 indexed name, uint256 risk_, uint256 thresholdRatio_, uint256 ceilingRatio_, uint256 rate_);
    event Update(bytes32 indexed nftID, uint256 value);
    event Update(bytes32 indexed nftID, uint256 value, uint256 risk);

    // getter functions
    function risk(bytes32 nft_) public view returns (uint256) {
        return uint256(details[nft_].risk);
    }

    function nftValues(bytes32 nft_) public view returns (uint256) {
        return uint256(details[nft_].nftValues);
    }

    function ceilingRatio(uint256 riskID) public view returns (uint256) {
        return uint256(riskGroup[riskID].ceilingRatio);
    }

    function thresholdRatio(uint256 riskID) public view returns (uint256) {
        return uint256(riskGroup[riskID].thresholdRatio);
    }

    function borrowed(uint256 loan) public view returns (uint256) {
        return uint256(loanDetails[loan].borrowed);
    }

    constructor() {
        wards[msg.sender] = 1;
        lastNAVUpdate = uniqueDayTimestamp(block.timestamp);
        emit Rely(msg.sender);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    // returns the ceiling of a loan
    // the ceiling defines the maximum amount which can be borrowed
    function ceiling(uint256 loan) public view virtual returns (uint256) {
        bytes32 nftID_ = nftID(loan);
        uint256 initialCeiling = rmul(nftValues(nftID_), ceilingRatio(risk(nftID_)));
        return safeSub(initialCeiling, pile.debt(loan));
    }

    // --- Administration ---
    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "pile") pile = PileLike(addr);
        else if (contractName == "shelf") shelf = ShelfLike(addr);
        else revert();
        emit Depend(contractName, addr);
    }

    function file(bytes32 name, uint256 risk_, uint256 thresholdRatio_, uint256 ceilingRatio_, uint256 rate_)
        public
        auth
    {
        if (name == "riskGroup") {
            require(ceilingRatio(risk_) == 0, "risk-group-in-usage");
            riskGroup[risk_].thresholdRatio = toUint128(thresholdRatio_);
            riskGroup[risk_].ceilingRatio = toUint128(ceilingRatio_);

            // set interestRate for risk group
            pile.file("rate", risk_, rate_);
            emit File(name, risk_, thresholdRatio_, ceilingRatio_, rate_);
        } else {
            revert("unknown name");
        }
    }

    // --- Actions ---
    function borrow(uint256 loan, uint256 amount) external virtual auth returns (uint256 navIncrease) {
        require(ceiling(loan) >= amount, "borrow-amount-too-high");
        return amount;
    }

    function repay(uint256 loan, uint256 amount) external virtual auth {}

    function borrowEvent(uint256 loan, uint256) public virtual auth {
        uint256 risk_ = risk(nftID(loan));
        // when issued every loan has per default interest rate of risk group 0.
        // correct interest rate has to be set on first borrow event
        if (pile.loanRates(loan) != risk_) {
            // set loan interest rate to the one of the correct risk group
            pile.setRate(loan, risk_);
        }
    }

    function repayEvent(uint256 loan, uint256 amount) public virtual auth {}
    function lockEvent(uint256 loan) public virtual auth {}
    function unlockEvent(uint256 loan) public virtual auth {}

    function writeOff(uint256 loan) public auth {
        pile.changeRate(loan, WRITEOFF_RATE_GROUP);
    }

    function isLoanWrittenOff(uint256 loan) public view returns (bool) {
        return pile.loanRates(loan) == WRITEOFF_RATE_GROUP;
    }

    // --- NAV calculation ---
    function currentNAV() public view returns (uint256) {
        uint256 totalDebt;
        // calculate total debt
        for (uint256 loanId = 1; loanId <= shelf.loanCount(); loanId++) {
            totalDebt = safeAdd(totalDebt, pile.debt(loanId));
        }

        // substract writtenoff loans -> all writtenOff loans are moved to writeOffRateGroup
        totalDebt = safeSub(totalDebt, pile.rateDebt(WRITEOFF_RATE_GROUP));
        return totalDebt;
    }

    function calcUpdateNAV() public returns (uint256) {
        latestNAV = currentNAV();
        lastNAVUpdate = uniqueDayTimestamp(block.timestamp);
        return latestNAV;
    }

    function update(bytes32 nftID_, uint256 value) public auth {
        // switch of collateral risk group results in new: ceiling, threshold for existing loan
        details[nftID_].nftValues = toUint128(value);
        emit Update(nftID_, value);
    }

    function update(bytes32 nftID_, uint256 value, uint256 risk_) public auth {
        uint256 nnow = uniqueDayTimestamp(block.timestamp);
        details[nftID_].nftValues = toUint128(value);

        // no change in risk group
        if (risk_ == risk(nftID_)) {
            return;
        }

        // nfts can only be added to risk groups that are part of the score card
        require(thresholdRatio(risk_) != 0, "risk group not defined in contract");
        details[nftID_].risk = toUint128(risk_);

        // switch of collateral risk group results in new: ceiling, threshold and interest rate for existing loan
        // change to new rate interestRate immediately in pile if loan debt exists
        uint256 loan = shelf.nftlookup(nftID_);
        if (pile.pie(loan) != 0) {
            pile.changeRate(loan, risk_);
        }
        emit Update(nftID_, value, risk_);
    }

    // --- Utilities ---
    // returns the threshold of a loan
    // if the loan debt is above the loan threshold the NFT can be seized
    function threshold(uint256 loan) public view returns (uint256) {
        bytes32 nftID_ = nftID(loan);
        return rmul(nftValues(nftID_), thresholdRatio(risk(nftID_)));
    }

    // returns a unique id based on the nft registry and tokenId
    // the nftID is used to set the risk group and value for nfts
    function nftID(address registry, uint256 tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(registry, tokenId));
    }

    // returns the nftID for the underlying collateral nft
    function nftID(uint256 loan) public view returns (bytes32) {
        (address registry, uint256 tokenId) = shelf.shelf(loan);
        return nftID(registry, tokenId);
    }

    // returns true if the present value of a loan is zero
    // true if all debt is repaid or debt is 100% written-off
    function zeroPV(uint256 loan) public view returns (bool) {
        return ((pile.debt(loan) == 0) || (pile.loanRates(loan) == WRITEOFF_RATE_GROUP));
    }

    // normalizes a timestamp to round down to the nearest midnight (UTC)
    function uniqueDayTimestamp(uint256 timestamp) public pure returns (uint256) {
        return (1 days) * (timestamp / (1 days));
    }
}