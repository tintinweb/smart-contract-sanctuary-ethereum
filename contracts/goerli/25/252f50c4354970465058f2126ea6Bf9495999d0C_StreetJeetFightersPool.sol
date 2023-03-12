// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IStreetJeetFighters is IERC721, IERC721Enumerable {
    function maxMintCount() external view returns (uint256);

    function mintedCount() external view returns (uint256);

    function lappsedMintCount() external view returns (uint256);

    function mint(address to, uint256 price) external payable;

    function burn(uint256 tokenId) external;

    function burnedCount() external view returns(uint256);

    function mintPrice(uint256 tokenId) external view returns (uint256);

    function winTokenId() external view returns (uint256);

    function setGameOver(
        address winnerAcc,
        uint256 tokenId
    ) external returns (uint256);

    function isGameOver() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./IStreetJeetFighters.sol";

struct ClaimData {
    address account; // account to claim
    uint256 time; // claim time
    uint256 tokenId;
}

contract StreetJeetFightersPool {
    //event OnSell(address indexed account, uint256 count, uint256 eth);
    event OnTakePool(
        address indexed account,
        uint256 tokenId,
        uint256 poolEthCount
    );
    event OnGameOver(address indexed account, uint256 tokenId);

    IStreetJeetFighters public immutable nftContract;
    ClaimData _claimData;
    uint256 immutable claimTimerminutes;

    constructor(address nftContractAddress, uint256 claimTimerminutes_) {
        nftContract = IStreetJeetFighters(nftContractAddress);
        claimTimerminutes = claimTimerminutes_;
    }

    modifier gameNotOver() {
        require(!this.isGameOver(), "game is over");
        _;
    }

    receive() external payable {}

    function takePool(uint256 tokenId) external gameNotOver {
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "only owner of token can call this function"
        );
        _takePool(tokenId);
    }

    function takePoolFirstToken() external gameNotOver {
        require(nftContract.balanceOf(msg.sender) > 0, "has no tokens");
        _takePool(nftContract.tokenOfOwnerByIndex(msg.sender, 0));
    }

    function _takePool(uint256 tokenId) internal gameNotOver {
        if (_tryClaim()) return;
        nftContract.burn(tokenId);
        _claimData.account = msg.sender;
        _claimData.tokenId = tokenId;
        _claimData.time = block.timestamp + claimTimerminutes * 1 minutes;

        emit OnTakePool(msg.sender, tokenId, address(this).balance);
    }

    function claim() external {
        require(_claimData.account != address(0), "has no burn data");
        _tryClaim();
    }

    function _tryClaim() internal returns (bool) {
        if (_claimData.account == address(0)) return false;
        if (block.timestamp < _claimData.time) return false;
        sendEth(_claimData.account, address(this).balance);
        nftContract.setGameOver(_claimData.account, _claimData.tokenId);
        emit OnGameOver(_claimData.account, _claimData.tokenId);
        return true;
    }

    function sendEth(address addr, uint256 ethCount) internal {
        if (ethCount <= 0) return;
        (bool sent, ) = addr.call{value: ethCount}("");
        require(sent, "ethereum is not sent");
    }

    function claimLapsedSeconds() external view returns (uint256) {
        require(_claimData.account != address(0), "has no claim data");
        if (block.timestamp > _claimData.time) return 0;
        return _claimData.time - block.timestamp;
    }

    function claimAddress() external view returns (address) {
        return _claimData.account;
    }

    function claimTime() external view returns (uint256) {
        return _claimData.time;
    }

    function claimTokenId() external view returns (uint256) {
        return _claimData.tokenId;
    }

    function isGameOver() external view returns (bool) {
        return nftContract.isGameOver();
    }

    /*function ToJeetLikeAlways(uint256 count) external {
        require(!nftContract.isGameOver(), "game is over");
        require(count <= 8, "8 tokens max");
        require(
            count <= nftContract.balanceOf(msg.sender),
            "not enough tokens count"
        );
        uint256 percent = 40;
        if (count == 2) percent = 46;
        else if (count == 3) percent = 53;
        else if (count == 4) percent = 59;
        else if (count == 5) percent = 66;
        else if (count == 6) percent = 72;
        else if (count == 7) percent = 79;
        else if (count == 8) percent = 85;

        uint256 revertEth;

        for (uint256 i = 0; i < count; ++i) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, 0);
            revertEth += (nftContract.mintPrice(tokenId) * percent) / 100;
            nftContract.burn(tokenId);
        }

        sendEth(msg.sender, revertEth);
        emit OnSell(msg.sender, count, revertEth);
    }*/
}