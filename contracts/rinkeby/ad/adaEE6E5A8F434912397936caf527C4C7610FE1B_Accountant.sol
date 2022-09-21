// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Borrower.sol";
import "./Admin.sol";
import "./JuniorPool.sol";
import "./SeniorPool.sol";
import "./interfaces/IUSDC.sol";
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
        uint256 amount
    ) external {
        uint256 depositAmount = amount * USDC_DECIMALS;
        s_borrowers[reciever].juniorPool.addJuniorPoolInvestment(
            sender,
            depositAmount
        );
        usdc.transferFrom(sender, reciever, depositAmount);
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
        emit JuniorPoolAmountTransfered(walletAddress, juniorPoolAmount);
    }

    /**
     * @notice transfer the amount of project wallet to the borrower
     * @param walletAddress: the wallet address of the borrower
     * @param amount: the amount of money to send
     */
    function payBorrower(address walletAddress, uint256 amount) external {
        if (s_borrowers[walletAddress].isPaid) {
            revert Accountant__PaymentAlreadyMade();
        }
        s_borrowers[walletAddress].isPaid = true;
        usdc.transferFrom(
            s_borrowers[walletAddress].projectWallet,
            walletAddress,
            amount * USDC_DECIMALS
        );
        emit BorrowerPaid(walletAddress, amount);
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
    function fundSeniorPool(uint256 USDC) external {
        s_seniorPool.fund(USDC);
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

error Admin__DoesNotExist();

/**
 * @title Admin
 * @notice This contract holds the information for admin wallets and Gnosis safe
 * @author Erly Stage Studios
 */
contract Admin {
    address[] private s_whiteListedWallets;

    address private s_gnosisWallet;

    /**
     * @notice Add a wallet to whitelist
     * @param walletAddress: the address of the wallet of the admin
     */
    function addWalletToWhiteList(address walletAddress) external {
        s_whiteListedWallets.push(walletAddress);
    }

    /**
     * @notice check if the given wallet is whitelisted
     * @param walletAddress: the address of the wallet
     * @return bool: the truth value if wallet exists or not
     */
    function checkWhitelisted(address walletAddress)
        external
        view
        returns (bool)
    {
        bool success = false;
        for (uint256 i = 0; i < s_whiteListedWallets.length; i++) {
            if (s_whiteListedWallets[i] == walletAddress) {
                success = true;
                break;
            }
        }
        return success;
    }

    /**
     * @notice remove the wallet address from whitelist
     * @param walletAddress: the address of the wallet
     */
    function removeWallet(address walletAddress) external {
        bool found = false;
        for (uint256 i = 0; i < s_whiteListedWallets.length; i++) {
            if (s_whiteListedWallets[i] == walletAddress) {
                found = true;
                delete s_whiteListedWallets[i];
                break;
            }
        }
        if (!found) {
            revert Admin__DoesNotExist();
        }
    }

    /**
     * @notice save the main Gnosis wallet address
     * @param walletAddress: the wallet Address of the genosis wallet
     */
    function connectGnosisWallet(address walletAddress) external {
        s_gnosisWallet = walletAddress;
    }

    /**
     * @notice getter for the Gnosis wallet address
     * @return address: the address of the Gnosis wallet
     */
    function getGnosisWalletAddress() external view returns (address) {
        return s_gnosisWallet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error JuniorPool__CannotWithdrawMoreFunds();
error JuniorPool__CannotWithdrawExtraFunds();
error JuniorPool__InvestmentPeriodOver();

/**
 * @title Junior Pool
 * @notice This contract holds the information for the junior pool of an opportunity
 * @author Erly Stage Studios
 */
contract JuniorPool {
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
    ) {
        i_poolWalletAddress = walletAddress;
        i_juniorInterestRate = juniorInterest;
        i_investmentDays = investmentDays;
        i_creationTimestamp = block.timestamp;
        i_investmentFinalizationTimestamp =
            i_creationTimestamp +
            (SECONDS_IN_A_DAY * i_investmentDays);
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
    ) external {
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
    {
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
pragma solidity ^0.8.8;

import "./interfaces/IUSDC.sol";

error SeniorPool__NotAdmin();
error SeniorPool__WithdrawalOutOfBounds();

/**
 * @title Senior Pool
 * @notice This contract holds the information for the Senior Pool of BraveNewDAO
 * @author Erly Stage Studios
 */
contract SeniorPool {
    IUSDC public USDc;
    address seniorPoolAddress;
    uint256 constant USDC_DECIMALS = 10**6;

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