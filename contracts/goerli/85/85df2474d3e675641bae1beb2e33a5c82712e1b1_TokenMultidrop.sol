/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-02
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the BIP.
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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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



contract TokenMultidrop is Ownable {

    uint256 public oneDayMembershipFee = 0;
    uint256 public sevenDayMembershipFee = 0;
    uint256 public oneMonthMembershipFee = 0;
    uint256 public lifetimeMembershipFee = 0;

    uint256 public tokenHoldersDiscountPer  = 0;
    uint256 public rate = 0;
    uint256 public dropUnitPrice = 0;
    uint256 public freeTrialLimit = 100;

    mapping (address => uint256) public tokenTrialDrops;
    mapping (address => uint256) public userTrialDrops;

    mapping (address => uint256) public membershipExpiryTime;

    address[] public vipMemberList;

    event BecomeVIPMember(address indexed _user, uint256 _day, uint256 _fee, uint256 _time);
    event TokenAirdrop (address indexed _user, address indexed _tokenAddress, uint256 _totalTransfer, uint256 _time);
    event NFTsAirdrop (address indexed _user, address indexed _tokenAddress, uint256 _totalTransfer, uint256 _time);

    function setMembershipFees(uint256 _oneDayFee, uint256 _sevenDayFee, uint256 _oneMonthFee, uint256 _lifetimeFee) public onlyOwner {
        oneDayMembershipFee = _oneDayFee;
        sevenDayMembershipFee = _sevenDayFee;
        oneMonthMembershipFee = _oneMonthFee;
        lifetimeMembershipFee = _lifetimeFee;
    }

    function setFreeTrialLimit(uint256 _limit) public onlyOwner {
        freeTrialLimit = _limit;
    }

    function setTokenHoldersDiscountPer(uint256 _per) public onlyOwner{
        tokenHoldersDiscountPer = _per;
    }

    function getVIPMembershipFee(uint256 _days) public view returns(uint256){
      if(_days == 1 ){
          return oneDayMembershipFee;
      }else if(_days ==7){
          return sevenDayMembershipFee;
      }else if(_days == 31){
          return oneMonthMembershipFee;
      }else{
          return lifetimeMembershipFee;
      }
    }

    function checkIsPremiumMember(address _addr) public view returns(bool isMember) {
        return membershipExpiryTime[_addr] >= block.timestamp;
    }

    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool hasFreeTrial) {
        return tokenTrialDrops[_addressOfToken] < freeTrialLimit;
    }

    function userHasFreeTrial(address _addressOfUser) public view returns(bool hasFreeTrial) {
        return userTrialDrops[_addressOfUser] < freeTrialLimit;
    }

    function getRemainingTokenTrialDrops(address _addressOfToken) public view returns(uint256 remainingTrialDrops) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            return freeTrialLimit - tokenTrialDrops[_addressOfToken];
        } 
        return 0;
    }

    function getRemainingUserTrialDrops(address _addressOfUser) public view returns(uint256 remainingTrialDrops) {
        if(userHasFreeTrial(_addressOfUser)) {
            return freeTrialLimit - userTrialDrops[_addressOfUser];
        }
        return 0;
    }

    function becomeMember(uint256 _day) public payable returns(bool success) {
        uint256 _fee;
        if(_day == 1){
            _fee = oneDayMembershipFee;
        }else if(_day == 7){
            _fee = sevenDayMembershipFee;
        }else if(_day == 31){
            _fee = oneMonthMembershipFee;
        }else {
            _fee = lifetimeMembershipFee;
        }
        require(checkIsPremiumMember(msg.sender) != true, "Is already premiumMember member");
       
        require(msg.value >= _fee, "Not Enough Fee Sent");
        membershipExpiryTime[msg.sender] = block.timestamp + (_day * 1 days);
        vipMemberList.push(msg.sender);
        emit BecomeVIPMember(msg.sender, _day, _fee, block.timestamp);
        return true;
    }

    function setServiceFeeRate(uint256 _newRate) public onlyOwner returns(bool success) {
        require(_newRate > 0,"Rate must be greater than 0");
        dropUnitPrice = _newRate;
        return true;
    }

    function erc20Airdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, bool _isDeflationary) public payable {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender);
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfToken) && userHasFreeTrial(msg.sender);
        require(msg.value >= price || isPremiumOrListed, "Not enough funds sent with transaction!");
        if((eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } 
      
        if(!_isDeflationary) {
            IERC20(_addressOfToken).transferFrom(msg.sender, address(this), _totalToSend);
            for(uint i = 0; i < _recipients.length; i++) {
                IERC20(_addressOfToken).transfer(_recipients[i], _values[i]);
            }
            if(IERC20(_addressOfToken).balanceOf(address(this)) > 0) {
                IERC20(_addressOfToken).transfer(msg.sender,IERC20(_addressOfToken).balanceOf(address(this)));
            }
        } else {
            for(uint i=0; i < _recipients.length; i++) {
                IERC20(_addressOfToken).transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }      
        if( !eligibleForFreeTrial && !isPremiumOrListed) {
            payable(owner()).transfer(_recipients.length * dropUnitPrice);   
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] += _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] += _recipients.length;
        }
        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length, block.timestamp);
    }

    function NFTAirdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds, uint256[] memory _amounts, uint8 _type) public payable {
        require(_recipients.length == _tokenIds.length, "Total number of recipients and total number of NFT IDs are not the same"); 
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);   
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender);
        require(msg.value >= price || isPremiumOrListed, "Not enough funds sent with transaction!");       
        if( (eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        }  
        if(_type == 1){
            require(_recipients.length == _amounts.length, "Total number of recipients and total number of amounts are not the same");
            for(uint i = 0; i < _recipients.length; i++) {
                IERC1155(_addressOfNFT).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], "");
            }
        }else{
            for(uint i = 0; i < _recipients.length; i++) {          
                IERC721(_addressOfNFT).transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
            }
        }                 
        if(!eligibleForFreeTrial && !isPremiumOrListed) {
            payable(owner()).transfer(_recipients.length * dropUnitPrice); 
        }
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] += _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] += _recipients.length;
        }
        emit NFTsAirdrop(msg.sender, _addressOfNFT, _recipients.length, block.timestamp);
    }

    function withdraw() public onlyOwner returns(bool success) {
        payable(owner()).transfer(address(this).balance);
        return true;
    }
}