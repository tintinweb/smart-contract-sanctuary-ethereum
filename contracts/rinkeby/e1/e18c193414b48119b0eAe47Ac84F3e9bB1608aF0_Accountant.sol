// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
contract Accountant is ReentrancyGuard {
    struct borrowerInfo {
        Borrower borrower;
        JuniorPool juniorPool;
        bool isPaid;
        address projectWallet;
    }
    Admin private s_admin;
    SeniorPool private s_seniorPool;
    mapping(address => borrowerInfo) private s_borrowers;
    IUSDC private usdc;
    uint256 private constant USDC_DECIMALS = 10**6;

    event SeniorPoolAmountTransfered(address walletAddress, uint256 amount);
    event JuniorPoolAmountTransfered(address walletAddress, uint256 amount);
    event BorrowerPaid(address walletAddress, uint256 amount);
    event JuniorPoolAmountDeposited(address walletAddress, uint256 amount);
    event JuniorPoolAmountWithdraw(address walletAddress, uint256 amount);

    constructor(address usdcContractAddress) {
        usdc = IUSDC(usdcContractAddress);
    }

    modifier isAdmin() {
        if (!s_admin.checkWhitelisted(msg.sender)) {
            revert Accountant__AdminPriviledgesNotOwned(msg.sender);
        }
        _;
    }
    modifier isBorrower(address walletAddress) {
        Borrower borrower = s_borrowers[walletAddress].borrower;
        if (borrower.getWalletAddress() != walletAddress) {
            revert Accountant__PaymentNotFromBorrower(walletAddress);
        }
        _;
    }

    function withdrawJuniorPool(
        address borrower,
        address withdrawer,
        uint256 amount
    ) external nonReentrant {
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
     * @notice transfers the amount from user into the Junior pool of the opportunity
     * @param sender: the wallet address of the sender
     * @param reciever: the wallet address of the reciever
     * @param amount: the amount of USDC to be transferred
     */
    function depositJuniorPool(
        address sender,
        address reciever,
        uint256 amount
    ) external nonReentrant {
        uint256 depositAmount = amount * USDC_DECIMALS;
        s_borrowers[reciever].juniorPool.addJuniorPoolInvestment(
            sender,
            depositAmount
        );
        usdc.transferFrom(sender, reciever, depositAmount);
        emit JuniorPoolAmountDeposited(sender, depositAmount);
    }

    /**
     * @notice transfers pool wallet amount to project wallet
     * @param walletAddress: the address of the project wallet
     * @param seniorPoolAmount: the amount to be extracted from senior pool
     */
    function transferAmountToProjectWallet(
        address walletAddress,
        uint256 seniorPoolAmount
    ) external nonReentrant {
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
     * @notice pay the borrower the amount of money
     * @param walletAddress: the wallet address of the borrower
     * @param amount: the amount of USDC the borrower wants
     */
    function payBorrower(address walletAddress, uint256 amount)
        external
        nonReentrant
    {
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
     * @notice add an admin to the whitelist
     * @param walletAddress: the wallet address of the admin
     */
    function addAdmin(address walletAddress) public isAdmin {
        s_admin.addWalletToWhiteList(walletAddress);
    }

    /**
     * @notice register new borrower against their wallet address
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
     * @notice generate the junior pool for the borrower
     * @param walletAddress: the wallet address of the borrower
     * @param gnosisWalletAddress: the wallet address of the junior pool
     * @param juniorInterest: the interest rate for the junior pool
     * @param termInDays: the number of days of the investment period
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
     * @notice Update the new payment scheme in case of partial payments
     * @param walletAddress: the wallet address of the borrower
     * @param interestPayments: a list of interest Payments for the upcoming months
     * @param principalPayments: a list of principal payments for the upcoming months
     * @param timestamps : a list of the timestamps involving the months to pay in
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
     * @notice Record a Monthly Payment Return and check if late fee is paid
     * @param walletAddress: the wallet address of tehe borrower
     * @param timestamp: the month in which the payment was made
     * @param interestPayment: the interest paid for the month
     * @param principalPayment: the principal amount paid for the month
     * @param lateFee: the additional late Fee if paid
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
     * @notice Check if the payment was made for a specific month
     * @param walletAddress: the wallet address of the borrower
     * @param timestamp : the time at which we want to check if the payment exists
     * @return paymentAllocation object consisting of the interest, principal and additionally paid amount
     */
    function returnBorrowerPaymentStatus(
        address walletAddress,
        string memory timestamp
    )
        external
        view
        isBorrower(walletAddress)
        returns (Borrower.PaymentAllocation memory)
    {
        return s_borrowers[walletAddress].borrower.getPaymentStatus(timestamp);
    }

    function getJuniorPoolBalance(address walletAddress)
        external
        view
        returns (uint256)
    {
        return s_borrowers[walletAddress].juniorPool.getPoolBalance();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Borrower__InvalidTimestamp();
error Borrower__InvalidInterestPoolRates();
error Borrower__LateFeeNotPaid();

import "./SafeMath.sol";

/**
 * @title Borrower
 * @notice This contract works as a record for the borrower
 * @author Erly Stage Studios
 */
contract Borrower {
    using SafeMath for uint256;
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
        s_remainingAmount = s_remainingAmount.sub(principalPayment);
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
        if (currentTime.sub(s_lastBlockTimestamp) > SECONDS_IN_A_MONTH) {
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
import "./SafeMath.sol";

/**
 * @title Junior Pool
 * @notice This contract holds the information for the junior pool of an opportunity
 * @author Erly Stage Studios
 */
contract JuniorPool {
    using SafeMath for uint256;
    struct juniorPoolMember {
        address walletAddress;
        uint256 amountInvested;
        uint256 amountDeserving;
        uint256 amountWithdrawn;
    }
    uint256 private immutable i_creationTimestamp;
    address[] private s_walletAddresses;
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
        i_investmentFinalizationTimestamp = i_creationTimestamp.add(
            SECONDS_IN_A_DAY.mul(i_investmentDays)
        );
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
        s_walletAddresses.push(walletAddress);
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
        uint256 amountDeserving = amountInvested.mul(i_juniorInterestRate) /
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
     * @notice return the interest rate of the junior pool
     * @return uint256
     */
    function getPoolInterestRate() external view returns (uint256) {
        return i_juniorInterestRate;
    }

    /**
     * @notice return the balance in the pool
     * @return uint256
     */
    function getPoolBalance() external view returns (uint256) {
        return s_balance;
    }

    /**
     * @notice return the list of wallet address of the investors
     * @return address[]
     */
    function getInvestorWalletAddresses()
        external
        view
        returns (address[] memory)
    {
        return s_walletAddresses;
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

    function getAmountDeserving(address investor)
        external
        view
        returns (uint256)
    {
        return s_member[investor].amountDeserving;
    }

    function getCreationTimestamp() public view returns (uint256) {
        return i_creationTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./interfaces/IUSDC.sol";

contract SeniorPool {
    IUSDC public USDc;

    address seniorPoolAddress;
    mapping(address => uint256) public addressToAmountLended;
    uint256 public totalLended;

    constructor(address _seniorPoolAddress) {
        seniorPoolAddress = _seniorPoolAddress;
        USDc = IUSDC(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
    }

    struct investor {
        uint256[] investments;
        uint256 totalInvestment;
    }

    address[] investors;

    mapping(address => investor) public addressToInvestor;

    function checkInvestor(address walletAddress) public view returns (bool) {
        bool success = false;
        for (uint256 i = 0; i < investors.length; i++) {
            if (investors[i] == walletAddress) {
                success = true;
                break;
            }
        }
        return success;
    }

    function fund(uint256 $USDC) public {
        // payable(seniorPoolAddress).transfer(msg.value);
        USDc.transfer(
            0xf17C53b9eA81236d3C0Eb485Ee8134979A87c8Cc,
            $USDC * 10**6
        );
        investor storage Investor = addressToInvestor[msg.sender];
        // Investor.investments.push(msg.value);
        if (checkInvestor(msg.sender) == false) {
            investors.push(msg.sender);
        }
        Investor.totalInvestment += $USDC;
    }

    // function investmentsPerAddress(address investorAddress)public view returns( uint256  [] memory){
    //  investor storage Investor = addressToInvestor[investorAddress];
    //  return Investor.investments;
    // }

    modifier onlyAdmin() {
        require(msg.sender == seniorPoolAddress);
        _;
    }

    modifier onlyInvestor() {
        require(checkInvestor(msg.sender));
        _;
    }

    function getInvestorsAddress() public view returns (address[] memory) {
        return investors;
    }

    function withdraw() external payable onlyAdmin {
        payable(seniorPoolAddress).transfer(address(this).balance);
    }

    function withdrawUser(uint256 withdrawAmount) public payable onlyInvestor {
        investor storage Investor = addressToInvestor[msg.sender];
        require(Investor.totalInvestment >= withdrawAmount);
        payable(msg.sender).transfer(withdrawAmount);
    }

    function seniorPoolBalance() public view returns (uint256) {
        return seniorPoolAddress.balance;
    }

    function lend(address projectAddress) public payable onlyAdmin {
        payable(projectAddress).transfer(msg.value);
        addressToAmountLended[projectAddress] += msg.value;
        totalLended += msg.value;
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity >=0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}