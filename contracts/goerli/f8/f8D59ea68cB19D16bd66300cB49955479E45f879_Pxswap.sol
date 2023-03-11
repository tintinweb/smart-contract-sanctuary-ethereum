/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

contract SwapData {
    struct Swap {
        uint256[] giveId;
        uint256[] wantId;
        uint256 amount;
        uint256 ethAmount;
        address seller;
        address buyer;
        address[] giveNft;
        address[] wantNft;
        address wantToken;
        address vault;
        bool active;
    }

    struct LimitBuy {
        bool active;
        address buyer;
        address wantNft;
        uint256 wantId;
        uint256 price;
    }

    struct LimitSell {
        bool active;
        address seller;
        address[] giveNft;
        address vault;
        uint256[] giveId;
        uint256 price;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

contract HandleERC721 {
    function transferNft(address[] memory nft_, address from, address to, uint256 lenNft, uint256[] memory id)
        internal
    {
        for (uint256 i; i < lenNft;) {
            IERC721 nft = IERC721(nft_[i]);

            require(nft.balanceOf(from) >= 1);

            nft.safeTransferFrom(from, to, id[i]);

            unchecked {
                ++i;
            }
        }
    }

    function sTransferNft(address nft_, address from, address to, uint256 id) internal {
        IERC721 nft = IERC721(nft_);
        require(nft.balanceOf(from) >= 1);

        nft.safeTransferFrom(from, to, id);
    }

    /*     function approveNft(
        address[] memory nft_,
        address to,
        uint256 lenNft,
        uint256[] memory id
    ) internal {
        for (uint256 i; i < lenNft;) {
            IERC721 nft = IERC721(nft_[i]);

            nft.approve(to, id[i]);

            unchecked {
                ++i;
            }
        }
    } */
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

contract PxswapERC721Receiver is ERC721Holder {
    mapping(uint256 => address) private sentFrom;

    function onERC721Received(address from, address to, uint256 id, bytes memory data)
        public
        override
        returns (bytes4)
    {
        sentFrom[id] = from;
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _sentFrom(uint256 id) public view returns (address) {
        return sentFrom[id];
    }
}

contract SwapVault is HandleERC721, PxswapERC721Receiver {
    address px;

    constructor(address px_) {
        px = px_;
    }

    function fromVault(address[] memory nfts, address to, uint256[] memory ids) external onlyPx {
        transferNft(nfts, address(this), to, nfts.length, ids);
    }

    /////////////////////////////////////////////
    //                Modifiers
    /////////////////////////////////////////////

    modifier onlyPx() {
        require(msg.sender == px, "Only px!");
        _;
    }
}

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISwapVault {
    function toVault(address[] memory nfts, address from, uint256[] memory ids) external;

    function fromVault(address[] memory nfts, address to, uint256[] memory ids) external;
}

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

contract HandleERC20 {
    function transferToken(address wantToken, address from, address to, address protocol, uint256 amount, uint256 fee)
        internal
    {
        IERC20 token = IERC20(wantToken);

        require(token.balanceOf(from) >= amount + fee, "Not enough balance");

        require(token.transferFrom(from, to, amount), "transfer to to error");
        require(token.transferFrom(from, protocol, fee), "transfer to protocol error");
    }
}

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
contract Pxswap is SwapData, Ownable, HandleERC20, HandleERC721 {
    /////////////////////////////////////////////
    //                 Events
    /////////////////////////////////////////////

    event PutSwap(
        uint256 indexed id,
        address[] nftsGiven,
        uint256[] idsGiven,
        address[] nftsWanted,
        uint256[] idsWanted,
        address tokenWanted,
        uint256 amount,
        uint256 ethAmount
    );
    event CancelSwap(uint256 id);
    event AcceptSwap(uint256 id);
    event OpenLimitBuy(uint256 indexed id, address indexed wantNft, uint256 wantId, uint256 indexed price);
    event CancelBuyOrder(uint256 indexed id);
    event FillBuy(uint256 id, address seller, address buyer, uint256 price, uint256 fee);
    event OpenLimitSell(uint256 indexed id, address[] indexed giveNft, uint256[] giveId, uint256 indexed price);
    event CancelSellOrder(uint256 id);
    event FillSell(uint256 indexed id, address indexed buyer, address seller, uint256 indexed price, uint256 fee);
    event OfferP2P(
        uint256 indexed id,
        address indexed buyer,
        address[] nftsGiven,
        uint256[] idsGiven,
        address[] nftsWanted,
        uint256[] idsWanted,
        address tokenWanted,
        uint256 amount,
        uint256 ethAmount
    );
    event CancelP2P(uint256 indexed id);

    /////////////////////////////////////////////
    //                 Storage
    /////////////////////////////////////////////

    Swap[] public swaps;
    LimitBuy[] public limitBuys;
    LimitSell[] public limitSells;

    address public protocol;
    uint256 public fee = 100; // %1 fee
    bool public mutex;

    /////////////////////////////////////////////
    //                  Swap
    /////////////////////////////////////////////

    function putSwap(
        address[] memory nftsGiven,
        uint256[] memory idsGiven,
        address[] memory nftsWanted,
        uint256[] memory idsWanted,
        address tokenWanted,
        uint256 amount,
        address buyer,
        uint256 ethAmount
    ) external noReentrancy {
        SwapVault vault = new SwapVault(address(this));

        transferNft(nftsGiven, msg.sender, address(vault), nftsGiven.length, idsGiven);

        swaps.push(
            Swap({
                active: true,
                seller: msg.sender,
                buyer: buyer,
                giveNft: nftsGiven,
                giveId: idsGiven,
                wantNft: nftsWanted,
                wantId: idsWanted,
                wantToken: tokenWanted,
                amount: amount,
                vault: address(vault),
                ethAmount: ethAmount
            })
        );

        uint256 id = swaps.length - 1;

        emit PutSwap(id, nftsGiven, idsGiven, nftsWanted, idsWanted, tokenWanted, amount, ethAmount);
    }

    function cancelSwap(uint256 id) external noReentrancy {
        Swap storage swap = swaps[id];
        require(msg.sender == swap.seller, "Unauthorized call, cant cancel swap!");
        require(swap.active == true, "Swap is not active!");

        swap.active = false;

        ISwapVault vault = ISwapVault(swap.vault);
        vault.fromVault(swap.giveNft, msg.sender, swap.giveId);

        /*         transferNft(swap.giveNft, address(this), msg.sender, swap.giveNft.length, swap.giveId); */

        emit CancelSwap(id);
    }

    function acceptSwap(uint256 id, uint256[] memory tokenIds) public payable noReentrancy {
        Swap storage swap = swaps[id];
        require(swap.active == true, "Swap is not active!");
        swap.active = false;

        uint256 lenWantNft = swap.wantNft.length;
        uint256 sethAmount = swap.ethAmount;
        uint256 samount = swap.amount;
        address sseller = swap.seller;
        uint256 lenwantId = swap.wantId.length;
        address swantToken = swap.wantToken;

        ISwapVault vault = ISwapVault(swap.vault);

        if (lenWantNft != 0 && swantToken != address(0) && sethAmount != 0) {
            require(msg.value >= sethAmount, "Not enough Eth");

            if (lenwantId != 0) {
                transferNft(swap.wantNft, msg.sender, sseller, lenWantNft, swap.wantId);
            } else if (lenwantId == 0) {
                transferNft(swap.wantNft, msg.sender, sseller, lenWantNft, tokenIds);
            }

            vault.fromVault(swap.giveNft, msg.sender, swap.giveId);

            /*             transferNft(swap.giveNft, address(this), msg.sender, swap.giveNft.length, swap.giveId); */

            uint256 protocolTokenFee = samount / fee;
            uint256 finalTokenAmount = samount - protocolTokenFee;

            transferToken(swantToken, msg.sender, sseller, protocol, finalTokenAmount, protocolTokenFee);

            uint256 protocolEthFee = msg.value / fee;
            uint256 finalEthAmount = sethAmount - protocolEthFee;

            (bool sent1,) = address(sseller).call{value: finalEthAmount}("");
            require(sent1, "Call must return true");

            (bool sent2,) = protocol.call{value: protocolEthFee}("");
            require(sent2, "Call must return true");
        } else if (lenWantNft == 0 && swantToken != address(0) && sethAmount != 0) {
            require(msg.value >= sethAmount);

            uint256 protocolTokenFee = samount / fee;
            uint256 finalTokenAmount = samount - protocolTokenFee;

            transferToken(swantToken, msg.sender, sseller, protocol, finalTokenAmount, protocolTokenFee);

            uint256 protocolEthFee = msg.value / fee;
            uint256 finalEthAmount = sethAmount - protocolEthFee;

            (bool sent1,) = address(sseller).call{value: finalEthAmount}("");
            require(sent1, "Call must return true");

            (bool sent2,) = protocol.call{value: protocolEthFee}("");
            require(sent2, "Call must return true");
        } else if (lenWantNft == 0 && swantToken == address(0) && sethAmount != 0) {
            uint256 protocolEthFee = msg.value / fee;

            uint256 finalEthAmount = sethAmount - protocolEthFee;

            (bool sent1,) = address(sseller).call{value: finalEthAmount}("");
            require(sent1, "Call must return true");

            (bool sent2,) = protocol.call{value: protocolEthFee}("");
            require(sent2, "Call must return true");
        } else if (lenWantNft != 0 && swantToken == address(0) && sethAmount != 0) {
            require(msg.value >= sethAmount, "Not enough Eth");

            if (lenwantId != 0) {
                transferNft(swap.giveNft, msg.sender, sseller, lenWantNft, swap.wantId);
            } else if (lenwantId == 0) {
                transferNft(swap.giveNft, msg.sender, sseller, lenWantNft, tokenIds);
            }

            uint256 protocolEthFee = msg.value / fee;

            uint256 finalEthAmount = sethAmount - protocolEthFee;

            (bool sent1,) = address(sseller).call{value: finalEthAmount}("");
            require(sent1, "Call must return true");

            (bool sent2,) = protocol.call{value: protocolEthFee}("");
            require(sent2, "Call must return true");
        }

        emit AcceptSwap(id);
    }

    /////////////////////////////////////////////
    //                 Limit
    /////////////////////////////////////////////

    function openLimitBuy(address wantNft, uint256 wantId) external payable noReentrancy {
        require(wantNft != address(0), "Zero address not allowed!");
        require(msg.value > 100000000000000, "Non-dust amount required!");

        limitBuys.push(LimitBuy({active: true, buyer: msg.sender, wantNft: wantNft, wantId: wantId, price: msg.value}));

        uint256 id = limitBuys.length - 1;

        emit OpenLimitBuy(id, wantNft, wantId, msg.value);
    }

    function cancelBuyOrder(uint256 id) external noReentrancy {
        LimitBuy storage limit = limitBuys[id];
        require(limit.buyer == msg.sender, "Only owner!");
        require(limit.active == true, "Order is not active!");

        limit.active = false;

        (bool sent,) = limit.buyer.call{value: limit.price}("");
        require(sent, "Call must return true");

        emit CancelBuyOrder(id);
    }

    function fillBuyOrder(uint256 id, uint256 tokenId) external noReentrancy {
        LimitBuy storage limit = limitBuys[id];
        require(limit.active == true, "Order is not active!");

        limit.active = false;

        uint256 lwantId = limit.wantId;
        address lbuyer = limit.buyer;

        if (lwantId == 0) {
            sTransferNft(limit.wantNft, msg.sender, lbuyer, tokenId);
        } else if (lwantId != 0) {
            sTransferNft(limit.wantNft, msg.sender, lbuyer, lwantId);
        }

        uint256 protocolFee = limit.price / fee;

        uint256 finalAmount = limit.price - protocolFee;

        (bool sent,) = msg.sender.call{value: finalAmount}("");
        require(sent, "Call must return true");

        (bool sent1,) = address(protocol).call{value: protocolFee}("");
        require(sent1, "Call must return true");

        emit FillBuy(id, msg.sender, lbuyer, finalAmount, protocolFee);
    }

    function openLimitSell(address[] memory giveNft, uint256[] memory giveId, uint256 price) external noReentrancy {
        require(giveNft.length == 1);

        SwapVault vault = new SwapVault(address(this));

        transferNft(giveNft, msg.sender, address(vault), giveNft.length, giveId);

        limitSells.push(
            LimitSell({
                active: true,
                seller: msg.sender,
                giveNft: giveNft,
                vault: address(vault),
                giveId: giveId,
                price: price
            })
        );

        uint256 id = limitSells.length - 1;

        emit OpenLimitSell(id, giveNft, giveId, price);
    }

    function cancelSellOrder(uint256 id) external noReentrancy {
        LimitSell storage limit = limitSells[id];

        require(limit.seller == msg.sender, "Only owner!");
        require(limit.active == true, "Order is not active!");

        limit.active = false;

        ISwapVault vault = ISwapVault(limit.vault);

        vault.fromVault(limit.giveNft, msg.sender, limit.giveId);

        /*         sTransferNft(limit.giveNft, address(this), msg.sender, limit.giveId); */

        emit CancelSellOrder(id);
    }

    function fillSellOrder(uint256 id) external payable noReentrancy {
        LimitSell storage limit = limitSells[id];

        uint256 lprice = limit.price;
        bool lactive = limit.active;

        uint256 protocolFee = lprice / fee;

        uint256 finalAmount = lprice - protocolFee;

        require(lactive == true, "Order is not active!");
        require(msg.value == lprice);

        lactive = false;

        ISwapVault vault = ISwapVault(limit.vault);

        vault.fromVault(limit.giveNft, msg.sender, limit.giveId);

        /*         sTransferNft(limit.giveNft, address(this), msg.sender, limit.giveId); */

        (bool sent,) = limit.seller.call{value: finalAmount}("");
        require(sent, "Call must return true");

        (bool sent1,) = protocol.call{value: protocolFee}("");
        require(sent1, "Call must return true");

        emit FillSell(id, msg.sender, limit.seller, finalAmount, protocolFee);
    }

    /////////////////////////////////////////////
    //                  Admin
    /////////////////////////////////////////////

    /**
     * @dev Function to set the protocol address.
     * @param protocol_ The address of the protocol.
     */

    function setProtocol(address protocol_) external payable onlyOwner {
        assembly {
            sstore(protocol.slot, protocol_)
        }
    }

    /**
     * @dev Allows the contract owner to set the transaction fee.
     * @param fee_ The new transaction fee.
     */
    function setFee(uint256 fee_) external payable onlyOwner {
        assembly {
            sstore(fee.slot, fee_)
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
        require(!mutex, "Mutex is already set, reentrancy detected!");
        mutex = true;
    }

    function _nonReentrantAfter() internal {
        mutex = false;
    }

    /////////////////////////////////////////////
    //                Getters
    /////////////////////////////////////////////

    function getLength() external view returns (uint256) {
        return swaps.length;
    }

    function getSwaps() external view returns (uint256) {
        return swaps.length;
    }
}