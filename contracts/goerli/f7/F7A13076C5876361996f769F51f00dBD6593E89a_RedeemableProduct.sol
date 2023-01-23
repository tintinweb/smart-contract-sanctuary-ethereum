// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract RedeemableProduct {
    using SafeMath for uint256;

    event SetRedemptionAmount(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed amount
    );

    event AddProductName(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        string name
    );

    event RemoveProductName(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        string name
    );

    event SetRecipientAddress(address indexed recipientAddress);

    event AddVariation(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed variationId,
        string variant,
        uint256 priceInWei,
        bool paused
    );

    event UpdateVariation(
        address indexed genArtCoreAddress,
        uint256 indexed projectId,
        uint256 indexed variationId,
        string variant,
        uint256 priceInWei,
        bool paused
    );

    struct Order {
        address redeemer;
        string productName;
        string variant;
        uint256 priceInWei;
    }

    struct Variation {
        string variant;
        uint256 priceInWei;
        bool paused;
    }

    IGenArt721CoreV2 public genArtCoreContract;

    string private _contractName;
    address private _redemptionServiceAddress;
    address payable private _recipientAddress;

    mapping(address => mapping(uint256 => uint256)) private _redemptionAmount;
    mapping(address => mapping(uint256 => uint256)) private _isTokenRedeemed;
    mapping(address => mapping(uint256 => string)) private _productName;
    mapping(address => mapping(uint256 => mapping(uint256 => Order))) private _orderInfo;
    mapping(address => mapping(uint256 => mapping(uint256 => Variation))) private _variationInfo;
    mapping(address => mapping(uint256 => uint256)) private _nextVariationId;

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == genArtCoreContract.admin(), "Only admin");
        _;
    }

    modifier onlyRedemptionService() {
        require(msg.sender == _redemptionServiceAddress, 'only merch shop contract');
        _;
    }

    constructor(string memory contractName, address genArtCoreAddress, address redemptionServiceAddress, address payable recipientAddress) public {
        _contractName = contractName;
        genArtCoreContract = IGenArt721CoreV2(genArtCoreAddress);
        _redemptionServiceAddress = redemptionServiceAddress;
        _recipientAddress = recipientAddress;
    }

    function getContractName() public view returns(string memory contractName) {
        return _contractName;
    }

    function getNextVariationId(address genArtCoreAddress, uint256 projectId) public view returns(uint256 nextVariationId) {
        return _nextVariationId[genArtCoreAddress][projectId];
    }

    function getRecipientAddress() public view returns(address payable recipientAddress) {
        return _recipientAddress;
    }

    function getTokenRedemptionCount(address genArtCoreAddress, uint256 tokenId) public view returns(uint256 tokenRedeemptionCount) {
        return _isTokenRedeemed[genArtCoreAddress][tokenId];
    }

    function getRedemptionAmount(address genArtCoreAddress, uint256 projectId) public view returns(uint256 amount) {
        return _redemptionAmount[genArtCoreAddress][projectId];
    }

    function getProductName(address genArtCoreAddress, uint256 projectId) public view returns(string memory name) {
        return _productName[genArtCoreAddress][projectId];
    }

    function getVariationInfo(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(string memory variant, uint256 priceInWei, bool paused) {
        Variation memory variation = _variationInfo[genArtCoreAddress][projectId][variationId];
        return (variation.variant, variation.priceInWei, variation.paused);
    }

    function getVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(bool paused) {
        Variation memory variation = _variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.paused;
    }

    function getVariationPriceInWei(address genArtCoreAddress, uint256 projectId, uint256 variationId) public view returns(uint256 priceInWei) {
        Variation memory variation = _variationInfo[genArtCoreAddress][projectId][variationId];
        return variation.priceInWei;
    }

    function getOrderInfo(address genArtCoreAddress, uint256 tokenId, uint256 redemptionCount) public view returns(string memory contractName, address redeemer, string memory name, string memory variant, uint256 priceInWei) {
        Order memory order = _orderInfo[genArtCoreAddress][tokenId][redemptionCount];
        return (_contractName, order.redeemer, order.productName, order.variant, order.priceInWei);
    }

    function setRecipientAddress(address payable recipientAddress) public onlyAdmin {
        _recipientAddress = recipientAddress;
        emit SetRecipientAddress(_recipientAddress);
    }

    function setRedemptionAmount(address genArtCoreAddress, uint256 projectId, uint256 amount) public onlyGenArtWhitelist {
        emit SetRedemptionAmount(genArtCoreAddress, projectId, amount);
        _redemptionAmount[genArtCoreAddress][projectId] = amount;
    }

    function addProductName(address genArtCoreAddress, uint256 projectId, string memory name) public onlyGenArtWhitelist {
        _productName[genArtCoreAddress][projectId] = name;
        emit AddProductName(genArtCoreAddress, projectId, name);
    }

    function removeProductName(address genArtCoreAddress, uint256 projectId) public onlyGenArtWhitelist {
        string memory name = _productName[genArtCoreAddress][projectId];
        delete _productName[genArtCoreAddress][projectId];
        emit RemoveProductName(genArtCoreAddress, projectId, name);
    }

    function addVariation(address genArtCoreAddress, uint256 projectId, string memory variant, uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        uint256 variationId = _nextVariationId[genArtCoreAddress][projectId];
        _variationInfo[genArtCoreAddress][projectId][variationId].variant = variant;
        _variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        _variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        _nextVariationId[genArtCoreAddress][projectId] = variationId.add(1);
        emit AddVariation(genArtCoreAddress, projectId, variationId, variant, priceInWei, paused);
    }

    function updateVariation(address genArtCoreAddress, uint256 projectId, uint256 variationId, string memory variant, uint256 priceInWei, bool paused) public onlyGenArtWhitelist {
        _variationInfo[genArtCoreAddress][projectId][variationId].variant = variant;
        _variationInfo[genArtCoreAddress][projectId][variationId].priceInWei = priceInWei;
        _variationInfo[genArtCoreAddress][projectId][variationId].paused = paused;
        emit UpdateVariation(genArtCoreAddress, projectId, variationId, variant, priceInWei, paused);
    }

    function toggleVariationIsPaused(address genArtCoreAddress, uint256 projectId, uint256 variationId) public onlyGenArtWhitelist {
        _variationInfo[genArtCoreAddress][projectId][variationId].paused = !_variationInfo[genArtCoreAddress][projectId][variationId].paused;
    }

    function incrementRedemptionAmount(address redeemer, address genArtCoreAddress, uint256 tokenId, uint256 variationId) public onlyRedemptionService {
        uint256 redemptionCount = _isTokenRedeemed[genArtCoreAddress][tokenId].add(1);
        uint256 projectId = genArtCoreContract.tokenIdToProjectId(tokenId);
        uint256 purchasePriceInWei = getVariationPriceInWei(genArtCoreAddress, projectId, variationId);
        _isTokenRedeemed[genArtCoreAddress][tokenId] = redemptionCount;
        string memory product = _productName[genArtCoreAddress][projectId];
        Variation memory incrementedVariation = _variationInfo[genArtCoreAddress][projectId][variationId];
        _orderInfo[genArtCoreAddress][tokenId][redemptionCount] =
            Order(
                redeemer,
                product,
                incrementedVariation.variant,
                purchasePriceInWei
            );
    }
}

pragma solidity ^0.5.0;

interface IGenArt721CoreV2 {
  function isWhitelisted(address sender) external view returns (bool);
  function admin() external view returns(address);
  function projectIdToCurrencySymbol(uint256 _projectId) external view returns (string memory);
  function projectIdToCurrencyAddress(uint256 _projectId) external view returns (address);
  function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);
  function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);
  function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);
  function projectIdToAdditionalPayeePercentage(uint256 _projectId) external view returns (uint256);
  function projectTokenInfo(uint256 _projectId) external view returns (address, uint256, uint256, uint256, bool, address, uint256, string memory, address);
  function renderProviderAddress() external view returns (address payable);
  function renderProviderPercentage() external view returns (uint256);
  function mint(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
  function ownerOf(uint256 tokenId) external view returns (address);
  function tokenIdToProjectId(uint256 tokenId) external view returns(uint256);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/math/SafeMath.sol
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}