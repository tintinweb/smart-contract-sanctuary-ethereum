// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IApeStaking {
    struct SingleNft {
        uint256 nftId;
        uint256 amount;
    }

    struct PairNftWithdrawWithAmount {
        uint256 nftId;
        uint256 amount;
        bool isUncommit;
    }

    function pendingRewards(
        uint256 _poolId,
        address _address
    ) external view returns (uint256);

    function depositApeCoin(uint256 _amount) external;

    function depositBAYC(uint256 _tokenId, uint256 _amount) external;

    function depositMAYC(uint256 _tokenId, uint256 _amount) external;

    function depositBAKC(
     PairNftWithdrawWithAmount[] calldata _baycPairs,
     PairNftWithdrawWithAmount[] calldata _maycPairs
    ) external;

    function depositPair(
        uint256 _baycTokenId,
        uint256 _maycTokenId,
        uint256 _amount
    ) external;

    function withdrawBAYC(
        SingleNft[] calldata _nfts,
        address _recipient
    ) external;

    function withdrawMAYC(
        SingleNft[] calldata _nfts,
        address _recipient
    ) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata _baycPairs,
        PairNftWithdrawWithAmount[] calldata _maycPairs
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IApeStaking.sol";

contract MatchingApe is IERC721Receiver {
    IERC20 public apeToken;
    IERC721 public baycToken;
    IERC721 public maycToken;
    IERC721 public bakcToken;
    IApeStaking public apeStaking;

    enum NftType {
        BAYC,
        MAYC,
        BAKC
    }

    struct NftDepositRequest {
        NftType nftType;
        uint256 tokenId;
        uint256 desiredApeAmount;
        uint256 minimumStakingTime;
        address nftOwner;
        bool isFulfilled;
        uint256 fulfillmentTime;
    }

    mapping(uint256 => NftDepositRequest) public nftDepositRequests;
    mapping(uint256 => address) public apeHolders;
    mapping(address => uint256) public apeBalances;

    uint256 public nextDepositRequestId;

    uint256 public constant BAYC_POOL_ID = 1;
    uint256 public constant MAYC_POOL_ID = 2;
    uint256 public constant BAKC_POOL_ID = 3;

    constructor() {
        // deployed contract addresses on Goerli
        apeToken = IERC20(0xBd01e830E112eDF18bB7aCF484d2a954a48016a7);
        baycToken = IERC721(0xFB539A97Af991B1D83502A7ee61D8287453763E1);
        maycToken = IERC721(0x216fAd4e2D20D28Cf3B6e5c21eD98822259572cB);
        bakcToken = IERC721(0x26374Fa390c2E3AdC5363c7f261faF96e0489ca9);
        apeStaking = IApeStaking(0xa6d86470da4709d2FF38521AaE18c47B4162311F);
    }

    function depositNft(
        NftType nftType,
        uint256 tokenId,
        uint256 desiredApeAmount,
        uint256 minimumStakingTime
    ) external {
        require(
            desiredApeAmount > 0,
            "Desired APE amount must be greater than 0"
        );

        if (nftType == NftType.BAYC) {
            baycToken.safeTransferFrom(msg.sender, address(this), tokenId);
        } else if (nftType == NftType.MAYC) {
            maycToken.safeTransferFrom(msg.sender, address(this), tokenId);
        } else if (nftType == NftType.BAKC) {
            bakcToken.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        NftDepositRequest storage request = nftDepositRequests[
            nextDepositRequestId
        ];
        request.nftType = nftType;
        request.tokenId = tokenId;
        request.desiredApeAmount = desiredApeAmount;
        request.minimumStakingTime = minimumStakingTime;
        request.nftOwner = msg.sender;

        nextDepositRequestId++;
    }

    function fulfillNftDeposit(
        uint256 depositRequestId,
        uint256 apeAmount
    ) external {
        NftDepositRequest storage request = nftDepositRequests[
            depositRequestId
        ];
        require(!request.isFulfilled, "Deposit request already fulfilled");
        require(
            apeAmount >= request.desiredApeAmount,
            "APE amount does not meet desired APE"
        );

        apeToken.transferFrom(msg.sender, address(this), apeAmount);

        uint256 tokenId = request.tokenId;
        if (request.nftType == NftType.BAYC) {
            apeStaking.depositBAYC(apeAmount, tokenId);
        } else if (request.nftType == NftType.MAYC) {
            apeStaking.depositMAYC(apeAmount, tokenId);
        } 
        // else if (request.nftType == NftType.BAKC) {
        //     apeStaking.depositBAKC(apeAmount, tokenId);
        // }

        apeBalances[msg.sender] += apeAmount;
        request.isFulfilled = true;
        request.fulfillmentTime = block.timestamp;
        apeHolders[depositRequestId] = msg.sender;
    }

    function claimRewardsAndUnstake(uint256 depositRequestId) external {
        uint256 rewards;
        uint256 halfRewards;

        NftDepositRequest storage request = nftDepositRequests[
            depositRequestId
        ];
        require(request.isFulfilled, "Deposit request not fulfilled");
        require(
            block.timestamp >=
                request.fulfillmentTime + request.minimumStakingTime,
            "Minimum staking time not reached"
        );

        if (request.nftType == NftType.BAYC) {
            rewards = apeStaking.pendingRewards(
            1,
            address(this)
        );
        halfRewards = rewards / 2;
        } else if (request.nftType == NftType.MAYC) {
            rewards = apeStaking.pendingRewards(
            2,
            address(this)
        
        );
        halfRewards = rewards / 2;
        }
        

        // Create a SingleNft struct with the tokenId and amount
        IApeStaking.SingleNft[] memory nfts = new IApeStaking.SingleNft[](1);
        nfts[0] = IApeStaking.SingleNft(request.tokenId, 0);

        // Call the corresponding withdraw function based on the poolId
        if (request.nftType == NftType.BAYC) {
            apeStaking.withdrawBAYC(nfts, address(this));
        } else if (request.nftType == NftType.MAYC) {
            apeStaking.withdrawMAYC(nfts, address(this));
        } else if (request.nftType == NftType.BAKC) {
            // Create PairNftWithdrawWithAmount structs for BAYC and MAYC pairs
            IApeStaking.PairNftWithdrawWithAmount[]
                memory baycPairs = new IApeStaking.PairNftWithdrawWithAmount[](
                    1
                );
            IApeStaking.PairNftWithdrawWithAmount[]
                memory maycPairs = new IApeStaking.PairNftWithdrawWithAmount[](
                    1
                );
            baycPairs[0] = IApeStaking.PairNftWithdrawWithAmount(
                request.tokenId,
                0,
                false
            );
            maycPairs[0] = IApeStaking.PairNftWithdrawWithAmount(
                request.tokenId,
                0,
                false
            );

            apeStaking.withdrawBAKC(baycPairs, maycPairs);
        }

        apeToken.transfer(request.nftOwner, halfRewards);
        apeToken.transfer(apeHolders[depositRequestId], halfRewards);
    }

    // functions for withdrawing APE and NFTs go here
    function withdrawApe(uint256 depositRequestId) public {
        require(
            apeHolders[depositRequestId] == msg.sender,
            "Not the APE holder"
        );
        uint256 apeAmount = nftDepositRequests[depositRequestId]
            .desiredApeAmount;
        apeBalances[msg.sender] -= apeAmount;
        apeToken.transfer(msg.sender, apeAmount);
        delete apeHolders[depositRequestId];
    }

    function withdrawNft(uint256 depositRequestId) public {
        NftDepositRequest storage request = nftDepositRequests[
            depositRequestId
        ];
        require(request.nftOwner == msg.sender, "Not the NFT owner");

        if (request.nftType == NftType.BAYC) {
            baycToken.safeTransferFrom(
                address(this),
                msg.sender,
                request.tokenId
            );
        } else if (request.nftType == NftType.MAYC) {
            maycToken.safeTransferFrom(
                address(this),
                msg.sender,
                request.tokenId
            );
        } else if (request.nftType == NftType.BAKC) {
            bakcToken.safeTransferFrom(
                address(this),
                msg.sender,
                request.tokenId
            );
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}