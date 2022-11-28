// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../errors/ITermsErrors.sol";
import "../types/TermsDataTypes.sol";

library TermsLogic {
    using TermsLogic for TermsDataTypes.Terms;

    event TermsActivationStatusUpdated(bool isActivated);
    event TermsUpdated(string termsURI, uint8 termsVersion);
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);

    /// @notice activates / deactivates the terms of use.
    function setTermsActivation(TermsDataTypes.Terms storage termsData, bool _active) external {
        if (_active) {
            _activateTerms(termsData);
        } else {
            _deactivateTerms(termsData);
        }
    }

    /// @notice updates the term URI and pumps the terms version
    function setTermsURI(TermsDataTypes.Terms storage termsData, string calldata _termsURI) external {
        if (keccak256(abi.encodePacked(termsData.termsURI)) == keccak256(abi.encodePacked(_termsURI)))
            revert TermsUriAlreadySet();
        if (bytes(_termsURI).length > 0) {
            termsData.termsVersion = termsData.termsVersion + 1;
            termsData.termsActivated = true;
        } else {
            termsData.termsActivated = false;
        }
        termsData.termsURI = _termsURI;
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsURI`
    function acceptTerms(TermsDataTypes.Terms storage termsData, address _acceptor) external {
        if (!termsData.termsActivated) revert TermsNotActivated();
        if (termsData.termsAccepted[_acceptor] && termsData.acceptedVersion[_acceptor] == termsData.termsVersion)
            revert TermsAlreadyAccepted(termsData.termsVersion);
        termsData.termsAccepted[_acceptor] = true;
        termsData.acceptedVersion[_acceptor] = termsData.termsVersion;
    }

    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails(TermsDataTypes.Terms storage termsData)
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        )
    {
        return (termsData.termsURI, termsData.termsVersion, termsData.termsActivated);
    }

    /// @notice returns true / false for whether the account owner accepted terms
    function hasAcceptedTerms(TermsDataTypes.Terms storage termsData, address _address) external view returns (bool) {
        return termsData.termsAccepted[_address] && termsData.acceptedVersion[_address] == termsData.termsVersion;
    }

    /// @notice returns true / false for whether the account owner accepted terms
    function hasAcceptedTerms(
        TermsDataTypes.Terms storage termsData,
        address _address,
        uint8 _version
    ) external view returns (bool) {
        return termsData.termsAccepted[_address] && termsData.acceptedVersion[_address] == _version;
    }

    /// @notice activates the terms
    function _activateTerms(TermsDataTypes.Terms storage termsData) internal {
        if (bytes(termsData.termsURI).length == 0) revert TermsURINotSet();
        if (termsData.termsActivated) revert TermsStatusAlreadySet();
        termsData.termsActivated = true;
    }

    /// @notice deactivates the terms
    function _deactivateTerms(TermsDataTypes.Terms storage termsData) internal {
        if (!termsData.termsActivated) revert TermsStatusAlreadySet();
        termsData.termsActivated = false;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface TermsDataTypes {
    /**
     *  @notice The criteria that make up terms.
     *
     *  @param termsActivated       Indicates whether the terms are activated or not.
     *
     *  @param termsVersion         The version of the terms.
     *
     *  @param termsURI             The URI of the terms.
     *
     *  @param acceptedVersion      Mapping with the address of the acceptor and the version of the terms accepted.
     *
     *  @param termsAccepted        Mapping with the address of the acceptor and the status of the terms accepted.
     *
     */
    struct Terms {
        bool termsActivated;
        uint8 termsVersion;
        string termsURI;
        mapping(address => uint8) acceptedVersion;
        mapping(address => bool) termsAccepted;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

error TermsNotActivated();
error TermsStatusAlreadySet();
error TermsURINotSet();
error TermsUriAlreadySet();
error TermsAlreadyAccepted(uint8 acceptedVersion);

error TermsCanOnlyBeSetByOwner(address token);
error TermsNotActivatedForToken(address token);
error TermsStatusAlreadySetForToken(address token);
error TermsURINotSetForToken(address token);
error TermsUriAlreadySetForToken(address token);
error TermsAlreadyAcceptedForToken(address token, uint8 acceptedVersion);