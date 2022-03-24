pragma solidity 0.8.10;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./libraries/SafeERC20.sol";

/// @title   King Token Distributor
/// @notice  Distributes King tokens for Incooom Genesis and Kings Gala
/// @author  JeffX
contract KingTokenDistributor {
    using SafeERC20 for IERC20;

    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if ID has already been claimed
    error IDAlreadyClaimed();

    /// STATE VARIABLES ///

    /// @notice King Token
    address public immutable kingToken;
    /// @notice Incooom Genesis
    address public immutable incooomGenesis;
    /// @notice Kings Gala
    address public immutable kingsGala;
    /// @notice Owner
    address public immutable owner;

    /// @notice Amount of King per Genesis
    uint256 public constant kingPerGenesis = 3333000000000000000000;
    /// @notice Amount of King per King's Gala
    uint256 public constant kingPerGala = 3690000000000000000000;

    /// @notice Genesis ID to if King has been claimed for
    mapping(uint256 => bool) public genesisIDClaimed;
    /// @notice King's Gala ID to if King has been claimed for
    mapping(uint256 => bool) public kingsGalaIDClaimed;

    /// CONSTRUCTOR ///

    /// @param _kingToken      Address of King token
    /// @param _incoomGenesis  Address of Incoom Genesis
    /// @param _kingsGala      Address of King's Gala
    /// @param _owner          Address of owner
    constructor(
        address _kingToken,
        address _incoomGenesis,
        address _kingsGala,
        address _owner
    ) {
        kingToken = _kingToken;
        incooomGenesis = _incoomGenesis;
        kingsGala = _kingsGala;
        owner = _owner;
    }

    /// USER FUNCTION ///

    /// @notice               Claims King for Genesis and King's Gala tokens
    /// @param _genesisIDs    Array of IDs for Genesis
    /// @param _kingsGalaIDs  Array of IDs for King's Gala
    /// @param _to            Address where King will be sent
    function claim(
        uint256[] calldata _genesisIDs,
        uint256[] calldata _kingsGalaIDs,
        address _to
    ) external {
        uint256 kingToSend;

        if(_genesisIDs.length > 0) {
            kingToSend += claimForGenesis(_genesisIDs);
        }

        if(_kingsGalaIDs.length > 0) {
            kingToSend += claimForKingsGala(_kingsGalaIDs);
        }

        if(kingToSend > 0) {
            IERC20(kingToken).safeTransfer(_to, kingToSend);
        }
    }

    /// PRIVATE FUNCTIONS ///

    /// @notice              Returns amount of King to be sent for Genesis tokens if no revert
    /// @param _ids          Array of IDs for Genesis
    /// @return kingToSend_  King to send for `_ids `
    function claimForGenesis(uint256[] calldata _ids) private returns (uint256 kingToSend_) {
        for (uint256 i; i < _ids.length; ++i) {
            if (IERC721(incooomGenesis).ownerOf(_ids[i]) != msg.sender)
                revert NotOwner();
            if (genesisIDClaimed[_ids[i]] == true) revert IDAlreadyClaimed();
            genesisIDClaimed[_ids[i]] = true;
        }

        return kingPerGenesis * _ids.length;
    }

    /// @notice              Returns amount of King to be sent for King's Gala tokens if no revert
    /// @param _ids          Array of IDs for King's Gala
    /// @return kingToSend_  King to send for `_ids `
    function claimForKingsGala(uint256[] calldata _ids) private returns (uint256 kingToSend_) {
        for (uint256 i; i < _ids.length; ++i) {
            if (IERC721(kingsGala).ownerOf(_ids[i]) != msg.sender)
                revert NotOwner();
            if (kingsGalaIDClaimed[_ids[i]] == true) revert IDAlreadyClaimed();
            kingsGalaIDClaimed[_ids[i]] = true;
        }

        return kingPerGala * _ids.length;
    }

    /// @notice         Owner of contracts transfers specified token
    /// @param _token   Address of token being send
    /// @param _to      Address where `_token` is being sent
    /// @param _amount  Amount of `_token` that is being sent
    function transferToken(address _token, address _to, uint256 _amount) external {
        if(msg.sender != owner) revert NotOwner();
        IERC20(_token).safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;

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