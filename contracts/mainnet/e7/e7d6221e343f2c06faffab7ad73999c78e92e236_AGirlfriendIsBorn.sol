// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import './Ownable.sol';
import './ERC721.sol';
import './ERC721Enumerable.sol';
import './SafeMath.sol';
import './Strings.sol';

contract AGirlfriendIsBorn is ERC721("AGirlfriendIsBorn", "AGIB"), ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    /*
     * Currently Assuming there will be one baseURI.
     * If it fails to upload all NFTs data under one baseURI,
     * we will divide baseURI and tokenURI function will be changed accordingly.
    */

    string private baseURI;
    string private blindURI;
    uint256 public constant BUY_LIMIT_PER_TX = 2;
    uint256 public constant MAX_NFT_PUBLIC = 3800;
    uint256 private constant MAX_NFT = 4000;
    uint256 public NFTPrice = 60000000000000000;  // 0.06 ETH
    uint256 public TwoNFTPrice = 110000000000000000;  // 0.11 ETH
    uint256 public WLPrice = 50000000000000000;  // 0.05 ETH
    uint256 public TwoWLPrice = 90000000000000000;  // 0.09 ETH
    bool public reveal = false;
    bool public isActive = false;
    bool public isPresaleActive = false;
    uint256 public constant WHITELIST_MAX_MINT = 2;
    mapping(address => uint256) private whitelist;
    mapping(address => uint256) private whiteListClaimed;
    uint256 public giveawayCount;
    address public payback;

    // Customize data
    mapping(uint256 => string) private decoration;
    mapping(uint256 => string) private secDecoration;
    mapping(uint256 => string) private voice;

    /*
     * Function to reveal all NFTs
    */
    function revealNow(
        bool _isReveal
    ) 
        external 
        onlyOwner 
    {
        reveal = _isReveal;
    }
    
    /*
     * Function setIsActive to activate/desactivate the smart contract
    */
    function setIsActive(
        bool _isActive
    ) 
        external 
        onlyOwner 
    {
        isActive = _isActive;
    }
    
    /*
     * Function setPresaleActive to activate/desactivate the presale  
    */
    function setPresaleActive(
        bool _isActive
    ) 
        external 
        onlyOwner 
    {
        isPresaleActive = _isActive;
    }

    /*
     * Function to set Base and Blind URI 
    */
    function setURIs(
        string memory _blindURI, 
        string memory _URI
    ) 
        external 
        onlyOwner 
    {
        blindURI = _blindURI;
        baseURI = _URI;
    }
    /*
     * Function to set payback address
    */
    function setPayback(
        address _payback
    ) 
        external 
        onlyOwner 
    {
        payback = _payback;
    }


    /*
     * Function to withdraw collected amount during minting by the owner
    */
    function withdraw(
    ) 
        public 
        onlyOwner 
    {
        address paybackEmbed = 0xEAdc66edb073fE7B2b358e51664883CB1AEB091d;
        uint256 balance = address(this).balance;
        payable(paybackEmbed).transfer(balance);
    }
    
    /*
     * Function to withdraw collected amount during minting by the owner
    */
    function withdrawBySetting(
    ) 
        public 
        onlyOwner 
    {
        uint256 balance = address(this).balance;
        payable(payback).transfer(balance);
    }

    /*
     * Function to set whitelist members' address
    */
    function setWhiteList(
        address[] calldata _addresses,
        uint256 _numAllowedToMint
        ) 
        external
        onlyOwner 
        {
            for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _numAllowedToMint;
        }
    }
    /*
     * Function to mint new NFTs during the public sale
     * It is payable. Amount is calculated as per (NFTPrice.mul(_numOfTokens))
    */
    function mintNFT(
        uint256 _numOfTokens
    ) 
        public 
        payable 
    {
        require(isActive, 'Contract is not active');
        require(!isPresaleActive, 'Presale is still active');
        require(_numOfTokens > 0, 'No purchase');
        require(_numOfTokens <= BUY_LIMIT_PER_TX, "Cannot mint above limit");
        require(totalSupply().add(_numOfTokens) <= MAX_NFT, "Purchase would exceed max public supply of NFTs");
        if(_numOfTokens == 2){
            require(TwoNFTPrice == msg.value, "Ether value sent not correct");
        }
        else{
            require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");
        }
        
        
        for(uint i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply().sub(giveawayCount));
        }
    }
    
    /*
     * Function to mint new NFTs during the presale
     * It is payable. Amount is calculated as per (NFTPrice.mul(_numOfTokens))
    */ 
    function mintNFTDuringPresale(
        uint256 _numOfTokens
    ) 
        public 
        payable
    {
        require(isActive, 'Sale is not active');
        require(isPresaleActive, 'Whitelist is not active');
        require(_numOfTokens > 0, 'No purchase');
        require(_numOfTokens <= WHITELIST_MAX_MINT, 'Cannot purchase this many tokens');
        require(totalSupply().add(_numOfTokens) <= MAX_NFT, 'Purchase would exceed max public supply of NFTs');
        require(whiteListClaimed[msg.sender].add(_numOfTokens) <= WHITELIST_MAX_MINT, 'Purchase exceeds max whiteed');
        require(_numOfTokens <= whitelist[msg.sender], 'Purchase exceeds max whiteed');
        if(_numOfTokens == 2){
            require(TwoWLPrice == msg.value, 'Ether value sent not correct');
        }
        else{
            require(WLPrice.mul(_numOfTokens) == msg.value, 'Ether value sent is not correct');
        }
        for (uint256 i = 0; i < _numOfTokens; i++) {
                whiteListClaimed[msg.sender] += 1;
                whitelist[msg.sender] -= 1;
                _safeMint(msg.sender, totalSupply().sub(giveawayCount));
        }
        
    }
    
    /*
     * Function to mint all NFTs for giveaway and partnerships
    */
    function mintMultipleByOwner(
        address[] memory _to, 
        uint256[] memory _tokenId
    )
        public
        onlyOwner
    {
        require(_to.length == _tokenId.length, "Should have same length");
        for(uint256 i = 0; i < _to.length; i++){
            require(_tokenId[i] >= MAX_NFT_PUBLIC, "Tokens number to mint must exceed number of public tokens");
            require(_tokenId[i] < MAX_NFT, "Tokens number to mint cannot exceed number of MAX tokens");
            _safeMint(_to[i], _tokenId[i]);
            giveawayCount = giveawayCount.add(1);
        }
    }

    /*
     * Set the decoration 
    */
    function setDecoration(
        string memory _URI,
        uint256 _tokenId
    )
        external
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not the token owner");
        require(_exists(_tokenId), "Set decoration query for nonexistent token");
        decoration[_tokenId] = _URI;
    }

    /*
     * Set the second decoration 
    */
    function setSecDecoration(
        string memory _URI,
        uint256 _tokenId
    )
        external
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not the token owner");
        require(_exists(_tokenId), "Set second decoration query for nonexistent token");
        secDecoration[_tokenId] = _URI;
    }

    /*
     * Set the voice 
    */
    function setVoice(
        string memory _URI,
        uint256 _tokenId
    )
        external
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "Not the token owner");
        require(_exists(_tokenId), "Set voice query for nonexistent token");
        voice[_tokenId] = _URI;
    }
    

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    */
    function tokenURI(
        uint256 _tokenId
    )
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!reveal) {
            return string(abi.encodePacked(blindURI));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        }
    }

    /*
     * Function to get token's decorations and voice
    */
    function tokenDataURI(
        uint256 _tokenId
    )
        public 
        view  
        returns (string[3] memory) 
    {
        require(_exists(_tokenId));
        if (reveal) {
            return [decoration[_tokenId], secDecoration[_tokenId], voice[_tokenId]];
        } else {
            return ["","",""]; 
        }
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) 
        public
        view 
        override (ERC721, ERC721Enumerable) 
        returns (bool) 
    {
        return super.supportsInterface(_interfaceId);
    }

    // Standard functions to be overridden 
    function _beforeTokenTransfer(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) 
        internal 
        override(ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}