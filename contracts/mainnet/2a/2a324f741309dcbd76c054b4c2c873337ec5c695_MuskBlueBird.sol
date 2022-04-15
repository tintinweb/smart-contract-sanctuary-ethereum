//         ,  . , * ..,. ,, ,  ...  ...        ,*.,....    , .. /      ..,
//         ,  . , * .,,. ,, , ...,  .,.        ,*.,.///////////////////..,.
//         ,  . , * .,,. ,, , ...,  ...        ,*/////////////////////////.
//         ,  . , * .,,. ,, , ...,  .,.       ./////////////////////////////
//         ,  . , * ..,. ,, , ....  ...      ////////////////////////////////
//         , /////////////////////  .,.    ///////////////////////////////////
//  ... ...///////////////////////////// .///////////////////////// .&  ./////.....
//           .//////////////////////////////////////////////////////  ( ///////, ,*
//           /////////////////////////////////////////////////////////////////////,
//   .        ../////////////////////////////////////////////////////////////////
//   . . .       //////////////////////////////////////////////////////////.*,*
//   . . .,.     . *,/////////////////////////////////////////////////////  ,,*
// .// . .,.  .  .   , //////////////////////////////////////////////////     *
//  ////////* .  . ,..,    /////////////////////////////////////////////
//   //////////////////////////////////////////////////////////////////
//    ////////////////////////////////////////////////////////////////
//     ./////////////////////////////////////////////////////////////
//       //////////////////////////////////////////////////////////
//         ///////////////////////////////////////////////////////
//          ,*//////////////////////////////////////////////////
//          ,,../////////////////////////////////////////////**.
//          ,,., .. //////////////////////////////////////.,.**.
//          ,,.. ..      ////////////////////////////*  . .,.**.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MuskBlueBird is ERC721A, Ownable {
    using Strings for uint256;

    constructor() ERC721A("Musk's Blue Bird", "MuskBlueBird") {}

    mapping(uint256 => bool) private _rewarded100ETH;
    bool public hit100ETH = false;
    uint256 public hit100ETHReward = 0.01 ether;

    mapping(uint256 => bool) private _rewardedSuccessAnd500ETH;
    bool public hitSuccessAnd500ETH = false;
    uint256 public hitSuccessAnd500ETHReward = 0.1 ether;

    uint256 public constant MAX_SUPPLY = 2000;

    uint256 private mintCount = 0;

    uint256 private maxMint = 10;

    uint256 public freeMintAmount = 200;

    uint256 public price = 0.01 ether;

    string private baseTokenURI;

    string public unRevealedURI =
        "https://ipfs.io/ipfs/QmZtBN9eozrmNFZCpWL2EhDY7tFJTizfib4BpuwYdoxorm";

    bool public saleOpen = true;

    bool public revealed = false;

    event Minted(uint256 totalMinted);

    function mint(uint256 _count) external payable {
        uint256 supply = totalSupply();

        require(saleOpen, "Sale is not open yet");
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum supply");
        require(_count > 0, "Minimum 1 NFT has to be minted per transaction");
        require(_count <= 5, "Maximum 5 NFTs can be minted per transaction");
        require(
            numberMinted(msg.sender) + _count <= maxMint,
            "Max mint amount per wallet exceeded."
        );

        if ((mintCount + _count) > freeMintAmount) {
            require(
                msg.value >= price * _count,
                "Ether sent with this transaction is not correct"
            );
        }

        mintCount += _count;
        _safeMint(msg.sender, _count);
        emit Minted(_count);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function reward100ETH(uint256 tokenId) external {
        require(hit100ETH, "Not ready!");
        require(!_rewarded100ETH[tokenId], "Have been rewarded!");
        TokenOwnership memory ownership = ownershipOf(tokenId);
        require(ownership.addr == msg.sender, "Not your bird :)");

        _rewarded100ETH[tokenId] = true;

        (bool success, ) = payable(msg.sender).call{value: hit100ETHReward}("");
        require(success, "Transfer failed.");
    }

    function rewardSuccessAnd500ETH(uint256 tokenId) external {
        require(hitSuccessAnd500ETH, "Not ready!");
        require(!_rewardedSuccessAnd500ETH[tokenId], "Have been rewarded");

        TokenOwnership memory ownership = ownershipOf(tokenId);
        require(ownership.addr == msg.sender, "Not your bird :)");

        _rewardedSuccessAnd500ETH[tokenId] = true;

        (bool success, ) = payable(msg.sender).call{
            value: hitSuccessAnd500ETHReward
        }("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view override returns (uint256) {
        return mintCount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setUnRevealedURI(string memory uri) public onlyOwner {
        unRevealedURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        freeMintAmount = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flip100ETHReward() external onlyOwner {
        hit100ETH = !hit100ETH;
    }

    function flipSuccessAnd500ETH() external onlyOwner {
        hitSuccessAnd500ETH = !hitSuccessAnd500ETH;
    }

    function flipSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 half = balance / 2;

        // dev
        (bool success1, ) = payable(0xEE9824f48998F87fbdAb9241ea612Eb451e70396)
            .call{value: half}("");

        // artist
        (bool success2, ) = payable(0x379af28aD9600Bf07D8a27A592c2e22DCA794eF2)
            .call{value: half}("");

        require(success1, "Transfer failed.");
        require(success2, "Transfer failed.");
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            revealed
                ? string(
                    abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")
                )
                : unRevealedURI;
    }
}