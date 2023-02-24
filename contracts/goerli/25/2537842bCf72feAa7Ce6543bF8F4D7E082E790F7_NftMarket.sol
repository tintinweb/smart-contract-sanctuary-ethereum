// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "IERC20.sol";
import "IERC721.sol";

// set Noetsi token address trough Nft owner
// get state
interface Inoetsi {
    function getBondState(uint256 _bondNumber) external view returns (uint256);
}

interface InoetsiNFT {
    function ownerExt() external view returns (address);
}

contract NftMarket is Ownable {
    enum ListedState {
        notListed,
        listed
    }

    struct SecondarySell {
        address nftOwner;
        address currencyTokenAddress;
        uint256 ask;
        address bidderAddress;
        uint256 bid;
        ListedState listedState;
    }
    SecondarySell secondarySell;

    mapping(address => mapping(uint256 => SecondarySell)) public getSellInfo;
    address[] allowedTokens;
    event addedToAllowed(address token);
    event deletedFromAllowed(address token);
    event askCreated(
        address nftAddress,
        uint256 tokenId,
        address nftOwner,
        address currencyTokenAddress,
        uint256 ask,
        ListedState
    );
    event askChanged(address nftAddress, uint256 tokenId, uint256 ask);
    event askCanceled(address nftAddress, uint256 tokenId, ListedState);
    event askAccepted(address nftAddress, uint256 tokenId, ListedState);
    event bidCreated(
        address nftAddress,
        uint256 tokenId,
        address bidderAddress,
        uint256 bid
    );
    event bidCanceled(
        address nftAddress,
        uint256 tokenId,
        address bidderAddress,
        uint256 bid
    );
    event bidAccepted(address nftAddress, uint256 tokenId, ListedState);
    event bondIsClosed(address nftAddress, uint256 tokenId, ListedState);

    // ---- function adds token to list of allowed to collaterate tokens

    function addAllowedToken(address _token) public onlyOwner {
        require(!isTokenAllowed(_token), "Token is already in the list");
        allowedTokens.push(_token);
        emit addedToAllowed(_token);
    }

    // ---- function turns token address in list to 0x0000000...00. Beter change it to remove address later

    function deleteAllowedToken(address _token) public onlyOwner {
        require(isTokenAllowed(_token), "Token is not in the list");
        for (
            uint256 listIndex = 0;
            listIndex < allowedTokens.length;
            listIndex++
        )
            if (allowedTokens[listIndex] == _token) {
                delete allowedTokens[listIndex];
            }
        emit deletedFromAllowed(_token);
    }

    // ---- function checks if the token is in allowedToken list

    function isTokenAllowed(address _token) public view returns (bool) {
        for (
            uint256 listIndex = 0;
            listIndex < allowedTokens.length;
            listIndex++
        )
            if (allowedTokens[listIndex] == _token) {
                return true;
            }
        return false;
    }

    function getAllowedTokenList() public view returns (address[] memory) {
        return allowedTokens;
    }

    function getBondState(uint256 _tokenId, address _nftAddress)
        public
        view
        returns (uint256)
    {
        address parentContract;
        parentContract = InoetsiNFT(_nftAddress).ownerExt();
        return Inoetsi(parentContract).getBondState(_tokenId);
    }

    function changeStateToNotListed(uint256 _tokenId, address _tokenAddress)
        external
    {
        require(
            getBondState(_tokenId, _tokenAddress) != 2,
            "You can't change the state of an active bond"
        );
        getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
            .notListed;
    }

    function createAsk(
        uint256 _tokenId,
        address _tokenAddress,
        address _currencyTokenAddress,
        uint256 _ask
    ) public {
        require(
            getBondState(_tokenId, _tokenAddress) == 2,
            "You can't sell a closed bond"
        );
        require(
            isTokenAllowed(_tokenAddress),
            "The token is currently prohibited from being sold on this market."
        );
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.notListed,
            "Bond is already listed"
        );
        secondarySell = SecondarySell(
            msg.sender,
            _currencyTokenAddress,
            _ask,
            0x0000000000000000000000000000000000000000,
            0,
            ListedState.listed
        );
        getSellInfo[_tokenAddress][_tokenId] = secondarySell;

        IERC721(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        emit askCreated(
            _tokenAddress,
            _tokenId,
            msg.sender,
            _currencyTokenAddress,
            _ask,
            ListedState.listed
        );
    }

    function changeAsk(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _ask
    ) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        require(
            msg.sender == getSellInfo[_tokenAddress][_tokenId].nftOwner,
            "You are not NFT owner"
        );

        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            getSellInfo[_tokenAddress][_tokenId].ask = _ask;
            emit askChanged(_tokenAddress, _tokenId, _ask);
        }
    }

    function cancelAsk(uint256 _tokenId, address _tokenAddress) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        require(
            msg.sender == getSellInfo[_tokenAddress][_tokenId].nftOwner,
            "You are not NFT owner"
        );
        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            IERC721(_tokenAddress).transferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit askCanceled(_tokenAddress, _tokenId, ListedState.notListed);
        }
    }

    function acceptAsk(uint256 _tokenId, address _tokenAddress) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            IERC20(getSellInfo[_tokenAddress][_tokenId].currencyTokenAddress)
                .transferFrom(
                    msg.sender,
                    getSellInfo[_tokenAddress][_tokenId].nftOwner,
                    getSellInfo[_tokenAddress][_tokenId].ask
                );
            IERC721(_tokenAddress).transferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit askAccepted(_tokenAddress, _tokenId, ListedState.notListed);
        }
    }

    function createBid(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _bid
    ) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        require(
            _bid > getSellInfo[_tokenAddress][_tokenId].bid,
            "Bond has a greater bid"
        );
        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            // If this bond previously had a lower bid that was surpassed by a new one, then transfer the previous bid to its creator
            if (getSellInfo[_tokenAddress][_tokenId].bid > 0) {
                IERC20(
                    getSellInfo[_tokenAddress][_tokenId].currencyTokenAddress
                ).transfer(
                        getSellInfo[_tokenAddress][_tokenId].bidderAddress,
                        getSellInfo[_tokenAddress][_tokenId].bid
                    );
            }

            IERC20(getSellInfo[_tokenAddress][_tokenId].currencyTokenAddress)
                .transferFrom(msg.sender, address(this), _bid);
            getSellInfo[_tokenAddress][_tokenId].bid = _bid;
            getSellInfo[_tokenAddress][_tokenId].bidderAddress = msg.sender;

            emit bidCreated(_tokenAddress, _tokenId, msg.sender, _bid);
        }
    }

    function cancelBid(uint256 _tokenId, address _tokenAddress) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        require(
            msg.sender == getSellInfo[_tokenAddress][_tokenId].bidderAddress,
            "You are not the owner of the bid"
        );
        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            IERC20(getSellInfo[_tokenAddress][_tokenId].currencyTokenAddress)
                .transfer(msg.sender, getSellInfo[_tokenAddress][_tokenId].bid);
            getSellInfo[_tokenAddress][_tokenId].bid = 0;
            getSellInfo[_tokenAddress][_tokenId]
                .bidderAddress = 0x0000000000000000000000000000000000000000;
            emit bidCanceled(
                _tokenAddress,
                _tokenId,
                0x0000000000000000000000000000000000000000,
                0
            );
        }
    }

    function acceptBid(uint256 _tokenId, address _tokenAddress) public {
        require(
            getSellInfo[_tokenAddress][_tokenId].listedState ==
                ListedState.listed,
            "Bond is not listed"
        );
        require(
            msg.sender == getSellInfo[_tokenAddress][_tokenId].nftOwner,
            "You are not NFT owner"
        );
        if (getBondState(_tokenId, _tokenAddress) != 2) {
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;
            emit bondIsClosed(_tokenAddress, _tokenId, ListedState.notListed);
        } else {
            IERC721(_tokenAddress).transferFrom(
                address(this),
                getSellInfo[_tokenAddress][_tokenId].bidderAddress,
                _tokenId
            );
            IERC20(getSellInfo[_tokenAddress][_tokenId].currencyTokenAddress)
                .transfer(msg.sender, getSellInfo[_tokenAddress][_tokenId].bid);
            getSellInfo[_tokenAddress][_tokenId].listedState = ListedState
                .notListed;

            emit bidAccepted(_tokenAddress, _tokenId, ListedState.notListed);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

import "IERC165.sol";

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