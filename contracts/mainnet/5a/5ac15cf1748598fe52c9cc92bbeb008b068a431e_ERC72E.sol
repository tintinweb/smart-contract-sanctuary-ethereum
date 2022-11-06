// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

import "./IERC721E.sol";
import "./ModernTypes.sol";

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract ERC72E is IERC721E, protected {

    // Metadata
    string public name;
    string public symbol;
    uint public totalSupply;
    string baseURI;

    // Properties
    uint next_id;

    // ID to owner
    mapping(uint => address) public ownership;
    // Owner to ID
    /*
    owned[address] -> [1,2,3,4,5...]
    index[3] -> 2
    owned[address][2] -> 3
    */ 
    mapping(address => uint[]) public owned;
    mapping(uint => uint) public index;

    // Tokenomics
    uint public price;
    mapping(address => 
            mapping(uint => 
            mapping(address => bool))) 
            public allowed;
    
    mapping(address => mapping(address => bool)) allowedAll;

    mapping(uint => address) masterAllowed;

    // Metadata

    struct METADATA {
        string name;
        string description;
        string image;
        string external_url;
        mapping(string => string) attribute;
        string[] attribute_keys;
    }

    mapping(uint => METADATA) metadata;

    constructor(string memory name_,
                string memory symbol_,
                uint totalSupply_) {

        // Setting ownership
        owner = msg.sender;
        is_auth[owner] = true;
        // Setting metadata
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_;

    }

    function setTokenMetadata(uint id, 
                              string memory _name,
                              string memory _description,
                              string memory _image,
                              string memory _external_url,
                              string[] memory _traits,
                              string[] memory _values) public onlyAuth {
        require(id < totalSupply, "id out of bounds");
        require(_traits.length == _values.length, "traits/values mismatch");
        metadata[id].name = _name;
        metadata[id].description = _description;
        metadata[id].image = _image;
        metadata[id].external_url = _external_url;
        for (uint i=0; i<_traits.length; i++) {
            metadata[id].attribute[_traits[i]] = _values[i];
            metadata[id].attribute_keys.push(_traits[i]);
        }
    }

    function getTokenMetadata(uint id) public view returns (string memory _metadata_) {
        // Ensure exists
        require(id < totalSupply, "id out of bounds");
        require(bytes(metadata[id].name).length > 0, "no metadata");
        // Start
        string memory _metadata = "{";
        _metadata = string.concat(_metadata, '"name": "');
        _metadata = string.concat(_metadata, metadata[id].name);
        _metadata = string.concat(_metadata, '", "description": "');
        _metadata = string.concat(_metadata, metadata[id].description);
        _metadata = string.concat(_metadata, '", "image": "');
        _metadata = string.concat(_metadata, metadata[id].image);
        _metadata = string.concat(_metadata, '", "external_url": "');
        _metadata = string.concat(_metadata, metadata[id].external_url);
        _metadata = string.concat(_metadata, '", "attributes": [');
        for (uint i = 0; i < metadata[id].attribute_keys.length; i++) {
            _metadata = string.concat(_metadata, '{"trait_type": "');
            _metadata = string.concat(_metadata, metadata[id].attribute_keys[i]);
            _metadata = string.concat(_metadata, '", "value": "');
            _metadata = string.concat(_metadata, metadata[id].attribute[metadata[id].attribute_keys[i]]);
            _metadata = string.concat(_metadata, '"}');
            if (i < metadata[id].attribute_keys.length - 1) {
                _metadata = string.concat(_metadata, ',');
            }
        }
        _metadata = string.concat(_metadata, ']}');
        return _metadata;
    }
    function mint(uint quantity) 
                  public safe payable 
                  returns (bool success) {
        // In bounds
        require(quantity > 0, "quantity must be > 0");
        require((next_id + quantity) <= totalSupply, "quantity must be <= totalSupply");
        require(msg.value >= price * quantity, "insufficient funds");
        if(quantity == 1) {
            _setOwnership(next_id, msg.sender);
            next_id++;
            emit Transfer(address(0), msg.sender, next_id);
            return true;
        } else {
            for (uint i = 0; i < quantity; i++) {
                _setOwnership(next_id, msg.sender);
                next_id++;
                emit Transfer(address(0), msg.sender, next_id);
            }
            return true;
        }
    }

    function transfer(address to, uint id) public safe returns (bool) {
        if (!(ownership[id]== msg.sender)) {
            revert ("Not owner");
        }
        // Give new ownership
        ownership[id] = to;
        owned[to].push(id);
        // Getting index of id from previous owner
        uint idIndex = index[id];
        // Getting index and id of the last id in the previous owner list
        uint lastIndex = owned[msg.sender].length - 1;
        uint lastId = owned[msg.sender][lastIndex];
        // Swapping the indexes
        owned[msg.sender][lastIndex] = id;
        owned[msg.sender][idIndex] = lastId;
        // Deleting last index to remove the ownership completely
        delete owned[msg.sender][lastIndex];
        // Emitting event
        emit Transfer(msg.sender, to, id);
        return true;
    }

    function tokenURI(uint id) public view returns (string memory URI) {
        require(id < totalSupply, "id out of bounds");
        return string(abi.encodePacked(baseURI, id));
    }

    function setBaseURI(string memory uri) public returns (bool success) {
        baseURI = uri;
        return true;
    }

    // Internals
    function _setOwnership(uint id, address addy) internal {
        ownership[id] = addy;
        owned[addy].push(id);
        index[id] = owned[addy].length - 1;
    }

    // Admin 
    function setPrice(uint price_) public onlyAuth {
        price = price_;
    }

    // ERC721 Compatibility

    // event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId) {
    // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId) {
    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved) {
    
    function balanceOf(address _owner) public view returns (uint256) {
        return owned[_owner].length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return ownership[_tokenId];
    }
    function safeTransferFrom(address _from, 
                              address _to, 
                              uint256 _tokenId, 
                              bytes memory data) 
                              public payable {
        // REVIEW Bypassing it basically
        delete data;
        transferFrom(_from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, 
                              address _to, 
                              uint256 _tokenId) 
                              public payable {
        // REVIEW Bypassing it basically
        transferFrom(_from, _to, _tokenId);
    }
    function transferFrom(address _from, 
                          address _to, 
                          uint256 _tokenId) 
                          public payable {
        // Check if the sender is the owner or the approved
        if (!(ownership[_tokenId]== msg.sender || 
              allowed[_from][_tokenId][msg.sender] ||
              allowedAll[_from][msg.sender])) {
            revert ("Not owner neither approved");
        }
        // Delete approval
        delete allowed[_from][_tokenId][msg.sender];
        // Give new ownership
        ownership[_tokenId] = _to;
        owned[_to].push(_tokenId);
        // Getting index of id from previous owner
        uint idIndex = index[_tokenId];
        // Getting index and id of the last id in the previous owner list
        uint lastIndex = owned[_from].length - 1;
        uint lastId = owned[_from][lastIndex];
        // Swapping the indexes
        owned[_from][lastIndex] = _tokenId;
        owned[_from][idIndex] = lastId;
        // Deleting last index to remove the ownership completely
        delete owned[_from][lastIndex];
        // Emitting event
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, 
                     uint256 _tokenId)
                     public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        masterAllowed[_tokenId] = _approved;
        // TODO Remember to reset this on transfers
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function approveOwned(address _approved, 
                     uint256 _tokenId) 
                     public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_approved] = true;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function disapproveOwned(address _disapproved, 
                        uint256 _tokenId) 
                        public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_disapproved] = false;
    }
    

    function setApprovalForAll(address _operator, 
                               bool _approved) 
                               public {
        if (_approved) {
            allowedAll[msg.sender][_operator] = true;
        } else {
            allowedAll[msg.sender][_operator] = false;
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) 
                         public view returns (address) {
        return masterAllowed[_tokenId];
    }

    function getApprovedOwned(uint256 _tokenId, 
                              address _owner,
                              address _spender)
                              public view returns (bool) {
        return allowed[_owner][_tokenId][_spender];
    }
    
    function isApprovedForAll(address _owner, 
                              address _operator) 
                              public view returns (bool) {
        return allowedAll[_owner][_operator];
    }

}