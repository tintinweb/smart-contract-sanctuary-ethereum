/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (Maze.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./auction/AuctionCore.sol";

contract Maze is AuctionCore, IERC721Receiver {
    constructor() {
        // starts paused.
        pause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// Pause maze protocol contract.
    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    /// @dev Override unpause so it requires all external contract addresses
    function unpause() public onlyOwner whenPaused {
        require(feeReceiver != address(0), "fee receiver is not ready.");
        // Actually unpause the contract.
        super._unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionCore.sol)

pragma solidity ^0.8.0;

import "./AuctionRadical.sol";
import "./AuctionDutch.sol";
import "./AuctionFixed.sol";

contract AuctionCore is AuctionRadical, AuctionDutch, AuctionFixed {
    /// @dev The ERC-165 interface signature for ERC-721.
    //  Ref: https://eips.ethereum.org/EIPS/eip-721
    //  type(IERC721).interfaceId == 0x80ac58cd
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = bytes4(0x80ac58cd);

    // supported contracts
    address[] internal supportedContracts;

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    // NFTs of ERC721 only could be auctioned after maze protocol owner call this function set
    // the ERC721 contract address and auction parameter to contractToAuctionParams.
    function setAuctionParam(
        address _contractAddress,
        uint8 _auctionType,
        uint128 _feeRatio,
        uint128 _taxRatio,
        address _taxReceiver
    ) external onlyOwner {
        IERC721 nonFungibleContract = IERC721(_contractAddress);
        require(nonFungibleContract.supportsInterface(INTERFACE_SIGNATURE_ERC721), "Not support contract interface.");

        // Radical 0, Dutch 1, Fixed 2
        require(_auctionType < 3, "Invalid auction type.");
        require(_feeRatio > 0, "Invalid fee ratio.");
        require(_taxRatio > 0, "Invalid tax ratio.");
        require(_taxReceiver != address(0), "Invalid tax receiver.");

        AuctionParam memory auctionParam = AuctionParam(AuctionType(_auctionType), _feeRatio, _taxRatio, _taxReceiver);
        contractToAuctionParams[_contractAddress] = auctionParam;

        supportedContracts.push(_contractAddress);
    }

    function getAuctionParam(address _contractAddress)
        external
        view
        returns (
            uint8 auctionType,
            uint256 feeRatio,
            uint256 taxRatio,
            address taxReceiver
        )
    {
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        _checkAuctionParam(auctionParam);

        auctionType = uint8(auctionParam.auctionType);
        feeRatio = uint256(auctionParam.feeRatio);
        taxRatio = uint256(auctionParam.taxRatio);
        taxReceiver = auctionParam.taxReceiver;
    }

    function getSupportedContracts() external view returns (address[] memory) {
        return supportedContracts;
    }

    // Returns auction info for an NFT on auction.
    function getAuction(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint8 auctionType,
            uint256 deposit,
            uint256 startPrice,
            uint256 endPrice,
            uint256 fixedPrice,
            uint256 currentPrice,
            uint64 startedAt,
            uint64 duration
        )
    {
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        _checkAuctionParam(auctionParam);

        auctionType = uint8(auctionParam.auctionType);

        if (auctionParam.auctionType == AuctionType.Radical) {
            RadicalAuction memory auction = contractTokenIdToRadicalAuction[_contractAddress][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            deposit = uint256(auction.deposit);
            currentPrice = _radicalAuctionCurrentPrice(auctionParam, auction);
            startedAt = auction.startedAt;
        } else if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_contractAddress][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            startPrice = uint256(auction.startPrice);
            endPrice = uint256(auction.endPrice);
            currentPrice = 0; //TODO
            startedAt = auction.startedAt;
            duration = auction.duration;
        } else if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_contractAddress][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            fixedPrice = uint256(auction.fixedPrice);
            currentPrice = uint256(auction.fixedPrice);
            startedAt = auction.startedAt;
        } else {
            revert("Invalid auction type");
        }
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionRadical.sol)

pragma solidity ^0.8.0;

import "./AuctionBase.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AuctionRadical is AuctionBase {
    // Represents an radical auction on an NFT
    struct RadicalAuction {
        // current NFT owner
        address seller;
        // for NFT creator initial radical auction
        uint128 initialPrice;
        // for radical auction
        uint128 deposit;
        // auction start timestamp
        //0 means auction is not start
        uint64 startedAt;
    }

    // storage nft contract address to nft radical auction
    mapping(address => mapping(uint256 => RadicalAuction)) internal contractTokenIdToRadicalAuction;

    // Create radical auction only could be called by NFT creator.
    function createInitialRadicalAuction(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _initialPrice
    ) external whenNotPaused {
        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        // check initial price
        require(_initialPrice == uint256(uint128(_initialPrice)), "Initial price is invalid.");

        // check is nft creator
        require(msg.sender == auctionParam.taxReceiver, "Not nft creator");

        // check ownership
        IERC721 nonFungibleContract = IERC721(_contractAddress);
        require(msg.sender == nonFungibleContract.ownerOf(_tokenId), "Not token owner.");

        // check auction exist
        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_contractAddress][_tokenId];
        require(auction.startedAt == 0, "Auction is already start.");

        // transfer ownership before auction created
        // need user send a setApprovalForAll transaction to ERC721 contract before this
        // frontend check isApprovedForAll for msg.sender
        nonFungibleContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        _createRadicalAuction(_contractAddress, _tokenId, msg.sender, _initialPrice, 0);
    }

    // Create radical auction when auction type of contract address contain radical.
    function createRadicalAuction(address _contractAddress, uint256 _tokenId) external payable whenNotPaused {
        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        // check ownership
        IERC721 nonFungibleContract = IERC721(_contractAddress);
        require(msg.sender == nonFungibleContract.ownerOf(_tokenId), "Not token owner.");

        // check auction exist
        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_contractAddress][_tokenId];
        require(auction.startedAt == 0, "Auction is already start.");

        // check radical auction deposit
        require(msg.value > 0, "No radical auction deposit");

        // transfer ownership before auction created
        // need user send a setApprovalForAll transaction to ERC721 contract before this
        // frontend check isApprovedForAll for msg.sender
        nonFungibleContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        // create auction
        _createRadicalAuction(_contractAddress, _tokenId, msg.sender, 0, msg.value);
    }

    function bidRadicalAuction(address _contractAddress, uint256 _tokenId) external payable whenNotPaused {
        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_contractAddress][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");
        require(msg.sender != auction.seller, "Can't bid own auction.");

        uint256 dealPrice = _radicalAuctionCurrentPrice(auctionParam, auction);
        uint256 feeAmount = dealPrice / uint256(auctionParam.feeRatio);
        uint256 taxAmount = dealPrice / uint256(auctionParam.taxRatio);

        require(msg.value > (dealPrice + feeAmount + taxAmount), "Insufficient payable amount.");

        // remove from contractTokenIdToAuction
        delete contractTokenIdToRadicalAuction[_contractAddress][_tokenId];

        // remove token auction offers
        delete contractTokenIdToOffers[_contractAddress][_tokenId];

        payable(auction.seller).transfer(dealPrice);
        payable(auction.seller).transfer(uint256(auction.deposit));
        payable(feeReceiver).transfer(feeAmount);
        payable(auctionParam.taxReceiver).transfer(taxAmount);

        emit AuctionSuccessful(_contractAddress, _tokenId, dealPrice, msg.sender);

        // will never underflow
        uint256 newDeposit = msg.value - dealPrice - feeAmount - taxAmount;

        // create new auction
        _createRadicalAuction(_contractAddress, _tokenId, msg.sender, 0, newDeposit);
    }

    // Only can cancel radical auction when maze protocol contract paused.
    function cancelRadicalAuctionWhenPaused(address _contractAddress, uint256 _tokenId) external whenPaused onlyOwner {
        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_contractAddress];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_contractAddress][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");

        // remove from contractTokenIdToAuction
        delete contractTokenIdToRadicalAuction[_contractAddress][_tokenId];

        // remove token auction offer
        delete contractTokenIdToOffers[_contractAddress][_tokenId];

        IERC721 nonFungibleContract = IERC721(_contractAddress);
        // transfer ownership after auction deleted
        nonFungibleContract.safeTransferFrom(address(this), auction.seller, _tokenId);

        payable(auction.seller).transfer(auction.deposit);

        emit AuctionCancelled(_contractAddress, _tokenId);
    }

    function _createRadicalAuction(
        address _contractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _initialPrice,
        uint256 _deposit
    ) internal {
        require(_initialPrice == uint256(uint128(_initialPrice)), "Initial price is invalid.");
        require(_deposit == uint256(uint128(_deposit)), "Deposit is invalid.");

        RadicalAuction memory auction = RadicalAuction(
            _seller,
            uint128(_initialPrice),
            uint128(_deposit),
            uint64(block.timestamp)
        );

        contractTokenIdToRadicalAuction[_contractAddress][_tokenId] = auction;

        emit AuctionCreated(_contractAddress, _tokenId, _seller);
    }

    function _radicalAuctionCurrentPrice(AuctionParam memory auctionParam, RadicalAuction memory auction)
        internal
        pure
        returns (uint256)
    {
        require(auctionParam.auctionType == AuctionType.Radical, "Invalid auction type.");
        // support nft creator create radical auction without deposit
        if (auction.seller == auctionParam.taxReceiver && auction.initialPrice != 0) {
            return uint256(auction.initialPrice);
        }
        return uint256(auction.deposit) * 10;
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionDutch.sol)

