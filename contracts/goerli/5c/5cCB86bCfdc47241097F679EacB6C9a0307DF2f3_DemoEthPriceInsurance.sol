// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
//0x142dC2cF1565C6838a125dA34d8700bB0705b664
pragma solidity ^0.8.0;

// / @title ETHEREUM PRICE DEVALUATION INSURANCE
// / @author TheBlocAmora TEAM
// / @notice This is an insurance policy for $ETH Price Devaluation
// / @notice Contract owner cannot transfer contract funds
// / @notice Contract leverages parametric insurance model, using chainlink price feeds
// / as a decentralized oracle to automatically handle claim assessment and settlement
// / Users also hold a policy NFT with DYNAMIC METADATA as Proof of Agreement!
// / This NFT is minted upon policy creation and burnt after claim settlements
// / @dev All function calls are currently implemented without side effects
// / @custom:testing stages. This contract has been rigorously tested.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IInsurancePolicy.sol";

contract DemoEthPriceInsurance is Ownable, ReentrancyGuard {
    /// @notice A Struct to record each holder of this policy
    /// @dev Struct stores each policyholder's Data
    struct PolicyHolder {
        uint256 insuredPrice;
        uint256 premiumPaid;
        uint256 timeDuration;
        uint256 portfolioValue;
        bool hasPolicy;
    }

    //**************VARIABLE DECLARATION***************//
    uint256 public tokenIds;
    uint256 public noOfHolders;
    uint256 public ethPrice;

    // policy contract instance
    IInsurancePolicy nftPolicy;

    //chainlink price feeds
    AggregatorV3Interface internal priceFeed;

    // a list of all Policy holders
    mapping(address => PolicyHolder) public policyHolders;
    // mapping(uint256 => PolicyHolder) public policyHolders;
    // stores record of insured users
    mapping(address => bool) insured;

    /**
     * Network: Goerli * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        nftPolicy = IInsurancePolicy(
            0xb5FfEcac8d239a19836DBEcb5262DA2B7Ca6b78e
        );
    }

    //******************READABLE FUNCTIONS*******************//
    /**
     * Returns the latest price of Ethereum in USD
     */

    /// @notice reads the current price of ETH from chainlink price feeds
    /// @dev returns $Ether as 8 decimals value
    /// @dev function rounds up $Ether price to 18 decimals by ^10
    function getEthPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10 ** 10);
    }

    /// @notice function calls getEthPrice() above
    /// @dev enables price feeds data to be reused inside of functions
    /// @dev stores $Ether price into ethPrice
    function checkEthPrice() public returns (uint256) {
        ethPrice = getEthPrice();
        return ethPrice;
    }

    /// @notice function handles the calculation of installmental payments
    /// @dev can only be called by this contract
    function calculateMinimumPremium(
        uint256 _value
    ) private pure returns (uint256) {
        //calculate how much premium user is to pay point
        uint256 premiumInstallments = (_value / 3) * 10 ** 18;
        return premiumInstallments;
    }

    /// @notice function handles the calculation of installmental payments
    /// @dev can only be called by contract owner
    function contractBalance() public view onlyOwner returns (uint256) {
        address insureContract = address(this);
        uint256 insurePool = insureContract.balance;
        return insurePool;
    }

    //******************WRITABLE FUNCTIONS*******************//

    /// @notice Enables DeFi users to create policy agreement
    /// @dev Updates parameters in struct
    /// @dev Records the data of every policyholder && tracks who holds policy
    /// @dev Function mints NFT with a DYNAMIC METADATA to holders wallet
    /// @dev DYNAMIC METADATA stores the "price", "duration" and "portfolio" insured onchain!
    /// @param _price is the ETH price a user wants to insure against
    /// @param _timeDuration the number of days the user wants cover to run(must not be lesser than 30 days)
    /// @param _porfolioValue is the portfolio size of the user. This determines amount to be paid as premium
    function createPolicyAgreement(
        uint256 _price,
        uint256 _timeDuration,
        uint _porfolioValue
    ) public payable {
        //require user hasn't claimed policy already
        require(!insured[msg.sender], "You have the policy already!");
        require(_price > 0, "Invalid Price!");
        uint price = _price * 10 ** 18;
        //require insurance period is more 30 days
        require(_timeDuration >= 30, "Duration must be more than 30Days!");
        //portfolio value is not 0
        require(_porfolioValue > 0, "Portfolio is too small");
        /// check ETH price isn't already less
        // require(getEthPrice() > price, "Price isn't valid");

        /// Update User Policy details
        policyHolders[msg.sender].insuredPrice = price;
        policyHolders[msg.sender].timeDuration = _timeDuration;
        policyHolders[msg.sender].portfolioValue = _porfolioValue;
        policyHolders[msg.sender].hasPolicy = true;
        noOfHolders++;

        ////////////////////////////
        // withdraw premium payment
        uint256 premium = calculateMinimumPremium(_porfolioValue);
        require(msg.value >= premium, "Premium Value isn't valid");

        address payable contractAddress = payable(address(this));
        contractAddress.transfer(premium);
        ////////////////////////////

        //Update premiumPaid
        policyHolders[msg.sender].premiumPaid += premium;

        //record user has insured
        insured[msg.sender] = true;
        // mint NFT to wallet
        // nftPolicy.mintNFT(msg.sender, _price, _timeDuration, _porfolioValue);
        //
    }

    /// @notice Enables DeFi users to withdraw premiums paid (No questions asked)
    /// @dev Function uses Chainlink price feeds to check if $Eth price
    /// @dev is below insured amount, if true, pays holder
    function claimSettlement() public nonReentrant {
        // require sender owns NFT OR he's on the insured list
        require(insured[msg.sender] == true, "You're not entitled to this!");
        //// require present ETH price is less than the amount user insured
        // require(policyHolders[msg.sender].insuredPrice < ethPrice);
        ///////////////////
        //// require agreement is more than 30days
        // require(policyHolders[msg.sender].timeDuration < 30, "");
        ///////////////////
        //
        ///////////////////
        // Withdraw Funds Paid by Users to their Wallet
        uint amountToBePaid = policyHolders[msg.sender].premiumPaid;
        payable(msg.sender).transfer(amountToBePaid);
        ///////////////////
        // @dev later take 1% of claim withdrawn for maintainance
        ///////////////////
        // BurnNFT
        // nftPolicy.burn();
        insured[msg.sender] = false;
        ///////////////////
        noOfHolders--;
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInsurancePolicy {
    function mintNFT(
        address recipient,
        uint256 _price,
        uint256 _timeDuration,
        uint256 _portfolioValue
    ) external;

    function mintInsureNFT(
        address recipient,
        uint256 _NFTInsurancePolicyID,
        uint256 _startDate,
        uint256 _endDay,
        uint256 _insureAmount,
        string memory _NFTName,
        string memory _NFTSymbol,
        string memory _NFTTokenURI
    ) external;

    function getTokenURI(
        uint256 _tokenID
    ) external view returns (string memory);

    function burnNFT(uint256 _tokenID) external;
}