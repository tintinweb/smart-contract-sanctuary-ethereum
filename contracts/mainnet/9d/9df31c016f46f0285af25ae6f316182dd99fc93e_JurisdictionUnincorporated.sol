/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/OtoCoJurisdiction.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract OtoCoJurisdiction {

    string private name;
    string private defaultBadge;
    string private goldBadge;

    constructor (
        string memory _name,
        string memory _defaultBadge,
        string memory _goldBadge
    ) {
        name = _name;
        defaultBadge = _defaultBadge;
        goldBadge = _goldBadge;
    }

    /**
     * Get formatted name according to the jurisdiction requirement.
     * To use when create new series, before series creation.
     * Returns the string name formatted accordingly.
     *
     * @param count current number of series deployed at the jurisdiction.
     * @return nameToFormat name of the series to format accordingly.
     */
    function getSeriesNameFormatted (uint256 count, string calldata nameToFormat) public pure virtual returns(string memory);
    
    /**
     * Return the name of the jurisdiction.
     * 
     * @return name the name of the jurisdiction.
     */
    function getJurisdictionName () external view returns(string memory){
        return name;
    }

    /**
     * Return the NFT URI link of the jurisdiction.
     * 
     * @return defaultBadge the badge URI.
     */
    function getJurisdictionBadge () external view returns(string memory) {
        return defaultBadge;
    }

    /**
     * Return the Gold NFT URI link of the jurisdiction.
     * 
     * @return goldBadge the gold badge URI.
     */
    function getJurisdictionGoldBadge () external view returns(string memory){
        return goldBadge;
    }

}


// File contracts/jurisdictions/Unincorporated.sol
pragma solidity ^0.8.0;

contract JurisdictionUnincorporated is OtoCoJurisdiction {

    constructor (
        string memory _name,
        string memory _defaultBadge,
        string memory _goldBadge
    ) OtoCoJurisdiction(_name, _defaultBadge, _goldBadge) {}

    /**
     * @dev See {OtoCoJurisdiction-getSeriesNameFormatted}.
     */
    function getSeriesNameFormatted (
        uint256 count,
        string calldata nameToFormat
    ) public pure override returns(string memory){
        return nameToFormat;
    }

}