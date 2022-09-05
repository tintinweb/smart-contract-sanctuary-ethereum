/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title data exchange agreements
/// @author iGrant.io
/// @dev To keep an audit trail of dexa transactions and permit authenticated data exchange
contract DEXA {
    // address of the contract owner
    address public owner;

    // organisation whitelist
    mapping(address => bool) organisations;

    // address to nonce to access token mapping
    mapping(address => mapping(string => string)) public accesstokens;

    // events
    // when owner is set.
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    // when organisation is added.
    event OrganisationAdded(address organisation);
    // when organisation is removed.
    event OrganisationRemoved(address organisation);
    // when access token is released to data using service organisation
    event AccessTokenReleased(
        address datausingservice,
        string token,
        string nonce
    );
    // when access token is added by data source organisation
    event AccessTokenAdded(address datasource, string token, string nonce);
    // when dda is finalised after negotiation
    event DDAFinalised(address organisation, string did);
    // when da is finalised after negotiation
    event DAFinalised(address organisation, string did);

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /// @dev Set contract deployer as owner
    constructor() {
        // set owner
        owner = msg.sender;

        // emit event
        emit OwnerSet(address(0), owner);
    }

    /// @dev Change owner of the contract
    /// @param newOwner address of new owner
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /// @dev Return owner address
    /// @return Owner address
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @dev A method to verify whether an organisation is a member of the whitelist
    /// @param _organisation The address to verify.
    /// @return Whether the organisation is a member of the whitelist.
    function isMember(address _organisation) public view returns (bool) {
        return organisations[_organisation];
    }

    /// @dev A method to add an organisation to whitelist
    /// @param _organisation The organisation to be added to the whitelist
    function addOrganisation(address _organisation) public isOwner {
        require(!isMember(_organisation), "Address is member already.");

        organisations[_organisation] = true;
        emit OrganisationAdded(_organisation);
    }

    /// @dev A method to remove a organisation from the whitelist
    /// @param _organisation The organisation to be removed from whitelist
    function removeOrganisation(address _organisation) public isOwner {
        require(isMember(_organisation), "Not member of whitelist.");

        delete organisations[_organisation];
        emit OrganisationRemoved(_organisation);
    }

    /// @dev Adds encrypted access token to be released.
    /// @param _nonce: Nonce associated with the DDA pull data didcomm message
    /// @param _accesstoken: Authcrypt access token
    function addAccessToken(string memory _nonce, string memory _accesstoken)
        public
    {
        require(isMember(msg.sender), "Not member of whitelist.");

        // Add the access token
        accesstokens[msg.sender][_nonce] = _accesstoken;

        // Emit the event
        emit AccessTokenAdded(msg.sender, _accesstoken, _nonce);
    }

    /// @dev Releases encrypted access token.
    /// @param _nonce: Nonce associated with the DDA pull data didcomm message
    /// @return Return the access token
    function releaseAccessToken(string memory _nonce)
        public
        returns (string memory)
    {
        require(isMember(msg.sender), "Not member of whitelist.");

        string memory token = accesstokens[msg.sender][_nonce];

        // Emit the event
        emit AccessTokenReleased(msg.sender, token, _nonce);

        // Delete the released token.
        delete accesstokens[msg.sender][_nonce];

        return token;
    }

    /// @dev Emit data agreement did:mydata identifier after finalisation
    /// @param _did: did:mydata identifier for data agreement
    function emitDADID(string memory _did) public {
        require(isMember(msg.sender), "Not member of whitelist.");

        emit DAFinalised(msg.sender, _did);
    }

    /// @dev Emit data disclosure agreement did:mydata identifier after finalisation
    /// @param _did: did:mydata identifier for data disclosure agreement
    function emitDDADID(string memory _did) public {
        require(isMember(msg.sender), "Not member of whitelist.");

        emit DDAFinalised(msg.sender, _did);
    }
}