// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../token/ERC20/IERC20.sol";
import "../utils/math/SafeMath.sol";
import "../token/ERC721/IERC721.sol";
import "../interfaces/IWhiteList.sol";
import "../access/NFTSpaceXAccessControls.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Pausable.sol";

contract NFTSpaceXINO is ReentrancyGuard,Pausable {
    using SafeMath for uint256;
      NFTSpaceXAccessControls public accessControl;
        //========================================================//
        //======================-  Struct -=======================//
        //========================================================//
    struct PaymentInfo {
        address paymentToken;
        uint256 priceItem;
        uint256 receivableAmount;
    }

    struct INOInfo {

        uint32 limitItemPerUser;
        mapping(address => uint256[]) purchasedNft;

        uint32 startTime;
        uint32 endTime;
       
        address nftAddress;

        PaymentInfo[] paymentInfo;

        uint256[] tokenIds;
        uint256 total;

        address whitelistAddress;
    }
    bool private initAccess;
    INOInfo private Ino;
    address public adminINO;
    
    //========================================================//
    //======================-  Event -========================//
    //========================================================//
    event CreateSuccess (
        address  creator,
        address nftAddress,
        uint32 start,
        uint32 end
    );

    event DepositAndGetItemSuccess(
        address  customer,
        address  token,
        uint256 amount
    );

    event CancelSuccess(
        address  creator,
        uint256  time
    );
    event UpdateSuccess(
        address creator,
        uint256 time
    );

    event ClaimSuccess (
        address creator,
        uint256 time
    );
    event TransferAdmin(
        address admin,
        uint256 time
    );

    //===============================================================//
    //=========================- Modifer -==========================//
    //===============================================================//
    modifier onlyAdminINOorAdminFactory {
          require(adminINO==msg.sender || accessControl.hasAdminRole(msg.sender), "INO: Not admin role");
        _;
    }
    modifier isNotStart{
        require(block.timestamp < Ino.startTime,"INO: INO started");
        _;
    }
    modifier isExpired{
        require(block.timestamp > Ino.endTime,"INO: INO not expired");
        _;
    }
    //===============================================================//
    //=========================- Pausable -==========================//
    //===============================================================//
    function pauseIno() 
    public
    onlyAdminINOorAdminFactory
    {
        _pause();
    }
    function _unpauseIno() 
    public
    onlyAdminINOorAdminFactory
    {
        _unpause();
    }
    //===============================================================//
    //=========================- Init INO -==========================//
    //===============================================================//
    function initINO(address _admin,address _accessControl) external 
    {
        require(!initAccess, "IGO: Already initialised");
        adminINO=_admin;
        accessControl=NFTSpaceXAccessControls(_accessControl);
        initAccess=true;
    }
    //===============================================================//
    //====================- Validate INO info -======================//
    //===============================================================//
    function validateInoInfo(
        address _nftAddress,
        uint256[] memory _tokenIds,

        address[] memory _paymentTokens,
        uint256[] memory _priceItems,

        uint32 _start,
        uint32 _end
    )
    public
    view
    returns(bool)
    {
        return(
               (_start>=block.timestamp && _end > _start) &&
               (_nftAddress != address(0)) &&
               (_paymentTokens.length >0 && _priceItems.length >0) &&
               (_paymentTokens.length == _priceItems.length) &&
               (_tokenIds.length >0)
        );
    }

    //===============================================================//
    //=======================- Ino matched -=========================//
    //===============================================================//
    function inoMatched(
        address _account,
        uint256 _amount
    )
    public
    view
    returns(bool)
    {
        if((block.timestamp < Ino.startTime) || (block.timestamp > Ino.endTime)) return false;

        if(Ino.whitelistAddress==address(0))
        {
            return(
            (Ino.purchasedNft[msg.sender].length+ _amount <= Ino.limitItemPerUser));
        }
        else
        {
            require(_isWhilelist(_account),"INO: Not member");
            uint256 pointOfUser=IWhiteList(Ino.whitelistAddress).points(_account);
            return(
            (Ino.purchasedNft[msg.sender].length+ _amount <= pointOfUser));
        }
        
    }
    //===============================================================//
    //=========================- Create INO -========================//
    //===============================================================//
   function createINO(
        address _nftAddress,
        uint256[] memory _tokenIds,

        address[] memory _paymentTokens,
        uint256[] memory _priceItems,

        uint32 _limitItemPerUser,
        address _whitelistAddress,

        uint32 _start,
        uint32 _end

   )
    onlyAdminINOorAdminFactory
    public 
    { 
        require(validateInoInfo(_nftAddress, _tokenIds,_paymentTokens,_priceItems, _start, _end),"INO: invalid paramater");
        
        _addPayment(_paymentTokens, _priceItems);

        Ino.nftAddress=_nftAddress;
        Ino.tokenIds=_tokenIds;

        Ino.limitItemPerUser=_limitItemPerUser;
        Ino.whitelistAddress=_whitelistAddress;

        Ino.startTime=_start;
        Ino.endTime=_end;


        _transferListItem(_nftAddress, _tokenIds, msg.sender,address(this));

    emit CreateSuccess(msg.sender,_nftAddress,_start,_end);

   }


    //===============================================================//
    //=========================- Update INO -========================//
    //===============================================================//
    function updateINO(
    
        uint32 _limitItemPerUser,
        address _whitelistAddress,

        address[] memory _paymentTokens,
        uint256[] memory _priceItems,
        
        uint32 _start,
        uint32 _end
    )
    onlyAdminINOorAdminFactory
    isNotStart
    public
    {

        validateInoInfo(Ino.nftAddress, Ino.tokenIds, _paymentTokens, _priceItems, _start, _end);
        _clearPayment();
        _addPayment(_paymentTokens, _priceItems);
        Ino.limitItemPerUser= _limitItemPerUser;
        Ino.whitelistAddress=_whitelistAddress;
        Ino.startTime=_start;
        Ino.endTime=_end;

        emit UpdateSuccess(msg.sender,block.timestamp);
    }
    //===============================================================//
    //=========================-  Addition item -====================//
    //===============================================================//
    function addItem(
        uint256[] memory _tokenIds
    )
    onlyAdminINOorAdminFactory
    isNotStart
    public
    {
         for (uint256 i=0;i<_tokenIds.length;i++)
        {
            IERC721(Ino.nftAddress).transferFrom(msg.sender,address(this), _tokenIds[i]);
            Ino.tokenIds.push(_tokenIds[i]);
        }
    }
    //===============================================================//
    //=========================- Cancel INO -========================//
    //===============================================================//

    function cancelINO()
    public
    onlyAdminINOorAdminFactory
    isNotStart
    {
        _transferListItem(Ino.nftAddress, Ino.tokenIds,address(this),msg.sender);
        _resetINO();

        emit CancelSuccess(msg.sender,block.timestamp);
    }

    //===============================================================//
    //==================- Deposit and get item -=====================//
    //===============================================================//

    function depositAndGetItem(
        address _paymentToken,
        uint256 _amountItem
    )
    public
    payable
    whenNotPaused()
    {
        inoMatched(msg.sender,_amountItem);

        uint256 totalItem=Ino.tokenIds.length;
        require(totalItem >0,"INO: No nft left ");
        if(_amountItem > totalItem)
        {
            _amountItem=totalItem;
        }

        uint256 randNumber= _random();

        for(uint256 i=0 ; i< _amountItem;i++)
        {
            uint256 tokenIdIndex=randNumber % totalItem;
            uint256 tokenId = Ino.tokenIds[tokenIdIndex];
            _transferItem(msg.sender,tokenId);

            Ino.purchasedNft[msg.sender].push(tokenId);

            _removeNftId(tokenIdIndex);
            randNumber = uint256(keccak256(abi.encodePacked(randNumber, i)));
            totalItem--;

        } 

        uint indexOfPaymentToken= _findIndexFromTokenAddress(_paymentToken);
        uint256 totalPayment = (Ino.paymentInfo[indexOfPaymentToken].priceItem).mul(_amountItem);
        if(_paymentToken==address(0))
        {
            require(msg.value>=totalPayment,"INO: not enough ETH");
            uint256 amountRefund=msg.value.sub(totalPayment);
            if(amountRefund>0) payable(msg.sender).transfer(amountRefund);
        }
        else
        {
            _transferToken(_paymentToken,msg.sender,address(this),totalPayment);
        }
        Ino.paymentInfo[indexOfPaymentToken].receivableAmount +=totalPayment;

        emit DepositAndGetItemSuccess(msg.sender,_paymentToken,_amountItem);
    }

    //===============================================================//
    //======================- Claim and Withdaw -====================//
    //===============================================================//

    function claimPaymentAndWithdrawItem(

    )
    public
    nonReentrant()
    onlyAdminINOorAdminFactory
    isExpired
    {
        uint256 totalRemaining =Ino.tokenIds.length;
        if(totalRemaining != 0)
        {
            for(uint256 i =0 ; i< Ino.tokenIds.length;i++)
            {
                _transferItem(msg.sender, Ino.tokenIds[i]);
            }
        }

        for(uint256 i=0; i < Ino.paymentInfo.length;i++)
        {
            address tokenAddress= Ino.paymentInfo[i].paymentToken;
            uint256 receivableAmount=Ino.paymentInfo[i].receivableAmount;

            if(receivableAmount==0) continue;

            if (tokenAddress==address(0))
            {
                payable(msg.sender).transfer(receivableAmount);
            }
            else
            {
                _transferToken(tokenAddress,address(this),msg.sender, receivableAmount);
            }
        }
        _resetINO();
        emit ClaimSuccess(msg.sender,block.timestamp);
    }

    //===============================================================//
    //=========================- Get INO info -======================//
    //===============================================================//
    function getINOInfo()
    public
    view
    returns
    (
        address nftAddress,
        uint32 limitItemPerUser,
        PaymentInfo[] memory payments,
        uint256[] memory tokenIds,
        uint256 start,
        uint256 end
    )
    {
        nftAddress=Ino.nftAddress;
        limitItemPerUser=Ino.limitItemPerUser;
        payments= Ino.paymentInfo;
        tokenIds=Ino.tokenIds;
        start= Ino.startTime;
        end=Ino.endTime;
    }
    //===============================================================//
    //===================- Transfer admin INO -======================//
    //===============================================================//
    function transferAdmin(address newAdmin)
    public
    onlyAdminINOorAdminFactory
    {
        require(newAdmin != address(0),"INO: not address zero");
        adminINO=newAdmin;
        emit TransferAdmin(newAdmin,block.timestamp);
    }
    //===============================================================//
    //=========================- Transfer token -====================//
    //===============================================================//
    function _transferToken(
        address _tokenAddres,
        address _from,
        address _to,
        uint256 _amount
    )
    internal
    {
        IERC20(_tokenAddres).transferFrom(_from,_to,_amount);
    }
    //===============================================================//
    //=========================- Transfer item -=====================//
    //===============================================================//
    function _transferListItem(
        address _nftAddress,
        uint256[] memory _tokenIds,
        address _from,
        address _to) 
    internal
    {
         for (uint256 i=0;i<_tokenIds.length;i++)
        {
            IERC721(_nftAddress).transferFrom(_from,_to, _tokenIds[i]);
        }
    }

    function _transferItem(
         address _to,
        uint256 _tokenId)
    internal
    {
            IERC721(Ino.nftAddress).transferFrom(address(this),_to, _tokenId);
    }
    //===============================================================//
    //==============- Add and clear payment info -===================//
    //===============================================================//
    function  _addPayment(
        address[] memory _paymentTokens,
        uint256[] memory _priceItems)
        internal 
        {
            for (uint256 i = 0; i < _paymentTokens.length; i++) {
            PaymentInfo memory payment = PaymentInfo(_paymentTokens[i], _priceItems[i], 0);
            Ino.paymentInfo.push(payment);
        }
    }

    function  _clearPayment()
        internal 
        {
            for(uint256 i=0; i<Ino.paymentInfo.length;i++)
            {
                delete Ino.paymentInfo[i];
            }
        }
    

    //===============================================================//
    //====================- Check whitelist -=======================//
    //==============================================================//
    function _isWhilelist(
        address _account)
        internal
        view
        returns(bool)
        {
            return IWhiteList(Ino.whitelistAddress).isInList(_account);
        }
    //===============================================================//
    //=========================- Randoom -==========================//
    //==============================================================//
    function _random() 
    internal 
    view 
    returns (uint256) 
    {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender,  block.coinbase))); //block.coinbase address miner
        return randomNumber;
    }
    //===============================================================//
    //=========================- Remove nft -=======================//
    //==============================================================//

    function _removeNftId(uint256 _tokenIdIndex) 
    private 
    {
        uint256 lastTokenIndex = Ino.tokenIds.length - 1;
        
        if (_tokenIdIndex != lastTokenIndex) {
            uint256 lastTokenId = Ino.tokenIds[lastTokenIndex];
            Ino.tokenIds[_tokenIdIndex] = lastTokenId;
        }
        Ino.tokenIds.pop();
    }

    //===============================================================//
    //============- Find index from token address -==================//
    //===============================================================//
    function _findIndexFromTokenAddress(address _paymentToken)
    internal
    view
    returns(uint256 index)
    {
        bool findOut;
        for(index=0; index< Ino.paymentInfo.length ; index++)
        {
            if(Ino.paymentInfo[index].paymentToken == _paymentToken)
            {
                findOut=true;
                return index;
            } 
        } 
        require(findOut,"INO: not find address tokeen");
    }
    //===============================================================//
    //===========================- Reset INO -=======================//
    //===============================================================// 
    function _resetINO()
    private
    {
        _clearPayment();
        Ino.nftAddress=address(0);
        Ino.tokenIds=new uint256[](0);
        Ino.limitItemPerUser=0;
        Ino.whitelistAddress=address(0);
        Ino.startTime=0;
        Ino.endTime=0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

interface IWhiteList {
  function points(address account) external view returns (uint256);
  function isInList(address account) external view returns (bool);
  function hasPoints(address account, uint256 amount) external view returns (bool);
  function setPoints(address[] memory accounts, uint256[] memory amounts) external;
  function initWhiteList(address accessControl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTSpaceXAdminAccess.sol";

contract NFTSpaceXAccessControls is NFTSpaceXAdminAccess {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event MinterRoleGranted(address indexed beneficiary, address indexed caller);
  event MinterRoleRemoved(address indexed beneficiary, address indexed caller);
  event OperatorRoleGranted(address indexed beneficiary, address indexed caller);
  event OperatorRoleRemoved(address indexed beneficiary, address indexed caller);
  event SmartContractRoleGranted(address indexed beneficiary, address indexed caller);
  event SmartContractRoleRemoved(address indexed beneficiary, address indexed caller);

  function hasMinterRole(address _address) public view returns (bool) {
    return hasRole(MINTER_ROLE, _address);
  }

  function hasSmartContractRole(address _address) public view returns (bool) {
    return hasRole(SMART_CONTRACT_ROLE, _address);
  }

  function hasOperatorRole(address _address) public view returns (bool) {
    return hasRole(OPERATOR_ROLE, _address);
  }

  function addMinterRole(address _beneficiary) external {
    grantRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeMinterRole(address _beneficiary) external {
    revokeRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleRemoved(_beneficiary, _msgSender());
  }

  function addSmartContractRole(address _beneficiary) external {
    grantRole(SMART_CONTRACT_ROLE, _beneficiary);
    emit SmartContractRoleGranted(_beneficiary, _msgSender());
  }

  function addOperatorRole(address _beneficiary) external {
    grantRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleGranted(_beneficiary, _msgSender());
  }

  function removeOperatorRole(address _beneficiary) external {
    revokeRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Pausable is Context {
  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  constructor() {
    _paused = false;
  }

  /**
   * @dev Return true if the contract is paused, and false otherwise
   */
  function paused() public virtual returns (bool) {
    return _paused;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Return to normal state
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract NFTSpaceXAdminAccess is AccessControl {
  bool private initAccess;

  event AdminRoleGranted(address indexed beneficiary, address indexed caller);
  event AdminRoleRemoved(address indexed beneficiary, address indexed caller);

  function initAccessControls(address _admin) public {
    require(!initAccess, "NSA: Already initialised");
    require(_admin != address(0), "NSA: zero address");
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    initAccess = true;
  }

  function hasAdminRole(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function addAdminRole(address _beneficiary) external {
    grantRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleGranted(_beneficiary, _msgSender());
  }

  function removeAdminRole(address _beneficiary) external {
    revokeRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../utils/introspection/ERC165.sol";
import "../interfaces/IAccessControl.sol";

abstract contract AccessControl is Context, IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members.contains(account);
  }

  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
    return _roles[role].members.at(index);
  }

  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AC: must renounce yourself");
    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
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

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
    * @dev Returns the number of values on the set. O(1).
    */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
    * @dev Returns the number of values in the set. O(1).
    */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Returns the number of values in the set. O(1).
    */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(AddressSet storage set, uint256 index) internal view returns (address) {
      return address(uint160(uint256(_at(set._inner, index))));
  }


  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
    * @dev Returns the number of values on the set. O(1).
    */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: MIT

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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