/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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



pragma solidity ^0.8.7;



contract CaveStaking  is  Ownable  {
    using Strings for uint256;
    using SafeMath for uint256;

    bool public _isStakeSwitch = false;  
    bool public _isGetRewardSwitch = true;  

    IERC721 private TokenA;
    IERC20  private TokenB;

    address private tokenAaddress = 0xb578F948Df1F2e401522f8774229497C2BdDdFff;
    address private tokenBaddress = 0xd33B79F237508251e5740c5229f2c8Ea47Ee30C8;

    uint256 public TotalWithdrawal;  
    uint256 public ExtractNftNumber;   
    address[] private  StakingAddress; 

    uint256 private  profit; 

    uint256 private  marketValue; 
    uint256 public  minimumWithdrawalAmount = 99999999999999;  

    uint256 public minimumStakingDays = 7;

    mapping(address => bool) public _isBlacklisted;    

    mapping(address => uint256[])  StakingNumber; 
    mapping(address => mapping(uint256 => uint256))  StakingTime; 
    mapping(address => uint256)  NumberOfSharesHeld; 
    mapping(address => uint256)  public AmountOfDividendWithdrawn;  

    mapping(address => uint256) public  EntryNumber;  

    constructor(){
        TokenA = IERC721(tokenAaddress);
        TokenB = IERC20(tokenBaddress);
    }

    function setUpNftTokenA(address _TokenA) public onlyOwner {
        TokenA = IERC721(_TokenA);
    }
    function setUp20TokenB(address _TokenB) public onlyOwner {
        TokenB = IERC20(_TokenB);
    }
  
    function flipisStakeSwitch() public onlyOwner {
        _isStakeSwitch = !_isStakeSwitch;
    }

    function flipisGetRewardSwitch() public onlyOwner {
        _isGetRewardSwitch = !_isGetRewardSwitch;
    }

    function setUpminimumStakingDays(uint256 _number) public onlyOwner {
        minimumStakingDays = _number;
    }
 
    function setUpminimumWithdrawalAmount(uint256 _number) public onlyOwner {
        minimumWithdrawalAmount = _number;
    }

    function withdrawChoose(uint256[] memory _tokenId) public {
        uint256  tokenIdLength  = _tokenId.length;
    
        for(uint i = 0;i < tokenIdLength;i++){
            require(getAddressStakingNumberbool(_tokenId[i]), "No collateral found");
            require(block.timestamp > setEndStakingTime(_tokenId[i]), "time is not up yet");
        }

        uint256 _Number =  getRewardBalance();
        if(_Number > minimumWithdrawalAmount){
           getReward();
        }

        (uint256 _SharesToBeReduced, uint256 _ReductionPool) = OneRelinquishedShare(tokenIdLength);
        profit +=   _ReductionPool;

        for(uint i = 0; i < tokenIdLength; i++){
            TokenA.transferFrom(address(this),msg.sender ,_tokenId[i]);
        }

        ExtractNftNumber += tokenIdLength;

        (, uint256 _marketValueNum) =  marketValue.trySub(_SharesToBeReduced);
        marketValue = _marketValueNum;
        (, uint256 _NumberOfSharesHeldNum) =  NumberOfSharesHeld[msg.sender].trySub(_SharesToBeReduced);
        NumberOfSharesHeld[msg.sender] = _NumberOfSharesHeldNum;

        uint256 number = getAddressStakingNumberlength(msg.sender);
        EntryNumber[msg.sender] -= (EntryNumber[msg.sender].div(number)) * tokenIdLength;

        if(number == 1 || number == tokenIdLength){
            NumberOfSharesHeld[msg.sender] = 0;
            EntryNumber[msg.sender] = 0;
            (bool response, uint256 _StakingAddresskey)  = getStakingAddresskey(msg.sender);
            if(response == true) deleteAddress(_StakingAddresskey);
        }
        for(uint i = 0; i < tokenIdLength; i++){
            (bool respond, uint256 _num)  = getAddressStakingNumberkey(_tokenId[i]);
            if(respond == true)deleteAddressStakingNumber(_num);
            deleteStakingTime(_tokenId[i]);
        }
    }
  
    function OneRelinquishedShare(uint256 _Number) internal view returns(uint256 ,uint256){
        uint256 pleNumber = getAddressStakingNumberlength(msg.sender);

         (,uint256 ProportionOfOneShareNum) = getIncreaseWei(NumberOfSharesHeld[msg.sender]).tryDiv(getNFTWei(pleNumber)); 
         uint256 SharesToBeReduced = ProportionOfOneShareNum.mul(getNFTWei(_Number));   
         uint256 ReductionPool = getReduceWei(SharesToBeReduced.mul(getSingleSharePrice()));  
        return (getReduceWei(SharesToBeReduced),getReduceWei(ReductionPool));
    }

  
    function stake(uint256[] memory _tokenId) public {
        require(_isStakeSwitch, "Can not be stake temporarily");
      
        uint256  tokenIdLength  = _tokenId.length;
        require(tokenIdLength > 0, "needs to be greater than 0");
        for(uint i = 0;i < tokenIdLength;i++){
            require(TokenA.ownerOf(_tokenId[i]) ==  msg.sender, "Insufficient balance");
        }


        if(marketValue == 0 || getTotalPool() == 0){
            marketValue +=  getNFTWei(tokenIdLength);
            NumberOfSharesHeld[msg.sender] = getNFTWei(tokenIdLength);
        }else{
            uint256  numberOfShares =  getIncreaseWei(getNFTWei(tokenIdLength)).div(getSingleSharePrice());
            marketValue += numberOfShares;
            NumberOfSharesHeld[msg.sender] +=  numberOfShares;
        }

        for(uint i= 0;i < tokenIdLength;i++){
            TokenA.transferFrom(msg.sender,address(this),_tokenId[i]);
            StakingNumber[msg.sender].push(_tokenId[i]);
            StakingTime[msg.sender][_tokenId[i]] = block.timestamp;
        }


        if(!getStakingAddressbool(msg.sender))
        StakingAddress.push(msg.sender);
    }


    function getRewardBalance() public view returns(uint256){
        uint256 pleNumber = getAddressStakingNumberlength(msg.sender);
        require(pleNumber > 0, "No collateral found");

        (,uint256 reducedNumber)  = getNFTWei(pleNumber).tryAdd(EntryNumber[msg.sender]);
        (,uint256 _plenumber)  =  getReduceWei(NumberOfSharesHeld[msg.sender].mul(getSingleSharePrice())).trySub(reducedNumber);
        if(getTokenBnumber() < _plenumber){
            _plenumber = getTokenBnumber();
        }
        return _plenumber;
    }
  
    function getReward() public  returns(uint256){ 
        require(_isGetRewardSwitch, "Temporarily unable to receive rewards");      
        require(!_isBlacklisted[msg.sender], "Blacklisted address");      

        uint256 dividends = getRewardBalance();
        if(dividends > minimumWithdrawalAmount){
            TokenB.transfer(msg.sender,dividends);
            AmountOfDividendWithdrawn[msg.sender] += dividends;
            EntryNumber[msg.sender] += dividends;
            TotalWithdrawal += dividends;
        }
        return dividends;
    }
 
    function getTotalPool() public view returns(uint256){
        uint256 nftStakingNum = getNftNum();
        uint256 TokenBnumber = getTokenBnumber();
        return getNFTWei(nftStakingNum + ExtractNftNumber) + TokenBnumber + TotalWithdrawal - profit;
    }
  
    function getNftNum() public view returns(uint256){
        return TokenA.balanceOf(address(this));
    }
 
    function getTokenBnumber() public view returns(uint256){
        return TokenB.balanceOf(address(this));
    }
  
    function getStakingAddresslength() public view returns(uint256){
        return StakingAddress.length;
    }
    
    function getAddressStakingNumberlength(address _addr) public view returns(uint256){
        return StakingNumber[_addr].length;
    }
    
    function getAddressStakingNumberkey(uint256 _tokenId) public view returns(bool,uint){
        uint256 popNum = getAddressStakingNumberlength(msg.sender);
        for(uint i = 0; i < popNum; i++){
            if(StakingNumber[msg.sender][i] == _tokenId){
                return (true,i);
            }
        }
        return (false,0);
    }
     
    function deleteAddressStakingNumber(uint256 _num) private {

        uint256 popNum = getAddressStakingNumberlength(msg.sender) -1;
        StakingNumber[msg.sender][_num] = StakingNumber[msg.sender][popNum];
        StakingNumber[msg.sender].pop();

    }
  
  
    function getAddressStakingNumberbool(uint256 _tokenId) public view returns(bool){
        uint256 popNum = getAddressStakingNumberlength(msg.sender);
        for(uint i = 0; i < popNum; i++){
            if(StakingNumber[msg.sender][i] == _tokenId){
                return true;
            }
        }
        return false;
    }
    
    function getStakingAddressbool(address _StakingAddress) public view returns(bool){
        uint256 StakingNumlength = getStakingAddresslength();
        for(uint i = 0; i < StakingNumlength; i++){
            if(StakingAddress[i] == _StakingAddress){
                return true;
            }
        }
        return false;
    }

    
    function getStakingAddresskey(address _StakingAddress) public view returns(bool,uint){
        uint256 StakingNumlength = getStakingAddresslength();
        for(uint i = 0; i < StakingNumlength; i++){
            if(StakingAddress[i] == _StakingAddress){
                return (true,i);
            }
        }
        return (false,0);
    }
    
    function deleteAddress(uint256 _num) private {
        uint256 popNum = getStakingAddresslength() -1;
        StakingAddress[_num] = StakingAddress[popNum];
        StakingAddress.pop();

    }

    
    function getSingleSharePrice() public view returns(uint256){
        (, uint256 _number) = getIncreaseWei(getTotalPool()).tryDiv(marketValue);
        return _number;
    }
    
    function  getIncreaseWei(uint256 _Number) internal pure returns(uint256) {
        return _Number * 10 ** 18;
    }
    
    function  getReduceWei(uint256 _Number) internal pure returns(uint256) {
        return _Number / 10 ** 18;
    }

    function getNFTWei(uint256 _num) internal pure returns(uint256){
        return _num * 10 ** 19;
    }  
  
    function getNumberOfSharesHeld() public view  returns(uint256){
        return  NumberOfSharesHeld[msg.sender];
    } 

    function getAddressStakingNumberarray() public view returns(uint256[] memory){
        return StakingNumber[msg.sender];
    }

    function deleteStakingTime(uint256 _num) internal {
        delete StakingTime[msg.sender][_num];
    }

    function setStakingTime(uint256 _num) public view returns(uint256){
        return StakingTime[msg.sender][_num];
    }

    function setEndStakingTime(uint256 _num) public view returns(uint256){
        return StakingTime[msg.sender][_num] + (minimumStakingDays * 24 * 3600);
    }

    function setAllStakingTime(address _addr,bool _type) public view returns(uint256[] memory){
      uint  NftLength  =   getAddressStakingNumberlength(_addr);
      uint256[] memory allTime = new uint[](NftLength);
      uint counter = 0;
      for(uint i = 0; i < NftLength; i++){
            if(_type){
                allTime[counter] =  StakingTime[_addr][StakingNumber[_addr][i]] + (minimumStakingDays * 24 * 3600);
            }else{
                allTime[counter] =  StakingTime[_addr][StakingNumber[_addr][i]];
            }
           counter++;
      }
      return allTime;
    }

    function blacklistAddress(address account, bool value) public onlyOwner{
        _isBlacklisted[account] = value;   
    }

    function safetyWithdraw(address _addr) public onlyOwner  {
        uint256 balance = getTokenBnumber();
        TokenB.transfer(_addr,balance);
    }


    
}