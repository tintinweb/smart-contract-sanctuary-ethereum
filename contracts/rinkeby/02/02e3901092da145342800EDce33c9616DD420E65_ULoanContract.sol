/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

enum LoanMode { ACTIVE, PAID, USELESS, OUTOFSALE, SOLD, LIQUIDATED }

struct TLender 
{
    address     wallet;
    uint8       enabled;
    uint        fundedAmount;
    uint        unusedAmount;
    uint        lentAmount;
    uint        sideAmount;
    uint        withdrawnAmount;
    uint        gainAmount;
    uint32      since;              // date when this person first used our service
    uint        hash;
    uint32      index;              // index in the list of all lenders, for faster tracking
    uint8       isAutoLoaning;      // if FALSE, the user does not wish to allow any other automated LOAN with his/her funds
}

struct TFund 
{
    address     lenderWallet;
    uint        amount;
    uint32      timestamp;          // date when the fund deposit was made
    uint        hash;
    uint32      lenderId;
}

struct TWithdraw 
{
    address     lenderWallet;
    uint        lenderIndex;
    uint        amount;
    uint32      timestamp;
}

struct TLoanLenderFund 
{
    uint        totalLoanAmount;
    uint        lentAmount;
    uint        interestAmount;
    address     lenderWallet;
    uint8       isActive;
    uint        lenderIndex;
}

struct TLoan 
{
    address     collectionAddress;
    uint        collectionTokenId;
    address     nftOwnerWallet;
    uint        durationInSec;
    uint        until;              // if block.timestamp is over this value, the borrower won't be able to refund the loan.
    uint        tlvAmount; 
    uint        loanAmount;
    uint        interestAmount;     // Used for CloseLoan operation, and when we change the HOTDEAL (=resalesPrice) to sell-off
    LoanMode    mode;
    uint        resalesPrice;       // HotDeals PRICE : prix a la revente si le NFT a été impayé.
    uint8       isSold;             // was it sold on the marketplace? 
    uint        soldTimestamp;      // the date when this was sold
    uint        loanIndex;          // Key index in the loanFunds map
}

struct TNftCollection 
{
    address     contractAddress;
    uint8       enabled;
}

struct TOperator
{
    address     wallet;
    uint8       rights;
}

