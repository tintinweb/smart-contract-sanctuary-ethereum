pragma solidity ^0.8.4;

contract DisclosureRegistry {

    struct Disclosure{
        string metadata;
        string disclaimer;
    }

    address registrar;
    uint private totalCount;
    mapping(address => uint256) private getIdGivenAddr;
    Disclosure[] private disclosures;

    constructor(){
        registrar = msg.sender;
    }

    function registerDisclosure(address _addr, string memory _metaData) public {
        require(msg.sender == registrar, "Unauthorized");
        _register(_addr, _metaData);
    }

    function _register (address _addr, string memory _metaData) internal {
        totalCount += 1;
        getIdGivenAddr[_addr] = totalCount;
        Disclosure memory disclosure = Disclosure(_metaData, "");
        disclosures.push(disclosure);
    }

    function getDisclaimer(address _addr) public view returns(string memory) {
        uint id = getIdGivenAddr[_addr];
        require(id != 0, "Does not exist");
        return disclosures[id].disclaimer;
    }

    function getMetadata(address _addr) public view returns(string memory) {
        uint id = getIdGivenAddr[_addr];
        require(id != 0, "Does not exist");
        return disclosures[id].metadata;
    }
}