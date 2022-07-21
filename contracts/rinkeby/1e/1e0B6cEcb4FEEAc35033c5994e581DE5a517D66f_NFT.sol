// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";


//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣫⣿⣿⣿⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⠛⣩⣾⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⡛⠛⠛⠛⠛⠛⠛⢿⢻⣿⡿⠟⠋⣴⣾⣿⣿⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣿⡿⢛⣋⠉⠁⠄⢀⠠⠄⠄⠄⠈⠄⠋⡂⠠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣛⣛⣉⠄⢀⡤⠊⠁⠄⠄⠄⢀⠄⠄⠄⠄⠲⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⡿⠟⠋⠄⠄⡠⠊⠄⠄⠄⠄⠄⣀⣼⣤⣤⣤⣀⠄⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⠛⣁⡀⠄⡠⠄⠄⠄⠄⠄⠄⢠⣿⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⠿⢟⡉⠰⠁⠄⠄⠄⠄⠄⠄⠄⠙⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⡇⠄⠄⠙⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠉⠉⠛⠛⠛⠻⢿⣿⣿⣿⣿
//    ⣇⠄⢰⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠻⣿⣿
//    ⣿⠄⠈⠻⣦⣤⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣦⠙⣿
//    ⣿⣄⠄⠚⢿⣿⡟⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⣿⣧⠸
//    ⣿⣿⣆⠄⢸⡿⠄⠄⢀⣴⣿⣿⣿⣿⣷⣶⣶⣶⣶⠄⠄⠄⠄⠄⠄⢀⣾⣿⣿⠄
//    ⣿⣿⣿⣷⡞⠁⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠄⠄⣠⣾⣿⣿⣿⣿⢀
//    ⣿⣿⣿⡿⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠄⠄⠘⣿⣿⡿⠟⢃⣼
//    ⣿⣿⠏⠄⠠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⢀⡠⢄⡠⡭⠄⣠⢠⣾⣿
//    ⠏⠄⠄⣸⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠄⢀⣦⣒⣁⣒⣩⣄⣃⢀⣮⣥⣼⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿





contract NFT is ERC721A, Ownable  {
    using Strings for uint256;

    uint256 public maxSupply = 5000;
    uint256 public cost = 0.005 ether;
    uint256 public discount = 50;
    uint256 public maxMintPerAddressLimit = 10;
    uint256 public maxMintAmountPerTx = 10;

    bytes32 public merkleRootFree;
    bytes32 public merkleRootDiscounted;

    string public baseURI;
    string public notRevealedUri;

    bool public pausedPublic = false;
    bool public pausedWL = false;
    bool public revealed = false;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount! (max 10)");
        require(quantity + _numberMinted(msg.sender) <= maxMintPerAddressLimit, "Exceeded the limit by user");
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");

        if (msg.sender != owner()) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            if(MerkleProof.verify(_merkleProof, merkleRootFree, leaf)){
                require(!pausedWL, "The wl minting is paused");
            } else if(MerkleProof.verify(_merkleProof, merkleRootDiscounted, leaf)){
                require(!pausedWL, "The wl minting is paused");
                uint discountedCost = (cost * quantity) - ((cost * quantity * discount) / 100);
                require(msg.value >= discountedCost);
            } else {
                require(!pausedPublic, "The public minting is paused");
                require(msg.value >= cost * quantity);
            }
        }

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return string(abi.encodePacked(notRevealedUri, tokenId.toString(), ".json"));
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    }

//    function airdrop(IERC721A _token, address[] calldata _to, uint256[] calldata _id) public onlyOwner{
//        require(_to.length == _id.length, "the length of ids and recepients differ");
//
//        for(uint256 i = 0; i < _to.length; i++){
//            _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
//        }
//    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRootFree(bytes32 newMerkleRootFree) public onlyOwner {
        merkleRootFree = newMerkleRootFree;
    }

    function setMerkleRootDiscounted(bytes32 newMerkleRootDiscounted) public onlyOwner {
        merkleRootDiscounted = newMerkleRootDiscounted;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmountPerTx(uint256 newMaxMintAmount) public onlyOwner {
        maxMintAmountPerTx = newMaxMintAmount;
    }

    function setMaxMintPerAddressLimit(uint256 newNftPerAddressLimit) public onlyOwner {
        maxMintPerAddressLimit = newNftPerAddressLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setDiscount(uint newDiscount) public onlyOwner {
        discount = newDiscount;
    }

    function pausePublicMint(bool _state) public onlyOwner {
        pausedPublic = _state;
    }

    function pauseWlMint(bool _state) public onlyOwner {
        pausedWL = _state;
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
}