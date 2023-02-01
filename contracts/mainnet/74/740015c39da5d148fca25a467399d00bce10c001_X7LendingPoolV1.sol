/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for originating initial liquidity loans and managing payments and distributions

The critical usage functions on this contract are:

    // Used to get a quote for a loan according to a specific borrower, loan term, amount, and duration
    function getDiscountedQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) external view returns (uint256[7] memory);

    // Used to originate the actual loan
    function getInitialLiquidityLoan(
        address tokenAddress,
        uint256 amount,
        address loanTermContract,
        uint256 loanAmount,
        uint256 loanDurationSeconds,
        address liquidityReceiver,
        uint256 deadline
    ) external lock payable returns (uint256 loanID);

    // Used to pay against any outstanding loan liability. See the loan term contract to understand how payment is applied.
    function payLiability(uint256 loanID) external lock payable;

    // Used to see the amount of the loan that can be liquidated. If the amount is greater than 0 the loan is eligible for a liquidation event.
    // For the initial loan terms any past due payments makes the entire loan eligible for liquidation
    function canLiquidate(uint256 loanID) external view returns (uint256)

    // Used to liquidate the loan. If the loan term allows, this will only be a partial liquidation.
    // The initial loan terms all liquidate in full.
    function liquidate(uint256 loanID) external lock;

    // Used to check the cost to buyout the loan (this is the remaining principal due)
    function buyoutLoanQuote(uint256 loanID) external view returns (uint256);

    // Used to buy out the loan. Doing so will cause the loan term NFT to be transferred to the caller
    function buyoutLoan(uint256 loanID) external payable;

    // Used to buy out the loan to a specific address. This will cause the loan term NFT to be transferred to the specified address
    function buyoutLoanTo(uint256 loanID, address to) external payable;

    Please see provided technical documentation for a full description of all the functionality of this contract.

