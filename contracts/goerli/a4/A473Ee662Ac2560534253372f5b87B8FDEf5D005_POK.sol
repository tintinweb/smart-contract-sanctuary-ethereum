/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.17;

contract POK {
  /* Events */
  event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);
  event AdminTransfer(uint256 indexed institutionId, address oldAdmin, address newAdmin);
  event BankTransfer(uint256 indexed institutionId, address oldBank, address newBank);

  event NewInstitution(uint256 institutionId, string name);
  event NewKnowledge(uint256 knowledgeId, string category, string title);
  event NewCollection(
    uint256 collectionId,
    uint256 indexed institutionId,
    uint256 indexed knowledgeId
  );

  event Mint(
    address indexed owner,
    uint256 indexed institutionId,
    uint256 indexed collectionId,
    uint256 tokenId
  );

  event FeePaid(
    address indexed from,
    address indexed to,
    uint256 collectionId,
    uint256 tokenId,
    uint256 fee
  );

  string public baseUri;
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  /* Structs */
  struct Institution {
    string name;
    address admin;
    address bank;
    uint256 fee;
    string uri;
  }

  struct Knowledge {
    string category;
    string title;
  }

  struct Collection {
    uint256 institutionId;
    uint256 knowledgeId;
  }

  /* State */
  Institution[] public institutions;
  Knowledge[] public knowledges;
  Collection[] public collections;

  // @dev: tracks whitelisted addresses for a given collection
  mapping(uint256 => mapping(address => bool)) public whitelist;

  // @dev: tracks owners of a given collection
  mapping(uint256 => address[]) public owners;

  // @dev: tracks how many institutions an address is the admin of
  mapping(address => uint256) public adminInstitutionCount;

  // @dev: tracks how many collections have been issued by an institution
  mapping(uint256 => uint256) public institutionCollectionCount;

  // @dev: tracks how many collections have a given knowledgeId
  mapping(uint256 => uint256) public knowledgeCollectionCount;

  /* Modifiers */
  modifier onlyOwner() {
    require(msg.sender == owner, "POK: only owner");
    _;
  }

  modifier onlyAdmin(uint256 _institutionId) {
    require(
      institutions[_institutionId].admin == msg.sender,
      "POK: must be admin of institution"
    );
    _;
  }

  modifier onlyCollectionAdmin(uint256 _collectionId) {
    require(
      institutions[collections[_collectionId].institutionId].admin == msg.sender,
      "POK: must be admin of collection"
    );
    _;
  }

  /* Functions */
  function createInstitution(string memory _name) external returns (uint256 institutionId) {
    institutions.push(Institution(_name, msg.sender, msg.sender, 0, ""));
    institutionId = institutions.length - 1;
    adminInstitutionCount[msg.sender]++;
    emit NewInstitution(institutionId, _name);
  }

  function createKnowledge(string memory _category, string memory _title)
    external
    returns (uint256 knowledgeId)
  {
    knowledges.push(Knowledge(_category, _title));
    knowledgeId = knowledges.length - 1;
    emit NewKnowledge(knowledgeId, _category, _title);
  }

  function createCollection(
    uint256 _institutionId,
    uint256 _knowledgeId,
    address[] memory _whitelist
  ) external onlyAdmin(_institutionId) returns (uint256 collectionId) {
    require(knowledges.length > _knowledgeId, "POK: knowledge id does not exist");

    collections.push(Collection(_institutionId, _knowledgeId));
    collectionId = collections.length - 1;

    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelist[collectionId][_whitelist[i]] = true;
    }

    institutionCollectionCount[_institutionId]++;
    knowledgeCollectionCount[_knowledgeId]++;

    emit NewCollection(collectionId, _institutionId, _knowledgeId);
  }

  function mint(uint256 _collectionId) external payable returns (uint256 tokenId) {
    require(collections.length > _collectionId, "POK: collection id does not exist");
    require(whitelist[_collectionId][msg.sender], "POK: only whitelisted addresses can mint");

    owners[_collectionId].push(msg.sender);
    tokenId = owners[_collectionId].length - 1;

    // transfer fee to bank
    address bank = institutions[collections[_collectionId].institutionId].bank;
    uint256 fee = institutions[collections[_collectionId].institutionId].fee;

    if (fee > 0) {
      require(msg.value >= fee, "POK: insufficient fee");
      payable(bank).transfer(fee);
      emit FeePaid(msg.sender, bank, _collectionId, tokenId, fee);
    }

    emit Mint(msg.sender, collections[_collectionId].institutionId, _collectionId, tokenId);
  }

  function mintFor(uint256 _collectionId, address[] memory _addresses)
    external
    onlyCollectionAdmin(_collectionId)
    returns (uint256[] memory tokenIds)
  {
    require(collections.length > _collectionId, "POK: collection id does not exist");
    require(
      msg.sender == institutions[collections[_collectionId].institutionId].admin,
      "POK: only collection admin can mint for others"
    );

    tokenIds = new uint256[](_addresses.length);
    for (uint256 i = 0; i < _addresses.length; i++) {
      // todo: check if address already has a token
      owners[_collectionId].push(_addresses[i]);
      uint256 tokenId = owners[_collectionId].length - 1;
      tokenIds[i] = tokenId;

      emit Mint(
        _addresses[i],
        collections[_collectionId].institutionId,
        _collectionId,
        tokenId
      );
    }
  }

  function addToWhitelist(uint256 _collectionId, address[] memory _addresses)
    external
    onlyCollectionAdmin(_collectionId)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_collectionId][_addresses[i]] = true;
    }
  }

  function removeFromWhitelist(uint256 _collectionId, address[] memory _addresses)
    external
    onlyCollectionAdmin(_collectionId)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_collectionId][_addresses[i]] = false;
    }
  }

  // Governance functions
  function setInstitutionName(uint256 _institutionId, string memory _name)
    external
    onlyAdmin(_institutionId)
  {
    institutions[_institutionId].name = _name;
  }

  function setInstitutionFee(uint256 _institutionId, uint256 _fee)
    external
    onlyAdmin(_institutionId)
  {
    institutions[_institutionId].fee = _fee;
  }

  function setInstitutionUri(uint256 _institutionId, string memory _uri)
    external
    onlyAdmin(_institutionId)
  {
    institutions[_institutionId].uri = _uri;
  }

  function transferBank(uint256 _institutionId, address _newBank)
    external
    onlyAdmin(_institutionId)
  {
    require(_newBank != address(0), "POK: cannot set bank to zero address");
    address oldBank = institutions[_institutionId].bank;
    institutions[_institutionId].bank = _newBank;

    emit BankTransfer(_institutionId, oldBank, _newBank);
  }

  function transferAdmin(uint256 _institutionId, address _newAdmin)
    external
    onlyAdmin(_institutionId)
  {
    require(_newAdmin != address(0), "POK: cannot set admin to zero address");

    address oldAdmin = institutions[_institutionId].admin;
    institutions[_institutionId].admin = _newAdmin;

    adminInstitutionCount[_newAdmin]++;
    adminInstitutionCount[msg.sender]--;

    emit AdminTransfer(_institutionId, oldAdmin, _newAdmin);
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "POK: cannot set owner to zero address");
    address oldOwner = owner;
    owner = _newOwner;

    emit OwnershipTransfer(oldOwner, _newOwner);
  }

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function getBaseUri() external view returns (string memory) {
    return baseUri;
  }

  function getUri(uint256 _collectionId) external view returns (string memory) {
    require(collections.length > _collectionId, "POK: collection id does not exist");

    string memory uri = institutions[collections[_collectionId].institutionId].uri;
    if (bytes(uri).length == 0) {
      uri = baseUri;
    }

    // concatanate collection id to uri
    return string(abi.encodePacked(uri, "/", _collectionId));
  }

  function _isEmptyString(string memory _string) internal pure returns (bool) {
    bytes memory tempString = bytes(_string); // Uses memory
    return tempString.length == 0;
  }

  /* Views */

  function getInstitution(uint256 _institutionId) external view returns (Institution memory) {
    return institutions[_institutionId];
  }

  function getKnowledge(uint256 _knowledgeId) external view returns (Knowledge memory) {
    return knowledges[_knowledgeId];
  }

  function getCollection(uint256 _collectionId) external view returns (Collection memory) {
    return collections[_collectionId];
  }

  function getOwner(uint256 _collectionId, uint256 _tokenId) external view returns (address) {
    return owners[_collectionId][_tokenId];
  }

  function getOwners(uint256 _collectionId) external view returns (address[] memory) {
    return owners[_collectionId];
  }

  function getWhitelist(uint256 _collectionId) external view returns (address[] memory) {
    address[] memory _whitelist = new address[](owners[_collectionId].length);

    for (uint256 i = 0; i < owners[_collectionId].length; i++) {
      if (whitelist[_collectionId][owners[_collectionId][i]]) {
        _whitelist[i] = owners[_collectionId][i];
      }
    }

    return _whitelist;
  }

  function getAllInstitutions() external view returns (Institution[] memory) {
    return institutions;
  }

  function getAllKnowledges() external view returns (Knowledge[] memory) {
    return knowledges;
  }

  function getAllCollections() external view returns (Collection[] memory) {
    return collections;
  }

  function getInstitutionsByAdmin(address _admin)
    external
    view
    returns (Institution[] memory)
  {
    Institution[] memory _institutions = new Institution[](adminInstitutionCount[_admin]);

    uint256 _index = 0;
    for (uint256 i = 0; i < institutions.length; i++) {
      if (institutions[i].admin == _admin) {
        _institutions[_index] = institutions[i];
        _index++;
      }
    }

    return _institutions;
  }

  function getCollectionsByInstitution(uint256 _institutionId)
    external
    view
    returns (Collection[] memory)
  {
    Collection[] memory _collections = new Collection[](
      institutionCollectionCount[_institutionId]
    );

    uint256 _index = 0;
    for (uint256 i = 0; i < collections.length; i++) {
      if (collections[i].institutionId == _institutionId) {
        _collections[_index] = collections[i];
        _index++;
      }
    }

    return _collections;
  }

  function getCollectionsByKnowledge(uint256 _knowledgeId)
    external
    view
    returns (Collection[] memory)
  {
    Collection[] memory _collections = new Collection[](
      knowledgeCollectionCount[_knowledgeId]
    );

    uint256 _index = 0;
    for (uint256 i = 0; i < collections.length; i++) {
      if (collections[i].knowledgeId == _knowledgeId) {
        _collections[_index] = collections[i];
        _index++;
      }
    }

    return _collections;
  }

  // todo: get knowledges by institution (?)
  // todo: get all owners of a knowledge (?)
  // todo: get uri of a collection or token id
}

// get all institutions
// get all collections
// get all knowledges
// get institutions owned by address
// get collections owned by institution
// get all collections from a given knowledge

// get all holders from a given collection
// get whitelist for a given collection
// get information for a given collection (knowledgeId, settingId)
// get information for a given knowledge (category, title)