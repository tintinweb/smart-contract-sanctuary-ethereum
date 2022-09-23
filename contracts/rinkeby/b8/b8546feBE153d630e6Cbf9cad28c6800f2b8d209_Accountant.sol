// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Borrower.sol";
import "./JuniorPool.sol";
import "./SeniorPool.sol";
import "./interfaces/IUSDC.sol";
import "./invoiceMinting.sol";

error Accountant__AdminPriviledgesNotOwned(address walletAddress);
error Accountant__PaymentNotFromBorrower(address walletAddress);
error Accountant__PaymentAlreadyMade();

/**
 * @title Accountant
 * @notice This contracts holds the main functionality for the contract
 * @author Erly Stage Studios
 */
contract Accountant {
    struct borrowerInfo {
        Borrower borrower;
        JuniorPool juniorPool;
        bool isPaid;
        address projectWallet;
    }
    SeniorPool private s_seniorPool;
    mapping(address => borrowerInfo) private s_borrowers;
    IUSDC private usdc;
    uint256 private constant USDC_DECIMALS = 10**6;
    MyToken private s_nftTokenizer;
    uint256 private tokenID = 0;

    event SeniorPoolAmountTransfered(address walletAddress, uint256 amount);
    event JuniorPoolAmountTransfered(address walletAddress, uint256 amount);
    event BorrowerPaid(address walletAddress, uint256 amount);
    event JuniorPoolAmountDeposited(address walletAddress, uint256 amount);
    event JuniorPoolAmountWithdraw(address walletAddress, uint256 amount);

    /**
     * @notice constructor for the contract
     * @param usdcContractAddress : the contract Address for the USDC contract on the respective net
     * @param seniorpoolWalletAddress: the wallet address of the senior pool
     */
    constructor(address usdcContractAddress, address seniorpoolWalletAddress) {
        usdc = IUSDC(usdcContractAddress);
        s_seniorPool = SeniorPool(seniorpoolWalletAddress);
    }

    modifier isBorrower(address walletAddress) {
        Borrower borrower = s_borrowers[walletAddress].borrower;
        if (borrower.getWalletAddress() != walletAddress) {
            revert Accountant__PaymentNotFromBorrower(walletAddress);
        }
        _;
    }

    /**
     * @notice function to assist withdrawal from Junior Pool
     * @param borrower: the wallet address of the borrower
     * @param withdrawer: the wallet address of the person who wants to withdraw
     * @param amount: the amount the withdrawer wants to withdraw
     */
    function withdrawJuniorPool(
        address borrower,
        address withdrawer,
        uint256 amount
    ) external {
        uint256 withdrawAmount = amount * USDC_DECIMALS;
        s_borrowers[borrower].juniorPool.addWithdrawalRecord(
            withdrawer,
            withdrawAmount
        );
        address juniorPoolWallet = s_borrowers[borrower]
            .juniorPool
            .getPoolWalletAddress();
        usdc.transferFrom(juniorPoolWallet, withdrawer, withdrawAmount);
        emit JuniorPoolAmountWithdraw(withdrawer, withdrawAmount);
    }

    /**
     * @notice function to assist deposit in a junior pool
     * @param sender: the wallet address of the borrower
     * @param reciever: the wallet address of the person who wants to withdraw
     * @param amount: the amount the withdrawer wants to withdraw
     */
    function depositJuniorPool(
        address sender,
        address reciever,
        uint256 amount,
        string memory uri
    ) external {
        uint256 depositAmount = amount * USDC_DECIMALS;
        s_borrowers[reciever].juniorPool.addJuniorPoolInvestment(
            sender,
            depositAmount
        );
        usdc.transferFrom(sender, reciever, depositAmount);
        s_nftTokenizer.safeMint(msg.sender, tokenID, uri);
        tokenID++;
        emit JuniorPoolAmountDeposited(sender, depositAmount);
    }

    /**
     * @notice transfer the amount to the project wallet on time completion
     * @param walletAddress: the walletAddress of the borrower
     * @param seniorPoolAmount: the amount from senior pool
     */
    function transferAmountToProjectWallet(
        address walletAddress,
        uint256 seniorPoolAmount
    ) external {
        address seniorPoolWalletAddress = address(0);
        address juniorPoolWalletAddress = s_borrowers[walletAddress]
            .juniorPool
            .getPoolWalletAddress();
        address projectWalletAddress = s_borrowers[walletAddress].projectWallet;
        usdc.transferFrom(
            seniorPoolWalletAddress,
            projectWalletAddress,
            seniorPoolAmount * USDC_DECIMALS
        );
        emit SeniorPoolAmountTransfered(walletAddress, seniorPoolAmount);
        uint256 juniorPoolAmount = s_borrowers[walletAddress]
            .juniorPool
            .getPoolBalance();
        usdc.transferFrom(
            juniorPoolWalletAddress,
            projectWalletAddress,
            juniorPoolAmount
        );
        s_borrowers[walletAddress].isPaid = true;
        s_borrowers[walletAddress].juniorPool.pauseJuniorPool();
        emit JuniorPoolAmountTransfered(walletAddress, juniorPoolAmount);
        emit BorrowerPaid(walletAddress, juniorPoolAmount + seniorPoolAmount);
    }

    /**
     * @notice register a new borrower
     * @param walletAddress: wallet address of the borrower
     * @param principalAmount: the principal amount
     * @param interestRate:the interest rate
     * @param termInMonths: the term period in months
     * @param juniorInterest: the junior pool interest
     * @param seniorInterest: the senior pool interest
     * @param collaterals: the offchain collateral IPFS hashes
     * @param lateFee: the late fee applicable
     * @param interestPayments: the list of interest payments
     * @param  principalPayments: the list of principal payments
     *  @param timestamps: the timestmaps at which ti pay
     */
    function registerBorrower(
        address walletAddress,
        uint256 principalAmount,
        uint256 interestRate,
        uint256 termInMonths,
        uint256 juniorInterest,
        uint256 seniorInterest,
        string[] memory collaterals,
        uint256 lateFee,
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) external {
        Borrower borrower = new Borrower(
            walletAddress,
            principalAmount,
            interestRate,
            termInMonths,
            juniorInterest,
            seniorInterest,
            collaterals,
            lateFee,
            interestPayments,
            principalPayments,
            timestamps
        );
        s_borrowers[walletAddress].borrower = borrower;
    }

    /**
     * @notice generate a junior pool for the borrower
     * @param walletAddress: the wallet address of the borrower
     * @param gnosisWalletAddress: the wallet address of the gnosis junior pool wallet
     * @param juniorInterest: the interest rate for the junior pool
     * @param termInDays: the term in days
     * @param projectWallet: the project Gnosis wallet Address
     */
    function generateJuniorPool(
        address walletAddress,
        address gnosisWalletAddress,
        uint256 juniorInterest,
        uint256 termInDays,
        address projectWallet
    ) external {
        JuniorPool juniorPool = new JuniorPool(
            /* send Gnosis wallet after creation wallet address */
            gnosisWalletAddress,
            juniorInterest,
            termInDays
        );
        s_borrowers[walletAddress].juniorPool = juniorPool;
        s_borrowers[walletAddress].projectWallet = projectWallet;
    }

    /**
     * @notice update the scheme for borrower monthly payments
     * @param walletAddress: the walletAddress of the borrower
     * @param interestPayments: the list of interest based payments per month
     * @param principalPayments: the list of principal payments per month
     * @param timestamps: the list of timestamps at which payments are to be made
     */
    function updateBorrowerPaymentScheme(
        address walletAddress,
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) external isBorrower(walletAddress) {
        s_borrowers[walletAddress].borrower.updatePaymentScheme(
            interestPayments,
            principalPayments,
            timestamps
        );
    }

    /**
     * @notice add a record for borrower's repayment
     * @param walletAddress: the walletAddress of the borrower
     * @param timestamp: the timestamp at which the payment is made
     * @param interestPayment: the interest paid with the repayment
     * @param principalPayment: the principal amount returned for the month
     * @param lateFee: the lateFee paid for the month
     */
    function returnMonthlyBorrowerPayment(
        address walletAddress,
        string memory timestamp,
        uint256 interestPayment,
        uint256 principalPayment,
        uint256 lateFee
    ) external isBorrower(walletAddress) {
        s_borrowers[walletAddress].borrower.loanPaymentReturn(
            timestamp,
            interestPayment,
            principalPayment,
            lateFee
        );
    }

    /**
     * @notice fund amount into senior pool
     * @param USDC: the amount of USDC to fund
     */
    function fundSeniorPool(uint256 USDC, string memory uri) external {
        s_seniorPool.fund(USDC);
        s_nftTokenizer.safeMint(msg.sender, tokenID, uri);
        tokenID++;
    }

    /**
     * @notice allow the user to withdraw some amount from senior pool
     * @param USDC: the amount of USDC to withdraw
     */
    function withdrawUserAmountFromSeniorPool(uint256 USDC) external {
        s_seniorPool.withdrawUser(USDC);
    }

    /**
     * @notice lend some USDC amount to project from the senior pool
     * @param projectAddress: the walletAddress of the project
     * @param USDC: the amount of USDc to give to the project
     */
    function lendAmountToProjectFromSeniorPool(
        address projectAddress,
        uint256 USDC
    ) external {
        s_seniorPool.lend(projectAddress, USDC);
    }

    /**
     * @notice return the balance of the specific juniorPool
     * @param walletAddress: the walletAddress of the borrower
     * @return amount balance of the junior pool
     */
    function getJuniorPoolBalance(address walletAddress)
        external
        view
        returns (uint256)
    {
        return s_borrowers[walletAddress].juniorPool.getPoolBalance();
    }

    /**
     * @notice return the senior pool wallet address
     * @return seniorPoolWalletAddress
     */
    function getSeniorPoolAddress() external view returns (address) {
        return s_seniorPool.getSeniorPoolAddress();
    }

    /**
     * @notice return the senior pool balance
     * @return balance
     */
    function getSeniorPoolBalance() external view returns (uint256) {
        return s_seniorPool.getSeniorPoolBalance();
    }

    /**
     * @notice get the list of investments made by an investor
     * @param investorAddress: the wallet address of the investor
     * @return listOfInvestments
     */
    function getSeniorPoolInvestorInvestment(address investorAddress)
        external
        view
        returns (uint256[] memory)
    {
        return s_seniorPool.investmentsPerAddress(investorAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./interfaces/IUSDC.sol";

error SeniorPool__NotAdmin();
error SeniorPool__WithdrawalOutOfBounds();
error SeniorPool__CannotWithdrawYet();

/**
 * @title Senior Pool
 * @notice This contract holds the information for the Senior Pool of BraveNewDAO
 * @author Erly Stage Studios
 */
contract SeniorPool {
    IUSDC public USDc;
    address seniorPoolAddress;
    uint256 constant USDC_DECIMALS = 10**6;
    uint256 private constant SECONDS_IN_A_DAY = 86400;

    /**
     * @notice constructor for the Senior Pool Contract
     * @param _seniorPoolAddress: the wallet address of the senior pool
     */
    constructor(address _seniorPoolAddress) {
        seniorPoolAddress = _seniorPoolAddress;
        USDc = IUSDC(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
    }

    struct investor {
        uint256[] investments;
        uint256 totalInvestment;
        uint256 unpauseTimestamp;
    }
    mapping(address => investor) public addressToInvestor;
    modifier onlyAdmin() {
        if (msg.sender != seniorPoolAddress) {
            revert SeniorPool__NotAdmin();
        }
        _;
    }

    /**
     * @notice fund the senior pool
     * @param USDC: the amount of USDC to provide to the senior pool
     */
    function fund(uint256 USDC) public {
        investor storage Investor = addressToInvestor[msg.sender];
        Investor.totalInvestment += USDC;
        Investor.investments.push(USDC);
        Investor.unpauseTimestamp = block.timestamp * 31 * SECONDS_IN_A_DAY;
        USDc.transferFrom(msg.sender, seniorPoolAddress, USDC * USDC_DECIMALS);
    }

    /**
     * @notice return the wallet address of the senior pool
     * @return seniorPoolAddress
     */
    function getSeniorPoolAddress() public view returns (address) {
        return seniorPoolAddress;
    }

    /**
     * @notice return the balance of the senior pool
     * @return balance
     */
    function getSeniorPoolBalance() public view returns (uint256) {
        return USDc.balanceOf(seniorPoolAddress);
    }

    /**
     * @notice return how much an investor has invested
     * @param investorAddress: the wallet address of the investor
     * @return investments[]
     */
    function investmentsPerAddress(address investorAddress)
        public
        view
        returns (uint256[] memory)
    {
        investor storage Investor = addressToInvestor[investorAddress];
        return Investor.investments;
    }

    /**
     * @notice Allow a user to withdraw funds from the senior pool
     * @param USDC: the amount of USDC the user wants to withdraw
     */
    function withdrawUser(uint256 USDC) public {
        investor storage Investor = addressToInvestor[msg.sender];
        if (block.timestamp < Investor.unpauseTimestamp) {
            revert SeniorPool__CannotWithdrawYet();
        }
        if (Investor.totalInvestment < USDC) {
            revert SeniorPool__WithdrawalOutOfBounds();
        }
        Investor.totalInvestment -= USDC;
        USDc.transferFrom(seniorPoolAddress, msg.sender, USDC * USDC_DECIMALS);
    }

    /**
     * @notice lend a specific project some amount of USDC from the senior pool
     * @param projectAddress: the wallet address of the project
     * @param USDC: the amount of USDC to transfer from senior pool
     */
    function lend(address projectAddress, uint256 USDC)
        public
        payable
        onlyAdmin
    {
        // add some records here
        USDc.transferFrom(
            seniorPoolAddress,
            projectAddress,
            USDC * USDC_DECIMALS
        );
        //TBD
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Borrower__InvalidTimestamp();
error Borrower__InvalidInterestPoolRates();
error Borrower__LateFeeNotPaid();

/**
 * @title Borrower
 * @notice This contract works as a record for the borrower
 * @author Erly Stage Studios
 */
contract Borrower {
    // THE DATA HAS TO BE IN PRECISION FORM
    struct PaymentAllocation {
        uint256 interestPayment;
        uint256 principalPayment;
        uint256 additionalBalancePayment;
    }
    struct PaymentScheme {
        uint256 interestPayment;
        uint256 principalPayment;
        string timestamp;
    }
    uint256 private constant PRECISION = 10**10;
    uint256 private constant SECONDS_IN_A_MONTH = 2.628e6;
    address private immutable i_borrowerWallet;
    uint256 private immutable i_principalAmount;
    uint256 private immutable i_interestRate;
    uint256 private immutable i_termInMonths;
    uint256 private immutable i_juniorPoolInterest;
    uint256 private immutable i_seniorPoolInterest;
    string[] private i_collateralHashs;
    uint256 private immutable i_lateFee;
    uint256 private s_lastBlockTimestamp;
    PaymentScheme[] private s_paymentScheme;
    mapping(string => PaymentAllocation) s_fundRecord;
    uint256 private s_monthsPaid;
    uint256 private s_remainingAmount;

    event contractCreated(address walletAddress);
    event fundRecorded(string timestamp);
    event paymentSchemeUpdated(PaymentScheme[] scheme);

    /**
     * @notice constructor for the contract
     * @param walletAddress: the wallet address of the borrower
     * @param principalAmount: the amount the borrower wants to borrow
     * @param interestRate: the amount of interest applied on the loan
     * @param termInMonths: the number of months for the repayment
     * @param juniorInterest: the interest given to junior pool
     * @param seniorInterest: the interest given to senior pool
     * @param collaterals: the list of collaterals for the loan
     * @param lateFee: the fee charged if the payment is not made on time
     * @param interestPayments: the list of interest payments to be paid monthly
     * @param principalPayments: the list of principal payments to be pain monthly
     * @param timestamps: the list of timestamps at which the payments are to be made
     */
    constructor(
        address walletAddress,
        uint256 principalAmount,
        uint256 interestRate,
        uint256 termInMonths,
        uint256 juniorInterest,
        uint256 seniorInterest,
        string[] memory collaterals,
        uint256 lateFee,
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) {
        if (juniorInterest <= seniorInterest) {
            revert Borrower__InvalidInterestPoolRates();
        }
        i_borrowerWallet = walletAddress;
        i_principalAmount = principalAmount;
        i_interestRate = interestRate;
        i_termInMonths = termInMonths;
        i_collateralHashs = collaterals;
        i_juniorPoolInterest = juniorInterest;
        i_seniorPoolInterest = seniorInterest;
        i_lateFee = lateFee;
        s_lastBlockTimestamp = block.timestamp;
        for (uint256 i = 0; i < i_termInMonths; i++) {
            s_paymentScheme.push();
            s_paymentScheme[i] = PaymentScheme(
                interestPayments[i],
                principalPayments[i],
                timestamps[i]
            );
        }
        s_remainingAmount = principalAmount * PRECISION;
        emit contractCreated(walletAddress);
    }

    /**
     * @notice Update the new payment scheme in case of partial payments
     * @param interestPayments: a list of interest Payments for the upcoming months
     * @param principalPayments: a list of principal payments for the upcoming months
     * @param timestamps : a list of the timestamps involving the months to pay in
     */
    function updatePaymentScheme(
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) external {
        delete s_paymentScheme;
        for (uint256 i = 0; i < i_termInMonths - s_monthsPaid; i++) {
            s_paymentScheme.push();
            s_paymentScheme[i] = PaymentScheme(
                interestPayments[i],
                principalPayments[i],
                timestamps[i]
            );
        }
        emit paymentSchemeUpdated(s_paymentScheme);
    }

    /**
     * @notice Record a Monthly Payment Return and check if late fee is paid
     * @param timestamp: the month in which the payment was made
     * @param interestPayment: the interest paid for the month
     * @param principalPayment: the principal amount paid for the month
     * @param lateFee: the additional late Fee if paid
     */
    function loanPaymentReturn(
        string memory timestamp,
        uint256 interestPayment,
        uint256 principalPayment,
        uint256 lateFee
    ) external {
        if (isLate() && lateFee == 0) {
            revert Borrower__LateFeeNotPaid();
        }
        s_fundRecord[timestamp] = PaymentAllocation(
            interestPayment,
            principalPayment,
            lateFee
        );
        s_lastBlockTimestamp = block.timestamp;
        s_monthsPaid++;
        s_remainingAmount = s_remainingAmount - principalPayment;
        emit fundRecorded(timestamp);
    }

    /**
     * @notice Check if the payment was made for a specific month
     * @param timestamp : the time at which we want to check if the payment exists
     * @return paymentAllocation object consisting of the interest, principal and additionally paid amount
     */
    function getPaymentStatus(string memory timestamp)
        external
        view
        returns (PaymentAllocation memory)
    {
        PaymentAllocation memory fund = s_fundRecord[timestamp];
        if (fund.principalPayment <= 0) {
            revert Borrower__InvalidTimestamp();
        }
        return fund;
    }

    /**
     * @notice check if the borrower is late on a payment
     * @return bool : true or false
     */
    function isLate() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (currentTime - s_lastBlockTimestamp > SECONDS_IN_A_MONTH) {
            return true;
        }
        return false;
    }

    /**
     * @notice return the borrower's wallet address
     * @return address
     */
    function getWalletAddress() external view returns (address) {
        return i_borrowerWallet;
    }

    /**
     * @notice return the borrower's months paid
     * @return uint256
     */
    function getMonthsPaid() external view returns (uint256) {
        return s_monthsPaid;
    }

    /**
     * @notice return the borrower's principal requested amount
     * @return uint256
     */
    function getPrincipalAmount() external view returns (uint256) {
        return i_principalAmount;
    }

    /**
     * @notice return the borrower's interest rate
     * @return uint256
     */
    function getInterestRate() external view returns (uint256) {
        return i_interestRate;
    }

    /**
     * @notice return the borrower's term in months
     * @return uint256
     */
    function getTerm() external view returns (uint256) {
        return i_termInMonths;
    }

    /**
     * @notice return the borrower's collateral contents
     * @return string[]
     */
    function getCollateralHashs() external view returns (string[] memory) {
        return i_collateralHashs;
    }

    /**
     * @notice return the borrower's junior pool interest
     * @return uint256
     */
    function getJuniorPoolInterest() external view returns (uint256) {
        return i_juniorPoolInterest;
    }

    /**
     * @notice return the borrower's senior pool interest
     * @return uint256
     */
    function getSeniorPoolInterest() external view returns (uint256) {
        return i_seniorPoolInterest;
    }

    /**
     * @notice return the borrower's late fee amount
     * @return uint256
     */
    function getLateFee() external view returns (uint256) {
        return i_lateFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

error JuniorPool__CannotWithdrawMoreFunds();
error JuniorPool__CannotWithdrawExtraFunds();
error JuniorPool__InvestmentPeriodOver();
error JuniorPool__CannotWithdrawYet();

/**
 * @title Junior Pool
 * @notice This contract holds the information for the junior pool of an opportunity
 * @author Erly Stage Studios
 */
contract JuniorPool is Pausable {
    struct juniorPoolMember {
        address walletAddress;
        uint256 amountInvested;
        uint256 amountDeserving;
        uint256 amountWithdrawn;
    }

    uint256 private immutable i_creationTimestamp;
    mapping(address => juniorPoolMember) s_member;
    uint256 private s_balance;
    uint256 private immutable i_juniorInterestRate;
    address private immutable i_poolWalletAddress;
    uint256 private immutable i_investmentDays;
    uint256 private immutable i_investmentFinalizationTimestamp;
    uint256 private constant SECONDS_IN_A_DAY = 86400;
    bool private s_pauseWithdrawals = true;
    uint256 private s_openWithdrawalTimestamp;

    /**
     * @notice constructor for the contract
     * @param walletAddress: the Gnosis wallet address for the junior pool
     * @param juniorInterest: the interest rate for the junior pool
     * @param investmentDays: the number of days the option to invest is availaible
     */
    constructor(
        address walletAddress,
        uint256 juniorInterest,
        uint256 investmentDays
    ) Pausable() {
        i_poolWalletAddress = walletAddress;
        i_juniorInterestRate = juniorInterest;
        i_investmentDays = investmentDays;
        i_creationTimestamp = block.timestamp;
        i_investmentFinalizationTimestamp =
            i_creationTimestamp +
            (SECONDS_IN_A_DAY * i_investmentDays);
    }

    function pauseJuniorPool() external {
        _pause();
        s_openWithdrawalTimestamp = block.timestamp * 31 * SECONDS_IN_A_DAY;
    }

    /**
     * @notice check and tell if investment period is complete
     * @return bool: the truth value if investment period is ongoing
     */
    function isInvestmentPeriodComplete() public view returns (bool) {
        uint256 timestamp = block.timestamp;
        if (timestamp > i_investmentFinalizationTimestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice add a member to junior pool with a certain investment, calculates the deserving amount inside the contract
     * @param walletAddress: the wallet address of the investor
     * @param amountInvested: the amount invested
     */
    function addJuniorPoolInvestment(
        address walletAddress,
        uint256 amountInvested
    ) external whenNotPaused {
        if (isInvestmentPeriodComplete()) {
            revert JuniorPool__InvestmentPeriodOver();
        }

        juniorPoolMember memory temp = s_member[walletAddress];
        if (temp.amountInvested == 0) {
            s_member[walletAddress] = juniorPoolMember(
                walletAddress,
                amountInvested,
                calculateAmountDeserving(amountInvested),
                0
            );
        } else {
            s_member[walletAddress].amountInvested += amountInvested;
            s_member[walletAddress].amountDeserving = calculateAmountDeserving(
                s_member[walletAddress].amountInvested
            );
        }

        s_balance += amountInvested;
    }

    /**
     * @notice calculate the amount the investor deserves with the interest provided
     * @param amountInvested: the amount paid by the investor
     * @return uint256: the amount they deserve with the interest
     */
    function calculateAmountDeserving(uint256 amountInvested)
        internal
        view
        returns (uint256)
    {
        uint256 hundred = 100;
        uint256 amountDeserving = (amountInvested * i_juniorInterestRate) /
            hundred;
        return amountInvested + amountDeserving;
    }

    /**
     * @notice adds the record of withdrawal by an investor to the chain
     * @param walletAddress: the wallet address of the investor
     * @param amountWithdrawn: the amount the investor wants to withdraw
     */
    function addWithdrawalRecord(address walletAddress, uint256 amountWithdrawn)
        external
        whenPaused
    {
        if (block.timestamp < s_openWithdrawalTimestamp) {
            revert JuniorPool__CannotWithdrawYet();
        }
        if (
            s_member[walletAddress].amountDeserving ==
            s_member[walletAddress].amountWithdrawn
        ) {
            revert JuniorPool__CannotWithdrawMoreFunds();
        }
        if (s_member[walletAddress].amountDeserving < amountWithdrawn) {
            revert JuniorPool__CannotWithdrawExtraFunds();
        }
        s_member[walletAddress].amountWithdrawn += amountWithdrawn;
    }

    /**
     * @notice return the junior pool's wallet address
     * @return address
     */
    function getPoolWalletAddress() external view returns (address) {
        return i_poolWalletAddress;
    }

    /**
     * @notice return the finalization timestamp for investment
     * @return uint256
     */
    function getFinalizationTimestamp() external view returns (uint256) {
        return i_investmentFinalizationTimestamp;
    }

    /**
     * @notice return the balance in the pool
     * @return uint256
     */
    function getPoolBalance() external view returns (uint256) {
        return s_balance;
    }

    /**
     * @notice return the  investor depending on the wallet address
     * @param walletAddress: the wallet address of the investor
     * @return juniorPoolMember
     */
    function getInvestor(address walletAddress)
        external
        view
        returns (juniorPoolMember memory)
    {
        return s_member[walletAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

interface IUSDC {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @return Return the amount held by address
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}