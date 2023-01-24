/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

interface INFTContract {
    // --------------- ERC1155 -----------------------------------------------------

    function balanceOf(address _owner, uint256 _id)external view returns (uint256);  
    function setApprovalForAll(address _operator, bool _approved) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    // ---------------------- ERC721 ------------------------------------------------
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // function setApprovalForAll(address _operator, bool _approved) external;
    function approve(address _approved, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function getRoyalityDetails(uint256 _tokenId) external view returns(address creator, uint256 percentage);

    // --------------------IWETH-----------------------------------------------------------
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract NFTMarketplace is Ownable{
    using SafeMath for uint256;
    using Address for address;

    enum EOrderType{
        None,
        Fixed,
        Auction
    }

    enum EOrderStatus{
        None,
        OpenForTheMarket,
        MarketCancelled,
        MarketClosed
    }

    struct Market{
        address contractAddress;
        uint256 tokenId;
        EOrderType orderType;
        EOrderStatus orderStatus;
        uint256 askAmount;
        uint256 maxAskAmount;
        address currentOwner;
        address newOwner;
    } 


    address private WETH;
    uint256 private feePercentage;
    address private feeAddress;
    mapping (bytes32 => Market) private markets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _WETH, uint256 _feePercentage, address _feeAddress) {
        feePercentage = _feePercentage;
        feeAddress = _feeAddress;
        WETH = _WETH;    
    }

    function setWETH(address _WETH) external onlyOwner{
        WETH = _WETH;
    }

    function getWETH() external view returns(address _WETH){
        return WETH;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner{
        feePercentage = _feePercentage; 
    }
    
    function getFeePercentage()external view returns(uint256 _feePercentage){
        return feePercentage; 
    }

    function setFeeAddress(address _feeAddress) external onlyOwner{
        feeAddress = _feeAddress; 
    }
    
    function getFeeAddress()external view returns(address _feeAddress){
        return feeAddress; 
    }

    function getPrivateUniqueKey(address nftContractId, uint256 tokenId) private pure returns (bytes32){
        return keccak256(abi.encodePacked(nftContractId, tokenId));
    }

    function getMarketObj(address nftContractId, uint256 tokenId) public view returns (Market memory){
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        return markets[uniqueKey];
    }

    function openMarketForFixedType(address nftContractId, uint256 tokenId, uint256 price ) external{
        openMarket(nftContractId,tokenId,price,EOrderType.Fixed, 0);
    }

    function openMarketForAuctionType(address nftContractId, uint256 tokenId, uint256 price, uint256 maxPrice) external{
        openMarket(nftContractId,tokenId,price,EOrderType.Auction, maxPrice);
    }

    function openMarket(address nftContractId, uint256 tokenId, uint256 price, EOrderType orderType, uint256 maxPrice) private{
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        /// For update lisitng.
        if (markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket) {
            address nftCurrentOwner = INFTContract(nftContractId).ownerOf(
                tokenId );
            if ( nftCurrentOwner == msg.sender &&
                nftCurrentOwner != markets[uniqueKey].currentOwner) {
                markets[uniqueKey].orderType = orderType;
                markets[uniqueKey].askAmount = price;
                markets[uniqueKey].maxAskAmount = maxPrice;
                markets[uniqueKey].currentOwner = payable(nftCurrentOwner);
                return;
            } else if (nftCurrentOwner == markets[uniqueKey].currentOwner) {
                revert("Market order is already opened");
            } else {
                revert("Not authorized");
            }
        }
        if(price <= 0){
            revert ("Price Should be greater then 0");
        }

        if(orderType == EOrderType.Auction && price > maxPrice){
            revert ("end Price Should be greater then price");
        }

        markets[uniqueKey].orderStatus = EOrderStatus.OpenForTheMarket;
        markets[uniqueKey].orderType = orderType;
        markets[uniqueKey].askAmount = price;
        markets[uniqueKey].maxAskAmount = maxPrice;
        markets[uniqueKey].contractAddress = nftContractId;
        markets[uniqueKey].tokenId = tokenId;
        markets[uniqueKey].currentOwner = payable(msg.sender);
    }

    function closeMarketForFixedType(address nftContractId, uint256 tokenId ) external payable{ 
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);
        
        if(markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket){
        
            if(markets[uniqueKey].orderType == EOrderType.None){
                revert ("nft not opened");
            }
            else if(markets[uniqueKey].orderType == EOrderType.Fixed){
                if(markets[uniqueKey].askAmount < msg.value){
                    revert ("Value not matched");
                }
            }else if (markets[uniqueKey].orderType == EOrderType.Auction){
            if(markets[uniqueKey].maxAskAmount < msg.value){
                    revert ("Value not matched");
                }
            }
            INFTContract(WETH).deposit{value:msg.value}();
            INFTContract nftContract = INFTContract(markets[uniqueKey].contractAddress);
            bool txStatus;
            uint256 fee = getFeePercentage(msg.value, feePercentage);

            // require(address(this).balance >= fee, "Insufficient balance. FEE"); /// remove require

            // payable(feeAddress).transfer(fee);
            txStatus = IERC20(WETH).transfer(feeAddress, fee);
            require(txStatus, "FEE transfer Failed");

            (address creator, uint256 royality) = nftContract.getRoyalityDetails(tokenId);
            uint256 creatorShare = getFeePercentage(msg.value,royality);

            // require(address(this).balance >= creatorShare, "Insufficient balance. Amount for creator"); /// remove require
            // payable(creator).transfer(creatorShare); 
            txStatus = IERC20(WETH).transfer(creator, creatorShare);
            require(txStatus, "Creator Share transfer Failed");

            
            // require(address(this).balance >= (msg.value.sub(fee+creatorShare)), "Insufficient balance. currentOwner share"); /// remove require
            
            // payable(markets[uniqueKey].currentOwner).transfer(msg.value.sub(fee+creatorShare));
            
            txStatus = IERC20(WETH).transfer(markets[uniqueKey].currentOwner, msg.value.sub(fee+creatorShare));
            require(txStatus, "Owner Share transfer Failed");


            nftContract.safeTransferFrom(markets[uniqueKey].currentOwner, msg.sender, tokenId);
            markets[uniqueKey].orderStatus = EOrderStatus.MarketClosed;
            markets[uniqueKey].newOwner = msg.sender;

        }else{
            revert ("Market order is not opened");
        }
    }

    function closeMarketForAuctionType(address nftContractId, uint256 tokenId, uint256 price, address buyerAccount ) external{
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId,tokenId);

        if(markets[uniqueKey].currentOwner != msg.sender){
            revert ("only for market operator");
        }    
        if(markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket){

            if(markets[uniqueKey].askAmount < price){
                INFTContract nftContract = INFTContract(markets[uniqueKey].contractAddress);

                uint256 fee = getFeePercentage(price, feePercentage);
                
                IERC20(WETH).transferFrom(buyerAccount,feeAddress,fee);

                (address creator, uint256 royality) = nftContract.getRoyalityDetails(tokenId);
                uint256 creatorShare = getFeePercentage(price,royality);
                IERC20(WETH).transferFrom(buyerAccount,creator,creatorShare);

                IERC20(WETH).transferFrom(buyerAccount,markets[uniqueKey].currentOwner,price.sub(fee+creatorShare));

                nftContract.safeTransferFrom(markets[uniqueKey].currentOwner, buyerAccount, tokenId);

                markets[uniqueKey].orderStatus = EOrderStatus.MarketClosed;
                markets[uniqueKey].newOwner = buyerAccount;

            }else{
                revert ("Value not matched");
            }
        }else{
            revert ("Market order is not opened");
        }
    }

    function getFeePercentage(uint256 price, uint256 percent) private pure returns (uint256){
        return price.mul(percent).div(100);
    }

    function cancel(address nftContractId, uint256 tokenId) external {
        bytes32 uniqueKey = getPrivateUniqueKey(nftContractId, tokenId);

        if ( INFTContract(nftContractId).ownerOf(tokenId) == msg.sender || owner() == msg.sender ) {
            if (
                markets[uniqueKey].orderStatus == EOrderStatus.OpenForTheMarket
            ) {
                markets[uniqueKey].orderStatus = EOrderStatus.MarketCancelled;
            } else {
                revert("Market order is not opened");
            }
        } else {
            revert("Not authorized");
        }
    }
   /// payment 
    function getTokenBalance(address _tokenAddress) public view returns (uint256 _balance) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdrawToken(address _tokenAddress, address _destionation, uint256 _amount) public onlyOwner{
        IERC20(_tokenAddress).transfer(_destionation, _amount);
    }

    function withdrawCurrency(address _destionation, uint256 _amount) public onlyOwner {
        payable(_destionation).transfer(_amount);
    }

    receive() external payable {
    }

    fallback() external payable {
    }
}