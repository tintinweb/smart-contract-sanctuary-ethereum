/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface IERC20Reward {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function mint(address _to, uint256 _tokenId) external;
}

contract Marketplace {

    IERC20Reward immutable private rewardToken;
    IERC721 immutable private nft;
    address immutable public owner;
    address public admin;
    enum Sale { presale, publicsale }
    Sale saleStatus;
    struct SaleInfo {
        uint256 price ;
        uint256 totalSupply;
        uint256 totalSupplied;
    }
    uint256 public constant TOTAL_NFT_SUPPLY = 200;
    SaleInfo preSale;
    SaleInfo publicSale;
    struct mintedInfo {
        uint256 silver;
        uint256 gold;
        uint256 platinum;
        uint256 diamond;
    }
    //for keeping number of mints for each category
    mintedInfo mintedTypeCount;
    //can be used to mint diamond
    mapping (address => mintedInfo) private typeMinted;
    // enum nftType { silver, gold, platinum, diamond }
    // //mapping (tokenId => nftType) which token has what type
    // mapping (uint256 => nftType) nfts;

    //merkle whitelisting
    bytes32 immutable private merkleRoot;
    mapping(address => bool) private claimed;

    constructor(address _rewardToken, address _nft) {
        owner = msg.sender;
        //by default admin is owner
        admin = msg.sender;
        rewardToken = IERC20Reward(_rewardToken);
        nft = IERC721(_nft);
        saleStatus = Sale.presale;
        preSale.price = 50;
        preSale.totalSupply = 50;
        preSale.totalSupplied = 0;
        publicSale.price = 100;
        publicSale.totalSupply = 150;
        publicSale.totalSupplied = 0;
        merkleRoot = 0x09485889b804a49c9e383c7966a2c480ab28a13a8345c4ebe0886a7478c0b73d;
    }

    function getMintedInfo(address user) public view returns (uint256, uint256, uint256, uint256) {
        return (typeMinted[user].silver, typeMinted[user].gold, typeMinted[user].platinum, typeMinted[user].diamond);
    }
    function setAdmin(address _admin) external {
        require(_admin != address(0), "Null address");
        require(msg.sender == owner, "Not owner");
        admin = _admin;
    }

    function switchPresale() private {
        require(msg.sender == admin, "Not Admin");
        saleStatus = Sale.presale;
    }

    function switchPublicsale() private {
        require(msg.sender == admin, "Not Admin");
        saleStatus = Sale.publicsale;
    }

    function getSaleStatus() public view returns (Sale) {
        return saleStatus;
    }

    // function verifyWhitelisted(bytes32[] memory _merkleProof) private view returns (bool){
    //     bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    //     return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    // }

    function getRandomNum(uint256 number) public view returns(uint){
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function mint(address user, uint256 tokenID) public {
        require(nft.balanceOf(msg.sender) < 4, "Cannot mint more that 4 NFTs");
        if(saleStatus == Sale.presale) {
            require(preSale.totalSupplied < preSale.totalSupply, "Pre sale limit full");
            //(verifyWhitelisted(merkleProof) == true, "Address not whitelisted for presale");
            require(rewardToken.balanceOf(msg.sender) >= preSale.price, "Not enough reward tokens");
        }
        else {
            require(publicSale.totalSupplied < publicSale.totalSupply, "public sale limit full");
            require(rewardToken.balanceOf(msg.sender) >= publicSale.price, "Not enough reward tokens");
        }
        uint256 tokenId;
        bool tokenFound;
        while (tokenFound == false) {
            tokenId = getRandomNum(181);
            if (nft.ownerOf(tokenId) == address(0)) {
                if (tokenId <= 60 && mintedTypeCount.silver < 60) {
                    mintedTypeCount.silver += 1;
                    tokenFound = true;
                    typeMinted[msg.sender].silver += 1;
                } else if (tokenId > 60 && tokenId <= 120 && mintedTypeCount.gold < 60) {
                    mintedTypeCount.gold += 1;
                    tokenFound = true;
                    typeMinted[msg.sender].gold += 1;
                } else if (tokenId > 120 && tokenId <= 180 && mintedTypeCount.platinum < 60) {
                    mintedTypeCount.platinum += 1;
                    tokenFound = true;
                    typeMinted[msg.sender].platinum += 1;
                }
            }
        }

        nft.mint(user, tokenID);
    }

    function mintDiamond() public {   
        require(nft.balanceOf(msg.sender) < 4, "Cannot mint more that 4 NFTs");
        require(typeMinted[msg.sender].silver == 1 && typeMinted[msg.sender].gold == 1
        && typeMinted[msg.sender].platinum == 1, "Other categories not Minted");
        require(mintedTypeCount.diamond < 20, "All diamonds already minted");
        uint256 tokenId;
        bool tokenFound;
        while (tokenFound == false) {
            tokenId = getRandomNum(201);
            if (tokenId > 180 && nft.ownerOf(tokenId) == address(0)) {
                mintedTypeCount.diamond += 1;
                tokenFound = true;
                typeMinted[msg.sender].diamond += 1;
            }
        }
        nft.mint(msg.sender, tokenId);
    }
}