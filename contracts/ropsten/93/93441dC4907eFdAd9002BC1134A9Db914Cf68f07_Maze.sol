/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (Maze.sol)

pragma solidity ^0.8.0;

import "./auction/AuctionCore.sol";

contract Maze is AuctionCore {
    // Initialize maze protocol contract
    function initialize(address _feeReceiver, address _wbtm) public initializer {
        feeReceiver = _feeReceiver;
        wbtm = _wbtm;
    }

    // Pause maze protocol contract
    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    // Override unpause so it requires all external contract addresses
    function unpause() public onlyOwner whenPaused {
        require(feeReceiver != address(0), "fee receiver is not ready.");
        require(wbtm != address(0), "wrapped btm contract is not ready.");
        // Actually unpause the contract.
        super._unpause();
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionCore.sol)

pragma solidity ^0.8.0;

import "./AuctionRadical.sol";
import "./AuctionDutch.sol";

contract AuctionCore is AuctionRadical, AuctionDutch {
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
        address _erc721Address,
        uint8 _auctionType,
        uint128 _feeRatio,
        uint128 _taxRatio,
        address _taxReceiver,
        address _erc20Address
    ) external onlyOwner {
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(erc721Contract.supportsInterface(INTERFACE_SIGNATURE_ERC721), "Not support contract interface.");

        // Radical 0, Dutch 1, Fixed 2
        require(_auctionType < 3, "Invalid auction type.");
        require(_feeRatio > 0, "Invalid fee ratio.");
        require(_taxRatio > 0, "Invalid tax ratio.");
        require(_taxReceiver != address(0), "Invalid tax receiver.");

        AuctionParam memory auctionParam = AuctionParam(
            AuctionType(_auctionType),
            _feeRatio,
            _taxRatio,
            _taxReceiver,
            _erc20Address
        );
        contractToAuctionParams[_erc721Address] = auctionParam;

        supportedContracts.push(_erc721Address);
    }

    // cancel dutch auction and fixed auction.
    function cancelAuction(address _erc721Address, uint256 _tokenId) external mutex whenNotPaused {
        // check auction parameter
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType != AuctionType.Radical, "Auction is radical.");
        _checkAuctionParam(auctionParam);

        if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller == msg.sender, "Not auction seller.");

            delete contractTokenIdToDutchAuction[_erc721Address][_tokenId];
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller == msg.sender, "Not auction seller.");

            delete contractTokenIdToFixedAuction[_erc721Address][_tokenId];
        }

        // transfer token ownership after auction deleted
        IERC721 erc721Contract = IERC721(_erc721Address);
        erc721Contract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit AuctionCancelled(_erc721Address, _tokenId);

        // cancel auction offers
        _cancelAuctionOffers(_erc721Address, _tokenId);
    }

    // cancel auction when maze protocol contract paused.
    function cancelAuctionWhenPaused(address _erc721Address, uint256 _tokenId) external whenPaused onlyOwner {
        // check auction parameter
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        _checkAuctionParam(auctionParam);

        // save gas
        address _erc20Address = auctionParam.erc20Address;

        address seller = address(0);
        uint256 deposit = 0;

        if (auctionParam.auctionType == AuctionType.Radical) {
            RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            deposit = uint256(auction.deposit);
            delete contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
        }

        if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            delete contractTokenIdToDutchAuction[_erc721Address][_tokenId];
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");

            seller = auction.seller;
            delete contractTokenIdToFixedAuction[_erc721Address][_tokenId];
        }

        // check auction seller
        require(seller != address(0), "Seller is invalid.");

        // transfer token ownership after auction deleted
        IERC721 erc721Contract = IERC721(_erc721Address);
        erc721Contract.safeTransferFrom(address(this), seller, _tokenId);

        // return deposit for radical auction
        if (auctionParam.auctionType == AuctionType.Radical && deposit != 0) {
            if (_erc20Address != address(0)) {
                _safeTransfer(_erc20Address, seller, deposit);
            } else {
                payable(seller).transfer(deposit);
            }
        }

        emit AuctionCancelled(_erc721Address, _tokenId);

        // cancel auction offers
        _cancelAuctionOffers(_erc721Address, _tokenId);
    }

    function getAuctionParam(address _erc721Address)
        external
        view
        returns (
            uint8 auctionType,
            uint256 feeRatio,
            uint256 taxRatio,
            address taxReceiver
        )
    {
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        _checkAuctionParam(auctionParam);

        auctionType = uint8(auctionParam.auctionType);
        feeRatio = uint256(auctionParam.feeRatio);
        taxRatio = uint256(auctionParam.taxRatio);
        taxReceiver = auctionParam.taxReceiver;
    }

    function getSupportedContracts() external view returns (address[] memory) {
        return supportedContracts;
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionRadical.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AuctionOffer.sol";

contract AuctionRadical is AuctionOffer {
    // Create radical auction only could be called by NFT creator.
    function createInitialRadicalAuction(
        address _erc721Address,
        uint256 _tokenId,
        uint128 _initialPrice
    ) external mutex whenNotPaused {
        // check ownership
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(msg.sender == erc721Contract.ownerOf(_tokenId), "Not token owner.");

        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        // check is nft creator
        require(msg.sender == auctionParam.taxReceiver, "Not nft creator");

        // check auction exist
        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
        require(auction.startedAt == 0, "Auction is already start.");

        // transfer ownership before auction created
        // need user send a setApprovalForAll transaction to ERC721 contract before this
        // frontend check isApprovedForAll for msg.sender
        erc721Contract.safeTransferFrom(msg.sender, address(this), _tokenId);

        _createRadicalAuction(_erc721Address, _tokenId, msg.sender, _initialPrice, 0);
    }

    // Create radical auction when auction type of contract address is radical.
    function createRadicalAuction(
        address _erc721Address,
        uint256 _tokenId,
        uint256 _deposit
    ) external payable mutex whenNotPaused {
        // check ownership
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(msg.sender == erc721Contract.ownerOf(_tokenId), "Not token owner.");

        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        // check auction exist
        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
        require(auction.startedAt == 0, "Auction is already start.");

        // transfer or check radical auction deposit
        if (auctionParam.erc20Address != address(0)) {
            _safeTransferFrom(auctionParam.erc20Address, msg.sender, address(this), _deposit);
        } else {
            require(msg.value > 0, "No radical auction deposit");
            _deposit = msg.value;
        }

        // transfer ownership before auction created
        // need user send a setApprovalForAll transaction to ERC721 contract before this
        // frontend check isApprovedForAll for msg.sender
        erc721Contract.safeTransferFrom(msg.sender, address(this), _tokenId);

        // create auction
        _createRadicalAuction(_erc721Address, _tokenId, msg.sender, 0, _deposit);
    }

    function bidRadicalAuction(
        address _erc721Address,
        uint256 _tokenId,
        uint256 _deposit
    ) external payable mutex whenNotPaused {
        // check support radical auction
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Radical, "Not support radical auction.");
        _checkAuctionParam(auctionParam);

        // save gas
        address _erc20Address = auctionParam.erc20Address;

        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");
        require(msg.sender != auction.seller, "Can't bid own auction.");

        // check token ownership
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(erc721Contract.ownerOf(_tokenId) == address(this), "Token is not owned.");

        uint256 dealPrice = _currentPrice(auctionParam, auction);
        uint256 feeAmount = dealPrice / uint256(auctionParam.feeRatio);
        uint256 taxAmount = dealPrice / uint256(auctionParam.taxRatio);

        // check radical auction deposit
        if (_erc20Address != address(0)) {
            uint256 totalAmount = dealPrice + feeAmount + taxAmount + _deposit;
            require(IERC20(_erc20Address).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance.");
        } else {
            require(msg.value > (dealPrice + feeAmount + taxAmount), "Insufficient payable amount.");
        }

        // remove from contractTokenIdToAuction
        delete contractTokenIdToRadicalAuction[_erc721Address][_tokenId];

        if (_erc20Address != address(0)) {
            _safeTransferFrom(_erc20Address, msg.sender, auction.seller, dealPrice);
            // return auction deposit to seller from maze contract
            _safeTransfer(_erc20Address, auction.seller, uint256(auction.deposit));
            _safeTransferFrom(_erc20Address, msg.sender, feeReceiver, feeAmount);
            _safeTransferFrom(_erc20Address, msg.sender, auctionParam.taxReceiver, taxAmount);
            _safeTransferFrom(_erc20Address, msg.sender, address(this), _deposit);
        } else {
            payable(auction.seller).transfer(dealPrice);
            payable(auction.seller).transfer(uint256(auction.deposit));
            payable(feeReceiver).transfer(feeAmount);
            payable(auctionParam.taxReceiver).transfer(taxAmount);
            // will never underflow
            _deposit = msg.value - dealPrice - feeAmount - taxAmount;
        }

        emit AuctionSuccessful(_erc721Address, _tokenId, msg.sender, dealPrice);

        // create new auction
        _createRadicalAuction(_erc721Address, _tokenId, msg.sender, 0, _deposit);
    }

    // Returns auction info for an NFT on an radical auction.
    function getRadicalAuction(address _erc721Address, uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 deposit,
            uint256 currentPrice,
            uint64 startedAt
        )
    {
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Radical, "Invalid auction type.");
        _checkAuctionParam(auctionParam);

        RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");

        seller = auction.seller;
        deposit = uint256(auction.deposit);
        currentPrice = _currentPrice(auctionParam, auction);
        startedAt = auction.startedAt;
    }

    function _createRadicalAuction(
        address _erc721Address,
        uint256 _tokenId,
        address _seller,
        uint128 _initialPrice,
        uint256 _deposit
    ) private {
        require(_deposit == uint256(uint128(_deposit)), "Invalid deposit.");

        RadicalAuction memory auction = RadicalAuction(
            _seller,
            _initialPrice,
            uint128(_deposit),
            uint64(block.timestamp)
        );

        contractTokenIdToRadicalAuction[_erc721Address][_tokenId] = auction;

        emit AuctionCreated(_erc721Address, _tokenId, _seller);
    }

    function _currentPrice(AuctionParam memory auctionParam, RadicalAuction memory auction)
        private
        pure
        returns (uint256)
    {
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AuctionOffer.sol";

contract AuctionDutch is AuctionOffer {
    // Create dutch auction when auction type of contract address is dutch.
    function createDutchAuction(
        address _erc721Address,
        uint256 _tokenId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint64 _duration
    ) external mutex whenNotPaused {
        require(_duration >= 1 hours, "Duration is invalid.");

        // check price
        require(_startPrice >= _endPrice, "Price is invalid.");

        // check ownership
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(msg.sender == erc721Contract.ownerOf(_tokenId), "Not token owner.");

        // check support fixed auction
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Dutch, "Not support dutch auction.");
        _checkAuctionParam(auctionParam);

        // check auction exist
        DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
        require(auction.startedAt == 0, "Auction is already start.");

        // transfer ownership before auction created
        // need user send a setApprovalForAll transaction to ERC721 contract before this
        // frontend check isApprovedForAll for msg.sender
        erc721Contract.safeTransferFrom(msg.sender, address(this), _tokenId);

        // create auction
        _createDutchAuction(_erc721Address, _tokenId, msg.sender, _startPrice, _endPrice, _duration);
    }

    function bidDutchAuction(address _erc721Address, uint256 _tokenId) external payable mutex whenNotPaused {
        // check support dutch auction
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Dutch, "Not support dutch auction.");
        _checkAuctionParam(auctionParam);

        // save gas
        address _erc20Address = auctionParam.erc20Address;
        address _taxReceiver = auctionParam.taxReceiver;

        DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");
        require(msg.sender != auction.seller, "Can't bid own auction.");

        // save gas
        address _seller = auction.seller;

        // check token ownership
        IERC721 erc721Contract = IERC721(_erc721Address);
        require(erc721Contract.ownerOf(_tokenId) == address(this), "Token is not owned.");

        uint256 dealPrice = _currentPrice(auction);
        uint256 feeAmount = dealPrice / uint256(auctionParam.feeRatio);
        uint256 taxAmount = dealPrice / uint256(auctionParam.taxRatio);

        uint256 totalAmount = dealPrice + feeAmount + taxAmount;
        if (_erc20Address != address(0)) {
            require(IERC20(_erc20Address).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance.");
        } else {
            require(msg.value >= totalAmount, "Insufficient payable amount.");
        }

        // remove from contractTokenIdToAuction
        delete contractTokenIdToDutchAuction[_erc721Address][_tokenId];

        // send money
        if (_erc20Address != address(0)) {
            _safeTransferFrom(_erc20Address, msg.sender, _seller, dealPrice);
            _safeTransferFrom(_erc20Address, msg.sender, feeReceiver, feeAmount);
            _safeTransferFrom(_erc20Address, msg.sender, _taxReceiver, taxAmount);
        } else {
            payable(_seller).transfer(dealPrice);
            payable(feeReceiver).transfer(feeAmount);
            payable(_taxReceiver).transfer(taxAmount);
        }

        // send token
        erc721Contract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit AuctionSuccessful(_erc721Address, _tokenId, msg.sender, dealPrice);

        // cancel auction offers
        _cancelAuctionOffers(_erc721Address, _tokenId);
    }

    // Returns auction info for an NFT on a dutch auction.
    function getDutchAuction(address _erc721Address, uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint128 startPrice,
            uint128 endPrice,
            uint128 currentPrice,
            uint64 startedAt,
            uint64 duration
        )
    {
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        require(auctionParam.auctionType == AuctionType.Dutch, "Invalid auction type.");
        _checkAuctionParam(auctionParam);

        DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
        require(auction.startedAt != 0, "Auction is not start.");

        seller = auction.seller;
        startPrice = auction.startPrice;
        endPrice = auction.endPrice;
        currentPrice = uint128(_currentPrice(auction));
        startedAt = auction.startedAt;
        duration = auction.duration;
    }

    function _createDutchAuction(
        address _erc721Address,
        uint256 _tokenId,
        address _seller,
        uint128 _startPrice,
        uint128 _endPrice,
        uint64 _duration
    ) private {
        DutchAuction memory auction = DutchAuction(_seller, _startPrice, _endPrice, uint64(block.timestamp), _duration);
        contractTokenIdToDutchAuction[_erc721Address][_tokenId] = auction;

        emit AuctionCreated(_erc721Address, _tokenId, _seller);
    }

    function _currentPrice(DutchAuction memory _auction) private view returns (uint256) {
        uint256 secondsPassed = 0;

        if (uint64(block.timestamp) > _auction.startedAt) {
            secondsPassed = uint64(block.timestamp) - _auction.startedAt;
        }

        if (secondsPassed >= _auction.duration) {
            return _auction.endPrice;
        }

        uint256 totalPriceChange = uint256(_auction.startPrice) - uint256(_auction.endPrice);
        uint256 currentPriceChange = (totalPriceChange * secondsPassed) / uint256(_auction.duration);
        return uint256(_auction.startPrice) - currentPriceChange;
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

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionOffer.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./AuctionBase.sol";
import "../interface/IWBTM.sol";

contract AuctionOffer is AuctionBase {
    function applyAuctionOffer(
        address _erc721Address,
        uint256 _tokenId,
        uint128 _offerPrice,
        uint128 _deposit,
        uint64 _deadline
    ) external mutex whenNotPaused {
        // check auction offer valid deadline
        require(_deadline > uint64(block.timestamp), "Deadline is invalid.");

        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        // check auction parameter
        _checkAuctionParam(auctionParam);

        // check auction
        if (auctionParam.auctionType == AuctionType.Radical) {
            RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller != msg.sender, "Can't offer own auction.");
            require(_deposit > 0, "Invalid auction deposit");
        }

        if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller != msg.sender, "Can't offer own auction.");
            require(_deposit == 0, "Invalid auction deposit");
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller != msg.sender, "Can't offer own auction.");
            require(_deposit == 0, "Invalid auction deposit");
        }

        // save gas
        address _erc20Address = auctionParam.erc20Address;
        if (_erc20Address == address(0)) {
            _erc20Address = wbtm;
        }

        uint256 dealPrice = uint256(_offerPrice);
        uint256 feeAmount = dealPrice / uint256(auctionParam.feeRatio);
        uint256 taxAmount = dealPrice / uint256(auctionParam.taxRatio);
        uint256 totalAmount = dealPrice + feeAmount + taxAmount + _deposit;

        if (auctionParam.auctionType == AuctionType.Radical) {
            require(IERC20(_erc20Address).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance.");
        } else {
            require(IERC20(_erc20Address).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance.");
        }

        Offer[] storage offers = contractTokenIdToOffers[_erc721Address][_tokenId];

        for (uint256 i = 0; i < offers.length; i++) {
            require(msg.sender != offers[i].buyer, "Only one offer.");
        }

        offers.push(Offer(msg.sender, _offerPrice, _deposit, _deadline));

        emit OfferCreated(_erc721Address, _tokenId, msg.sender, dealPrice);
    }

    function acceptAuctionOffer(
        address _erc721Address,
        uint256 _tokenId,
        address _buyer
    ) external mutex whenNotPaused {
        // check auction parameter
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        _checkAuctionParam(auctionParam);

        if (auctionParam.auctionType == AuctionType.Radical) {
            RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller == msg.sender, "Not auction seller.");
        }

        if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller == msg.sender, "Not auction seller.");
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
            require(auction.seller == msg.sender, "Not auction seller.");
        }

        // save gas
        address _erc20Address = auctionParam.erc20Address;
        address _taxReceiver = auctionParam.taxReceiver;

        Offer[] storage offers = contractTokenIdToOffers[_erc721Address][_tokenId];

        Offer memory acceptedOffer;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].buyer == _buyer) {
                acceptedOffer = offers[i];
                // remove buyer offer from array
                delete offers[i];
            }
        }

        require(acceptedOffer.buyer != address(0), "Invalid offer.");
        require(acceptedOffer.deadline > uint64(block.timestamp), "Expired offer.");

        uint256 dealPrice = acceptedOffer.offerPrice;
        uint256 feeAmount = dealPrice / uint256(auctionParam.feeRatio);
        uint256 taxAmount = dealPrice / uint256(auctionParam.taxRatio);

        if (_erc20Address != address(0)) {
            _safeTransferFrom(_erc20Address, _buyer, msg.sender, dealPrice);
            if (auctionParam.auctionType == AuctionType.Radical) {
                RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
                _safeTransfer(_erc20Address, msg.sender, uint256(auction.deposit));
            }
            _safeTransferFrom(_erc20Address, _buyer, feeReceiver, feeAmount);
            _safeTransferFrom(_erc20Address, _buyer, _taxReceiver, taxAmount);
            _safeTransferFrom(_erc20Address, _buyer, address(this), acceptedOffer.deposit);
        } else {
            uint256 totalAmount = dealPrice + feeAmount + taxAmount + acceptedOffer.deposit;
            _safeTransferFrom(_erc20Address, _buyer, address(this), totalAmount);
            IWBTM(wbtm).withdraw(totalAmount);
            payable(msg.sender).transfer(dealPrice);
            if (auctionParam.auctionType == AuctionType.Radical) {
                RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
                payable(msg.sender).transfer(uint256(auction.deposit));
            }
            payable(feeReceiver).transfer(feeAmount);
            payable(auctionParam.taxReceiver).transfer(taxAmount);
        }

        if (auctionParam.auctionType != AuctionType.Radical) {
            IERC721 erc721Contract = IERC721(_erc721Address);
            erc721Contract.safeTransferFrom(address(this), _buyer, _tokenId);
        }

        emit OfferAccepted(_erc721Address, _tokenId, _buyer, acceptedOffer.offerPrice);

        if (auctionParam.auctionType != AuctionType.Radical) {
            // cancel auction offers
            _cancelAuctionOffers(_erc721Address, _tokenId);
        }

        if (auctionParam.auctionType == AuctionType.Radical) {
            // will never underflow, checked in apply offer
            uint256 deposit = acceptedOffer.deposit;
            require(deposit > 0, "Invalid deposit.");

            RadicalAuction memory auction = RadicalAuction(_buyer, 0, uint128(deposit), uint64(block.timestamp));
            contractTokenIdToRadicalAuction[_erc721Address][_tokenId] = auction;

            emit AuctionCreated(_erc721Address, _tokenId, _buyer);
        }

        if (auctionParam.auctionType == AuctionType.Dutch) {
            delete contractTokenIdToDutchAuction[_erc721Address][_tokenId];

            emit AuctionCancelled(_erc721Address, _tokenId);
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            delete contractTokenIdToFixedAuction[_erc721Address][_tokenId];

            emit AuctionCancelled(_erc721Address, _tokenId);
        }
    }

    function cancelAuctionOffer(address _erc721Address, uint256 _tokenId) external mutex whenNotPaused {
        // check auction
        _checkAuction(_erc721Address, _tokenId);
        // cancel msg.sender's offer
        Offer[] storage offers = contractTokenIdToOffers[_erc721Address][_tokenId];
        for (uint256 i = 0; i < offers.length; i++) {
            Offer memory offer = offers[i];
            // only cancel msg.sender's offer
            if (offer.buyer == msg.sender) {
                // remove offer from array
                delete offers[i];
                // emit event
                emit OfferCancelled(_erc721Address, _tokenId, offer.buyer);
                return;
            }
        }
        revert("Offer not found.");
    }

    function cancelOffersWhenPaused(address _erc721Address, uint256 _tokenId) external whenPaused onlyOwner {
        // check auction
        _checkAuction(_erc721Address, _tokenId);
        // cancel offers
        _cancelAuctionOffers(_erc721Address, _tokenId);
    }

    function getAuctionOffer(address _erc721Address, uint256 _tokenId) external view returns (Offer[] memory) {
        return contractTokenIdToOffers[_erc721Address][_tokenId];
    }

    function _checkAuction(address _erc721Address, uint256 _tokenId) private view {
        AuctionParam memory auctionParam = contractToAuctionParams[_erc721Address];
        // check auction parameter
        _checkAuctionParam(auctionParam);

        if (auctionParam.auctionType == AuctionType.Radical) {
            RadicalAuction memory auction = contractTokenIdToRadicalAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
        }

        if (auctionParam.auctionType == AuctionType.Dutch) {
            DutchAuction memory auction = contractTokenIdToDutchAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
        }

        if (auctionParam.auctionType == AuctionType.Fixed) {
            FixedAuction memory auction = contractTokenIdToFixedAuction[_erc721Address][_tokenId];
            require(auction.startedAt != 0, "Auction is not start.");
        }
    }

    // cancel auction all offers when auction successful or auction canceled
    function _cancelAuctionOffers(address _erc721Address, uint256 _tokenId) internal {
        Offer[] storage offers = contractTokenIdToOffers[_erc721Address][_tokenId];
        // cancel all offers
        for (uint256 i = 0; i < offers.length; i++) {
            Offer memory offer = offers[i];
            // buyer is address(0) means offer already been canceled
            if (offer.buyer != address(0)) {
                // remove offer from array
                delete offers[i];
                emit OfferCancelled(_erc721Address, _tokenId, offer.buyer);
            }
        }
        // remove token auction offers from mapping
        delete contractTokenIdToOffers[_erc721Address][_tokenId];
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

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (auction/AuctionBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract AuctionBase is OwnableUpgradeable, PausableUpgradeable, IERC721Receiver {
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
        // optional - if the auction is settled in the ERC20 token or in native currency
        // if erc20Address == address(0) -> native currency
        address erc20Address;
    }

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

    // Represents an offer on an NFT
    struct Offer {
        // offer provider
        address buyer;
        // buy NFT price
        uint128 offerPrice;
        // new deposit amount only for radical auction
        uint128 deposit;
        // offer valid deadline
        uint64 deadline;
    }

    // address receive maze protocol fee
    address public feeReceiver;

    // WBTM contract address
    address public wbtm;

    // storage nft contract address to auction parameter
    mapping(address => AuctionParam) internal contractToAuctionParams;

    // storage nft contract address to nft radical auction
    mapping(address => mapping(uint256 => RadicalAuction)) internal contractTokenIdToRadicalAuction;

    // storage nft contract address to nft dutch auction
    mapping(address => mapping(uint256 => DutchAuction)) internal contractTokenIdToDutchAuction;

    // storage nft contract address to nft fixed auction
    mapping(address => mapping(uint256 => FixedAuction)) internal contractTokenIdToFixedAuction;

    // storage nft contract address to nft offers
    mapping(address => mapping(uint256 => Offer[])) internal contractTokenIdToOffers;

    // auction created event
    event AuctionCreated(address indexed contractAddress, uint256 indexed tokenId, address indexed seller);

    // auction successful event
    event AuctionSuccessful(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed winner,
        uint256 price
    );

    // auction cancelled event
    event AuctionCancelled(address indexed contractAddress, uint256 indexed tokenId);

    // offer created event
    event OfferCreated(address indexed contractAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);

    // offer accepted event
    event OfferAccepted(address indexed contractAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);

    // offer cancelled event
    event OfferCancelled(address indexed contractAddress, uint256 indexed tokenId, address indexed buyer);

    bool private locked;

    modifier mutex() {
        require(!locked, "Locked!");
        locked = true;
        _;
        locked = false;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _checkAuctionParam(AuctionParam memory auctionParam) internal pure {
        require(auctionParam.feeRatio > 0, "Invalid fee ratio.");
        require(auctionParam.taxRatio > 0, "Invalid tax ratio.");
        require(auctionParam.taxReceiver != address(0), "Invalid tax receiver");
    }

    // erc20 token transfer
    function _safeTransfer(
        address _erc20Address,
        address to,
        uint256 value
    ) internal {
        require(IERC20(_erc20Address).transfer(to, value), "Fail to transfer");
    }

    // erc20 token safe transfer
    function _safeTransferFrom(
        address _erc20Address,
        address from,
        address to,
        uint256 value
    ) internal {
        require(IERC20(_erc20Address).transferFrom(from, to, value), "Fail to transferFrom");
    }
}

/// SPDX-License-Identifier: MIT
/// Maze Protocol Contracts v1.0.0 (interface/IWBTM.sol)

pragma solidity ^0.8.0;

interface IWBTM {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}