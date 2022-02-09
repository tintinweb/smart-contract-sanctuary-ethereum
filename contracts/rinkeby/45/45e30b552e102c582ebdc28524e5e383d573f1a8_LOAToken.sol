/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

enum LoanMode      { ACTIVE, PAID, UNPAID, DISABLED }

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
    uint256     since;                      // date when this person first used our service
    uint256     hash;
} 

struct  TFund 
{
    address     lenderWallet;
    uint256     amount;
    uint256     timestamp;                  // date when the fund deposit was made
    uint256     hash;
}

struct  TWithdraw
{
    address     lenderWallet;
    uint256     amount;
    uint256     unlockEpoch;
    bool        isDone;                     // default = FALSE . when the ETH payment is done, set to TRY
    uint256     hash;
}

struct  TLoan
{
    address     collectionAddress;
    uint256     collectionTokenId;
    address     nftOwnerWallet;
    uint256     hash;
    uint256     durationInSec;
    uint256     since;
    uint256     until;                  // on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
    uint256     loanAmount;
    uint256     interestAmount;
    uint256     totalRefundAmount;      // = loanAmiunt+interestAmount ==> ce que devra rembourser le gars
    LoanMode    mode;                   // = UNPAID si la personne n'a pas rembourser son pret
    uint256     resalesPrice;           // prix a la revente si le NFT a été impayé.
    uint256     index;                  // The index inside the nftOwnerLoans[ wallet ] map

}

struct  TLoanLenderFund
{
    uint256     loanAmount;
    uint256     lentAmount;
    uint256     interestAmount;
    address     lenderWallet;
    bool        isActive;
}

struct TBorrower
{
    address     wallet;
    uint256     loanDoneCount;
    uint256     loanOkCount;
    uint256     loadBadCount;
    uint256     loanDoneAmount;
    uint256     loanOkAmount;
    uint256     loanBadAmount;
    uint256     currentLoanCount;
}

struct TNftCollection
{
    address         contractAddress;
    bool            enabled;
}

struct TProduct                                 // A product is a NFT which is for sale on our Marketplace
{
    uint256         hash;
    bool            isSold;
    uint256         since;
    uint256         soldTimestamp;
    uint256         activeProductIndex;
    uint256         soldProductIndex;
    TLoan           loan;
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
library Strings
{
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory)
    {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value==0)       return "0";
   
        uint256 temp = value;
        uint256 digits;
   
        while (temp!=0)
        {
            digits++;
            temp /= 10;
        }
       
        bytes memory buffer = new bytes(digits);
       
        while (value != 0)
        {
            digits        -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value         /= 10;
        }
       
        return string(buffer); 
    }
}
//--------------------------------------------------------------------------------
library Address
{
    function isContract(address account) internal view returns (bool)
    {
        uint256 size;
       
        assembly { size := extcodesize(account) }   // solhint-disable-next-line no-inline-assembly
        return size > 0;
    }
}
//--------------------------------------------------------------------------------
library SafeMath 
{
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) 
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
/*  0xaC410DFa874DC3e285663Dd615802973Cb23aA68      LENDER -> JEAN
    0x2091f35A4A64f6F1419c333d57afD7D152B18272      LENDER -> FAKE
    0xD45A48CFFD9B18077415E873e55206F90604Ae98      LENDER -> J1
    0x57457bc3e5e9f85C932F984aeDbB881c14C805b1      BORROWER            */
