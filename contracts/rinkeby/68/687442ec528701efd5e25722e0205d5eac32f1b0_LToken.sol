/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

enum LoanMode      { CREATED, RUNNING, PAID, UNPAID }

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
    uint256     fundedAmount;
    uint256     unusedAmount;               // amount not used for loan. Just sleeping for nothing
    uint256     lentAmount;
    uint256     sideAmount;                 // used for withdrawing
    uint256     sinceEpoch;                 // date when the fund deposit was made
    uint256     minWithdrawEpoch;           // The fund cannot be withdrawn during the first 30 days. This tell when the guy can really withdraw
    uint256     hash;
}

struct  TBalances
{
    uint256     fundedAmount;
    uint256     unusedAmount;
    uint256     lentAmount;
    uint256     idleAmount;
    uint256     sideAmount;
    uint256     withdrawnAmount;
    uint256     feeAmount;
}

struct  TWithdraw
{
    address     lenderWallet;
    uint256     askedAmount;
    uint256     unlockEpoch;
    bool        isDone;                     // default = FALSE . when the ETH payment is done, set to TRY
    uint256     hash;
}

        //--------

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

struct  TLoan
{
    address     collectionAddress;
    uint256     tokenId;
    address     nftOwnerWallet;
    uint256     hash;
    uint256     durationInSec;
    uint256     since;
    uint256     until;                  // Quand est-ce que l'emprunt s'arretera
    uint256     realUntil;              // on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
    uint256     loanAmount;
    uint256     interestAmount;
    uint256     totalRefundAmount;      // = loanAmiunt+interestAmount ==> ce que devra rembourser le gars
    LoanMode    mode;                   // =UNPAID si la personne n'a pas rembourser son pret
    uint256     resalesPrice;           // prix a la revente si le NFT a été impayé.
}

