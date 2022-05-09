// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";


interface IPDSReserved {
  function burn (address from, uint256 tokenId) external;
  function ownerOf(uint256 tokenId)  external view returns (address);

}

interface IHatchlingz {
  function balanceOf (address owner) external view returns (uint256);

}

contract PDS is ERC721, ERC721Enumerable, Ownable {
  
   IPDSReserved public PDSR;
   IHatchlingz public Hatchlingz;

   address  PDSWallet = 0x4C53E1DF995Aefec0d3723fCaFE9edffD4CC5Bcf;
   address  HatchlingzWallet = 0x44D4C4C2197F69aA276c74037f2ce6ebBC5e489E;

   uint PDSPay = 70; //will be divided by 100 and leave some space for infinite division
   uint HatchlingzPay = 295; //will be divided by 1000


    bool public saleIsActive = false;
    bool public isReservedClaimActive = false;

    string private _baseURIextended;

    bool public isAllowListActive = false;
    bool public isVIPListActive = false;
    uint256 public constant MAX_SUPPLY = 1122;
  
    uint256 public constant RESERVED_AMOUNT = 80;
    uint256 public constant PUBLIC_AVAILABLE_AMOUNT = MAX_SUPPLY-RESERVED_AMOUNT;

    uint256 public publicSupplyCounter =0;

    uint256 public constant PRICE_PER_TOKEN = 0.07 ether;
    uint256 public constant VIP_PRICE_PER_TOKEN = 0.03 ether;

    // mapping(address => uint8) private _allowList;
    mapping(address => uint8) private _VIPList;

    constructor() ERC721("Port Du Soleil", "PDS") {
    }

    function HatchlingzBalanceCheck(address wallet) external view returns (uint256){
        return Hatchlingz.balanceOf(wallet);
    }

     function setPDSR(address PDSRAddress) external onlyOwner {
        PDSR = IPDSReserved(PDSRAddress);
    }
    
     function setHatchlingz(address HatchlingzAddress) external onlyOwner {
        Hatchlingz = IHatchlingz(HatchlingzAddress);
    }

     function setReservedClaimState (bool newState) external onlyOwner {
      isReservedClaimActive = newState;
    }

    // function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
    //     isAllowListActive = _isAllowListActive;
    // }

    // function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         _allowList[addresses[i]] = numAllowedToMint;
    //     }
    // }

     function setIsVIPListActive(bool _isVIPListActive) external onlyOwner {
        isVIPListActive = _isVIPListActive;
    }

    function setVIPList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _VIPList[addresses[i]] = numAllowedToMint;
        }
    }

    function VIPnumAvailableToMint(address addr) external view returns (uint8) {
        return _VIPList[addr];
    }

    // function mintAllowList(uint8 numberOfTokens) external payable {
    //     uint256 ts = totalSupply();
    //     require(isAllowListActive, "Allow list is not active");
    //     require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    //     require(publicSupplyCounter + numberOfTokens <= PUBLIC_AVAILABLE_AMOUNT, "Purchase would exceed max tokens");
    //     require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    //     _allowList[msg.sender] -= numberOfTokens;
    //     for (uint256 i = 0; i < numberOfTokens; i++) {
    //         _safeMint(msg.sender, ts + i);
    //         publicSupplyCounter++;
    //     }
    // }

     function mintVIPList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        

        require(isVIPListActive, "Allow list is not active");
        require(numberOfTokens <= _VIPList[msg.sender], "Exceeded max available to purchase");
       
        require(publicSupplyCounter + numberOfTokens <= PUBLIC_AVAILABLE_AMOUNT, "Purchase would exceed max tokens");
        require(VIP_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _VIPList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
            publicSupplyCounter++;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

  

    function reserve(address to, uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      require(publicSupplyCounter + n <= PUBLIC_AVAILABLE_AMOUNT, "Purchase would exceed max tokens");
      for (i = 0; i < n; i++) {
          _safeMint(to, supply + i);
          publicSupplyCounter++;
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(publicSupplyCounter + numberOfTokens <= PUBLIC_AVAILABLE_AMOUNT, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
            publicSupplyCounter++;
        }
    }

     function reservedMintClaim (uint256[] memory tokenArray) external {
    uint256 ts = totalSupply();
    require(isReservedClaimActive, "can't reserve right now");
    require (ts + tokenArray.length <= MAX_SUPPLY, "eXCEEDED TOTAL SUPPLY");
    for ( uint i = 0; i < tokenArray.length ; i++){
        require(PDSR.ownerOf(tokenArray[i]) == msg.sender);
      PDSR.burn(msg.sender, tokenArray[i]);
      _safeMint(msg.sender, ts+ i );
    }

  }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint PDSPayout = balance*PDSPay/100;
        uint hatchlingzPayout = balance*HatchlingzPay/1000;
        payable(PDSWallet).transfer(PDSPayout);
        payable(HatchlingzWallet).transfer(hatchlingzPayout);
    }
}