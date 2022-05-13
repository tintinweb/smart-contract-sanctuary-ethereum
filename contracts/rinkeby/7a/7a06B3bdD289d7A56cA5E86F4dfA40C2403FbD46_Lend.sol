// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

interface IVeNft{
  function getAmount(uint _tokenId) external view returns(uint);
  function getEnd(uint _tokenId) external view returns(uint);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IChee{
  function mint(address account, uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

interface Iizi{
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

contract Lend is IERC721Receiver{
    
  struct User{
    address lender;
    uint lockPeriod;
    uint amount;
    uint fee;
    uint lockPercentage;
  }


  User private user;
  uint internal interestRatePerBlock;
  uint internal feeRate;
  uint internal lockPercentageThreshold;
  uint internal graceTime;
  address internal depositAddress;
  uint internal maxLendingPeriod;

  using SafeMath for uint;
  address internal admin;
  uint internal value;


  mapping(address => bool) internal permissioned;
  mapping(address => mapping(uint => User)) internal userInfo;
  mapping(address => address) internal supportedAddress1;
  mapping(address => address) internal supportedAddress2;

  constructor(){
    admin = msg.sender;
  }  

  modifier onlyPermissioned{
    require(permissioned[msg.sender] == true,"You don't have permission");
    _;
  }

  modifier onlyAdmin{
    require(msg.sender == admin,"You are not an admin");
    _;
  }

  function changeAdmin(address _newAdmin) public onlyAdmin{
    require(_newAdmin != address(0),"Zero Address Detected");
    admin = _newAdmin;
  }  

  function whitelist(address _user) public onlyAdmin{
    require(_user != address(0),"Zero Address Detected");
    permissioned[_user] = true;
  }  

  function setInterestRatePerBlock(uint _interestRate) public onlyAdmin{
    require(_interestRate > 0,"Value cannot be less then 1");
    interestRatePerBlock = _interestRate;
  }

  function setFeeRate(uint _feeRate) public onlyAdmin{
    require(_feeRate > 0,"Value cannot be less then 1");
    feeRate = _feeRate;
  }

  function setCollateralPercentageThreshold(uint _maximumLockPercentage) public onlyAdmin{
    require(_maximumLockPercentage > 0,"Value cannot be less then 1");
    lockPercentageThreshold = _maximumLockPercentage;
  }  

  function setGraceTime(uint _timeInBlocks) public onlyAdmin{
    require(_timeInBlocks > 0,"Value cannot be less then 1");
    graceTime = _timeInBlocks;
  }  

  function setMaxLendingPeriod(uint _maxLendingPeriod) public onlyAdmin{
    require(_maxLendingPeriod > 0,"Value cannot be less then 1");
    maxLendingPeriod = _maxLendingPeriod;
  } 

  function addSupportedAsset(address veNFTAddress, address cheeTokenAddress,address iziTokenAddress)
   public onlyAdmin{
    require(veNFTAddress != address(0) && cheeTokenAddress != address(0) && iziTokenAddress != address(0),"Incorrect Input");
    supportedAddress1[veNFTAddress] = cheeTokenAddress;
    supportedAddress2[veNFTAddress] = iziTokenAddress;
  }  

  function changeDepositAddress(address _address) public onlyAdmin{
    require(_address != address(0),"Zero Address Detected");
    depositAddress = _address;
  }  

  function getInterestRatePerBlock() public view returns(uint){
    return interestRatePerBlock;
  }

  function getCollateralPercentageThreshold() public view returns(uint){
    return lockPercentageThreshold;
  }
    
  function getGraceTime() public view returns(uint){
    return graceTime;
  }

  function getFeeRate() public view returns(uint){
    return feeRate;
  } 
 
  function getMaxLendingPeriod() public view returns(uint){
    return maxLendingPeriod;
  }

  function getMaxTokenAmount(address _veNftAddress,uint _nftId) public view returns(uint){
    return IVeNft(_veNftAddress).getAmount(_nftId).mul(lockPercentageThreshold).div(100);
  }

  function getUsersCollateralToken(address _veNftAddress,uint _nftId) public view returns(uint){
    return userInfo[_veNftAddress][_nftId].amount;
  }

  function lend(address _veNftAddress,uint _nftId,uint _cheeTokenAmount) public{
    require(_veNftAddress != address(0) && _nftId > 0 && _cheeTokenAmount > 0,"Incorrect Input");
    require(IVeNft(_veNftAddress).ownerOf(_nftId) == msg.sender,"You are not the owner of Nft");
    require(_cheeTokenAmount <= IVeNft(_veNftAddress).getAmount(_nftId).mul(lockPercentageThreshold).div(100),"Value should be less then Max");
    value = _cheeTokenAmount;
    uint fee = (value.mul(feeRate)).div(100);
    IERC721(_veNftAddress).safeTransferFrom(msg.sender,address(this),_nftId);
    IChee(supportedAddress1[_veNftAddress]).mint(msg.sender,value);
    Iizi(supportedAddress2[_veNftAddress]).transferFrom(msg.sender,depositAddress,fee);
    userInfo[_veNftAddress][_nftId].lockPeriod = block.number;
    userInfo[_veNftAddress][_nftId].lender = msg.sender;
    userInfo[_veNftAddress][_nftId].amount = value;
    userInfo[_veNftAddress][_nftId].fee = fee;
  }


  function repay(address _veNftAddress,uint _cheeAmount,uint _nftId) public{
    require(_veNftAddress != address(0) && _cheeAmount > 0 && _nftId > 0,"Incorrect Input");
    require(IERC721(_veNftAddress).ownerOf(_nftId) == address(this),"Nft Id not detected in contract");
    require(userInfo[_veNftAddress][_nftId].lender == msg.sender,"You have not lender of this nft");
    uint lockPeriod = userInfo[_veNftAddress][_nftId].lockPeriod.add(maxLendingPeriod).add(graceTime);
    require(lockPeriod >= block.number,"Cannot repay Now");
    require(userInfo[_veNftAddress][_nftId].amount == _cheeAmount,"Enter Correct Amount");
    value = (IVeNft(_veNftAddress).getAmount(_nftId).
    mul(userInfo[_veNftAddress][_nftId].lockPercentage)).div(100);
    uint interest = (value.mul(block.number.sub(userInfo[_veNftAddress][_nftId].lockPeriod)).mul(interestRatePerBlock)).div(100);
    IChee(supportedAddress1[_veNftAddress]).burnFrom(msg.sender,_cheeAmount);
    Iizi(supportedAddress2[_veNftAddress]).transferFrom(msg.sender,depositAddress,interest);
    IVeNft(_veNftAddress).safeTransferFrom(address(this),msg.sender,_nftId);
  }

  function liquidate(address _veNftAddress,uint _cheeAmount,uint _nftId) public onlyPermissioned{
    require(_veNftAddress != address(0) && _cheeAmount > 0 && _nftId > 0,"Incorrect Input");
    uint lockPeriod = userInfo[_veNftAddress][_nftId].lockPeriod.add(maxLendingPeriod).add(graceTime);
    require(lockPeriod < block.number,"Cannot Liquidate Now");
    require(userInfo[_veNftAddress][_nftId].amount == _cheeAmount,"Enter Correct Amount");
    value = (IVeNft(_veNftAddress).getAmount(_nftId).
    mul(userInfo[_veNftAddress][_nftId].lockPercentage)).div(100);
    uint interest = (value.mul(block.number.
    sub(userInfo[_veNftAddress][_nftId].lockPeriod.add(graceTime))).mul(interestRatePerBlock)).div(100); 
    IChee(supportedAddress1[_veNftAddress]).burnFrom(msg.sender,_cheeAmount);
    Iizi(supportedAddress2[_veNftAddress]).transferFrom(msg.sender,depositAddress,interest);
    IVeNft(_veNftAddress).safeTransferFrom(address(this),msg.sender,_nftId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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