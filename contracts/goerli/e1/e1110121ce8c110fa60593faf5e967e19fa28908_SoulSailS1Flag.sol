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
    
error ErrorContractMintDenied();
error ErrorNotWhiteListed();
error ErrorPulicSaleNotStarted();
error ErrorWlSaleNotStarted();
error ErrorWlSalePeriodOver();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedWalletLimit();
error ErrorExceedMaxSupply();

contract SoulSailS1Flag is ERC2981, ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using MerkleProof for bytes32[];
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;
    
    uint256 public _wlMintPrice = 0 ether;
    uint256 public _wlWalletLimit = 1;
    uint256 public _wlMintStartTime;

    uint256 public _mintPrice = 0 ether;
    uint256 public  _txLimit = 5;
    uint256 public  _walletLimit = 10;
    uint256 public _mintStartTime;

    uint256 public  _maxSupply = 2000;
    
    uint256 public _wlMintTimeRange = 86400;

    bool public _publicStarted = false;
    bool public _wlStarted = false;
    bool public _revealed = false;
    string public _metadataURI = "";
    string public _hiddenMetadataUri;
    bytes32 public _merkleRoot;
    
    mapping (address => uint256) public wlWalletMinted;
    mapping (address => uint256) public walletMinted;

    constructor() ERC721A("Soul Sail S1-Flag", "SSF") {
        _setDefaultRoyalty(owner(), 500);
    }
    
    function wlMint(bytes32[] calldata signature) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_wlStarted) revert ErrorWlSaleNotStarted();
        if (block.timestamp < _wlMintStartTime) revert ErrorWlSaleNotStarted();
        if (block.timestamp > _wlMintStartTime + _wlMintTimeRange)  revert ErrorWlSalePeriodOver();
        if (_wlWalletLimit + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        if (!isWhitelisted(msg.sender, signature)) revert ErrorNotWhiteListed();

        uint256 userMinted = walletMinted[msg.sender];
        if (userMinted >= _wlWalletLimit) revert ErrorExceedWalletLimit();
        
        _safeMint(msg.sender, _wlWalletLimit);
        walletMinted[msg.sender] += _wlWalletLimit;
        
    }

    function pulicMint(uint256 amount) external payable {
        if (tx.origin != msg.sender) revert ErrorContractMintDenied();
        if (!_publicStarted) revert ErrorPulicSaleNotStarted();
        if (block.timestamp < _mintStartTime) revert ErrorPulicSaleNotStarted();
        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
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
        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        _safeMint(to, amount);
    }
    
    struct State {
        uint256 wlMintPrice;
        uint256 wlWalletLimit;
        uint256 mintPrice;
        uint256 txLimit;
        uint256 walletLimit;
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 userMinted;
        bool revealed;
        bool publicStarted;
        bool wlStarted; 
        uint256 mintStartTime;
        uint256 wlMintStartTime;
        uint256 wlMintTimeRange;
    }

    function _state(address minter) external view returns (State memory) {
        return
            State({
                wlMintPrice: _wlMintPrice,
                wlWalletLimit: _wlWalletLimit,
                mintPrice: _mintPrice,
                txLimit: _txLimit,
                walletLimit: _walletLimit,
                maxSupply: _maxSupply,
                totalMinted: uint256(ERC721A._totalMinted()),
                userMinted: uint256(walletMinted[minter]),
                revealed: _revealed,
                publicStarted: _publicStarted,
                wlStarted: _wlStarted,
                mintStartTime: _mintStartTime,
                wlMintStartTime: _wlMintStartTime,
                wlMintTimeRange: _wlMintTimeRange
            });
    }

    function isWhitelisted(address addr, bytes32[] calldata signature) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(signature, _merkleRoot, leaf);
    }
    
    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    } 

    function setWlMintTimeRange(uint256 wlMintTimeRange) public onlyOwner {
        _wlMintTimeRange = wlMintTimeRange;
    }

    function setMintStartTime(uint256 mintStartTime) public onlyOwner {
        _mintStartTime = mintStartTime;
    }
    
    function setWlMintStartTime(uint256 wlMintStartTime) public onlyOwner {
        _wlMintStartTime = wlMintStartTime;
    }

    function setWlWalletLimit(uint256 wlWalletLimit) public onlyOwner {
        _wlWalletLimit = wlWalletLimit;
    } 
    
    function setWlMintPrice(uint256 wlMintPrice) public onlyOwner {
        _wlMintPrice = wlMintPrice;
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
    
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    } 

    function setRevealed(bool revealed) public onlyOwner {
        _revealed = revealed;
    }
 
    function setPublicStarted(bool publicStarted) external onlyOwner {
        _publicStarted = publicStarted;
    }
    
    function setWlStarted(bool wlStarted) external onlyOwner {
        _wlStarted = wlStarted;
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