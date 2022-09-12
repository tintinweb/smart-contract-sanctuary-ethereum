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
        _initializeArrays();
        registrar = msg.sender;
    }

    function registerDisclosure(address _addr, string memory _metaData) public {
        require(getIdGivenAddr[_addr] == 0, "already registered");
        require(msg.sender == registrar, "Unauthorized");
        _register(_addr, _metaData);
    }

    function _register (address _addr, string memory _metaData) internal {
        totalCount += 1;
        getIdGivenAddr[_addr] = totalCount;
        Disclosure memory disclosure = Disclosure(_metaData, "");
        disclosures.push(disclosure);
    }

    function updateDisclaimer(address _addr, string memory _disclaimer) public {
        uint id = getIdGivenAddr[_addr];
        require(id != 0, "Does not exist");
        disclosures[id].disclaimer = _disclaimer;
    }

    function updateMetadata(address _addr, string memory _metadata) public {
        uint id = getIdGivenAddr[_addr];
        require(id != 0, "Does not exist");
        disclosures[id].metadata = _metadata;
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

    function getTotalCount() public view returns(uint256) {
        return totalCount;
    }

    function _initializeArrays() private {
        Disclosure memory disclosure = Disclosure("","");
        disclosures.push(disclosure);
    }

}