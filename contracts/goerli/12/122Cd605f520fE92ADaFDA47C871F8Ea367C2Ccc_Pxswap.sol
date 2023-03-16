// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import {SwapData} from "./SwapData.sol";
import {Ownable} from "./utils/Ownable.sol";
import {IERC721} from "./utils/IERC721.sol";
import {HandleERC20} from "./utils/HandleERC20.sol";
import {HandleERC721} from "./utils/HandleERC721.sol";
import {ERC721Holder} from "./utils/ERC721Holder.sol";

//   ______   __  __     ______     __     __     ______     ______
//  /\  == \ /\_\_\_\   /\  ___\   /\ \  _ \ \   /\  __ \   /\  == \
//  \ \  _-/ \/_/\_\/_  \ \___  \  \ \ \/ ".\ \  \ \  __ \  \ \  _-/
//   \ \_\     /\_\/\_\  \/\_____\  \ \__/".~\_\  \ \_\ \_\  \ \_\
//    \/_/     \/_/\/_/   \/_____/   \/_/   \/_/   \/_/\/_/   \/_/

/**
 * @title pxswap
 * @author pxswap (https://github.com/pxswap-xyz/pxswap/blob/main/src/Pxswap.sol)
 * @author Ali Konuk - @alikonuk1
 * @dev This contract is for buying, selling and swapping non-fungible tokens (NFTs)
 * @dev Please reach out to [email protected] if you find any issues
 */
