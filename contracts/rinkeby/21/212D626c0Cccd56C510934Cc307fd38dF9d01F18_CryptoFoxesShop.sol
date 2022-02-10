// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CryptoFoxesShopWithdraw.sol";
import "./CryptoFoxesShopProducts.sol";

contract CryptoFoxesShop is Ownable, CryptoFoxesShopProducts, CryptoFoxesShopWithdraw, ReentrancyGuard{

    mapping(string => uint256) public purchasedProduct;
    mapping(string => mapping(address => uint256)) public purchasedProductWallet;

    uint256 public purchaseId;

    event Purchase(address indexed _owner, string indexed _slug, uint256 _quantity, uint256 _id);

    constructor(address _cryptoFoxesSteak) CryptoFoxesShopWithdraw(_cryptoFoxesSteak) {}

    //////////////////////////////////////////////////
    //      TESTER                                  //
    //////////////////////////////////////////////////

    function checkPurchase(string memory _slug, uint256 _quantity, address _wallet) private{

        require(products[_slug].enable && _quantity > 0,"Product not available");

        if(products[_slug].start > 0 && products[_slug].end > 0){
            require(products[_slug].start <= block.timestamp && block.timestamp <= products[_slug].end, "Product not available");
        }

        if (products[_slug].quantityMax > 0) {
            require(purchasedProduct[_slug] + _quantity <= products[_slug].quantityMax, "Product sold out");
            purchasedProduct[_slug] += _quantity;
        }

        if(products[_slug].maxPerWallet > 0){
            require(purchasedProductWallet[_slug][_wallet] + _quantity <= products[_slug].maxPerWallet, "Max per wallet limit");
            purchasedProductWallet[_slug][_wallet] += _quantity;
        }
    }

    //////////////////////////////////////////////////
    //      PURCHASE                               //
    //////////////////////////////////////////////////

    function purchase(string memory _slug, uint256 _quantity) public nonReentrant {
        _purchase(_msgSender(), _slug, _quantity);
    }

    function purchaseCart(string[] memory _slugs, uint256[] memory _quantities) public nonReentrant {
        _purchaseCart(_msgSender(), _slugs, _quantities);
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function _purchase(address _wallet, string memory _slug, uint256 _quantity) private {

        checkPurchase(_slug, _quantity, _wallet);

        uint256 price = products[_slug].price * _quantity;

        if(price > 0){
            cryptoFoxesSteak.transferFrom(_wallet, address(this), price);
        }

        purchaseId += 1;
        emit Purchase(_msgSender(), _slug, _quantity, purchaseId);
    }

    function _purchaseCart(address _wallet, string[] memory _slugs, uint256[] memory _quantities) private  {
        require(_slugs.length == _quantities.length, "Bad data length");

        uint256 price = 0;
        for (uint256 i = 0; i < _slugs.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if(_compareStrings(_slugs[j], _slugs[i]) == true) {
                    revert("Duplicate slug");
                }
            }
            checkPurchase(_slugs[i], _quantities[i], _wallet);
            price += products[_slugs[i]].price * _quantities[i];
        }

        if(price > 0){
            cryptoFoxesSteak.transferFrom(_wallet, address(this), price);
        }

        for (uint256 i = 0; i < _slugs.length; i++) {
            purchaseId += 1;
            emit Purchase(_wallet, _slugs[i], _quantities[i], purchaseId);
        }
    }

    //////////////////////////////////////////////////
    //      PURCHASE BY CONTRACT                   //
    //////////////////////////////////////////////////

    function purchaseByContract(address _wallet, string memory _slug, uint256 _quantity) public isFoxContract {
        _purchase(_wallet, _slug, _quantity);
    }

    function purchaseCartByContract(address _wallet, string[] memory _slugs, uint256[] memory _quantities) public isFoxContract {
        _purchaseCart(_wallet, _slugs, _quantities);
    }

    //////////////////////////////////////////////////
    //      PRODUCT GETTER                          //
    //////////////////////////////////////////////////

    function getProductPrice(string memory _slug, uint256 _quantity) public view returns(uint256){
        return products[_slug].price * _quantity;
    }
    function getProductStock(string memory _slug) public view returns(uint256){
        return products[_slug].quantityMax - getTotalProductPurchased(_slug);
    }
    function getTotalProductPurchased(string memory _slug) public view returns(uint256){
        return purchasedProduct[_slug];
    }
    function getTotalProductPurchasedWallet(string memory _slug, address _wallet) public view returns(uint256){
        return purchasedProductWallet[_slug][_wallet];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICryptoFoxesSteakBurnable.sol";

// @author: miinded.com

interface ICryptoFoxesSteakBurnableShop is IERC20, ICryptoFoxesSteakBurnable {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICryptoFoxesSteak.sol";

// @author: miinded.com

interface ICryptoFoxesSteakBurnable is ICryptoFoxesSteak {
    function burnSteaks(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesSteak {
    function addRewards(address _to, uint256 _amount) external;
    function withdrawRewards(address _to) external;
    function isPaused() external view returns(bool);
    function dateEndRewards() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesShopStruct {

    struct Product {
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 maxPerWallet; // 0 for infinity
        uint256 quantityMax; // 0 for infinity
        bool enable;
        bool isValid;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICryptoFoxesShopStruct.sol";

// @author: miinded.com

interface ICryptoFoxesShopProducts is ICryptoFoxesShopStruct {

    function getProducts() external view returns(Product[] memory);
    function getProduct(string calldata _slug) external view returns(Product memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CryptoFoxesAllowed.sol";
import "./interfaces/ICryptoFoxesSteakBurnableShop.sol";

contract CryptoFoxesShopWithdraw is CryptoFoxesAllowed {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 part;
        uint256 timestamp;
    }
    uint256 startIndexParts = 0;

    Part[] public parts;

    ICryptoFoxesSteakBurnableShop public cryptoFoxesSteak;

    constructor(address _cryptoFoxesSteak) {
        cryptoFoxesSteak = ICryptoFoxesSteakBurnableShop(_cryptoFoxesSteak);

        parts.push(Part(address(0), 90, block.timestamp));
    }

    function changePart(Part[] memory _parts) public isFoxContractOrOwner{
        startIndexParts = parts.length;
        for(uint256 i = 0; i < _parts.length; i++){
            parts.push(Part(_parts[i].wallet, _parts[i].part, block.timestamp));
        }
    }

    function getParts() public view returns(Part[] memory){
        return parts;
    }

    //////////////////////////////////////////////////
    //      WITHDRAW                                //
    //////////////////////////////////////////////////

    function withdrawAndBurn() public isFoxContractOrOwner {
        uint256 balance = cryptoFoxesSteak.balanceOf(address(this));
        require(balance > 0);

        for (uint256 i = startIndexParts; i < parts.length; i++) {
            if (parts[i].part == 0) {
                continue;
            }
            if (parts[i].wallet == address(0)) {
                cryptoFoxesSteak.burn(balance.mul(parts[i].part).div(100));
            } else {
                cryptoFoxesSteak.transfer(parts[i].wallet, balance.mul(parts[i].part).div(100));
            }
        }

        cryptoFoxesSteak.transfer(owner(), cryptoFoxesSteak.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICryptoFoxesShopProducts.sol";
import "./CryptoFoxesAllowed.sol";

contract CryptoFoxesShopProducts is ICryptoFoxesShopProducts, CryptoFoxesAllowed{

    mapping(string => Product) public products;
    string[] public productSlugs;

    //////////////////////////////////////////////////
    //      PRODUCT SETTER                          //
    //////////////////////////////////////////////////

    function addProduct(string memory _slug, Product memory _product) public isFoxContractOrOwner{
        require(!products[_slug].isValid, "Product slug already exist");
        require(_product.isValid, "Missing isValid param");
        products[_slug] = _product;
        productSlugs.push(_slug);
    }

    function editProduct(string memory _slug, Product memory _product) public isFoxContractOrOwner{
        require(products[_slug].isValid, "Product slug does not exist");
        require(_product.isValid, "Missing isValid param");

        if(products[_slug].maxPerWallet == 0){
            require(_product.maxPerWallet == 0, "maxPerWallet == 0, need to change slug");
        }

        products[_slug] = _product;
    }

    function statusProduct(string memory _slug, bool _enable) public isFoxContractOrOwner {
        require(products[_slug].isValid, "Product slug does not exist");
        products[_slug].enable = _enable;
    }

    //////////////////////////////////////////////////
    //      PRODUCT GETTER                          //
    //////////////////////////////////////////////////

    function getProduct(string memory _slug) public override view returns(Product memory) {
        return products[_slug];
    }
    function getProducts() public override view returns(Product[] memory) {
        Product[] memory prods = new Product[](productSlugs.length);
        for(uint256 i = 0; i < productSlugs.length; i ++){
            prods[i] = products[productSlugs[i]];
        }
        return prods;
    }
    function getSlugs() public view returns(string[] memory) {
        return productSlugs;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoFoxesSteak.sol";

// @author: miinded.com

abstract contract CryptoFoxesAllowed is Ownable {

    mapping (address => bool) public allowedContracts;

    modifier isFoxContract() {
        require(allowedContracts[_msgSender()] == true, "Not allowed");
        _;
    }
    
    modifier isFoxContractOrOwner() {
        require(allowedContracts[_msgSender()] == true || _msgSender() == owner(), "Not allowed");
        _;
    }

    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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