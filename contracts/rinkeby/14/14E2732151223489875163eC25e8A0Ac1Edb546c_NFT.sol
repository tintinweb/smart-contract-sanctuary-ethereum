// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
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
    uint256 public upgradeableCost = 0.005 ether;
    uint256 public discount = 50;
    uint256 public maxMintPerAddressLimit = 10;
    uint256 public maxMintAmountPerTx = 50;

    bytes32 public merkleRootFree;
    bytes32 public merkleRootDiscounted;

    string public notRevealedUri;

    bool public pausedPublic = false;
    bool public pausedWL = false;
    bool public revealed = false;
    address otherContract;

    string [] public collections;
    mapping(uint256 => uint256) public tokenView;
    mapping(uint256 => bool) public upgradeable;

    constructor(
        string memory _name,
        string memory _symbol
//        string memory _initNotRevealedUri,
//        bytes32 _initMerkleRootDiscounted,
//        bytes32 _initMerkleRootFree,
//        address _initOtherAddressContract
    ) ERC721A(_name, _symbol) {
//        setNotRevealedURI(_initNotRevealedUri);
//        setMerkleRootDiscounted(_initMerkleRootDiscounted);
//        setMerkleRootFree(_initMerkleRootFree);
//        setOtherAddressContract(_initOtherAddressContract);
    }

    function _startTokenId() override internal view virtual returns (uint256){
        return 1;
    }

    function mint(uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount! (max 50)");
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");


        if(_merkleProof.length == 0){

            require(!pausedPublic, "Public minting is paused");
            require(msg.value >= cost * quantity, "Not enough ethers paid");

        } else {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            if(MerkleProof.verify(_merkleProof, merkleRootFree, leaf)){
                require(!pausedWL, "WL minting is paused");
                require(quantity + _numberMinted(msg.sender) <= maxMintPerAddressLimit, "Exceeded the limit for wl");
            } else if(MerkleProof.verify(_merkleProof, merkleRootDiscounted, leaf)){
                require(!pausedWL, "WL minting is paused");
                require(quantity + _numberMinted(msg.sender) <= maxMintPerAddressLimit, "Exceeded the limit for wl");
                uint discountedCost = (cost * quantity) - ((cost * quantity * discount) / 100);
                require(msg.value >= discountedCost, "Not enough ethers paid");
            } else {
                require(!pausedPublic, "Public minting is paused");
                require(msg.value >= cost * quantity, "Not enough ethers paid");
            }

        }

        _safeMint(msg.sender, quantity);


        uint256 tokenId = _nextTokenId() - 1;

        (,bytes memory response) = otherContract.staticcall(
            abi.encodeWithSignature("validateToken(uint256)", tokenId)
        );

        bool res = abi.decode(response, (bool));
        if(res){
            tokenView[tokenId] = 1;
            upgradeable[tokenId] = true;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );

        if(revealed == false) {
            return string(abi.encodePacked(notRevealedUri, tokenId.toString(), ".json"));
        }


        return string(abi.encodePacked(collections[tokenView[tokenId]], tokenId.toString(), ".json"));

    }

    function ownerMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");

        _safeMint(msg.sender, quantity);

        uint256 tokenId = _nextTokenId() - 1;

        (,bytes memory response) = otherContract.staticcall(
            abi.encodeWithSignature("validateToken(uint256)", tokenId)
        );

        bool res = abi.decode(response, (bool));
        if(res){
            tokenView[tokenId] = 1;
            upgradeable[tokenId] = true;
        }
    }

    receive() external payable {

    }

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

    function setOtherAddressContract(address _newAddr) public onlyOwner{
        otherContract = _newAddr;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function addCollection(string memory _newCollection) public onlyOwner{
        collections.push(_newCollection);
    }

    function modifyCollection(string memory _modified, uint256 indx) public onlyOwner{
        collections[indx] = _modified;
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

    function upgrade(uint256 tokenId) external payable {
        require(msg.value >= upgradeableCost, "not enough ethers paid");
        upgradeable[tokenId] = true;
        tokenView[tokenId] = 1;
    }

    function switchView(uint256 tokenId, uint256 num) external payable{
        require(num - 1 <= collections.length, "invalid collection number");
        if(num == 1){
            require(upgradeable[tokenId] == true, "token id is not upgraded");
        }
        tokenView[tokenId] = num;
    }
}