pragma solidity ^0.8.0;

import "./AuctionBase.sol";

contract AuctionDutch is AuctionBase {
    // Represents an dutch auction on an NFT
    struct DutchAuction {
        // current NFT owner
        address seller;
        // for dutch auction
        uint128 startPrice;
        // for dutch auction
        uint128 endPrice;
        // auction start timestamp
        //0 means auction is not start
        uint64 startedAt;
        // auction start price -> end price duration
        uint64 duration;
    }

    // storage nft contract address to nft dutch auction
    mapping(address => mapping(uint256 => DutchAuction)) internal contractTokenIdToDutchAuction;

    function _createDutchAuction(
        address _contractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _startPrice,
        uint256 _endPrice,
        uint64 _duration
    ) internal {
        require(_startPrice == uint256(uint128(_startPrice)), "Start price is invalid.");
        require(_endPrice == uint256(uint128(_endPrice)), "End price is invalid.");
        require(_duration > 0, "Duration is invalid.");

        DutchAuction memory auction = DutchAuction(
            _seller,
            uint128(_startPrice),
            uint128(_endPrice),
            uint64(block.timestamp),
            _duration
        );
        contractTokenIdToDutchAuction[_contractAddress][_tokenId] = auction;

        emit AuctionCreated(_contractAddress, _tokenId, _seller);
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionFixed.sol)

pragma solidity ^0.8.0;

import "./AuctionBase.sol";

contract AuctionFixed is AuctionBase {
    // Represents an fixed auction on an NFT
    struct FixedAuction {
        // current NFT owner
        address seller;
        // for fixed auction
        uint128 fixedPrice;
        // auction start timestamp
        //0 means auction is not start
        uint64 startedAt;
    }

    // storage nft contract address to nft fixed auction
    mapping(address => mapping(uint256 => FixedAuction)) internal contractTokenIdToFixedAuction;

    function _createFixedAuction(
        address _contractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _fixedPrice
    ) internal {
        require(_fixedPrice == uint256(uint128(_fixedPrice)), "Fixed price is invalid.");

        FixedAuction memory auction = FixedAuction(_seller, uint128(_fixedPrice), uint64(block.timestamp));
        contractTokenIdToFixedAuction[_contractAddress][_tokenId] = auction;

        emit AuctionCreated(_contractAddress, _tokenId, _seller);
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AuctionBase is Ownable, Pausable {
    // auction type
    enum AuctionType {
        Radical,
        Dutch,
        Fixed
    }

    // auction parameter
    struct AuctionParam {
        // all NFT of a contract support auction types
        // only one auction type for a contract
        AuctionType auctionType;
        // auction fee ratio, to maze protocol
        // fee = amount / feeRatio
        uint128 feeRatio;
        // auction tax ratio
        // tax = amount / taxRatio
        uint128 taxRatio;
        // NFT creator
        address taxReceiver;
    }

    // Represents an offer on an NFT
    struct Offer {
        // offer provider
        address buyer;
        // buy NFT price
        uint128 offerPrice;
    }

    // address receive maze protocol fee
    address public feeReceiver;

    // storage nft contract address to auction parameter
    mapping(address => AuctionParam) internal contractToAuctionParams;

    // storage nft contract address to nft offers
    mapping(address => mapping(uint256 => Offer[])) internal contractTokenIdToOffers;

    // auction created event
    event AuctionCreated(address indexed contractAddress, uint256 tokenId, address indexed seller);

    // auction successful event
    event AuctionSuccessful(address indexed contractAddress, uint256 tokenId, uint256 price, address indexed winner);

    // auction cancelled event
    event AuctionCancelled(address indexed contractAddress, uint256 tokenId);

    function _checkAuctionParam(AuctionParam memory auctionParam) internal pure {
        require(auctionParam.feeRatio > 0, "Invalid fee ratio.");
        require(auctionParam.taxRatio > 0, "Invalid tax ratio.");
        require(auctionParam.taxReceiver != address(0), "Invalid tax receiver");
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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