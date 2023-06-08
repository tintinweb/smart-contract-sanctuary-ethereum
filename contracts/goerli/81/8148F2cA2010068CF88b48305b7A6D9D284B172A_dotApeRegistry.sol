/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// File: dotApe/implementations/addressesImplementation.sol


pragma solidity ^0.8.7;

interface IApeAddreses {
    function owner() external view returns (address);
    function getDotApeAddress(string memory _label) external view returns (address);
}

pragma solidity ^0.8.7;

abstract contract apeAddressesImpl {
    address dotApeAddresses;

    constructor(address addresses_) {
        dotApeAddresses = addresses_;
    }

    function owner() public view returns (address) {
        return IApeAddreses(dotApeAddresses).owner();
    }

    function getDotApeAddress(string memory _label) public view returns (address) {
        return IApeAddreses(dotApeAddresses).getDotApeAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == getDotApeAddress("registrar"), "Ownable: caller is not the registrar");
        _;
    }

    modifier onlyErc721() {
        require(msg.sender == getDotApeAddress("erc721"), "Ownable: caller is not erc721");
        _;
    }

}
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: dotApe/registry.sol


pragma solidity ^0.8.7;



contract dotApeRegistry is apeAddressesImpl {
    using Counters for Counters.Counter;

    constructor(address _address) apeAddressesImpl(_address) {}

    mapping(bytes32 => uint256) private hashToTokenId;
    mapping(uint256 => string) private tokenIdToName;
    mapping(uint256 => uint256) private tokenIdToExpiration;
    mapping(uint256 => address) private tokenIdToOwners;
    mapping(address => uint256) private primaryNames;
    Counters.Counter private tokenIdCounter;

    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 expiration_) public onlyRegistrar {
        hashToTokenId[_hash] = _tokenId;
        tokenIdToName[_tokenId] = _name;
        tokenIdToExpiration[_tokenId] = expiration_;
    }

    function addOwner(address address_) public onlyErc721 {
        tokenIdToOwners[nextTokenId()] = address_;
        tokenIdCounter.increment();
    }

    function changeOwner(address address_, uint256 tokenId_) public onlyErc721 {
        tokenIdToOwners[tokenId_] = address_;
    }

    function changeExpiration(uint256 tokenId, uint256 expiration_) public onlyRegistrar {
        tokenIdToExpiration[tokenId] = expiration_;
    }

    function getTokenId(bytes32 _hash) public view returns (uint256) {
        return hashToTokenId[_hash];
    }

    function getName(uint256 _tokenId) public view returns (string memory) {
        return tokenIdToName[_tokenId];        
    }

    function currentSupply() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    function nextTokenId() public view returns (uint256) {
        return tokenIdCounter.current() + 1;
    }

    function getOwner(uint256 tokenId) public view returns (address) {
        if(tokenIdToExpiration[tokenId] < block.timestamp && tokenId <= currentSupply() && tokenId != 0) { 
            return getDotApeAddress("expiredVault");
        } else {
            return tokenIdToOwners[tokenId];
        }
    }

    function getExpiration(uint256 tokenId) public view returns (uint256) {
        return tokenIdToExpiration[tokenId];
    }

    function setPrimaryName(address address_, uint256 tokenId) public onlyRegistrar {
        require(getOwner(tokenId) == address_, "Primaty Name: Not owned by address");
        primaryNames[address_] = tokenId;
    }

    function getPrimaryNameTokenId(address address_) public view returns (uint256) {
        uint256 tokenId = primaryNames[address_];
        if(getOwner(tokenId) == address_) {
            return tokenId;
        } else {
            return 0;
        }
    }

    function getPrimaryName(address address_) public view returns (string memory) {
        uint256 tokenId = getPrimaryNameTokenId(address_);
        return string(abi.encodePacked(getName(tokenId), ".ape"));
    }
 
}