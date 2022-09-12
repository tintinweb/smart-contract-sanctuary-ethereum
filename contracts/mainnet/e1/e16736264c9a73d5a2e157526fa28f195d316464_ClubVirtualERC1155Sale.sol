/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.14;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.14;

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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function mint(
        address _to,
        uint256 no_of_tokens_to_create,
        string calldata _uri
    ) external;

    function tokensOwned(address holder) external returns (uint256[] memory);

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

    function contractSafeTransferFrom(
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IDataStorage {
    struct Affiliate {
        uint16 feePercent;
        address affiliateAddr;
    }

    function getSellerCommission(address _artist)
        external
        view
        returns (Affiliate[3] memory);

    function setRoyaltyData(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external;

    function nftRoyalty(address _nftContractAddress, uint256 _tokenId) external;

    function activateRoyalty(address _nftContractAddress, uint _tokenId)
        external;

    function getRoyaltyPercentage(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (uint);

    function getRoyaltyOwner(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (address);

    function isActivated(address _nftContractAddress, uint _tokenId)
        external
        view
        returns (bool);

    function setRoyaltyPercentage(
        address _nftContractAddress,
        uint _tokenId,
        uint256 _newPercentage
    ) external;

    function platformCommission() external view returns (uint16);

    function nftCommission() external view returns (uint16);

    function sellerCommission(address _artist) external view returns (uint16);
}

interface IClubVirtualERC1155 {
    function mint(
        address _to,
        uint256 no_of_tokens_to_create,
        string calldata _uri
    ) external returns (uint256);

    function contractSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 tokenAmount
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amountoftoken
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amountoftoken
    ) external;
}

/**
    @title ClubVirtual contract for ERC1155 tokens sale/purchase
    @custom:description This contract will use two other contracts 
    1. ERC1155 Token contract: The in-house token which will be used most often.Outside tokens are also 
    accepted.
    2. Data Storage contract: It will store royalty data and fees data that will be applied across the 
    marketplace.
    
    It will allow end users to Sell & Resell, Purchase, Change sale data, Get royalty, Withdraw Sale etc. 
    straight from contract.
*/
contract ClubVirtualERC1155Sale is Ownable, ReentrancyGuard {
    IDataStorage public dataStorage;
    address public platformERC1155NFT;

    event SaleCreated(
        uint indexed tokenID,
        address indexed nftContract,
        address seller,
        uint256 buyNowPrice
    );

    event Buy(
        uint indexed tokendID,
        address indexed nftContract,
        address seller,
        address buyer,
        uint256 price,
        uint256 fees
    );

    // Keeps account of all proposal for NFT purchase
    mapping(address => mapping(uint256 => mapping(address => Proposal)))
        public buyProposal;
    // Keeps account of all NFTs put on sale
    mapping(address => mapping(uint256 => mapping(address => Sale)))
        public nftContractSale;

    struct Proposal {
        address buyer;
        uint256 price;
    }

    struct Sale {
        address nftSeller;
        uint256 tokenAmount;
        uint256 buyNowPrice;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Given zero address");
        _;
    }

    /**
        @notice Change price of the NFT that seller put on sale
        @dev Only the owner can change the price of the NFT put on sale
        @param _buyNowPrice New buy price of the specified NFT token
    */
    function changeSaleERC1155Data(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _buyNowPrice
    ) external onlyOwner {
        Sale storage s = nftContractSale[_nftContractAddress][_tokenId][
            msg.sender
        ];
        s.buyNowPrice = _buyNowPrice;
    }

    /// @notice Initial Setup Required Before This Contract Is Functional
    function setInitData(address _platformERC1155NFT, IDataStorage _dataStorage)
        external
        onlyOwner
    {
        platformERC1155NFT = _platformERC1155NFT;
        dataStorage = _dataStorage;
    }

    function setPlatformNFT(address _platformERC1155NFT) public onlyOwner {
        platformERC1155NFT = _platformERC1155NFT;
    }

    /// @dev Sets Royalty Data in DataStorage contract
    function setRoyaltyData(
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external {
        require(msg.sender == platformERC1155NFT, "Only run on redeem");
        dataStorage.setRoyaltyData(
            platformERC1155NFT,
            _tokenId,
            _royaltyPercentage,
            _royaltyOwner
        );
    }

    /**
        @dev Creates sale of already existing NFTs; transfers the NFT unto itself and holds until 
        buy/withdraw happens. 
    */
    function createResaleERC1155(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _amountOfTokens,
        uint256 _price,
        uint32 _royaltyPercentage
    ) external {
        require(_price > 0, "Price less than 0");

        if (_nftContractAddress == platformERC1155NFT) {
            // Transfer tokens to this contract
            IClubVirtualERC1155(platformERC1155NFT).contractSafeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _amountOfTokens
            );
        } else {
            // Transfer tokens to this contract
            IClubVirtualERC1155(_nftContractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _amountOfTokens
            );
        }

        setupSale(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _amountOfTokens,
            _price,
            _royaltyPercentage
        );
    }

    /**
        @param _nftContractAddress Address of NFT Contract
        @param _tokenId Token ID of the NFT
        @param _seller Address of the Seller
        @param _amountOfTokens Amount of tokens to be put on Sale
        @param _price Price per token copy
        @param _royaltyPercentage Royalty percentage
    */
    function setupSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _amountOfTokens,
        uint256 _price,
        uint256 _royaltyPercentage
    ) internal {
        // setup Royalty
        if (
            dataStorage.getRoyaltyOwner(platformERC1155NFT, _tokenId) ==
            address(0)
        ) {
            dataStorage.setRoyaltyData(
                _nftContractAddress,
                _tokenId,
                _royaltyPercentage,
                msg.sender
            );
        }
        // setup sale
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId][
            _seller
        ];
        sale.tokenAmount = _amountOfTokens;
        sale.nftSeller = msg.sender;
        sale.buyNowPrice = _price;

        nftContractSale[_nftContractAddress][_tokenId][_seller] = sale;
    }

    /**
        @param  _amountOfTokens Number of tokens to mint and put on sale
        @param  _price Price per token
        @param  _royaltyPercentage Royalty Percentage
        @param  _uri URI
        @dev Mints the NFT and puts it on sale;Communicates with DataStorage and NFT Contract
    */
    function createSaleERC1155(
        uint256 _amountOfTokens,
        uint256 _price,
        uint32 _royaltyPercentage,
        string memory _uri
    ) external {
        // checks
        require(_price > 0, "Price less than 0");
        // Transfer tokens to this contract
        uint256 _tokenId = IClubVirtualERC1155(platformERC1155NFT).mint(
            address(this),
            _amountOfTokens,
            _uri
        );

        setupSale(
            platformERC1155NFT,
            _tokenId,
            msg.sender,
            _amountOfTokens,
            _price,
            _royaltyPercentage
        );

        emit SaleCreated(_tokenId, platformERC1155NFT, msg.sender, _price);
    }

    /**
        @dev Internal function responsible for paying the NFT Seller and the Admin
        @param _nftContractAddress Contract address of the NFT 
        @param _tokenId Token ID of the NFT
        @param _seller Seller's Address
        @param _totalPayable Total Payable Amount Including Any Fees
        @param _adminFees Admin Fees (Platform Fee + Seller Commission + NFT Commission)
    */
    function _buyNFT(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _buyNowPrice,
        uint256 _totalPayable,
        uint256 _adminFees
    ) internal {
        uint256 totalAmount = _totalPayable;
        // If there is royalty involved, pay the royalty owner
        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royaltypercentage
            uint royaltyAmount = (_buyNowPrice * (_royaltyPercentage)) /
                (10000);
            totalAmount -= royaltyAmount;
            payable(royaltyOwner).transfer(royaltyAmount);
            (bool _success, ) = payable(royaltyOwner).call{
                value: royaltyAmount
            }("");
            require(_success);
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        
        // Give out seller commission
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(_seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (_buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                totalAmount -= ownerAmount;
                (bool _success, ) = payable(sellerCommission[i].affiliateAddr)
                    .call{value: ownerAmount}("");
                require(_success, "Transfer Failed to Affiliate");
            }
        }

        totalAmount = totalAmount - _adminFees;

        address owner = owner();
        (bool success, ) = payable(owner).call{value: _adminFees}("");
        if (!success) {
            revert("Transfer Failed to Admin");
        }
        (bool success_, ) = payable(_seller).call{value: totalAmount}("");
        if (!success_) {
            revert("Transfer Failed to Seller");
        }

    }

    /**
        @notice Buyer can pay and buy the specified NFT
        @dev Buyer needs to pay extra platform fee when purchasing. 
        @param _seller Field is required because more than one people can have same NFT copies
    */
    function buyNFT(address _nftContractAddress, uint256 _tokenId, address _seller)
        public
        payable
        nonReentrant
    {
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId][
            _seller
        ];
        // Check if sale exists
        require(sale.buyNowPrice>0, "INVALID_SALE");
        require(msg.sender != sale.nftSeller, "Seller cannot buy own NFT");
        uint buyNowPrice= sale.buyNowPrice;
        // 1. Platform Fees
        uint256 platformFees = (buyNowPrice *
            dataStorage.platformCommission()) / (10000);
        uint256 totalPayable = buyNowPrice + platformFees;
        require(msg.value >= totalPayable, "Amount less than cost");
        _buyNFTWithEth(_nftContractAddress, _tokenId, _seller);

        IClubVirtualERC1155(_nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId,
            1
        );
    }

    /// @notice Buy the NFT with ETH/BNB/MATIC
    function _buyNFTWithEth(address _nftContractAddress, uint256 _tokenId, address _seller)
        internal
    {
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId][
            _seller
        ];
        uint buyNowPrice = sale.buyNowPrice;
        address seller = sale.nftSeller;
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);

        uint totalAmount = buyNowPrice + platformFees;
        // 2. Cut ownerAmount from Seller
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                totalAmount -= ownerAmount;
                (bool _success, ) = payable(sellerCommission[i].affiliateAddr)
                    .call{value: ownerAmount}("");
                require(_success, "TRANSFER_FAILED");
            }
        }

        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (buyNowPrice * (dataStorage.nftCommission())) /
            (10000);
        
        // Reset Sale Data
        if (sale.tokenAmount > 1) {
            sale.tokenAmount -= 1;
        } else {
            resetERC1155Sale(_nftContractAddress, _tokenId, _seller);
        }
        // Check Royalty Applicable
        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royalty Percentage
            uint royaltyAmount = (buyNowPrice * (_royaltyPercentage)) / (10000);
            totalAmount -= royaltyAmount;
            (bool _success, ) = payable(royaltyOwner).call{
                value: royaltyAmount
            }("");
            require(_success);
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        address owner = owner();
        uint256 adminFees = platformFees + nftFee;
        totalAmount -= adminFees;
        payable(owner).transfer(adminFees);
        (bool success, ) = payable(seller).call{value: totalAmount}("");
        if (!success) {
            revert();
        }
    }


    function resetERC1155Sale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        delete nftContractSale[_nftContractAddress][_tokenId][_seller];
    }

    /// @notice Accept the buy proposal that the proposer has put
    /// @dev Other buyers can still purchase the NFT for the normal price
    function acceptBuyProposal(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _proposedPrice,
        address _proposingBuyer
    ) public {
        require(
            msg.sender ==
                nftContractSale[_nftContractAddress][_tokenId][_seller]
                    .nftSeller,
            "Only Seller function"
        );
        buyProposal[_nftContractAddress][_tokenId][_seller]
            .buyer = _proposingBuyer;
        buyProposal[_nftContractAddress][_tokenId][_seller]
            .price = _proposedPrice;
    }

    /// @notice Buyers run this function and pay the price that they initially promised in proposal
    /// @dev Extra platform fee is to be paid on top of price.
    function buyFromProposalERC1155(
        address _nftContractAddress,
        uint256 _tokenId,
        address _seller
    ) external payable nonReentrant {
        address seller = nftContractSale[_nftContractAddress][_tokenId][_seller]
            .nftSeller;
        
        require(nftContractSale[_nftContractAddress][_tokenId][_seller]
            .buyNowPrice > 0, "INVALID_SALE");

        require(
            msg.sender ==
                buyProposal[_nftContractAddress][_tokenId][_seller].buyer,
            "Invalid Buyer"
        );
        require(msg.sender != seller, "Seller cannot buy own NFT");
        uint256 buyNowPrice = buyProposal[_nftContractAddress][_tokenId][
            _seller
        ].price;
        // 1. Platform Fee
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);
        uint256 totalPayable = buyNowPrice + platformFees;

        require(msg.value >= totalPayable, "Must be greater than NFT cost");

        _buyFromProposal(_nftContractAddress, _tokenId, _seller);

        // Transfer to buyer
        IClubVirtualERC1155(_nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId,
            1
        );
    }

    /// @notice Buy the NFT with ETH/BNB/MATIC
    function _buyFromProposal(address _nftContractAddress, uint256 _tokenId, address _seller)
        internal
    {
        Sale storage sale = nftContractSale[_nftContractAddress][_tokenId][
            _seller
        ];

        uint256 buyNowPrice = buyProposal[_nftContractAddress][_tokenId][
            _seller
        ].price;
        
        address seller = sale.nftSeller;
        uint256 platformFees = (buyNowPrice *
            (dataStorage.platformCommission())) / (10000);

        uint totalAmount = buyNowPrice + platformFees;
        // 2. Cut ownerAmount from Seller
        IDataStorage.Affiliate[3] memory sellerCommission;
        sellerCommission = dataStorage.getSellerCommission(seller);
        for (uint8 i = 0; i < sellerCommission.length; i++) {
            if (sellerCommission[i].feePercent > 0) {
                uint256 ownerAmount = (buyNowPrice *
                    (sellerCommission[i].feePercent)) / (10000);
                totalAmount -= ownerAmount;
                (bool _success, ) = payable(sellerCommission[i].affiliateAddr)
                    .call{value: ownerAmount}("");
                require(_success, "TRANSFER_FAILED");
            }
        }

        // 3. Cut NFT Commission from Seller
        uint256 nftFee = (buyNowPrice * (dataStorage.nftCommission())) /
            (10000);
        
        // Reset Sale Data
        if (sale.tokenAmount > 1) {
            sale.tokenAmount -= 1;
        } else {
            resetERC1155Sale(_nftContractAddress, _tokenId, _seller);
            delete buyProposal[_nftContractAddress][_tokenId][_seller];
        }
        // Check Royalty Applicable
        if (dataStorage.isActivated(_nftContractAddress, _tokenId)) {
            address royaltyOwner = dataStorage.getRoyaltyOwner(
                _nftContractAddress,
                _tokenId
            );
            uint _royaltyPercentage = dataStorage.getRoyaltyPercentage(
                _nftContractAddress,
                _tokenId
            );
            // 3. Cut Royalty Percentage
            uint royaltyAmount = (buyNowPrice * (_royaltyPercentage)) / (10000);
            totalAmount -= royaltyAmount;
            (bool _success, ) = payable(royaltyOwner).call{
                value: royaltyAmount
            }("");
            require(_success);
        } else {
            dataStorage.activateRoyalty(_nftContractAddress, _tokenId);
        }
        address owner = owner();
        uint256 adminFees = platformFees + nftFee;
        totalAmount -= adminFees;
        payable(owner).transfer(adminFees);
        (bool success, ) = payable(seller).call{value: totalAmount}("");
        if (!success) {
            revert();
        }
    }

    /// @notice Seller can withdraw their sale at any time
    function withdrawERC1155Sale(address _nftContractAddress, uint256 _tokenId)
        external
    {
        address seller = nftContractSale[_nftContractAddress][_tokenId][
            msg.sender
        ].nftSeller;
        require(msg.sender == seller, "Only seller function");
        uint256 tokenAmount = nftContractSale[_nftContractAddress][_tokenId][
            msg.sender
        ].tokenAmount;
        resetERC1155Sale(_nftContractAddress, _tokenId, msg.sender);
        IClubVirtualERC1155(_nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId,
            tokenAmount
        );
    }

    /** 
        @notice Seller can change the sale data: Buy Price and Royalty Data (if not already activated)
        @dev If the first sale happens then royalty is activated, after that royalty cannot be changed**
    */
    function changeSaleERC1155(
        uint256 _tokenId,
        uint _buyNowPrice,
        uint _royaltyPercentage
    ) public {
        require(
            msg.sender ==
                nftContractSale[platformERC1155NFT][_tokenId][msg.sender]
                    .nftSeller,
            "Only Seller allowed"
        );
        nftContractSale[platformERC1155NFT][_tokenId][msg.sender]
            .buyNowPrice = _buyNowPrice;
        if (!dataStorage.isActivated(platformERC1155NFT, _tokenId)) {
            dataStorage.setRoyaltyPercentage(
                platformERC1155NFT,
                _tokenId,
                _royaltyPercentage
            );
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}