There is an operational function that allows for ETH held by this contract to be returned to the lending pool reserve. A caller must be a capital manager to call this. This contract is an X7D minter but not an X7D redeemer. As such capital may need to be transferred back to the reserve pool on an as needed basis to ensure depositors are always capable of withdrawing their X7D deposits.

    function returnETHToLendingPoolReserve(uint256 amount) external {
        require(authorizedCapitalManagers[msg.sender]);
        require(amount > address(this).balance);
        require(lendingPoolReserve != address(0));
        X7DMinter(lendingPoolReserve).returnETH{value: amount}();
    }

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setEcosystemRecipientAddress(address recipient) external onlyOwner {
        require(ecosystemRecipient != recipient);
        address oldRecipient = ecosystemRecipient;
        ecosystemRecipient = recipient;
        emit EcosystemRecipientSet(oldRecipient, recipient);
    }

    function setRouter(address routerAddress) external onlyOwner {
        require(address(router) != routerAddress);
        address oldRouter = address(router);
        router = IXchangeRouter(routerAddress);
        emit RouterSet(oldRouter, routerAddress);
    }

    function setWETH(address wethAddress) external onlyOwner {
        require(weth != wethAddress);
        address oldWethAddress = weth;
        weth = wethAddress;
        emit WETHSet(oldWethAddress, wethAddress);
    }

    function setX7D(address X7DAddress) external onlyOwner {
        require(address(X7D) != X7DAddress);
        address oldAddress = address(X7D);
        X7D = IX7D(X7DAddress);
        emit X7DSet(oldAddress, X7DAddress);
    }

    function setLoanTermActiveState(address loanTermAddress, bool isActive) external onlyOwner {
        require(loanTermActive[loanTermAddress] != isActive);
        loanTermActive[loanTermAddress] = isActive;

        if (isActive) {
            activeLoanTerms.push(loanTermAddress);
            loanTermIndex[loanTermAddress] = activeLoanTerms.length - 1;
        } else {
            address otherLoanTermAddress = activeLoanTerms[activeLoanTerms.length-1];
            activeLoanTerms[loanTermIndex[loanTermAddress]] = otherLoanTermAddress;
            loanTermIndex[otherLoanTermAddress] = loanTermIndex[loanTermAddress];
            delete loanTermIndex[loanTermAddress];
            activeLoanTerms.pop();
        }

        emit LoanTermActiveStateSet(loanTermAddress, isActive);
    }

    function setLiquidationReward(uint256 reward) external onlyOwner {
        require(liquidationReward != reward);
        uint256 oldReward = liquidationReward;
        liquidationReward = reward;
        emit LiquidationRewardSet(oldReward, reward);
    }

    function setOriginationShares(
        uint256 ecosystemSplitterOriginationShare_,
        uint256 X7DAOOriginationShare_,
        uint256 X7100OriginationShare_,
        uint256 lendingPoolOriginationShare_
    ) external onlyOwner {
        require(ecosystemSplitterOriginationShare_ + X7DAOOriginationShare_ + X7100OriginationShare_ + lendingPoolOriginationShare_ == 10000);

        uint256 oldEcosystemSplitterOriginationShare = ecosystemSplitterOriginationShare;
        uint256 oldX7DAOOriginationShare = X7DAOOriginationShare;
        uint256 oldX7100OriginationShare = X7100OriginationShare;
        uint256 oldLendingPoolOriginationShare = lendingPoolOriginationShare;

        ecosystemSplitterOriginationShare = ecosystemSplitterOriginationShare_;
        X7DAOOriginationShare = X7DAOOriginationShare_;
        X7100OriginationShare = X7100OriginationShare_;
        lendingPoolOriginationShare = lendingPoolOriginationShare_;

        emit OriginationSharesSet(
            oldEcosystemSplitterOriginationShare,
            oldX7DAOOriginationShare,
            oldX7100OriginationShare,
            oldLendingPoolOriginationShare,
            ecosystemSplitterOriginationShare_,
            X7DAOOriginationShare_,
            X7100OriginationShare_,
            lendingPoolOriginationShare_
        );
    }

    function setPremiumShares(
        uint256 ecosystemSplitterPremiumShare_,
        uint256 X7DAOPremiumShare_,
        uint256 X7100PremiumShare_,
        uint256 lendingPoolPremiumShare_
    ) external onlyOwner {
        require(ecosystemSplitterPremiumShare_ + X7DAOPremiumShare_ + X7100PremiumShare_ + lendingPoolPremiumShare_ == 10000);

        uint256 oldEcosystemSplitterPremiumShare = ecosystemSplitterPremiumShare;
        uint256 oldX7DAOPremiumShare = X7DAOPremiumShare;
        uint256 oldX7100PremiumShare = X7100PremiumShare;
        uint256 oldLendingPoolPremiumShare = lendingPoolPremiumShare;

        ecosystemSplitterPremiumShare = ecosystemSplitterPremiumShare_;
        X7DAOPremiumShare = X7DAOPremiumShare_;
        X7100PremiumShare = X7100PremiumShare_;
        lendingPoolPremiumShare = lendingPoolPremiumShare_;

        emit PremiumSharesSet(
            oldEcosystemSplitterPremiumShare,
            oldX7DAOPremiumShare,
            oldX7100PremiumShare,
            oldLendingPoolPremiumShare,
            ecosystemSplitterPremiumShare_,
            X7DAOPremiumShare_,
            X7100PremiumShare_,
            lendingPoolPremiumShare_
        );
    }

    function setEcosystemSplitter(address recipient) external onlyOwner {
        require(ecosystemSplitter != recipient);
        address oldEcosystemSplitterAddress = ecosystemSplitter;
        ecosystemSplitter = recipient;
        emit EcosystemSplitterSet(oldEcosystemSplitterAddress, recipient);
    }

    function setX7100ReserveRecipient(address recipient) external onlyOwner {
        require(X7100ReserveRecipient != recipient);
        address oldX7100ReserveRecipient = X7100ReserveRecipient;
        X7100ReserveRecipient = recipient;
        emit X7100ReserveRecipientSet(oldX7100ReserveRecipient, recipient);
    }

    function setX7DAORewardRecipient(address recipient) external onlyOwner {
        require(X7DAORewardRecipient != recipient);
        address oldX7DAORewardRecipient = X7DAORewardRecipient;
        X7DAORewardRecipient = recipient;
        emit X7DAORewardRecipientSet(oldX7DAORewardRecipient, recipient);
    }

    function setDiscountAuthority(address discountAuthorityAddress) external onlyOwner {
        require(address(discountAuthority) != discountAuthorityAddress);

        address oldDiscountAuthority = address(discountAuthority);

        discountAuthority = IX7LendingDiscountAuthority(discountAuthorityAddress);

        emit DiscountAuthoritySet(oldDiscountAuthority, discountAuthorityAddress);
    }

    function setRetainedFeeNumerator(uint256 numerator) external onlyOwner {
        require(retainedFeeNumerator != numerator);
        uint256 oldRetainedFeeNumerator = retainedFeeDenominator;
        retainedFeeNumerator = numerator;

        emit RetainedFeeNumeratorSet(oldRetainedFeeNumerator, numerator);
    }

    function setLendingPoolReserve(address reserveAddress) external onlyOwner {
        require(lendingPoolReserve != reserveAddress);

        address oldLendingPoolReserve = lendingPoolReserve;
        lendingPoolReserve = reserveAddress;

        emit LendingPoolReserveSet(oldLendingPoolReserve, reserveAddress);

    }

    function setLendingHalted(bool isHalted) external onlyOwner {
        require(lendingHalted != isHalted);
        lendingHalted = isHalted;

        if (isHalted) {
            emit LendingHalted();
        } else {
            emit LendingCommenced();
        }
    }

    function setAllowLoanBuyout(bool isAllowed) external onlyOwner {
        require(allowLoanBuyout != isAllowed);
        allowLoanBuyout = isAllowed;

        emit LoanBuyoutAllowed(isAllowed);
    }

    function setAuthorizedCapitalManager(address manager, bool isTrusted) external onlyOwner {
        require(authorizedCapitalManagers[manager] != isTrusted);
        authorizedCapitalManagers[manager] = isTrusted;

        emit AuthorizedCapitalManagerSet(manager, isTrusted);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IX7D {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IX7LendingTerm {
    function createLoan() external returns (uint256);
    function fundLoan(uint256 loanID) external;


}

// 1. Loan origination fee
// 2. Loan retention premium fee schedule
// 3. Principal repayment condition/maximum loan duration
// 4. Liquidation conditions and Reward
// 5. Loan duration

interface IX7LendingDiscountAuthority {
    function getFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external view returns (uint256, uint256);

    function useFeeModifiers(
        address borrower,
        uint256[3] memory loanAmountDetails,
        uint256[3] memory loanDurationDetails
    ) external returns (uint256, uint256);
}

interface IX7InitialLiquidityLoanTerm {

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function originateLoan(
        uint256 loanAmount,
        uint256 originationFee,
        uint256 loanLengthSeconds_,

        uint256 premiumFeeModifierNumerator_,
        uint256 originationFeeModifierNumerator_,

        address receiver,
        uint256 tokenId
    ) external payable;

    function minimumLoanAmount() external view returns (uint256);
    function maximumLoanAmount() external view returns (uint256);
    function minimumLoanLengthSeconds() external view returns (uint256);
    function maximumLoanLengthSeconds() external view returns (uint256);

    function getPrincipalDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getPremiumsDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getTotalDue(uint256 loanID, uint256 asOf) external view returns (uint256);
    function getRemainingLiability(uint256 loanID) external view returns (uint256);
    function getPremiumPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory);
    function getPrincipalPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory);

    function isComplete(uint256 loanID) external view returns (bool);
    function getOriginationAmounts(uint256 loanAmount) external view returns (uint256 loanAmountRounded, uint256 originationFee);
    function getQuote(uint256 loanAmount) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium);
    function getDiscountedQuote(uint256 loanAmount_, uint256 premiumFeeModifier, uint256 originationFeeModifier) external view returns (uint256 loanAmountRounded, uint256 originationFee, uint256 totalPremium);
    function recordPrincipalRepayment(uint256 loanID, uint256 amount) external returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability);
    function recordPayment(uint256 loanID, uint256 amount) external returns (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability);
    function liquidationAmount(uint256 loanID) external view returns (uint256);

    function loanAmount(uint256 loanID) external view returns (uint256);
    function principalAmountPaid(uint256 loanID) external view returns (uint256);

}


