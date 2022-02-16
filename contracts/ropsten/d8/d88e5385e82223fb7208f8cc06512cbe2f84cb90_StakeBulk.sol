/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: stakeBulk.sol

pragma solidity 0.8.7;
//SPDX-License-Identifier: UNLICENSED




contract StakeBulk is IERC721Receiver {
    IERC721 public nft_address;
    IERC20 public ft_address;

    uint256 public blocks_per_day = 6500;
    uint256 public rewards_per_day = 11 * 10**18;

    address admin;
    
    struct StakeData {
        uint256 accruedBlocks;
        uint256 stakingBlock; // time when the NFT was staked
        uint256 numStaked;
    }

    mapping(uint256 => address) NftIdToOwner;
    mapping(address => StakeData) NftOwnerToData;

    address[] stakers;
    uint256 totalStaked = 0;

    constructor(address nft, address ft, address ceo) {
        nft_address = IERC721(nft);
        ft_address = IERC20(ft);
        admin = ceo;

    }

    function stake(uint256[] memory tokenIds) public {
    
        if (NftOwnerToData[msg.sender].numStaked == 0) {
            StakeData memory data;
            data.stakingBlock = block.number;
            //data.accruedBlocks = 0;
            //data.numStaked = 0;
            NftOwnerToData[msg.sender] = data;
        } else {
            NftOwnerToData[msg.sender].accruedBlocks += (block.number - NftOwnerToData[msg.sender].stakingBlock) * NftOwnerToData[msg.sender].numStaked;
            NftOwnerToData[msg.sender].stakingBlock = block.number;
        }
        
        for (uint256 index; index < tokenIds.length; index++) {
            nft_address.safeTransferFrom(msg.sender, address(this), tokenIds[index], "");

            NftOwnerToData[msg.sender].numStaked += 1;
            NftIdToOwner[tokenIds[index]] = msg.sender;

            totalStaked +=1;
        }

        stakers.push(msg.sender);
    
    }


    function unstake(uint256[] memory tokenIds) public {
        require(NftOwnerToData[msg.sender].numStaked > 0);

        this.withdrawTokens();

        for (uint256 index; index < tokenIds.length; index++) {
            if (msg.sender == NftIdToOwner[tokenIds[index]]){

                nft_address.safeTransferFrom(address(this), msg.sender, tokenIds[index], "");
                delete NftIdToOwner[tokenIds[index]];
                totalStaked -= 1;
                NftOwnerToData[msg.sender].numStaked -= 1;

                break;
            }
        }  
    }

    event withdrew(address indexed _from, uint _value);

    function withdrawTokens() public {
        require(NftOwnerToData[msg.sender].numStaked > 0);
        uint256 earnedBlocks = ((block.number - NftOwnerToData[msg.sender].stakingBlock) * NftOwnerToData[msg.sender].numStaked) + NftOwnerToData[msg.sender].accruedBlocks;
        uint256 rewardAmount = (earnedBlocks * rewards_per_day) / blocks_per_day;

        require(ft_address.balanceOf(address(this)) >= rewardAmount, "contract doesn't own enough rewards");
        emit withdrew(msg.sender, rewardAmount);
        ft_address.transfer(msg.sender, rewardAmount);

        NftOwnerToData[msg.sender].stakingBlock = block.number;
        NftOwnerToData[msg.sender].accruedBlocks = 0;

    }

    modifier onlyOwner() {
        require(msg.sender==admin);
        _;
    }

    function getStakedData(address owner) public view returns(uint256, uint256, uint256) {
        return (NftOwnerToData[owner].accruedBlocks, NftOwnerToData[owner].stakingBlock, NftOwnerToData[owner].numStaked);
    }
    
    
    function getStakers() public view returns(address[] memory) {
        return stakers;
    }

    function getTotalStaked() public view returns(uint256) {
        return totalStaked;
    }

    function getOwnerOfNft(uint256 tokenId) public view returns(address) {
        return NftIdToOwner[tokenId];
    }

    function withdraw(uint256 amount) public onlyOwner {
        ft_address.transfer(msg.sender, amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4){
        return this.onERC721Received.selector;
    }
}