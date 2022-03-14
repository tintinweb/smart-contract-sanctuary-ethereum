// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "./ERC721A.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";


contract SB_721A is Ownable, ERC721A, ReentrancyGuard {
  
  using Strings for uint256;

  string public PROVENANCE;

  uint256 public constant MAX_SUPPLY=10000;
  uint256 public constant MAX_BATCH_SIZE=1000;
  
  uint256 public limit_total_supply = 20; // 9000
  uint256 public price_per_token = 0.01 ether; //0.01, 0.015, 0.03
  bool public paused = true;
  
  bool public isTotalSupplyLimitActive = true; // initial is true
  bool public isWhiteListActiveList1 = true; // initial set to true, instead of false, to avoid Public mint
  bool public isWhiteListActiveNoLimit = false;
  bool public isFreeMintActive = false;

  uint256 public max_whitelist_mint_list1 =2;

  mapping (address => bool) public whitelistedAddressList1;
  mapping (address => uint256) public _whitelist_mint_max_list1;

  mapping (address => bool) public whitelistedAddressNoLimit;

  string public baseExtension = ".json";

  string baseURI; // not used actually
  // string private _baseURIextended;
  string public notRevealedUri;
  address public owner_address;
  address public admin_address;
  address public sysadm_address;
  bool public revealed = false;

  
  


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address ownerAddress,
    address adminAddress,
    address sysadmAddress
  ) ERC721A(_name, _symbol, MAX_BATCH_SIZE, MAX_SUPPLY) {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    owner_address = ownerAddress;
    admin_address = adminAddress;
    sysadm_address = sysadmAddress;

  }


  function setProvenance(string memory provenance) public {
    // function setProvenance(string memory provenance) public onlyOwner {
        require(msg.sender == owner_address,"Not Owner");
        PROVENANCE = provenance;
    }

    

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {    
        notRevealedUri = _notRevealedURI;
    }

    function setNotRevealedURIExternal(string memory _notRevealedURI) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        notRevealedUri = _notRevealedURI;
    }


    function reveal() public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        revealed = true;
    }

    function changeAdmin(address newAdminAddress) external {
        require(msg.sender==owner_address|| msg.sender == sysadm_address, "notOwnerNorSysadm");
        admin_address = newAdminAddress;
    }


    function setMaxWhiteListMintList1(uint16 _max_whitelist_mint) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        max_whitelist_mint_list1 = _max_whitelist_mint;

        emit SetWhiteListMintMaxGeneralList1(max_whitelist_mint_list1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }


  function setNewCost(uint256 _newCost) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        price_per_token = _newCost;
    }

  function setBaseExtension(string memory _newBaseExtension) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        baseExtension = _newBaseExtension;
    }


  

  event WhitelistedList1(address indexed account, bool isWhitelisted);
  event WhitelistedNoLimit(address indexed account, bool isWhitelisted);
  
  event RemoveWhitelistedList1(address indexed account, bool isWhitelisted);
  event RemoveWhitelistedNoLimit(address indexed account, bool isWhitelisted);
  
  
  event MintedTokenId(address indexed _address, uint256 _price_per_token);
  event Minted(address indexed _address, uint256 quantity);
  
  event WhiteListMintedTokenIdList1(address indexed _address, uint256 _price_per_token);
  event WhiteListMintedTokenIdNoLimit(address indexed _address, uint256 _price_per_token);

  event WhiteListMintedList1(address indexed _address, uint256 quantity);
  event WhiteListMintedNoLimit(address indexed _address, uint256 quantity);
  
  event SetWhiteListMintMaxGeneralList1(uint256 WhiteListMintMax);

  function pause(bool _state) public nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        paused = _state;
    }


  function mint(uint256 numberOfTokens) external payable callerIsUser {
    
        uint256 ts = totalSupply();
        
        require(!paused, "Contract paused");
        // require( numberMinted(msg.sender) + numberOfTokens <= maxPerAddressDuringMint, "cannot mint this many");
        
        // default is activated
        if (isTotalSupplyLimitActive) {
            require(ts + numberOfTokens <= limit_total_supply, "Purchase would exceed current limit max tokens");
        }

        require(ts + numberOfTokens <= collectionSize, "Purchase would exceed max tokens");

        if(!isFreeMintActive){
            require(price_per_token * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        if(isFreeMintActive){
            require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        }

        if (isWhiteListActiveNoLimit){
            require(!isWhiteListActiveList1, "White List 1 is not deactivated");
            require(whitelistedAddressNoLimit[msg.sender], "Client is not on White list");
        
        } 

        if (isWhiteListActiveList1){
            require(!isWhiteListActiveNoLimit, "White List No Limit is not deactivated"); // default is deactivated
            require(whitelistedAddressList1[msg.sender], "Client is not on White List 1");
            
            require(numberOfTokens <= _whitelist_mint_max_list1[msg.sender], "Exceeded max token purchase for White List 1");

            _whitelist_mint_max_list1[msg.sender] -= numberOfTokens;

        } 
          _safeMint(msg.sender, numberOfTokens);

          if (isWhiteListActiveList1 || isWhiteListActiveNoLimit) {
              if (isWhiteListActiveList1){
                  emit WhiteListMintedTokenIdList1(msg.sender, price_per_token);
                  emit WhiteListMintedList1(msg.sender, numberOfTokens);
              } else if (isWhiteListActiveNoLimit) {
                  emit WhiteListMintedTokenIdNoLimit(msg.sender, price_per_token);
                  emit WhiteListMintedNoLimit(msg.sender, numberOfTokens);
              }
          } else {
            if (isFreeMintActive){
              emit MintedTokenId(msg.sender, msg.value);
            } else {
              emit MintedTokenId(msg.sender, price_per_token);
            }
              emit Minted(msg.sender, numberOfTokens);
          }

    }

  function setWhiteListActiveStatusList1(bool _status) external nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        isWhiteListActiveList1 = _status;
    }


  function setWhiteListActiveStatusNoLimit(bool _status) external nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        isWhiteListActiveNoLimit = _status;
    }

  
  function setTotalSupplyLimitActive(bool _status) external nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        isTotalSupplyLimitActive = _status;
    }


  function setFreeMintActive(bool _status) external nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        isFreeMintActive = _status;
    }


  function setLimitTotalSupply(uint256 _limit_total_supply) public nonReentrant {    
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        limit_total_supply = _limit_total_supply;
    }


  function whiteListUserArrayWithIdList1(address[] calldata _address) public {
      
      require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

      for (uint256 i = 0; i < _address.length; i++) {

          whitelistedAddressList1[_address[i]] = true;
          
          _whitelist_mint_max_list1[_address[i]]=max_whitelist_mint_list1;

          emit WhitelistedList1(_address[i], true);
      }

  }


  function whiteListUserArrayWithIdNoLimit(address[] calldata _address) public {
        
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        for (uint256 i = 0; i < _address.length; i++) {

            whitelistedAddressNoLimit[_address[i]] = true;
            
            emit WhitelistedNoLimit(_address[i], true);
        }

    }


    function whiteListNumAvailableToMintList1(address addr) external view returns (uint256) {
    
        return _whitelist_mint_max_list1[addr];
    }


    function viewWhiteListStatusList1(address _address) public view returns (bool) {
        
        return whitelistedAddressList1[_address];
    }

    function viewWhiteListStatusNoLimit(address _address) public view returns (bool) {
        
        return whitelistedAddressNoLimit[_address];
    }

    function removeSingleWhiteListStatusWithIdList1(address _address) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        
        whitelistedAddressList1[_address] = false;

        _whitelist_mint_max_list1[_address]=0;

        emit RemoveWhitelistedList1(_address, false);
                    
    }



    function removeSingleWhiteListStatusWithIdNoLimit(address _address) public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        
        whitelistedAddressNoLimit[_address] = false;

        emit RemoveWhitelistedNoLimit(_address, false);
                     
    }


  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // function setBaseURI(string calldata baseURI) external onlyOwner {
  function setBaseURI(string memory baseURI_) public onlyOwner {
    // _baseTokenURI = baseURI;
    _baseTokenURI = baseURI_;
  }


  function setBaseURIExternal(string memory baseURI_) external nonReentrant {
    require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
    _baseTokenURI = baseURI_;
  }


  function withdrawContractBalance() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}