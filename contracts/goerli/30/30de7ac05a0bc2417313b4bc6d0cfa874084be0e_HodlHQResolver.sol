// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
   * @title Lock
   * @dev ContractDescription
   * @custom:dev-run-script ./scripts/deploy.js
*/
import "./ContentHashResolver.sol";
import "./AddrResolver.sol";
import "./TextResolver.sol";
import "./Multicallable.sol";
import "./Ownable.sol";
import "./IENS.sol";

contract HodlHQResolver is AddrResolver, Multicallable, ContentHashResolver, TextResolver, Ownable {
    string public ENSDomain = "HODLHQ.eth";
    bytes32 public rootHash = 0xda88a20378b9622fcc70b0ce03b53b3205c76e28c9863cff08b7bb9acb2f7f80;

    IENS public ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;
    uint64 public defaultTTL = 0;

    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);

    function setAuthorisation(bytes32 node, address target, bool _isAuthorised) external {
        authorisations[node][msg.sender][target] = _isAuthorised;
        emit AuthorisationChanged(node, msg.sender, target, _isAuthorised);
    }

    function isAuthorised(bytes32 node) internal view override returns(bool) {
        address owner = ens.owner(node);
        return owner == msg.sender || authorisations[node][owner][msg.sender];
    }

    function getSubdomainNameHash(string memory subdomain) public view returns (bytes32) {
        return keccak256(abi.encodePacked(rootHash, keccak256(abi.encodePacked(subdomain))));
    }

    function createSubdomain(string calldata _subdomain) public {
        ens.setSubnodeRecord(rootHash, keccak256(abi.encodePacked(_subdomain)), address(this), address(this), defaultTTL);
        setAddr(getSubdomainNameHash(_subdomain), 60, addressToBytes(msg.sender));
    }

    function setDefaultTTL(uint64 _defaultTTL) public onlyOwner {
        defaultTTL = _defaultTTL;
    }
    
    function supportsInterface(bytes4 interfaceID) public view override(Multicallable, AddrResolver, ContentHashResolver, TextResolver) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}