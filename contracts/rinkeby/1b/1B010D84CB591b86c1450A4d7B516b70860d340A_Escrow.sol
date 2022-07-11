// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "./interface/ITransferProxy.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Escrow is ERC721Holder, ERC1155Receiver, ERC1155Holder {

    event Lended(bytes32 id, address lender, address nftAddress, uint256 tokenId, uint256 quantity);

    event Rented(bytes32 id, address renter, address nftAddress, uint256 tokenId, uint256 quantity);

    event Claimed(bytes32 id, address lender, address renter, address nftAddress, uint256 tokenId, uint256 quantity);

    event regained(bytes32 id, address lender, address nftAddress, uint256 tokenId, uint256 quantity);


    struct LendData {
        bytes32 lendId;
        address lender;
        address nftAddress;
        uint256 tokenId;
        uint256 maxduration;
        uint256 dailyRent;
        uint256 lendingQuantity;
        address paymentAddress;
        uint256 lendTime;
    }

    struct RentData {
        bytes32 lendedId;
        address renter;
        address lender;
        address nftAddress;
        uint256 tokenId;
        uint256 duration;
        uint256 rentedQuantity;
        uint256 rentedTime;
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    mapping(uint256 => bool) usedNonce;
    mapping(bytes32 => LendData) private lendingDetails;
    mapping(bytes32 => RentData) private rentalDetails;
    mapping(bytes32 => bool) public isValid;
    mapping(address=> mapping(address => mapping(uint256 => uint256))) private rentedQty;
    event OwnershipTransferred(address owner, address newOwner);
    event Signerchanged(address signer, address newSigner);

    address public owner;

    address public signer;

    uint256 public RentalFee;

    ITransferProxy public transferProxy;


    constructor(uint256 _platFee, ITransferProxy _transferProxy) {

        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = msg.sender;
        RentalFee = _platFee;
    }

    function changeSigner(address newSigner) external {
        require(newSigner != address(0), "signer: Invalid Address");
        signer = newSigner;
    }

    function tranferOwnership(address newOwner) external {
        require(newOwner != address(0), "signer: Invalid Address");
        owner = newOwner;
    }

    function setRentalFee(uint256 _platFee) external {
        RentalFee = _platFee;
    }

    function lend(LendData memory lendData, Sign calldata sign) external {
        require(!usedNonce[sign.nonce], "Nonce: invalid nonce");
        usedNonce[sign.nonce] = true;
        require(lendData.maxduration > 0, "Lend: lending duration must be greater than zero");
        require(lendData.dailyRent > 0, "Lend: daily rent must be greater than zero");
        require(lendData.nftAddress != address(0) && lendData.paymentAddress != address(0), "Lend: address should not be zero");
        verifySign(generateId(lendData.lender, lendData.tokenId, lendData.lendingQuantity, lendData.nftAddress, lendData.paymentAddress), msg.sender, sign);
        lendData.lendTime = block.timestamp;
        lendData.lender = msg.sender;
        lendData.lendId = generateId(lendData.lender, lendData.tokenId, lendData.lendingQuantity, lendData.nftAddress, lendData.paymentAddress);
        isValid[lendData.lendId] = true; 
        lendingDetails[lendData.lendId] = lendData;
        uint8 nftType = getValidType(lendData.nftAddress);
        isApproved(nftType, lendData.nftAddress);
        safeTransfer(lendData.nftAddress, lendData.paymentAddress, lendData.lender, address(this), lendData.tokenId, lendData.lendingQuantity, nftType, 0, false);
        emit Lended(lendData.lendId, lendData.lender, lendData.nftAddress, lendData.tokenId, lendData.lendingQuantity);
    }

    function rent(bytes32 lendId, uint256 qty, uint256 duration, Sign calldata sign) external {
        require(!usedNonce[sign.nonce], "Nonce: invalid nonce");
        usedNonce[sign.nonce] = true;
        require(isValid[lendId],"rent: Invalid Id");
        require(duration > 0 && duration <= lendingDetails[lendId].maxduration, "rent: lending duration must be greater than zero or less than max duration");
        verifySign(generateId(msg.sender, lendingDetails[lendId].tokenId, qty, lendingDetails[lendId].nftAddress, lendingDetails[lendId].lender), msg.sender, sign);
        bytes32 rentId = (generateId(msg.sender, lendingDetails[lendId].tokenId, qty, lendingDetails[lendId].nftAddress, lendingDetails[lendId].lender));
        uint8 nftType = getValidType(lendingDetails[lendId].nftAddress);
        isApproved(nftType,lendingDetails[lendId].nftAddress);
        uint256 fee = getFees(lendingDetails[lendId].paymentAddress, lendingDetails[lendId].dailyRent, duration, qty);
        rentalDetails[rentId] = RentData(lendId, msg.sender, lendingDetails[lendId].lender, lendingDetails[lendId].nftAddress, lendingDetails[lendId].tokenId, duration, qty, block.timestamp);
        safeTransfer(lendingDetails[lendId].nftAddress, lendingDetails[lendId].paymentAddress, address(this), msg.sender, lendingDetails[lendId].tokenId, qty, nftType, fee, false);
        rentedQty[msg.sender][lendingDetails[lendId].nftAddress][lendingDetails[lendId].tokenId] = rentedQty[msg.sender][lendingDetails[lendId].nftAddress][lendingDetails[lendId].tokenId] + qty;
        lendingDetails[lendId].lendingQuantity -= qty;
        if(lendingDetails[lendId].lendingQuantity == 0) {isValid[lendId] = false; }
        emit Rented(rentId, lendingDetails[lendId].lender, msg.sender, lendingDetails[lendId].tokenId, qty);
    }

    function claim(bytes32 rentalId, Sign calldata sign) external {
        require(!usedNonce[sign.nonce], "Nonce: invalid nonce");
        usedNonce[sign.nonce] = true;
        verifySign(rentalId, msg.sender, sign);
        isExpired(rentalId);
        bytes32 lendId = rentalDetails[rentalId].lendedId;
        require(msg.sender == rentalDetails[rentalId].lender);
        rentedQty[rentalDetails[rentalId].renter][rentalDetails[rentalId].nftAddress][rentalDetails[rentalId].tokenId] -= rentalDetails[rentalId].rentedQuantity;
        uint8 nftType = getValidType(lendingDetails[lendId].nftAddress); 
        uint256 fee = getFees(lendingDetails[lendId].paymentAddress, lendingDetails[lendId].dailyRent, rentalDetails[rentalId].duration, rentalDetails[rentalId].rentedQuantity);
        require(IERC20(lendingDetails[lendId].paymentAddress).approve(address(transferProxy), fee),"IERC20: failed on Approval");
        safeTransfer(lendingDetails[lendId].nftAddress, lendingDetails[lendId].paymentAddress, rentalDetails[rentalId].renter, rentalDetails[rentalId].lender, rentalDetails[rentalId].tokenId, rentalDetails[rentalId].rentedQuantity, nftType, fee, true);
        if(lendingDetails[lendId].lendingQuantity == 0) isValid[lendId] = false;
        isValid[rentalId] = false;
        emit Claimed(rentalId, rentalDetails[rentalId].lender, rentalDetails[rentalId].renter, lendingDetails[lendId].nftAddress, rentalDetails[rentalId].tokenId, rentalDetails[rentalId].rentedQuantity);
    }

    function regain(bytes32 lendId, Sign calldata sign) external {
        require(isValid[lendId],"retain: Invalid Id");
        require(!usedNonce[sign.nonce], "Nonce: invalid nonce");
        usedNonce[sign.nonce] = true;
        verifySign(lendId, msg.sender, sign);
        require(msg.sender == lendingDetails[lendId].lender, "retain: caller doesn't have role");
        uint8 nftType = getValidType(lendingDetails[lendId].nftAddress);
        isApproved(nftType,lendingDetails[lendId].nftAddress);
        safeTransfer(lendingDetails[lendId].nftAddress, lendingDetails[lendId].paymentAddress, address(this), lendingDetails[lendId].lender,lendingDetails[lendId].tokenId, lendingDetails[lendId].lendingQuantity, nftType, 0, false);
        isValid[lendId] = false;
    }

    function isRented(address nftAddress, address account, uint256 tokenId, uint256 qty) external view returns(bool) {
        uint256 _rentedQty = rentedQty[account][nftAddress][tokenId];
        uint256 nftType = getValidType(nftAddress);
        if(nftType == 0) {
            return _rentedQty == 1;
        }
        if(nftType == 1 ) {
            uint256 balance = IERC1155(nftAddress).balanceOf(account, tokenId);
            if((balance - _rentedQty) >= qty)
            {
                return true;
            }
            else {
                return false;
            }
        }
        return false;
    }

        // bytes32 lendId;
        // address lender;
        // address nftAddress;
        // uint256 tokenId;
        // uint256 maxduration;
        // uint256 dailyRent;
        // uint256 lendingQuantity;
        // address paymentAddress;
        // uint256 lendTime;

    function getLendDetails(bytes32 id) external view returns(LendData memory, bool) {
        return (lendingDetails[id], isValid[id]);
    }
    
    function getrentDetails(bytes32 id) external view returns(RentData memory, bool) {
        return (rentalDetails[id], isValid[id]);
    }

    function generateId(address account, uint256 tokenId, uint256 qty, address nftAddress, address keyAddress) internal pure returns(bytes32 meomory){
        return keccak256(abi.encodePacked(account, tokenId, qty, nftAddress, keyAddress));
    }

    function getValidType(address nftAddress) internal view returns(uint8) {
        if (IERC165(nftAddress).supportsInterface(type(IERC721).interfaceId)) return 0;
        if (IERC165(nftAddress).supportsInterface(type(IERC1155).interfaceId)) return 1;
        return 99;
    }

    function isApproved(uint8 _type, address nftAddress) internal {
        
        if(_type == 0) {
            if(!IERC721(nftAddress).isApprovedForAll(address(this), address(transferProxy))) {
                IERC721(nftAddress).setApprovalForAll(address(transferProxy), true);
            }
        }
        if(_type == 1) {
            if(!IERC1155(nftAddress).isApprovedForAll(address(this), address(transferProxy))) {
                IERC1155(nftAddress).setApprovalForAll(address(transferProxy), true);
            }
        }
    }

    function safeTransfer(address nftAddress, address paymentAddress, address caller, address callee, uint256 tokenId, uint256 lendingAmount, uint8 nftType, uint256 amount, bool isClaim) internal {
        if(nftType == 0) {
            transferProxy.erc721safeTransferFrom(IERC721(nftAddress) , caller, callee, tokenId);
        }

        if(nftType == 1) {
            transferProxy.erc1155safeTransferFrom(IERC1155(nftAddress), caller, callee, tokenId, lendingAmount, "");
        }

        if(amount > 0) {
            if(isClaim) { 
                caller = msg.sender; 
                callee = address(this);
                uint256 fee = amount * RentalFee / 1000;
                amount -=fee;
                if( fee > 0) {
                transferProxy.erc20safeTransferFrom(IERC20(paymentAddress), callee, owner, fee);
                }

            }
            transferProxy.erc20safeTransferFrom(IERC20(paymentAddress), callee, caller, amount);
        }
    }

    function getFees(address token, uint256 dailyRent, uint256 duration, uint256 qty) internal view returns(uint256) {
       return (dailyRent * duration * qty) * 10 ** IERC20Metadata(token).decimals();
    }

    function isExpired(bytes32 rentId) internal view {
        require(rentalDetails[rentId].rentedTime + ((rentalDetails[rentId].duration) * 1 seconds) <= block.timestamp, "time not exceeds");
    }

    function verifySign(
        bytes32 id,
        address caller,
        Sign memory sign
    ) internal view {

        bytes32 hash = keccak256(
            abi.encodePacked(this, caller, id, sign.nonce)
        );
        require(
            owner ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }

}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

interface ITransferProxy {
    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;
    

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";