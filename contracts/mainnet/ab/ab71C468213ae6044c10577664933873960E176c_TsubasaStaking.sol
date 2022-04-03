//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract TsubasaStaking is IERC721Receiver {
    /**
     * admin address
     */
    address public admin;
    /**
     * how many tokens can be rewarded per second per NFT
     */
    uint256 public rewardRate;
    /**
     * can user stake NFTs
     */
    bool public stakeEnabled;
    /**
     * when does the reward start
     */
    uint256 public rewardStartTimestamp;
    /**
     * nft address
     */
    address public nftAddress;
    /**
     * ERC20 token address
     */
    address public tokenAddress;
    /**
     * nft id => owner
     */
    mapping(uint256 => address) public nftOwners;
    /**
     * nft id => reward start time
     */
    mapping(uint256 => uint256) public nftTimestamp;
    /**
     * address => staked nft ids
     */
    mapping(address => uint256[]) public userNftIds;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is NOT admin");
        _;
    }

    constructor(
        uint256 rewardRate_,
        address nftAddress_,
        address tokenAddress_
    ) {
        admin = msg.sender;
        stakeEnabled = false;
        rewardRate = rewardRate_;
        rewardStartTimestamp = block.timestamp;
        nftAddress = nftAddress_;
        tokenAddress = tokenAddress_;
    }

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
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        require(stakeEnabled, "Stake disabled");
        // only specified nft contract can call this api
        require(msg.sender == nftAddress, "Wrong NFT");
        // mint to this contract directly is not allowed
        require(from != address(0), "Wrong sender address");
        // confirm nft received
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "NFT NOT received"
        );
        // check nft stake information is empty
        require(nftOwners[tokenId] == address(0), "NFT already staked");
        _stakeNft(tokenId, from);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _stakeNft(uint256 nftId, address owner) private {
        nftOwners[nftId] = owner;
        nftTimestamp[nftId] = block.timestamp;
        userNftIds[owner].push(nftId);
    }

    function stakeApproved() public view returns (bool) {
        return IERC721(nftAddress).isApprovedForAll(msg.sender, address(this));
    }

    function stakeNfts(uint256[] calldata nftIds) public {
        require(stakeApproved(), "Operation unapproved");
        _checkNftOwners(nftIds, msg.sender);
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            IERC721(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                nftId
            );
        }
    }

    function getStakedNftIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return userNftIds[owner];
    }

    function unstakeNfts(uint256[] calldata nftIds) public {
        _checkNftOriginalOwners(nftIds, msg.sender);
        uint256 token = _calculateRewards(nftIds);
        _transferToken(msg.sender, token);
        _returnNfts(nftIds, msg.sender);
    }

    function claimableToken() public view returns (uint256) {
        uint256[] memory nftIds = userNftIds[msg.sender];
        return _calculateRewards(nftIds);
    }

    function claimToken() public {
        uint256[] memory nftIds = userNftIds[msg.sender];
        uint256 token = _calculateRewards(nftIds);
        _resetRewardStartTime(nftIds);
        _transferToken(msg.sender, token);
    }

    function setAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function setNftAddress(address nftAddress_) public onlyAdmin {
        nftAddress = nftAddress_;
    }

    function setTokenAddress(address tokenAddress_) public onlyAdmin {
        tokenAddress = tokenAddress_;
    }

    function setStakeEnabled(bool stakeEnabled_) public onlyAdmin {
        stakeEnabled = stakeEnabled_;
    }

    function setRewardRate(uint256 rewardRate_) public onlyAdmin {
        rewardRate = rewardRate_;
    }

    function setRewardStartTimestamp(uint256 rewardStartTimestamp_)
        public
        onlyAdmin
    {
        rewardStartTimestamp = rewardStartTimestamp_;
    }

    function returnNfts(uint256[] calldata nftIds) public onlyAdmin {
        for (uint256 i = 0; i < nftIds.length; i++) {
            returnNft(nftIds[i]);
        }
    }

    function returnNft(uint256 nftId) public onlyAdmin {
        _returnNft(nftId, nftOwners[nftId]);
    }

    function returnNftToAddress(uint256 nftId, address owner) public onlyAdmin {
        _returnNft(nftId, owner);
    }

    function returnSpecifiedNftToAddress(
        address nftContract,
        uint256 nftId,
        address owner
    ) public onlyAdmin {
        _transferNft(nftContract, nftId, owner);
    }

    function withdrawEther() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(uint256 amount) public onlyAdmin {
        _transferToken(msg.sender, amount);
    }

    function withdrawAllToken() public onlyAdmin {
        withdrawToken(tokenBalance());
    }

    function tokenBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _checkNftOwners(uint256[] memory nftIds, address owner)
        private
        view
    {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(
                IERC721(nftAddress).ownerOf(nftId) == owner,
                "Wrong NFT owner"
            );
        }
    }

    function _checkNftOriginalOwners(uint256[] memory nftIds, address owner)
        private
        view
    {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            require(nftOwners[nftId] == owner, "Wrong NFT owner");
        }
    }

    function _calculateRewards(uint256[] memory nftIds)
        private
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (currentTime <= rewardStartTimestamp) {
            return 0;
        }
        uint256 rewardTime = 0;
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            uint256 startTime = nftTimestamp[nftId];
            if (startTime < rewardStartTimestamp) {
                startTime = rewardStartTimestamp;
            }
            if (startTime >= currentTime) continue;
            rewardTime = rewardTime + (currentTime - startTime);
        }
        return rewardTime * rewardRate;
    }

    function _resetRewardStartTime(uint256[] memory nftIds) private {
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            uint256 time = nftTimestamp[nftId];
            if (time >= currentTime) continue;
            nftTimestamp[nftId] = currentTime;
        }
    }

    function _transferToken(address to, uint256 amount) private {
        require(
            amount <= tokenBalance(),
            "Insufficient token in the pool, contact admin"
        );
        if (amount > 0) {
            IERC20(tokenAddress).transfer(to, amount);
        }
    }

    function _returnNfts(uint256[] memory nftIds, address owner) private {
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            _returnNft(nftId, owner);
        }
    }

    function _returnNft(uint256 nftId, address to) private {
        _removeNftIdOfUser(to, nftId);
        delete nftOwners[nftId];
        _transferNft(nftAddress, nftId, to);
    }

    function _transferNft(
        address nftContract,
        uint256 nftId,
        address to
    ) private {
        IERC721(nftContract).safeTransferFrom(address(this), to, nftId);
    }

    function _removeNftIdOfUser(address owner, uint256 nftId) private {
        for (uint256 i = 0; i < userNftIds[owner].length; i++) {
            if (userNftIds[owner][i] == nftId) {
                userNftIds[owner][i] = userNftIds[owner][
                    userNftIds[owner].length - 1
                ];
                userNftIds[owner].pop();
                return;
            }
        }
    }
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