//SPDX-License-Identifier: CC0
pragma solidity ^0.8.12;

// Name: Kinetic Spectrum Minter
// Description: Contract that mints tokens and store seeds
// Twitter: @KineticSpectrum
// Design: biron.eth
// Buidl: himlate.eth
//_______________________________________________________________________________________________________________________________________
//_____/\\\\\\\\\\\______________________________________________________________________________________________________________________
//____/\\\/////////\\\___________________________________________________________________________________________________________________
//____\//\\\______\///____/\\\\\\\\\___________________________________/\\\______________________________________________________________
//______\////\\\__________/\\\/////\\\_____/\\\\\\\\______/\\\\\\\\__/\\\\\\\\\\\__/\\/\\\\\\\___/\\\____/\\\____/\\\\\__/\\\\\__________
//__________\////\\\______\/\\\\\\\\\\____/\\\/////\\\___/\\\//////__\////\\\////__\/\\\/////\\\_\/\\\___\/\\\__/\\\///\\\\\///\\\_______
//_______________\////\\\___\/\\\//////____/\\\\\\\\\\\___/\\\____________\/\\\______\/\\\___\///__\/\\\___\/\\\_\/\\\_\//\\\__\/\\\_____
//________/\\\______\//\\\__\/\\\_________\//\\///////___\//\\\___________\/\\\_/\\__\/\\\_________\/\\\___\/\\\_\/\\\__\/\\\__\/\\\_____
//________\///\\\\\\\\\\\/___\/\\\__________\//\\\\\\\\\\__\///\\\\\\\\____\//\\\\\___\/\\\_________\//\\\\\\\\\__\/\\\__\/\\\__\/\\\____
//___________\///////////_____\///____________\//////////_____\////////______\/////____\///___________\/////////___\///___\///___\///____
//_______________________________________________________________________________________________________________________________________
//_______________________________________________________________________________________________________________________________________
//_______________________________________________________________________________________________________________________________________

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Utils.sol";
import "./SpectrumGeneratorInterface.sol";

contract KineticSpectrum is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SPECTRUMS = 1111;
    uint256 public constant MAX_FOUNDER = 20;
    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant FRIENDS_PRICE = 0.02 ether;

    bool public isFriendSale = false;
    bool public isPublicSale = false;

    bytes32 private root;

    mapping(uint256 => uint256) public seeds;
    mapping(address => uint256) public mintedAddress;
    mapping(address => bool) public founders;

    SpectrumGeneratorInterface public spectrumGenerator;

    constructor(SpectrumGeneratorInterface _spectrumGenerator)
        ERC721A("Kinetic Spectrum", "SPCTR")
    {
        spectrumGenerator = _spectrumGenerator;
    }

    function _createSeed(uint256 _tokenId, address _address)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _tokenId,
                        _address,
                        utils.getRandomInteger("spectrum", _tokenId, 0, 42069),
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < _totalMinted(), "TokenId not yet minted");
        return spectrumGenerator.tokenURI(_tokenId, seeds[_tokenId]);
    }

    function mint(uint256 _q) external payable nonReentrant {
        require(isPublicSale, "Sale has not started");
        require(_q > 0, "You should mint one");
        require(_currentIndex <= MAX_SPECTRUMS, "All metavatars minted");
        require(
            _currentIndex + _q <= MAX_SPECTRUMS,
            "Minting exceeds max supply"
        );
        require(PRICE * _q <= msg.value, "Min 0.03eth per Spectrum");
        uint256 currentTokenId = _currentIndex;

        _safeMint(msg.sender, _q);
        mintedAddress[msg.sender] += _q;

        for (uint8 i = 0; i < _q; i++) {
            seeds[currentTokenId] = _createSeed(currentTokenId, msg.sender);

            currentTokenId++;
        }
    }

    function friendMint(uint256 _q, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        require(isFriendSale, "Sale has not started or has finished");
        require(_q > 0, "You should mint one");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "This address is not in friendlist"
        );
        require(_currentIndex <= MAX_SPECTRUMS, "All metavatars minted");
        require(
            _currentIndex + _q <= MAX_SPECTRUMS,
            "Minting exceeds max supply"
        );
        require(FRIENDS_PRICE * _q <= msg.value, "Min 0.02eth per Spectrum");

        uint256 currentTokenId = _currentIndex;

        _safeMint(msg.sender, _q);
        mintedAddress[msg.sender] += _q;

        for (uint8 i = 0; i < _q; i++) {
            seeds[currentTokenId] = _createSeed(currentTokenId, msg.sender);

            currentTokenId++;
        }
    }

    function foundersMint(uint256 _q) external payable nonReentrant {
        require(founders[msg.sender], "You are not a founder");
        require(_currentIndex <= MAX_SPECTRUMS, "All metavatars minted");
        require(
            _currentIndex + _q <= MAX_SPECTRUMS,
            "Minting exceeds max supply"
        );
        require(mintedAddress[msg.sender] + _q <= MAX_FOUNDER, "Max reached");
        uint256 currentTokenId = _currentIndex;

        _safeMint(msg.sender, _q);
        mintedAddress[msg.sender] += _q;

        for (uint8 i = 0; i < _q; i++) {
            seeds[currentTokenId] = _createSeed(currentTokenId, msg.sender);

            currentTokenId++;
        }
    }

    function airdrop(address _address) external onlyOwner {
        require(_currentIndex <= MAX_SPECTRUMS, "All metavatars minted");
        require(
            _currentIndex + 1 <= MAX_SPECTRUMS,
            "Minting exceeds max supply"
        );
        seeds[_currentIndex] = _createSeed(_currentIndex, msg.sender);
        mintedAddress[_address] += 1;
        _safeMint(_address, 1);
    }

    function addFounder(address _address) external onlyOwner {
        founders[_address] = true;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function startFriendSale() external onlyOwner {
        isFriendSale = true;
    }

    function stopFriendSale() external onlyOwner {
        isFriendSale = false;
    }

    function startPublicSale() external onlyOwner {
        isPublicSale = true;
    }

    function stopPublicSale() external onlyOwner {
        isPublicSale = false;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setGenerator(SpectrumGeneratorInterface _spectrumGenerator)
        external
        onlyOwner
    {
        spectrumGenerator = _spectrumGenerator;
    }
}