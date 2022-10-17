/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// File: contracts/SPromotion.sol


pragma solidity 0.8.15;

contract SPromotion{
    address private ownerAddress;
    address private nftAddress;

    address[] public addressMintLists;
    mapping(address => mapping(uint256 => uint256)) private adrressToBoxIdMintCount;


    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner address");
        _;
    }

    modifier onlyNFT() {
        require(msg.sender == nftAddress, "Only NFT address");
        _;
    }

    constructor() {
        ownerAddress = msg.sender;
    }

    function setNFTAddress(address _nftAddress) external onlyOwner{
        nftAddress = _nftAddress;
    }

    function getAddressMintListByPage(uint256 page, uint256 takePerPage) external view returns (address[] memory){
        address[] memory tempAddress;
        for(uint256 i = 0; i < takePerPage;i++){
            tempAddress[i] = addressMintLists[(page*takePerPage)+i];
        }
        return tempAddress;
    }

    function getAddressMintList() external view returns (address[] memory){
        return addressMintLists;
    }

    function getTotalMintPerAddress(address minterAddress, uint256 boxId) external view returns (uint256) {
        return adrressToBoxIdMintCount[minterAddress][boxId];
    }

    function updatePromotionMint(uint256 boxId, uint256 quantity) external onlyNFT {
        require(nftAddress != address(0), "NFT address not yet set");
        adrressToBoxIdMintCount[tx.origin][boxId]  += quantity;
    }

    //condition in NFT contract
    function isMintAble(
        uint256 boxId,
        uint256 totalSupply,
        uint256 totalMint,
        bool close,
        bool pause,
        uint256 hashLength,
        uint256 mintLimitPerTransaction,
        uint256 mintLimitPerBoxInfo,
        uint256 quantity) 
        external view onlyNFT returns (bool,string memory) {
        if(adrressToBoxIdMintCount[tx.origin][boxId]+ quantity > mintLimitPerBoxInfo){
            return (false, "Can't mint more than mint limit per box info!");
        }
        if(close){
            return (false, "Can't mint anymore this box already close!");
        }
        if(pause){
            return (false, "Can't mint this box was pause!");
        }
        if(hashLength < quantity){
            return (false, "Hash of box is not enough for mint!");
        }
        if(totalMint+ quantity > totalSupply){
            return (false, "Box : Sold out!");
        }
        if(quantity > mintLimitPerTransaction){
            return (false, "Can't mint more than mint limit per transaction!");
        }
        return (true,"PASS");
    }
}