interface IXchangeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IXchangeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IXchangePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function syncSafe(uint256, uint256) external;
    function withdrawTokensAgainstMinimumBalance(address tokenAddress, address to, uint112 amount) external returns (uint256);
    function setMinimumBalance(address tokenAddress, uint112 minimumAmount) external;
    function tokenMinimumBalance(address) external view returns (uint256);
}

interface X7DMinter {
    event FundsReturned(address indexed sender, uint256 amount);

    // Call this function to explicitly mint X7D
    function depositETH() external payable;

    // Call this function to return ETH to this contract without minting X7D
    function returnETH() external payable;

    // Call this function to mint X7D to a recipient of your choosing
    function depositETHForRecipient(address recipient) external payable;
}

contract X7LendingPoolV1 is X7DMinter, Ownable {

    mapping(address => bool) public loanTermActive;
    address[] public activeLoanTerms;
    mapping(address => uint256) loanTermIndex;

    mapping(uint256 => address) public loanTermLookup;
    mapping(uint256 => address) public loanPair;
    mapping(uint256 => address) public loanToken;
    mapping(uint256 => uint256) public loanLiquidationReward;
    mapping(uint256 => address) public loanLiquidationReturnTo;

    mapping(address => uint256[]) public loanLookupByBorrower;
    mapping(uint256 => address) public loanBorrower;
    mapping(uint256 => uint256) loanBorrowerIndex;

    uint256 public nextLoanID = 1;
    bool lendingHalted = true;
    bool allowLoanBuyout = false;

    IX7LendingDiscountAuthority public discountAuthority;
    mapping(address => bool) public authorizedCapitalManagers;

    address public lendingPoolReserve;

    address public ecosystemSplitter;
    address public X7100ReserveRecipient;
    address public X7DAORewardRecipient;
    IX7D public X7D;

    uint256 public ecosystemSplitterPremiumShare;
    uint256 public X7DAOPremiumShare;
    uint256 public X7100PremiumShare;
    uint256 public lendingPoolPremiumShare;

    uint256 public ecosystemSplitterOriginationShare;
    uint256 public X7DAOOriginationShare;
    uint256 public X7100OriginationShare;
    uint256 public lendingPoolOriginationShare;

    IXchangeRouter public router;
    address public weth;
    address public ecosystemRecipient;

    uint256 public liquidationEscrow;
    uint256 public liquidationReward;

    uint256 public retainedFeeNumerator;
    uint256 public retainedFeeDenominator = 100;

    uint256 public syncSafeGasAmount = 100000;

    event EcosystemRecipientSet(address oldAddress, address newAddress);
    event RouterSet(address oldAddress, address newAddress);
    event WETHSet(address oldAddress, address newAddress);
    event X7DSet(address oldAddress, address newAddress);
    event LoanTermActiveStateSet(address indexed newAddress, bool isActive);
    event LiquidationRewardSet(uint256 oldReward, uint256 newReward);
    event OriginationSharesSet(
        uint256 oldEcosystemSplitterOriginationShare,
        uint256 oldX7DAOOriginationShare,
        uint256 oldX7100OriginationShare,
        uint256 oldLendingPoolOriginationShare,
        uint256 newEcosystemSplitterOriginationShare,
        uint256 newX7DAOOriginationShare,
        uint256 newX7100OriginationShare,
        uint256 newLendingPoolOriginationShare
    );
    event PremiumSharesSet(
        uint256 oldEcosystemSplitterOriginationShare,
        uint256 oldX7DAOOriginationShare,
        uint256 oldX7100OriginationShare,
        uint256 oldLendingPoolOriginationShare,
        uint256 newEcosystemSplitterOriginationShare,
        uint256 newX7DAOOriginationShare,
        uint256 newX7100OriginationShare,
        uint256 newLendingPoolOriginationShare
    );
    event EcosystemSplitterSet(address oldAddress, address newAddress);
    event X7100ReserveRecipientSet(address oldAddress, address newAddress);
    event X7DAORewardRecipientSet(address oldAddress, address newAddress);
    event DiscountAuthoritySet(address oldAddress, address newAddress);
    event RetainedFeeNumeratorSet(uint256 oldValue, uint256 newValue);
    event LendingPoolReserveSet(address oldAddress, address newAddress);
    event LendingHalted();
    event LendingCommenced();
    event AuthorizedCapitalManagerSet(address managerAddress, bool isTrusted);
    event LoanBuyoutAllowed(bool isAllowed);
    event SyncSafeGasAmountSet(uint256 oldValue, uint256 newValue);
    event LoanBoughtOut(address indexed buyer, uint256 indexed loanID);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LendingPool: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address routerAddress) Ownable(msg.sender) {
        router = IXchangeRouter(routerAddress);
    }

    receive () external payable {}

    function activeLoansByBorrower(address borrower) external view returns (uint256) {
        return loanLookupByBorrower[borrower].length;
    }

    function countOfActiveLoanTerms() external view returns (uint256) {
        return activeLoanTerms.length;
    }

    function availableCapital() external view returns (uint256) {
        return address(this).balance - liquidationEscrow;
    }

    function getDiscountedQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) external view returns (uint256[7] memory) {
        require(loanTerm.minimumLoanAmount() <= loanAmount);
        require(loanTerm.maximumLoanAmount() >= loanAmount);
        require(loanTerm.minimumLoanLengthSeconds() <= loanDurationSeconds);
        require(loanTerm.maximumLoanLengthSeconds() >= loanDurationSeconds);
        return _getDiscountedQuote(borrower, loanTerm, loanAmount, loanDurationSeconds);
    }

    function canLiquidate(uint256 loanID) external view returns (uint256) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        return loanTerm.liquidationAmount(
            loanID
        );
    }

    function getPrincipalDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        return loanTerm.getPrincipalDue(loanID, asOf);
    }

    function getPremiumsDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        return loanTerm.getPremiumsDue(loanID, asOf);
    }

    function getTotalDue(uint256 loanID, uint256 asOf) external view returns (uint256) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        return loanTerm.getTotalDue(loanID, asOf);
    }

    function getRemainingLiability(uint256 loanID) external view returns (uint256) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        return loanTerm.getRemainingLiability(loanID);
    }

    function getPremiumPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        (uint256[] memory dueDates, uint256[] memory paymentAmounts) = loanTerm.getPremiumPaymentSchedule(loanID);
        return (dueDates, paymentAmounts);
    }

    function getPrincipalPaymentSchedule(uint256 loanID) external view returns (uint256[] memory, uint256[] memory) {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        (uint256[] memory dueDates, uint256[] memory paymentAmounts) = loanTerm.getPrincipalPaymentSchedule(loanID);
        return (dueDates, paymentAmounts);
    }

    function getQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) external view returns (uint256[5] memory) {
        require(loanTerm.minimumLoanAmount() <= loanAmount);
        require(loanTerm.maximumLoanAmount() >= loanAmount);
        require(loanTerm.minimumLoanLengthSeconds() <= loanDurationSeconds);
        require(loanTerm.maximumLoanLengthSeconds() >= loanDurationSeconds);
        return _getQuote(borrower, loanTerm, loanAmount, loanDurationSeconds);
    }

    function buyoutLoanQuote(uint256 loanID) external view returns (uint256) {
        require(allowLoanBuyout);
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        address owner_ = loanTerm.ownerOf(loanID);
        require(owner_ == address(this));

        uint256 buyoutAmount = loanTerm.loanAmount(loanID) - loanTerm.principalAmountPaid(loanID);
        return buyoutAmount;
    }

    function setEcosystemRecipientAddress(address recipient) external onlyOwner {
        require(ecosystemRecipient != recipient);
        address oldRecipient = ecosystemRecipient;
        ecosystemRecipient = recipient;
        emit EcosystemRecipientSet(oldRecipient, recipient);
    }

    function setRouter(address routerAddress) external onlyOwner {
        require(address(router) != routerAddress);
        address oldRouter = address(router);
        router = IXchangeRouter(routerAddress);
        emit RouterSet(oldRouter, routerAddress);
    }

    function setWETH(address wethAddress) external onlyOwner {
        require(weth != wethAddress);
        address oldWethAddress = weth;
        weth = wethAddress;
        emit WETHSet(oldWethAddress, wethAddress);
    }

    function setX7D(address X7DAddress) external onlyOwner {
        require(address(X7D) != X7DAddress);
        address oldAddress = address(X7D);
        X7D = IX7D(X7DAddress);
        emit X7DSet(oldAddress, X7DAddress);
    }

    function setLoanTermActiveState(address loanTermAddress, bool isActive) external onlyOwner {
        require(loanTermActive[loanTermAddress] != isActive);
        loanTermActive[loanTermAddress] = isActive;

        if (isActive) {
            activeLoanTerms.push(loanTermAddress);
            loanTermIndex[loanTermAddress] = activeLoanTerms.length - 1;
        } else {
            address otherLoanTermAddress = activeLoanTerms[activeLoanTerms.length-1];
            activeLoanTerms[loanTermIndex[loanTermAddress]] = otherLoanTermAddress;
            loanTermIndex[otherLoanTermAddress] = loanTermIndex[loanTermAddress];
            delete loanTermIndex[loanTermAddress];
            activeLoanTerms.pop();
        }

        emit LoanTermActiveStateSet(loanTermAddress, isActive);
    }

    function setLiquidationReward(uint256 reward) external onlyOwner {
        require(liquidationReward != reward);
        uint256 oldReward = liquidationReward;
        liquidationReward = reward;
        emit LiquidationRewardSet(oldReward, reward);
    }

    function setOriginationShares(
        uint256 ecosystemSplitterOriginationShare_,
        uint256 X7DAOOriginationShare_,
        uint256 X7100OriginationShare_,
        uint256 lendingPoolOriginationShare_
    ) external onlyOwner {
        require(ecosystemSplitterOriginationShare_ + X7DAOOriginationShare_ + X7100OriginationShare_ + lendingPoolOriginationShare_ == 10000);

        uint256 oldEcosystemSplitterOriginationShare = ecosystemSplitterOriginationShare;
        uint256 oldX7DAOOriginationShare = X7DAOOriginationShare;
        uint256 oldX7100OriginationShare = X7100OriginationShare;
        uint256 oldLendingPoolOriginationShare = lendingPoolOriginationShare;

        ecosystemSplitterOriginationShare = ecosystemSplitterOriginationShare_;
        X7DAOOriginationShare = X7DAOOriginationShare_;
        X7100OriginationShare = X7100OriginationShare_;
        lendingPoolOriginationShare = lendingPoolOriginationShare_;

        emit OriginationSharesSet(
            oldEcosystemSplitterOriginationShare,
            oldX7DAOOriginationShare,
            oldX7100OriginationShare,
            oldLendingPoolOriginationShare,
            ecosystemSplitterOriginationShare_,
            X7DAOOriginationShare_,
            X7100OriginationShare_,
            lendingPoolOriginationShare_
        );
    }

    function setPremiumShares(
        uint256 ecosystemSplitterPremiumShare_,
        uint256 X7DAOPremiumShare_,
        uint256 X7100PremiumShare_,
        uint256 lendingPoolPremiumShare_
    ) external onlyOwner {
        require(ecosystemSplitterPremiumShare_ + X7DAOPremiumShare_ + X7100PremiumShare_ + lendingPoolPremiumShare_ == 10000);

        uint256 oldEcosystemSplitterPremiumShare = ecosystemSplitterPremiumShare;
        uint256 oldX7DAOPremiumShare = X7DAOPremiumShare;
        uint256 oldX7100PremiumShare = X7100PremiumShare;
        uint256 oldLendingPoolPremiumShare = lendingPoolPremiumShare;

        ecosystemSplitterPremiumShare = ecosystemSplitterPremiumShare_;
        X7DAOPremiumShare = X7DAOPremiumShare_;
        X7100PremiumShare = X7100PremiumShare_;
        lendingPoolPremiumShare = lendingPoolPremiumShare_;

        emit PremiumSharesSet(
            oldEcosystemSplitterPremiumShare,
            oldX7DAOPremiumShare,
            oldX7100PremiumShare,
            oldLendingPoolPremiumShare,
            ecosystemSplitterPremiumShare_,
            X7DAOPremiumShare_,
            X7100PremiumShare_,
            lendingPoolPremiumShare_
        );
    }

    function setEcosystemSplitter(address recipient) external onlyOwner {
        require(ecosystemSplitter != recipient);
        address oldEcosystemSplitterAddress = ecosystemSplitter;
        ecosystemSplitter = recipient;
        emit EcosystemSplitterSet(oldEcosystemSplitterAddress, recipient);
    }

    function setX7100ReserveRecipient(address recipient) external onlyOwner {
        require(X7100ReserveRecipient != recipient);
        address oldX7100ReserveRecipient = X7100ReserveRecipient;
        X7100ReserveRecipient = recipient;
        emit X7100ReserveRecipientSet(oldX7100ReserveRecipient, recipient);
    }

    function setX7DAORewardRecipient(address recipient) external onlyOwner {
        require(X7DAORewardRecipient != recipient);
        address oldX7DAORewardRecipient = X7DAORewardRecipient;
        X7DAORewardRecipient = recipient;
        emit X7DAORewardRecipientSet(oldX7DAORewardRecipient, recipient);
    }

    function setDiscountAuthority(address discountAuthorityAddress) external onlyOwner {
        require(address(discountAuthority) != discountAuthorityAddress);

        address oldDiscountAuthority = address(discountAuthority);

        discountAuthority = IX7LendingDiscountAuthority(discountAuthorityAddress);

        emit DiscountAuthoritySet(oldDiscountAuthority, discountAuthorityAddress);
    }

    function setRetainedFeeNumerator(uint256 numerator) external onlyOwner {
        require(retainedFeeNumerator != numerator);
        uint256 oldRetainedFeeNumerator = retainedFeeDenominator;
        retainedFeeNumerator = numerator;

        emit RetainedFeeNumeratorSet(oldRetainedFeeNumerator, numerator);
    }

    function setLendingPoolReserve(address reserveAddress) external onlyOwner {
        require(lendingPoolReserve != reserveAddress);

        address oldLendingPoolReserve = lendingPoolReserve;
        lendingPoolReserve = reserveAddress;

        emit LendingPoolReserveSet(oldLendingPoolReserve, reserveAddress);

    }

    function setLendingHalted(bool isHalted) external onlyOwner {
        require(lendingHalted != isHalted);
        lendingHalted = isHalted;

        if (isHalted) {
            emit LendingHalted();
        } else {
            emit LendingCommenced();
        }
    }

    function setAllowLoanBuyout(bool isAllowed) external onlyOwner {
        require(allowLoanBuyout != isAllowed);
        allowLoanBuyout = isAllowed;

        emit LoanBuyoutAllowed(isAllowed);
    }

    function setAuthorizedCapitalManager(address manager, bool isTrusted) external onlyOwner {
        require(authorizedCapitalManagers[manager] != isTrusted);
        authorizedCapitalManagers[manager] = isTrusted;

        emit AuthorizedCapitalManagerSet(manager, isTrusted);
    }

    function setSyncSafeGasAmount(uint256 amount) external onlyOwner {
        require(amount != syncSafeGasAmount);
        uint256 oldSyncSafeGasAmount = syncSafeGasAmount;
        syncSafeGasAmount = amount;
        emit SyncSafeGasAmountSet(oldSyncSafeGasAmount, amount);
    }

    function returnETHToLendingPoolReserve(uint256 amount) external {
        require(authorizedCapitalManagers[msg.sender]);
        require(amount > address(this).balance);
        require(lendingPoolReserve != address(0));
        X7DMinter(lendingPoolReserve).returnETH{value: amount}();
    }

    function getInitialLiquidityLoan(
        address tokenAddress,
        uint256 amount,
        address loanTermContract,
        uint256 loanAmount,
        uint256 loanDurationSeconds,
        address liquidityReceiver,
        uint256 deadline
    ) external lock payable returns (uint256 loanID) {
        require(!lendingHalted);
        loanID = nextLoanID;
        nextLoanID += 1;

        require(loanTermActive[loanTermContract]);
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermContract);

        loanTermLookup[loanID] = loanTermContract;

        uint256[5] memory quote = _useQuote(
            loanTerm,
            loanAmount,
            loanDurationSeconds
        );

        // Duplicates logic from loan terms
        uint256 originationFee = quote[1] * quote[4] / 10000 / 1 gwei * 1 gwei;
        uint256 roundedLoanAmount = quote[0];

        address loanOwner;
        uint256 amountToCollect;

        if (msg.value >= roundedLoanAmount + originationFee + liquidationReward) {
            // Case when externally funded
            loanOwner = msg.sender;
            amountToCollect = roundedLoanAmount + originationFee + liquidationReward;
        } else if (msg.value >= originationFee + liquidationReward) {
            require(address(this).balance - liquidationEscrow >= roundedLoanAmount);
            loanOwner = address(this);
            amountToCollect = originationFee + liquidationReward;
        } else {
            revert("Insufficient funds provided");
        }

        address pair = _addLiquidity(
            tokenAddress,
            amount,
            roundedLoanAmount,
            liquidityReceiver,
            deadline
        );

        loanPair[loanID] = pair;
        loanToken[loanID] = tokenAddress;

        loanLiquidationReward[loanID] = liquidationReward;
        loanLiquidationReturnTo[loanID] = msg.sender;
        liquidationEscrow += liquidationReward;

        loanTerm.originateLoan(
            roundedLoanAmount,
            originationFee,
            loanDurationSeconds,
            quote[3],
            quote[4],
            loanOwner,
            loanID
        );

        loanBorrower[loanID] = msg.sender;
        loanLookupByBorrower[msg.sender].push(loanID);

        if (
            loanOwner != address(this)
        ) {
            uint256 returnToSender = msg.value - amountToCollect;
            uint256 retainedFee = originationFee * retainedFeeNumerator / retainedFeeDenominator;
            _splitOriginationFee(retainedFee);
            returnToSender += (originationFee - retainedFee);
            if (returnToSender > 0) {
                (bool success,) = msg.sender.call{value: returnToSender}("");
                require(success);
            }
        } else {
            _splitOriginationFee(originationFee);
            uint256 returnToSender = msg.value - amountToCollect;
            if (returnToSender > 0) {
                (bool success,) = msg.sender.call{value: returnToSender}("");
                require(success);
            }
        }
    }

    function payLiability(uint256 loanID) external lock payable {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        address owner_ = loanTerm.ownerOf(loanID);
        if (loanTerm.isComplete(loanID) && msg.value > 0) {
            (bool success,) = msg.sender.call{value: msg.value}("");
            require(success);
            return;
        }

        (uint256 premiumPaid, uint256 principalPaid, uint256 refundAmount, uint256 remainingLiability) = loanTerm.recordPayment(
            loanID,
            msg.value
        );

        if (owner_ != address(this)) {
            uint256 toPayOwner = principalPaid;
            uint256 retainedFee = premiumPaid * retainedFeeNumerator / retainedFeeDenominator;

            _splitPremiumFee(retainedFee);
            toPayOwner += premiumPaid - retainedFee;

            if (toPayOwner > 0) {
                // Gas limit imposed to prevent owner griefing repayment
                // Failure is ignored and considered a donation to lending pool
                owner_.call{gas: 10000, value: toPayOwner}("");
            }

        } else {
            if (premiumPaid > 0) {
                _splitPremiumFee(premiumPaid);
            }
        }

        if (refundAmount > 0) {
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success);
        }

        IXchangePair pair = IXchangePair(loanPair[loanID]);
        uint256 remainingLockedCapital = pair.tokenMinimumBalance(weth);

        if (remainingLiability < remainingLockedCapital) {
            pair.setMinimumBalance(weth, uint112(remainingLiability));
        }

        if (remainingLiability == 0) {
            _payLiquidationFee(loanID, loanLiquidationReturnTo[loanID]);
            _removeLoanFromIndex(loanID);
        }
    }

    function liquidate(uint256 loanID) external lock {
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        address owner_ = loanTerm.ownerOf(loanID);

        uint256 amountToLiquidate = loanTerm.liquidationAmount(
            loanID
        );
        require(amountToLiquidate > 0);

        IXchangePair pair = IXchangePair(loanPair[loanID]);
        uint256 withdrawnTokens = pair.withdrawTokensAgainstMinimumBalance(weth, address(this), uint112(amountToLiquidate));

        // Try to sync the pair. If the paired token is malicious or broken it will not prevent a withdrawal.
        try pair.syncSafe(syncSafeGasAmount, syncSafeGasAmount) {} catch {}

        uint256 remainingLockedTokens = pair.tokenMinimumBalance(weth);

        IWETH(weth).withdraw(withdrawnTokens);

        (uint256 premiumPaid, uint256 principalPaid, uint256 excessAmount, uint256 remainingLiability) = loanTerm.recordPrincipalRepayment(loanID, withdrawnTokens);

        if (principalPaid > 0 && owner_ != address(this)) {
            // Gas limit imposed to prevent owner griefing repayment
            // Failure is ignored and considered a donation to lending pool
            owner_.call{gas: 10000, value: principalPaid}("");
        }

        if (premiumPaid > 0) {
            _splitPremiumFee(premiumPaid);
        }

        if (remainingLiability == 0 || remainingLockedTokens == 0) {
            _payLiquidationFee(loanID, msg.sender);
        }

        if (remainingLiability == 0) {
            _removeLoanFromIndex(loanID);
        }

        if (excessAmount > 0) {
            X7D.mint(ecosystemRecipient, excessAmount);
        }
    }

    function buyoutLoan(uint256 loanID) external payable {
        _buyoutLoan(loanID, msg.sender);
    }

    function buyoutLoanTo(uint256 loanID, address to) external payable {
        _buyoutLoan(loanID, to);
    }

    function depositETH() external payable {
        X7D.mint(msg.sender, msg.value);
    }

    function depositETHForRecipient(address recipient) external payable {
        X7D.mint(recipient, msg.value);
    }

    function returnETH() external payable {
        emit FundsReturned(msg.sender, msg.value);
    }

    function _buyoutLoan(uint256 loanID, address to) internal {
        require(allowLoanBuyout);
        IX7InitialLiquidityLoanTerm loanTerm = IX7InitialLiquidityLoanTerm(loanTermLookup[loanID]);
        address owner_ = loanTerm.ownerOf(loanID);
        require(owner_ == address(this));

        uint256 buyoutAmount = loanTerm.loanAmount(loanID) - loanTerm.principalAmountPaid(loanID);
        require(buyoutAmount == msg.value);
        loanTerm.transferFrom(address(this), to, loanID);
        emit LoanBoughtOut(to, loanID);
    }

    function _removeLoanFromIndex(uint256 loanID) internal {
        address borrower = loanBorrower[loanID];
        uint256 loanIndex = loanBorrowerIndex[loanID];
        uint256 length = loanLookupByBorrower[borrower].length;
        uint256 lastLoanID = loanLookupByBorrower[borrower][length-1];
        loanLookupByBorrower[borrower][loanIndex] = lastLoanID;
        loanBorrowerIndex[lastLoanID] = loanIndex;
        loanLookupByBorrower[borrower].pop();
        delete loanBorrowerIndex[loanID];
    }

    function _getQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) internal view returns (uint256[5] memory) {

        uint256 roundedLoanAmount;
        uint256 originationFee;
        uint256 totalPremium;
        uint256 premiumFeeModifier;
        uint256 originationFeeModifier;

        (roundedLoanAmount, originationFee, totalPremium) = loanTerm.getQuote(loanAmount);
        (premiumFeeModifier, originationFeeModifier) = discountAuthority.getFeeModifiers(
            borrower,
            [loanTerm.minimumLoanAmount(), roundedLoanAmount, loanTerm.maximumLoanAmount()],
            [loanTerm.minimumLoanLengthSeconds(), loanDurationSeconds, loanTerm.maximumLoanLengthSeconds()]
        );

        return [
            roundedLoanAmount,
            originationFee,
            totalPremium,
            premiumFeeModifier,
            originationFeeModifier
        ];
    }

    function _getDiscountedQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) internal view returns (
        uint256[7] memory discountedQuote
        // roundedLoanAmount
        // originationFee
        // totalPremium
        // discountedOriginationFee
        // discountedTotalPremium
        // premiumFeeModifier
        // originationFeeModifier
    ) {

        uint256 ret1;
        uint256 ret2;
        uint256 ret3;

        // roundedLoanAmount, originationFee, totalPremium
        (ret1, ret2, ret3) = loanTerm.getQuote(loanAmount);
        discountedQuote[0] = ret1;  // roundedLoanAmount
        discountedQuote[1] = ret2;  // originationFee
        discountedQuote[2] = ret3;  // totalPremium

        // premiumFeeModifier, originationFeeModifier
        (ret1, ret2) = discountAuthority.getFeeModifiers(
            borrower,
            [loanTerm.minimumLoanAmount(), ret1, loanTerm.maximumLoanAmount()],
            [loanTerm.minimumLoanLengthSeconds(), loanDurationSeconds, loanTerm.maximumLoanLengthSeconds()]
        );

        discountedQuote[5] = ret1;
        discountedQuote[6] = ret2;

        // roundedLoanAmount, discountedOriginationFee, discountedTotalPremium
        (ret1, ret2, ret3) = loanTerm.getDiscountedQuote(loanAmount, ret1, ret2);

        discountedQuote[3] = ret2;
        discountedQuote[4] = ret3;

        return discountedQuote;
    }

    function _useQuote(
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) internal returns (uint256[5] memory) {

        uint256 roundedLoanAmount;
        uint256 originationFee;
        uint256 totalPremium;
        uint256 premiumFeeModifier;
        uint256 originationFeeModifier;

        (roundedLoanAmount, originationFee) = loanTerm.getOriginationAmounts(loanAmount);
        (premiumFeeModifier, originationFeeModifier) = discountAuthority.useFeeModifiers(
            msg.sender,
            [loanTerm.minimumLoanAmount(), roundedLoanAmount, loanTerm.maximumLoanAmount()],
            [loanTerm.minimumLoanLengthSeconds(), loanDurationSeconds, loanTerm.maximumLoanLengthSeconds()]
        );

        return [
            roundedLoanAmount,
            originationFee,
            totalPremium,
            premiumFeeModifier,
            originationFeeModifier
        ];
    }

    function _splitOriginationFee(uint256 amount) internal {
        uint256 ecosystemSplitterAmount = amount * ecosystemSplitterOriginationShare / 10000;
        uint256 X7100LiquidityAmount = amount * X7100OriginationShare / 10000;
        uint256 X7DAOAmount = amount * X7DAOOriginationShare / 10000;
        uint256 lendingPoolAmount = amount - ecosystemSplitterAmount - X7100LiquidityAmount - X7DAOAmount;

        bool success;

        if (ecosystemSplitterAmount > 0) {
            (success, ) = ecosystemSplitter.call{value: ecosystemSplitterAmount}("");
            require(success);
        }

        if (X7100LiquidityAmount > 0) {
            (success, ) = X7100ReserveRecipient.call{value: X7100LiquidityAmount}("");
            require(success);
        }

        if (X7DAOAmount > 0) {
            (success,) = X7DAORewardRecipient.call{value: X7DAOAmount}("");
            require(success);
        }

        if (lendingPoolAmount > 0) {
            X7D.mint(ecosystemRecipient, lendingPoolAmount);
        }
    }

    function _splitPremiumFee(uint256 amount) internal {
        uint256 ecosystemSplitterAmount = amount * ecosystemSplitterPremiumShare / 10000;
        uint256 X7100Amount = amount * X7100PremiumShare / 10000;
        uint256 X7DAOAmount = amount * X7DAOPremiumShare / 10000;
        uint256 lendingPoolAmount = amount - ecosystemSplitterAmount - X7100Amount - X7DAOAmount;

        bool success;
        if (ecosystemSplitterAmount > 0) {
            (success,) = ecosystemSplitter.call{value: ecosystemSplitterAmount}("");
            require(success);
        }

        if (X7100Amount > 0) {
            (success,) = X7100ReserveRecipient.call{value: X7100Amount}("");
            require(success);
        }

        if (X7DAOAmount > 0) {
            (success,) = X7DAORewardRecipient.call{value: X7DAOAmount}("");
            require(success);
        }

        if (lendingPoolAmount > 0) {
            X7D.mint(ecosystemRecipient, lendingPoolAmount);
        }
    }

    function _payLiquidationFee(uint256 loanID, address recipient) internal {
        uint256 amount = loanLiquidationReward[loanID];
        if (amount == 0) {
            return;
        }

        // Ensures liquidation reward is only ever paid out once
        loanLiquidationReward[loanID] = 0;

        (bool success,) = recipient.call{value: amount}("");
        require(success);
        liquidationEscrow -= amount;
    }

    function _addLiquidity(
        address tokenAddress,
        uint256 amount,
        uint256 roundedLoanAmount,
        address liquidityTokenReceiver,
        uint256 timestamp
    ) internal returns (address) {

        IXchangeFactory factory = IXchangeFactory(router.factory());
        address pairAddress = factory.getPair(tokenAddress, router.WETH());
        IXchangePair pair;

        if (pairAddress != address(0)) {
             pair = IXchangePair(pairAddress);
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            require(reserve0 == 0 && reserve1 == 0);
        } else {
            pairAddress = factory.createPair(tokenAddress, router.WETH());
            pair = IXchangePair(pairAddress);
        }

        pair.setMinimumBalance(
            weth,
            uint112(roundedLoanAmount)
        );

        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amount);
        TransferHelper.safeApprove(tokenAddress, address(router), amount);

        router.addLiquidityETH{value: roundedLoanAmount}(
            tokenAddress,
            amount,
            0,
            0,
            liquidityTokenReceiver,
            timestamp
        );

        return address(pair);
    }

}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}