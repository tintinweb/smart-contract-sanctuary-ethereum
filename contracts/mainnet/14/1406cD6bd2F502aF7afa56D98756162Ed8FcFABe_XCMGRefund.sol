/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

pragma solidity 0.8.18;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


contract XCMGRefund {
    mapping(uint256 => address) public tokenIdAddrMap;
    mapping(uint256 => bool) public isRefund;
    uint256 public tokenRefundPrice;
    
    IERC721 public nftContract;
    address public nftReceiver;
    address private owner;
    
    uint256 public refundStartTime = 1686549600;
    uint256 public refundEndTime = 1686636000;

    constructor(
        address _nftContract
    ) {
        nftContract = IERC721(_nftContract);
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner,"NOT OWNER");
        _;
    }

    modifier isProcess() {
        require(block.timestamp >= refundStartTime &&  block.timestamp <= refundEndTime,"Not in the refund process");
        _;
    }

    event Refund(address account, uint256 tokenId, uint256 price);

    fallback() external payable {}
    receive() external payable {}

    function setTime(uint256 start, uint256 end) external isOwner{
        require(end > start, "TIME INVALID");

        refundStartTime = start;
        refundEndTime = end;
    }

    function setTokenIdMap(uint256[] memory tokenIds, address[] memory addrs) external isOwner{
        require(tokenIds.length == addrs.length,"PARAM INVALID");
        for(uint256 i = 0; i<tokenIds.length;i++) {
            tokenIdAddrMap[tokenIds[i]] = addrs[i];
        }
    }

    function setPriceAndNftReceiver(uint256 _price, address _receiver) external isOwner {
        tokenRefundPrice = _price;
        nftReceiver = _receiver;
    }

    function withLeftOverFund() external isOwner {
        uint256 currentBalance = address(this).balance;
        require(currentBalance > 0, "Current balance is zero");
        payable(owner).transfer(currentBalance);
    }

    function refund(uint256 tokenId) public isProcess {
        require(nftContract.ownerOf(tokenId) == msg.sender, "TokenId Not Belong to you");
        require(msg.sender == tokenIdAddrMap[tokenId], "Address corresponding to tokenId is incorrect");
        require(isRefund[tokenId] == false, "TokenId Already Refunded");
        
        nftContract.safeTransferFrom(msg.sender, nftReceiver, tokenId);

        isRefund[tokenId] = true;
        
        require(address(this).balance >= tokenRefundPrice, "Insufficient contract balance");
        payable(msg.sender).transfer(tokenRefundPrice);

        emit Refund(msg.sender, tokenId, tokenRefundPrice);
    }

    function batchRefund(uint256[] memory tokenIds) external {
        for(uint256 i = 0; i<tokenIds.length; i++) {
            refund(tokenIds[i]);
        }
    }
}