pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981Royalties.sol";

interface MoonBoyzCoinContract {
    function deposit()  external view;
    function transferFrom(address src, address dst, uint wad)  external view returns (bool);
}

contract TheMoonBoyzEcoSystem is ERC721Enumerable, Ownable, ERC2981Royalties {
    using SafeMath for uint;

    string baseURI;
    MoonBoyzCoinContract private moonBoyzCoinContract;
    
    mapping(address => uint) private lastClaims;

    
    bool public mergeStarted = true;
    
    event MoonBoyzMerged(uint indexed tokenId, address indexed owner);
    
    constructor(string memory baseURI_) ERC721("The Moon Boyz Merged", "MBZM") {
        baseURI = baseURI_;
        _setRoyalties(owner(), 1000);
        moonBoyzCoinContract = MoonBoyzCoinContract(0xE083eB5f2924d2Ba6Bd3F832cb9A36A5c1D36Db4);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function merge() external payable returns (uint)  {
        uint mintIndex = totalSupply().add(1);
        _safeMint(msg.sender, mintIndex);
        emit MoonBoyzMerged(mintIndex, msg.sender);
        moonBoyzCoinContract.transferFrom(owner(), msg.sender, 10);

        return mintIndex;
    }

    function dailyClaim() public payable {
        if(lastClaims[msg.sender] + (3600 * 24) <= block.timestamp ) {
            lastClaims[msg.sender] = block.timestamp;
            moonBoyzCoinContract.transferFrom(owner(), msg.sender, 10);
        }
    }

    function canClaim(address source) public view returns (bool) {
        return lastClaims[source] + (3600 * 24) <= block.timestamp ;
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
    
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function startMerge() external onlyOwner {
        require(!mergeStarted, "Merge already active.");
        mergeStarted = true;
    }

    function MergeSale() external onlyOwner {
        require(mergeStarted, "Merge is not active.");
        
        mergeStarted = false;
    }

    function withdraw() public onlyOwner {        
        uint256 balance = address(this).balance;
        payable(owner()).transfer( balance );
    }
}