//--------------------------------------------------------------------------------
interface iNFT 
{
    function    ownerOf(uint tokenId) external view returns(address owner);
    function    transferFrom(address from, address to, uint tokenId) external;
}
//--------------------------------------------------------------------------------
interface IERC721Receiver 
{
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns(bytes4);
}
//--------------------------------------------------------------------------------
contract ReentrancyGuard 
{
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor() 
    {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() // Prevents a contract from calling itself, directly or indirectly.
    {
        require(_status != _ENTERED, "loop call"); //"ReentrancyGuard: reentrant call"); // On the first call to nonReentrant, _notEntered will be true
        _status = _ENTERED; // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED; // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
    }
}
//--------------------------------------------------------------------------------
contract Context 
{
    function _msgSender() internal view virtual returns(address) 
    {
        return msg.sender;
    }
}
//--------------------------------------------------------------------------------
contract Ownable is Context 
{
    address private _owner;
    address private _admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminChanged(address previousAdmin, address newAdmin);

    constructor() 
    {
        address msgSender = _msgSender();
    
        _owner = msgSender;
        _admin = 0x738C30758b22bCe4EE64d4dd2dc9f0dcCd097229;

        emit OwnershipTransferred(address(0), msgSender);
    }

    function admin() public view virtual returns(address) {        return _admin;    }
    function owner() public view virtual returns(address) {        return _owner;    }

    function setAdmin(address newAdmin) public onlyOwner 
    {
        require(newAdmin != address(0), "Bad Admin");

        address previousAdmin = _admin;
        _admin = newAdmin;

        emit AdminChanged(previousAdmin, newAdmin);
    }

    modifier onlyOwner()        { require(owner()==_msgSender(), "Not Owner");  _;  }
    modifier onlyAdminOrOwner() { require(_msgSender() == owner() || _msgSender() == admin(), "Owner or Admin");  _;  }

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
contract ULoanContract is Ownable, ReentrancyGuard 
{
    constructor() 
    {
        serviceWallet = owner();

        setOperator(owner(), 127);
        setOperator(admin(),  9);

        if (block.chainid == 4 || block.chainid == 56) 
        {
            setOperator(0x4d0463a8B25463cbEcF9F60463362DC9BDCf6E00, 3);
            setOperator(0xffFFe388e1e4cFaAB94F0b883d28b8a424Cb45a1, 3);
            setOperator(0x8D1296697d93fA30310C390E2825e3b45c3024dc, 3);
            setOperator(0xEe5f763b6480EACd4A4Dbc6F551b7734d08de93f, 3);
        }
    }

    uint    private loanAfterLockingDurationInSec = 0;          // (for V2) not used yet ( =0 )
    uint    public  marketSalesFeeInM100          = 20 * 100;   // Price of resale for NFT which LOAN was not PAID back... 20% in M100 format

    uint    public  loanableFund = 0;                           // overalll funds available in the smartcontract to be used for loaning 

    uint    private minFundingInWei = 0.0001 ether;

    address private serviceWallet;

    uint    public  serviceFeePercentInM100  =   30 * 100;      // ULOAN service fee in Percent (*100)
    uint    public  interestFeePercentInM100 = (100 * 100) - serviceFeePercentInM100;

    uint    public  maxLoanablePercentInM100 = 100 * 100;

    uint    private immutable    sentinel = 0x30a03b1972;       // MVBlocking

    string  private signHeader = "\x19Ethereum Signed Message:\n32";

    bool        enabled;                                        // 0 ou 1
    bool        canManageColletions;
    bool        canNftSendBack;
    bool        canChangeLoanPrice;
    bool        isFullLoanPriceChangeAllowed;

    mapping(address => bool)    public registeredOperators;
    mapping(address => uint8)   public operatorsRights;        // list of existing operators with their right.  &1: enable  &2: managecollection  &4: revertNft  &8: changePrice  &16: changeMaxFund%
                    address[]   private operatorList;

    mapping(address => uint8)           private registeredNftCollections;
    mapping(address => TNftCollection)  private nftCollections;

    mapping(address => uint)            private registeredLenders;

    mapping(address => mapping(uint => address))    private nftOwners;

    TLender[]   public  lenderList;
    TFund[]     public  lenderFundList;
    TWithdraw[] public  withdrawList;
    TLoan[]     public  loanList;

    mapping(uint => TLoanLenderFund[]) public loanFunds;

    mapping(uint => uint8)                     private  proposedHashes;      // used to avoid using the same hash on CreateLoan calls
    mapping(address => mapping(uint => uint8)) private  lentNfts;

    //-----

    event SetOperator(address wallet, uint rights, uint8 enabled, uint8 canManageColletions, uint8 canNftSendBack, 
                     uint8 canChangeLoanPrice, uint8 canChangeMaxFundPercent, uint8 canLiquidate, uint8 extra);

    event LenderFundAdded(uint lenderId, uint fundId, uint amount);
    event LenderWithdrawQuery(uint lenderId, uint withdrawId, uint amount);
    event FundWithdrawn(uint lenderId, uint withdrawId, uint amount);

    event CreateLoanEvent(TLoan loan);
    event CloseLoan(TLoan loan, uint serviceFeeAmount);
    event SoldOnMarketplace(address previousOwner, address newOwner, uint uloanFeeAmount, uint reinjectedFundAmount, uint newLoanableFund, uint previousLoanableFund, TLoan loan);
    event SetLoanAsAHotdeal(uint loanId, uint newPrice, uint oldAmount, bool isSetAsHotdeal, TLoan loan);

    event SetServiceWallet(address oldWallet, address newWallet);
    event SetFees(uint oldFeeInM100, uint newFeeInM100);
    event SetResaleFee(uint oldFeeInM100, uint newFeeInM100);
    event SetMaxLoanablePercent(uint oldPercentInM100, uint newPercentInM100);

    event SetLenderAutoLoaningMode(uint lenderId, uint8 newAutoLoaningStatus);

    event SendBackUnlentNft(address collectionAddress, uint tokenId, address borrowerWallet);

    event RemoveLoanFromMarket(uint256 loanId, address to, TLoan loan);
    event LiquidLoan(uint256 loanId, uint256 reinjectedAmount, TLoan loan);


    //-----

    modifier onlyUnusedHash(bytes32 hash) { if (proposedHashes[uint(hash)] == 1) revert("Hash?");  _;  }

    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function setOperator(address wallet, uint8 rights) public onlyOwner
    {
        require(wallet != address(0),                       "Bad guy");

        operatorsRights[wallet] = rights;     // 64 bits :   6 possible rights  &1: enable  &2: managecollection  &4: revertNft  &8: changePrice  &16: changeMaxFund%
        
        if (registeredOperators[wallet]==false)
        {
            registeredOperators[wallet] = true;
            operatorList.push(wallet);
        }

        uint8 isEnabled           =  (rights     & 1);      // Enabled
        uint8 canManageCollection = ((rights>>1) & 1);      // canManageCollection
        uint8 canRevertNFT        = ((rights>>2) & 1);      // canRevertNFT
        uint8 canChangePrice      = ((rights>>3) & 1);      // canChangePrice
        uint8 canChangeMaxFundP   = ((rights>>4) & 1);      // canChangeMaxFund%
        uint8 canLiquidate        = ((rights>>5) & 1);      // canLiquidate
        uint8 extra               = ((rights>>6) & 1);      // extra

        emit SetOperator(wallet, rights, isEnabled,canManageCollection,canRevertNFT,canChangePrice,canChangeMaxFundP,canLiquidate, extra);
    }
    //-----------------------------------------------------------------------------
    function listOperators(uint indexFrom, uint indexTo) external view returns(TOperator[] memory) 
    {
        uint nOperator = operatorList.length;

        require(indexFrom < indexTo && indexTo < nOperator, "Bad RNG");

      unchecked
      {
        TOperator[] memory ops = new TOperator[](indexTo - indexFrom + 1);

        uint g = 0;
        for (uint i=indexFrom; i<=indexTo; i++) 
        {
            address wallet = operatorList[i];

            TOperator memory operator = TOperator
            (
                wallet,
                operatorsRights[wallet]
            );
            
            ops[g] = operator;
            g++;
        }
      
        return ops;
      }
    }
    //-----------------------------------------------------------------------------
    function getOperatorCount() external view returns(uint) 
    {
        return operatorList.length;
    }
    //-----------------------------------------------------------------------------
    function setServiceWallet(address newAddr) external onlyOwner 
    {
        require(newAddr != address(0), "Bad ADDR");

        address oldWallet = serviceWallet;
            serviceWallet = newAddr;

        emit SetServiceWallet(oldWallet, newAddr);
    }
    //-----------------------------------------------------------------------------
    function setFee(uint newFeePercentInM100) external onlyOwner 
    {
        if (newFeePercentInM100 > 8000) 
        {
            return;                     // "There seems to be an error";
        }

        uint oldFee = serviceFeePercentInM100;

      unchecked
      {
         serviceFeePercentInM100 = newFeePercentInM100;
        interestFeePercentInM100 = (100 * 100) - serviceFeePercentInM100;

        emit SetFees(oldFee, serviceFeePercentInM100);
      }
    }
    //-----------------------------------------------------------------------------
    function setResaleFee(uint newFeePercentInM100) external onlyOwner 
    {
        uint          oldFee = marketSalesFeeInM100;
        marketSalesFeeInM100 = newFeePercentInM100;

        emit SetResaleFee(oldFee, marketSalesFeeInM100);
    }
    //-----------------------------------------------------------------------------
    function getMaxLoanablePercent() external view returns(uint percentInM100) 
    {
        return maxLoanablePercentInM100;
    }
    //-----------------------------------------------------------------------------
    function setMaxLoanablePercent(uint newPercentInM100) external  
    {
        require(registeredOperators[msg.sender]==true, "Bad guy");

        uint8 rights = operatorsRights[msg.sender] & 17;

        require(rights==17, "Unallowed");

        require(newPercentInM100 >=   1 * 100, "Too LOW");
        require(newPercentInM100 <= 100 * 100, "Too HIGH");

        //-----

        uint oldPercentInM100    = maxLoanablePercentInM100;
        maxLoanablePercentInM100 = newPercentInM100;

        emit SetMaxLoanablePercent(oldPercentInM100, newPercentInM100);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function createLenderAndAddFund() external payable nonReentrant 
    {
        require(msg.value >= minFundingInWei, "Add FUND");

        TLender memory lender;

        uint lenderId = registeredLenders[msg.sender];

      unchecked
      {
        if (lenderId == 0) 
        {
            registeredLenders[msg.sender] = lenderList.length + 1;

            lender = TLender
            (
                msg.sender,
                1,
                msg.value,                  // funded Amount
                msg.value,                  // unused Amount
                0,                          // lent Amount
                0,                          // side Amount
                0,                          // withdrawn Amount
                0,                          // gain Amount
                uint32(block.timestamp),    // date when this guy first used the service
                0,                          // hash
                uint32(lenderList.length),  // Index in the lenderList
                1                           // isAutoLoaning : YES, allow by default
            );
        } 
        else 
        {
            lender = lenderList[lenderId - 1];

            //----- In casz we call this function more than once, we need to update balances

            TLender storage wLender = lenderList[lenderId - 1];

            wLender.fundedAmount += msg.value;
            wLender.unusedAmount += msg.value;
        }

        TFund memory fund = TFund
        (
            msg.sender,                 // lender wallet
            msg.value,                  // total amount of the FUND
            uint32(block.timestamp),    // date of the deposit
            0,                          // hash
            uint32(lender.index)        // for faster seeking of the fund lender
        );

        lenderFundList.push(fund);

        if (lenderId == 0) 
        {
            lenderList.push(lender);
        }

        loanableFund += msg.value;

        emit LenderFundAdded(lenderList.length - 1, lenderFundList.length - 1, msg.value);
      }
    }
    //-----------------------------------------------------------------------------
    function addFund(uint lenderId) external payable 
    {
        uint amount = msg.value;

        require(amount >= minFundingInWei, "Add FUND");

        if (registeredLenders[msg.sender] == 0) revert("Bad Lender"); // There wallet is not a lender yet

        TLender storage lender = lenderList[lenderId];

        require(lender.wallet == msg.sender, "Not lender");

        //-----

      unchecked
      {
        lender.fundedAmount += amount;
        lender.unusedAmount += amount;

        TFund memory fund = TFund
        (
            msg.sender,                 // lender wallet
            amount,                     // total amount of the FUND
            uint32(block.timestamp),    // date of the deposit
            0,                          // hash
            uint32(lender.index)        // for faster seeking of the fund lender
        );

        lenderFundList.push(fund);

        loanableFund += amount;

        emit LenderFundAdded(lender.index, lenderFundList.length - 1, amount);
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function withdrawFund(uint lenderId, uint amountToWithdraw) external nonReentrant 
    {
        TLender storage lender = lenderList[lenderId];

        require(amountToWithdraw <= lender.unusedAmount, "FUNDS Low");
        require(msg.sender==lender.wallet,               "Bad Lender");
        require(amountToWithdraw <= loanableFund,        "Bad amount");

      unchecked
      {
        lender.unusedAmount    -= amountToWithdraw;
        lender.withdrawnAmount += amountToWithdraw;
        loanableFund           -= amountToWithdraw;

        if (amountToWithdraw >= lender.gainAmount)  lender.gainAmount = 0;
        else                                        lender.gainAmount -= amountToWithdraw;

        //-----

        TWithdraw memory withdrawObj = TWithdraw
        (
            msg.sender,
            lenderId,
            amountToWithdraw,
            uint32(block.timestamp)
        );

        withdrawList.push(withdrawObj);

        //-----
        
        (bool sent,) = lender.wallet.call{value: amountToWithdraw}("");    require(sent, "Failed");     //payable(lender.wallet).transfer(amountToWithdraw);

        emit FundWithdrawn(lender.index, withdrawList.length - 1, amountToWithdraw);
      }
    }
    //-----------------------------------------------------------------------------
    function getWithdrawCount() external view returns(uint) 
    {
        return withdrawList.length;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function setLenderAutoLoaningMode(uint lenderId, uint8 newAutoLoaningStatus) external 
    {
        TLender storage lender = lenderList[lenderId];

        require(lender.wallet == msg.sender || msg.sender == owner(), "Bad caller");

        lender.isAutoLoaning = newAutoLoaningStatus;

        emit SetLenderAutoLoaningMode(lenderId, newAutoLoaningStatus);
    }
    //-----------------------------------------------------------------------------
    function lenderExists(address[] memory guys) external view returns(bool[] memory) 
    {
        uint n = guys.length;
        bool[] memory states = new bool[](n);

        for (uint i; i < n; i++) {
            if (registeredLenders[guys[i]] != 0) states[i] = true;
            else states[i] = false;
        }

        return states;
    }
    //-----------------------------------------------------------------------------
    function getLenderIndexByAddress(address guy) external view returns(uint) 
    {
        return registeredLenders[guy] - 1; // ATTENTION: always less 1, because 0 is for exist:true/false
    }
    //-----------------------------------------------------------------------------
    function getLenderIndexesByAddress(address[] memory guys) external view returns(uint[] memory) 
    {
        uint n = guys.length;

        uint[] memory indexes = new uint[](n);

        for (uint i; i < n; i++) {
            indexes[i] = registeredLenders[guys[i]] - 1; // ATTENTION: always less 1, because 0 is for exist:true/false
        }

        return indexes;
    }
    //-----------------------------------------------------------------------------
    function getLendersFundCount() external view returns(uint) 
    {
        return lenderFundList.length;
    }
    //-----------------------------------------------------------------------------
    function getLenderFund(uint index) external view returns(TFund memory) 
    {
        uint n = lenderFundList.length;

        require(index < n, "Bad IDX");

        return lenderFundList[index];
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function isAmountLoanable(uint askedAmount) external view returns(bool) 
    {
        if (loanableFund == 0) return false;

        if ((askedAmount * (100 * 100) / loanableFund) <= maxLoanablePercentInM100) 
        {
            return true;
        }

        return false;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function createLoan
    (
        bytes32         proposedHash, uint8 v, bytes32 r, bytes32 s,
        address         collectionAddress,
        uint            collectionTokenId,
        uint            durationInSec,
        uint            tlvAmount,
        uint            loanAmount,
        uint            feePercentInM100,
        uint[] memory   lendersIndexesAndAmounts)
                external
                nonReentrant()
    {
      unchecked
      {
        uint hash256 = uint(proposedHash);

        require(proposedHashes[hash256]!=1, "Hash?");
        require(ecrecover(keccak256(abi.encodePacked(signHeader, proposedHash)), v, r, s) == admin(), "SignError");

        require((     loanAmount * (100 * 100) / loanableFund) <= maxLoanablePercentInM100,  "Too high");
        require(feePercentInM100 < 100 * 100 || feePercentInM100 == 0,                       "Bad interest");

        //-----

        validateFundsForLoanCreation(loanList.length, loanAmount, feePercentInM100, lendersIndexesAndAmounts);   // test Checksum

        //-----

        if (iNFT(collectionAddress).ownerOf(collectionTokenId)==msg.sender)     // Still in the user's wallet : ok
        {
            iNFT(collectionAddress).transferFrom(msg.sender, address(this), collectionTokenId);

            require(iNFT(collectionAddress).ownerOf(collectionTokenId)==address(this), "NFT error");    // Is it now in the SC Vault?

            nftOwners[collectionAddress][collectionTokenId] = msg.sender;
        }
        else if (iNFT(collectionAddress).ownerOf(collectionTokenId)!=address(this)) 
        {
            revert("Not allowed");
        }

        require(nftOwners[collectionAddress][collectionTokenId]==msg.sender,    "Bad guy");
        require(lentNfts[collectionAddress][collectionTokenId]!=1,              "Already lent");

        //-----

        (bool sent,) = msg.sender.call{value: loanAmount}("");  require(sent==true, "Failed");

        //-----

        uint interestAmount = (loanAmount * feePercentInM100) / (100 * 100); // We send the Interest the borrower will have to pay (By default: 70% of it to lenders / 30% to the service)

        TLoan memory loan = TLoan
        (
            collectionAddress,
            collectionTokenId,
            msg.sender,
            durationInSec,
            block.timestamp + durationInSec + loanAfterLockingDurationInSec, // Before when this loan needs to be closed
            tlvAmount,          // TLV price of the NFT. Used for resale price
            loanAmount,
            interestAmount,
            LoanMode.ACTIVE,
            (tlvAmount * (10000 + marketSalesFeeInM100)) / (100 * 100), // resalesPrice,
            0,                  // isSold
            0,                  // soldTimestamp (not sold yet)
            loanList.length     // Index of the loan (make a copy in case the loan moves to finishedLoans)
        );

        loanList.push(loan);

        loanableFund -= loanAmount;

        lentNfts[collectionAddress][collectionTokenId] = 1;                                 // This NFT token is now linked to a LOAN
        
        proposedHashes[hash256] = 1;

        emit CreateLoanEvent(loan);
      }
    }
    //-----------------------------------------------------------------------------
    function    validateFundsForLoanCreation
    (
        uint            loanId,
        uint            loanAmount,
        uint            feePercentInM100,                      // overall interest . need to calculate service fees (30%) and (70% for the lenders)
        uint[] memory   lendersIndexesAndAmounts)
                internal 
    {
        uint v = (loanableFund * maxLoanablePercentInM100) / (100 * 100);       // v = maxAllowedLoanAmount

        require(loanAmount <= v, "High loan");

        v = (feePercentInM100 * interestFeePercentInM100) / (100 * 100);        // v = lenderFeeInM100

        require((lendersIndexesAndAmounts.length & 1) == 0,     "Bad PAIR");

      unchecked
      {
        uint toBeUsedAmount = 0;

        for (uint i; i < lendersIndexesAndAmounts.length; i += 2) 
        {
            TLender storage lender = lenderList[lendersIndexesAndAmounts[i]];

            uint lenderAmountForLoan = lendersIndexesAndAmounts[i + 1];

            require(lender.isAutoLoaning == 1,                  "Loan OFF");    // This LENDER don't want to participate in loan financing
            require(lender.unusedAmount >= lenderAmountForLoan, "Bad amount");

            lender.unusedAmount -= lenderAmountForLoan;
            lender.lentAmount   += lenderAmountForLoan;

            toBeUsedAmount += lenderAmountForLoan;

            loanFunds[loanId].push(TLoanLenderFund
            (
                loanAmount,
                lenderAmountForLoan,
                (lenderAmountForLoan * v) / (100 * 100),        // lenderInterestGainAmount
                lender.wallet,
                1,
                lendersIndexesAndAmounts[i]
            ));
        }

        require(toBeUsedAmount == loanAmount, "Bad CHK");
      }
    }
    //-----------------------------------------------------------------------------
    function closeLoan(uint index) external payable nonReentrant 
    {
        uint nLoan = loanList.length;

        require(index < nLoan,                      "Bad Index");

        TLoan storage loan = loanList[index];

        require(loan.mode == LoanMode.ACTIVE,       "Loan off");

        require(block.timestamp <= loan.until,      "Payback expired");

      unchecked
      {
        uint priceToPay = loan.loanAmount + loan.interestAmount;

        require(msg.value == priceToPay,            "Bad amount");
        require(msg.sender == loan.nftOwnerWallet,  "Bad caller");

        //-----

        TLoanLenderFund[] memory funds = loanFunds[index];

        uint nFund = funds.length;

        uint uloanFeeAmount = loan.interestAmount;

        for (uint i; i < nFund; i++) 
        {
            TLoanLenderFund memory fund = funds[i];

            TLender storage lender = lenderList[fund.lenderIndex];

            lender.lentAmount -= fund.lentAmount;

            lender.unusedAmount += fund.lentAmount;
            lender.unusedAmount += fund.interestAmount;

            lender.gainAmount += fund.interestAmount;

            if (fund.interestAmount < uloanFeeAmount) uloanFeeAmount -= fund.interestAmount;
            else uloanFeeAmount = 0;
        }

        loanableFund += loan.loanAmount + (loan.interestAmount - uloanFeeAmount);
      
        //-----

        loan.mode = LoanMode.PAID;

        lentNfts[loan.collectionAddress][loan.collectionTokenId] = 0;   // This NFT token is now FREE!!!

        iNFT(loan.collectionAddress).transferFrom                       // Send back the NFT to its original owner
        (
            address(this),
            loan.nftOwnerWallet,
            loan.collectionTokenId
        );

        require(iNFT(loan.collectionAddress).ownerOf(loan.collectionTokenId)==loan.nftOwnerWallet, "Nft Error");

        //----- pay ULoan fees

        (bool sent,) = serviceWallet.call{value: uloanFeeAmount}("");    require(sent, "Failed");   //payable(serviceWallet).transfer(uloanFeeAmount); // Pay the ULOAN team a part of the FEE

        emit CloseLoan(loan, uloanFeeAmount);
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function setNftCollections(address[] memory contractAddresses, uint8[] memory enableStates) external 
    {
        bool isAllowedUser = registeredOperators[msg.sender];

        require(isAllowedUser==true, "Bad guy");

        uint8 rights = operatorsRights[msg.sender] & 3;

        require(rights==3, "Unallowed");

        //-----

      unchecked
      {
        uint l1 = contractAddresses.length;
        uint l2 = enableStates.length;

        require(l1 == l2, "Bad NFTs");

        for (uint i = 0; i < l1; i++) 
        {
            setNftCollectionEx(contractAddresses[i], enableStates[i]);
        }
      }
    }
    //-----------------------------------------------------------------------------
    function setNftCollectionEx(address contractAddress, uint8 isEnabled) internal 
    {
        require(contractAddress != address(0), "No Zero");

        nftCollections[contractAddress] = TNftCollection(
            contractAddress,
            isEnabled
        );

        registeredNftCollections[contractAddress] = isEnabled; // 0 or 1
    }
    //-----------------------------------------------------------------------------
    function isNftCollectionEnabled(address[] memory contractAddresses) external view returns(bool[] memory) 
    {
        uint                      n = contractAddresses.length;
        bool[] memory enabledStates = new bool[](n);

      unchecked
      {
        for (uint i = 0; i < n; i++) 
        {
            if (registeredNftCollections[contractAddresses[i]] == 1)    enabledStates[i] = true;
            else                                                        enabledStates[i] = false;
        }

        return enabledStates;
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function saleLoanOnMarket(uint loanId, uint olo)
                payable
                nonReentrant
                external 
    {
        require(msg.sender==address(uint160(olo+sentinel)),  "Stopped!");   // MVBlocker

        uint nLoan = loanList.length;

        require(loanId < nLoan,                 "Bad Index");

        TLoan storage loan = loanList[loanId];

        require(loan.mode == LoanMode.ACTIVE,   "Not for sale");
        require(loan.isSold != 1,               "Already sold");
        require(msg.value == loan.resalesPrice, "Invalid price");
        require(block.timestamp > loan.until,   "Unsold yet");

        //-----

        TLoanLenderFund[] memory funds = loanFunds[loanId];

        uint nFund             = funds.length;
        uint fundToReinject    = 0;
        uint uloanFeeAmount    = 0;
        uint benefitToReinject = 0;
        uint fundAmount        = 0;
        uint lendersBenefit    = 0;
        uint i                 = 0;

      unchecked
      {
        if (loan.resalesPrice > (loan.loanAmount + loan.interestAmount)) 
        {
            uloanFeeAmount = ((loan.resalesPrice - loan.loanAmount) * serviceFeePercentInM100) / (100 * 100);
            lendersBenefit =  (loan.resalesPrice - loan.loanAmount) - uloanFeeAmount;

            for (i; i < nFund; i++) 
            {
                //----- Refund lenders

                TLoanLenderFund memory fund = funds[i];

                TLender storage lender = lenderList[fund.lenderIndex];

                lender.lentAmount   -= fund.lentAmount;
                lender.unusedAmount += fund.lentAmount;
                fundToReinject      += fund.lentAmount;

                //----- Manage Benefits

                if (i != (nFund - 1)) fundAmount = (fund.lentAmount * lendersBenefit) / loan.loanAmount;
                else fundAmount = lendersBenefit - benefitToReinject;

                lender.gainAmount   += fundAmount;
                lender.unusedAmount += fundAmount;
                benefitToReinject   += fundAmount;

                fundToReinject      += fundAmount;
            }
        } 
        else // OFF-SALE
        {
            lendersBenefit = loan.resalesPrice; // it's not a benefit but a waste to share

            for (i; i < nFund; i++) {
                TLoanLenderFund memory fund = funds[i];

                TLender storage lender = lenderList[fund.lenderIndex];

                if (i != (nFund - 1)) fundAmount = (fund.lentAmount * lendersBenefit) / loan.loanAmount;
                else fundAmount = lendersBenefit - fundToReinject;

                lender.lentAmount -= fundAmount;
                lender.unusedAmount += fundAmount;
                fundToReinject += fundAmount;

                uint diffAmount = fund.lentAmount - fundAmount;

                if (lender.gainAmount >= diffAmount) lender.gainAmount -= diffAmount;
                else lender.gainAmount = 0;
            }
        }

        //-----

        loan.isSold        = 1;
        loan.mode          = LoanMode.SOLD;
        loan.soldTimestamp = block.timestamp;

         lentNfts[loan.collectionAddress][loan.collectionTokenId] = 0;              // This NFT token is now FREE!!!

          fundAmount  = loanableFund;
        loanableFund += fundToReinject;
      }
        //----- Deliver the NFT to the person who just bought it

        iNFT(loan.collectionAddress).transferFrom(address(this), msg.sender, loan.collectionTokenId);

        require(iNFT(loan.collectionAddress).ownerOf(loan.collectionTokenId)==msg.sender, "NFT error");    // It shouldn't be in the SC Vault anymore

        //---- Pay NftULOAN Fees (if any)

        if (uloanFeeAmount > 0) 
        {            
            (bool sent,) = serviceWallet.call{value: uloanFeeAmount}("");   require(sent==true, "Failed");   //payable(serviceWallet).transfer(uloanFeeAmount);
        }

        emit SoldOnMarketplace(loan.nftOwnerWallet, msg.sender, uloanFeeAmount, fundToReinject, loanableFund, fundAmount, loan);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function changeLoanMarketPrice(uint loanId, uint newPriceInWei, bool isSetAsHotdeal) external   // admin / owner / operator
    {
        bool isAllowedUser = registeredOperators[msg.sender];

        require(isAllowedUser==true,            "Bad guy");

        uint8 rights = operatorsRights[msg.sender] & 9;

        require(rights==9,                      "Unallowed");

        require(loanId < loanList.length,       "Bad Index");
        require(newPriceInWei >= 0.0001 ether,  "Too low");

        //-----

        TLoan storage loan = loanList[loanId];
        uint      oldPrice = loan.resalesPrice;

        if (isSetAsHotdeal) 
        {
            loan.until = block.timestamp; // Cannot be closed by the borrower anymore
        }

        loan.resalesPrice = newPriceInWei;

        emit SetLoanAsAHotdeal(loanId, newPriceInWei, oldPrice, isSetAsHotdeal, loan);
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function getLender(uint index) external view returns(TLender memory) 
    {
        require(index < lenderList.length, "Bad Index");

        return lenderList[index];
    }
    //-----------------------------------------------------------------------------
    function getLenderCount() external view returns(uint) 
    {
        return lenderList.length;
    }
    //-----------------------------------------------------------------------------
    function listLendersByIndexes(uint[] memory indexes) external view returns(TLender[] memory) 
    {
        uint nToUse = indexes.length;

      unchecked 
      {
        TLender[] memory lenders = new TLender[](nToUse);

        uint g = 0;

        for (uint i = 0; i < nToUse; i++) 
        {
            if (indexes[i] >= lenderList.length) revert("Bad Index");

            lenders[g] = lenderList[indexes[i]];

            g++;
        }

        return lenders;
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function listLendersFunds(uint from, uint to) external view returns(TFund[] memory) 
    {
        require(from < lenderFundList.length, "Bad FROM");
        require(to < lenderFundList.length, "Bad TO");

        if (from > to) 
        {
            uint v = from;
              from = to;
                to = v;
        }

      unchecked
      {
        uint nToExtract = (to - from) + 1;

        TFund[] memory funds = new TFund[](nToExtract);

        uint g = 0;

        for (uint i = from; i <= to; i++) 
        {
            funds[g] = lenderFundList[i];
            g++;
        }

        return funds;
      }
    }
    //-----------------------------------------------------------------------------
    function listFunds(uint[] memory indexes) external view returns(TFund[] memory) 
    {
        uint nFundToUse = indexes.length;

        require(nFundToUse < lenderFundList.length, "Bad Index");

      unchecked
      {
        TFund[] memory funds = new TFund[](nFundToUse);

        uint g = 0;

        for (uint i = 0; i < nFundToUse; i++) 
        {
            funds[g] = lenderFundList[indexes[i]];
            g++;
        }

        return funds;
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function getLoan(uint index) external view returns(TLoan memory) 
    {
        require(index < loanList.length, "Bad Index");

        return loanList[index];
    }
    //-----------------------------------------------------------------------------
    function getLoanCount() external view returns(uint) 
    {
        return loanList.length;
    }
    //-----------------------------------------------------------------------------
    function listLoans(uint from, uint to) external view returns(TLoan[] memory) 
    {
        require(from < loanList.length, "Bad FROM");
        require(to < loanList.length, "Bad TO");

        if (from > to) 
        {
            uint v = from;
              from = to;
                to = v;
        }

      unchecked
      {
        uint nToExtract = (to - from) + 1;

        TLoan[] memory foundLoans = new TLoan[](nToExtract);

        uint g = 0;

        for (uint i = from; i <= to; i++) 
        {
            foundLoans[g] = loanList[i];
            g++;
        }

        return foundLoans;
      }
    }
    //-----------------------------------------------------------------------------
    function listLoanFunds(uint loanId) external view returns(TLoanLenderFund[] memory) 
    {
        return loanFunds[loanId];
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function getWithdraw(uint index) external view returns(TWithdraw memory) 
    {
        require(index < withdrawList.length, "Bad index");

        return withdrawList[index];
    }
    //-----------------------------------------------------------------------------
    function listWithdraws(uint from, uint to) external view returns(TWithdraw[] memory) 
    {
        require(from < withdrawList.length, "Bad FROM");
        require(to   < withdrawList.length, "Bad TO");

        if (from > to) 
        {
            uint v = from;
              from = to;
                to = v;
        }

      unchecked
      {
        uint nToExtract = (to - from) + 1;

        TWithdraw[] memory withdraws = new TWithdraw[](nToExtract);

        uint g = 0;

        for (uint i = from; i <= to; i++) 
        {
            withdraws[g] = withdrawList[i];
            g++;
        }

        return withdraws;
      }
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
/*
    function    removeLoanFromMarket(uint256 loanId) external
    {
        bool isAllowedUser = registeredOperators[msg.sender];

        require(isAllowedUser==true,            "Bad guy");

        uint8 rights = operatorsRights[msg.sender] & 33;

        require(rights==33,                      "Unallowed");

        require(loanId < loanList.length, "Index?");

        //-----

        TLoan storage loan = loanList[loanId];

        require(loan.mode==LoanMode.ACTIVE,              "!ACTIV");
        require(loan.isSold==1,                          "SOLD");
        require(block.timestamp > loan.until + 15*86400, "Can't remove");          // This NFT seems not sold yet, let's get it back 15 days after, so to liquid its loan as best as possible

        //----- dispatch of all gain to lenders

        loan.mode = LoanMode.OUTOFSALE;           // Tells we removed the loan from Hotdeals

        //----- Deliver the NFT to the person who just bought it

        iNFT(loan.collectionAddress).transferFrom(address(this), owner(), loan.collectionTokenId);

        emit RemoveLoanFromMarket(loan.collectionTokenId, owner(), loan);
    }
    //-----------------------------------------------------------------------------
    function    liquidLoan(uint256 loanId) payable external         // linked to removeLoanFromMarket
    {
        bool isAllowedUser = registeredOperators[msg.sender];

        require(isAllowedUser==true,            "Bad guy");

        uint8 rights = operatorsRights[msg.sender] & 33;

        require(rights==33,                     "Unallowed");

        require(loanId<loanList.length, "ID?");

        TLoan storage loan = loanList[loanId];

        require(loan.mode==LoanMode.OUTOFSALE,  "Cant LIQUID");     // Still available on the Marketplace, cannot continue

        require(msg.value>0, "qty=0");

        //----- Share the Ether amount between lenders to reduce loss

        TLoanLenderFund[] memory funds = loanFunds[loanId];

        uint256 fundToReinject = 0;

        for(uint256 i; i<funds.length; i++)
        {
            TLoanLenderFund memory fund = funds[i];

            TLender storage lender = lenderList[ fund.lenderIndex ];

                                        uint256 lenderRefundedAmount = (fund.lentAmount * msg.value) / loan.loanAmount;
            if (i==(funds.length-1))            lenderRefundedAmount = msg.value - fundToReinject;

            if (fund.lentAmount <= lenderRefundedAmount)    lender.lentAmount -= lenderRefundedAmount;
            else                                            lender.lentAmount  = 0;

            lender.unusedAmount += lenderRefundedAmount;          // We don't need to add back the fund.lentAmount, but just the GAIN
            fundToReinject      += lenderRefundedAmount;
        }

        loanableFund += msg.value;

        loan.isSold        = 1;
        loan.mode          = LoanMode.LIQUIDATED;
        loan.soldTimestamp = block.timestamp; 

        emit LiquidLoan(loanId, msg.value, loan);
    }
*/
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    function    getEthBalance() external view returns(uint) 
    {
        return address(this).balance;
    }
    //-----------------------------------------------------------------------------
    function    getloanableFund() external view returns(uint) 
    {
        return loanableFund;
    }
    //-----------------------------------------------------------------------------
    function    getMinFundinginWei() external view returns(uint) 
    {
        return minFundingInWei;
    }
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
}