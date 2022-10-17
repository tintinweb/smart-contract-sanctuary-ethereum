/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../interface.sol";
import { Errors } from "./Errors.sol";

library ValidateLogic {
    function checkDepositPara(
        address game,
        uint[] memory toolIds,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle
    ) public view {
        require(
            IERC721Upgradeable(game).supportsInterface(0x80ac58cd) &&
            totalAmount > (amountPerDay * cycle / 1 days) &&
            totalAmount > minPay &&
            (cycle > 0 && cycle <= 365 days) &&
            toolIds.length > 0 &&
            amountPerDay > 0 &&
            totalAmount > 0 &&
            minPay > 0,
            Errors.VL_DEPOSIT_PARAM_INVALID
        );
    }

    function checkEditPara(
        address editor,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        uint internalId,
        mapping(uint => ICCAL.DepositAsset) storage assetMap
    ) external view {
        ICCAL.DepositAsset memory asset = assetMap[internalId];
        require(
            totalAmount > (amountPerDay * cycle / 1 days) &&
            totalAmount > minPay &&
            (cycle > 0 && cycle <= 365 days) &&
            amountPerDay > 0 &&
            totalAmount > 0 &&
            minPay > 0,
            Errors.VL_EDIT_PARAM_INVALID
        );

        require(
            block.timestamp < asset.depositTime + asset.cycle &&
            asset.status == ICCAL.AssetStatus.INITIAL &&
            asset.holder == editor,
            Errors.VL_EDIT_CONDITION_NOT_MATCH
        );
    }

    function checkBorrowPara(
        uint internalId,
        uint amountPerDay,
        uint totalAmount,
        uint minPay,
        uint cycle,
        mapping(uint => ICCAL.DepositAsset) storage assetMap
    ) public view returns(bool) {
        ICCAL.DepositAsset memory asset = assetMap[internalId];
        if (
            asset.depositTime + asset.cycle <= block.timestamp ||
            asset.status != ICCAL.AssetStatus.INITIAL ||
            asset.internalId != internalId
        ) {
            return false;
        }
        // prevent depositor change data before borrower freeze token
        if (asset.amountPerDay != amountPerDay || asset.totalAmount != totalAmount || asset.minPay != minPay || asset.cycle != cycle) {
            return false;
        }
        return true;
    }

    function checkWithdrawTokenPara(
        address user,
        uint16 chainId,
        uint internalId,
        uint borrowIdx,
        mapping(address => ICCAL.InterestInfo[]) storage pendingWithdraw
    ) public view returns(bool, uint) {
        ICCAL.InterestInfo[] memory list = pendingWithdraw[user];
        uint len = list.length;
        if (len < 1) {
            return (false, 0);
        }

        for (uint i = 0; i < len;) {
            if (
                list[i].borrowIndex == borrowIdx &&
                list[i].chainId == chainId &&
                list[i].internalId == internalId 
            ) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }

        return (false, 0);
    }

    function calcCost(uint amountPerDay, uint time, uint min, uint max) external pure returns(uint) {
        uint cost = time * amountPerDay / 1 days;
        if (cost <= min) {
            return min;
        } else {
            return cost > max ? max : cost;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 *  - L = Logic
 *  - VL = ValidationLogic
 *  - P = Privilege
 *  - SET = Configure
 *  - LZ = layerzero
 */

library Errors {
  string public constant VL_TOKEN_NOT_SUPPORT = "1";
  string public constant VL_TOKEN_NOT_MATCH_CREDIT = "2";
  string public constant VL_DEPOSIT_PARAM_INVALID = "3";
  string public constant VL_EDIT_PARAM_INVALID = "4";
  string public constant VL_EDIT_CONDITION_NOT_MATCH = "5";
  string public constant VL_BORROW_ALREADY_FREEZE = "6";
  string public constant VL_BORROW_PARAM_NOT_MATCH = "7";
  string public constant VL_CREDIT_NOT_VALID = "8";
  string public constant VL_REPAY_CONDITION_NOT_MATCH = "9";
  string public constant VL_WITHDRAW_ASSET_CONDITION_NOT_MATCH = "10";
  string public constant VL_LIQUIDATE_NOT_EXPIRED = "11";
  string public constant VL_WITHDRAW_TOKEN_PARAM_NOT_MATCH = "12";
  string public constant VL_REPAY_CREDIT_AMOUNT_0 = "13";
  string public constant VL_REPAY_CREDIT_AMOUNT_TOO_LOW = "14";
  string public constant VL_REPAY_CREDIT_NO_NEED = "15";
  string public constant VL_USER_NOT_IN_CREDIT = "16";
  string public constant VL_RELEASE_TOKEN_CONDITION_NOT_MATCH = "17";

  string public constant P_ONLY_AUDITOR = "51";
  string public constant P_CALLER_MUST_BE_BRIDGE = "52";

  string public constant SET_FEE_TOO_LARGE = '55';
  string public constant SET_VAULT_ADDRESS_INVALID = '56';

  string public constant LZ_NOT_OTHER_CHAIN = "60";
  string public constant LZ_GAS_TOO_LOW = "61";
  string public constant LZ_BAD_SENDER = "62";
  string public constant LZ_BAD_REMOTE_ADDR = "63";
  string public constant LZ_BACK_FEE_FAILED = "64";
  string public constant LZ_ONLY_BRIDGE = "65";

  string public constant L_INVALID_REQ = "80";
}

/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICreditSystem {
    function getCCALCreditLine(address user) external returns(uint);
    function getState(address user) external returns(bool, bool);
}

interface ICCAL {
    enum Operation { BORROW, REPAY, LIQUIDATE }

    enum AssetStatus { INITIAL, BORROW, REPAY, WITHDRAW, LIQUIDATE }

    struct TokenInfo {
        uint8 decimals;
        bool active;
        bool stable;
    }

    struct DepositAsset {
        uint cycle;
        uint minPay;
        uint borrowTime;
        uint depositTime;
        uint totalAmount;
        uint amountPerDay;
        uint internalId;
        uint borrowIndex;
        address borrower;
        address token;
        address game;
        address holder;
        AssetStatus status;
        uint[] toolIds;
    }

    struct FreezeTokenInfo {
        address operator;
        bool useCredit;
        uint amount;
        address token;
    }

    struct InterestInfo {
        uint internalId;
        uint16 chainId;
        uint amount;
        uint borrowIndex;
        address token;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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