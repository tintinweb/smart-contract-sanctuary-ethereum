// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721AA.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SolSuxTest2 is ERC721AA, Ownable ,ReentrancyGuard {
  using Strings for uint256;

  mapping(address => EnumerableSet.Uint16Set) ownerTokenIds;
  uint256 public constant TOTAL_SUPPLY = 8;

  //----private--
  string private _baseURIextended;
  string private _blindURIextended;

  bool private _timeSaleActiveLock;

  address private _payeeAccount = 0x807F99f84805650080B2DB2B8e791E9C18DBB648;

  mapping(address => uint16) private _whiteList;

  //----public--
  uint256 public tokenPrice = 0.03 * 10 ** 18;
  uint256 public tokenPriceWL = 0;

  uint256 public timeSaleActive;
  bool public isSaleActive;

  mapping(address => uint16) public amountMinted;
  //--

  constructor() ERC721AA("Sol Sux t2", "SOLSUXT2") {
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
  }


  function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
  }


  function setWhiteAccount(address account, uint16 numAllowedToMint) external onlyOwner {
        _whiteList[account] = numAllowedToMint;
  }

  function deleteWhiteAccounts(address accounts) external onlyOwner {
            delete _whiteList[accounts];
  }

  function setSaleActiveTime(uint32 hours_) external onlyOwner {
        require(_timeSaleActiveLock == false, "");
        timeSaleActive = block.timestamp + hours_ * 3600;
        _timeSaleActiveLock = true;
  }

  function getSaleActiveTime() external view virtual returns(uint256) {
      return timeSaleActive;
  }


  function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
  }

  function accountAuthorityCheck(address account) public view returns (uint256) {
        if (_whiteList[account] != 0) {
            return _whiteList[account];
        } else {
            return 0;
        }
    }

  function getTokenPrice() public view virtual returns (uint256) {
        if (accountAuthorityCheck(msg.sender) > 0) {
            return tokenPriceWL;
        } else {
            return tokenPrice;
        }
    }



  function adminMintFor(address recipient, uint amount) external onlyOwner {
    require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceed max supply");
    _safeMint(recipient, amount);
  }

  function mint(uint16 amount) external payable nonReentrant {
    require(isSaleActive, "Sale is not active.");
    require(block.timestamp >= timeSaleActive, "Sale is not active yet.");
    require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceed max supply");
    require(amountMinted[msg.sender] + amount <= 3, "Out of mint limit per address!");
    if (totalSupply() >= 7) {
      require(accountAuthorityCheck(msg.sender) > 0, "Sold out.");
    } else {if (totalSupply() > 3) {
      require(getTokenPrice() * amount <= msg.value, "Ether value is not correct");
      }
    }
    amountMinted[msg.sender] += amount;
    _safeMint(msg.sender, amount);
  }


  function ownerTokenIdList(address owner) public view virtual returns (uint16[] memory) {
    return EnumerableSet.values(ownerTokenIds[owner]);
  }


  // OVERRIDE FUNCTION
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return string(abi.encodePacked(_baseURI(), tokenId.toString()));
      
  }

  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
    for (uint16 i = uint16(startTokenId); i < startTokenId + quantity; i++) {
      EnumerableSet.remove(ownerTokenIds[from], i);
      EnumerableSet.add(ownerTokenIds[to], i);
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }



  receive() external payable {}


  function withdraw() external onlyOwner nonReentrant {
      uint balance = address(this).balance;
      payable(_payeeAccount).transfer(balance);
  }

}