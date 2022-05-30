// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!

    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    The developer will not be responsible or liable for all loss or
    damage whatsoever caused by you participating in any way in the
    experimental code, whether putting money into the contract or
    using the code for your own project.
*/

pragma solidity >=0.7.0 <0.9.0;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";

contract DemoFounders is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.2 ether; //TODO: 2 ETH
    uint256 public maxSupply = 100;
    uint256 preMintQty = 70; // Qty that should be reserved/pre-minted by the contract
    uint256 public maxMintAmountPerTx = 5;

    bool public paused = true; // true on deploy
    bool public revealed = false; //false on deploy

    constructor() ERC721("Demo Founders", "DFNDR") {
        setHiddenMetadataUri("ipfs://__CID__/hidden.json");

        // mint 70 to contract when deployed)
        _mintLoop(address(this), preMintQty);

        //TODO: Should we be minting in constructor like this, or should we have another method [onlyOwner mintToContract(uint256 _qtyToMint)]?
    }

    //TODO: Do I need to be able to freeze metadata?


    function airdropToken(address _receiver) public onlyOwner {
        // check contract owns at least one token
        require(walletOfOwner(address(this)).length >= 1, "Contract does not own enough tokens!");
        // airdrop contracts 1st token to _receiver
        _transfer(address(this), _receiver, walletOfOwner(address(this))[0]);
    }

    function airdropTokens(address[] memory _addresses) public onlyOwner {
        // check number of addreses is <= number of nfts owned by contract
        require(_addresses.length <= walletOfOwner(address(this)).length, "Contract does not own enogh tokens!");
        _airdropLoop(_addresses);
    }

    function _airdropLoop(address[] memory _addresses) internal {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _transfer(address(this), _addresses[i], walletOfOwner(address(this))[i]);
        }
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _mintLoop(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _mintLoop(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}