struct  TLoanFund
{
    uint256     usedAmount;
    uint256     fundHash;
    uint256     gainAmount;             // when the loan will be closed, this is the interest gain to give to the fund owner (=lender)
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
contract LToken     is  Ownable, ReentrancyGuard
{
    using Address  for  address;
    using Strings  for  uint256;
    using SafeMath for  uint256;

    modifier callerIsUser()    { require(tx.origin == msg.sender, "The caller is another contract"); _; }

    constructor()
    {
    }

    event WithdrawFund_Error_Index( uint256 index,uint256 n, address guy);
    event WithdrawFund_Error_NotYet(uint256 index,uint256 n, address guy); 
    event AskToUnlockFund_Error_AskedToMuch(uint256 amountToUnlock, uint256 withdrawableFunds, address guy);
    event AskToUnlockFund(uint256 amountToUnlock, address guy, TWithdraw withdrawDDetails);
    event AskToUnlockFund2(uint256 amountToUnlock, address guy, uint256 val);
    event Withdraw(address guy, uint256 amount, uint256 plannedAmount);

    uint256                         maxFundCandidate              = 15;
    uint256                         loanAfterLockingDurationInSec = 0;          // (for V2) une fois que pret est terminé, combien de temps on donne de sursit pour qu'il paye. En V1 : 0 -->  aucun sursit
    uint256                         marketSalesFeeInM100          = 20 *100;    // 20% in M100 format

    mapping(address => bool)        public  registeredLenders;
    mapping(address => TLender)     public  lenders;
                       address[]    public  lendersWallets;

    mapping(address => TFund[])     public  lenderFunds;
    mapping(uint256 => TFund)       public  funds;               // list of funds by HASH
                       uint256[]    public  fundHashes;

    mapping(address => TFund[])     public  lenderHistoryFunds;

    mapping(address => TWithdraw[]) public  lenderWithdraws;
    mapping(uint256 => TWithdraw)   public  withdraws;
                       uint256[]    public  withdrawHashes;

    mapping(address => TBalances)   public  lenderBalances;

  
    mapping(address => bool)        public  registeredBorrowers;
    mapping(address => TBorrower)   public  borrowers;
                       address[]    public  borrowersWallets;


    mapping(address => TLoan[])     public  nftOwnerLoans;
    mapping(uint256 => TLoan)       public  loans;
                       uint256[]    public  loanHashes;

    mapping(uint256 => TLoanFund[]) public  loanFunds;



    //-----------------------------------------------------------------------------
    function    addFund(uint256 amount, address guy) public
    {
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

        TFund memory fund = TFund
        (
            guy,                            // lender wallet
            amount,                         // total    amount of the FUND
            amount,                         // unused   amount
            0,                              // lent     amount (non for now)
            0,                              // unlocked amount (not yet)
            block.timestamp,                // date of the deposit
            block.timestamp+0,//30*86400,   // this fund can't be withdrawn before this timestamp
            hash
        );

        funds[hash] = fund;

        lenderFunds[guy].push(fund);
        
        fundHashes.push(hash);

        //-----

        TBalances storage balance = lenderBalances[guy];

        balance.unusedAmount = balance.idleAmount.add(amount);

        updateLenderBalances(guy, 0);           // 0 means don't update withdrawn balance
    }
    //-----------------------------------------------------------------------------
    function    askToUnlockFund(uint256 amountToUnlock, address guy) public returns(bool)
    {
        uint256 nFund             = lenderFunds[guy].length;
        uint256 withdrawableFunds = 0;

        for(uint256 i; i<nFund; i++)
        {
            TFund memory fund = lenderFunds[guy][i];

            withdrawableFunds = withdrawableFunds.add(fund.unusedAmount);
        }

        if (withdrawableFunds < amountToUnlock)             // The lender asks more than what's available
        {
            emit AskToUnlockFund_Error_AskedToMuch(amountToUnlock, withdrawableFunds, guy);
            return false;
        }

        uint256 leftAmount = amountToUnlock;

        for(uint256 i; i<nFund; i++)
        {
            TFund storage fund = lenderFunds[guy][i];

            uint256 unusedAmount = fund.unusedAmount;

            if (unusedAmount==0)          continue;

            if (leftAmount >= unusedAmount)
            {
                leftAmount = leftAmount.sub(unusedAmount);

                fund.unusedAmount = 0;
                fund.sideAmount   = fund.sideAmount.add(unusedAmount);
            }
            else                                                // il y a un residu a traiter
            {
                //leftAmount = 0;

                fund.unusedAmount = fund.unusedAmount.sub(leftAmount);
                fund.sideAmount   = fund.sideAmount.add(leftAmount);
                break;
            }
        }

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

        emit AskToUnlockFund(amountToUnlock, guy, withdraw);

        //----

        updateLenderBalances(guy, 0);           // 0 means don't update withdrawn balance

        return true;
    }
    //-----------------------------------------------------------------------------
    function    withdrawFund(uint256 index, address guy) public returns(bool)
    {
        uint256     n = lenderWithdraws[guy].length;

        if (index>=n)
        {
            emit WithdrawFund_Error_Index(index, n, guy);
            return false;
        }

        TWithdraw storage withdraw = lenderWithdraws[guy][index];

        if (block.timestamp < withdraw.unlockEpoch)            // It's not yet the moment
        {
            emit WithdrawFund_Error_NotYet(index, n, guy);
            return false;
        }

        uint256 amountToWithdraw = withdraw.askedAmount;

        //-----

        uint256 nFund        = lenderFunds[guy].length;
        uint256 amountToSend = 0;

        for(uint256 i; i<nFund; i++)
        {
            TFund memory fund = lenderFunds[guy][i];

            uint256 sideAmount = fund.sideAmount;

            if (sideAmount==0)          continue;

            if (amountToWithdraw >= sideAmount)
            {
                amountToSend     = amountToSend.add(sideAmount);
                amountToWithdraw = amountToWithdraw.sub(sideAmount);
                
                lenderFunds[guy][i].sideAmount = 0;             // We used all available
            }
            else                                                // il y a un residu a traiter
            {
                amountToSend = amountToSend.add(amountToWithdraw);          // amountToWithdraw is the residual amount

                //amountToWithdraw = 0;
                lenderFunds[guy][i].sideAmount = fund.sideAmount.sub(amountToWithdraw);
                break;
            }
        }

        //-----

        updateLenderBalances(guy, lenders[guy].withdrawnAmount+amountToSend);       // 2nd param is the new withdrawAmount (updated)

        withdraw.isDone = true;

        /////
        /////payable(guy).transfer(amountToSend);
        /////

        emit Withdraw(guy, amountToSend, withdraw.askedAmount);

        return true;
    }
    //-----------------------------------------------------------------------------
    function    updateLenderBalances(address guy, uint256 updatedWithdrawAmount) internal
    {
        uint256 nFund        = lenderFunds[guy].length;
        uint256 fundedAmount = 0;
        uint256 unusedAmount = 0;
        uint256 lentAmount   = 0;
        uint256 sideAmount   = 0;

        for(uint256 i; i<nFund; i++)
        {
            TFund memory fund = lenderFunds[guy][i];

            fundedAmount = fundedAmount.add(fund.fundedAmount);
            unusedAmount = unusedAmount.add(fund.unusedAmount);
            lentAmount   = lentAmount.add(fund.lentAmount);
            sideAmount   = sideAmount.add(fund.sideAmount);
        }

        //-----

        TBalances storage balance = lenderBalances[guy];

        balance.fundedAmount = fundedAmount;
        balance.unusedAmount = unusedAmount;
        balance.lentAmount   = lentAmount;
        balance.sideAmount   = sideAmount;

        //-----

        TLender storage lender = lenders[guy];

        lender.fundedAmount = fundedAmount;
        lender.unusedAmount = unusedAmount;
        lender.lentAmount   = lentAmount;
        lender.sideAmount   = sideAmount;

        if (updatedWithdrawAmount!=0)   
        {
            balance.withdrawnAmount = updatedWithdrawAmount;
            lender.withdrawnAmount  = updatedWithdrawAmount;
        }
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
    function    liquidLender(address guy) external onlyOwner
    {
        uint256 withdrawableAmount = 0;                 // There can be LOANS in progress, so it may be possible to recall this function again, to fully liquid it

        uint256 nFund = lenderFunds[guy].length;

        for(uint256 i; i<nFund; i++)
        {
            TFund storage fund = lenderFunds[guy][i];

            withdrawableAmount = withdrawableAmount.add(fund.unusedAmount);
            withdrawableAmount = withdrawableAmount.add(fund.sideAmount);

            fund.unusedAmount = 0;
            fund.sideAmount   = 0;
        }
        
        //----- create a withdraw objet for proof

        uint256 hash = forgeHash(withdrawableAmount, guy, block.timestamp, withdrawHashes.length);

        TWithdraw memory withdraw = TWithdraw
        (
            guy, 
            withdrawableAmount,
            block.timestamp + 0,//30*86400,
            true,                               // true=DONE because we are paying immediately
            hash
        );

        lenderWithdraws[guy].push(withdraw);
        withdrawHashes.push(hash);
        withdraws[hash] = withdraw;

        //-----

        updateLenderBalances(guy, withdrawableAmount);

        /////
        /////payable(guy).transfer(withdrawableAmount);
        /////

        emit Withdraw(guy, withdrawableAmount, withdrawableAmount);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    _LEND_A() external
    {
        addFund(1, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(2, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(3, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(4, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
    }
    //-----------------------------------------------------------------------------
    function    _LEND_B() external
    {
        askToUnlockFund(8, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
    }
    //-----------------------------------------------------------------------------
    function    _LEND_C() external
    {
        withdrawFund(0, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
    }
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
        TLoanFund[] memory fundCandidates = collectFundCandidatesForALoan(loanAmount);

        uint256 nFund = fundCandidates.length;

        if (nFund==0)
        {
            return false;
        }

        if (interestPercentInM100 > 70*100)
        {
            return false;
        }

        uint256 amountToBeLent = 0;

        for (uint256 i; i<nFund; i++)
        {
            TLoanFund memory candidate = fundCandidates[i];

            TFund storage fund = funds[ candidate.fundHash ];

            fund.unusedAmount = fund.unusedAmount.sub( candidate.usedAmount );
            fund.lentAmount   = fund.unusedAmount.add( candidate.usedAmount );
            amountToBeLent    = amountToBeLent.add(    candidate.usedAmount );

            //-----

            TLender storage lender = lenders[fund.lenderWallet];

            lender.unusedAmount = lender.unusedAmount.sub( candidate.usedAmount );
            lender.lentAmount   = lender.lentAmount.add(   candidate.usedAmount );

            //-----

            TBalances storage balance = lenderBalances[ fund.lenderWallet ];

            balance.unusedAmount = lender.unusedAmount;
            balance.lentAmount   = lender.lentAmount;
        }

        uint256 interestAmount = amountToBeLent.mul( interestPercentInM100 ).div( 100*100 );

        //-----

        uint256 loanHash     = forgeLoanHash(collectionAddress,collectionTokenId,nftOwnerAddress, loanAmount, block.timestamp);
        uint256 resalesPrice = loanAmount.add( loanAmount.mul( marketSalesFeeInM100 ).div(100*100));

        TLoan memory loan = TLoan
        (
            collectionAddress,
            collectionTokenId,
            nftOwnerAddress,
            loanHash,
            durationInSec,
            block.timestamp,                                                    // "since"  mais la personne n'a pas encore lancer, alors =0
            block.timestamp + durationInSec,                                    //loadEndTimestamp;           // Quand est-ce que l'emprunt s'arretera
            block.timestamp + durationInSec + loanAfterLockingDurationInSec,    //realEndTimestamp;           // (for V2) on va donner un delai pour rembourser. Si le temps a depasser cette valeur, le gars pourra plus rembourser
            loanAmount,
            interestAmount,
            loanAmount + interestAmount,
            LoanMode.CREATED,
            resalesPrice
        );

        loans[loanHash] = loan;

        nftOwnerLoans[nftOwnerAddress].push(loan);
        
        loanHashes.push(loanHash);

        //----- copy fund candidates

        for (uint256 i; i<nFund; i++)
        {
            TLoanFund memory loanFund = fundCandidates[i];

            uint256 fundInterestGainAmount = loanFund.usedAmount.mul( interestPercentInM100 ).div( 100*100 );

            loanFunds[loanHash].push( TLoanFund
            (
                loanFund.usedAmount,
                loanFund.fundHash,
                fundInterestGainAmount              // This is what we will distribute as interest Gain to the fund owner (=lender)
            ));
        }

        return true;
    }
   //-----------------------------------------------------------------------------
    function    closeLoan(uint256 index, address guy) public returns(bool)
    {
        uint256 nLoan = loanHashes.length;

        if (index>=nLoan)
        {
            return false;
        }

        //-----

        uint256 loanHash = loanHashes[index] ;
        uint256 nFund    = loanFunds[ loanHash ].length;

        for(uint256 i; i<nFund; i++)
        {
            TLoanFund memory loanFund = loanFunds[loanHash][i];
            uint256          fundHash = fundHashes[ loanFund.fundHash ];
            TFund storage    fund     = funds[fundHash];

            fund.lentAmount = fund.lentAmount.sub( loanFund.usedAmount );
            fund.sideAmount = fund.sideAmount.add( loanFund.gainAmount );
        }

        updateLenderBalances(guy, 0);

        //-----

        return true;
    }
    //-----------------------------------------------------------------------------
     function    collectFundCandidatesForALoan(uint256 loanAmount) 
                    internal 
                    view
                    returns(TLoanFund[] memory)
    {
        uint256     nFundToScan      = fundHashes.length;
        uint256     amountLeft       = loanAmount;
        uint256     nFundFound       = 0;

        for(uint256 i; i<nFundToScan; i++)
        {
            TFund memory fund = funds[ fundHashes[i]];

            if (fund.unusedAmount==0)   continue;           // not enough funds to create a loan

            nFundFound++;

            if (fund.unusedAmount >= amountLeft)
            {
                //amountLeftToLoan = 0;       // useless code
                break;
            }
            else
            {
                amountLeft = amountLeft.sub( fund.unusedAmount);
            }
        }

        //-----

        uint256     amountLeftToLoan = loanAmount;

        TLoanFund[] memory fundCandidates = new TLoanFund[](nFundFound);

        uint256 g=0;

        for(uint256 i; i<nFundToScan; i++)
        {
            TFund memory fund = funds[ fundHashes[i] ];

            if (fund.unusedAmount==0)   continue;           // not enough funds to create a loan

            if (fund.unusedAmount >= amountLeftToLoan)
            {
                fundCandidates[g] = TLoanFund
                (
                    amountLeftToLoan,
                    fund.hash,
                    0
                );

                g++;
                //amountLeftToLoan = 0;       // useless code
                break;
            }
            else
            {
                amountLeftToLoan = amountLeftToLoan.sub( fund.unusedAmount );

                fundCandidates[g] = TLoanFund
                (
                    fund.unusedAmount,
                    fund.hash,
                    0
                );

                g++;
            }
        }

        return fundCandidates;
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
    function    _BORROW_A() external
    {
        addFund(100000, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(200000, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(300000, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
        addFund(400000, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
    }
    //-----------------------------------------------------------------------------
    function    _BORROW_B() external
    {
        createLoan( 0xd96268797e666E9eaE7e2Ef16969Ce8221B9f6D9,1, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68, 10, 700000, 10 *100 );
    }
    //-----------------------------------------------------------------------------
    function    _BORROW_C() external
    {
        closeLoan(0, 0xaC410DFa874DC3e285663Dd615802973Cb23aA68);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------

}