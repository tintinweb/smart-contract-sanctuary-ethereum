/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract TestPunkOL {

    event Register(address indexed vault, uint256 nftId);
    event Propose(address indexed proposer, address indexed vault, uint256 collateral, uint256 pricePerToken);
    event Reject(address indexed rejecter, address indexed vault, uint256 amount);
    event Withdraw(address indexed vault, uint256 listingId);
    event List(address indexed vault, uint256 listingId);
    event Delist(address indexed vault, uint256 listingId);

    struct Listing {
        address payable proposer;
        uint256 collateral;
        uint256 pricePerToken;
        uint256 proposalDate;
    }

    /// @notice mapping of vault address to all NFTs
    mapping(address => uint256) public vaultToNFT;
    /// @notice mapping of vault address to all listing proposals
    mapping(address => Listing[]) public listings;
    /// @notice mapping of vault address to the current listing ID
    mapping(address => uint256) public current;
    

    /// @notice register a vault and punk combo
    /// @param _vault the vault address
    /// @param _id the id of the punk
    function register(address _vault, uint256 _id) public {
        // in the real contract we check that we actually own this punk
        vaultToNFT[_vault] = _id;

        emit Register(_vault, _id);
    }

    /// @notice propose a new optimistic listing for a vault
    /// @param _vault the address of the vault we are OL for
    /// @param _collateral the amount of tokens the proposer is risking in the proposal
    /// @param _valPerToken the desired listing price of the punk divided by total supply of tokens
    function propose(address _vault, uint256 _collateral, uint256 _valPerToken) public {
        Listing memory newListing = Listing(payable(msg.sender), _collateral, _valPerToken, block.timestamp);
        listings[_vault].push(newListing);

        emit Propose(msg.sender, _vault, _collateral, _valPerToken);
    }

    /// @notice reject a listing proposal
    /// @param _vault the vault to reject proposal on
    /// @param _listingId the id of the listing to reject
    /// @param _amount the amount of tokens to reject
    function reject(address _vault, uint256 _listingId, uint256 _amount) public payable {
        Listing memory tempListing = listings[_vault][_listingId];
        require(tempListing.collateral >= _amount, "too many");
        require(tempListing.pricePerToken * _amount == msg.value, "wrong amount");

        // TODO transfer tokens to msg.sender
        tempListing.proposer.transfer(msg.value);
        listings[_vault][_listingId].collateral -= _amount;

        emit Reject(msg.sender, _vault, _amount);
    }

    /// @notice allow for the proposer to withdraw their listing after the 3 day period
    /// @param _vault address of the vault for the listing
    /// @param _listingId id of the listing
    function withdraw(address _vault, uint256 _listingId) public {
        Listing memory tempListing = listings[_vault][_listingId];
        require(tempListing.proposer == msg.sender, "not proposer");

        // TODO transfer tokens to proproser

        delete listings[_vault][_listingId];
    }

    /// @notice list an NFT for sale
    /// @param _vault the address of the vault to list
    /// @param _listingId the id of the listing
    function list(address _vault, uint256 _listingId, bytes32[] calldata) public {
        Listing memory tempListing = listings[_vault][_listingId];
        require(tempListing.collateral > 0, "rejected");
        require(tempListing.proposalDate + 3 days <= block.timestamp, "too soon");
        Listing memory currentListing = listings[_vault][current[_vault]];
        require(tempListing.pricePerToken < currentListing.pricePerToken, "not lower");
        
        // TODO delist current listing and list lower one
        current[_vault] = _listingId;

        emit List(_vault, _listingId);
    }

    /// @notice delist an NFT
    /// @param _vault the address of the vault to delist
    function delist(address _vault, bytes32[] calldata) public {
        Listing memory currentListing = listings[_vault][current[_vault]];
        require(currentListing.collateral == 0, "not rejected");

        // TODO delist
        emit Delist(_vault, current[_vault]);

        current[_vault] = 0;
    }

    function settle(address _vault, bytes32[] calldata, bytes32[] calldata) public {

    }

    function cash(address _vault, bytes32[] calldata) public {
        
    }

}