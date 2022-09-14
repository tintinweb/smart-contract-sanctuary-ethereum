/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  @dev Contract module which provides a basic access control mechanism, where
 *  there is an account (an owner) that can be granted exclusive access to
 *  specific functions.
 *
 *  By default, the owner account will be the one that deploys the contract. This
 *  can later be changed with {transferOwnership}.
 *
 *  This module is used through inheritance. It will make available the modifier
 *  `onlyOwner`, which can be applied to your functions to restrict their use to
 *  the owner.
 */

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 *  @dev Interface of the ERC721 standard as defined in the EIP.
 */
interface IERC721 {
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract INO is Ownable {
    address public token;

    uint256 public startTime;
    uint256 public endTime;

    struct NFT {
        uint256 nftID;
        bool isSold;
        bool exists;
    }

    mapping(uint256 => NFT) nfts;

    uint256 public tokenRate;

    uint256 public totalNFTs;
    uint256 public soldNFT;
    uint256 public totalRaise;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokenRate
    ) {
        require(_startTime < _endTime);
        require(_tokenRate > 0);

        token = _token;

        startTime = _startTime;
        endTime = _endTime;
        tokenRate = _tokenRate;
    }

    function addNFT(uint256[] memory _nftIDs) public onlyOwner {
        for (uint256 x = 0; x < _nftIDs.length; x++) {
            IERC721(token).transferFrom(msg.sender, address(this), _nftIDs[x]);
            nfts[totalNFTs + x] = NFT(_nftIDs[x], false, true);
        }

        totalNFTs += _nftIDs.length;
    }

    function isActive() public view returns (bool) {
        return startTime <= block.timestamp && block.timestamp <= endTime;
    }

    function getTokenInETH(uint256 _tokens) public view returns (uint256) {
        return _tokens * tokenRate;
    }

    function calculateAmount(uint256 _acceptedAmount)
        public
        view
        returns (uint256)
    {
        return _acceptedAmount / tokenRate;
    }

    function buyTokens() public payable {
        address payable _senderAddress = _msgSender();
        uint256 _acceptedAmount = msg.value;

        require(isActive(), "Sale is not ACTIVE!");
        require(_acceptedAmount > 0, "Accepted amount is ZERO");

        uint256 _rewardedAmount = calculateAmount(_acceptedAmount);
        uint256 _unsoldTokens = totalNFTs - soldNFT;

        if (_rewardedAmount > _unsoldTokens) {
            _rewardedAmount = _unsoldTokens;

            uint256 _excessAmount = _acceptedAmount -
                getTokenInETH(_unsoldTokens);
            _senderAddress.transfer(_excessAmount);
        }

        require(_rewardedAmount > 0, "Zero rewarded amount");

        for (uint256 x = soldNFT; x < soldNFT + _rewardedAmount; x++) {
            require(!nfts[x].isSold, "NFT already SOLD!");
            require(nfts[x].exists, "NFT does NOT exist!");

            IERC721(token).transferFrom(
                address(this),
                _senderAddress,
                nfts[x].nftID
            );
            nfts[x] = NFT(nfts[x].nftID, true, nfts[x].exists);
        }

        soldNFT += _rewardedAmount;
        totalRaise += getTokenInETH(_rewardedAmount);
    }

    function withdrawETHBalance() external onlyOwner {
        address payable _sender = _msgSender();

        uint256 _balance = address(this).balance;
        _sender.transfer(_balance);
    }

    function withdrawRemainingTokens() external onlyOwner {
        require(!isActive(), "Token SALE is still ACTIVE!");

        address payable _sender = _msgSender();

        for (uint256 x = soldNFT; x < totalNFTs; x++) {
            if (!nfts[x].isSold && nfts[x].exists)
                IERC721(token).transferFrom(address(this), _sender, x);
        }
    }
}