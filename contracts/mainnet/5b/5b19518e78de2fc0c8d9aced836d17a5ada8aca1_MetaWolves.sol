// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

    contract MetaWolves is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    uint64 private premintStageMinted = 0;
    uint64 private premintStageLimitPerWallet = 30;
    uint64 private premintStageTotalSupplyLimit = 2500;
    uint64 public premintStagePrice = 0.2 ether;

    uint128 private publicMintStageLimitPerWallet = 30;
    uint128 public publicMintStagePrice = 0.22 ether;

    uint128 public TotalSupply = 9999; //tokenID should be <= TotalSupply

    string public baseURI;
    string public notRevealedUri =
        "https://gateway.pinata.cloud/ipfs/QmVtQWaJWrJ2Tq9E9MS7MGtUGhFi4AM33FQEQUezWLFxzk";

    mapping(address => uint256) private premintStageMintedInWallet;
    mapping(address => uint256) private publicStageMintedInWallet;

    mapping(uint256 => address) private tokenID2Owner;

    mapping(address => bool) private premintStageWhiteListed;

    bool public isPremintStageActive = false;
    bool public isPublicMintStageActive = false;
    bool public revealed = false;

    constructor() ERC721("MetaWolves", "MW") {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updatePremintStagePrice(uint64 _newPrice) external onlyOwner {
        premintStagePrice = ((1 / 1000) * 1 ether * _newPrice);
    }

    function updatePublicMintStagePrice(uint128 _newPrice) external onlyOwner {
        publicMintStagePrice = ((1 / 1000) * 1 ether * _newPrice);
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

    function updateTotalSupply(uint64 _totalSupplyLimit) external onlyOwner {
        TotalSupply = _totalSupplyLimit;
    }

    function togglePremintStage() external onlyOwner {
        isPremintStageActive = (!isPremintStageActive);
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
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenID.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function batchMint(uint256 _batchSize) internal returns (uint256[] memory) {
        uint256[] memory returnTokensBM = new uint256[](_batchSize);
        uint256 numberMinted = 0;
        while (numberMinted < _batchSize) {
            if (tokenID2Owner[_tokenIdCounter.current()] != address(0)) {
                _tokenIdCounter.increment();
                continue;
            } else {
                returnTokensBM[numberMinted] = _tokenIdCounter.current();
                numberMinted++;
                
                mintMetaWolf(_tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
        return returnTokensBM;
    }

    function batchPremint(uint256 _batchSize)
        public
        payable
        whenNotPaused
        returns (uint256[] memory)
    {
        require(_batchSize > 0, "Mint at least 1");
        require(isPremintStageActive, "isPremintStage not active");
        require(
            premintStageWhiteListed[msg.sender] == true,
            "User not Whitelisted for preMint"
        );
        require(
            (premintStageMintedInWallet[msg.sender] + _batchSize) <=
                premintStageLimitPerWallet,
            "Batch exceeds Premint Limit/Wallet"
        );
        require(
            (premintStageMinted + _batchSize) < premintStageTotalSupplyLimit,
            "Batch exceeds Premint Supply"
        );
        require(
            msg.value == (premintStagePrice * _batchSize),
            "Incorrect Price"
        );

uint256[] memory returnTokens = new uint256[](_batchSize);
        returnTokens = batchMint(_batchSize);

        premintStageMintedInWallet[msg.sender] += _batchSize;
        premintStageMinted += uint64(_batchSize);
        require(
            premintStageMinted < premintStageTotalSupplyLimit,
            "Try Minting Fewer"
        );
        return returnTokens;
    }

    function batchPublicMint(uint256 _batchSize)
        public
        payable
        whenNotPaused
        returns (uint256[] memory)
    {
        require(_batchSize > 0, "Mint at least 1");
        require(isPublicMintStageActive, "Public Mint not active");

        require(
            (publicStageMintedInWallet[msg.sender] + _batchSize) <
                publicMintStageLimitPerWallet,
            "Batch exceeds Public Mint Limit/Wallet"
        );
        require(
            msg.value == (publicMintStagePrice * _batchSize),
            "Incorrect Price"
        );

       uint256[] memory returnTokens = new uint256[](_batchSize);
       returnTokens = batchMint(_batchSize);

        publicStageMintedInWallet[msg.sender] += _batchSize;
        return returnTokens;
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


function batchOwnerMintMetaWolf(uint _batchSize)
public
payable
onlyOwner
returns (uint256[] memory)
{
    uint256[] memory returnTokens = new uint256[](_batchSize);
       return returnTokens = batchMint(_batchSize);

}


    function mintMetaWolf(uint256 _tokenID) private {
        require(_tokenID <= TotalSupply, "Total Supply Exhausted");
        tokenID2Owner[_tokenID] = msg.sender;
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