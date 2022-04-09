/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Lending {

    enum AssetType{ERC1155, ERC721}

    address public owner;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    uint256 public totalNumLoans;

    uint256 public totalActiveLoans;

    uint256 public adminFee = 100;

    mapping(uint256 => LoanDetails) public loan;
    mapping(uint256 => bool) public loanIdStatus;
    mapping(uint256 => bool) public loanRepaidOrLiquidated;

    mapping(uint256 => bool) private usedNonce;

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;        
    }

    struct Order {
        address borrower;
        address lender;
        address erc20Address;
        address nftAddress;
        AssetType nftType;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
        uint256 loanDuration;
        uint256 interestRateDuration;
    }

    struct LoanDetails {
        uint256 loanId;
        address nftAddress;
        AssetType nftType;
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 loanPrincipalAmount;
        uint256 loanRepaymentAmount;
        uint256 loanStartTime;
        uint256 loanDuration;
        address loanERC20Address;
        uint256 qty;
        uint256 aFee;
        uint256 loanInterestForDuration;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: owner sign verification failed");
        _;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }

    function verifyLenderSign( address lender, address borrower, address nftAddress, uint256 tokenId, uint256 amount, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, lender, borrower, tokenId, nftAddress, amount, sign.nonce));
        require(lender == getSigner(hash, sign), "lender sign verification failed");
    }

    function verifySign(uint256 tokenId, address caller, Sign memory sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, caller, tokenId, sign.nonce));
        require(owner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function inititateLending(Order memory order, Sign memory sign) external returns(bool){
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifyLenderSign(order.lender, msg.sender, order.nftAddress, order.tokenId, order.amount, sign);

        totalNumLoans += 1;
        order.loanDuration = order.loanDuration * 1 days;
        uint256 interestForAdmin = order.amount * (adminFee) / 1000;
        uint256 interestForBorrowerDuration = order.amount *  order.interestRateDuration / 1000;
        uint256 interest = interestForAdmin + interestForBorrowerDuration;
        uint256 id = totalNumLoans;

        LoanDetails memory details = LoanDetails({
            loanId: id,
            nftAddress: order.nftAddress,
            nftType: order.nftType,
            tokenId: order.tokenId,
            borrower: msg.sender,
            lender: order.lender,
            loanPrincipalAmount: order.amount,
            loanRepaymentAmount: order.amount + interest,
            loanStartTime: block.timestamp,
            loanDuration: order.loanDuration,
            loanERC20Address: order.erc20Address,
            qty: order.qty,
            aFee: adminFee,
            loanInterestForDuration: order.interestRateDuration
        });

        loan[id] = details;
        loanIdStatus[id] = true;
        totalActiveLoans += 1;

        if(order.nftType == AssetType.ERC721) { 
            IERC721(order.nftAddress).safeTransferFrom(order.borrower, address(this), order.tokenId);
        }
        if(order.nftType == AssetType.ERC1155) {
            IERC1155(order.nftAddress).safeTransferFrom(order.borrower, address(this), order.tokenId, order.qty, "");
        }
        if(order.amount > 0){
            IERC20(order.erc20Address).transferFrom(order.lender, order.borrower, order.amount);
        }

        return true;
    }

    function loanRepayment(uint256 _loanId, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_loanId, msg.sender, sign);
        require(loanIdStatus[_loanId], "Invalid loanId");
        require(!loanRepaidOrLiquidated[_loanId], "Loan has been already repaid or liquidated");

        uint256 timeDiff = block.timestamp - loan[_loanId].loanStartTime;

        uint256 interestDue = calculateInterest(loan[_loanId].loanPrincipalAmount, loan[_loanId].loanRepaymentAmount, timeDiff, loan[_loanId].loanDuration, loan[_loanId].loanInterestForDuration);

        if(interestDue > 0) {
            uint256 amount = interestDue + loan[_loanId].loanPrincipalAmount;
            IERC20(loan[_loanId].loanERC20Address).transferFrom(loan[_loanId].borrower, loan[_loanId].lender, amount);
        }

        if(loan[_loanId].nftType == AssetType.ERC721) { 
            IERC721(loan[_loanId].nftAddress).safeTransferFrom(address(this), loan[_loanId].borrower, loan[_loanId].tokenId);
        }
        if(loan[_loanId].nftType == AssetType.ERC1155) {
            IERC1155(loan[_loanId].nftAddress).safeTransferFrom(address(this), loan[_loanId].borrower, loan[_loanId].tokenId, loan[_loanId].qty, "");
        }

        loanRepaidOrLiquidated[_loanId] = true;
        loanIdStatus[_loanId] = false;
        totalActiveLoans -= 1;
        delete loan[_loanId];
        return true;
    }

    function loanOverdue(uint256 _loanId, Sign memory sign) external returns(bool) {

        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_loanId, msg.sender, sign);

        require(loanIdStatus[_loanId],"Invalid LoanId");
        require(!loanRepaidOrLiquidated[_loanId], "Loan has been already repaid or liquidated");
        uint256 loanMaturityDate = loan[_loanId].loanStartTime + loan[_loanId].loanDuration;
        require(block.timestamp < loanMaturityDate, "loan not overdue yet");
        
        if(loan[_loanId].nftType == AssetType.ERC721) {
            IERC721(loan[_loanId].nftAddress).safeTransferFrom(address(this), loan[_loanId].lender, loan[_loanId].tokenId);
        }

        if(loan[_loanId].nftType == AssetType.ERC1155) {
            IERC1155(loan[_loanId].nftAddress).safeTransferFrom(address(this), loan[_loanId].lender, loan[_loanId].tokenId, loan[_loanId].qty, "");
        }

        totalActiveLoans -= 1;
        delete loan[_loanId];
        loanIdStatus[_loanId] = false;
        loanRepaidOrLiquidated[_loanId] = true;
        
        return true;
    }

    function calculateInterest(uint256 amount, uint256 repaymentAmount, uint256 timeDiff, uint256 loanDuration, uint256 interestRate) internal pure returns(uint256) {
        uint256 interestForDuration = amount *  interestRate / 1000;
        uint256 interestForCurrent = interestForDuration * timeDiff / loanDuration;
        if(amount + interestForCurrent >= repaymentAmount) {
            uint256 lendingInterest = repaymentAmount - amount;
            return lendingInterest;
        }
        return interestForCurrent;
    }

    function getInterest(uint256 _loanId) external view returns(uint256) {
        uint256 timeDiff = block.timestamp - loan[_loanId].loanStartTime;
        uint256 interestDue = calculateInterest(loan[_loanId].loanPrincipalAmount, loan[_loanId].loanRepaymentAmount, timeDiff, loan[_loanId].loanDuration, loan[_loanId].loanInterestForDuration);
        uint256 amount = loan[_loanId].loanPrincipalAmount + interestDue;
        return amount;
    }

    function setAdminFee(uint256 fee) external onlyOwner returns(bool) {
        require(fee >= 0, "Fee must be greater than zero");
        adminFee = fee;
        return true;
    }

    function getUserDetails(uint256 _loanId) external view returns(LoanDetails memory) {
        return loan[_loanId];
    }

    function onERC721Received( address, address, uint256, bytes calldata /*data*/) external pure returns(bytes4) {
        return _ERC721_RECEIVED;
    }
    
    function onERC1155Received( address /*operator*/, address /*from*/, uint256 /*id*/, uint256 /*value*/, bytes calldata /*data*/ ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}