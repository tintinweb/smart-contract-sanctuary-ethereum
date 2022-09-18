/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//    _____.___.                                   __              //
//    \__  |   |__ __  ____   ____   _____   _____/  |______       //
//     /   |   |  |  \/    \ /  _ \ /     \_/ __ \   __\__  \      //
//     \____   |  |  /   |  (  <_> )  Y Y  \  ___/|  |  / __ \_    //
//     / ______|____/|___|  /\____/|__|_|  /\___  >__| (____  /    //
//     \/                 \/             \/     \/          \/     //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract YunoMetaNFT is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  // Predefined NFT Types
  uint8 private constant TANJORE_DOLL = 1;
  uint8 private constant RANGOLI = 2;
  uint8 private constant TICKET = 3;
  uint8 private constant GEN_ART = 4;
  uint8 private constant TOURISM = 5;
  uint8 private constant LOOTBOX = 6;
  uint8 private constant LOOTBOX_CONTENT_NFT = 7;

  uint256 private constant MAX_NFT_URI_GROUPS = 25;
  uint256 private constant MAX_NUM = 1000000000000;

  uint256 public maxMintAmountPerTx = 5;

  uint256 public NFTTypesCount;
  uint256 public LootBoxTypesCount;

  uint256 public ContractState = 2;
  // 0 = Paused
  // 1 = WL
  // 2 = Public Mint



    bool public Apply_Mint_Restriction;

    string internal errorMetadataUri;

    mapping(uint256 => string) public NFT_metaDataURI_Hidden;

    mapping(uint256 => uint256) public NFT_maxSupply;
    mapping(uint256 => uint256) public NFT_metaFileId;
    mapping(uint256 => uint256) public NFT_totalMinted;
    mapping(uint256 => uint256) public NFT_totalRevealedCount;
    mapping(uint256 => uint256) public NFT_sellingPrice;
    mapping(uint256 => uint256) public NFT_maxMintAllowed;


    mapping(uint256 => uint256) public LB_Content_NFTCount;
    mapping(uint256 => uint256) public LB_Content_maxSupply;
    mapping(uint256 => uint256) public LB_Content_totalMinted;


    mapping(uint256 => uint256) internal mapTokenId_NFTFileNum;
    mapping(uint256 => mapping(uint256 => string)) public metaDataURIs;
    mapping(uint256 => mapping(uint256 => uint256)) public metaURIGroupCounts;

    mapping(address => mapping(uint8 => uint8)) public mintRestriction;
    mapping(address => uint256) internal contractAdmins;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {

    contractAdmins[msg.sender] = 1;
    Apply_Mint_Restriction  = true;
    initSmartContract();

  }


  modifier contractModifyCompliance() {
    require(contractAdmins[msg.sender] == 1, 'Only contract admins can perform this operation');
    _;
  }

  function contractAdmin_Add(address adminAddress) public onlyOwner {
      contractAdmins[adminAddress] = 1;
  }

  function contractAdmin_Remove(address adminAddress) public onlyOwner {
      contractAdmins[adminAddress] = 0;
  }


  function initSmartContract() internal {

    // uri for error meta data file
    errorMetadataUri  = 'https://bafybeiasrs4zthnbvrhiuithokikawcxsi5bw22z43ozcin3w4g7s24wtm.ipfs.nftstorage.link/hidden.json';

    // Configure the NFTs
    NFTTypesCount = 7;

    NFT_maxSupply[TANJORE_DOLL] = 0;
    NFT_maxSupply[RANGOLI] = 0;
    NFT_maxSupply[TICKET] = 0;
    NFT_maxSupply[GEN_ART] = 0;
    NFT_maxSupply[TOURISM] = 0;
    NFT_maxSupply[LOOTBOX] = 5000;
    NFT_maxSupply[LOOTBOX_CONTENT_NFT] = 12350;

    NFT_totalMinted[TANJORE_DOLL] = 0;
    NFT_totalMinted[RANGOLI] = 0;
    NFT_totalMinted[TICKET] = 0;
    NFT_totalMinted[GEN_ART] = 0;
    NFT_totalMinted[TOURISM] = 0;
    NFT_totalMinted[LOOTBOX] = 0;
    NFT_totalMinted[LOOTBOX_CONTENT_NFT] = 0;

    NFT_totalRevealedCount[TANJORE_DOLL] = 0;
    NFT_totalRevealedCount[RANGOLI] = 0;
    NFT_totalRevealedCount[TICKET] = 0;
    NFT_totalRevealedCount[GEN_ART] = 0;
    NFT_totalRevealedCount[TOURISM] = 0;
    NFT_totalRevealedCount[LOOTBOX] = 5000;
    NFT_totalRevealedCount[LOOTBOX_CONTENT_NFT] = 12350;

    NFT_metaFileId[TANJORE_DOLL] = 10000;
    NFT_metaFileId[RANGOLI] = 20000;
    NFT_metaFileId[TICKET] = 30000;
    NFT_metaFileId[GEN_ART] = 40000;
    NFT_metaFileId[TOURISM] = 50000;
    NFT_metaFileId[LOOTBOX] = 60000;
    NFT_metaFileId[LOOTBOX_CONTENT_NFT] = 510000;


    NFT_maxMintAllowed[TANJORE_DOLL] = 5;
    NFT_maxMintAllowed[RANGOLI] = 5;
    NFT_maxMintAllowed[TICKET] = 5;
    NFT_maxMintAllowed[GEN_ART] = 5;
    NFT_maxMintAllowed[TOURISM] = 5;
    NFT_maxMintAllowed[LOOTBOX] = 10;
    NFT_maxMintAllowed[LOOTBOX_CONTENT_NFT] = 500;



    NFT_sellingPrice[TANJORE_DOLL] = 0.001 ether;
    NFT_sellingPrice[RANGOLI] = 0.001 ether;
    NFT_sellingPrice[TICKET] = 0.001 ether;
    NFT_sellingPrice[GEN_ART] = 0.001 ether;
    NFT_sellingPrice[TOURISM] = 0.001 ether;
    NFT_sellingPrice[LOOTBOX] = 0.013 ether;
    NFT_sellingPrice[LOOTBOX_CONTENT_NFT] = 0;


    NFT_metaDataURI_Hidden[TANJORE_DOLL] = '';
    NFT_metaDataURI_Hidden[RANGOLI] = '';
    NFT_metaDataURI_Hidden[TICKET] = '';
    NFT_metaDataURI_Hidden[GEN_ART] = '';
    NFT_metaDataURI_Hidden[TOURISM] = '';
    NFT_metaDataURI_Hidden[LOOTBOX] = '';
    NFT_metaDataURI_Hidden[LOOTBOX_CONTENT_NFT] = '';


    metaURIGroupCounts[TANJORE_DOLL][1] = 10;
    metaDataURIs[TANJORE_DOLL][1] = 'https://bafybeibjwjoyokpvislp5gqgtnvmjec7pgtamc2oblvd25ssehf6mub4si.ipfs.nftstorage.link/';

    metaURIGroupCounts[RANGOLI][1] = 0;
    metaDataURIs[RANGOLI][1] = '';
    
    metaURIGroupCounts[TICKET][1] = 0;
    metaDataURIs[TICKET][1] = '';

    metaURIGroupCounts[GEN_ART][1] = 0;
    metaDataURIs[GEN_ART][1] = '';

    metaURIGroupCounts[TOURISM][1] = 0;
    metaDataURIs[TOURISM][1] = '';

    metaURIGroupCounts[LOOTBOX][1] = 5000;
    metaDataURIs[LOOTBOX][1] = 'https://bafybeicd7syoahgvi52ynwjfuy6alvzkcv6hkxzjeqk4cwpw24pejbnku4.ipfs.nftstorage.link/';

    metaURIGroupCounts[LOOTBOX_CONTENT_NFT][1] = 12350;
    metaDataURIs[LOOTBOX_CONTENT_NFT][1] = 'https://bafybeiab6nyca22vw2u4vgqsbokwqsghhv6ryhbrcapijmue3uxuksyldq.ipfs.nftstorage.link/';


    // Configure lootboxes

    LootBoxTypesCount = 4;
    LB_Content_NFTCount[1] = 2;
    LB_Content_maxSupply[1] = 3200;
    LB_Content_totalMinted[1] = 0;

    LB_Content_NFTCount[2] = 3;
    LB_Content_maxSupply[2] = 1400;
    LB_Content_totalMinted[2] = 0;

    LB_Content_NFTCount[3] = 4;
    LB_Content_maxSupply[3] = 250;
    LB_Content_totalMinted[3] = 0;

    LB_Content_NFTCount[4] = 5;
    LB_Content_maxSupply[4] = 150;
    LB_Content_totalMinted[4] = 0;
 
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public contractModifyCompliance() {
    require(_maxMintAmountPerTx >= 1, 'Incorrect Max Mint Amount');
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMintRestriction(bool _applyRestriction)  public contractModifyCompliance() {
    Apply_Mint_Restriction = _applyRestriction;
  }

  function modifyLootboxType(uint256 _LootboxId, uint256 _LootboxNFTCount, 
                      uint256 _maxSupply)  public contractModifyCompliance() {
    
    // when loot box type is added or modified then LootboxContentNFTs should be kept in sync
    require(_LootboxId <= LootBoxTypesCount, "Invalid Lootbox Id.");
    require(_maxSupply >= LB_Content_totalMinted[_LootboxId], "Maxsupply should be more than minted.");

    LB_Content_NFTCount[_LootboxId] = _LootboxNFTCount;
    LB_Content_maxSupply[_LootboxId] = _maxSupply;    
  }


  function modifyNFTType_Price(uint256 _NFTTypeId,  
                      uint256 _SellingPrice)  public contractModifyCompliance() {
    require(_NFTTypeId < LOOTBOX_CONTENT_NFT, "Invalid NFT Type.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_sellingPrice.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _SellingPrice)
    }

  }


  function modifyNFTType_Supply(uint256 _NFTTypeId, uint256 _maxSupply)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256 minted;
    uint256 fileid;

    minted = getMinted(_NFTTypeId);
    fileid = getFileid(_NFTTypeId);

    require(_maxSupply >= minted, "Max Supply less than Total Minted.");
    require(fileid + _maxSupply < MAX_NUM, "Invalid Max Supply.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_maxSupply.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _maxSupply)
    }
  }



  function modifyNFTType_Reveal(uint256 _NFTTypeId, uint256 _revealCount, 
                      string memory _metaDataURI_hidden)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_totalRevealedCount.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _revealCount)

      mstore(add(tempMem, 0x20),  NFT_metaDataURI_Hidden.slot)
      hash := keccak256(tempMem, 64)
      sstore(hash, _metaDataURI_hidden)
    }

  }


  function modifyNFTType_FileId(uint256 _NFTTypeId,  
                       uint256 _metaFileId)  public contractModifyCompliance() {

    uint256 minted;
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    require(_metaFileId < MAX_NUM, "Invalid File Id.");

    minted = getMinted(_NFTTypeId);
    require(minted == 0, "Cannot change file id for minted NFTs.");

    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_metaFileId.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _metaFileId)
    }
  }


  function modifyNFTType_MaxMintAllowed(uint256 _NFTTypeId,  
                       uint8 _maxMints)  public contractModifyCompliance() {

    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256[] memory tempMem =new uint256[](2);
  
    assembly {
      mstore(tempMem, _NFTTypeId)
      mstore(add(tempMem, 0x20),  NFT_maxMintAllowed.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, _maxMints)
    }
  }




  function modifyNFTType_AddMetaURIGroup(uint256 _NFTTypeId,  
                      uint256 _uriGroupCount, string memory _metaDataURI)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");
    uint256 i;
    unchecked { 
      i = 1;
      while (i < MAX_NFT_URI_GROUPS) {
        if (metaURIGroupCounts[_NFTTypeId][i] == 0) {
          break;
        } else {
          i++; 
        }
      }
    }
    require(i < MAX_NFT_URI_GROUPS, "Max URIs already added.");
    metaURIGroupCounts[_NFTTypeId][i] = _uriGroupCount;
    metaDataURIs[_NFTTypeId][i] = _metaDataURI;
  }



  function modifyNFTType_ChangeMetaURIGroup(uint256 _NFTTypeId,  uint256 _groupId,
                      uint256 _uriGroupCount, string memory _metaDataURI)  public contractModifyCompliance() {
    require(_NFTTypeId <= NFTTypesCount, "Invalid NFT Type.");

    metaURIGroupCounts[_NFTTypeId][_groupId] = _uriGroupCount;
    metaDataURIs[_NFTTypeId][_groupId] = _metaDataURI;
  }


  function getMetaURIGroupCount(uint256 _NFTTypeId, uint256 _groupId) public view contractModifyCompliance() returns (uint256) {
    return metaURIGroupCounts[_NFTTypeId][_groupId];
  }

  function getMetaGroupURI(uint256 _NFTTypeId, uint256 _groupId) public view contractModifyCompliance() returns (string memory) {
    return metaDataURIs[_NFTTypeId][_groupId];
  }


  function getTokenMetaFileName(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), 'query for non existent token');
    uint256[] memory tempMem =new uint256[](2);
    uint256 i;
    uint256 nftFileName;

    assembly {
      i := _tokenId
      mstore(tempMem, i)
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      let hash := keccak256(tempMem, 64)
      nftFileName := sload(hash)
      for {} eq(nftFileName, 0) {} {
        i := sub(i,1)
        mstore(tempMem, i)
        hash := keccak256(tempMem, 64)
        nftFileName := sload(hash)
        if eq(i, 1) {
          break
        }
      }
      nftFileName := add(nftFileName, sub(_tokenId, i))
    }

    return nftFileName;
  }


  function getTokenNFTType(uint256 _tokenId) public view returns (uint256) {
    
    require(_exists(_tokenId), 'query for non existent token');
    uint256 i;
    uint256 tokenFile;

    unchecked {
      tokenFile = getTokenMetaFileName(_tokenId);
      assembly {
        i := div(tokenFile, 10000)
        if gt(i, sload(NFTTypesCount.slot)) {
          i := LOOTBOX_CONTENT_NFT
        }
      }
    }
    return i;
  }


  function randomNum(uint256 _rand) public view returns (uint256) {
    uint256 num;
    unchecked { 
      num  = (uint256(keccak256(abi.encode( _rand, msg.sender, block.timestamp, 5001))) % 5000) + 1;
      assembly {
        switch lt(num, 3201) 
        case true {
          num := 1
        }        
        default {
          switch lt(num, 4601)  
          case true {
            num := 2
          }        
          default {
            switch lt(num, 4851) 
            case true {
              num := 3
            }        
            default {
              num := 4
            }
          }
        }
      }
    }
    return num;
  }

  function isAdmin(address _add) public view returns (bool) {
    return contractAdmins[_add] > 0
        ? true
        : false;
  }


  
  function whitelistMint(uint8 _NFTTypeID, uint256 _mintAmount, bytes32[] memory _merkleProof) public payable 
    {
    // Verify whitelist requirements
    uint256 supply;
    uint256 fileid;
    uint256 minted;
    uint256 myMinted;
    uint256 price;
    uint256 maxMints;
    uint256[] memory tempMem =new uint256[](2);
    

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Not included in whitelist!');
      require(ContractState == 1, 'Invalid mint type!');
      require(_NFTTypeID < LOOTBOX_CONTENT_NFT, 'Invalid NFT Type!');

    minted = getMinted(_NFTTypeID);
    supply = getSupply(_NFTTypeID);
    price = getCost(_NFTTypeID);

    
    unchecked {
      require((_mintAmount > 0) && (_mintAmount <= maxMintAmountPerTx), 'Mint Count More Than Max Allowed.');
      require((_mintAmount + minted) <= supply, 'Mint amount more than available!');
      require(msg.value  >= (price * _mintAmount), 'Insufficient Funds!');
    }

    fileid = getFileid(_NFTTypeID);
    supply = totalSupply();

    unchecked {
      if (Apply_Mint_Restriction) {
        maxMints = getMaxMintAllowed(_NFTTypeID);
        myMinted = mintRestriction[msg.sender][_NFTTypeID];
        require((myMinted + _mintAmount) <= maxMints, 'Mint Count More Than Max Allowed.');
      }
    }

    assembly {

      mstore(tempMem, _NFTTypeID)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, add(minted, _mintAmount))


      fileid := add(fileid, minted)

      mstore(tempMem, add(supply, 1))
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      hash := keccak256(tempMem, 64)
      sstore(hash, add(fileid,1))
    }


    unchecked {
      if (Apply_Mint_Restriction) {
        mintRestriction[msg.sender][_NFTTypeID] = uint8(myMinted + _mintAmount);
      }
    }

    _safeMint(_msgSender(), _mintAmount);
  }


  function mint(uint8 _NFTType, uint256 _mintAmount) public payable 
   {

    uint256 supply;
    uint256 fileid;
    uint256 minted;
    uint256 price;
    uint256 myMinted;
    uint256 maxMints;
    uint256[] memory tempMem =new uint256[](2);

    minted = getMinted(_NFTType);
    supply = getSupply(_NFTType);
    price = getCost(_NFTType);

  unchecked {

    require((_mintAmount + minted) <= supply, 'Mint amount more than available!');
    require(msg.value  >= (price * _mintAmount), 'Insufficient Funds!');
    require(ContractState == 2, 'Invalid mint type!');
    require(_NFTType < LOOTBOX_CONTENT_NFT, 'Invalid NFT Type!');
    require((_mintAmount > 0) && (_mintAmount <= maxMintAmountPerTx), 'Mint Count More Than Max Allowed.');

  }

    fileid = getFileid(_NFTType);
    supply = totalSupply();

    unchecked {

      if (Apply_Mint_Restriction) {
        myMinted = mintRestriction[msg.sender][_NFTType];
        maxMints = getMaxMintAllowed(_NFTType);
        require((myMinted + _mintAmount) <= maxMints, 'Mint Count More Than Max Allowed.');
      }
    }

    assembly {

      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      sstore(hash, add(minted, _mintAmount))

      fileid := add(fileid, minted)
      mstore(tempMem, add(supply, 1))
      mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
      hash := keccak256(tempMem, 64)
      sstore(hash, add(fileid,1))

    }
    unchecked {
      if (Apply_Mint_Restriction) {
        mintRestriction[msg.sender][_NFTType] = uint8(myMinted + _mintAmount);
      }
    }
    _safeMint(_msgSender(), _mintAmount);
  }
  


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    uint256 supply = totalSupply();
    address tokenOwner;

    unchecked {
      while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supply) {
        tokenOwner = ownerOf(currentTokenId);
        if (tokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;
          ownedTokenIndex++;
        }
        currentTokenId++;
      }
    }
    return ownedTokenIds;
  }

  function burnLootbox(uint256 _lbTokenId) public {
    transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _lbTokenId);
    return;
  }

  function findMyLootbox() public view returns (uint256) {

    uint256 supply = totalSupply();
    require(supply > 0, 'query for non existent token');
    uint256 currentTokenId = 1;
    address tokenOwner;
    uint256 lootboxId;

    unchecked {
      while (currentTokenId <= supply) {
        if (getTokenNFTType(currentTokenId) == LOOTBOX) {
          tokenOwner = ownerOf(currentTokenId);
          if (tokenOwner == msg.sender) {
            lootboxId = currentTokenId;
            break;
          }
        }
        currentTokenId++;
      }
    }
    return lootboxId;
  }

  function walletOfOwner_FindLootbox(address _owner, uint256 _startCountTokenId) public view returns (uint256) {
    require(_exists(_startCountTokenId), 'query for non existent token');
    uint256 currentTokenId = _startCountTokenId;
    uint256 supply = totalSupply();
    address tokenOwner;
    uint256 lootboxId;

    unchecked {
      while (currentTokenId <= supply) {
        if (getTokenNFTType(currentTokenId) == LOOTBOX) {
          tokenOwner = ownerOf(currentTokenId);
          if (tokenOwner == _owner) {
            lootboxId = currentTokenId;
            break;
          }
        }
        currentTokenId++;
      }

    }

    return lootboxId;
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function mintLootboxContents(address _from) internal {
    uint256 supply;
    uint256 i;
    uint256 fileStartNum;
    uint256 minted;
    uint256 fileid;
    uint256 maxSupply;
    uint256 lootBoxType;
    uint256 mintAmount;
    uint256[] memory tempMem =new uint256[](2);
    string memory errText;

    errText = "Cannot burn lootbox";
    supply = totalSupply();
    lootBoxType = randomNum(supply);

    minted = getMinted(LOOTBOX_CONTENT_NFT);
    fileid = getFileid(LOOTBOX_CONTENT_NFT);
    maxSupply = getSupply(LOOTBOX_CONTENT_NFT);
    
    assembly {

      mstore(tempMem, lootBoxType)
      mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      let lbMinted := sload(hash)
      
      mstore(add(tempMem, 0x20),  LB_Content_maxSupply.slot)
      hash := keccak256(tempMem, 64)
      let lbSupply := sload(hash)
      
     
      switch lt(lbMinted, lbSupply)
      case true {
        mstore(add(tempMem, 0x20),  LB_Content_NFTCount.slot)
        hash := keccak256(tempMem, 64)
        mintAmount := sload(hash)
      }
      default {
        for {i:=1} or(lt(i,4), eq(i,4) ) {i:= add(i,1)} {
          mstore(tempMem, i)
          mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
          hash := keccak256(tempMem, 64)
          lbMinted := sload(hash)
      
          mstore(add(tempMem, 0x20),  LB_Content_maxSupply.slot)
          hash := keccak256(tempMem, 64)
          lbSupply := sload(hash)
          if lt(lbMinted, lbSupply) {
            lootBoxType := i
            break 
          }
        }


        if gt(lootBoxType,4) {
          revert(add(errText, 0x20), mload(errText))
        }
        mstore(tempMem, lootBoxType)
        mstore(add(tempMem, 0x20),  LB_Content_NFTCount.slot)
        hash := keccak256(tempMem, 64)
        mintAmount := sload(hash)
      }

      if lt(maxSupply, add(minted, mintAmount)) {
          revert(add(errText, 0x20), mload(errText))
      }

        fileStartNum := add(fileid, minted)

        mstore(tempMem, LOOTBOX_CONTENT_NFT)
        mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(minted, mintAmount))

        mstore(tempMem, add(supply, 1))
        mstore(add(tempMem, 0x20),  mapTokenId_NFTFileNum.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(fileStartNum,1))

        mstore(tempMem, lootBoxType)
        mstore(add(tempMem, 0x20),  LB_Content_totalMinted.slot)
        hash := keccak256(tempMem, 64)
        sstore(hash, add(sload(hash),1))
    }

    _safeMint(_from, mintAmount);

  }
  

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {

      uint256 NFTType;
      NFTType = getTokenNFTType(tokenId);
      
      if ((NFTType == LOOTBOX) && to == address(0x000000000000000000000000000000000000dEaD)) {
        require(ownerOf(tokenId) == from, "Only NFT owner can transfer");
        mintLootboxContents(from);
      } 
      super.transferFrom(from, to, tokenId);

    }



  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'URI query for non existent token');
    string memory currentBaseURI;
    uint256 nftType;
    uint256 nftFileName;
    uint256 nftNum;


    unchecked {
      nftFileName = getTokenMetaFileName(_tokenId);

      assembly {
        nftType := div(nftFileName, 10000)
        if gt(nftType, sload(NFTTypesCount.slot)) {
          nftType := LOOTBOX_CONTENT_NFT
        }
      }

      nftNum = nftFileName - getFileid(nftType);
      currentBaseURI = getNFTURI(nftType, nftNum, nftFileName);

    }

    return bytes(currentBaseURI).length > 0
        ? currentBaseURI
          : errorMetadataUri;
  }


  function getNFTURI(uint256 _NFTType, uint256 _NFTNum, uint256 _NFTFileName) public view returns (string memory) {

    string memory NFTUri;
    uint256 i;
    uint256  count;

    if (_NFTNum > getRevealCount(_NFTType)) {
      NFTUri = getHiddenURI(_NFTType);
    } else {
       count = 0;
        for (i = 1; i < MAX_NFT_URI_GROUPS; i++) {
          count = count + metaURIGroupCounts[_NFTType][i];
          if (_NFTNum <= count) {
            NFTUri = metaDataURIs[_NFTType][i];
            NFTUri = string(abi.encodePacked(NFTUri, _NFTFileName.toString(), '.json'));
            break;
          }
        }
    }

    return NFTUri;
  }



  function getNFTURISave(uint256 _NFTType, uint256 _NFTNum, uint256 _NFTFileName) public view returns (string memory) {

    uint256[] memory tempMem =new uint256[](2);
    uint256[] memory tempMem2 =new uint256[](2);
    string memory NFTUri;
    bool bAddId = true;
    if (_NFTNum > getRevealCount(_NFTType)) {
      NFTUri = getHiddenURI(_NFTType);
      bAddId = false;
    } else {

      assembly {

        let count := 0        
        let i := 1
        mstore(tempMem, _NFTType)
        mstore(add(tempMem, 0x20),  metaURIGroupCounts.slot)
        let hash := keccak256(tempMem, 64) 
        
        mstore(add(tempMem2, 0x20), hash)

        for { } lt(i, sload(MAX_NFT_URI_GROUPS)) { } {
          mstore(tempMem2, i)
          hash := keccak256(tempMem2, 64) 
          count := add(count, sload(hash))
          if or(lt(_NFTNum, count), eq(_NFTNum, count)) {
            break
          }
          i := add(i,1)
        }
        switch eq(i, sload(MAX_NFT_URI_GROUPS))
        case true {
          NFTUri := sload(errorMetadataUri.slot)
          bAddId := false
        } 
        default {
          mstore(add(tempMem, 0x20),  metaDataURIs.slot)
          hash := keccak256(tempMem, 64) 
          mstore(tempMem2, i)
          mstore(add(tempMem2, 0x20), hash)
          hash := keccak256(tempMem2, 64)
          NFTUri := sload(hash) 
        }

      }
      if (bAddId) {
        NFTUri = string(abi.encodePacked(NFTUri, _NFTFileName.toString(), '.json'));
      }
    }

    return NFTUri;
  }


  function getRevealCount(uint256 _NFTType) public view returns (uint256) {

    uint256 count;
    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalRevealedCount.slot)
      let hash := keccak256(tempMem, 64)
      count := sload(hash)
    }
    return count;
  }


  function getHiddenURI(uint256 _NFTType) public view returns (string memory) {

    string memory hiddenURI;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_metaDataURI_Hidden.slot)
      let hash := keccak256(tempMem, 64)
      hiddenURI := sload(hash)
    }
    
    return hiddenURI;
  }



  function getSupply(uint256 _NFTType) public view returns (uint256) {

    uint256 supply;
    
    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_maxSupply.slot)
      let hash := keccak256(tempMem, 64)
      supply := sload(hash)
    }

    return supply;
  }

  function getFileid(uint256 _NFTType) public view returns (uint256) {

    uint256 fileid;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_metaFileId.slot)
      let hash := keccak256(tempMem, 64)
      fileid := sload(hash)
    }

    return fileid;
  }



  function getMinted(uint256 _NFTType) public view returns (uint256) {

    uint256 minted;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_totalMinted.slot)
      let hash := keccak256(tempMem, 64)
      minted := sload(hash)
    }

    return minted;
  }


  function getCost(uint256 _NFTType) public view returns (uint256) {
    uint256 price;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_sellingPrice.slot)
      let hash := keccak256(tempMem, 64)
      price := sload(hash)
    }
    return price;
  }


  function getMaxMintAllowed(uint256 _NFTType) public view returns (uint256) {
    uint256 maxMints;

    uint256[] memory tempMem =new uint256[](2);
    assembly {
      mstore(tempMem, _NFTType)
      mstore(add(tempMem, 0x20),  NFT_maxMintAllowed.slot)
      let hash := keccak256(tempMem, 64)
      maxMints := sload(hash)
    }
    return maxMints;
  }



  function setContractState(uint256 _state) public contractModifyCompliance() {
    ContractState = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public contractModifyCompliance() {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

 
  fallback() external{
  }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}