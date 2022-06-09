/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

enum LoanMode      { ACTIVE, PAID, USELESS, OUTOFSALE, SOLD, LIQUIDATED }

struct  TLender
{
    address     wallet;
    bool        enabled;
    uint256     fundedAmount;
    uint256     unusedAmount;
    uint256     lentAmount;
    uint256     sideAmount;
    uint256     withdrawnAmount;
    uint256     gainAmount;
    uint32      since;                      // date when this person first used our service
    uint256     hash;
    uint32      index;                      // index in the list of all lenders, for faster tracking
    bool        isAutoLoaning;              // if FALSE, the user does not wish to allow any other automated LOAN with his/her funds
} 

struct  TFund 
{
    address     lenderWallet;
    uint256     amount;
    uint32      timestamp;                  // date when the fund deposit was made
    uint256     hash;
    uint32      lenderId;
}

struct  TWithdraw
{
    address     lenderWallet;
    uint256     lenderIndex;
    uint256     amount;
    uint32      unlockEpoch;
    bool        isDone;                     // default = FALSE . when the ETH payment is done, set to TRY
    uint256     hash;
}

struct  TLoanLenderFund
{
    uint256     totalLoanAmount;
    uint256     lentAmount;
    uint256     interestAmount;
    address     lenderWallet;
    bool        isActive;
    uint256     lenderIndex;
}

struct  TLoan
{
    address     collectionAddress;
    uint256     collectionTokenId;
    address     nftOwnerWallet;
    uint256     durationInSec;
    uint256     until;                  // on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
    uint256     tlvAmount;              // 
    uint256     loanAmount;
    uint256     interestAmount;
    LoanMode    mode;                   
    uint256     resalesPrice;           // HotDeals PRICE : prix a la revente si le NFT a été impayé.
    bool        isSold;                 // was it sold on the marketplace? 
    uint256     soldTimestamp;          // the date when this was sold
    uint256     loanIndex;              // Key index in the loanFunds map
}

struct TNftCollection
{
    address         contractAddress;
    bool            enabled;
}

struct TOperator
{
    address         wallet;
    bool            enabled;
}

//--------------------------------------------------------------------------------
interface iNFT
{
    function ownerOf(uint256 tokenId)                                   external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId)    external;
}
//--------------------------------------------------------------------------------
interface IERC721Receiver
{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//--------------------------------------------------------------------------------
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED     = 2;

    uint256 private _status;

