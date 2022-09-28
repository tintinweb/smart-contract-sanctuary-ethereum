pragma solidity 0.8.14;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

contract NFTexchange {

    using SafeMath for uint256;

    uint256 public chainId;

    string private _name;
    string private _version;
    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    string private constant SELL_TYPE = "SellOrder(string _nonce,uint _startsAt,uint _expiresAt,address _nftContract,uint256 _nftTokenId,address _paymentTokenContract,address _seller,address _royaltyPayTo,uint256 _sellerAmount,uint256 _feeAmount,uint256 _royaltyAmount,uint256 _totalAmount)";
    string private constant BUY_TYPE = "BuyOrder(string _nonce,uint _startsAt,uint _expiresAt,address _nftContract,uint256 _nftTokenId,address _paymentTokenContract,address _buyer,address _royaltyPayTo,uint256 _sellerAmount,uint256 _feeAmount,uint256 _royaltyAmount,uint256 _totalAmount)";
    
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant SELL_TYPEHASH = keccak256(abi.encodePacked(SELL_TYPE));
    bytes32 private constant BUY_TYPEHASH = keccak256(abi.encodePacked(BUY_TYPE));
    
    bytes32 private DOMAIN_SEPARATOR;

    mapping (address => bool) public admins;
    address[] private allAdmins;
    uint16 public adminCount;

    bool public paused;

    struct SellOrder {
        string _nonce;
        uint _startsAt;
        uint _expiresAt;
        address _nftContract;
        uint256 _nftTokenId;
        address _paymentTokenContract;
        address _seller;
        address _royaltyPayTo;
        uint256 _sellerAmount;
        uint256 _feeAmount;
        uint256 _royaltyAmount;
        uint256 _totalAmount;
    }

    struct BuyOrder {
        string _nonce;
        uint _startsAt; 
        uint _expiresAt; 
        address _nftContract;
        uint256 _nftTokenId;
        address _paymentTokenContract; 
        address _buyer;
        address _royaltyPayTo;
        uint256 _sellerAmount; 
        uint256 _feeAmount;
        uint256 _royaltyAmount;
        uint256 _totalAmount;
    }

    event Exchange(uint256 indexed exchangeId);

    event Paused();
    event Unpaused();

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized request.");
        _;
    }

    modifier ifUnpaused() {
        require(paused == false, "Sorry!! The Contract is paused currently.");
        _;
    }

    function hashSellOrder(SellOrder memory sell) internal view returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                SELL_TYPEHASH,
                keccak256(bytes(sell._nonce)),
                sell._startsAt,
                sell._expiresAt,
                sell._nftContract,
                sell._nftTokenId,
                sell._paymentTokenContract,
                sell._seller,
                sell._royaltyPayTo,
                sell._sellerAmount,
                sell._feeAmount,
                sell._royaltyAmount,
                sell._totalAmount
            ))
        ));
    }

    function verifySeller(SellOrder memory sell, bytes memory sig) internal view returns (bool) {    
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return sell._seller == ecrecover(hashSellOrder(sell), v, r, s);
    }

    function hashBuyOrder(BuyOrder memory buy) internal view returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                BUY_TYPEHASH,
                keccak256(bytes(buy._nonce)),
                buy._startsAt,
                buy._expiresAt,
                buy._nftContract,
                buy._nftTokenId,
                buy._paymentTokenContract,
                buy._buyer,
                buy._royaltyPayTo,
                buy._sellerAmount,
                buy._feeAmount,
                buy._royaltyAmount,
                buy._totalAmount
            ))
        ));
    }

    function verifyBuyer(BuyOrder memory buy, bytes memory sig) internal view returns (bool) {    
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return buy._buyer == ecrecover(hashBuyOrder(buy), v, r, s);
    }

    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function removeAddressArrayElement(address[] storage _arr, address _elem) internal {
        bool found;
        uint index;
        for(uint i = 0; i<_arr.length; i++) {
            if(_arr[i] == _elem) {
                found = true;
                index = i;
                break;
            }
        }
        if(found) {
            _arr[index] = _arr[_arr.length - 1];
            _arr.pop();
        }
    }

    constructor(string memory _contractName, string memory _contractVersion, address _admin) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        chainId = chain;
        _name = _contractName;
        _version = _contractVersion;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            chainId,
            address(this)
        ));
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function version() external view returns(string memory) {
        return _version;
    }

    function addAdmin(address _account) external onlyAdmin returns(bool) {
        admins[_account] = true;
        allAdmins.push(_account);
        adminCount++;
        return true;
    }

    function deleteAdmin(address _account) external onlyAdmin returns(bool) {
        require(_account != msg.sender, "You can't delete yourself from admin.");
        require(admins[_account] == true, "No admin found with this address.");
        delete admins[_account];
        removeAddressArrayElement(allAdmins, _account);
        adminCount--;
        return true;
    }

    function pauseContract() external onlyAdmin returns(bool){
        paused = true;
        emit Paused();
        return true;
    }

    function unPauseContract() external onlyAdmin returns(bool){
        paused = false;
        emit Unpaused();
        return true;
    }

    function getAllAdmins() external view onlyAdmin returns(address[] memory) {
        return allAdmins;
    }

    function withdrawNative(address payable to, uint256 amountInWei) external onlyAdmin returns(bool) {
        require(amountInWei <= address(this).balance, "Not enough fund.");
        to.transfer(amountInWei);
        return true;
    }

    function withdrawToken(address _tokenContract, address to, uint256 amount)
     external onlyAdmin returns(bool) {
        IERC20 token = IERC20(_tokenContract);
        require(amount <= token.balanceOf(address(this)), "Not enough fund.");
        token.transfer(to, amount);
        return true;
    }

    function buyNFT(SellOrder memory sell, uint256 exchangeId, bytes memory _signature)
    ifUnpaused payable external returns(bool) {
        require(sell._nftContract != address(0), "NFT Contract address can't be zero address");
        require(sell._seller != address(0), "Seller address can't be zero address");
        if(sell._royaltyAmount > 0) {
            require(sell._royaltyPayTo != address(0), "Royalty payout address can't be zero address");
        }

        IERC721 nft = IERC721(sell._nftContract);
        require(nft.isApprovedForAll(sell._seller, address(this)), "Sorry!! Seller removed the approval for selling NFT.");
        require(nft.ownerOf(sell._nftTokenId) == sell._seller, "Sorry!! Currently Seller doesn't own the NFT.");

        require(block.timestamp >= sell._startsAt, "Sell offer hasn't started yet.");
        require(block.timestamp < sell._expiresAt, "Sell offer expired.");

        require(msg.value > 0, "Zero amount sent.");
        require(sell._totalAmount == msg.value, "Total Amount and sent amount doesn't match.");

        require(verifySeller(sell, _signature), "Invalid seller signature.");
        
        emit Exchange(exchangeId);

        nft.transferFrom(sell._seller, msg.sender, sell._nftTokenId);

        payable(sell._seller).transfer(sell._sellerAmount);
        if(sell._royaltyAmount > 0) {
            payable(sell._royaltyPayTo).transfer(sell._royaltyAmount);
        }
        return true;
    }

    function sellNFT(BuyOrder memory buy, uint256 exchangeId, bytes memory _signature)
    ifUnpaused external returns(bool) {
        require(buy._nftContract != address(0), "NFT Contract address can't be zero address");
        require(buy._buyer != address(0), "Buyer address can't be zero address");
        require(buy._paymentTokenContract != address(0), "Payment Token Contract address can't be zero address");
        if(buy._royaltyAmount > 0) {
            require(buy._royaltyPayTo != address(0), "Royalty payout address can't be zero address");
        }

        IERC20 token = IERC20(buy._paymentTokenContract);
        require(token.allowance(buy._buyer, address(this)) > buy._totalAmount, "Sorry!! Buyer removed the approval for Payment Token transfer.");
        require(token.balanceOf(buy._buyer) > buy._totalAmount, "Sorry!! Currently Buyer doesn't have enough Token.");

        IERC721 nft = IERC721(buy._nftContract);
        require(nft.isApprovedForAll(msg.sender, address(this)), "Sorry!! You removed the approval for selling NFT.");
        require(nft.ownerOf(buy._nftTokenId) == msg.sender, "Sorry!! Currently you don't own the NFT.");

        require(block.timestamp >= buy._startsAt, "Buy offer hasn't started yet.");
        require(block.timestamp < buy._expiresAt, "Buy offer expired.");

        require(verifyBuyer(buy, _signature), "Invalid buyer signature.");
        
        emit Exchange(exchangeId);

        nft.transferFrom(msg.sender, buy._buyer, buy._nftTokenId);

        token.transferFrom(buy._buyer, msg.sender, buy._sellerAmount);
        token.transferFrom(buy._buyer, address(this), buy._feeAmount);
        if(buy._royaltyAmount > 0) {
            token.transferFrom(buy._buyer, buy._royaltyPayTo, buy._royaltyAmount);
        }
        return true;
    }

    function exchangeNFTauction(SellOrder memory sell, BuyOrder memory buy, 
    uint256 exchangeId, uint256 minBidAmountToExecute,
    bytes memory _sellerSig, bytes memory _buyerSig)
    external onlyAdmin ifUnpaused returns(bool) {

        require(sell._seller != address(0), "Seller address can't be zero address");
        require(buy._buyer != address(0), "Buyer address can't be zero address");
        if(sell._royaltyAmount > 0) {
            require(buy._royaltyPayTo != address(0), "Royalty payout address can't be zero address");
        }

        require(sell._nftContract != address(0), "NFT Contract address can't be zero address");
        require(sell._nftContract == buy._nftContract, "Buy and Sell NFT Contract address doesn't match");
        require(sell._nftTokenId == buy._nftTokenId, "Buy and Sell NFT Token Id doesn't match");

        require(buy._paymentTokenContract != address(0), "Payment Token Contract address can't be zero address");
        require(sell._paymentTokenContract == buy._paymentTokenContract, "Buy and Sell Payment Token doesn't match");

        require(buy._totalAmount >= minBidAmountToExecute, "Buy amount is less than min Bid amount to execute the Auction Exchange");
        require(buy._totalAmount >= sell._totalAmount, "Buy amount is less than Sell amount");

        // require(block.timestamp >= sell._expiresAt, "Auction isn't finished yet.");

        require(verifySeller(sell, _sellerSig), "Invalid seller signature.");
        require(verifyBuyer(buy, _buyerSig), "Invalid buyer signature.");

        IERC721 nft = IERC721(sell._nftContract);
        require(nft.isApprovedForAll(sell._seller, address(this)), "We Don't have approval for the NFT.");
        require(nft.ownerOf(sell._nftTokenId) == sell._seller, "Seller doesn't own the NFT.");

        IERC20 token = IERC20(buy._paymentTokenContract);
        require(token.allowance(buy._buyer, address(this)) > buy._totalAmount, "We Don't have approval for the Payment Token.");
        require(token.balanceOf(buy._buyer) > buy._totalAmount, "Buyer doesn't have enough Token.");

        emit Exchange(exchangeId);
        
        nft.transferFrom(sell._seller, buy._buyer, sell._nftTokenId);

        token.transferFrom(buy._buyer, sell._seller, buy._sellerAmount);
        token.transferFrom(buy._buyer, address(this), buy._feeAmount);
        if(sell._royaltyAmount > 0) {
            token.transferFrom(buy._buyer, buy._royaltyPayTo, sell._royaltyAmount);
        }
        return true;
    }
    
}

pragma solidity ^0.8.6;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.13;

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