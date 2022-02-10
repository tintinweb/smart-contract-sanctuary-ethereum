/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity 0.8.11;

contract Ownable {
  address public owner;

  event OwnerTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
  {
    owner = msg.sender;
  }

  modifier onlyOwner()
  {
    require(msg.sender == owner,"");
    _;
  }

  function transferOwner(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0),"");
    emit OwnerTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
contract AliasRegistryV2 is Ownable {

  struct Identity
  {
    uint index;
    bytes32 store;
    bool active;
    bytes32[] aliases;
    mapping(bytes32 => uint) aliasIndex;
  }

  mapping(address => Identity) private identities;
  address[] private identityList;

  struct Aliases
  {
    uint index;
    address identityAddress;
    uint createdAt;
    uint updatedAt;
    bool burner;
    uint expiry;
    bool nonce;
    bool active;
  }

  mapping(bytes32 => Aliases) public aliases;
  bytes32[] private aliasList;

  event LogNewIdentity(
    address sender,
    address identityAddress
  );

  event LogNewAlias(
    address sender,
    bytes32 _alias,
    address identityAddress,
    uint createdAt,
    uint updatedAt,
    bool burner,
    uint expiry,
    bool nonce,
    bool active
  );

  event LogAliasUpdated(
    address sender,
    bytes32 _alias,
    uint updatedAt
  );

  event LogAliasBurned(
    address sender,
    bytes32 _alias,
    uint updatedAt
  );
  

  function getIdentityCount()
    public
    view
  returns(uint identityCount)
  {
    return identityList.length;
  }

  function getAliasCount()
    public
    view
  returns(uint aliasCount)
  {
    return aliasList.length;
  }

  function isIdentity(
    address identityAddress
  )
    public
    view
  returns(bool success)
  {
    if (identityList.length == 0) return false;
    return identityList[identities[identityAddress].index] == identityAddress;
  }

  function isAlias(
    bytes32 _alias
  )
    public
    view
  returns(bool success)
  {
    if (aliasList.length == 0) return false;
    return aliasList[aliases[_alias].index] == _alias;
  }

  function getAliasesByIdentitiesCount(
    address identityAddress
  )
    public
    view
  returns(uint aliasCount)
  {
    require(isIdentity(identityAddress), "Identity not registered");

    return identities[identityAddress].aliases.length;
  }

  function getIdentityAliasAtIndex(
    address identityAddress,
    uint index
  )
    public
    view
  returns(bytes32 _alias)
  {
    require(isIdentity(identityAddress), "Identity not registered");
    return (identities[identityAddress].aliases[index]);
  }

  function setIdentity(
    address identityAddress,
    bytes32 store,
    bool active
  )
    public
    onlyOwner
  returns(bool success)
  {
    require(!isIdentity(identityAddress), "Identity already registered");

    identityList.push(identityAddress);
    identities[identityAddress].index = identityList.length - 1;
    identities[identityAddress].store = store;
    identities[identityAddress].active = active;

    emit LogNewIdentity(msg.sender, identityAddress);
  
    return true;
  }

  function setIdentityStore(
    address identityAddress,
    bytes32 store
  )
    public
    onlyOwner
  {
    identities[identityAddress].store = store;
  }

  function setIdentityActive(
    address identityAddress,
    bool active
  )
    public
    onlyOwner
  {
    identities[identityAddress].active = active;
  }

  function getIdentity(
    address identityAddress
  )
    external
    view
    returns(bytes32, bytes32[] memory, bool)
  {
    return (
      identities[identityAddress].store,
      identities[identityAddress].aliases,
      identities[identityAddress].active);
  }
  
  function setAlias(
    bytes32 _alias,
    address identityAddress,
    bool burner,
    uint expiry,
    bool nonce
  )
    public
    onlyOwner
  returns(bool success)
  {
    require(isIdentity(identityAddress), "Identity not registered");
    require(!isAlias(_alias), "Alias already exists");
  
    uint timestamp = block.timestamp;
    aliasList.push(_alias); 
    aliases[_alias].index = aliasList.length - 1;
    aliases[_alias].identityAddress = identityAddress;
    aliases[_alias].createdAt = timestamp;
    aliases[_alias].updatedAt = timestamp;
    aliases[_alias].burner = burner;
    aliases[_alias].expiry = expiry;
    aliases[_alias].nonce = nonce;
    aliases[_alias].active = true;

    identities[identityAddress].aliases.push(_alias);
    identities[identityAddress].aliasIndex[_alias] = identities[identityAddress].aliases.length - 1;

    emit LogNewAlias(
      msg.sender,
      _alias,
      identityAddress,
      timestamp,
      timestamp,
      burner,
      expiry,
      nonce,
      true
    );

    return true;
  }


// function to delete _alias from aliasList and aliasIndex then shift array
  function deleteAlias(
    bytes32 _alias
  )
    public
    onlyOwner
  {
     require(isAlias(_alias), "Alias not registered");

    uint index = aliases[_alias].index;

    address identityAddress = aliases[_alias].identityAddress;
    //uint identityIndex = identities[aliases[_alias].identityAddress].index;
    uint identityAliasIndex = identities[identityAddress].aliasIndex[_alias];
 
    aliases[_alias].active = false;
    bytes32 _resortedAlias = identities[identityAddress].aliases[identities[identityAddress].aliases.length - 1];
    
    delete identities[identityAddress].aliasIndex[_alias];

    identities[identityAddress].aliases[identityAliasIndex] = _resortedAlias;
    identities[identityAddress].aliasIndex[_resortedAlias] = identityAliasIndex;
    identities[identityAddress].aliases.pop();
   
    delete aliases[_alias];
    aliasList[index] = aliasList[aliasList.length - 1];
    aliasList.pop();

    aliases[aliasList[index]].index = index;
    emit LogAliasBurned(msg.sender, _alias, block.timestamp);
  }

  function setAliasActive(
    bytes32 _alias,
    bool active
  )
    public
    onlyOwner
  returns(bool success)
  {
    require(isAlias(_alias), "Alias not found");

    uint timestamp = block.timestamp;

    aliases[_alias].active = active;

    aliases[_alias].updatedAt = timestamp;

    emit LogAliasUpdated(msg.sender, _alias, timestamp);

    return true;
  }

  function setIdentityAliasAtIndex(
    address identityAddress,
    uint index,
    bool active
  )
    public
    onlyOwner
  returns(bool success)
  {
    require(isIdentity(identityAddress), "Identity not registered");

    uint timestamp = block.timestamp;

    bytes32 _alias = identities[identityAddress].aliases[index];

    if(aliases[_alias].burner) {
      if(aliases[_alias].nonce == true || aliases[_alias].expiry < timestamp) {
        aliases[_alias].active = false;
      }
    } else {
      aliases[_alias].active = active;
    }

    aliases[_alias].updatedAt = timestamp;

    emit LogAliasUpdated(msg.sender, _alias, timestamp);

    return true;
  }

}