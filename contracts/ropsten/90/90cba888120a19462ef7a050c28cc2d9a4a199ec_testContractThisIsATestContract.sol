// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol"; 


contract testContractThisIsATestContract is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    // map Wolf token id to ALL-Wolves

    uint64 private premintStageMinted = 0;
    uint64 private premintStageLimitPerWallet = 1;
    uint64 private premintStageTotalSupplyLimit = 5;
    uint64 public premintStagePrice = 0.002 ether;

    uint64 private celebMintStageMinted = 0;
    uint64 private celebMintStageLimitPerWallet = 3;
    uint64 private celebMintStageTotalSupplyLimit = 5;
    uint64 public celebMintStagePrice = 0 ether;

    uint128 private publicMintStageLimitPerWallet = 3;
    uint128 public publicMintStagePrice = 1 ether;

    uint256 public TotalSupply = 99999; //tokenID should be <= TotalSupply

    string public baseURI;
    string public notRevealedUri = "not revealed yet";

    mapping(address => uint256) private premintStageMintedInWallet;
    mapping(address => uint256) private celebMintStageMintedInWallet;
    mapping(address => uint256) private publicStageMintedInWallet;

    mapping(uint256 => address) private tokenID2Owner;

    mapping(address => bool) private premintStageWhiteListed;
    mapping(address => bool) private celebMintStageWhiteListed;

    bool public isPremintStageActive = false;
    bool public isCelebMintStageActive = false;
    bool public isPublicMintStageActive = false;
    bool public revealed = false;

    constructor() ERC721("Metawolves", "MW") {
        _tokenIdCounter.increment();
    }


 function seedPreMintStageWhiteListed(address[] memory addresses)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      premintStageWhiteListed[addresses[i]] = true;
    }
  }

  function seedCelebMintStageWhiteListed(address[] memory addresses)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      celebMintStageWhiteListed[addresses[i]] = true;
    }
  }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updatePremintStagePrice(uint64 _newPrice) external onlyOwner {
        premintStagePrice = ((1 / 1000) * 1 ether * _newPrice);
    }

    function updateCelebMintStagePrice(uint64 _newPrice) external onlyOwner {
        celebMintStagePrice = ((1 / 1000) * 1 ether * _newPrice);
    }

    function updatePublicMintStagePrice(uint128 _newPrice) external onlyOwner {
        publicMintStagePrice = ((1 / 1000) * 1 ether * _newPrice);
    }

    function updateCelebMintStageLimitPerWallet(uint64 _limitPerWallet)
        external
        onlyOwner
    {
        celebMintStageLimitPerWallet = _limitPerWallet;
    }

    function updatePremintStageLimitPerWallet(uint64 _limitPerWallet)
        external
        onlyOwner
    {
        premintStageLimitPerWallet = _limitPerWallet;
    }

    function updatePublicMintStageLimitPerWallet(uint128 _limitPerWallet)
        external
        onlyOwner
    {
        publicMintStageLimitPerWallet = _limitPerWallet;
    }


    function updatePremintStageTotalSupplyLimit(uint64 _totalSupplyLimit)
        external
        onlyOwner
    {
        premintStageTotalSupplyLimit = _totalSupplyLimit;
    }

     function updateTotalSupply(uint64 _totalSupplyLimit)
        external
        onlyOwner
    {
        TotalSupply = _totalSupplyLimit;
    }

    function updateCelebmintTotalSupplyLimit(uint64 _totalSupplyLimit)
        external
        onlyOwner
    {
        celebMintStageTotalSupplyLimit = _totalSupplyLimit;
    }

function  togglePremintStage() external onlyOwner{
    isPremintStageActive = (!isPremintStageActive);
}

function  toggleCelebmintStage() external onlyOwner{
    isCelebMintStageActive = (!isCelebMintStageActive);
}

function togglePublicmintStage() external onlyOwner {
    isPublicMintStageActive = (!isPublicMintStageActive);
}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reveal() external onlyOwner {
        require(revealed == false, "Already revealed");
        revealed = true;
    }

    function setBaseURI(string calldata _inputBaseURI) external onlyOwner {
        baseURI = _inputBaseURI;
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, _tokenID.toString(), ".json")
                )
                : "";
    }


        function preMint()
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        require(isPremintStageActive, "isPremintStage not active");
        require(
            premintStageWhiteListed[msg.sender] == true,
            "User not Whitelisted for preMint"
        );
        require(
            premintStageMintedInWallet[msg.sender] < premintStageLimitPerWallet,
            "User exceeded Premint Limit/Wallet"
        );
        require(
            premintStageMinted < premintStageTotalSupplyLimit,
            "Premint Supply Exhausted"
        );
        require(msg.value == premintStagePrice, "Incorrect Price");

        uint256 tokenID = regularMint();

        premintStageMintedInWallet[msg.sender]++;
        premintStageMinted++;
        return tokenID;
    }


        function celebMint()
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        require(isCelebMintStageActive, "CelebMintStage not active");
        require(
            celebMintStageWhiteListed[msg.sender] == true,
            "User not Whitelisted for Celeb Mint"
        );
        require(
            celebMintStageMintedInWallet[msg.sender] < premintStageLimitPerWallet,
            "User exceeded Celeb Limit/Wallet"
        );
        require(
            celebMintStageMinted < celebMintStageTotalSupplyLimit,
            "Premint Supply Exhausted"
        );
        require(msg.value == celebMintStagePrice, "Incorrect Price");

        uint256 tokenID = regularMint();

        celebMintStageMintedInWallet[msg.sender]++;
        celebMintStageMinted++;
        return tokenID;
    }

       function publicMint()
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        require(isPublicMintStageActive, "PublicMint not active");
      
        require(
            publicStageMintedInWallet[msg.sender] < publicMintStageLimitPerWallet,
            "User exceeded Limit/Wallet"
        );
 
        require(msg.value == publicMintStagePrice, "Incorrect Price");

        uint256 tokenID = regularMint();

        publicStageMintedInWallet[msg.sender]++;
        return tokenID;
    }

    function ownerMintMetaWolf(uint256 _tokenID)
        public
        payable
        onlyOwner
        returns (uint256)
    {
           require(tokenID2Owner[_tokenID] == address(0), "token already Minted");
        mintMetaWolf(_tokenID);
        return _tokenID;
    }

    function regularMint() internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        while (tokenID2Owner[tokenId] != address(0)) {
            tokenId++;
            _tokenIdCounter.increment();
        }
        _tokenIdCounter.increment();

        mintMetaWolf(tokenId);

        return tokenId;
    }

    function mintMetaWolf(uint256 _tokenID) private {
        require(_tokenID <= TotalSupply, "Total Supply Exhausted");
        _safeMint(msg.sender, _tokenID);
    }

    function transfer(address payable _to, uint256 amount)
        public
        payable
        onlyOwner
    {
        uint256 transferVal = 0;
        if (amount == 0) {
            transferVal = address(this).balance;
        } else {
            transferVal = amount;
        }
        (bool sent, bytes memory data) = _to.call{value: transferVal}("");
        require(sent, "Failed to send Ether");
    }
}