// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFT/ICrownNFT.sol";

contract Mining {
    uint256 public mintedQuantity;

    struct Mint {
        uint256 id;
        address owner;
        uint256 timestamp;
        uint256 amount;
        uint256 duration;
        uint256 contributeNFTId;
        uint256 receiveNFTId;
    }

    struct Package {
        uint8 id;
        uint256 amount;
        uint256 duration;
    }

    event Minted(
        uint256 indexed id,
        address indexed owner,
        uint256 amount,
        uint256 indexed duration,
        uint256 contributeNFTId,
        uint256 receiveNFTId
    );

    event Claimed(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 duration
    );

    address _WDAtokenAddress;
    address _owner;
    Package[3] packages;
    ICrownNFT CrownContract;
    // maps address of user to stake
    Mint[] vault;

    constructor(address _token) {
        _WDAtokenAddress = _token;
        _owner = msg.sender;
    }

    /** ============== TEST ONLY ================ */
    function setDuration(uint256 miningId, uint256 newDuration) public {
        vault[miningId].duration = newDuration;
    }

    function setCrownContract(address _CrownAddress) external {
        CrownContract = ICrownNFT(_CrownAddress);
    }

    uint256 maxPercentProposal = 10;

    function setMaxPercentProposal(uint256 percent) external {
        maxPercentProposal = percent;
    }

    address WinDaoAddress;

    function setWinDAOAddress(address _newWinDaoAddress) external {
        WinDaoAddress = _newWinDaoAddress;
    }

    uint256 unitToSecond = 60 * 60;

    function setToSecond(uint256 newUnit) external {
        unitToSecond = newUnit;
    }

    /** ============== END OF TEST ONLY ============== */

    function initialize() external {
        require(msg.sender == _owner, "Ownable: Not owner");
        packages[0].amount = 330000 * 10**18;
        packages[0].duration = 3; // MUST CHANGE TO 360
        packages[0].id = 0;
        packages[1].amount = 800000 * 10**18;
        packages[1].duration = 2; // MUST CHANGE TO 180
        packages[1].id = 1;
        packages[2].amount = 2000000 * 10**18;
        packages[2].duration = 1; // MUST CHANGE TO 90
        packages[2].id = 2;
    }

    function setProposal(uint256 percentChange, uint8 action) external {
        require(
            msg.sender == _owner || msg.sender == WinDaoAddress,
            "Ownable: Not owner"
        );
        require(percentChange <= maxPercentProposal, "Percentage too big");
        uint256 amountChangePackage1 = (packages[0].amount * percentChange) /
            100;
        uint256 amountChangePackage2 = (packages[1].amount * percentChange) /
            100;
        uint256 amountChangePackage3 = (packages[2].amount * percentChange) /
            100;
        if (action == 0) {
            packages[0].amount -= amountChangePackage1;
            packages[1].amount -= amountChangePackage2;
            packages[2].amount = amountChangePackage3;
        } else {
            packages[0].amount += amountChangePackage1;
            packages[1].amount += amountChangePackage2;
            packages[2].amount += amountChangePackage3;
        }
    }

    function getListPackage(uint256 nftId)
        external
        view
        returns (Package[3] memory)
    {
        Package[3] memory finalPackages = packages;

        if (nftId != 0) {
            ICrownNFT.CrownTraits memory nftDetail = CrownContract.getTraits(
                nftId
            );
            finalPackages[0].amount -= ((finalPackages[0].amount *
                nftDetail.reduce) / 100);
            finalPackages[1].amount -= ((finalPackages[1].amount *
                nftDetail.reduce) / 100);
            finalPackages[2].amount -= ((finalPackages[2].amount *
                nftDetail.reduce) / 100);
        }
        return finalPackages;
    }

    /**
     * @param _miningId: 0, 1, 2
     * @param _nftId: apply nft to reduce fee
     */
    function mint(uint256 _miningId, uint256 _nftId) external {
        require(CrownContract.totalSupply() < 5000, "Over Crown supply");
        Package memory finalPackage = packages[_miningId];
        if (_nftId != 0) {
            require(
                CrownContract.ownerOf(_nftId) == msg.sender,
                "Ownable: Not owner"
            );
            ICrownNFT.CrownTraits memory nftDetail = CrownContract.getTraits(
                _nftId
            );
            require(nftDetail.staked == false, "Crown staked");
            finalPackage.amount -= ((finalPackage.amount * nftDetail.reduce) /
                100);
        }

        uint256 allowance = IERC20(_WDAtokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= finalPackage.amount, "Over allowance WDA");
        IERC20(_WDAtokenAddress).transferFrom(
            msg.sender,
            address(this),
            finalPackage.amount
        );
        if (_nftId != 0) {
            CrownContract.stakeOrUnstake(_nftId, true);
        }
        // mint crown for this mining
        uint256 receiveTokenId = CrownContract.mintValidTarget(1);

        vault.push(
            Mint(
                mintedQuantity,
                msg.sender,
                block.timestamp,
                finalPackage.amount,
                finalPackage.duration,
                _nftId,
                receiveTokenId
            )
        );
        emit Minted(
            mintedQuantity,
            msg.sender,
            finalPackage.amount,
            finalPackage.duration,
            _nftId,
            receiveTokenId
        );
        mintedQuantity++;
    }

    function claim(uint256 _miningId) external {
        Mint memory minted = vault[_miningId];
        require(msg.sender == minted.owner, "Ownable: Not owner");
        uint256 lastTimeCheck = minted.timestamp;
        uint256 miningDuration = minted.duration;
        // phải đúng thời hạn mới claim được
        require(
            block.timestamp >=
                (lastTimeCheck + (miningDuration * unitToSecond)),
            "Mining locked"
        );
        // delete mining
        if (minted.contributeNFTId != 0) {
            CrownContract.stakeOrUnstake(minted.contributeNFTId, false);
        }
        delete vault[_miningId];
        //
        CrownContract.transferFrom(
            address(this),
            msg.sender,
            minted.receiveNFTId
        );
        emit Claimed(
            minted.id,
            minted.owner,
            minted.receiveNFTId,
            minted.amount,
            minted.duration
        );
        IERC20(_WDAtokenAddress).transfer(msg.sender, minted.amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(msg.sender == _owner, "Ownable: Not owner");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICrownNFT is IERC721, IERC721Enumerable {
    struct CrownTraits {
        uint256 reduce;
        uint256 aprBonus;
        uint256 lockDeadline;
        bool staked;
    }

    function getTraits(uint256) external view returns (CrownTraits memory);

    function mintValidTarget(uint256 number) external returns(uint256);

    function burn(uint256 tokenId) external;

    function stakeOrUnstake(uint256, bool) external;
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