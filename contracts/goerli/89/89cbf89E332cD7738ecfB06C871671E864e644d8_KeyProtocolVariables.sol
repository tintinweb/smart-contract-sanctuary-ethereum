//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KeyProtocolVariables is Ownable {
    address public dao;

    bool public preLaunch = true;

    //Commisions
    uint256 public xTokenMintFee = 300; // 3%
    uint256 public cTokenSellFee = 1000; // 10%
    uint256 public payRentFee = 150; // 1.5%

    uint256 public validatorCommission = 25; // 0.25%
    uint256 public maxValidatorFee = 1000;

    uint256 public sellXTokenSlippage = 300; //3%
    uint256 public buyXTokenSlippage = 300; //3%

    uint256 public hedgeFundAllocation = 1500; //15%
    uint8 public securityDepositMonths = 12; // 12 months

    uint256 public landXOpertationsPercentage = 3000;
    uint256 public landXChoicePercentage = 500;
    uint256 public lndxHoldersPercentage = 6500;

    // Wallets
    address public hedgeFundWallet;
    address public landxOperationalWallet;
    address public landxChoiceWallet;
    address public xTokensSecurityWallet;
    address public validatorCommisionWallet;

    constructor(
        address _dao,
        address _hedgeFundWallet,
        address _landxOperationalWallet,
        address _landxChoiceWallet,
        address _xTokensSecurityWallet,
        address _validatorCommisionWallet
    ) {
        dao = _dao;

        require(_hedgeFundWallet != address(0), "zero address is not allowed");
        require(_landxOperationalWallet != address(0), "zero address is not allowed");
        require(_landxChoiceWallet != address(0), "zero address is not allowed");
        require(_xTokensSecurityWallet != address(0), "zero address is not allowed");
        require(_validatorCommisionWallet != address(0), "zero address is not allowed");

        hedgeFundWallet = _hedgeFundWallet;
        landxOperationalWallet = _landxOperationalWallet;
        landxChoiceWallet = _landxChoiceWallet;
        xTokensSecurityWallet = _xTokensSecurityWallet;
        validatorCommisionWallet = _validatorCommisionWallet;
    }

    function updateXTokenMintFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        xTokenMintFee = _fee;
    }

    function updateCTokenSellFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        cTokenSellFee = _fee;
    }

    function updateValidatorCommission(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        validatorCommission = _fee;
    }

     function updateMaxValidatorFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        maxValidatorFee = _fee;
    }

    function updateSellXTokenSlippage(uint256 _slippage) public {
        require(msg.sender == dao, "only dao can change value");
        require(_slippage < 10000, "value can't be above 100%");
        sellXTokenSlippage = _slippage;
    }

    function updateBuyXTokenSlippage(uint256 _slippage) public {
        require(msg.sender == dao, "only dao can change value");
        require(_slippage < 10000, "value can't be above 100%");
        buyXTokenSlippage = _slippage;
    }

    function updatePayRentFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        payRentFee = _fee;
    }

    function updateHedgeFundAllocation(uint256 _allocation) public {
        require(msg.sender == dao, "only dao can change value");
        require(_allocation < 10000, "value can't be above 100%");
        hedgeFundAllocation = _allocation;
    }

    function updateSecurityDepositMonths(uint8 _months) public {
        require(msg.sender == dao, "only dao can change value");
        securityDepositMonths = _months;
    }

    function updateFeeDistributionPercentage(
        uint256 _lndxHoldersPercentage,
        uint256 _landxOperationPercentage
    ) public {
        require(msg.sender == dao, "only dao can change value");
        require(
            (_lndxHoldersPercentage + _landxOperationPercentage) < 10000,
            "inconsistent values"
        );
        lndxHoldersPercentage = _lndxHoldersPercentage;
        landXOpertationsPercentage = _landxOperationPercentage;
        landXChoicePercentage =
            10000 -
            lndxHoldersPercentage -
            landXOpertationsPercentage;
    }

    function updateHedgeFundWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        hedgeFundWallet = _wallet;
    }

    function updateLandxOperationalWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        landxOperationalWallet = _wallet;
    }

    function updateLandxChoiceWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        landxChoiceWallet = _wallet;
    }

    function updateXTokensSecurityWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        xTokensSecurityWallet = _wallet;
    }

    function updateValidatorCommisionWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        validatorCommisionWallet = _wallet;
    }

     function updateDao(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        dao = _wallet;
    }

    function launch() public {
        require(msg.sender == dao, "only dao can change value");
        preLaunch = false;
    }

    function renounceOwnership() public view override onlyOwner {
        revert ("can 't renounceOwnership here");
    }
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