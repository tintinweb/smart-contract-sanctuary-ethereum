//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


contract IOStaking {

    //general state
    address public owner = msg.sender;
    bool public paused;

    //NFT connected to this staking contract
    mapping(address => bool) public stakableNFT;
    mapping(address => bool) public disallowNewStaking;

    //ranking timing
    mapping(address => uint[]) public rankTime;
    mapping(address => uint8) public maxRank;

    //staking records
    mapping(address => mapping(uint256 => uint)) public stakedTokenTime;
    mapping(address => mapping(uint256 => address)) public stakedOwner;

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
    }

    //stake using a safeTransferFrom into staking contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        require(!paused, "paused");
        require(stakableNFT[msg.sender], "not stakable");
        require(!disallowNewStaking[msg.sender], "no new staking");
        require(data.length==0, "unknown data");

        stakedTokenTime[msg.sender][tokenId] = block.timestamp;
        stakedOwner[msg.sender][tokenId] = from;
        return type(IERC721Receiver).interfaceId;
    }

    //stake, requires approve or SetApprovalForAll first
    function stake(address _nftContract, uint256[] memory tokenIds) public {
        require(!paused, "paused");
        require(stakableNFT[_nftContract], "not stakable");
        require(!disallowNewStaking[_nftContract], "no new staking");

        for(uint i=0;i<tokenIds.length;i++){
            IERC721(_nftContract).transferFrom(msg.sender, address(this), tokenIds[i]);
            stakedTokenTime[_nftContract][tokenIds[i]] = block.timestamp;
            stakedOwner[_nftContract][tokenIds[i]] = msg.sender;
        }
    }

    //unstake
    function unstake(address _nftContract, uint256[] memory tokenIds) public {
        require(!paused, "paused");
        require(stakableNFT[_nftContract], "Not stakable contract");

        for(uint8 i=0;i<tokenIds.length;i++){
            require(stakedOwner[_nftContract][tokenIds[i]] == msg.sender, "NFT not owned");

            //reset staking time
            delete stakedTokenTime[_nftContract][tokenIds[i]];
            delete stakedOwner[_nftContract][tokenIds[i]];

            //return staked tokens
            IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    //ranking view function
    function getRank(address _nftContract, uint256 tokenId) public view returns(uint8){
        require(stakableNFT[_nftContract], "Not stakable contract");
        require(stakedOwner[_nftContract][tokenId] != address(0), "Not staked");

        uint stakedTimestamp = stakedTokenTime[_nftContract][tokenId];
        require(stakedTimestamp!=0, "Not staked");

        uint stakedDuration = block.timestamp - stakedTimestamp;

        for(uint8 i=0;i<maxRank[_nftContract];i++){
            if(stakedDuration < rankTime[_nftContract][i])
                return i;
        }
        return maxRank[_nftContract];
    }

    function getStakedOwner(address _nftContract, uint256 tokenId) public view returns(address){
        require(stakableNFT[_nftContract], "Not stakable contract");
        require(stakedOwner[_nftContract][tokenId] != address(0), "Not staked");

        return stakedOwner[_nftContract][tokenId];
    }

    //admin functions
    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function changeOwnership(address _newOwner) public ownerOnly {
        owner = _newOwner;
    }

    function setPaused(bool _pause) public ownerOnly {
        paused = _pause;
    }

    function addStakableNFT(address _nftContract) private {
        require(ERC165(_nftContract).supportsInterface(type(IERC721).interfaceId), "Not a ERC721 contract");
        stakableNFT[_nftContract] = true;
    }

    function setDisallowNewStake(address _nftContract, bool _state) public ownerOnly {
        require(stakableNFT[_nftContract], "Not a stakable contract");
        disallowNewStaking[_nftContract] = _state;
    }

    function setRanking(address _nftContract, uint[] memory _rankTime) public ownerOnly {
        if(!stakableNFT[_nftContract]){
            addStakableNFT(_nftContract);
        }

        //check _rankTime is monotonic increasing
        for(uint i=1;i<_rankTime.length;i++){
            require(_rankTime[i] > _rankTime[i-1], "Not monotonic");
        }

        rankTime[_nftContract] = _rankTime;
        maxRank[_nftContract] = (uint8)(_rankTime.length);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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