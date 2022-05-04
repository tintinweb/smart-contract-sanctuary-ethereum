/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract Owner {
    address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    function getOwner() external view returns (address) {
        return owner;
    }
}
contract LendMyNFT is Owner{

    IERC721 public nft;
    IERC20 usdc;

    constructor () {
        usdc = IERC20(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);

    }
    uint8 interest;    
    uint256 loanId;
    uint256 lastCheckedId;
    mapping (uint256 => Collateral) stake;  // tokenid to Collateral
    mapping (uint256 => Loan) loans;    // loanId to Loan
    mapping(uint256 => bool) npa;   // loanId to overdue status
    event Loans(address Borrower, uint256 LoanId);
    struct Collateral {
        IERC721 nftAddress;
        uint256 price ; // in wei

    }
    struct Loan {
        uint32 startTime;
        uint32 endTime;
        uint8 rate; // per annum
        uint256 principal;
        uint256 tokenId;
        bool isActive;
        
    }
    function setInterestRate(uint8 _rate) public isOwner {
        interest = _rate;
    }
    function viewInterestRate() public view returns(uint8){
        return interest;
    }
    function _generateCollateral(IERC721 _nft, uint256 _tokenId, uint256 _price) internal {
        nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "Only owner of NFT can collateralize");
        stake[_tokenId] = Collateral( nft,_price);
    }
    function borrow (IERC721 _nft,uint256 _tokenId, uint256 _price, uint32 _endTime) public returns(uint256 LoanId) {
        _generateCollateral(_nft,_tokenId,_price);
        uint256 weiAmount = stake[_tokenId].price *70/100;
        require(usdc.balanceOf(address(this))>=weiAmount, "Error :: Not enough balance USDC to lend");
        nft.safeTransferFrom(msg.sender,address(this),_tokenId);
        usdc.transfer(msg.sender,weiAmount);
        loanId++;
        loans[loanId] = Loan(uint32(block.timestamp),_endTime,interest,weiAmount,_tokenId,true);
        npa[loanId] = false;
        emit Loans(msg.sender,loanId);
        return loanId;
    }
    function viewLoan(uint256 _loanId)public view returns(uint32,uint256,uint256,bool){
        return (loans[_loanId].endTime,loans[_loanId].principal,loans[_loanId].tokenId,loans[_loanId].isActive );
    }
    function rePay(uint256 _loanId) public {
        require(block.timestamp<loans[_loanId].endTime, "Error: Repayment time expired");
        nft = stake[_loanId].nftAddress;
        uint32 elapsedTime = uint32(block.timestamp) - loans[_loanId].startTime;
        uint256 rePayAmount = loans[_loanId].principal + loans[_loanId].principal*loans[_loanId].rate * elapsedTime/(60*60*24*365*100);
        usdc.transferFrom(msg.sender, address(this), rePayAmount);
        nft.setApprovalForAll(address(this),true);
        nft.safeTransferFrom(address(this), msg.sender, loans[_loanId].tokenId);
        loans[_loanId].isActive = false;
    }
    function _assignAsNPA(uint256 _loanId) internal returns(bool) {
        require(loans[_loanId].isActive && loans[_loanId].endTime<block.timestamp, "This is not a NPA yet");
        npa[_loanId] = true;
        return true;
    }
    function assignAllNPA() public {
        
        for(uint256 i = lastCheckedId; i<=loanId;i++){
            if(loans[i].isActive = true){
                if(loans[i].endTime<block.timestamp){
                npa[i] = true;
                }
            }
            
        }
        lastCheckedId = loanId;
    }
    function listNPA(uint256 _noOffResults) public view returns(uint256[] memory){
        uint k;
        uint256[] memory npas = new uint256[](_noOffResults);
        for(uint i=1;i<=loanId;i++){
            if(k<=_noOffResults){
                if(npa[i] == true){
                npas[k] = i;
                k++;
                }
            }
            
        }
        return npas;
    }
    function liquidateNPA(uint256 _loanId) public {
        require(npa[_loanId] || _assignAsNPA(_loanId), "This is not a Non Performing Asset" );
        uint32 elapsedTime = uint32(block.timestamp) - loans[_loanId].startTime;
        uint256 rePayAmount = loans[_loanId].principal + loans[_loanId].principal*loans[_loanId].rate * elapsedTime/(60*60*24*365*100);
        usdc.transferFrom(msg.sender, address(this), rePayAmount);
        nft = stake[_loanId].nftAddress;
        nft.setApprovalForAll(address(this),true);
        nft.safeTransferFrom(address(this), msg.sender, loans[_loanId].tokenId);
        loans[_loanId].isActive = false;
        npa[_loanId] = false;
    }

}