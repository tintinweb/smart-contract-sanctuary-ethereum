// SPDX-License-Identifier: MIT

import "../interfaces/IERC721.sol";
import "../interfaces/IERC20.sol";
import "../util/BmallMath.sol";
import "../util/Context.sol";

pragma solidity 0.8.15;

contract FeeManagerLogic is Context {
  using BmallMath for uint256;

  event AdminWithdraw(address tokenAddr, uint256 tokenAmount);
  event FeeClaim(address nftAddr, uint256[] tokenID, address[] paymentTokenAddrs, uint256[] paymentTokenAmounts);
  event CommunityFeeUpdate(address nftAddr, address paymentTokenAddr, uint256 cummunityFee);
  event SetWhiteList(address nftAddr, bool state);
  event Paused(address account);
  event Unpaused(address account);

  uint256 constant UNIFIEDPOINT = 10 ** 18;
  address constant NATIVECOINADDR = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  address public implementationAddr;
  address public owner;
  address public wyvernProtocolAddr;
  bool private _paused;

  mapping(address => uint256) public nftTotalSupply;

  // This Variable is existed, because of "stack too deep"
  struct CummunityFeeParams {
    uint256 totalSupply;
    uint256 holdingPercent;
    uint256 tokenLength;
    uint256 totalClaimableAmount;
    uint256 rewardPerNFT;
  }

  // accumulatedCommunityFee[nftAddr][tokenAddr] = unifiedAmount
  mapping(address => mapping(address => uint256)) public accumulatedCommunityFee;

  // claimedCommunityFeeInCollection[nftAddr][tokenAddr] = unifiedAmount
  mapping(address => mapping(address => uint256)) public claimedCommunityFeeInCollection;

  // claimedCommunityFee[nftAddr][tokenAddr][nftID] = unifiedAmount
  mapping(address => mapping(address => mapping(uint256 => uint256))) public claimedCommunityFee;

  // NFT whiteList in feeClaim
  mapping(address => bool) public whiteList;

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  modifier onlyWyvernProtocol() {
    require((wyvernProtocolAddr == msg.sender) || (owner == msg.sender), "Wyvernable: caller is not the WyvernProtocol contract");
    _;
  }

  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  modifier whenPaused() {
    _requirePaused();
    _;
  }

  /**
    * @dev Returns true if the contract is paused, and false otherwise.
    */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
    * @dev Throws if the contract is paused.
    */
  function _requireNotPaused() internal view {
    require(!paused(), "Pausable: paused");
  }

  /**
    * @dev Throws if the contract is not paused.
    */
  function _requirePaused() internal view {
    require(paused(), "Pausable: not paused");
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _pause() internal whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  function communityFeeUpdate(address nftAddr, address paymentTokenAddr, uint256 cummunityFee) external onlyWyvernProtocol {
    if(paymentTokenAddr == NATIVECOINADDR){
      accumulatedCommunityFee[nftAddr][NATIVECOINADDR] += cummunityFee;
    }else{
      IERC20 paymentToken = IERC20(paymentTokenAddr);
      uint256 underlyingDecimal = uint256(10 ** paymentToken.decimals());

      uint256 unifiedAmount = cummunityFee.underlyingToUnifiedAmount(underlyingDecimal);
      accumulatedCommunityFee[nftAddr][paymentTokenAddr] += unifiedAmount;
    }

    emit CommunityFeeUpdate(nftAddr, paymentTokenAddr, cummunityFee);
  }

  function batchFeeClaim(address[] memory nftAddr, uint256[][] memory tokenID, address[][] memory tokenAddrs) external whenNotPaused {
    for(uint256 i = 0; i < nftAddr.length; i++){
      _feeClaim(nftAddr[i], tokenID[i], tokenAddrs[i]);
    }
  }

  function adminWithdraw(address tokenAddr, uint256 tokenAmount) external onlyOwner {
    if(tokenAddr == NATIVECOINADDR){
      payable(owner).transfer(tokenAmount);
    }else{
      require(IERC20(tokenAddr).transfer(owner, tokenAmount));
    }
    emit AdminWithdraw(tokenAddr, tokenAmount);
  }

  function feeClaim(address nftAddr, uint256[] memory tokenID, address[] memory tokenAddrs) external whenNotPaused {
    _feeClaim(nftAddr, tokenID, tokenAddrs);
  }

  function _feeClaim(address nftAddr, uint256[] memory tokenID, address[] memory tokenAddrs) internal {
    // mitigation for flashloan attack based on NFT
    require(msg.sender == tx.origin);

    // mitigation for malicious nft contract, add whiteList require statement
    require(whiteList[nftAddr] == true, "only whitelist");

    IERC721 nft = IERC721(nftAddr);

    CummunityFeeParams memory cummunityFeeParams;
    cummunityFeeParams.totalSupply = _getTotalSupply(nftAddr);
    cummunityFeeParams.tokenLength = tokenID.length * UNIFIEDPOINT;


    // This code for blocking nft's minting. if specific nft is minted in Bmall, maybe this nft is blocked.
    if(nftTotalSupply[nftAddr] == 0){
      nftTotalSupply[nftAddr] = cummunityFeeParams.totalSupply;
    }
    require( nftTotalSupply[nftAddr] == cummunityFeeParams.totalSupply, "NFT totalSupply is changed");
    //

    uint256[] memory rewardAmount = new uint256[](tokenAddrs.length);

    for(uint256 tokenAddrIndex = 0; tokenAddrIndex < tokenAddrs.length; tokenAddrIndex++){
        address _tokenAddr = tokenAddrs[tokenAddrIndex];

        for(uint256 tokenIDIndex = 0; tokenIDIndex < tokenID.length; tokenIDIndex++) {
            uint256 _tokenID = tokenID[tokenIDIndex];
            address nftOwner = nft.ownerOf(_tokenID);
            require(nftOwner == msg.sender, "Do not match nft owners");

            cummunityFeeParams.rewardPerNFT = accumulatedCommunityFee[nftAddr][_tokenAddr].unifiedDiv(cummunityFeeParams.totalSupply);

            if(cummunityFeeParams.rewardPerNFT > claimedCommunityFee[nftAddr][_tokenAddr][_tokenID]){
                cummunityFeeParams.rewardPerNFT -= claimedCommunityFee[nftAddr][_tokenAddr][_tokenID];
            }else{
                continue;
            }

            claimedCommunityFee[nftAddr][_tokenAddr][_tokenID] += cummunityFeeParams.rewardPerNFT;
            claimedCommunityFeeInCollection[nftAddr][_tokenAddr] += cummunityFeeParams.rewardPerNFT;
            rewardAmount[tokenAddrIndex] += cummunityFeeParams.rewardPerNFT;
        }

        require(claimedCommunityFeeInCollection[nftAddr][_tokenAddr] <= accumulatedCommunityFee[nftAddr][_tokenAddr], "Over claimed fees");

        if(rewardAmount[tokenAddrIndex] > 0){
          if(tokenAddrs[tokenAddrIndex] == NATIVECOINADDR){
            payable(msg.sender).transfer(rewardAmount[tokenAddrIndex]);
          }else{
            IERC20 token = IERC20(tokenAddrs[tokenAddrIndex]);
            uint256 underlyingDecimal = uint256(10 ** token.decimals());
            uint256 underlyingAmount = rewardAmount[tokenAddrIndex].unifiedToUnderlyingAmount(underlyingDecimal);
            require(token.transfer(msg.sender, underlyingAmount));
          }
        }

    }

    emit FeeClaim(nftAddr, tokenID, tokenAddrs, rewardAmount);
  }

  // mitigation of totalSupply function not existed in erc721
  function _getTotalSupply(address nftAddr) internal view returns (uint256) {
    IERC721 erc721 = IERC721(nftAddr);

    try erc721.totalSupply() returns (uint256 _value) {
      return (_value * UNIFIEDPOINT);
    }
    catch {
      require(nftTotalSupply[nftAddr] != 0, "Err: nft totalSupply is 0");
      return nftTotalSupply[nftAddr];
    }
  }

  function setWhiteList(address _nftAddr, bool _state) external onlyOwner {
    whiteList[_nftAddr] = _state;
    emit SetWhiteList(_nftAddr, _state);
  }

  function setClaimedCommunityFeeInCollection(address _nftAddr, address _tokenAddr, uint256 _claimedAmount) external onlyOwner {
    claimedCommunityFeeInCollection[_nftAddr][_tokenAddr] = _claimedAmount;
  }

  function setClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _nftID, uint256 _claimedAmount) external onlyOwner {
    claimedCommunityFee[_nftAddr][_tokenAddr][_nftID] = _claimedAmount;
  }

  function setAccumulatedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _accumulatedAmount) external onlyOwner {
    accumulatedCommunityFee[_nftAddr][_tokenAddr] = _accumulatedAmount;
  }

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setWyvernProtocolAddr(address _wyvernProtocolAddr) external onlyOwner {
    wyvernProtocolAddr = _wyvernProtocolAddr;
  }

  function getWhiteList(address _nftAddr) external view returns (bool) {
    return whiteList[_nftAddr];
  }

  function setNFTTotalSupply(address _nftAddr, uint256 _totalSupply) external onlyOwner {
    nftTotalSupply[_nftAddr] = _totalSupply;
  }

  function getNFTTotalSupply(address _nftAddr) external view returns (uint256) {
    return nftTotalSupply[_nftAddr];
  }

  function getWyvernProtocolAddr() external view returns (address) {
    return wyvernProtocolAddr;
  }

  function getRewardPerNFT(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return _getRewardPerNFT(_nftAddr, _tokenAddr);
  }

  function _getRewardPerNFT(address _nftAddr, address _tokenAddr) internal view returns (uint256) {
    uint256 totalSupply = _getTotalSupply(_nftAddr);
    uint256 rewardPerNFT = accumulatedCommunityFee[_nftAddr][_tokenAddr].unifiedDiv(totalSupply);
    return rewardPerNFT;
  }

  function getRewardAmount(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    uint256 rewardPerNFT = _getRewardPerNFT(_nftAddr, _tokenAddr);
    return rewardPerNFT - claimedCommunityFee[_nftAddr][_tokenAddr][_tokenID];
  }

  function getClaimedCommunityFee(address _nftAddr, address _tokenAddr, uint256 _tokenID) external view returns (uint256) {
    return claimedCommunityFee[_nftAddr][_tokenAddr][_tokenID];
  }

  function getAccumulatedCommunityFee(address _nftAddr, address _tokenAddr) external view returns (uint256) {
    return accumulatedCommunityFee[_nftAddr][_tokenAddr];
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.15;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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


    function totalSupply() external view  returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.15;

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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.15;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

library BmallMath {
  uint256 internal constant UNIFIEDPOINT = 10 ** 18;
	/******************** Safe Math********************/
  function underlyingToUnifiedAmount(uint256 underlyingAmount, uint256 underlyingDecimal) internal pure returns (uint256) {
    return (underlyingAmount * UNIFIEDPOINT) / underlyingDecimal;
  }

  function unifiedToUnderlyingAmount(uint256 unifiedTokenAmount, uint256 underlyingDecimal) internal pure returns (uint256) {
    return (unifiedTokenAmount * underlyingDecimal) / UNIFIEDPOINT;
  }

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
	  return (a * UNIFIEDPOINT) / b;
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / UNIFIEDPOINT;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity >=0.4.23;

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
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}