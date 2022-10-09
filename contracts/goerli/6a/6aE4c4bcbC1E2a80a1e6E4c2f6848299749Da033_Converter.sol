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

pragma solidity ^0.8.4;

interface IMoonCatAcclimator {
    /**
     * @dev rewrap several MoonCats from the old wrapper at once
     * Owner needs to call setApprovalForAll in old wrapper first.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     * @param _oldTokenIds an array holding the corresponding token ID
     *        in the old wrapper for each MoonCat to be rewrapped
     */
    function batchReWrap(uint256[] memory _rescueOrders, uint256[] memory _oldTokenIds) external;

    /**
     * @dev Take a list of unwrapped MoonCat rescue orders and wrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to rewrap
     */
    function batchWrap(uint256[] memory _rescueOrders) external;

    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) external payable;

    function makeAdoptionOfferToAddress(
        bytes5 catId,
        uint256 price,
        address to
    ) external;

    function giveCat(bytes5 catId, address to) external;

    function catOwners(bytes5 catId) external view returns (address);

    function rescueOrder(uint256 rescueIndex) external view returns (bytes5 catId);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IMoonCatsWrapped {
    function wrap(bytes5 catId) external;

    function _catIDToTokenID(bytes5 catId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index) external view returns (address owner);

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) external;

    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/punks/ICryptoPunks.sol";
import "../interfaces/punks/IWrappedPunk.sol";
import "../interfaces/mooncats/IMoonCatsWrapped.sol";
import "../interfaces/mooncats/IMoonCatsRescue.sol";
import "../interfaces/mooncats/IMoonCatAcclimator.sol";
import "../interfaces/weth/IWETH.sol";

library Converter {
    struct MoonCatDetails {
        bytes5[] catIds;
        uint256[] oldTokenIds;
        uint256[] rescueOrders;
    }

    /**
     * @dev converts uint256 to a bytes(32) object
     */
    function _uintToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
     * @dev converts address to a bytes(32) object
     */
    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function mooncatToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i],
                0,
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69
            );
        }
        // mint Acclimated​MoonCats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchWrap(moonCatDetails.rescueOrders);
    }

    function wrappedToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.oldTokenIds.length; i++) {
            // transfer the token to Acclimated​MoonCats to mint
            IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).safeTransferFrom(
                address(this),
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                moonCatDetails.oldTokenIds[i],
                abi.encodePacked(_uintToBytes(moonCatDetails.rescueOrders[i]), _addressToBytes(address(this)))
            );
        }
    }

    function mooncatToWrapped(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i],
                0,
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function acclimatedToWrapped(MoonCatDetails memory moonCatDetails) external {
        // unwrap Acclimated​MoonCats to get Mooncats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchUnwrap(moonCatDetails.rescueOrders);
        // Convert Mooncats to Wrapped Mooncats
        for (uint256 i = 0; i < moonCatDetails.rescueOrders.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract
            IMoonCatsRescue(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i],
                0,
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function cryptopunkToWrapped(address punkProxy, uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer the CryptoPunk to the userProxy
            ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).transferPunk(punkProxy, tokenIds[i]);
            // mint Wrapped CryptoPunk
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).mint(tokenIds[i]);
        }
    }

    function wrappedToCryptopunk(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).burn(tokenIds[i]);
        }
    }

    function ethToWeth(uint256 amount) external {
        bytes memory _data = abi.encodeWithSelector(IWETH.deposit.selector);
        (bool success, ) = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).call{value: amount}(_data);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function wethToEth(uint256 amount) external {
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(amount);
    }
}