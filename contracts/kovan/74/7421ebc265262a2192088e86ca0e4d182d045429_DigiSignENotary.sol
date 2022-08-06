/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

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

// File: contracts/Notery.sol


pragma solidity ^0.8.9;


contract DigiSignENotary {

    using Counters for Counters.Counter;
    Counters.Counter private _notaryIds;

    address public owner;

    struct Notary {
        string uri;
        address arbitraror;
        address first_party;
        address second_party;
        bool isSigned_by_first_party;
        bool isSigned_by_second_party;
        bytes first_party_signature;
        bytes second_party_signature;
        uint256 createdAt;
        uint256 first_party_sign_timestamp;
        uint256 second_party_sign_timestamp;
        bool isExpired;
    }

    mapping(uint256 => Notary) public notaries;
    mapping(address => bool) public arbitrarors;
    mapping(address => uint256[]) public userToNotaryIds;


    event NotrayStored(string uri, address arbitraror, address first_party, address second_party);

    constructor() {
        arbitrarors[msg.sender]=true;
        owner = msg.sender;
    }

    function putNotaryOnChain(string memory _uri,address _first_part,address _second_party) external{
           require(_first_part!=address(0) && _second_party!=address(0),"Address cannot be zero");
           require(arbitrarors[msg.sender],"Caller is not certified arbitraror");
            _notaryIds.increment();
            uint256 newNotaryID = _notaryIds.current();
            notaries[newNotaryID] = Notary(_uri , msg.sender,_first_part,_second_party,false,false,"","",block.timestamp,0,0,false);
            userToNotaryIds[_first_part].push(newNotaryID);
            userToNotaryIds[_second_party].push(newNotaryID);
            userToNotaryIds[msg.sender].push(newNotaryID);
            emit NotrayStored(_uri,msg.sender,_first_part,_second_party);
    }

    function signAndUpdateNotary(uint256 _notaryId,bytes memory signature) external {
        Notary storage notary = notaries[_notaryId];
        require(msg.sender==notary.first_party || msg.sender==notary.second_party,"You are not authorized to sign this Notary");
        address firstSigner = address(0);
        address secondSigner = address(0);
        msg.sender == notary.first_party?firstSigner = notary.first_party:secondSigner = notary.second_party;
        if(firstSigner!=address(0)){
        notary.first_party_signature =signature;
        notary.isSigned_by_first_party=true;
        notary.first_party_sign_timestamp=block.timestamp;
        } else {
        notary.second_party_signature =signature;
        notary.isSigned_by_second_party=true;
        notary.second_party_sign_timestamp=block.timestamp;
    }
}

function addArbitrator(address _arbitrator) external onlyOwner {
     arbitrarors[_arbitrator] = true;
}

modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getUserIds(address _userAddress) external view returns (uint[] memory){
        return userToNotaryIds[_userAddress];
    }
}