// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DBSNFTTechnology.sol";

contract DBSNFTCast  is Ownable{
    using SafeMath for uint256;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    IERC20 internal token;
    DBSNFTTechnology techAddress;
    // tokens holder address
    address private pveAddress;
    DBSNFTTokens nftAddress;
    bool castOpen;
    uint256 constant NFTSilver = 2;
    uint256 price; 
    mapping(address => uint256) internal CastShip;

    event newCast(address _caster, uint256 _tokenId, uint256 _tableId);

    constructor(address _dbsnft, IERC20 _erc20, address _techAddress, address _pveAddress){
        nftAddress = DBSNFTTokens(_dbsnft);
        //nftAddress.addMinter(address(this));
        token = _erc20;
        techAddress = DBSNFTTechnology(_techAddress);
        pveAddress = _pveAddress;
        castOpen = true;
        price = 110*(10**uint256(18));
    }

    /**
     * @return true if the Cast is open, false otherwise.
     */
    function isCastOpen() public view returns (bool) {
        return castOpen;
    }

    function Cast() public  returns (bool){
        require(castOpen, "DBSNFTTechnology: Cast open error");
        if(CastShip[msg.sender] == 0){
            // Transfer the token
            token.safeTransferFrom(msg.sender, pveAddress, price);
            CastShip[msg.sender] = block.timestamp;
            return true;
        }
        return false;
    }

    function CloseCast() public onlyOwner  {
        require(castOpen, "DBSNFTTechnology: CloseCast error");
        castOpen = false;
    }

    function IsCastClosed() public view returns (bool){
        return castOpen;
    }

    function GetCast() public  returns (uint256, uint256){
        uint256 oldTime = CastShip[msg.sender];
        require(oldTime <= 0, "DBSNFTTechnology: GetCast oldTime error");
        // Transfer the token
        if(oldTime.add(7*24*3600) >= block.timestamp){
            uint256 tableid = techAddress.GetRandomShip(NFTSilver);
            uint256 tokenId = nftAddress.mint(msg.sender, tableid);
            CastShip[msg.sender] = 0;
            emit newCast(msg.sender, tokenId, tableid);
            return (tokenId, tableid);
        }
        return (uint256(0), uint256(0));
    }

    function GetCastTime() public view returns (uint256){
        return CastShip[msg.sender];
    }

    function SetCastPrice(uint256 _price) public{
        require(_price > 0);
        price = _price;
    }

    function GetCastPrice() public view returns (uint256){
        return price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DBSNFTTokens.sol";

contract DBSNFTTechnology  is Ownable{
    using SafeMath for uint256;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    enum NFTQuality { NFTInvalid, NFTCopper, NFTSilver, NFTGold }
    constructor(address _dbsnft, IERC20 _erc20, address _pveAddress){
        nftAddress = DBSNFTTokens(_dbsnft);
        //nftAddress.addMinter(address(this));
        token = _erc20;
        pveAddress = _pveAddress;
        seed = 13884;
    }

    struct Ship {
        uint256 id;
        uint256 camp;
        uint256 skill;
    }

    IERC20 internal token;
    DBSNFTTokens nftAddress;
    // tokens holder address
    address private pveAddress;

    Ship[] copperShip;
    Ship[] silverShip;
    Ship[] goldShip;

    uint256[] copperSkill;
    uint256[] silverSkill;
    uint256[] goldSkill;

    uint256 seed;
    mapping(uint256 => uint256) internal NftToQuality;
    mapping(uint256 => uint256) internal IDToIndex;
    address randCaller;
    // event
    event newRecast(address _caster, uint256[] _ids, uint256 _tokenId, uint256 _id);
    event newRecruitCopper(address _operator, uint256 _id, uint256 _tokenId, uint256 _destid);
    event newRecruitDest(address _operator, uint256[] _ids, uint256 _tokenId, uint256 _destid);
    event newDecompose(address _operator, uint256 _id,  uint256[] _tokens, uint256[] _destcids);

    function GetRandomShip(uint256 _quality) public  returns (uint256){
        require(randCaller != address(0) && msg.sender == randCaller, "DBSNFTTechnology: GetRandomShip address");
        uint256 index = _pickShipRandomClass(_quality);
        if(_quality == uint256(NFTQuality.NFTCopper)){
            return copperShip[index].id;
        }else if(_quality == uint256(NFTQuality.NFTSilver)){
            return silverShip[index].id;
        }
        return goldShip[index].id;
    }

    function SetRandCaller(address _caller) public onlyOwner{
        randCaller = _caller;
    }

    function Recast(uint256[] memory _ids) public  returns (uint256, uint256){
        require(_ids.length == 5, "DBSNFTTechnology: Recast _ids length error");
        uint256 mainId = nftAddress.getPropertyID(_ids[0]);
        uint256 quality = NftToQuality[mainId];
        require(quality > uint256(NFTQuality.NFTInvalid) && quality < uint256(NFTQuality.NFTGold), "DBSNFTTechnology: Recast quality error");

        if(quality == uint256(NFTQuality.NFTCopper)){
            uint256 camp = copperShip[IDToIndex[mainId]].camp;
            for (uint256 i = 1; i < _ids.length; i++) {
                uint256 tableId = nftAddress.getPropertyID(_ids[i]);
                require(quality == NftToQuality[tableId], "DBSNFTTechnology: NFTCopper quality error");
                require(camp == copperShip[IDToIndex[tableId]].camp, "DBSNFTTechnology: NFTCopper camp error");
            }
            require(IDToIndex[mainId] < copperShip.length);
            uint256[] memory cids;
            uint256 count;
            (cids, count) = GetSameShipCamp(camp, uint256(NFTQuality.NFTSilver));
            require(count > 0, "DBSNFTTechnology: NFTCopper count error");
            nftAddress.burnBatch(msg.sender, _ids);
            uint256 cindex = uint256(_random()).mod(count - 1);
            uint256 tokenId = nftAddress.mint(msg.sender, cids[cindex]);

            emit newRecast(msg.sender, _ids, tokenId, cids[cindex]);
            return (tokenId, cids[cindex]);
        }else if(quality == uint256(NFTQuality.NFTSilver)){
            uint256 camp = silverShip[IDToIndex[mainId]].camp;
            for (uint256 i = 1; i < _ids.length; i++) {
                uint256 tableId = nftAddress.getPropertyID(_ids[i]);
                require(quality == NftToQuality[tableId], "DBSNFTTechnology: NFTSilver quality error");
                require(camp == silverShip[IDToIndex[tableId]].camp, "DBSNFTTechnology: NFTSilver camp error");
            }
            require(IDToIndex[mainId] < silverShip.length, "DBSNFTTechnology: NFTSilver silverShip error");
            
            uint256[] memory sids;
            uint256 count;
            (sids, count) = GetSameShipCamp(camp, uint256(NFTQuality.NFTGold));
            require(count > 0, "DBSNFTTechnology: NFTSilver count error");
            nftAddress.burnBatch(msg.sender, _ids);
            uint256 sindex = uint256(_random()).mod(count - 1);
            uint256 tokenId = nftAddress.mint(msg.sender, sids[sindex]);

            emit newRecast(msg.sender, _ids, tokenId, sids[sindex]);
            return (tokenId, sids[sindex]);
        }
        return (uint256(0), uint256(0));
    }

    function GetSameShipCamp(uint256 _camp, uint256 _quality) public view returns (uint256[] memory ids, uint256 count){
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: GetSameShipCamp _quality error");
        require(_camp > 0, "DBSNFTTechnology: GetSameShipCamp _camp error");
        if(_quality == uint256(NFTQuality.NFTCopper)){
            uint256 coppercount = 0;
            uint256[] memory copperids = new uint256[](copperShip.length);
            for (uint256 i = 0; i < copperShip.length; i++) {
                if(copperShip[i].camp == _camp){
                    copperids[coppercount] = copperShip[i].id;
                    coppercount = coppercount.add(1);
                }
            }
            return (copperids, coppercount);
        }else if(_quality == uint256(NFTQuality.NFTSilver)){
            uint256 silvercount = 0;
            uint256[] memory silverids = new uint256[](silverShip.length);
            for (uint256 i = 0; i < silverShip.length; i++) {
                if(silverShip[i].camp == _camp){
                    silverids[silvercount] = silverShip[i].id;
                    silvercount = silvercount.add(1);
                }
            }
            return (silverids, silvercount);
        }else if(_quality == uint256(NFTQuality.NFTGold)){
            uint256 goldcount = 0;
            uint256[] memory goldids = new uint256[](goldShip.length);
            for (uint256 i = 0; i < goldShip.length; i++) {
                if(goldShip[i].camp == _camp){
                    goldids[goldcount] = goldShip[i].id;
                    goldcount = goldcount.add(1);
                }
            }
            return (goldids, goldcount);
        }
    }

    function GetSameSkills(uint256 _quality) public view returns (uint256[] memory ids, uint256 count){
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: GetSameSkills _quality error");
        
        if(_quality == uint256(NFTQuality.NFTCopper)){
            return (copperSkill, copperSkill.length);
        }else if(_quality == uint256(NFTQuality.NFTSilver)){
            return (silverSkill, silverSkill.length);
        }else if(_quality == uint256(NFTQuality.NFTGold)){
            return (goldSkill, goldSkill.length);
        }
    }

    function GetQuality(uint256 _id) public view returns (uint256 quality){
        return NftToQuality[_id];
    }

    function RecruitCopper(uint256 _id) public returns (uint256, uint256){
        uint256 tableId = nftAddress.getPropertyID(_id);
        uint256 quality = NftToQuality[tableId];
        require(quality == uint256(NFTQuality.NFTCopper), "DBSNFTTechnology: RecruitCopper _quality error");
        
        nftAddress.burn(msg.sender, _id);
        uint256 index = _pickSkillRandomClass(quality);
        uint256 tokenId = nftAddress.mint(msg.sender, copperSkill[index]);

        emit newRecruitCopper(msg.sender, _id, tokenId, copperSkill[index]);
        return (tokenId, copperSkill[index]); 
    }

    function RecruitDest(uint256[] memory _ids) public returns (uint256, uint256){
        require(_ids.length == 4, "DBSNFTTechnology: RecruitDest ids error");
        uint256 tableId = nftAddress.getPropertyID(_ids[0]);
        uint256 quality = NftToQuality[tableId];
        require(quality > uint256(NFTQuality.NFTInvalid) && quality < uint256(NFTQuality.NFTGold), "DBSNFTTechnology: RecruitDest quality error");
        for (uint256 i = 0; i < _ids.length; i++) {
            tableId = nftAddress.getPropertyID(_ids[i]);
            require(quality == NftToQuality[tableId]);
        }

        if(quality == uint256(NFTQuality.NFTCopper)){
            nftAddress.burnBatch(msg.sender, _ids);
            uint256 tokenId = nftAddress.mint(msg.sender, copperShip[IDToIndex[tableId]].skill);

            emit newRecruitDest(msg.sender, _ids, tokenId, copperShip[IDToIndex[tableId]].skill);
            return (tokenId, copperShip[IDToIndex[tableId]].skill); 
        }else if(quality == uint256(NFTQuality.NFTSilver)){
            nftAddress.burnBatch(msg.sender, _ids);
            uint256 tokenId = nftAddress.mint(msg.sender, silverShip[IDToIndex[tableId]].skill);

            emit newRecruitDest(msg.sender, _ids, tokenId, copperShip[IDToIndex[tableId]].skill);
            return (tokenId, copperShip[IDToIndex[tableId]].skill); 
        }
        return (uint256(0),uint256(0));
    }

    function Decompose(uint256 _id) public  returns (uint256[] memory, uint256[] memory){
        uint256 tableId = nftAddress.getPropertyID(_id);
        uint256 quality = NftToQuality[tableId];
        require(quality > uint256(NFTQuality.NFTCopper) && quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: Decompose quality error");
        if(quality == uint256(NFTQuality.NFTSilver)){
            nftAddress.burn(msg.sender, _id);

            uint256[] memory cids;
            uint256 count;
            (cids, count) = GetSameShipCamp(copperShip[IDToIndex[tableId]].camp, uint256(NFTQuality.NFTCopper));
            require(count > 0, "DBSNFTTechnology: Decompose NFTSilver count error");
            uint256[] memory destcids = new uint256[](3);
            for(uint256 i=0; i<3; i++){
                uint256 index = uint256(_random()).mod(count - 1);
                destcids[i] = cids[index];
            }
            (uint256[] memory tokens, uint256[] memory tableIds) = nftAddress.batchMint(msg.sender, destcids);
            emit newDecompose(msg.sender, _id, tokens, destcids);
            return (tokens, tableIds); 
        }else{
            nftAddress.burn(msg.sender, _id);

            uint256[] memory cids;
            uint256 count;
            (cids, count) = GetSameShipCamp(copperShip[IDToIndex[tableId]].camp, uint256(NFTQuality.NFTSilver));
            require(count > 0, "DBSNFTTechnology: Decompose NFTGold count error");
            uint256[] memory destcids = new uint256[](3);
            for(uint256 i=0; i<3; i++){
                uint256 index = uint256(_random()).mod(count - 1);
                destcids[i] = cids[index];
            }
            (uint256[] memory tokens, uint256[] memory tableIds) = nftAddress.batchMint(msg.sender, destcids);
            emit newDecompose(msg.sender, _id, tokens, destcids);
            return (tokens, tableIds);  
        }
    }

    function _pickShipRandomClass(uint256 _quality) internal returns (uint256) {
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: _pickShipRandomClass quality error");

        if(_quality == uint256(NFTQuality.NFTCopper)){
            uint256 cindex = uint256(_random()).mod(copperShip.length - 1);
            return cindex;
        }else if(_quality == uint256(NFTQuality.NFTSilver)){
            uint256 sindex = uint256(_random()).mod(silverShip.length - 1);
            return sindex;
        }
        uint256 index = uint256(_random()).mod(goldShip.length - 1);
        return index;
    }

    function _pickSkillRandomClass(uint256 _quality) internal returns (uint256) {
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: _pickSkillRandomClass quality error");

        if(_quality == uint256(NFTQuality.NFTCopper)){
            uint256 cindex = uint256(_random()).mod(copperSkill.length - 1);
            return cindex;
        }else if(_quality == uint256(NFTQuality.NFTSilver)){
            uint256 sindex = uint256(_random()).mod(silverSkill.length - 1);
            return sindex;
        }
        uint256 index = uint256(_random()).mod(goldSkill.length - 1);
        return index;
    }


    function AddShips(uint256 _quality, uint256[] memory _camp, uint256[] memory _ids, uint256[] memory _skills) public onlyOwner{
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: AddShips quality error");
        require(_camp.length == _ids.length);
        require(_camp.length == _skills.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] > 0);
            require(NftToQuality[_ids[i]] <= 0);
            Ship memory s = Ship({
                id: _ids[i],
                camp: _camp[i],
                skill: _skills[i]
            });
            
            if(_quality == uint256(NFTQuality.NFTCopper)){
                IDToIndex[_ids[i]] = copperShip.length;
                copperShip.push(s);
                NftToQuality[_ids[i]] = _quality;
            }else if(_quality == uint256(NFTQuality.NFTSilver)){
                IDToIndex[_ids[i]] = silverShip.length;
                silverShip.push(s);
                NftToQuality[_ids[i]] = _quality;
            }else if(_quality == uint256(NFTQuality.NFTGold)){
                IDToIndex[_ids[i]] = goldShip.length;
                goldShip.push(s);
                NftToQuality[_ids[i]] = _quality;
            }
        }
    }

    function AddSkills(uint256 _quality, uint256[] memory _ids) public onlyOwner{
        require(_quality > uint256(NFTQuality.NFTInvalid) && _quality <= uint256(NFTQuality.NFTGold), "DBSNFTTechnology: AddSkills quality error");
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] > 0);
            require(NftToQuality[_ids[i]] <= 0);
            if(_quality == uint256(NFTQuality.NFTCopper)){
                IDToIndex[_ids[i]] = copperSkill.length;
                copperSkill.push(_ids[i]);
                NftToQuality[_ids[i]] = _quality;
            }else if(_quality == uint256(NFTQuality.NFTSilver)){
                IDToIndex[_ids[i]] = silverSkill.length;
                silverSkill.push(_ids[i]);
                NftToQuality[_ids[i]] = _quality;
            }else if(_quality == uint256(NFTQuality.NFTGold)){
                IDToIndex[_ids[i]] = goldSkill.length;
                goldSkill.push(_ids[i]);
                NftToQuality[_ids[i]] = _quality;
            }
        }
    }

    /**
    * @dev Pseudo-random number generator
    * NOTE: to improve randomness, generate it with an oracle
    */
    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed)));
        seed = randomNumber;
        return randomNumber;
    }

    function setSeed(
        uint256 _newSeed
    ) public onlyOwner{
        seed = _newSeed;
    }

    function modifypve(address _pve) public onlyOwner(){
        require(_pve != address(0), "DBSNFTTechnology: modify _pve for the zero address");
        pveAddress = _pve;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721Tradable.sol";

contract DBSNFTTokens is ERC721Tradable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct DBSNFT {
        uint256 id;
        string name;
        string image;
        string description;
        string attributes;
    }
    uint256 constant UINT256_MAX = ~uint256(0);
    //tableid to property
    mapping(uint256 => DBSNFT) public tokenProperty;

    constructor(
    ) ERC721Tradable(
            "Deep Blue Sea NFT",
            "DBSNFT"
        ) {
    }

    function initProperty(uint[] memory _ids, string[] memory _name, string[] memory _images, string[] memory _des, string[] memory _attributes) public onlyOwner {
        require(_ids.length == _name.length);
        require(_ids.length == _images.length);
        require(_ids.length == _des.length);
        require(_ids.length == _attributes.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] > 0 && bytes(_images[i]).length > 0, "initProperty _id or _image failed");
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            DBSNFT memory s = DBSNFT({
                id: _ids[i],
                name: _name[i],
                image: _images[i],
                description: _des[i],
                attributes: _attributes[i]
            });
            tokenProperty[_ids[i]] = s;
        }
    }

    function updateProperty(uint _id, string memory _name, string memory _image, string memory _des, string memory _attribute) public onlyOwner {
        require(tokenProperty[_id].id > 0, "updateProperty _id invalid");

        tokenProperty[_id].name = _name;
        tokenProperty[_id].image = _image;
        tokenProperty[_id].description = _des;
        tokenProperty[_id].attributes = _attribute;
    }

    function getPropertyID(uint256 _tokenid) public view returns(uint256){
        require(tokens[_tokenid] > 0, "getPropertyID _tokenid invalid");
        return tokenProperty[tokens[_tokenid]].id;
    }

    function tokenName(uint256 _tokenId) public view returns(string memory){
        require(tokens[_tokenId] > 0);

        return tokenProperty[tokens[_tokenId]].name;
    }

    function tokenImage(uint256 _tokenId) public view returns(string memory){
        require(tokens[_tokenId] > 0);

        return tokenProperty[tokens[_tokenId]].image;
    }

    function tokenDescription(uint256 _tokenId) public view returns(string memory){
        require(tokens[_tokenId] > 0);

        return tokenProperty[tokens[_tokenId]].description;
    }

    function tokenAttributes(uint256 _tokenId) public view returns(string memory){
        require(tokens[_tokenId] > 0);

        return tokenProperty[tokens[_tokenId]].attributes;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = string(abi.encodePacked("{ \"name\":" , tokenProperty[tokens[_tokenId]].name, "\"image\":", tokenProperty[tokens[_tokenId]].image, "\"description\":", tokenProperty[tokens[_tokenId]].description, "\"attributes\":", tokenProperty[tokens[_tokenId]].attributes,"}"));
        return json;
    }
    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` is valid.
     */
    function balanceOfAccount(address _account)
        public
        view
        returns (uint256, uint256[] memory, uint256[] memory)
    {
        require(_account != address(0), "balanceOfAccount: _account zero");
        uint256 amount = balanceOf(_account);
        uint256[] memory list = new uint256[](amount);
        uint256[] memory tableids = new uint256[](amount);
        if(amount > 0){
            uint256 _currentID = currentID();
            uint256 index = 0;
            for (uint256 i = 1; i < _currentID; ++i) {
                if(exists(i)){
                    if(ownerOf(i) == _account){
                        list[index] = i;
                        tableids[index] = tokens[i];
                        index++;
                        if(index >= amount){
                            break;
                        }
                    }
                }
            }
        }
        
        return (amount, list, tableids);
    }

    function totalSupply() public pure returns (uint256){
        return UINT256_MAX;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Burnable, AccessControl, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private baseuri;
    //
    mapping (uint256 => string) customUri;
    //tokenid to tableid
    mapping(uint256 => uint256) public tokens;
    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event URI(string value, uint256 indexed id);
    
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _nextTokenId.increment();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _setURI(string memory _newuri) internal virtual {
        baseuri = _newuri;
    }

    function currentID() public view returns (uint256){
        return _nextTokenId.current();
    }

    function exists(uint256 _tokenId) public view virtual returns (bool) {
        return _exists(_tokenId);
    }
    /**
    * @dev Sets a new URI for all token types, by relying on the token type ID
        * substitution mechanism
        * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
    * @param _newURI New URI for all tokens
    */
    function setURI(
        string memory _newURI
    ) public onlyOwner {
        _setURI(_newURI);
    }

    /**
    * @dev Will update the base URI for the token
    * @param _tokenId The token to update. _msgSender() must be its creator.
    * @param _newURI New URI for the token.
    */
    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public onlyOwner {
        customUri[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE,_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Restricted to admins.");
        _;
    }

    function addMinter(address account) public  {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinter() public {
        revokeRole(MINTER_ROLE, _msgSender());
    }

    function burn(
        address _account,
        uint256 _id
    ) public virtual {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "ERC721: caller is not owner nor approved"
        );
        delete tokens[_id];
        _burn(_id);
    }

    function burnBatch(
        address _account,
        uint256[] memory _ids
    ) public virtual {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "ERC721: caller is not owner nor approved"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
             _burn(_id);
        }
    }
    
    /**
        * @dev Mints some amount of tokens to an address
        * @param _to          Address of the future owner of the token
        * @param _id          Token ID to mint
        */
    function mint(
        address _to,
        uint256 _id
    ) virtual public onlyRole(MINTER_ROLE) returns(uint256){
        require(_id > 0, "mint _id error");
        uint256 currentTokenId = _nextTokenId.current();
        
        _mint(_to, currentTokenId);
        tokens[currentTokenId] = _id;
        _nextTokenId.increment();
        
        return currentTokenId;
    }

    /**
        * @dev Mint tokens for each id in _ids
        * @param _to          The address to mint tokens to
        * @param _tableIds         Array of ids to mint
        */
    function batchMint(
        address _to,
        uint256[] memory _tableIds
    ) public onlyRole(MINTER_ROLE) returns(uint256[] memory, uint256[] memory){
        uint256 counts = 0;
        uint256[] memory alltokens = new uint256[](_tableIds.length);
        uint256[] memory allids = new uint256[](_tableIds.length);
        for (uint256 i = 0; i < _tableIds.length; i++) {
            uint256 got = mint(_to, _tableIds[i]);
            alltokens[counts] = got;
            allids[counts] = _tableIds[i];
            counts++;
        }
        return (alltokens, allids);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}