contract Pxswap is SwapData, Ownable, HandleERC20, HandleERC721, ERC721Holder {
    /////////////////////////////////////////////
    //                 Errors
    /////////////////////////////////////////////

    error Unauthorized();
    error NotActive();
    error NotEnoughEth();

    /////////////////////////////////////////////
    //                 Events
    /////////////////////////////////////////////

    event PutSwap(uint256 indexed id);
    event CancelSwap(uint256 indexed id);
    event AcceptSwap(uint256 indexed id);

    /////////////////////////////////////////////
    //                 Storage
    /////////////////////////////////////////////

    Swap[] public swaps;

    address public protocol;
    address public pxNft;
    uint256 public flatFee;
    uint256 public discountedFee;
    uint256 public fee;
    bool public mutex;

    /////////////////////////////////////////////
    //                  Swap
    /////////////////////////////////////////////

    /**
    * @dev Creates a new swap by the seller with the specified NFTs and tokens offered.
    * @param nftsGiven Array of addresses of the NFTs given by the seller.
    * @param idsGiven Array of IDs of the NFTs given by the seller.
    * @param nftsWanted Array of addresses of the NFTs wanted by the seller.
    * @param buyer The address of the buyer for the swap.
    * @param tokenWanted The address of the ERC20 token wanted by the seller.
    * @param amount The amount of ERC20 tokens wanted by the seller.
    * @param ethAmount The amount of ether wanted by the seller.
    * Emits a {PutSwap} event indicating the creation of the swap and its ID.
    */
    function putSwap(
        address[] memory nftsGiven,
        uint256[] memory idsGiven,
        address[] memory nftsWanted,
        address buyer,
        address tokenWanted,
        uint256 amount,
        uint256 ethAmount
    ) external noReentrancy {
        transferNft(nftsGiven, msg.sender, address(this), nftsGiven.length, idsGiven);

        swaps.push(
            Swap({
                active: true,
                seller: msg.sender,
                buyer: buyer,
                giveNft: nftsGiven,
                giveId: idsGiven,
                wantNft: nftsWanted,
                wantToken: tokenWanted,
                amount: amount,
                ethAmount: ethAmount
            })
        );

        uint256 id = swaps.length - 1;

        emit PutSwap(id);
    }

    /**
    * @dev Allows the seller to cancel an active swap and transfer the ERC721 tokens back to the seller.
    * @param id The ID of the swap to be cancelled.
    */
    function cancelSwap(uint256 id) external noReentrancy {
        Swap storage swap = swaps[id];
        address sseller = swap.seller;

        if(msg.sender != sseller){
            revert Unauthorized();
        }
        if(swap.active == false){
            revert NotActive();
        }

        swap.active = false;

        transferNft(swap.giveNft, address(this), sseller, swap.giveNft.length, swap.giveId);

        emit CancelSwap(id);
    }

    /**
    * @dev Allows the buyer to accept a swap by ID and transfer the assets to the respective parties.
    * @param id The ID of the swap to be accepted.
    * @param tokenIds An array of token IDs for ERC721 tokens.
    */
    function acceptSwap(uint256 id, uint256[] memory tokenIds) public payable noReentrancy {
        Swap storage swap = swaps[id];

        if(swap.active == false){
            revert NotActive();
        }

        if(swap.buyer != address(0)){
            if(msg.sender != swap.buyer){
                revert Unauthorized();
            }
        }

        swap.active = false;

        // variable fee
        uint256 fee_;
        if(IERC721(pxNft).balanceOf(msg.sender) != 0){
            fee_ = discountedFee;
        } else {
            fee_ = fee;
        }

        address[] memory swantNft = swap.wantNft;
        address[] memory sgiveNft = swap.giveNft;
        uint256[] memory sgiveId = swap.giveId;
        address sseller = swap.seller;
        address swantToken = swap.wantToken;
        uint256 lenWantNft = swantNft.length;
        uint256 sethAmount = swap.ethAmount;
        uint256 samount = swap.amount;

        if(lenWantNft != 0){
            transferNft(swantNft, msg.sender, sseller, lenWantNft, tokenIds);
        }

        if(swantToken != address(0)){
            uint256 protocolTokenFee = samount / fee_;
            uint256 finalTokenAmount = samount - protocolTokenFee;

            transferToken(swantToken, msg.sender, sseller, protocol, finalTokenAmount, protocolTokenFee);
        }

        if(sethAmount != 0){
            if(msg.value < sethAmount){
                revert NotEnoughEth();
            }
            uint256 protocolEthFee = msg.value / fee_;
            uint256 finalEthAmount = sethAmount - protocolEthFee;

            (bool sent1,) = address(sseller).call{value: finalEthAmount}("");
            require(sent1, "!Call");

            (bool sent2,) = protocol.call{value: protocolEthFee}("");
            require(sent2, "!Call");
        }

        if(lenWantNft != 0 && swantToken == address(0) && sethAmount == 0){
            if(msg.value < flatFee){
                revert NotEnoughEth();
            }

            (bool sent,) = protocol.call{value: flatFee}("");
            require(sent, "!Call");
        }

        transferNft(sgiveNft, address(this), msg.sender, sgiveNft.length, sgiveId);

        emit AcceptSwap(id);
    }

    /////////////////////////////////////////////
    //                  Admin
    /////////////////////////////////////////////

    /**
     * @dev Function to set the protocol address.
     * @param protocol_ The address of the protocol.
     */
    function setProtocol(address protocol_) external onlyOwner {
        assembly {
            sstore(protocol.slot, protocol_)
        }
    }

    /**
     * @dev Allows the contract owner to set the transaction fee.
     * @param fee_ The new transaction fee.
     */
    function setFee(uint256 fee_) external onlyOwner {
        assembly {
            sstore(fee.slot, fee_)
        }
    }

    /**
     * @dev Allows the contract owner to set the discounted transaction fee.
     * @param discountedFee_ The new discounted transaction fee.
     */
    function setDiscountedFee(uint256 discountedFee_) external onlyOwner {
        assembly {
            sstore(discountedFee.slot, discountedFee_)
        }
    }
    
    /**
     * @dev Allows the contract owner to set the flat transaction fee.
     * @param flatFee_ The new flat transaction fee.
     */
    function setFlatFee(uint256 flatFee_) external onlyOwner {
        assembly {
            sstore(flatFee.slot, flatFee_)
        }
    }

    /**
     * @dev Allows the contract owner to set the pxswap's nft contract address.
     * @param pxNft_ pxswap's nft contract address.
     */
    function setPxNft(address pxNft_) external onlyOwner {
        assembly {
            sstore(pxNft.slot, pxNft_)
        }
    }

    /////////////////////////////////////////////
    //                Modifiers
    /////////////////////////////////////////////

    modifier noReentrancy() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        require(!mutex, "lol!");
        mutex = true;
    }

    function _nonReentrantAfter() internal {
        mutex = false;
    }

    /////////////////////////////////////////////
    //                Getter
    /////////////////////////////////////////////

    /**
    * @dev Returns the number of swaps in the contract.
    * @return The length of the swaps array.
    */
    function getLength() external view returns (uint256) {
        return swaps.length;
    }

    /**
    * @dev Returns the details of a specific swap by its ID.
    * @param id The ID of the swap to be retrieved.
    * @return The details of the swap as a memory struct.
    */
    function getSwap(uint256 id) external view returns (Swap memory) {
        return swaps[id];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

contract SwapData {
    struct Swap {
        uint256[] giveId;
        uint256 amount;
        uint256 ethAmount;
        address seller;
        address buyer;
        address[] giveNft;
        address[] wantNft;
        address wantToken;
        bool active;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity 0.8.19;

import "./IERC721Receiver.sol";

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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "./IERC20.sol";

contract HandleERC20 {

    error NotSuccessful();

    function transferToken(address wantToken, address from, address to, address protocol, uint256 amount, uint256 fee)
        internal
    {
        IERC20 token = IERC20(wantToken);

        require(token.balanceOf(from) >= amount + fee, "Not enough balance");

        if(!(token.transferFrom(from, to, amount))){
            revert NotSuccessful();
        }
        if(!(token.transferFrom(from, protocol, fee))){
            revert NotSuccessful();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "./IERC721.sol";

contract HandleERC721 {
    function transferNft(address[] memory nft_, address from, address to, uint256 lenNft, uint256[] memory id)
        internal
    {
        for (uint256 i; i < lenNft;) {
            transferNft_(nft_[i], from, to, id[i]);
            unchecked {
                ++i;
            }
        }
    }

    function transferNft_(address nft_, address from, address to, uint256 id) internal {
        IERC721 nft = IERC721(nft_);
        require(nft.balanceOf(from) >= 1);
        nft.safeTransferFrom(from, to, id);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.19;

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
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.19;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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

pragma solidity 0.8.19;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "!owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "!zero");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}