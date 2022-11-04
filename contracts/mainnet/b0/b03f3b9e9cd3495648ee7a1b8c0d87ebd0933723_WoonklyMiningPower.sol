// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./RoyaltiesV2ImplUnique.sol";
import "./RoyaltiesV2UpgradeableUpdated.sol"; 

contract WoonklyMiningPower is Initializable,  RoyaltiesV2ImplUnique, RoyaltiesV2Upgradeable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
      
    mapping(uint256 => TokenType) private _tokenTypes;
    mapping(address => bool) private _allowedProxies;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint256 private _maxSupply;
    uint256 private _totalMinted; 
    address private _transferProxy;

    //example
    //0 -> legendary
    //1 -> epic
    //2 -> mythical
    struct TokenType{
        string uri;
        bool mintingEnabled;
        uint256 minted;
        uint256 burned;
    }

    event SetAllowedProxy(address indexed proxy, bool status);
    event SetMaxSupply(uint256 maxSupply);
    event SetMintingEnabled(uint256 indexed tokenId,bool mintingEnabled);
    event SetName(string name);
    event SetSymbol(string symbol);
    event SetTransferProxy(address indexed transferProxy); 
    event SetURI(uint256 indexed tokenId,string uri);

    /// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}

    function initialize(string memory _newName, string memory _newSymbol, uint256 _newSupply, uint256[] memory _tokenIds, string[] memory _uris, LibPart.Part[] memory _newRoyalties) initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        //__RoyaltiesV2Upgradeable_init_unchained()

        _name = _newName;
        _symbol = _newSymbol;
        _maxSupply = _newSupply;

        emit SetName(_newName);
        emit SetSymbol(_newSymbol);
        emit SetMaxSupply(_newSupply);
        
        for(uint256 i;i<_tokenIds.length;++i)
        {
           _tokenTypes[_tokenIds[i]].mintingEnabled = true;
           _tokenTypes[_tokenIds[i]].uri = _uris[i];

           emit SetMintingEnabled(_tokenIds[i],true);
           emit SetURI(_tokenIds[i],_uris[i]);
        }


        if (_newRoyalties.length > 0) {
            _saveRoyalties(_newRoyalties);
        }
       
    }

     function allowedProxies(address _proxy) public view returns (bool) {
        return _allowedProxies[_proxy];
    }  

     function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    
    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function transferProxy() public view returns (address) {
        return _transferProxy;
    } 


    function tokenTypes(uint _tokenId) public view returns(
        string memory uri,
        bool mintingEnabled,
        uint256 minted,
        uint256 burned){
            TokenType storage tokenType = _tokenTypes[_tokenId];
            return (tokenType.uri,tokenType.mintingEnabled,tokenType.minted,tokenType.burned);
        }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return _tokenTypes[_tokenId].uri;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function setAllowedProxy(address _proxy, bool _allowed) public onlyOwner {
        require(_proxy != address(0x00),"zero address not allowed");
        _allowedProxies[_proxy] = _allowed;
        emit SetAllowedProxy(_proxy, _allowed);
    }


    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_totalMinted <= _newMaxSupply,"new supply need to be equal or greater than existent minted token amount");
        _maxSupply = _newMaxSupply;
        emit SetMaxSupply(_newMaxSupply);
    }


    function setMintingEnabled(uint256 _tokenId, bool _mintingEnabled) public onlyOwner {
        require(_mintingEnabled != _tokenTypes[_tokenId].mintingEnabled, " new status is the same");
        _tokenTypes[_tokenId].mintingEnabled = _mintingEnabled;
        emit SetMintingEnabled(_tokenId,_mintingEnabled);
    }

    function setName(string memory _newName) public onlyOwner {
          require(bytes(_newName).length > 0,"new name length should be larger than zero");
          _name = _newName;
          emit SetName(_newName);
    }

    function setRoyalties(LibPart.Part[] memory _newRoyalties) public onlyOwner {
       _saveRoyalties(_newRoyalties);
    } 

    function setSymbol(string memory _newSymbol) public onlyOwner {
        require(bytes(_newSymbol).length > 0,"new symbol length should be larger than zero");
        _symbol = _newSymbol;
        emit SetSymbol(_newSymbol);
    }
 

    function setTransferProxy(address _newTransferProxy) public onlyOwner {
        require(_newTransferProxy != _transferProxy, "same _transferProxy");
        _transferProxy = _newTransferProxy;
        emit SetTransferProxy(_newTransferProxy);
    } 

     function setURI(uint256 _tokenId, string memory _newuri) public onlyOwner {
        require(bytes(_newuri).length > 0,"new uri length should be larger than zero");
        _tokenTypes[_tokenId].uri = _newuri;
        emit SetURI(_tokenId,_newuri);
    }


    modifier isValidParty() {
        _isValidParty();
        _;
    }

    function _isValidParty() internal view virtual {
        require(owner() == _msgSender() || _allowedProxies[_msgSender()] == true,"Caller is not owner or a valid proxy");
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        isValidParty
    {
        require(_tokenTypes[id].mintingEnabled == true, "minting is not allowed for this token id");
        uint256 newMinted = _totalMinted + amount;

        require(newMinted <= _maxSupply, "supply has run out");

        _mint(account, id, amount, data);

        _tokenTypes[id].minted += amount;
        _totalMinted = newMinted;
        
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        isValidParty
    {
        uint256 newMinted = _totalMinted;
        uint256 tokenId;
        for(uint256 i;i<ids.length;++i)
        {
            tokenId = ids[i];
            require(_tokenTypes[tokenId].mintingEnabled == true, "minting is not allowed for this token id");
            newMinted+=amounts[i];
            _tokenTypes[tokenId].minted += amounts[i];
        }

        require(newMinted <= _maxSupply, "supply has run out");

        _mintBatch(to, ids, amounts, data);

         _totalMinted = newMinted;
    }

        function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

      function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override  {

        super.burn(account, id, value);

        _tokenTypes[id].burned+=value;
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {


        super.burnBatch(account, ids, values);

        for(uint256 i;i<ids.length;++i)
        {
            _tokenTypes[ids[i]].burned+=values[i];
        }
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return (operator == _transferProxy || super.isApprovedForAll(owner, operator));
    }

    function supportsInterface(bytes4 interfaceId) public view override (RoyaltiesV2Upgradeable, ERC1155Upgradeable) returns (bool) {
        return
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
            || ERC1155Upgradeable.supportsInterface(interfaceId);
    }

 


}