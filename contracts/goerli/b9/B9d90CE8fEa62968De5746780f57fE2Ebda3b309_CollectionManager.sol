//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";

contract CollectionManager {
    NFTCollection public newcollection;  // NFT Smart Contract

    uint256 public currentcollections;  // count of Current exist Collections
    string[] public collectionnames;  // Collection Names Array
    
    address public treasury = 0xaaaffAb7763fB811f3d4C692BdA070A8474BcE93; // Treasury Account

    mapping(uint256 => NFTCollection) public nftcollectionsbyindex; // NFT Collection By Index
    mapping(string => NFTCollection) public nftcollectionsbyname; // NFT Collection By Collection Name
    mapping(string => bool) public collectionnameexists;  // Collections are exist. Collection should be Unique
    mapping(string => uint256) public mintprice; // CollectionName => mintPrice (this is for public mint collection)
    mapping(string => uint256) public royaltiprice; // CollectionName => royaltyprice
    mapping(string => address[]) public collaboratorsbycollectioname; // CollectionName => collaborators
    mapping(address => uint256) public royaltyvaluepercollaborators;  // Collaborators => royalty percentage

    // Event
    event CreateCollection(string name, string symbol, uint256 price, uint256 royalty, address[]  collaborators, NFTCollection new_contract);

    // Create Collection Function
    function creatcollection(
        string memory _collectionname, 
        string memory _collectionsymbol, 
        uint256 _mintprice, 
        uint256 _royalty,
        address[] memory _collaborators, 
        uint256[] memory _royaltypercollaborators
    ) public {
        require(!collectionnameexists[_collectionname], "Collection Name Should be Unique! Or exist!");
        for(uint256 i=0; i<_collaborators.length;i++) {
            royaltyvaluepercollaborators[_collaborators[i]] = _royaltypercollaborators[i];
        }
        mintprice[_collectionname] = _mintprice;
        royaltiprice[_collectionname] = _royalty;
        collaboratorsbycollectioname[_collectionname] = _collaborators;
        newcollection = new NFTCollection(_collectionname, _collectionsymbol);
        collectionnameexists[_collectionname] = true;
        collectionnames.push(_collectionname);
        currentcollections++;
        nftcollectionsbyindex[currentcollections] = newcollection;
        nftcollectionsbyname[_collectionname] = newcollection;

        emit CreateCollection(_collectionname, _collectionsymbol, _mintprice, _royalty, _collaborators, newcollection);

    }

    // Mint Public Tickets
    function publicmint(string memory _collectionName, string memory _tokenURI) public payable {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        require(msg.value == mintprice[_collectionName], 'The ETH amount should match with the Public Ticket Price');
        // Send Funds to treasury wallet.
        payable(treasury).transfer(msg.value);
        nftcollectionsbyname[_collectionName].safeMint(_tokenURI, msg.sender);
    }

    // Get Treasury wallet 
    function gettreasury() public view returns(address) {
        return treasury;
    }

    // Set Treasury Wallet
    function settreasury(address _newAddr) external {
        treasury = _newAddr;
    } 

    // Creat NFT Item by selected Collection
    function mintItem (string memory _collectionName, string memory _tokenURI) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        nftcollectionsbyname[_collectionName].safeMint(_tokenURI, msg.sender);
    }

    // Set Royalty
    function setRoyalty (string memory _collectionName, uint256 _newRoyalty) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        require(_newRoyalty >= 0 && _newRoyalty <= 10, "Royalty is range 0 to 10");
        royaltiprice[_collectionName] = _newRoyalty;
    }
    // Get Royalty
    function getRoyalty (string memory _collectionName) public view returns (uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return royaltiprice[_collectionName];
    }
    // Set collaborators
    function setcollaborators(string memory _collectionName, address[] memory _newcollaborators) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        collaboratorsbycollectioname[_collectionName] = _newcollaborators;
    }

    // get collaborators
    function getcollaborators(string memory _collectionName) public view returns(address[] memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return collaboratorsbycollectioname[_collectionName];
    }

    // Set Collaborators => royalty
    function Setroyaltyvaluepercollaborators(address _collaborator, uint256 _royalty) public {
        royaltyvaluepercollaborators[_collaborator] = _royalty;
    }

    // Get Collaborators => royalty
    function Getroyaltyvaluepercollaborators(address _collaborator) public view returns(uint256) {
        return royaltyvaluepercollaborators[_collaborator];
    }

    // Get Token Id by selected Collection
    function getTokenId (string memory _collectionName, address _addr) public view returns(uint256[] memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].getTokenId(_addr);
    }

    // Get Track by token id
    function getTrack (string memory _collectionName, uint256 _id) public view returns(address[] memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].getTrack(_id);
    }

    // Get TokenURI by token id
    function tokenURI (string memory _collectionName, uint256 _id) public view returns (string memory){
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].tokenURI(_id);
    }
    // Get Token Id By TokenURI
    function gettokenIdByTokenURI(string memory _collectionName , string memory _tokenURI) public view returns (uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].gettokenIdByTokenURI(_tokenURI);
    }

    // Approve Function
    function approve(string memory _collectionName, address to, uint256 tokenId) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        nftcollectionsbyname[_collectionName].approve(to, tokenId, msg.sender);
    }

    // setApprovalForAll
    function setApprovalForAll (string memory _collectionName, address operator, bool approved) public {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        nftcollectionsbyname[_collectionName].setApprovalForAll(operator, approved, msg.sender);
    }

    // balance of function
    function balanceOf(string memory _collectionName, address owner) public view returns (uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].balanceOf(owner);
    }

    // getApproved
    function getApproved(string memory _collectionName, uint256 _id) public view returns (address) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].getApproved(_id);
    }

    // isApprovedForAll
    function isApprovedForAll(string memory _collectionName, address owner, address operator) public view returns (bool) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].isApprovedForAll(owner, operator);
    }

    // name
    function name(string memory _collectionName) public view returns(string memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].name();
    }

    // Symbol
    function symbol(string memory _collectionName) public view returns(string memory) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].symbol();
    }

    // totalSupply
    function totalSupply (string memory _collectionName) public view returns(uint256) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].totalSupply();
    }

    // external collectionnameexists
    function Ex_collectionnameexists(string memory _collectionName) view external returns (bool) {
        return collectionnameexists[_collectionName];
    }

    // external collection contract by name
    function Ex_nftcollectionsbyname(string memory _collectionName) view external returns (NFTCollection) {
        return nftcollectionsbyname[_collectionName];
    }
    
    // ownerOf function
    function ownerOf (string memory _collectionName, uint256 _id) public view returns(address) {
        require(collectionnameexists[_collectionName], "Collection Name Should be Unique! Or exist!");
        return nftcollectionsbyname[_collectionName].ownerOf(_id);
    }
}