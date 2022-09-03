// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./JurisdictionFund.sol";

contract Legislatoor {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    mapping(uint => JurisdictionFund) public jurisdictions;

    // Using same ids as EthMap
    modifier onlyValidJurisdiction(uint jurisdictionId)
    {
       // Throws if jurisdiction id is not valid
        require(jurisdictionId >= 1 && jurisdictionId <= 178);
        _;
    }

    function contribute(uint jurisdictionId, uint amount) public onlyValidJurisdiction(jurisdictionId) {
        ensureJurisdictionCreated(jurisdictionId);

        jurisdictions[jurisdictionId].contribute(amount);
    }

    function submitDocument(uint jurisdictionId, string memory ipfsReference) public onlyValidJurisdiction(jurisdictionId) {
        ensureJurisdictionCreated(jurisdictionId);

        jurisdictions[jurisdictionId].submitDocument(ipfsReference);
    }

    function pickWinner(uint jurisdictionId, uint submissionId) public onlyValidJurisdiction(jurisdictionId) {
        ensureJurisdictionCreated(jurisdictionId);

        jurisdictions[jurisdictionId].pickWinner(submissionId);
    }

    function withdrawReward(uint jurisdictionId) public onlyValidJurisdiction(jurisdictionId) {
        ensureJurisdictionCreated(jurisdictionId);

        jurisdictions[jurisdictionId].withdrawReward();
    }

    function ensureJurisdictionCreated(uint jurisdictionId) private onlyValidJurisdiction(jurisdictionId) {
        if (address(jurisdictions[jurisdictionId]) == address(0)) {
            // Instatiate contract to manage contributions for this jurisdiction if not created yet.
            jurisdictions[jurisdictionId] = new JurisdictionFund(token);
        }
    }
}