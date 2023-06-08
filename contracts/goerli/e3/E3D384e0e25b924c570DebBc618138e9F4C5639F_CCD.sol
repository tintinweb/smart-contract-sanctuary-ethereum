// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// import "./SafeMath.sol";
import "./Strings.sol";
// import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
// import "./IERC1155.sol";
// import "./ERC721Enumerable.sol";
import "./ERC721A.sol";

contract CCD is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    //70000000000000000; //0.07 ETH
    //1000000000000000;  //0.001 ETH
    uint256 public constant CCD_PRICE = 1000000000000000; 
    uint256 public constant CCD_MAX = 6000;
    uint256 public constant CCD_RESERVED = 100;
    
    uint256 public constant CCD_PER_MINT = 10;

    uint256 public publicAmountMinted = 0;
    uint256 public reservedAmountMinted = 0;

    string private _baseTokenURI;
    string private _contractURI;

    string public provenanceHash;
    
    bool public publicSaleLive = false;

    constructor() ERC721A("Crazy Cat Damsels", "CCD", CCD_PER_MINT, CCD_MAX)  {    }

    function publicMint(uint256 _num, address _targetAddress) public payable nonReentrant{
        uint256 supply = CCD_RESERVED + publicAmountMinted;
        require(publicSaleLive,                    "PUBLIC_SALE_PAUSED");
        require(_num <= CCD_PER_MINT,              "EXCEED_PER_MINT");
        require(totalSupply() + _num <= CCD_MAX,   "OUT_OF_STOCK");
        require(supply + _num <= CCD_MAX,          "EXCEED_PUBLIC");
        require(msg.value == CCD_PRICE * _num,     "ETH_INCORRECT");

        _safeMint( _targetAddress, _num );
        publicAmountMinted += _num;
    }


    function giveAway(address _targetAddress, uint256 _amount) external onlyOwner {
        require(_amount + reservedAmountMinted <= CCD_RESERVED,    "EXCEED_RESERVED");
        require(totalSupply() + _amount <= CCD_MAX,                "OUT_OF_STOCK");
        
        for(uint256 i; i < _amount; i++){
            reservedAmountMinted++;
            _safeMint( _targetAddress, reservedAmountMinted );
        }
    }
    
    // function walletOfOwner(address _owner) public view virtual override returns(uint256[] memory) {
    //     uint256 tokenCount = balanceOf(_owner);

    //     uint256[] memory tokensId = new uint256[](tokenCount);
    //     for(uint256 i; i < tokenCount; i++){
    //         tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    //     }
    //     return tokensId;
    // }
    

    // function burn(uint256 _tokenId) public virtual {
    //     require(_isApprovedOrOwner(msg.sender, _tokenId), "NOT_OWNER_NOR_APPROVED");
    //     _burn(_tokenId);
    // }
    
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }

    function setProvenanceHash(string calldata _hash) external onlyOwner{
        provenanceHash = _hash;
    }

    function setPublicSaleLiveStatus(bool _val) public onlyOwner {
        publicSaleLive = _val;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}