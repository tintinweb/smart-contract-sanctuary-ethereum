/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// File: contracts/LibBoxInfo.sol


pragma solidity 0.8.15;
library LibBoxInfo{
    struct BoxInfo{
        uint256 boxId;
        uint256 totalSupply;
        uint256 price;
        uint256 totalMint;
        uint256 startTime;
        uint256 endTime;
        uint256 mintLimitPerBoxInfo;
        uint256 mintLimitPerTransaction;
        string baseURI; //end with "/"
        uint256[] boxHashList;
        bool onlyWhiteList;
        bool pause;
        bool close;
    }
}
// File: contracts/SPromotion.sol


pragma solidity 0.8.15;

interface INft{
    function getBoxInfo(uint256 boxId) external returns(LibBoxInfo.BoxInfo memory);
}

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

    function getAddressMintList() external view returns (address[] memory){
        return addressMintLists;
    }

    function getTotalMintPerAddress(address minterAddress, uint256 boxId) external view returns (uint256) {
        return adrressToBoxIdMintCount[minterAddress][boxId];
    }

    function promotionMint(uint256 quantity,uint256 boxId) external onlyNFT {
        require(nftAddress != address(0), "NFT address not yet set");
        if(adrressToBoxIdMintCount[tx.origin][boxId] == 0){
            addressMintLists.push(tx.origin);
        }
        adrressToBoxIdMintCount[tx.origin][boxId]  += quantity;
    }

    //condition in NFT contract
    function isMintAble(uint256 boxId, uint256 quantity) external returns (bool,string memory) {
        LibBoxInfo.BoxInfo memory boxInfoTemp = INft(nftAddress).getBoxInfo(boxId);
        if(boxInfoTemp.close){
            return (false, "Can't mint anymore this box already close!");
        }
        if(boxInfoTemp.pause){
            return (false, "Can't mint this box was pause!");
        }
        if(boxInfoTemp.boxHashList.length < quantity){
            return (false, "Hash of box is not enough for mint!");
        }
        if(boxInfoTemp.totalMint + quantity > boxInfoTemp.totalSupply){
            return (false, "Box : Sold out!");
        }
        if(block.timestamp < boxInfoTemp.startTime || block.timestamp > boxInfoTemp.endTime){
            return (false, "Can't mint now!");
        }
        if(adrressToBoxIdMintCount[msg.sender][boxId] + quantity > boxInfoTemp.mintLimitPerBoxInfo){
            return (false, "Can't mint more than mint limit per box info!");
        }
        if(quantity > boxInfoTemp.mintLimitPerTransaction){
            return (false, "Can't mint more than mint limit per transaction!");
        }
        
        return (true,"PASS");
    }
}