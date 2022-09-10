// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ContentHashResolver.sol";
import "./AddrResolver.sol";
import "./TextResolver.sol";
import "./Multicallable.sol";
import "./Ownable.sol";
import "./IENS.sol";
import "./IERC721.sol";

contract HodlHQResolver is AddrResolver, Multicallable, ContentHashResolver, TextResolver, Ownable {
    // add nft with ids and make authorisation functions with isOwner of nft from id. (depends, don't have to add if there is nothing they need to change. also remove some setaddr functions etc if they either way aren't able to. remove all the isauthorized functions)
    string public ENSDomain = "tcvdhdev.eth";
    bytes32 public rootHash = 0x5cfddf95dd98637d8134ede5e6651a48070ce387f5b6e25ae8cd89e0dc58848c;
    address public NFTcontract;

    IENS public ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IERC721 public nftCard;
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;
    uint64 public defaultTTL = 0;

    mapping(uint256=>bytes32) public idHashMapping;
    mapping(bytes32=>uint256) public hashIdMapping;


    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);

    function setAuthorisation(bytes32 node, address target, bool _isAuthorised) external {
        authorisations[node][msg.sender][target] = _isAuthorised;
        emit AuthorisationChanged(node, msg.sender, target, _isAuthorised);
    }

    function isAuthorised(bytes32 node) internal view override returns(bool) {
        address owner = nftCard.ownerOf(hashIdMapping[node]);
        return owner == msg.sender || authorisations[node][owner][msg.sender];
    }

    function getSubdomainNameHash(string memory subdomain) public view returns (bytes32) {
        return keccak256(abi.encodePacked(rootHash, keccak256(abi.encodePacked(subdomain))));
    }

    // add nft id
    function createSubdomain(string calldata _subdomain, uint256 cardId) external {
        require(nftCard.ownerOf(cardId) == tx.origin);
        bytes32 subDomainHash = getSubdomainNameHash(_subdomain);

        ens.setSubnodeRecord(rootHash, keccak256(abi.encodePacked(_subdomain)), address(this), address(this), defaultTTL);
        idHashMapping[cardId] = subDomainHash;
        hashIdMapping[subDomainHash] = cardId;
        _addresses[subDomainHash][60] = addressToBytes(tx.origin);

        emit AddrChanged(subDomainHash, tx.origin);
        emit AddressChanged(subDomainHash, 60, addressToBytes(tx.origin));
    }

    // testing function, remove later
    function setaddresses(string calldata _subdomain, address user) public onlyOwner {
        bytes32 subDomainHash = getSubdomainNameHash(_subdomain);

        _addresses[subDomainHash][60] = addressToBytes(user);

        emit AddrChanged(subDomainHash, msg.sender);
        emit AddressChanged(subDomainHash, 60, addressToBytes(user));
    }

    // add id
    function swapOwnerOnTrade(address _to, uint256 _id) public {
        require(msg.sender == address(nftCard));
        bytes32 subDomainHash = idHashMapping[_id];
        _addresses[subDomainHash][60] = addressToBytes(_to);

        emit AddrChanged(subDomainHash, _to);
        emit AddressChanged(subDomainHash, 60, addressToBytes(_to));
    }

    function setNFTcontract(address newContract) public onlyOwner {
        nftCard = IERC721(newContract);
    }

    function setDefaultTTL(uint64 _defaultTTL) public onlyOwner {
        defaultTTL = _defaultTTL;
    }
    
    function supportsInterface(bytes4 interfaceID) public view override(Multicallable, AddrResolver, ContentHashResolver, TextResolver) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}