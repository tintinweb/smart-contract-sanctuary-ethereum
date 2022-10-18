/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0
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

// File: contracts/mysbt.sol



pragma solidity >=0.8.0;


contract experimentalSBT {
    using Counters for Counters.Counter;

    string public name;
    string public symbol;
    string public baseUrl;
    address public admin;
    
    Counters.Counter public totalSupply;
    Counters.Counter private tokenIdCounter;
    
    //maping of owners to DID
    //mapping(address => DID) private DIDs;
    // Mapping from owner to token ID address
    mapping(address => uint256) private exists;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;
    // Mapping from token ID to tokenURL
    mapping(uint256 => string) private tokenURIs;
    // Mapping owner address to token count
    mapping(address => uint256) private balances;
    //mapping of issuers
    mapping(address => bool) private issuer;

    //List of events to be emitted
    event Attest(address indexed from, address indexed to, uint256 indexed _tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed _tokenId);
    

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        admin = msg.sender;
        tokenIdCounter.increment();
        balances[address(0)] = totalSupply.current();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    function setIssuer(address _issuer) public onlyAdmin {
        issuer[_issuer] = true;
    }

    function removeIssuer(address _issuer) public onlyAdmin {
        issuer[_issuer] = false;
    }

    function isIssuer(address _issuer) public view returns (bool){
        return issuer[_issuer];
    }

    function revoke(address _address) public {
        require(msg.sender == _address || msg.sender == admin);
        uint256 _tokenid = exists[_address];
        delete exists[_address];
        delete owners[_tokenid];
        balances[_address] = 0;
        totalSupply.decrement();

    }

    function attest(address _address, string memory _tokenURI) external {
        require(exists[_address] == 0, "Already own token!");
        require(issuer[msg.sender] == true || msg.sender == admin);
        
        /* DID memory newDID = DID(_tokenURI, _timestamp);
        DIDs[_address] = newDID; */
        uint256 tokenID = tokenIdCounter.current();
        tokenURIs[tokenID] = _tokenURI;
        exists[_address] = tokenID;
        owners[tokenID] = _address;
        balances[_address] = 1;
        tokenIdCounter.increment();
        totalSupply.increment();
        
        emit Attest(address(0), _address, tokenID);
        emit Transfer(address(0), _address, tokenID);

    }

    function ownerOf(uint256 _tokenId) public view returns(address) {
        return owners[_tokenId];
    }

    function tokenIdOf(address _address) public view returns(uint256) {
        return exists[_address];
    }

    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        return tokenURIs[_tokenId];
    }   

    function balanceOf(address _address) public view returns(uint256) {
        return balances[_address];
    }

    /* function getDID(address _address) public view returns(DID memory) {
        return DIDs[_address];
    } */

}