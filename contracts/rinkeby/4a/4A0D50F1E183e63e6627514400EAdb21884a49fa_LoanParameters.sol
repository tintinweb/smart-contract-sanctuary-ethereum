/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/LoanParameters.sol

pragma solidity ^0.8.4;

contract LoanParameters is Ownable {

    /// @notice The precision at which we store decimals. A precision of 10000 allows storage of 10.55% as 1055
    /// @dev The higher the number the more precise the calculated values. Since we are using this to store apr
    ///      the value should be read only as making it writable would break the math of pre existing loans
    uint256 public precision = 10000;

    /// @notice The total supply of the fractionalized loan. Fractions are then distributed to Loan Provider based on
    ///         the amount of eth loan and the apr averaged across all accepted providers for that loan.
    uint256 public fractionalizeSupply = 10000;

    /// @notice The minimum percent a borrower can either select or accept to determine the principal amount of the loan.
    uint256 public minLoanPercentageOfCollateral = 2000;

    /// @notice The maximum percent a borrower can either select or accept to determine the principal amount of the loan.
    uint256 public maxLoanPercentageOfCollateral = 6000;

    /// @notice The minimum number of days a loan is allowed to be taken out for.
    uint256 public minLoanDurationInDays = 7;

    /// @notice The maximum number of days a loan is allowed to be taken out for. If set to 0, no upper limit.
    uint256 public maxLoanDurationInDays = 365;

    /// @notice When a loan is ended (paid in full) prior to the scheduled end date, interest owed is only calculated
    ///         on the actual duration of the loan, not the originally selected loan duration. However, if the loan is
    ///         paid too early, this presents a situation where the loan providers could actually lose money on this
    ///         loan. Therefore this value represents the minimum percentage of the estimated duration that interest
    ///         must be paid by the borrower. The borrower may be required to pay more, this is the minimum. NOTE:
    ///         When interest is calculated on a loan paid back early, the actual interest owed is determined by which
    ///         value is larger when using these values for the duration: minLoanDurationInDays,
    ///         minPercentOfDurationForInterest * requestedLoanDuration, actualLoanDuration.
    uint256 public minPercentOfDurationForInterest = 4000;

    /// @notice This is the fee that a borrower is required to pay as part of starting the campaign. This is calculated
    ///         as a percentage of the estimatedCollateralValue.
    uint256 public loanPostingFeePercent = 100;

    /// @notice This is the fee that a borrower pays at the time they start the loan, making the loan active. This is
    ///         calculated as a percentage of the estimatedCollateralValue.
    uint256 public loanProcessingFeePercent = 100;

    /// @notice This tells the contract if it can be used to create new loan campaigns. Setting this to false, would
    ///         render the create campaign capability.
    bool public enabled = true;

    /// @notice This is the amount of days after the loan period has elapsed before the loan officially defaults.
    uint256 public loanDefaultGracePeriodInMinutes = 30;

    /// @notice set the fractionalize supply
    /// @param _value the new fractional supply value
    function setFractionalizeSupply(uint256 _value) public onlyOwner {
        fractionalizeSupply = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0011
    /////////////////////////////////////////////

    /// @notice set the minLoanPercentageOfCollateral
    /// @param _value the new minLoanPercentageOfCollateral value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMinLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        minLoanPercentageOfCollateral = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0012
    /////////////////////////////////////////////

    /// @notice set the maxLoanPercentageOfCollateral
    /// @param _value the new maxLoanPercentageOfCollateral value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMaxLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        maxLoanPercentageOfCollateral = _value;
    }


    /////////////////////////////////////////////
    // Reference TFL-0013
    /////////////////////////////////////////////

    /// @notice set the minLoanDurationInDays
    /// @param _value the new minLoanDurationInDays value
    function setMinLoanDurationInDays(uint256 _value) public onlyOwner {
        minLoanDurationInDays = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0014
    /////////////////////////////////////////////

    /// @notice set the maxLoanDurationInDays
    /// @param _value the new maxLoanDurationInDays value
    function setMaxLoanDurationInDays(uint256 _value) public onlyOwner {
        maxLoanDurationInDays = _value;
    }

    /// @notice set the setMinPercentOfDurationForInterest
    /// @param _value the new setMinPercentOfDurationForInterest value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMinPercentOfDurationForInterest(uint256 _value) public onlyOwner {
        minPercentOfDurationForInterest = _value;
    }

    /// @notice set the setLoanPostingFeePercent
    /// @param _value the new setLoanPostingFeePercent value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setLoanPostingFeePercent(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // Reference TFL-0016
        /////////////////////////////////////////
        loanPostingFeePercent = _value;
    }

    /// @notice set the setLoanProcessingFeePercent
    /// @param _value the new setLoanProcessingFeePercent value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setLoanProcessingFeePercent(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0017
        /////////////////////////////////////////
        loanProcessingFeePercent = _value;
    }

    /// @notice set the enabled
    /// @param _value the new enabled value
    function setEnabled(bool _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0018
        /////////////////////////////////////////
        enabled = _value;
    }

    /// @notice set the loanDefaultGracePeriodInMinutes
    /// @param _value the new loanDefaultGracePeriodInMinutes value
    function setLoanDefaultGracePeriodInMinutes(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0019
        /////////////////////////////////////////
        loanDefaultGracePeriodInMinutes = _value;
    }


    /////////////////////////////////////////
    // LA-0001
    /////////////////////////////////////////

    /// @notice The duration in minutes that the auction MUST be active beyond the collateralSellDate
    uint256 public minDurationBeyondSellableDateInMinutes = 1440;

    function setMinDurationBeyondSellableDateInMinutes(uint256 _value) public onlyOwner {
        minDurationBeyondSellableDateInMinutes = _value;
    }

    /////////////////////////////////////////
    // LA-0002
    /////////////////////////////////////////

    /// @notice The minimum percentage of the collateral price (loan amount, not estimated value) the loan can sell for
    /// @dev value is stored in 10 thousandth position
    uint256 public minAuctionPercentOfLoanAmount = 100;

    function setMinAuctionPercentOfLoanAmount(uint256 _value) public onlyOwner {
        minAuctionPercentOfLoanAmount = _value;
    }

    /////////////////////////////////////////
    // LA-0004
    /////////////////////////////////////////

    /// @notice Maximum number of days an auction can be active
    uint256 public maxAuctionDurationInMinutes = 86400;

    function setMaxAuctionDurationInMinutes(uint256 _value) public onlyOwner {
        maxAuctionDurationInMinutes = _value;
    }

    /////////////////////////////////////////
    // LA-0005
    /////////////////////////////////////////

    /// @notice The fee the protocol charges
    /// @dev value is stored in 10 thousandth position
    uint256 public protocolAuctionFeePercentage = 500;

    function setProtocolAuctionFeePercentage(uint256 _value) public onlyOwner {
        protocolAuctionFeePercentage = _value;
    }
}