//################################################################################
//################################################################################
//################################################################################
contract LOAToken     is  Ownable, ReentrancyGuard
{
    using Address  for  address;
    using Strings  for  uint256;
    using SafeMath for  uint256;

    modifier callerIsUser()    { require(tx.origin == msg.sender, "The caller is another contract"); _; }

    constructor()
    {
        setNftCollectionEx( 0xd96268797e666E9eaE7e2Ef16969Ce8221B9f6D9, true);
    }

    event WithdrawFund_Error_Index( uint256 index,uint256 n, address guy);
    event WithdrawFund_Error_NotYet(uint256 index,uint256 n, address guy); 
    event AskToUnlockFund_Error_AskedToMuch(uint256 amountToUnlock, uint256 withdrawableFunds, address guy);
    event AskToUnlockFund(uint256 amountToUnlock, address guy, TWithdraw withdrawDDetails);
    event AskToUnlockFund2(uint256 amountToUnlock, address guy, uint256 val);
    event Withdraw(address guy, uint256 amount, uint256 index, uint256 withdrawHash);
    event WithdrawFund_Error_Withdraw_LoanableFund(uint256 index, uint256 loanableFund, uint256 amountToWithdraw, address guy);
    event WithdrawFund_Error_TooLow(uint256 index, address lenderWallet, TLender lender);
    event WithdrawFund_Error_Done(  uint256 index,uint256 n, address guy);

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
    mapping(address => TLender)         public  lenders;
                       address[]        public  lendersWallets;

    mapping(address => TFund[])         public  lenderFunds;
    mapping(uint256 => TFund)           public  funds;               // list of funds by HASH
                       uint256[]        public  fundHashes;

    mapping(address => TFund[])         public  lenderHistoryFunds;

    mapping(address => TWithdraw[])     public  lenderWithdraws;
    mapping(uint256 => TWithdraw)       public  withdraws;
                       uint256[]        public  withdrawHashes;
  
    mapping(address => bool)            public  registeredBorrowers;
    mapping(address => TBorrower)       public  borrowers;
                       address[]        public  borrowersWallets;

    mapping(uint256 => bool)            public  registeredLoans;
    mapping(address => TLoan[])         public  nftOwnerLoans;
    mapping(uint256 => TLoan)           public  loans;
                       uint256[]        public  loanHashes;

    mapping(uint256 => TLoanLenderFund[]) public  loanLenderFunds;

    mapping(uint256 => bool)            public  registeredProducts;     
    mapping(uint256 => TProduct)        public  activeProducts;
    mapping(uint256 => TProduct)        public  soldProducts;                       
                       uint256[]        public  activeProductHashes;
                       uint256[]        public  soldProductHashes;    

    //-----------------------------------------------------------------------------
    function    addFund() 
                    public 
                    payable
    {
        uint256 amount = msg.value;

        require(amount >= minFundingInWei, "Action cancelled - Add more funds");

        //-----

        address guy  = msg.sender;

        uint256 hash = forgeHash(amount, guy, block.timestamp, fundHashes.length);

        if (registeredLenders[guy]==false)      // This is a new Lender
        {
            registeredLenders[guy] = true;
            
            TLender memory lender = TLender
            (
                guy,
                true,
                amount,                     // funded    Amount
                amount,                     // unused    Amount
                0,                          // lent      Amount
                0,                          // side      Amount
                0,                          // withdrawn Amount
                0,                          // gain      Amount
                block.timestamp,            // date when this guy first used the service
                hash
            );

            lenders[guy] = lender;

            lendersWallets.push(guy);
        }
        else        // We add funds 
        {
            TLender storage lender = lenders[guy];

            lender.fundedAmount = lender.fundedAmount.add(amount);
            lender.unusedAmount = lender.unusedAmount.add(amount);
        }

        TFund memory fund = TFund
        (
            guy,                            // lender wallet
            amount,                         // total amount of the FUND
            block.timestamp,                // date of the deposit
            hash
        );

        funds[hash] = fund;

        lenderFunds[guy].push(fund);
        
        fundHashes.push(hash);

        loanableFund = loanableFund.add(amount);
    }
    //-----------------------------------------------------------------------------
    function    askToUnlockFund(uint256 amountToUnlock) 
                    public 
                    returns(bool)
    {
        address guy = msg.sender;

        TLender storage lender    = lenders[guy];
        uint256 withdrawableFunds = 0;

        if (lender.unusedAmount <= amountToUnlock)             // The lender asks more than what's available
        {
            emit AskToUnlockFund_Error_AskedToMuch(amountToUnlock, withdrawableFunds, guy);
            return false;
        }

        lender.unusedAmount = lender.unusedAmount.sub(amountToUnlock);
        lender.sideAmount   = lender.sideAmount.add(  amountToUnlock);

        uint256 hash = forgeHash(amountToUnlock, guy, block.timestamp, withdrawHashes.length);

        TWithdraw memory withdraw = TWithdraw
        (
            guy, 
            amountToUnlock,
            block.timestamp + 0,//30*86400,
            false,
            hash
        );

        lenderWithdraws[guy].push(withdraw);
        withdrawHashes.push(hash);

        withdraws[hash] = withdraw;

        loanableFund = loanableFund.sub(amountToUnlock);

        emit AskToUnlockFund(amountToUnlock, guy, withdraw);

        return true;
    }
    //-----------------------------------------------------------------------------
    function    withdrawFund(uint256 index) 
                    public 
                    returns(bool) 
    {
        address guy = msg.sender;

        uint256     n = lenderWithdraws[guy].length;

        if (index>=n)
        {
            emit WithdrawFund_Error_Index(index, n, guy);
            return false;
        }

        TWithdraw storage withdraw = lenderWithdraws[guy][index];

        if (withdraw.isDone==true)
        {
            emit WithdrawFund_Error_Done(index, n, guy);
            return false;
        }

        if (block.timestamp < withdraw.unlockEpoch)
        {
            emit WithdrawFund_Error_NotYet(index, n, guy);
            return false;
        }

        uint256 amountToWithdraw = withdraw.amount;

        //if (address(this).balance < amountToWithdraw)
        //{
        //    emit WithdrawFund_Error_EthBalance(index, n, guy);
        //    return false;
        //}

        //-----

        TLender storage lender = lenders[ guy ];

        if (lender.sideAmount < amountToWithdraw)
        {
            emit WithdrawFund_Error_TooLow(index, guy, lender);
            return false;
        }

        lender.sideAmount      = lender.sideAmount.sub(      amountToWithdraw );
        lender.withdrawnAmount = lender.withdrawnAmount.add( amountToWithdraw );

        //-----

        withdraw.isDone = true;

        
        payable(guy).transfer( amountToWithdraw );
        

        emit Withdraw(guy, amountToWithdraw, index, withdraw.hash);

        return true;
    }
    //-----------------------------------------------------------------------------
    function    forgeHash(uint256 amount, address guy, uint256 extra, uint256 extra2) 
                    internal 
                    pure 
                    returns(uint256)
    {
        return uint256
        (
            keccak256
            (
                abi.encodePacked
                (
                    amount,
                    guy,
                    extra,
                    extra2
                )
            )
        );
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
    function    createLoan(
        address     collectionAddress,
        uint256     collectionTokenId,
        address     nftOwnerAddress,
        uint256     durationInSec, 
        uint256     loanAmount, 
        uint256     interestPercentInM100)
                        public
                        returns(bool)
    {    
        if (interestPercentInM100 > 70*100)
        {
            return false;
        }

        if (loanableFund < loanAmount)
        {
            return false;                                                   // We don't have enough left in the LOAN balance
        }

        if (checkIfNftAlreadyTransfered(collectionAddress, collectionTokenId)==false)
        {
            //require(false, "Please transfert your NFT before all");
            return false;
        }

        //-----

        uint256 loanHash = forgeLoanHash(collectionAddress,collectionTokenId,nftOwnerAddress, loanAmount, block.timestamp);

        //-----

        uint256 leftToBeLent            = loanAmount;
        uint256 lenderLentAmountForLoan = 0;
        bool    isDone                  = false;
        uint256 interestAmount          = 0;      

        for (uint256 i; i<lendersWallets.length; i++)
        {
            TLender storage lender = lenders[ lendersWallets[i] ];

            uint256 unusedAmount = lender.unusedAmount;

            if (unusedAmount==0)      
            {
                continue;
            }

            if (unusedAmount >= leftToBeLent)                               // We use all funds left from this guy
            {
                lenderLentAmountForLoan = leftToBeLent;

                unusedAmount = unusedAmount.sub( leftToBeLent );
                leftToBeLent = 0;
                isDone       = true;
            }
            else                                                            // A chunk of the funds will be used
            {
                lenderLentAmountForLoan = unusedAmount;
                
                leftToBeLent = leftToBeLent.sub( unusedAmount );
                unusedAmount = 0;
            }

            lender.unusedAmount = unusedAmount;
            lender.lentAmount   = lender.lentAmount.add( lenderLentAmountForLoan );

            //-----

            uint256 lenderInterestGainAmount = lenderLentAmountForLoan.mul( interestPercentInM100 ).div(100*100);

            loanLenderFunds[loanHash].push( TLoanLenderFund
            (
                loanAmount,
                lenderLentAmountForLoan,
                lenderInterestGainAmount,
                lendersWallets[i],
                true                            // active
            ));

            interestAmount = interestAmount.add( lenderInterestGainAmount );

            //-----

            if (leftToBeLent==0 || isDone==true)      // We collected the funds correctly
            {
                break;
            }
        }

        //-----

        uint256 resalesPrice = loanAmount.add( loanAmount.mul( marketSalesFeeInM100 ).div(100*100));

        TLoan memory loan = TLoan
        (
            collectionAddress,
            collectionTokenId,
            nftOwnerAddress,
            loanHash,
            durationInSec,
            block.timestamp,                                                    // "since"  mais la personne n'a pas encore lancer, alors =0
            block.timestamp + durationInSec + loanAfterLockingDurationInSec,    //realEndTimestamp;           // (for V2) on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
            loanAmount,
            interestAmount,
            loanAmount + interestAmount,
            LoanMode.ACTIVE,
            resalesPrice,
            nftOwnerLoans[nftOwnerAddress].length                               // Index : necessary for the nftBuyMarket function
        );

        loans[loanHash]           = loan;
        registeredLoans[loanHash] = true;

        nftOwnerLoans[nftOwnerAddress].push(loan);
        
        loanHashes.push(loanHash);

        loanableFund = loanableFund.sub( loanAmount );

        
        payable(msg.sender).transfer(loanAmount);
        

        return true;
    }
    //-----------------------------------------------------------------------------
    function    closeLoan(uint256 index, address guy) 
                    external 
                    payable 
                    nonReentrant
                    returns(bool)
    {
        uint256 nLoan = nftOwnerLoans[guy].length;

        if (index>=nLoan)
        {
            return false;
        }

        //-----

        TLoan storage loan = nftOwnerLoans[guy][index];

        if (loan.mode!=LoanMode.ACTIVE)
        {
            return false;                       // Ce LOAN n'est plus actif
        }

        uint256 loanHash = loan.hash;

        for(uint256 i; i<loanLenderFunds[loanHash].length; i++)
        {
            TLoanLenderFund storage fund = loanLenderFunds[loanHash][i];

            fund.isActive = false;

            TLender storage lender = lenders[ fund.lenderWallet ];

            lender.unusedAmount = lender.unusedAmount.add( fund.lentAmount     );
            lender.lentAmount   = lender.lentAmount.sub(   fund.lentAmount     );

            lender.sideAmount   = lender.sideAmount.add(   fund.interestAmount );            
            lender.gainAmount   = lender.gainAmount.add(   fund.interestAmount );
        }           

        loanableFund = loanableFund.add( loan.loanAmount );

        //-----

        if (block.timestamp <= loan.until)          // FINE, the NFTOwner paid his loan fully
        {                                           // So let's bring him back his NFT
            loan.mode = LoanMode.PAID;

            iNFT(loan.collectionAddress).safeTransferFrom(address(this), guy, loan.collectionTokenId);
        }
        else                                        // let's tag the NFT to be sold in our MARKETPLACE!
        {
            loan.mode = LoanMode.UNPAID;

            uint256 productHash = forgetMarketProductHash(loan);

            TProduct memory marketProduct = TProduct
            (
                productHash,
                false,                              // isSold
                block.timestamp,
                0,
                activeProductHashes.length,      // used as an index to be used later
                0,
                loan
            );

            activeProducts[productHash]     = marketProduct;
            registeredProducts[productHash] = true;

            activeProductHashes.push( productHash );
        }
/*        
    mapping(address => TProduct[])      public  collectionProducts;
    mapping(uint256 => TProduct)        public  activeProducts;
    mapping(uint256 => TProduct)        public  soldProducts;                       
                       uint256[]        public  collectionProductHashes;
                       uint256[]        public  availableProductHashes;
                       uint256[]        public  soldProductHashes;
*/
        return true;
    }
    //-----------------------------------------------------------------------------
    function    forgetMarketProductHash(TLoan memory loan)
                        internal 
                        pure 
                        returns(uint256)
    {
        return uint256
        (
            keccak256
            (
                abi.encodePacked
                (
                    loan.collectionAddress,
                    loan.collectionTokenId,
                    loan.hash
                )
            )
        );
    }
    //-----------------------------------------------------------------------------
    function    forgeLoanHash(
        address     collectionAddress, 
        uint256     collectionTokenId, 
        address     nftOwner,
        uint256     amountToLoan,
        uint256     extra)
                        internal 
                        pure 
                        returns(uint256)
    {
        return uint256
        (
            keccak256
            (
                abi.encodePacked
                (
                    collectionAddress,
                    collectionTokenId,
                    nftOwner,
                    amountToLoan,
                    extra
                )
            )
        );
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
    function    nftMarketBuy(uint256 productHash) 
                    external 
                    payable 
                    nonReentrant 
                    returns(uint256)
    {
        //require(isLoanAvailable,                    "This NFT reference is not available");
        if (registeredProducts[productHash]==false)
        {
            emit MarketBuy_Error_Loan_NotFound(productHash);
            return 1000;
        }

        TProduct storage product = activeProducts[productHash];

        //require(product.isSold==false, "This product has been sold already");
        if (product.isSold==true)
        {
            emit MarketBuy_Error_Already_Sold(productHash, product.loan.collectionAddress, product.loan.collectionTokenId, product.loan.resalesPrice);
            return 1001;
        }

        //require(msg.value==product.loan.resalesPrice,       "Please send the exact loan and its interest amount");
        if (msg.value!=product.loan.resalesPrice)
        {
            emit MarketBuy_Error_Invalid_Price(productHash, msg.value, product.loan.resalesPrice);
            return 1002;
        }

        //-----

        product.isSold             = true;
        product.soldTimestamp      = block.timestamp;
        product.activeProductIndex = 0;
        product.soldProductIndex   = soldProductHashes.length;

        delete activeProducts[productHash];
        delete activeProductHashes[ product.activeProductIndex ];       // Don't keep it in the actives, to faster treat a pool of products

        soldProducts[productHash] = product;
        soldProductHashes.push( productHash );

        //----- deliver the NFT to the person who just bought it

        iNFT(product.loan.collectionAddress).safeTransferFrom(address(this), msg.sender, product.loan.collectionTokenId);

        return 1;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
}