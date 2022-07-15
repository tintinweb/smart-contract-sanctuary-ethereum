// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../utils/math/SafeMath.sol";
import "../token/ERC721/IERC721.sol";
import "../interfaces/INFTSpaceXTicketCard.sol";
import "../access/NFTSpaceXAccessControls.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Pausable.sol";
import "../utils/Context.sol";
import "../utils/SafeTransfer.sol";
import "../token/ERC1155/IERC1155.sol";
import "../utils/libraries/EnumerableSet.sol";
contract INO721 is  Context, SafeTransfer, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Payment {
        address paymentToken;
        uint256 priceItem;
    }

    struct Status {
        uint256 numParticipants;
        uint256[] tokenIds;
        mapping(address => EnumerableSet.UintSet) purchasedNft;
        bool finalized;
    }

    struct Info {
        address nftAddress;
        uint256 startTime;
        uint256 endTime;
        uint256 floorPoint;
        uint32 limitItemPerUser;
    }

    INFTSpaceXTicketCard public nftspacexTicketCard;
    NFTSpaceXAccessControls public nftspacexAccessControls;

    uint256 private constant TEMPLATE_ID = 1;
    address private stakingPool;
    bool private initialized;
    Payment[] private inoPayments;
    Info private inoInfo;
    Status private inoStatus;
    address private adminIno;

    event Created(address creator, address nftAddress, uint256 start, uint256 end);
    event Deposit(address customer, address token, uint256 amount);
    event Canceled(address creator, uint256 time);
    event Updated(address creator, uint256 time);
    event Claim(address customer, uint256 time);
    event Finalized (address creator, uint256 time);
    event WithdrawTokenFailed(address creator, address token, uint256 amount);
    event WithdrawNFTFailed(address crestor, address nftAddress, uint256 tokenId);

    modifier onlyAdminINO {
        require(adminIno == _msgSender(), "INO: only INO admin");
        _;
    }

    modifier onlyAdminFactory {
          require(nftspacexAccessControls.hasAdminRole(_msgSender()), "INO: only factory admin");
        _;
    }

    function isNotStart() public view returns(bool) {
        return block.timestamp < inoInfo.startTime;
    }

    function isINOExpired() public view returns (bool) {
        return inoStatus.finalized;
    }

    function isINOOngoing() public view returns (bool) {
        return (
            (block.timestamp >= inoInfo.startTime) &&
            (block.timestamp < inoInfo.endTime)
        );
    }

    function factorySchemaName() public pure returns (string memory) {
        return "ERC721";
    }

    function inoTemplate() public pure returns (uint256) {
        return TEMPLATE_ID;
    }

    function pauseIno() public onlyAdminFactory {
        _pause();
    }

    function unPauseIno() public onlyAdminFactory {
        _unpause();
    }

    function initIno(
        address _admin,
        address _nftspacexAccessControls,
        address _nftspacexTicketCard,
        address _stakingPool
    ) external {
        require(!initialized, "INO: Already initialised");
        adminIno = _admin;
        nftspacexAccessControls = NFTSpaceXAccessControls(_nftspacexAccessControls);
        nftspacexTicketCard = INFTSpaceXTicketCard(_nftspacexTicketCard);
        stakingPool = _stakingPool;
        initialized = true;
        _pause();
    }

    function canJoinINO(address account, uint256 amount) public view returns (bool) {
        require(isINOOngoing(),"INO: expired");
        require(amount > 0, "INO: amount equal zero");

        uint256 amountAllowed = inoStatus.purchasedNft[_msgSender()].length() + amount;
        if (address(nftspacexTicketCard) == address(0)) {
            return(amountAllowed <= inoInfo.limitItemPerUser);
        } else {
            uint256 idCard = nftspacexTicketCard.currentIdSupported();
            require(!nftspacexTicketCard.isIdExpired(idCard), "INO: card not expired");
            uint256 pointOfUser = nftspacexTicketCard.balanceOf(account, idCard);
            return(
                (amountAllowed <= inoInfo.limitItemPerUser) &&
                (amountAllowed * inoInfo.floorPoint <= pointOfUser)
            );
        }
    }

    function createIno(
        address nftAddress,
        uint256[] memory tokenIds,
        address[] memory paymentTokens,
        uint256[] memory priceItems,
        uint32 limitItemPerUser,
        uint256 floorPoint,
        uint32 start,
        uint32 end
    ) public onlyAdminINO whenPaused {
        require(!isINOExpired(), "INO: expired");
        require(inoStatus.tokenIds.length == 0, "INO: created");
        require(_isValidIno(nftAddress, tokenIds, paymentTokens, priceItems, start, end), "INO: invalid paramater");

        _setupIno(nftAddress, tokenIds, paymentTokens, priceItems, limitItemPerUser, floorPoint, start, end);
        _unpause();

        emit Created(_msgSender(), nftAddress, start, end);
    }


    function updateInfo(uint256 startTime, uint256 endTime, uint256 floorPoint, uint32 limitItemPerUser)
        public
        onlyAdminINO
        whenNotPaused
    {
        require(isNotStart(),"INO: started");
        inoInfo.startTime = startTime;
        inoInfo.endTime = endTime;
        inoInfo.floorPoint = floorPoint;
        inoInfo.limitItemPerUser = limitItemPerUser;
        emit Updated(_msgSender(), block.timestamp);
    }

    function cancelIno() public onlyAdminINO {
        require(isNotStart(),"INO: started");
        _transferItem(inoInfo.nftAddress, inoStatus.tokenIds, address(this), _msgSender());
        _resetIno();
        _pause();
        emit Canceled(_msgSender(), block.timestamp);
    }

    function deposit(address paymentToken, uint256 amountItem)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(canJoinINO(_msgSender(), amountItem), "INO: not matched");
        if (address(nftspacexTicketCard) != address(0)) {
            uint256 idCard = nftspacexTicketCard.currentIdSupported();
            nftspacexTicketCard.safeTransferFrom(_msgSender(), stakingPool, idCard, amountItem * inoInfo.floorPoint, "");
        }
        uint256 totalItem = inoStatus.tokenIds.length;
        require(totalItem > 0, "INO: No nft left ");

        if (amountItem > totalItem) {
            amountItem = totalItem;
        }

        uint256 randNumber = _random();
        for(uint256 i = 0 ; i < amountItem; i++) {
            uint256 tokenIdIndex = randNumber % totalItem;
            uint256 tokenId = inoStatus.tokenIds[tokenIdIndex];
            inoStatus.purchasedNft[_msgSender()].add(tokenId);

            _removeTokenId(tokenIdIndex);
            randNumber = uint256(keccak256(abi.encodePacked(randNumber, i)));
            totalItem--;
        }

        _executeFunds(paymentToken, amountItem);
        inoStatus.numParticipants++;

        emit Deposit(_msgSender(), paymentToken, amountItem);
    }

    function claim() public whenNotPaused {
        require(!isINOOngoing() && !isNotStart(),"INO: not end");
        require(inoStatus.purchasedNft[_msgSender()].length() > 0,"INO: not yet deposit");

        uint256 tokenId;
        for (uint256 i = 0 ; i < inoStatus.purchasedNft[_msgSender()].length() ; i++ ) {
            tokenId = inoStatus.purchasedNft[_msgSender()].at(i);
            IERC721(inoInfo.nftAddress).transferFrom(address(this), _msgSender(), tokenId);
        }
        delete inoStatus.purchasedNft[_msgSender()];
        emit Claim(_msgSender(), block.timestamp);
    }
    function finalise()
        public
        whenNotPaused
        onlyAdminINO
        nonReentrant
    {
        require(!isINOOngoing() && !isNotStart(),"INO: not end");
        require(!isINOExpired(), "INO: expired");
        address tokenAddress;
        uint256 receivableAmount;
        if (inoStatus.tokenIds.length != 0) {
          _transferItem(inoInfo.nftAddress, inoStatus.tokenIds, address(this), _msgSender());
        }

        for (uint256 i = 0; i < inoPayments.length; i++) {
            tokenAddress = inoPayments[i].paymentToken;
            if (tokenAddress == address(0)) {
                receivableAmount = address(this).balance;
                if(receivableAmount > 0) payable(_msgSender()).transfer(receivableAmount);
            } else {
                receivableAmount = IERC20(tokenAddress).balanceOf(address(this));
                if(receivableAmount > 0) safeTokenTransfer(tokenAddress, payable(_msgSender()), receivableAmount);
            }
        }
        inoStatus.finalized = true;
        emit Finalized(_msgSender(), block.timestamp);
    }

    function payments() public view returns(address[] memory, uint256[] memory) {
        address[] memory paymentToken = new address[](inoPayments.length);
        uint256[] memory priceItem = new uint256[](inoPayments.length);
        for (uint256 i = 0; i < inoPayments.length; i++) {
            paymentToken[i] = inoPayments[i].paymentToken;
            priceItem[i] = inoPayments[i].priceItem;
        }
        return (paymentToken, priceItem);
    }

    function info() public view
        returns (
            address nftAddress,
            uint256 startTime,
            uint256 endTime,
            uint256 floorPoint,
            uint32 limitItemPerUser
        )
    {
        nftAddress = inoInfo.nftAddress;
        startTime = inoInfo.startTime;
        endTime = inoInfo.endTime;
        floorPoint = inoInfo.floorPoint;
        limitItemPerUser = inoInfo.limitItemPerUser;
    }

    function status() public view 
        returns(
            uint256 numParticipants,
            uint256[] memory tokenIds,
            uint256[] memory quantity,
            bool finalized
        )
    {
        numParticipants = inoStatus.numParticipants;
        tokenIds = inoStatus.tokenIds;
        quantity = new uint256[](0);
        finalized = inoStatus.finalized;
    }

    function withdrawTokenFailed(address token, uint256 amount) 
        public
        onlyAdminFactory
        nonReentrant
    {
        require(isINOExpired(), "INO: not finalized");
        safeTokenTransfer(token, payable(_msgSender()), amount);
        emit WithdrawTokenFailed(_msgSender(), token, amount);
    }

    function withdrawNFTFailed(address nftAddress, uint256 tokenId) 
        public
        onlyAdminFactory
    {
        require(isINOExpired(), "INO: not finalized");
        IERC721(nftAddress).transferFrom(address(this), _msgSender(), tokenId);
        emit WithdrawNFTFailed(_msgSender(), nftAddress, tokenId);
    }

    function _isValidIno(
        address nftAddress,
        uint256[] memory tokenIds,
        address[] memory paymentTokens,
        uint256[] memory priceItems,
        uint32 start,
        uint32 end
    ) internal view returns (bool){
        return(
            (start >= block.timestamp && end > start) &&
            (nftAddress != address(0)) &&
            (paymentTokens.length > 0 && priceItems.length > 0) &&
            (paymentTokens.length == priceItems.length) &&
            (tokenIds.length > 0)
        );
    }

    function _transferItem(
        address _nftAddress,
        uint256[] memory _tokenIds,
        address _from,
        address _to
    ) internal {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_nftAddress).transferFrom(_from, _to, _tokenIds[i]);
            }
    }
    function _random() internal view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender(),  block.coinbase)));
        return randomNumber;
    }

    function _removeTokenId(uint256 _tokenIdIndex) internal {
        uint256 lastTokenIndex = inoStatus.tokenIds.length - 1;
        if (_tokenIdIndex != lastTokenIndex) {
            uint256 lastTokenId = inoStatus.tokenIds[lastTokenIndex];
            inoStatus.tokenIds[_tokenIdIndex] = lastTokenId;
        }
        inoStatus.tokenIds.pop();
    }

    function _findIndexFromTokenAddress(address _paymentToken) internal view returns(uint256 index) {
        bool findOut;
        for (index = 0; index < inoPayments.length; index++) {
            if (inoPayments[index].paymentToken == _paymentToken) {
                findOut = true;
                return index;
            }
        }
        require(findOut, "INO: not find address token");
    }

    function _resetIno() internal {
        delete inoPayments;
        delete inoStatus;
        delete inoInfo;
    }
    function _setupIno (
        address nftAddress,
        uint256[] memory tokenIds,
        address[] memory paymentTokens,
        uint256[] memory priceItems,
        uint32 limitItemPerUser,
        uint256 floorPoint,
        uint32 start,
        uint32 end
    ) internal {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            Payment memory payment = Payment(paymentTokens[i], priceItems[i]);
            inoPayments.push(payment);
        }

        inoInfo.nftAddress = nftAddress;
        inoStatus.tokenIds = tokenIds;
        inoInfo.limitItemPerUser = limitItemPerUser;
        inoInfo.floorPoint = floorPoint;
        inoInfo.startTime = start;
        inoInfo.endTime = end;
        _transferItem(nftAddress, tokenIds, _msgSender(), address(this));
    }

    function _executeFunds(address _paymentToken,uint256 _amountItem) internal {
        uint256 indexOfPaymentToken = _findIndexFromTokenAddress(_paymentToken);
        uint256 totalPayment = (inoPayments[indexOfPaymentToken].priceItem).mul(_amountItem);
        if (_paymentToken == address(0)) {
            require(msg.value >= totalPayment, "INO: not enough ETH");
            uint256 amountRefund = msg.value.sub(totalPayment);
            if (amountRefund > 0) _safeTransferETH(_msgSender(), amountRefund);
        } else {
            _safeTransferFrom(_paymentToken, _msgSender(), totalPayment);
        }
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
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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

import "../token/ERC1155/IERC1155.sol";

interface INFTSpaceXTicketCard is IERC1155 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function factorySchemaName() external pure returns (string memory);
  function tokenURI(uint256 id) external view returns (string memory);
  function tokenSupply(uint256 id) external view returns (uint256);
  function currentIdSupported() external view returns (uint256);
  function isIdExpired(uint256 id) external view returns (bool);

  function setBaseTokenURI(string memory baseTokenURI) external;
  function create(address initialOwner, uint256 initialSupply, uint256 expiry, bytes calldata data) external;
  function mint(address to, uint256 quantity, bytes calldata data) external;
  function burn(address account, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTSpaceXAdminAccess.sol";

contract NFTSpaceXAccessControls is NFTSpaceXAdminAccess {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event MinterRoleGranted(address indexed beneficiary, address indexed caller);
  event MinterRoleRemoved(address indexed beneficiary, address indexed caller);
  event OperatorRoleGranted(address indexed beneficiary, address indexed caller);
  event OperatorRoleRemoved(address indexed beneficiary, address indexed caller);
  event TokenMinterRoleGranted(address indexed beneficiary, address indexed caller);
  event TokenMinterRoleRemoved(address indexed beneficiary, address indexed caller);

  function hasMinterRole(address _address) public view returns (bool) {
    return hasRole(MINTER_ROLE, _address);
  }

  function hasTokenMinterRole(address _address) public view returns (bool) {
    return hasRole(TOKEN_MINTER_ROLE, _address);
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

  function addTokenMinterRole(address _beneficiary) external {
    grantRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit TokenMinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeTokenMinterRole(address _beneficiary) external {
    revokeRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit TokenMinterRoleRemoved(_beneficiary, _msgSender());
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
  function paused() public virtual view returns (bool) {
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

contract SafeTransfer {
  address private constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

  function safeTokenTransfer(address _token, address payable _to, uint256 _amount) internal {
    if (address(_token) == ETH_ADDRESS) {
      _safeTransferETH(_to, _amount);
    } else {
      _safeTransfer(_token, _to, _amount);
    }
  }

  function tokenTransfer(address _token, address payable _to, uint256 _amount) internal {
    if (address(_token) == ETH_ADDRESS) {
      _to.transfer(_amount);
    } else {
      _safeTransfer(_token, _to, _amount);
    }
  }

  function safeApprove(address token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: approve failed");
  }

  function _safeTransfer(address token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer failed");
  }

  function _safeTransferFrom(address token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer from failed");
  }

  function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer from failed");
  }

  function _safeTransferETH(address to, uint256 value) internal {
    (bool success,) = to.call{value: value}("");
    require(success, "ST: eth transfer failed"); 
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    // event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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