    constructor() 
    {       
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant()         // Prevents a contract from calling itself, directly or indirectly.
    {
        require(_status != _ENTERED, "Reentrant call");    //"ReentrancyGuard: reentrant call");    // On the first call to nonReentrant, _notEntered will be true
        _status = _ENTERED;                                                 // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED;                                             // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
    }
}
//--------------------------------------------------------------------------------
abstract contract Context
{
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    } 
}
//--------------------------------------------------------------------------------
abstract contract Ownable is Context
{
    address private _owner;
    address private _admin;

    event   OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event   AdminChanged(address previousAdmin, address newAdmin);

    constructor ()
    {
        address msgSender = _msgSender();
                   _owner = msgSender;
                   _admin = 0x738C30758b22bCe4EE64d4dd2dc9f0dcCd097229;
                   
        emit OwnershipTransferred(address(0), msgSender);
    }
   
    function admin() public view virtual returns (address)
    {
        return _admin;
    }
   
    function owner() public view virtual returns (address)
    {
        return _owner;
    }
   
    function setAdmin(address newAdmin) public onlyOwner
    {
        address previousAdmin = _admin;
                _admin        = newAdmin;

        emit AdminChanged(previousAdmin, newAdmin);
    }

    modifier onlyOwner()
    {
        require(owner() == _msgSender(),    "Not owner");
        _;
    }
   
    modifier onlyAdminOrOwner()
    {
        require(_msgSender()==owner() || _msgSender()==admin(), "Owner or Admin only");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Bad addr");
       
        emit OwnershipTransferred(_owner, newOwner);
       
        _owner = newOwner;
    }
}
//################################################################################
//################################################################################
//################################################################################
contract ULoanContract     is  Ownable, ReentrancyGuard
{
    constructor()
    {
        serviceWallet = owner();

        operators[owner()] = true;
        registeredOperators[owner()] = 1;
        operatorList.push(owner());

        if (block.chainid==4)
        {
            setOperator(0x4d0463a8B25463cbEcF9F60463362DC9BDCf6E00, true);
            setOperator(0xffFFe388e1e4cFaAB94F0b883d28b8a424Cb45a1, true);
            setOperator(0x8D1296697d93fA30310C390E2825e3b45c3024dc, true);
            setOperator(0xEe5f763b6480EACd4A4Dbc6F551b7734d08de93f, true);
        }
    }

    uint256  private    loanAfterLockingDurationInSec = 0;          // (for V2) une fois que pret est terminé, combien de temps on donne de sursit pour qu'il paye. En V1 : 0 -->  aucun sursit
    uint256  public     marketSalesFeeInM100          = 20 *100;    // Price of resale for NFT which LOAN was not PAID back... 20% in M100 format

    uint256  public     loanableFund                  = 0;          // overalll funds available in the smartcontract to be used for loaning 

    uint256  private    minLenderLockDurationInSec    = 60;
    uint256  private    minFundingInWei               = 0.0001 ether;

    address  private    serviceWallet;
    uint256  public     serviceFeePercentInM100       = 30 * 100;   // ULOAN service fee in Percent (*100)
    uint256  public     interestFeePercentInM100      = (100*100)-serviceFeePercentInM100;

    uint256  public     maxLoanablePercentInM100      = 20*100;

    uint256  public     withdrawLockingDuration       = 30*86400;

    string   private    signHeader                    = "\x19Ethereum Signed Message:\n32";

    mapping(address => bool)            public  operators;                  // operators with their status = enabled / disabled
    mapping(address => uint256)         public  registeredOperators;        // list of existing operators

    mapping(address => bool)            public  registeredNftCollections;
    mapping(address => TNftCollection)  public  nftCollections;

    mapping(address => uint256)         public  registeredLenders;

                        address[]       public  operatorList;
                        TLender[]       public  lenderList;
                        TFund[]         public  lenderFundList;
                        TWithdraw[]     public  withdrawList;
                        TLoan[]         public  loanList;
    
    mapping(uint256 => TLoanLenderFund[])public loanFunds;
    
    mapping(bytes32 => bool)            private proposedHashes;     // used to avoid using the same hash on CreateLoan calls

    mapping(address => mapping(uint256 => bool)) private lentNfts;

    //-----

    event   SetOperator(address wallet, bool newStatus);
    event   LenderFundAdded(    uint256 lenderId, uint256 fundId,     uint256 amount);
    event   LenderWithdrawQuery(uint256 lenderId, uint256 withdrawId, uint256 amount);
    event   FundWithdrawn(      uint256 lenderId, uint256 withdrawId, uint256 amount);

    event   CreateLoanEvent(TLoan loan);
    event   CloseLoan( TLoan loan, uint256 serviceFeeAmount);
    event   SoldOnMarketplace(address previousOwner, address newOwner, uint256 uloanFeeAmount, uint256 reinjectedFundAmount, uint256 newLoanableFund, uint256 previousLoanableFund, TLoan loan);
    event   RemoveLoanFromMarket(uint256 loanId, address to, TLoan loan);
    event   SetLoanAsAHotdeal(uint256 loanId, uint256 newPrice, uint256 oldAmount, TLoan loan);
    event   LiquidLoan(uint256 loanId, uint256 reinjectedAmount, TLoan loan);
    
    event   ChangeLoanPriceOnMarket(uint256 loanId, uint256 newPrice, uint256 oldPrice);

    event   SetServiceWallet(address oldWallet, address newWallet);
    event   SetFees(     uint256 oldFeeInM100, uint256 newFeeInM100);
    event   SetResaleFee(uint256 oldFeeInM100, uint256 newFeeInM100);
    event   SetMaxLoanablePercent(uint256 oldPercentInM100, uint256 newPercentInM100);

    event   SetLenderAutoLoaningMode(uint256 lenderId, bool newAutoLoaningStatus);

    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------

    function    setOperator(address wallet, bool newStatus) public onlyOwner
    {
        require(wallet!=owner() && wallet!=address(0), "Bad wallet");

        if (registeredOperators[wallet]==0)          // Not yet listed
        {
            operatorList.push(wallet);
    
            registeredOperators[wallet] = 1;
        }

        operators[wallet] = newStatus;

        emit SetOperator(wallet, newStatus);
    }
    //-----------------------------------------------------------------------------
    function    listOperators(uint256 indexFrom, uint256 indexTo) external view returns(TOperator[] memory)
    {
        uint256 nOperator  = operatorList.length;

        require(indexFrom<indexTo && indexTo<nOperator, "Bad Range");

        TOperator[] memory collectedOperators = new TOperator[](indexTo - indexFrom + 1);

        uint256 g=0;

        for (uint256 i=0; i<nOperator; i++)
        {
            if (operators[ operatorList[i] ]==false)    continue;

            collectedOperators[g] = TOperator
            (
                operatorList[i],                // ADDRESS
                operators[ operatorList[i] ]    // enabled :true/false  
            );

            g++;
        }

        return collectedOperators;
    }
    //-----------------------------------------------------------------------------
    function    getOperatorCount() external view returns(uint256)
    {
        return operatorList.length;
    }
    //-----------------------------------------------------------------------------
    function    setServiceWallet(address newAddr) external onlyOwner
    {
        address oldWallet = serviceWallet;
        serviceWallet     = newAddr;

        emit SetServiceWallet(oldWallet, newAddr);
    }
    //-----------------------------------------------------------------------------
    function    setFee(uint256 newFeePercentInM100) external onlyOwner
    {
        if (newFeePercentInM100 > 8000)
        {
            return;// "There seems to be an error";
        }

        uint256 oldFee = serviceFeePercentInM100;

        serviceFeePercentInM100  = newFeePercentInM100;
        interestFeePercentInM100 = (100*100)-serviceFeePercentInM100;

        emit SetFees(oldFee, serviceFeePercentInM100);
    }
    //-----------------------------------------------------------------------------
    function    setResaleFee(uint256 newFeePercentInM100) external onlyOwner
    {
        uint256 oldFee = marketSalesFeeInM100;

        marketSalesFeeInM100  = newFeePercentInM100;

        emit SetResaleFee(oldFee, marketSalesFeeInM100);
    }
    //-----------------------------------------------------------------------------
    function    getMaxLoanablePercent() external view returns(uint256 percentInM100)
    {
        return maxLoanablePercentInM100;
    }
    //-----------------------------------------------------------------------------
    function    setMaxLoanablePercent(uint256 newPercentInM100) external onlyOwner
    {
        require(newPercentInM100 <   1*100, "Too low");
        require(newPercentInM100 > 100*100, "Too high");
        
        uint256 oldPercentInM100 = maxLoanablePercentInM100;
        maxLoanablePercentInM100 = newPercentInM100;

        emit SetMaxLoanablePercent(oldPercentInM100, newPercentInM100);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    createLenderAndAddFund() external payable nonReentrant
    {
		require(msg.value >= minFundingInWei, "Add Funds");

        TLender memory lender;

        uint256 lenderId = registeredLenders[msg.sender];

        if (lenderId==0)
        {
            registeredLenders[msg.sender] = lenderList.length + 1;
            
            lender = TLender
            (
                msg.sender,
                true,
                msg.value,                      // funded    Amount
                msg.value,                      // unused    Amount
                0,                              // lent      Amount
                0,                              // side      Amount
                0,                              // withdrawn Amount
                0,                              // gain      Amount
                uint32(block.timestamp),        // date when this guy first used the service
                0,                              // hash
                uint32(lenderList.length),      // Index in the lenderList
                true                            // isAutoLoaning : YES, allow by default
            );
        }
        else 
        {
            lender = lenderList[ lenderId - 1 ];
        }

        TFund memory fund = TFund
        (
            msg.sender,                     // lender wallet
            msg.value,                      // total amount of the FUND
            uint32(block.timestamp),        // date of the deposit
            0,                              // hash
            uint32(lender.index)            // for faster seeking of the fund lender
        );
            
        lenderFundList.push(fund);
    
        if (lenderId==0)
        {
            lenderList.push(lender);
        }

        loanableFund += msg.value;

        emit LenderFundAdded(lenderList.length-1, lenderFundList.length-1, msg.value);
    }
    //-----------------------------------------------------------------------------
    function    addFund(uint256 lenderId) external payable
    {
        uint256 amount = msg.value;

        require(amount >= minFundingInWei, "Add funds");

        bool isExist = (registeredLenders[msg.sender]!=0);

        require(isExist==true, "Bad Lender");

        TLender storage lender = lenderList[lenderId];

        require(lender.wallet==msg.sender, "Not lender");

        //-----

        lender.fundedAmount += amount;
        lender.unusedAmount += amount;

        TFund memory fund = TFund
        (
            msg.sender,                     // lender wallet
            amount,                         // total amount of the FUND
            uint32(block.timestamp),        // date of the deposit
            0,                              // hash
            uint32(lender.index)            // for faster seeking of the fund lender
        );
    
        lenderFundList.push(fund);
 
        loanableFund += amount;

        emit LenderFundAdded(lender.index, lenderFundList.length-1, amount);
    }
    //-----------------------------------------------------------------------------
    function    askToUnlockFund(uint256 amountToUnlock, uint256 lenderId) external
    {
        TLender storage lender    = lenderList[lenderId];

        require(amountToUnlock <= lender.unusedAmount, "Not enough funds");

        lender.unusedAmount -= amountToUnlock;
        lender.sideAmount   += amountToUnlock;

        TWithdraw memory withdraw = TWithdraw
        (
            msg.sender, 
            lenderId,
            amountToUnlock,

            (block.chainid==1) ? uint32(block.timestamp + 30*86400) : uint32(block.timestamp + 5*60),

            false,
            0//hash
        );

        withdrawList.push(withdraw); 

        loanableFund -= amountToUnlock;

        emit LenderWithdrawQuery(lender.index, withdrawList.length-1, amountToUnlock);
    }
    //-----------------------------------------------------------------------------
    function    withdrawFund(uint256 withdrawId)   external nonReentrant
    {
        TWithdraw storage withdraw = withdrawList[withdrawId];

        require(withdraw.isDone==false,                     "Withdraw already treated");
        require(withdraw.lenderWallet==msg.sender,          "Unallowed withdraw");
        require(block.timestamp >= withdraw.unlockEpoch,    "Withdraw is locked");

        uint256 amountToWithdraw = withdraw.amount;

        //if (address(this).balance < amountToWithdraw)
        //{
        //    emit WithdrawFund_Error_EthBalance(index, n, msg.sender);
        //    return false;
        //}

        //-----

        TLender storage lender = lenderList[ withdraw.lenderIndex ];

        require(lender.sideAmount >= amountToWithdraw,      "Amount above locked amount");

        lender.sideAmount      -= amountToWithdraw;
        lender.withdrawnAmount += amountToWithdraw;

        //----- Reduce the Gain also, since it will be removed from capital possible

        if (amountToWithdraw < lender.gainAmount)   lender.gainAmount -= amountToWithdraw;
        else                                        lender.gainAmount  = 0;

        //-----

        withdraw.isDone = true;
       
        payable(msg.sender).transfer( amountToWithdraw );

        emit FundWithdrawn(lender.index, withdrawId, amountToWithdraw);
    }
    //-----------------------------------------------------------------------------
    function    getWithdrawCount() external view returns(uint256)
    {
        return withdrawList.length;
    }
    //-----------------------------------------------------------------------------
    function    getWithdrawLockingDuration() external view returns(uint256)
    {
        return withdrawLockingDuration;
    }
    //-----------------------------------------------------------------------------
    function    setWithdrawLockingDuration(uint256 newDuration) external
    {
        withdrawLockingDuration = newDuration;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    setLenderAutoLoaningMode(uint256 lenderId, bool newAutoLoaningStatus) external
    {
        TLender storage lender = lenderList[lenderId];

        require(lender.wallet==msg.sender || msg.sender==owner(), "Bad caller");

        if (newAutoLoaningStatus==true && lender.isAutoLoaning==false)
        {
            loanableFund += lender.unusedAmount;
        }
        else if (newAutoLoaningStatus==false && lender.isAutoLoaning==true)
        {
            loanableFund -= lender.unusedAmount;
        }
        
        lender.isAutoLoaning = newAutoLoaningStatus;

        emit SetLenderAutoLoaningMode(lenderId, newAutoLoaningStatus);
    }
    //-----------------------------------------------------------------------------
    function    lenderExists(address[] memory guys) external view returns(bool[] memory)
    {
        uint256       n      = guys.length;
        bool[] memory states = new bool[](n);

        for (uint256 i; i<n; i++)
        {
            states[i] = (registeredLenders[ guys[i] ] != 0);
        }

        return states;
    } 
    //-----------------------------------------------------------------------------
    function    getLenderIndexByAddress(address guy)  external view returns(uint256)
    {
        return registeredLenders[ guy ] - 1;                    // ATTENTION: always less 1, because 0 is for exist:true/false
    }
    //-----------------------------------------------------------------------------
    function    getLenderIndexesByAddress(address[] memory guys)  external view returns(uint256[] memory)
    {
        uint n = guys.length;

        uint256[] memory indexes = new uint256[](n);

        for (uint256 i; i<n; i++)
        {
            indexes[i] = registeredLenders[ guys[i] ] - 1;      // ATTENTION: always less 1, because 0 is for exist:true/false
        }

        return indexes;
    }
    //-----------------------------------------------------------------------------
    function    getLendersFundCount() external view returns(uint256)
    {
        return lenderFundList.length;
    }
    //-----------------------------------------------------------------------------
    function    getLenderFund(uint256 index)  external view returns(TFund memory)
    {
        uint n = lenderFundList.length;

        require(index < n, "Bad index");

        return lenderFundList[index];
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    isAmountLoanable(uint askedAmount) external view returns(bool)
    {
        return ((askedAmount*(100*100) / loanableFund) <= maxLoanablePercentInM100);
    }/*
    //-----------------------------------------------------------------------------
    function    ___DBG() external pure returns(uint)
    {
        uint loanAmount       = 500000000000000;
        uint feePercentInM100 = 1;

        uint interestAmount = (loanAmount * feePercentInM100) / 100*100;

        return interestAmount;
    }*/
    //-----------------------------------------------------------------------------
    function    createLoan(
        bytes32             proposedHash, uint8 v, bytes32 r, bytes32 s,
        address             collectionAddress,
        uint256             collectionTokenId,
        uint256             durationInSec, 
        uint256             tlvAmount, 
        uint256             loanAmount,
        uint256             feePercentInM100,
        uint256[] memory    lendersIndexesAndAmounts)
            external
            nonReentrant
    {
                //----- signed function checker

        bool isProposedHashedUsed = proposedHashes[proposedHash];

        require(isProposedHashedUsed==false, "Bad Hash");

        proposedHashes[proposedHash] = true;

        bytes32 messageDigest = keccak256(abi.encodePacked(signHeader, proposedHash));
        bool    isFromAdmin   = (ecrecover(messageDigest, v, r, s)==admin());

        require(isFromAdmin==true, "Bad call");

        require( (loanAmount*(100*100) / loanableFund) <= maxLoanablePercentInM100, "Loan too high");

                //-----

        require(checkIfNftAlreadyTransfered(collectionAddress, collectionTokenId)==true, "Send NFT");
        require(feePercentInM100 < 100*100 || feePercentInM100==0,  "Bad interest");

        //-----

        tagFundsForLoanCreation(loanList.length, loanAmount, feePercentInM100, lendersIndexesAndAmounts);

        uint256 interestAmount = (loanAmount * feePercentInM100) / 100*100;       // We send the Interest the borrower will have to pay (By default: 70% of it to lenders / 30% to the service)

        TLoan memory loan = TLoan
        (
            collectionAddress,
            collectionTokenId,
            msg.sender,
            durationInSec,
            block.timestamp + durationInSec + loanAfterLockingDurationInSec,    // Before when this loan needs to be closed
            tlvAmount,                                                          // TLV price of the NFT. Used for resale price
            loanAmount,
            interestAmount,
            LoanMode.ACTIVE,
            (tlvAmount * (10000 + marketSalesFeeInM100))/ (100*100),    //resalePrice,
            false,                                          // isSold
            0,                                              // soldTimestamp (not sold yet)
            loanList.length                                 // Index of the loan (make a copy in case the loan moves to finishedLoans)
        );

        loanList.push(loan);

        loanableFund -= loanAmount;

        lentNfts[collectionAddress][collectionTokenId] = true;  // This NFT token is now linked to a LOAN

        payable(msg.sender).transfer(loanAmount);

        emit CreateLoanEvent(loan);
    }
    //-----------------------------------------------------------------------------
    function    tagFundsForLoanCreation(
        uint                loanId,
        uint256             loanAmount, 
        uint256             feePercentInM100,                                   // overall interest . need to calculate service fees (30%) and (70% for the lenders)
        uint256[] memory    lendersIndexesAndAmounts)
            internal
    {
        uint256 maxAllowedLoanAmount = (loanableFund * maxLoanablePercentInM100) / (100*100);

        require(loanAmount<=maxAllowedLoanAmount, "Loan too high");

        uint256 lenderFeeInM100 = (feePercentInM100 * interestFeePercentInM100) / (100*100); 

        require((lendersIndexesAndAmounts.length&1)==0, "Bad pairs");
        
        for (uint256 i; i<lendersIndexesAndAmounts.length; i+=2)
        {           
            TLender storage lender = lenderList[ lendersIndexesAndAmounts[i] ];

            uint256 lenderAmountForLoan = lendersIndexesAndAmounts[i+1];

            require(lender.isAutoLoaning==true, "Loaning blocked");                          // This LENDER don't want to participate in loan financing
            require(lender.unusedAmount >= lenderAmountForLoan, "Bad amount");
            
            lender.unusedAmount -= lenderAmountForLoan;
            lender.lentAmount   += lenderAmountForLoan;

            uint256 lenderInterestGainAmount = (lenderAmountForLoan * lenderFeeInM100) / (100*100);

            loanFunds[loanId].push(TLoanLenderFund
            (
                loanAmount,
                lenderAmountForLoan,
                lenderInterestGainAmount,
                lender.wallet,
                true,
                lendersIndexesAndAmounts[i]
            ));
        }
    }
    //-----------------------------------------------------------------------------
    function    closeLoan(uint256 index) external payable nonReentrant
    {
        uint256 nLoan = loanList.length;

        require(index < nLoan, "Bad Index");

        TLoan storage loan = loanList[index];

        require(loan.mode==LoanMode.ACTIVE,  "Loan off");

        require(block.timestamp<=loan.until, "Payback expired");

        uint256 priceToPay = loan.loanAmount + loan.interestAmount;

        require(msg.value==priceToPay, "Bad amount");
        require(msg.sender==loan.nftOwnerWallet, "Bad caller");

        //-----

        TLoanLenderFund[] memory funds = loanFunds[index];

        uint256 nFund = funds.length;

        uint256 uloanFeeAmount = loan.interestAmount;

        for(uint256 i; i<nFund; i++)
        {
            TLoanLenderFund memory fund = funds[i];

            TLender storage lender = lenderList[ fund.lenderIndex ];

            lender.lentAmount   -= fund.lentAmount;

            lender.unusedAmount += fund.lentAmount;
            lender.unusedAmount += fund.interestAmount;         

            lender.gainAmount   += fund.interestAmount;

            if (fund.interestAmount < uloanFeeAmount)   uloanFeeAmount -= fund.interestAmount;         // The rest of the fees is for us
            else                                        uloanFeeAmount  = 0;
        }

        loanableFund += loan.loanAmount + (loan.interestAmount - uloanFeeAmount);

        //-----

        loan.mode = LoanMode.PAID;

        iNFT(loan.collectionAddress).transferFrom               // Send back the NFT to its original owner
        (
            address(this), 
            loan.nftOwnerWallet, 
            loan.collectionTokenId
        );

        lentNfts[loan.collectionAddress][loan.collectionTokenId] = false;  // This NFT token is now FREE!!!

        //----- pay ULoan fees

        payable(serviceWallet).transfer(uloanFeeAmount);        // Pay the ULOAN team a part of the FEE

        emit CloseLoan(loan, uloanFeeAmount);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    setNftCollections(address[] memory contractAddresses, bool[] memory enableStates) external
    {
        bool isValidOperator = operators[msg.sender];

        require(isValidOperator==true, "Bad caller");

        uint256 l1 = contractAddresses.length;
        uint256 l2 = enableStates.length;

        require(l1==l2, "Bad collections");

        for(uint256 i=0; i<l1; i++)
        {
            setNftCollectionEx
            (
                contractAddresses[i],
                enableStates[i]
            );
        }
    }
    //-----------------------------------------------------------------------------
    function    setNftCollectionEx(address contractAddress, bool isEnabled) internal
    {
        require(contractAddress!=address(0x0), "No Zero");

        nftCollections[contractAddress] = TNftCollection
        (
            contractAddress,
            isEnabled
        );

        registeredNftCollections[contractAddress] = isEnabled;
    }
    //-----------------------------------------------------------------------------
    function    isNftCollectionEnabled(address[] memory contractAddresses) external view returns(bool[] memory)
    {
        uint256                   n = contractAddresses.length;
        bool[] memory enabledStates = new bool[](n);
        
        for (uint i=0; i<n; i++)
        {
            enabledStates[i] = registeredNftCollections[ contractAddresses[i] ];
        }

        return enabledStates;
    }
    //-----------------------------------------------------------------------------
    function    checkIfNftAlreadyTransfered(address collectionAddress, uint256 tokenId) 
                    public
                    view 
                    returns(bool)
    {
        address currentNftOwner = iNFT(collectionAddress).ownerOf(tokenId);

        bool isValidCollection  = registeredNftCollections[ collectionAddress ];

        return (currentNftOwner==address(this) && isValidCollection);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    saleLoanOnMarket(uint256 loanId,  bytes32 proposedHash, uint8 v, bytes32 r, bytes32 s) 
                    payable 
                    nonReentrant    
                    external
    {
                //----- signed function checker

        bool isProposedHashedUsed = proposedHashes[proposedHash];

        require(isProposedHashedUsed==false,    "Hash used");

        proposedHashes[proposedHash] = true;

        bytes32 messageDigest = keccak256(abi.encodePacked(signHeader, proposedHash));
        address caller        = ecrecover(messageDigest, v, r, s);
        bool    isFromAdmin   = (caller==admin());

        require(isFromAdmin==true,              "Bad call");

        //-----

        uint256 nLoan = loanList.length;

        require(loanId < nLoan, "Bad Index");

        TLoan storage loan = loanList[loanId];

        require(loan.mode==LoanMode.ACTIVE,     "Not for sale");
        require(loan.isSold==false,             "Already sold");
        require(msg.value==loan.resalesPrice,   "Invalid price");
        require(block.timestamp > loan.until,   "Not yet for sale");

        //----- dispatch of all gain to lenders

        TLoanLenderFund[] memory funds = loanFunds[loanId];

        uint256 nFund = funds.length;

        uint256 uloanFeeAmount = loan.resalesPrice;
        uint256 K              = (uloanFeeAmount * interestFeePercentInM100) / (100*100);
        uint256 fundToReinject = 0;

        for(uint256 i; i<nFund; i++)
        {
            TLoanLenderFund memory fund = funds[i];

            TLender storage lender = lenderList[ fund.lenderIndex ];

            uint256 lenderGain = (fund.lentAmount * K) / loan.loanAmount;

            if (fund.lentAmount <= lender.lentAmount)   lender.lentAmount -= fund.lentAmount;
            else                                        lender.lentAmount  = 0;

            lender.unusedAmount += lenderGain;          // We don't need to add back the fund.lentAmount, but just the GAIN
            lender.gainAmount   += lenderGain;

            if (uloanFeeAmount >= lenderGain)           uloanFeeAmount -= lenderGain;
            else                                        uloanFeeAmount  = 0;             // should never happen

            fundToReinject += lenderGain;
        }

        uint256 previousLoanableFund = loanableFund;
                       loanableFund += fundToReinject;

        loan.isSold        = true;
        loan.mode          = LoanMode.SOLD;
        loan.soldTimestamp = block.timestamp; 

        //----- pay ULoan fees

        payable(serviceWallet).transfer(uloanFeeAmount);

        //----- Deliver the NFT to the person who just bought it

        iNFT(loan.collectionAddress).transferFrom(address(this), msg.sender, loan.collectionTokenId);

        lentNfts[loan.collectionAddress][loan.collectionTokenId] = false;  // This NFT token is now FREE!!!

        emit SoldOnMarketplace(loan.nftOwnerWallet, msg.sender, uloanFeeAmount, fundToReinject, loanableFund, previousLoanableFund, loan);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    sendBackUnlentNft(address collectionAddress, uint256 tokenId, address borrowerWallet) external onlyOwner
    {
        // For very rare case, when the NFT was sent to the smartcontract but the LOAN could not be started,
        //   we transfer back the NFT to his owner.
        //   Unfortunatelly there is no event mecanism in solidity to detect the borrower wallet.
        //   So we are forced to set it as a parameter when calling this function. The borrower is know by us
        //   from the smarcontract blockchain history.

        if (lentNfts[collectionAddress][tokenId]==true)     // Don't allow the borrower to get back his NFT before he pays back!!!!
        {
            revert("NFT linked to Loan");
        }

        iNFT(collectionAddress).transferFrom(address(this), borrowerWallet, tokenId);   // Sendback        
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    setLoanAsAHotdeal(uint256 loanId, uint256 newPriceInWei) external onlyAdminOrOwner
    {
        require(loanId<loanList.length, "Bad Index");

        TLoan storage loan = loanList[loanId];
        uint256 oldPrice   = loan.resalesPrice;

        require(newPriceInWei>=oldPrice/4 && newPriceInWei>0, "Bad Price");

        loan.until        = block.timestamp;
        loan.resalesPrice = newPriceInWei;

        emit SetLoanAsAHotdeal(loanId, newPriceInWei, oldPrice, loan);
    }
    //-----------------------------------------------------------------------------
    function    changeLoanPricesOnMarket(uint256 loanId, uint256 newPriceInWei) external onlyAdminOrOwner
    {
        require(loanId<loanList.length, "Bad ID");

        TLoan storage loan = loanList[loanId];

        if (loan.mode==LoanMode.ACTIVE && loan.isSold==false && newPriceInWei>0.001 ether)
        {
            uint256 oldPrice  = loan.resalesPrice;

            loan.resalesPrice = newPriceInWei;

            emit ChangeLoanPriceOnMarket(loanId, newPriceInWei, oldPrice);
        }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    getLender(uint256 index) external view returns(TLender memory)
    {
        require(index < lenderList.length, "Bad Index");

        return lenderList[index];
    }
    //-----------------------------------------------------------------------------
    function    getLenderCount() external view returns(uint256)
    {
        return lenderList.length;
    }
     //-----------------------------------------------------------------------------
    function    listLendersByIndexes(uint256[] memory indexes) external view returns(TLender[] memory)
    {
         uint256 nToUse = indexes.length;

        TLender[] memory lenders = new TLender[](nToUse);

        uint256 g=0;

        for (uint256 i=0; i<nToUse; i++)
        {
            //uint256 idx = indexes[i];
            //require(idx<lenderList.length, "Bad Index");
            //lenders[g] = lenderList[ idx ];
            require(indexes[i]<lenderList.length, "Bad Index");

            lenders[g] = lenderList[indexes[i]];

            g++;
        }

        return lenders;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    listLendersFunds(uint256 from, uint256 to) external view returns(TFund[] memory)
    {
        require(from < lenderFundList.length, "Bad FROM");
        require(to   < lenderFundList.length, "Bad TO");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        TFund[] memory funds = new TFund[](nToExtract);

        uint256 g=0;

        for (uint256 i=from; i<=to; i++)
        {
            funds[g] = lenderFundList[i];
            g++;
        }

        return funds;
    }
    //-----------------------------------------------------------------------------
    function    listFunds(uint256[] memory indexes) external view  returns(TFund[] memory)
    {
        uint256 nFundToUse = indexes.length;

        require(nFundToUse < lenderFundList.length, "Bad Index");

        TFund[] memory funds = new TFund[](nFundToUse);

        uint256 g=0;

        for (uint256 i=0; i<nFundToUse; i++)
        {
            funds[g] = lenderFundList[ indexes[i] ];
            g++;
        }

        return funds;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    getLoan(uint256 index) external view  returns(TLoan memory)
    {
        require(index < loanList.length, "Bad Index");

        return loanList[index];
    }
    //-----------------------------------------------------------------------------
    function    getLoanCount() external view returns(uint256)
    {
        return loanList.length;
    }
    //-----------------------------------------------------------------------------
    function    listLoans(uint256 from, uint256 to) external view  returns(TLoan[] memory)
    {
        require(from < loanList.length, "Bad FROM");
        require(to   < loanList.length, "Bad TO");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        TLoan[] memory foundLoans = new TLoan[](nToExtract);

        uint g = 0;

        for (uint i=from; i<=to; i++)
        {
            foundLoans[g] = loanList[i];
            g++;
        }

        return foundLoans;
    }
    //-----------------------------------------------------------------------------
    function    listLoanFunds(uint256 loanId) external view  returns(TLoanLenderFund[] memory)
    {
        return loanFunds[ loanId ];
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    getWithdraw(uint256 index) external view returns(TWithdraw memory)
    {
        require(index<withdrawList.length, "Bad index");

        return withdrawList[index];
    }
    //-----------------------------------------------------------------------------
    function    listWithdraws(uint256 from, uint256 to) external view  returns(TWithdraw[] memory)
    {
        require(from < withdrawList.length, "Bad FROM");
        require(to   < withdrawList.length, "Bad TO");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        TWithdraw[] memory withdraws = new TWithdraw[](nToExtract);

        uint256 g=0;

        for (uint256 i=from; i<=to; i++)
        {
            withdraws[g] = withdrawList[i];
            g++;
        }

        return withdraws;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    getEthBalance() external view returns(uint256)
    {
        return address(this).balance;
    }
    //-----------------------------------------------------------------------------
    function    getloanableFund() external view returns(uint256)
    {
        return loanableFund;
    }
    //-----------------------------------------------------------------------------
    function    getMinFundinginWei() external view returns(uint256)
    {
        return minFundingInWei;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
}