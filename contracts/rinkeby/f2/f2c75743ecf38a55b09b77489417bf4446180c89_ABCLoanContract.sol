/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

/*
    addFund         :   0,048 ETH

    createLoan      :   0.078 ETH

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

enum LoanMode      { ACTIVE, PAID, UNPAID, DISABLED, SOLD }

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
} 

struct  TFund 
{
    address     lenderWallet;
    uint256     amount;
    uint32      timestamp;                  // date when the fund deposit was made
    uint256     hash;
    uint32      lenderIdx;
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
    uint256     since;
    uint256     until;                  // on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
    uint256     loanAmount;
    uint256     interestAmount;
    LoanMode    mode;                   // = UNPAID si la personne n'a pas rembourser son pret
    uint256     resalesPrice;           // prix a la revente si le NFT a été impayé.
    bool        isSold;                 // was it sold on the marketplace? 
    uint256     soldTimestamp;          // the date when this was sold
    uint256     loanIndex;              // Key index in the loanFunds map
}

struct TNftCollection
{
    address         contractAddress;
    bool            enabled;
}

//--------------------------------------------------------------------------------
interface iNFT
{
    function ownerOf(uint256 tokenId)                                       external view returns (address owner);
    function name()                                                         external view returns (string memory);
    function symbol()                                                       external view returns (string memory);
    function safeTransferFrom(address from, address to, uint256 tokenId)    external;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");    // On the first call to nonReentrant, _notEntered will be true
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
                   _admin = msgSender;
                   
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    modifier onlyAdminOrOwner()
    {
        require(_msgSender()==owner() || _msgSender()==admin(), "Ownable: Only Admin or Owner are allowed");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
       
        emit OwnershipTransferred(_owner, newOwner);
       
        _owner = newOwner;
    }
}
//################################################################################
//################################################################################
//################################################################################
contract ABCLoanContract     is  Ownable, ReentrancyGuard
{
    modifier callerIsUser()    { require(tx.origin == msg.sender, "The caller is another contract"); _; }

    constructor()
    {
        setNftCollectionEx( 0xd96268797e666E9eaE7e2Ef16969Ce8221B9f6D9, true);          // contrat de NFT de reference pour test (@rinkeby)
    }

    event WithdrawFund_Error_Index( uint256 withdrawHash, address guy);
    event WithdrawFund_Error_NotYet(uint256 withdrawHash, address guy); 
    event AskToUnlockFund_Error_AskedToMuch(uint256 amountToUnlock, uint256 withdrawableFunds, address guy);
    event AskToUnlockFund(uint256 amountToUnlock, address guy, TWithdraw withdrawDDetails);
    event AskToUnlockFund2(uint256 amountToUnlock, address guy, uint256 val);
    event Withdraw(address guy, uint256 amount, uint256 index, uint256 withdrawHash);
    event WithdrawFund_Error_Withdraw_LoanableFund(uint256 index, uint256 loanableFund, uint256 amountToWithdraw, address guy);
    event WithdrawFund_Error_TooLow(uint256 index, address lenderWallet, TLender lender);
    event WithdrawFund_Error_Done(  uint256 withdrawHash, address guy);
    event WithdrawFund_Error_Not_Owner(  uint256 withdrawHash, address guy);

    uint256  private    maxFundCandidate              = 15;
    uint256  private    loanAfterLockingDurationInSec = 0;          // (for V2) une fois que pret est terminé, combien de temps on donne de sursit pour qu'il paye. En V1 : 0 -->  aucun sursit
    uint256  private    marketSalesFeeInM100          = 20 *100;    // Price of resale for NFT which LOAN was not PAID back... 20% in M100 format
    uint256  private    capitalMaxInvestmentPercent   = 30;         // from the global funds available for Loan, allow only 30% max for the creation of a loan

    uint256  public     loanableFund                  = 0;          // overalll funds available in the smartcontract to be used for loaning 

    uint256  private    minLenderLockDurationInSec    = 60;
    uint256  private    minFundingInWei               = 0.0001 ether;

    mapping(address => bool)            public  registeredNftCollections;
    mapping(address => TNftCollection)  public  nftCollections;

    mapping(address => bool)            public  registeredLenders;
                       address[]        public  lendersWallets;

                       TLender[]        public  lenderList;
                       TFund[]          public  fundList;
                       TFund[]          public  finishedFundList;           // Funds that have been withdrawn, so no need to use them anymore
                       TWithdraw[]      public  withdrawList;
                       TLoan[]          public  loanList;
                       TLoan[]          public  finishedLoanList;
    
    mapping(uint256 => TLoanLenderFund[])public loanFunds;
    //// mapping(uint256 => TFund[])          public lenderFunds;
    
    //-----------------------------------------------------------------------------
    function    addFund(uint256 idx) external payable  returns(uint256 fundIdx)
    {
        /* DEBUG */ //uint256 amount = 0.005 ether;
        /* PROD */  uint256 amount = msg.value;

        require(amount >= minFundingInWei, "Action cancelled - Add more funds");

        //-----

        if (registeredLenders[msg.sender]==false)      // This is a new Lender
        {
            registeredLenders[msg.sender] = true;
            
            TLender memory lender = TLender
            (
                msg.sender,
                true,
                amount,                     // funded    Amount
                amount,                     // unused    Amount
                0,                          // lent      Amount
                0,                          // side      Amount
                0,                          // withdrawn Amount
                0,                          // gain      Amount
                uint32(block.timestamp),    // date when this guy first used the service
                0,                          // hash
                uint32(lenderList.length)   // Index in the lenderList
            );

            TFund memory fund = TFund
            (
                msg.sender,                     // lender wallet
                amount,                         // total amount of the FUND
                uint32(block.timestamp),        // date of the deposit
                0,                              // hash
                uint32(lenderList.length)       // for faster seeking of the fund lender
            );

            fundList.push(fund);
            lenderList.push(lender);
    
            //// lenderFunds[ lender.index ].push(fund);
        }
        else        // We add funds 
        {
            TLender storage lender = lenderList[idx];

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
    
            fundList.push(fund);
    
            //// lenderFunds[ lender.index ].push(fund);
        }

        loanableFund += amount;

        return fundList.length-1;
    }
    //-----------------------------------------------------------------------------
    function    askToUnlockFund(uint256 amountToUnlock, uint256 lenderIdx)
                    public 
                    returns(bool)
    {
        TLender storage lender    = lenderList[lenderIdx];
        uint256 withdrawableFunds = 0;

        if (lender.unusedAmount <= amountToUnlock)             // The lender asks more than what's available
        {
            emit AskToUnlockFund_Error_AskedToMuch(amountToUnlock, withdrawableFunds, msg.sender);
            return false;
        }

        lender.unusedAmount -= amountToUnlock;
        lender.sideAmount   += amountToUnlock;

        TWithdraw memory withdraw = TWithdraw
        (
            msg.sender, 
            lenderIdx,
            amountToUnlock,
            uint32(block.timestamp + 0),//30*86400,
            false,
            0//hash
        );

        withdrawList.push(withdraw);

        loanableFund -= amountToUnlock;
        return true;
    }
    //-----------------------------------------------------------------------------
    function    withdrawFund(uint256 idx) 
                    public 
                    returns(bool) 
    {
        TWithdraw storage withdraw = withdrawList[idx];

        if (withdraw.isDone==true)
        {
            emit WithdrawFund_Error_Done(idx, msg.sender);
            return false;
        }

        if (withdraw.lenderWallet!=msg.sender)
        {
            emit WithdrawFund_Error_Not_Owner(idx, msg.sender);
            return false;
        }

        if (block.timestamp < withdraw.unlockEpoch)
        {
            emit WithdrawFund_Error_NotYet(idx, msg.sender);
            return false;
        }

        uint256 amountToWithdraw = withdraw.amount;

        //if (address(this).balance < amountToWithdraw)
        //{
        //    emit WithdrawFund_Error_EthBalance(index, n, msg.sender);
        //    return false;
        //}

        //-----

        TLender storage lender = lenderList[ withdraw.lenderIndex ];

        if (lender.sideAmount < amountToWithdraw)
        {
            emit WithdrawFund_Error_TooLow(idx, msg.sender, lender);
            return false;
        }

        lender.sideAmount      -= amountToWithdraw;
        lender.withdrawnAmount += amountToWithdraw;

        //-----

        withdraw.isDone = true;
       
        payable(msg.sender).transfer( amountToWithdraw );

        return true;
    }
    //-----------------------------------------------------------------------------
    function    liquidLender(address guy) 
                    external 
                    onlyOwner
    {
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    createLoan(
        address             collectionAddress,
        uint256             collectionTokenId,
        uint256             durationInSec, 
        uint256             loanAmount, 
        uint256             interestPercentInM100,
        uint256[] memory    lendersIndexes)
                        public
                        returns(string memory)
    {


        if (interestPercentInM100 > 70*100)     return "interestPercentInM100 > 70*100";
        if (loanableFund < loanAmount)          return "loanableFund < loanAmount";                     // We don't have enough left in the LOAN balance

        if (checkIfNftAlreadyTransfered(collectionAddress, collectionTokenId)==false)
        {
            return "Please transfert your NFT before all";
        }


        //-----

        uint256 nFundToUse = isValidLoanCreation(loanAmount, lendersIndexes);

        if (nFundToUse==0)
        {
            return "Invalid request for creating a LOAN";
        }

        uint256 loanIdx = loanList.length;

        //-----

        uint256 interestAmount = tagFundsForLoanCreation(loanIdx, loanAmount, interestPercentInM100, lendersIndexes);

        uint256 resalePrice    = loanAmount + ((loanAmount * marketSalesFeeInM100)/ 100*100);

        TLoan memory loan = TLoan
        (
            collectionAddress,
            collectionTokenId,
            msg.sender,
            durationInSec,
            block.timestamp,                                                    // "since"  mais la personne n'a pas encore lancer, alors =0
            block.timestamp + durationInSec + loanAfterLockingDurationInSec,    // realEndTimestamp;           // (for V2) on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
            loanAmount,
            interestAmount,
            LoanMode.ACTIVE,
            resalePrice,
            false,                                                              // isSold
            0,                                                                  // soldTimestamp (not sold yet)
            loanIdx                                                             // Index of the loan (make a copy in case the loan moves to finishedLoans
        );

        loanList.push(loan);

        loanableFund -= loanAmount;

        payable(msg.sender).transfer(loanAmount);

        return "CreateLoan: OK";
    }
    //-----------------------------------------------------------------------------
    function    isValidLoanCreation(uint256 loanAmount, uint256[] memory lendersIndexes)
                        internal
                        view
                        returns(uint)
    {    
        uint256 nLenderToUse   = 0; 
        uint256 leftToBeLent   = loanAmount;
        bool    isDone         = false;
        bool    isValidRequest = false;

        for (uint256 i; i<lendersIndexes.length; i++)
        {          
            TLender memory lender = lenderList[ lendersIndexes[i] ];

            uint256 unusedAmount = lender.unusedAmount;

            if (unusedAmount==0)      
            {
                continue;
            }

            if (unusedAmount >= leftToBeLent)                               // We use all funds left from this guy
            {
                nLenderToUse++;
                unusedAmount -= leftToBeLent;
                leftToBeLent  = 0;
                isDone        = true;
            }
            else                                                            // A chunk of the funds will be used
            {
                nLenderToUse++;
                leftToBeLent -= unusedAmount;
                unusedAmount  = 0;
            }

            if (leftToBeLent==0 || isDone==true)                            // We've collected the funds correctly
            {
                isValidRequest=true;
                break;
            }
        }

        if (isValidRequest==true)
        {
            return nLenderToUse;
        }

        return 0;
    }
    //-----------------------------------------------------------------------------
    function    tagFundsForLoanCreation(
        uint                loanIdx,
        uint256             loanAmount, 
        uint256             interestPercentInM100,
        uint256[] memory    lendersIndexes)
            internal
            returns(uint256)
    {
        uint256 leftToBeLent            = loanAmount;
        bool    isDone                  = false;
        uint256 lenderLentAmountForLoan = 0;
        uint256 interestAmount          = 0;

        for (uint256 i; i<lendersIndexes.length; i++)
        {           
            TLender storage lender = lenderList[ lendersIndexes[i] ];

            uint256 unusedAmount = lender.unusedAmount;

            if (unusedAmount==0)      
            {
                continue;
            }

            if (unusedAmount >= leftToBeLent)                               // We use all funds left from this guy
            {
                lenderLentAmountForLoan = leftToBeLent;

                unusedAmount -= leftToBeLent;
                leftToBeLent  = 0;
                isDone        = true;
            }
            else                                                            // A chunk of the funds will be used
            {
                lenderLentAmountForLoan = unusedAmount;
                
                leftToBeLent -= unusedAmount;
                unusedAmount  = 0;
            }

            lender.unusedAmount  = unusedAmount;
            lender.lentAmount   += lenderLentAmountForLoan;

            //-----

            uint256 lenderInterestGainAmount = (lenderLentAmountForLoan * interestPercentInM100) / (100*100);

            loanFunds[loanIdx].push(TLoanLenderFund
            (
                loanAmount,
                lenderLentAmountForLoan,
                lenderInterestGainAmount,
                lender.wallet,
                true,
                lendersIndexes[i]
            ));
        
            interestAmount += lenderInterestGainAmount;

            if (leftToBeLent==0 || isDone==true)        // We collected the funds correctly
            {
                break;
            }
        }

        return interestAmount;
    }
    //-----------------------------------------------------------------------------
    function    closeLoan(uint256 index) 
                    external 
                    payable 
                    nonReentrant
                    returns(string memory)
    {
        uint256 nLoan = loanList.length;

        if (index>=nLoan)
        {
            return "[closeLoan] index>=nLoan";
        }

        TLoan storage loan = loanList[index];

        if (loan.mode!=LoanMode.ACTIVE)
        {
            return "Loan is no more active";
        }

        if (block.timestamp > loan.until)                       // It's too LATE. you cannot get back this NFT
        {                                                       // You were too late to pay it
            return "It's too late to get back this NFT";
        }

        //-----

        TLoanLenderFund[] memory funds = loanFunds[index];

        uint256 nFund = funds.length;

        for(uint256 i; i<nFund; i++)
        {
            TLoanLenderFund memory fund = funds[i];

            fund.isActive = false;

            TLender storage lender = lenderList[ fund.lenderIndex ];

            lender.unusedAmount += fund.lentAmount;
            lender.lentAmount   -= fund.lentAmount;

            lender.sideAmount   += fund.interestAmount;            
            lender.gainAmount   += fund.interestAmount;
        }

        loanableFund += loan.loanAmount;

        //-----

        loan.mode = LoanMode.PAID;

        iNFT(loan.collectionAddress).safeTransferFrom           // Send back the NFT to its original owner
        (
            address(this), 
            msg.sender, 
            loan.collectionTokenId
        );

        return "CloseLoan: OK";
    }
    //-----------------------------------------------------------------------------
    function    unlockFundsFromLoan(uint256 loanHash) external
    {
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    setNftCollections(address[] memory contractAddresses, bool[] memory enableStates) 
                    external 
                    onlyAdminOrOwner
    {
        uint256 l1 = contractAddresses.length;
        uint256 l2 = enableStates.length;

        require(l1==l2, "Invalid collections information provided");

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
        require(contractAddress!=address(0x0), "Blackhole not allowed");

        nftCollections[contractAddress] = TNftCollection
        (
            contractAddress,
            isEnabled
        );

        registeredNftCollections[contractAddress] = isEnabled;
    }
    //-----------------------------------------------------------------------------
    function    checkIfNftAlreadyTransfered(address collectionAddress, uint256 tokenId) 
                    public
                    view 
                    returns(bool)
    {
        address currentNftOwner = iNFT(collectionAddress).ownerOf(tokenId);

        return (currentNftOwner==address(this));
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    setCapitalMaxInvestmentPercent(uint256 newPercent) external 
    {
        require(newPercent>0 && newPercent<=100, "Invalid capital percent set");

        capitalMaxInvestmentPercent = newPercent;
    }
   //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    event   MarketBuy_Error_Loan_NotFound(uint256 productHash);
    event   MarketBuy_Error_Invalid_Price(uint256 productHash, uint256 receivedAmountInEth, uint256 marketPriceInWei);
    event   MarketBuy_Error_Not_Buyable(  uint256 productHash);
    event   MarketBuy_Error_Too_Early(    uint256 productHash, uint256 nowEpoch, uint256 realUntil);
    event   MarketBuy_Error_Already_Sold( uint256 productHash, address collectionAddress, uint256 tokenId, uint256 priceInWei);
    //-----------------------------------------------------------------------------
    function    nftMarketBuy(uint256 loanIndex) 
                    external 
                    payable 
                    nonReentrant 
                    returns(string memory)
    {
        uint256 nLoan = loanList.length;

        if (loanIndex>=nLoan)
        {
            return "Invalid Index";
        }

        TLoan storage loan = loanList[loanIndex];

        if (loan.mode==LoanMode.SOLD)
        {
            return "This product was already sold";
        }

        if (loan.mode==LoanMode.ACTIVE || loan.mode==LoanMode.PAID)
        {
            return "This product is not for sale";
        }

        if (loan.isSold==true)
        {
            return "This product has already been sold";
        }

        if (msg.value!=loan.resalesPrice)
        {
            return "Send the exact amount to buy this";
        }

        if (block.timestamp <= loan.until)
        {
            return "this item is not for sold";
        }

        //-----

        loan.isSold        = true;
        loan.soldTimestamp = block.timestamp; 
    
        //----- deliver the NFT to the person who just bought it

        iNFT(loan.collectionAddress).safeTransferFrom(address(this), msg.sender, loan.collectionTokenId);

        return "This NFT just sold on the marketplace";
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    listLenders(uint256 from, uint256 to) external view onlyAdminOrOwner returns(TLender[] memory)
    {
        require(from < loanList.length, "listLenders: Invalid FROM index");
        require(to   < loanList.length, "listLenders: Invalid TO index");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        TLender[] memory foundLenders = new TLender[](nToExtract);

        uint g = 0;

        for (uint i=from; i<=to; i++)
        {
            foundLenders[g] = lenderList[i];
            g++;
        }

        return foundLenders;
    }
    //-----------------------------------------------------------------------------
    function    listLentingLenders(uint256 from, uint256 to) external view onlyAdminOrOwner returns(TLender[] memory)
    {
        require(from < loanList.length, "listLenders: Invalid FROM index");
        require(to   < loanList.length, "listLenders: Invalid TO index");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        TLender[] memory foundLenders = new TLender[](nToExtract);

        uint g = 0;

        for (uint i=from; i<=to; i++)
        {
            if (lenderList[i].lentAmount==0)    continue;

            foundLenders[g] = lenderList[i];
            g++;
        }

        return foundLenders;
    }
    //-----------------------------------------------------------------------------
    /*
    function    listLenderFunds(uint256 lenderIdx) external view onlyAdminOrOwner returns(TFund[] memory)
    {
        require(lenderIdx >= lenderList.length, "listLenderFunds: index out of range");

        return lenderFunds[ lenderIdx ];
    }*/
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    listLoans(uint256 from, uint256 to) external view onlyAdminOrOwner returns(TLoan[] memory)
    {
        require(from < loanList.length, "listLoans: Invalid FROM index");
        require(to   < loanList.length, "listLoans: Invalid TO index");

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
    function    getLoanStatus(uint256 index) external view onlyAdminOrOwner returns(LoanMode)
    {
        require(index >= loanList.length, "getLoanStatus: Invalid index");

        TLoan memory loan = loanList[index];
        LoanMode     mode = loanList[index].mode;

        if (mode==LoanMode.ACTIVE && block.timestamp > loan.until)          // cas special.
        {
            mode = LoanMode.UNPAID;         // utilisable dans le marketplace
        }

        return mode;
    }
    //-----------------------------------------------------------------------------
    function    getLoanStatues(uint256[] memory indexes) external view onlyAdminOrOwner returns(LoanMode[] memory)
    {
        LoanMode[] memory statues = new LoanMode[](indexes.length);

        for (uint256 i; i<indexes.length; i++)
        {
            TLoan memory loan = loanList[ indexes[i] ]; 
            LoanMode     mode = loan.mode;

            if (mode==LoanMode.ACTIVE && block.timestamp > loan.until)          // cas special.
            {
                mode = LoanMode.UNPAID;         // utilisable dans le marketplace
            }

            statues[i] = mode;
        }

        return statues;
    }
    //-----------------------------------------------------------------------------
    function    getLoanStatuesFromRange(uint256 from, uint256 to) external view onlyAdminOrOwner returns(uint256[] memory)
    {
        require(from<loanList.length, "getLoanStatuesFromRange: Invalid FROM index");
        require(to<loanList.length,   "getLoanStatuesFromRange: Invalid TO index");

        if (from>to)
        {
            uint v = from;
            from   = to;
            to     = v;
        }

        uint256 nToExtract = (to - from) + 1;

        uint256[] memory statues = new uint256[](nToExtract);

        uint256 g=0;

        for (uint256 i=from; i<=to; i++)
        {
            statues[g] = uint256(loanList[i].mode);
            g++;
        }

        return statues;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    listLoanFunds(uint256 loanIdx) external view onlyAdminOrOwner returns(TLoanLenderFund[] memory)
    {
        require(loanIdx >= loanList.length,  "listLoanFunds: index out of range");

        return loanFunds[ loanIdx ];
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    listFunds(uint256 from, uint256 to) external view onlyAdminOrOwner returns(TFund[] memory)
    {
        require(from<loanList.length, "listFunds: Invalid FROM index");
        require(to<loanList.length,   "listFunds: Invalid TO index");

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
            funds[g] = fundList[i];
            g++;
        }

        return funds;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
}