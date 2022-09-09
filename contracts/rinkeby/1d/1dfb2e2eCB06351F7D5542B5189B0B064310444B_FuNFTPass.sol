// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: GPL-3.0

//======================================================================
//
//  #######                       #
//  #
//  #        #     #   # ###    ###      #####   # ####
//  #####    #     #   ##         #     #     #  ##    #
//  #        #     #   #          #     #     #  #     #
//  #        #    ##   #          #     #     #  #     #
//  #         #### #   #        #####    #####   #     #
//
//======================================================================

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IFuCatNFT } from "./interfaces/IFuCatNFT.sol";

contract FuNFTPass is Ownable, IERC721Receiver {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    struct TierInfo {
        // Tier: 0 1 2 3 4 5 ...
        uint256 tier;
        // The score of tier
        uint256 score;
        // The discount of tier, 0~100
        uint256 discount;
    }

    // Operator can modify the supported token list and token score
    address public operator;

    // The token impl standard ERC721
    IFuCatNFT public fuCatNFT;

    // The token impl standard ERC721,and nontransferable
    IERC721[] public badgeTokens;
    // Token address => if token has added to array
    mapping(address => bool) public isBadgeTokenListed;
    // Token address => score
    mapping(address => uint256) public badgeTokenScore;

    // Support tiers, level from hight to low
    // Eg: tiers[0]=0 tiers[1]=1 tiers[2]=2 tiers[3]=3 ...
    uint256[] public tiers;
    // Tier number => if tier has added to array
    mapping(uint256 => bool) public hasTierAdded;
    // Tier number => tier info
    mapping(uint256 => TierInfo) public tierInfos;

    // User address => token id
    mapping(address => uint256) public userStaked;
    // User address => score
    mapping(address => uint256) public userStakedScore;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event OperatorTransferred(address previousOperator, address newOperator);

    event FuCatNFTUpdated(address previewsFuCatNFT, address newFuCatNFT);

    event BadgeScoreUpdated(address badgeToken, uint256 score);

    event TierInfoUpdated(uint256 tier, uint256 score, uint256 discount);

    event Stake(address user, uint256 tokenId, uint256 tokenScore);
    event Unstake(address user, uint256 tokenId);

    event ChampionReceived(address operator, address from, uint256 tokenId, bytes data);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _fuCatNFT) {
        fuCatNFT = IFuCatNFT(_fuCatNFT);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyOperator() {
        require(_msgSender() == operator || _msgSender() == owner(), "Operatable: caller is not the operator");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function getTierInfo(uint256 score)
        public
        view
        returns (
            uint256 infoTier,
            uint256 infoScore,
            uint256 infoDiscount
        )
    {
        // Foreach tiers, compare with tier score
        // From High to low
        for (uint256 i = tiers.length; i > 0; i--) {
            uint256 tier = tiers[i - 1];
            TierInfo memory info = tierInfos[tier];
            if (score >= info.score) {
                infoTier = info.tier;
                infoDiscount = info.discount;
            }
        }
        infoScore = score;
    }

    // Query user profile(user score and tier)
    // If user does't have staked cat token, the score will be 0
    /// @return profileTier The user's tier
    /// @return profileScore The user's score
    /// @return profileDiscount The user's discount, range: 0~100
    function profileOf(address _user)
        public
        view
        returns (
            uint256 profileTier,
            uint256 profileScore,
            uint256 profileDiscount
        )
    {
        require(_user != address(0), "TokenId cannot be zero");
        profileScore = userStakedScore[_user];

        if (profileScore <= 0) {
            return (0, 0, 0);
        }

        for (uint256 i = 0; i < badgeTokens.length; i++) {
            // If the badge token is not listed, the score of badge is 0
            if (isBadgeTokenListed[address(badgeTokens[i])]) {
                if (badgeTokens[i].balanceOf(_user) > 0) {
                    profileScore += badgeTokenScore[address(badgeTokens[i])];
                }
            }
        }
        (profileTier, , profileDiscount) = getTierInfo(profileScore);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Operator address err");
        address oldOperator = operator;
        operator = _operator;
        emit OperatorTransferred(oldOperator, operator);
    }

    function setFuCatNFT(address _fuCatNFT) external onlyOperator {
        require(_fuCatNFT != address(0), "Address cannot be zero");
        address oldFuCatNFT = address(fuCatNFT);
        fuCatNFT = IFuCatNFT(_fuCatNFT);
        emit FuCatNFTUpdated(oldFuCatNFT, _fuCatNFT);
    }

    function setBadgeScore(address _token, uint256 score) external onlyOperator {
        require(_token != address(0), "Address cannot be zero");
        badgeTokenScore[_token] = score;
        // Add token to badgeTokens array
        if (!isBadgeTokenListed[_token]) {
            badgeTokens.push(IERC721(_token));
            isBadgeTokenListed[_token] = true;
        }

        emit BadgeScoreUpdated(_token, score);
    }

    // Update tier info, eg:
    //      arrayIndex  tier   score    discount
    //      tiers[0]    0       100     10
    //      tiers[1]    1       200     20
    //      tiers[2]    2       300     30
    //      tiers[3]    3       400     40
    function setTierInfo(
        uint256 _tier,
        uint256 _score,
        uint256 _discount
    ) external onlyOperator {
        // Add tier order: tiers[0]=0 tiers[1]=1 tiers[2]=2 tiers[3]=3 ...

        if (tiers.length == 0) {
            _tier = 0;
        } else {
            require(_tier <= tiers.length, "Tier error");
        }

        // Check tier info
        require(_discount < 100, "Tier discount error");

        tierInfos[_tier] = TierInfo({ tier: _tier, score: _score, discount: _discount });

        // Update tiers array
        if (!hasTierAdded[_tier]) {
            tiers.push(_tier);
            hasTierAdded[_tier] = true;
            // Sort tiers from high to low?
            // No sorting required
            //
        }
        emit TierInfoUpdated(_tier, _score, _discount);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    // Stake FuCatNFT
    function stake(uint256 _tokenId) external {
        require(_tokenId != 0, "TokenId cannot be zero");
        require(userStaked[_msgSender()] == 0, "Already staked");
        require(fuCatNFT.ownerOf(_tokenId) == _msgSender(), "Not owner of token");

        fuCatNFT.approve(address(this), _tokenId);

        // If token score is 0, it also able to stake
        uint256 tokenScore = fuCatNFT.tokenScore(_tokenId);

        fuCatNFT.safeTransferFrom(_msgSender(), address(this), _tokenId);

        userStaked[_msgSender()] = _tokenId;
        userStakedScore[_msgSender()] = tokenScore;

        emit Stake(_msgSender(), _tokenId, tokenScore);
    }

    // Unstake FuCatNFT
    function unstake(uint256 _tokenId) external {
        require(userStaked[_msgSender()] == _tokenId, "Not owner of token");

        fuCatNFT.safeTransferFrom(address(this), _msgSender(), _tokenId);

        // Delete the record
        userStaked[_msgSender()] = 0;
        userStakedScore[_msgSender()] = 0;

        emit Unstake(msg.sender, _tokenId);
    }

    // Selector for receiving ERC721 tokens
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        emit ChampionReceived(_operator, _from, _tokenId, _data);
        return this.onERC721Received.selector;
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Pure Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFuCatNFT is IERC721 {
    function tokenScore(uint256) external view returns (uint256);
}