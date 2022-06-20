//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";



// import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
// import "./ERC721.sol";
// import "./ERC721Enumerable.sol";
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

// import "./ERC721URIStorage.sol";

// contract nft721_1 is ERC721URIStorage, Ownable {
//     using Counters for Counters.Counter;
//     Counters.Counter private _tokenIds;

//     constructor() public ERC721("MyNFT", "NFT") {}

//     function mintNFT(address recipient, string memory tokenURI)
//         public onlyOwner
//         returns (uint256)
//     {
//         _tokenIds.increment();

//         uint256 newItemId = _tokenIds.current();
//         _mint(recipient, newItemId);
//         _setTokenURI(newItemId, tokenURI);

//         return newItemId;
//     }
// }


//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
// contract nft721_1 is Ownable, ERC721, ERC721Enumerable {
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

contract nft721_1 is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

// contract nft721_1 is ERC721URIStorage, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;

    // bool public saleIsActive = false;
    bool public paused = true;
    bool public revealed = false;
    string public notRevealedUri;
    address public owner_address;
    address public admin_address;
    address public sysadm_address;
    string public baseExtension = ".json";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    // uint256 public constant PRICE_PER_TOKEN = 0.01 ether;
    uint256 public price_per_token = 0.001 ether;

    ///////////////////////////////////////////////////
    uint256 public limit_total_supply = 9000;
    bool public isTotalSupplyLimitActive = true; 
    bool public isWhiteListActiveList1 = true; 
    bool public isWhiteListActiveNoLimit = false;
    bool public isFreeMintActive = false;

    uint256 public max_whitelist_mint_list1 =2;

    mapping (address => bool) public whitelistedAddressList1;
    mapping (address => uint256) public _whitelist_mint_max_list1;

    mapping (address => bool) public whitelistedAddressNoLimit;


    ///////////////////////////////////////////////////

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address ownerAddress,
        address adminAddress,
        address sysadmAddress
    ) ERC721A(_name,  _symbol, MAX_SUPPLY) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        owner_address = ownerAddress;
        admin_address = adminAddress;
        sysadm_address = sysadmAddress;
    }

    // ) public ERC721("MyNFT", "NFT") {}

    // function mintNFT(address recipient, string memory tokenURI)
    //     public onlyOwner
    //     returns (uint256)
    // {
    //     _tokenIds.increment();

    //     uint256 newItemId = _tokenIds.current();
    //     _mint(recipient, newItemId);
    //     _setTokenURI(newItemId, tokenURI);

    //     return newItemId;
    // }

    event WhitelistedList1(address indexed account, bool isWhitelisted);
    event WhitelistedNoLimit(address indexed account, bool isWhitelisted);
    
    event RemoveWhitelistedList1(address indexed account, bool isWhitelisted);
    event RemoveWhitelistedNoLimit(address indexed account, bool isWhitelisted);
    
    
    event MintedTokenId(address indexed _address, uint256 minted_token_id, uint256 _price_per_token);
    // event Minted(address indexed _address, uint256 quantity);
    
    event WhiteListMintedTokenIdList1(address indexed _address, uint256 minted_token_id, uint256 _price_per_token);
    event WhiteListMintedTokenIdNoLimit(address indexed _address, uint256 minted_token_id, uint256 _price_per_token);

    // event WhiteListMintedList1(address indexed _address, uint256 quantity);
    // event WhiteListMintedNoLimit(address indexed _address, uint256 quantity);
    
    event SetWhiteListMintMaxGeneralList1(uint256 WhiteListMintMax);

    function mint(uint numberOfTokens) public payable callerIsUser {
        uint256 ts = totalSupply();
        // require(saleIsActive, "Sale must be active to mint tokens");
        require(!paused, 'Contract is paused');
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(price_per_token * numberOfTokens <= msg.value, "Ether value sent is not correct");


        if (isTotalSupplyLimitActive) {
            require(ts + numberOfTokens <= limit_total_supply, "Purchase would exceed current limit max tokens");
        }

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

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);

            if (isWhiteListActiveList1 || isWhiteListActiveNoLimit) {
              if (isWhiteListActiveList1){
                  emit WhiteListMintedTokenIdList1(msg.sender, ts + i, price_per_token);
                  // emit WhiteListMintedList1(msg.sender, numberOfTokens);
              } else if (isWhiteListActiveNoLimit) {
                  emit WhiteListMintedTokenIdNoLimit(msg.sender, ts + i, price_per_token);
                  // emit WhiteListMintedNoLimit(msg.sender, numberOfTokens);
              }
            } else {
                if (isFreeMintActive){
                // event MintedTokenId(address indexed _address, uint256 minted_token_id, uint256 _price_per_token);
                emit MintedTokenId(msg.sender, ts + i, msg.value);
                } else {
                emit MintedTokenId(msg.sender, ts + i, price_per_token);
                }
                
                // emit Minted(msg.sender, numberOfTokens);
            }


        }
    }

    //AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
    //AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

    function pause(bool _state) public  {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        paused = _state;
    }

    function reveal() public {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {    
        notRevealedUri = _notRevealedURI;
    }

    function setNotRevealedURIExternal(string memory _notRevealedURI) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        notRevealedUri = _notRevealedURI;
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


    function setBaseURIExternal(string memory baseURI_) external {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");
        _baseTokenURI = baseURI_;
    }


    function withdrawContractBalance() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function setLimitTotalSupply(uint256 _limit_total_supply) public nonReentrant {    
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        limit_total_supply = _limit_total_supply;
    }

    function setFreeMintActive(bool _status) external nonReentrant {
        require(msg.sender == owner_address || msg.sender == admin_address,"Not Owner nor Admin");

        isFreeMintActive = _status;
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


}

/*
@openzeppelin/contracts/token/ERC721/ERC721.sol contains the 
implementation of the ERC-721 standard, 
which our NFT smart contract will inherit. 
(To be a valid NFT, your smart contract must implement all 
the methods of the ERC-721 standard.) 
To learn more about the inherited ERC-721 functions, check out the interface definition

*/