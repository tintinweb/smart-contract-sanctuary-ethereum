// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

error ErrorHolderClaimedAlready();
error ErrorBurnedAlready();
error ErrorContractMintDenied();
error ErrorNotValidHolder();
error ErrorPulicSaleNotStarted();
error ErrorBurnNotStarted();
error ErrorBurnPeriodOver();
error ErrorBurnTokenIds();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();
error ErrorPorvideWrongTokenids();
error ErrorHolderClaimNotStarted();
error ErrorHolderClaimPeriodOver();

contract SoulSailS3Clan is ERC2981, ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public _burnStartTime;
    
    uint256 public _holderClaimStartTime;

    uint256 public _mintPrice = 0 ether;
    uint256 public  _txLimit = 5;
    uint256 public  _walletLimit = 10;
    uint256 public _mintStartTime;

    uint256 public  _maxSupplyForPublic = 2000;
    uint256 public  _maxSupplyForBurn = 1500;

    uint256 public _burnTimeRange = 86400;

    uint256 public _holderClaimTimeRange = 86400;

    bool public _publicStarted = false;
    bool public _burnStarted = false;
    bool public _holderClaimStarted = false;
    bool public _revealed = false;
    string public _metadataURI = "";
    string public _hiddenMetadataUri;
    bytes32 public _merkleRoot;

    mapping (address => bool) public holderClaimed;
    mapping (address => uint256) public holderBurnedPairs;
    mapping (address => uint256) public walletMinted;
    
    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    IERC721 public _s1FlagContract;

    constructor() ERC721A("Soul Sail S3-Clan", "SSC") {
        _setDefaultRoyalty(owner(), 500);
    }
    
    function holderClaim(uint256 amount,bytes32[] calldata holderSignature) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_holderClaimStarted) revert ErrorHolderClaimNotStarted();
        if (block.timestamp < _holderClaimStartTime) revert ErrorHolderClaimNotStarted();
        if (block.timestamp > _holderClaimStartTime + _holderClaimTimeRange)  revert ErrorHolderClaimPeriodOver();
        if (holderClaimed[msg.sender] == true) revert ErrorHolderClaimedAlready();
        if (amount + _totalMintedForBurn() > _maxSupplyForBurn) revert ErrorExceedMaxSupply();
        if (!isValidHolder(msg.sender, amount, holderSignature)) revert ErrorNotValidHolder();
        
        _safeMintForBurn(msg.sender, amount); 
        holderClaimed[msg.sender] = true;
        walletMinted[msg.sender] += amount;
    }

    function BurnForClan(uint256[] memory tokenIds) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_burnStarted) revert ErrorBurnNotStarted();
        if (block.timestamp < _burnStartTime) revert ErrorBurnNotStarted();
        if (block.timestamp > _burnStartTime + _burnTimeRange)  revert ErrorBurnPeriodOver();
        if (tokenIds.length < 1)  revert ErrorPorvideWrongTokenids();
        if (tokenIds.length + _totalMintedForBurn() > _maxSupplyForBurn) revert ErrorExceedMaxSupply();
        
        uint256 burnNumber = tokenIds.length;

        for (uint256 i = 0; i < burnNumber; ) {
            if(_s1FlagContract.ownerOf(tokenIds[i]) == msg.sender){
                _s1FlagContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
                unchecked {
                    i++;
                }
            }else{
                burnNumber--;
            } 
        }
        if (burnNumber < 1)  revert ErrorBurnTokenIds();
        
        _safeMintForBurn(msg.sender, burnNumber); 
        holderBurnedPairs[msg.sender] += burnNumber;
        walletMinted[msg.sender] += burnNumber;
    }

     function BurnForClan2(uint256[] memory tokenIds) external payable {
     
       
                _s1FlagContract.transferFrom(msg.sender, BLACKHOLE, tokenIds[0]);
            
        
        _safeMintForBurn(msg.sender, 1);  
    }

    function pulicMint(uint256 amount) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_publicStarted) revert ErrorPulicSaleNotStarted();
        if (block.timestamp < _mintStartTime) revert ErrorPulicSaleNotStarted();
        if (amount + _totalMinted() > _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        if (amount > _txLimit) revert ErrorExceedTransactionLimit();
        
        uint256 requiredValue = amount * _mintPrice;
        uint256 userMinted = walletMinted[msg.sender];
        if (userMinted >= _walletLimit) revert ErrorExceedWalletLimit();
        if (userMinted + amount > _walletLimit) revert ErrorExceedWalletLimit();
        if (msg.value < requiredValue) revert ErrorInsufficientFund();
        
        _safeMint(msg.sender, amount);
        walletMinted[msg.sender] += amount;
    
    }
    
    function devMint(address to, uint256 amount) external onlyOwner {
        if (amount + _totalMinted() > _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        _safeMint(to, amount);
    }
    
    function devMintForBurn(address to, uint256 amount) external onlyOwner {
        if (amount + _totalMinted() > _maxSupplyForPublic) revert ErrorExceedMaxSupply();
        _safeMintForBurn(to, amount);
    }

    struct State {
        uint256 mintPrice;
        uint256 txLimit;
        uint256 walletLimit;
        uint256 maxSupplyForPublic;
        uint256 maxSupplyForBurn;
        uint256 totalMinted;
        uint256 totalMintedForBurn;
        bool revealed;
        bool publicStarted;
        bool BurnStarted; 
        uint256 holderClaimStartTime; 
        uint256 burnStartTime; 
        uint256 burnTimeRange; 
        uint256 holderClaimTimeRange; 
        uint256 mintStartTime; 
    }

    function _state() external view returns (State memory) {
        return
            State({
                mintPrice: _mintPrice,
                txLimit: _txLimit,
                walletLimit: _walletLimit,
                maxSupplyForPublic: _maxSupplyForPublic,
                maxSupplyForBurn: _maxSupplyForBurn,
                totalMinted: uint256(ERC721A._totalMinted()),
                totalMintedForBurn: uint256(ERC721A._totalMintedForBurn()),
                revealed: _revealed,
                publicStarted: _publicStarted,
                BurnStarted: _burnStarted,
                holderClaimStartTime: _holderClaimStartTime,
                burnStartTime: _burnStartTime,
                burnTimeRange: _burnTimeRange,
                holderClaimTimeRange: _holderClaimTimeRange,
                mintStartTime: _mintStartTime
            });
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function isValidHolder( address addr, uint256 amount, bytes32[] calldata signature) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(string.concat( "0x",toAsciiString(addr), ",", Strings.toString(amount))));
        return MerkleProof.verify(signature, _merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }
    
    function setHolderClaimTimeRange(uint256 holderClaimTimeRange) public onlyOwner {
        _holderClaimTimeRange = holderClaimTimeRange;
    }
    
    function setHolderClaimStartTime(uint256 holderClaimStartTime) public onlyOwner {
        _holderClaimStartTime = holderClaimStartTime;
    }
    
    function setHolderClaimStarted(bool holderClaimStarted) external onlyOwner {
        _holderClaimStarted = holderClaimStarted;
    }

    function setBurnTokenContract(address s1FlagContract) external onlyOwner {
        _s1FlagContract = IERC721(s1FlagContract);
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1501;
    } 
    
    function _startTokenIdForBurn() internal view virtual override returns (uint256) {
        return 1;
    } 

    function setBurnTimeRange(uint256 burnTimeRange) public onlyOwner {
        _burnTimeRange = burnTimeRange;
    }

    function setMintStartTime(uint256 mintStartTime) public onlyOwner {
        _mintStartTime = mintStartTime;
    }
    
    function setBurnStartTime(uint256 burnStartTime) public onlyOwner {
        _burnStartTime = burnStartTime;
    }
 
    function setTxLimit(uint256 txLimit) public onlyOwner {
        _txLimit = txLimit;
    }
    
    function setWalletLimit(uint256 walletLimit) public onlyOwner {
        _walletLimit = walletLimit;
    } 

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }
    
    function setMaxSupply(uint256 maxSupplyForBurn,uint256 maxSupplyForPublic) public onlyOwner {
        _maxSupplyForPublic = maxSupplyForPublic;
        _maxSupplyForBurn = maxSupplyForBurn;
    } 

    function setRevealed(bool revealed) public onlyOwner {
        _revealed = revealed;
    }
 
    function setPublicStarted(bool publicStarted) external onlyOwner {
        _publicStarted = publicStarted;
    }
    
    function setBurnStarted(bool burnStarted) external onlyOwner {
        _burnStarted = burnStarted;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setHiddenMetadataUri(string memory hiddenMetadataUri) public onlyOwner {
        _hiddenMetadataUri = hiddenMetadataUri;
    }
    
    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (_revealed == false) {
            return _hiddenMetadataUri;
        }

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    } 
  
    function withdraw() external onlyOwner nonReentrant{
        payable(msg.sender).sendValue(address(this).balance);
    }
	
	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}
  
}