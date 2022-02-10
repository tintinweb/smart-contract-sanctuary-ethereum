// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../../lib/Ownable.sol";
import {Pausable} from "../../lib/Pausable.sol";
import {Reentrancy} from "../../lib/Reentrancy.sol";
import {ERC721, IERC721, IERC165} from "../../lib/ERC721/ERC721.sol";
import {IERC721Metadata} from "../../lib/ERC721/interface/IERC721.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";
import {IERC2981} from "../../lib/ERC2981/interface/IERC2981.sol";
import {IEditions, IEditionsEvents} from "./interface/IEditions.sol";

import {IRenderer} from "./interface/IRenderer.sol";

import {ITreasuryConfig} from "../../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../treasury/interface/IMirrorTreasury.sol";
import {IMirrorFeeConfig} from "../../fee-config/MirrorFeeConfig.sol";

/**
 * @title Editions
 * @author MirrorXYZ
 */
contract Editions is
    Ownable,
    Pausable,
    Reentrancy,
    ERC721,
    IERC721Metadata,
    IERC2309,
    IERC2981,
    IEditions,
    IEditionsEvents
{
    // ============ Deployment ============

    /// @notice Address that deploys and initializes clones
    address public immutable override factory;

    // ============ Fee Configuration ============

    /// @notice Address for Mirror fee configuration.
    address public immutable override feeConfig;

    /// @notice Address for Mirror treasury configuration.
    address public immutable override treasuryConfig;

    // ============ ERC721 Metadata ============

    /// @notice Edition name
    string public override name;

    /// @notice Ediiton symbol
    string public override symbol;

    // ============ Edition Data ============

    /// @notice Last tokenId that was minted
    uint256 internal currentTokenId;

    /// @notice Edition contractURI
    string internal _contractURI;

    /// @notice Edition contentURI
    string internal contentURI;

    /// @notice Edition price
    uint256 public override price;

    /// @notice Edition limit
    uint256 public override limit;

    /// @notice Edition contentHash
    bytes32 public override contentHash;

    // ============ Royalty Info (ERC2981) ============

    /// @notice Account that will receive royalties
    /// @dev set address(0) to avoid royalties
    address public override royaltyRecipient;

    /// @notice Royalty Basis Points
    uint256 public override royaltyBPS;

    // ============ Rendering ============

    /// @notice Rendering contract
    address public override renderer;

    // ============ Pre allocation ============

    /// @notice Allocation recipient (consecutive transfer)
    address internal allocationRecipient;

    /// @notice Allocation count (consecutive transfer)
    uint256 internal allocationCount;

    // ============ Constructor ============
    constructor(
        address factory_,
        address feeConfig_,
        address treasuryConfig_
    ) Ownable(address(0)) Pausable(false) {
        factory = factory_;
        feeConfig = feeConfig_;
        treasuryConfig = treasuryConfig_;
    }

    // ============ Initializing ============

    /// @notice Initialize metadata
    /// @param owner_ the clone owner
    /// @param name_ the name for the edition clone
    /// @param symbol_ the symbol for the edition clone
    /// @param contentURI_ the contentURI for the edition clone
    /// @param contractURI_ the contractURI for the edition clone
    /// @param edition_ the parameters for the edition sale
    /// @param paused_ the pause state for the edition sale
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory contentURI_,
        string memory contractURI_,
        Edition memory edition_,
        bool paused_
    ) external override {
        require(msg.sender == factory, "unauthorized caller");

        // store erc721 metadata
        name = name_;
        symbol = symbol_;

        // store edition data
        contentURI = contentURI_;
        _contractURI = contractURI_;
        price = edition_.price;
        limit = edition_.limit;
        contentHash = edition_.contentHash;

        // set pause status
        if (paused_) {
            _pause();
        }

        // store owner
        _setOwner(address(0), owner_);

        // set royalty defaults to owner and 10%
        royaltyRecipient = owner_;
        royaltyBPS = 1000;
    }

    // ============ Pause Methods ============

    /// @notice Unpause edition sale
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice Pause edition sale
    function pause() external override onlyOwner {
        _pause();
    }

    // ============ Allocation ============

    /// @notice Allocates `count` editions to `recipient`
    /// @dev Throws if an edition has been purchased already or `count` exceeds limit
    /// @param recipient the account to receive tokens
    /// @param count the number of tokens to mint to `recipient`
    function allocate(address recipient, uint256 count)
        external
        override
        onlyOwner
    {
        // check that no purchases have happened and count does not exceed limit
        require(
            currentTokenId == 0 && (limit == 0 || count <= limit),
            "cannot allocate"
        );

        // set allocation recipient
        allocationRecipient = recipient;
        allocationCount = count;

        // update tokenId
        currentTokenId = count;

        // update balance
        _balances[recipient] = count;

        // emit transfer
        emit ConsecutiveTransfer(
            // fromTokenId
            1,
            // toTokenId
            count,
            // fromAddress
            address(0),
            // toAddress
            recipient
        );
    }

    /// @notice Finds the owner of a token
    /// @dev this method takes into account allocation
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address _owner = _owners[tokenId];

        // if there is not owner set,
        // and the tokenId is within the allocation count
        // the allocationRecipient owns it
        if (_owner == address(0) && tokenId < allocationCount) {
            return allocationRecipient;
        }

        require(_owner != address(0), "ERC721: query for nonexistent token");

        return _owner;
    }

    // ============ Purchase ============

    /// @notice Purchase an edition
    /// @dev throws if sale is paused or incorrect value is sent
    /// @param recipient the account to receive the edition
    function purchase(address recipient)
        external
        payable
        override
        whenNotPaused
        returns (uint256 tokenId)
    {
        require(msg.value == price, "incorrect value");

        return _purchase(recipient);
    }

    // ============ Minting ============

    /// @notice Mint an edition
    /// @dev throws if called by a non-owner
    /// @param recipient the account to receive the edition
    function mint(address recipient)
        external
        override
        onlyOwner
        returns (uint256 tokenId)
    {
        tokenId = _getTokenIdAndMint(recipient);
    }

    /// @notice Allows the owner to set a global limit on the total supply
    /// @dev throws if attempting to increase the limit
    function setLimit(uint256 limit_) external override onlyOwner {
        // enforce that the limit should only ever decrease once set
        require(
            limit == 0 || limit_ < limit,
            "limit must be < than current limit"
        );

        // announce the change in limit
        emit EditionLimitSet(
            // oldLimit
            limit,
            // newLimit
            limit_
        );

        // update the limit.
        limit = limit_;
    }

    // ============ ERC2981 Methods ============

    /// @notice Called with the sale price to determine how much royalty
    //  is owed and to whom
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;

        royaltyAmount = (_salePrice * royaltyBPS) / 10_000;
    }

    /// @param royaltyRecipient_ the address that will receive royalties
    /// @param royaltyBPS_ the royalty amount in basis points (bps)
    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyBPS_
    ) external override onlyOwner {
        require(
            royaltyBPS_ <= 10_000,
            "bps must be less than or equal to 10,000"
        );

        emit RoyaltyChange(
            // oldRoyaltyRecipient
            royaltyRecipient,
            // oldRoyaltyBPS
            royaltyBPS,
            // newRoyaltyRecipient
            royaltyRecipient_,
            // newRoyaltyBPS
            royaltyBPS_
        );

        royaltyRecipient = royaltyRecipient_;
        royaltyBPS = royaltyBPS_;
    }

    // ============ Rendering Methods ============

    /// @notice Set the renderer address
    /// @dev Throws if renderer is not the zero address
    function setRenderer(address renderer_) external override onlyOwner {
        require(renderer == address(0), "renderer already set");

        renderer = renderer_;

        emit RendererSet(
            // renderer
            renderer_
        );
    }

    /// @notice Get contract metadata
    /// @dev If a renderer is set, return the renderer's metadata
    function contractURI() external view override returns (string memory) {
        if (renderer != address(0)) {
            return IRenderer(renderer).contractURI();
        }

        return _contractURI;
    }

    /// @notice Get `tokenId` URI or data
    /// @dev If a renderer is set, call renderer's tokenURI
    /// @param tokenId The tokenId used to request data
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        if (renderer != address(0)) {
            return IRenderer(renderer).tokenURI(tokenId);
        }

        return contentURI;
    }

    // ============ Withdrawal ============

    /// @notice Set the price
    function setPrice(uint256 price_) external override onlyOwner {
        price = price_;

        emit PriceSet(
            // price
            price_
        );
    }

    function withdraw(uint16 feeBPS, address fundingRecipient)
        external
        onlyOwner
        nonReentrant
    {
        require(fundingRecipient != address(0), "must set fundingRecipient");

        _withdraw(feeBPS, fundingRecipient);
    }

    // ============ IERC165 Method ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ============ Internal Methods ============
    function _withdraw(uint16 feeBPS, address fundingRecipient) internal {
        // assert that the fee is valid
        require(IMirrorFeeConfig(feeConfig).isFeeValid(feeBPS), "invalid fee");

        // calculate the fee on the current balance, using the fee percentage
        uint256 fee = _feeAmount(address(this).balance, feeBPS);

        // if the fee is not zero, attempt to send it to the treasury
        if (fee != 0) {
            _sendEther(ITreasuryConfig(treasuryConfig).treasury(), fee);
        }

        // broadcast the withdrawal event – with balance and fee
        emit Withdrawal(
            // recipient
            fundingRecipient,
            // amount
            address(this).balance,
            // fee
            fee
        );

        // transfer the remaining balance to the fundingRecipient
        _sendEther(payable(fundingRecipient), address(this).balance);
    }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // ensure sufficient balance
        require(address(this).balance >= amount, "insufficient balance");
        // send the value
        (bool success, ) = recipient_.call{value: amount, gas: gasleft()}("");
        require(success, "recipient reverted");
    }

    function _feeAmount(uint256 amount, uint16 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10_000;
    }

    /// @dev ensure token has an owner, or token is within the allocation
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return _owners[tokenId] != address(0) || tokenId < allocationCount;
    }

    /// @dev Mints token and emits purchase event
    function _purchase(address recipient) internal returns (uint256 tokenId) {
        // mint the token, get a tokenId
        tokenId = _getTokenIdAndMint(recipient);

        emit EditionPurchased(
            // tokenId
            tokenId,
            // nftRecipient
            recipient,
            // amountPaid
            msg.value
        );
    }

    /// @dev Mints and returns tokenId
    function _getTokenIdAndMint(address recipient)
        internal
        returns (uint256 tokenId)
    {
        // increment currentTokenId and store tokenId
        tokenId = ++currentTokenId;

        // check that there are still tokens available to purchase
        require(limit == 0 || tokenId < limit + 1, "sold out");

        // mint a new token for the recipient, using the `tokenId`.
        _mint(recipient, tokenId);
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IPausableEvents {
    /// @notice Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @notice Emitted when the pause is lifted by `account`.
    event Unpaused(address account);
}

interface IPausable {
    function paused() external returns (bool);
}

contract Pausable is IPausable, IPausableEvents {
    bool public override paused;

    // Modifiers

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /// @notice Initializes the contract in unpaused state.
    constructor(bool paused_) {
        paused = paused_;
    }

    // ============ Internal Functions ============

    function _pause() internal whenNotPaused {
        paused = true;

        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        paused = false;

        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC721, IERC721Events, IERC721Metadata, IERC721Receiver} from "./interface/IERC721.sol";
import {IERC165} from "../ERC165/interface/IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is ERC165, IERC721, IERC721Events {
    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/**
 * @title IERC2981
 * @notice Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    // / bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IEditionsEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        address indexed nftRecipient,
        uint256 amountPaid
    );

    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyBPS,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyBPS
    );

    event RendererSet(address indexed renderer);

    event EditionLimitSet(uint256 oldLimit, uint256 newLimit);

    event Withdrawal(address indexed recipient, uint256 amount, uint256 fee);

    event FundingRecipientSet(
        address indexed oldFundingRecipient,
        address indexed newFundingRecipient
    );

    event PriceSet(uint256 price);
}

interface IEditions {
    struct Edition {
        // Edition price
        uint256 price;
        // Edition supply limit
        uint256 limit;
        // Edition contentHash
        bytes32 contentHash;
    }

    // ============ Authorization ============

    function factory() external returns (address);

    // ============ Fee Configuration ============

    function feeConfig() external returns (address);

    function treasuryConfig() external returns (address);

    // ============ Edition Data ============

    function price() external returns (uint256);

    function limit() external returns (uint256);

    function contentHash() external returns (bytes32);

    // ============ Royalty Info (ERC2981) ============

    function royaltyRecipient() external returns (address);

    function royaltyBPS() external returns (uint256);

    // ============ Rendering ============

    function renderer() external view returns (address);

    // ============ Initializing ============

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory contentURI_,
        string memory contractURI_,
        Edition memory edition_,
        bool paused_
    ) external;

    // ============ Pause Methods ============

    function unpause() external;

    function pause() external;

    // ============ Allocation ============

    function allocate(address recipient, uint256 count) external;

    // ============ Purchase ============

    function purchase(address recipient)
        external
        payable
        returns (uint256 tokenId);

    // ============ Minting ============

    function mint(address recipient) external returns (uint256 tokenId);

    function setLimit(uint256 limit_) external;

    // ============ ERC2981 Methods ============

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;

    // ============ Rendering Methods ============

    function setRenderer(address renderer_) external;

    function contractURI() external view returns (string memory);

    // ============ Withdrawal ============

    function setPrice(uint256 price_) external;

    function withdraw(uint16 feeBPS, address fundingRecipient) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string calldata);

    function contractURI() external view returns (string calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../lib/Ownable.sol";

interface IMirrorFeeConfig {
    function maxFee() external returns (uint16);

    function minFee() external returns (uint16);

    function isFeeValid(uint16) external view returns (bool);

    function updateMaxFee(uint16 newFee) external;

    function updateMinFee(uint16 newFee) external;
}

/**
 * @title MirrorFeeConfig
 * @author MirrorXYZ
 */
contract MirrorFeeConfig is IMirrorFeeConfig, Ownable {
    uint16 public override maxFee = 500;
    uint16 public override minFee = 250;

    constructor(address owner_) Ownable(owner_) {}

    function updateMaxFee(uint16 newFee) external override onlyOwner {
        maxFee = newFee;
    }

    function updateMinFee(uint16 newFee) external override onlyOwner {
        minFee = newFee;
    }

    function isFeeValid(uint16 fee)
        external
        view
        returns (bool isBeweenMinAndMax)
    {
        isBeweenMinAndMax = (minFee <= fee) && (fee <= maxFee);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}