// SPDX-License-Identifier: MIT
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

/*~~~>
    Thank you Phunks, your inspiration and phriendship meant the world to me and helped me through hard times.
      Never stop phighting, never surrender, always stand up for what is right and make the best of all situations towards all people.
      Phunks are phreedom phighters!
        "When the power of love overcomes the love of power the world will know peace." - Jimi Hendrix <3

        On the point of halting the trading of collections,
          We the People of web3 must moderate ourselves. 
          With any power comes great responsibility,
           and if we don't moderate ourselves from within, 
           then we will be moderated from without. 
           I will always stand against CP or any form of profiteering from child exploitation 
           and refuse to allow the trading or promotion of any material that is knowingly harmful or explicit.
           Knowing this power can be controlled as a weapon against other projects, 
            let us only refuse collections that are explicitly tied to CP or knowingly harmful activities.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected][email protected]@[email protected]@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 <~~~*/
pragma solidity  >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

interface RoleProvider {
  function hasTheRole(bytes32 role, address _address) external returns(bool);
}
contract MarketCollections {
  using Counters for Counters.Counter;
  
  //*~~~> counter increments NFT collection addresses registered to this market
  Counters.Counter private _collectionsAdded;

  //*~~~> counter increments NFT collection addresses unregistered to this market
  Counters.Counter private _collectionsRemoved;

  //*~~~> Roles for designated accessibility
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE"); 
  string Mess = "DOES NOT HAVE ADMIN ROLE";
  address public roleAdd;
  
  constructor(address _role) {
    roleAdd = _role;
  }
  modifier hasAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), Mess);
    _;
  }
  modifier hasDevAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(DEV_ROLE, msg.sender), Mess);
    _;
  }

  //*~~~> Declaring object structure for marketplace collections and state variables
  struct MarketCollection {
    bool isNotTradable;
    uint collectionId;
    string collectionName;
    address collectionContract;
  }

  struct TokenList{
    bool canOffer;
    address tokenAdd;
  }

  //*~~~> Memory array of all listed Market Collections
  mapping(uint256 => MarketCollection) private idToCollection;
  mapping(address => MarketCollection) private addressToCollection;
  mapping(address => TokenList) private addressToToken;

  //*~~~> Declaring event object structure for new collection added
  event CollectionAdded(
    uint indexed collectionId,
    string collectionName,
    address indexed collectionContract
    );

  //*~~~> Declaring event object structure for updated collection
  event CollectionUpdated(
    bool isNotTradable,
    uint indexed collectionId,
    string collectionName,
    address indexed collectionContract
  );

  function setRoleAdd(address _role) public hasAdmin returns(bool){
    roleAdd = _role;
    return true;
  }

  ///@notice
    //*~~~> Admin only function to create a new marketplace item to be halted for trading
  ///@dev
  /*~~~>
    name: name of Market collection to be halted;
    nftContract: contract address of collection to be halted;
  <~~~*/
  ///@return Bool
  function restrictMarketCollection(
    string[] calldata name,
    address[] calldata nftContract
    ) public hasAdmin returns (bool) {
    for (uint i; i<nftContract.length; i++) {
      _collectionsAdded.increment();
      uint256 collectionId = _collectionsAdded.current();
      idToCollection[collectionId] = MarketCollection(true, collectionId, name[i], nftContract[i]);
      emit CollectionAdded(collectionId, name[i], nftContract[i]);
    }
    return true;
  }
  
  /// @notice
    //*~~~> OnlyOwner function to edit a new marketplace item
  /// @dev 
    /*~~~>
      isNotTradable: (true) if collection cannot trade;
      name: Name of the collection;
      nftContract: collection contract address;
      collectionId: internal Id of the collection
      <~~~*/
  /// @return Bool
  function editMarketCollection(
    bool[] memory isNotTradable,
    string[] memory name,
    address[] memory nftContract,
    uint[] memory collectionId
    ) public hasAdmin returns (bool) {
    for (uint i; i<nftContract.length; i++) {
      idToCollection[collectionId[i]] = MarketCollection( isNotTradable[i], collectionId[i], name[i], nftContract[i]);
      emit CollectionAdded(collectionId[i], name[i], nftContract[i]);
    }
    return true;
  }

  //*~~~> sets approved tokens for offers
  function setTokenList(bool[] calldata _canOffer, address[] calldata _token) public hasDevAdmin returns (bool) {
    for (uint i; i < _token.length; i++){
      addressToToken[_token[i]] = TokenList(_canOffer[i], _token[i]);
    }
    return true;
  }

  function canOfferToken(address token) public view returns(bool){
    bool canOffer = addressToToken[token].canOffer;
    return canOffer;
  }

  /// @notice
    //*~~~> Public read functions for internal state
  function fetchCollectionItem(uint collectionId) public view returns (MarketCollection memory) {
    MarketCollection memory collection = idToCollection[collectionId];
    return collection;
  }

  // checks if the collection is restricted from trading, returns false if not
  function fetchCollection(address nftContract) public view returns (bool) {
    uint collectionCount = _collectionsAdded.current();
    if(collectionCount == 0) return false;
    MarketCollection memory collection = addressToCollection[nftContract];
    if (collection.isNotTradable){
      return true;
    } else {
      return false;
      }
  }

  function fetchCollections() public view returns (MarketCollection[] memory) {
    uint collectionCount = _collectionsAdded.current();
    uint listedCollectionCount = _collectionsAdded.current() - _collectionsRemoved.current();
    MarketCollection[] memory collections = new MarketCollection[](listedCollectionCount);
    for (uint i; i < collectionCount; i++) {
      if (idToCollection[i + 1].isNotTradable == true) {
        MarketCollection storage currentItem = idToCollection[i + 1];
        collections[i] = currentItem;
      }
    }
    return collections;
  }

  function fecthCollectionCount() public view returns(uint count){
    return _collectionsAdded.current();
  }

  ///@notice
  /*~~~> External ETH transfer forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address _from, address _to);
  receive() external payable {
    payable(roleAdd).transfer(msg.value);
      emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }
}