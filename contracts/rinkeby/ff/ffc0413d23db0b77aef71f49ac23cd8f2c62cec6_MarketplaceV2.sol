/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/interfaces/[email protected]



pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File contracts/WhiteList.sol


pragma solidity 0.8.4;

/// @title For whitelisting addresses
abstract contract Whitelist {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    mapping(address => bool) members;

    /// @dev Collectibles: For whitelisting members
    /// @dev Marketplace: Responsible for fund transfer, change in gross pay and transferring admin privileges
    address public owner;

    function initializeWhitelist(address _owner) internal {
        owner = _owner;
        members[owner] = true;
        emit MemberAdded(owner);
    }

    modifier onlyWhiteList() {
        require(isMember(msg.sender), "Only whitelisted.");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @notice Checks if supplied address is member or not
    /// @param _member Address to be checked
    /// @return Returns boolean
    function isMember(address _member) public view returns (bool) {
        return members[_member];
    }

    /// @notice Adds new address as whitelist member
    /// @param _member Address to be whitelisted
    function addMember(address _member) external onlyWhiteList {
        require(!isMember(_member), "Address is member already.");

        members[_member] = true;
        emit MemberAdded(_member);
    }

    /// @notice Removed existing address from whitelist
    /// @param _member Address to be removed
    function removeMember(address _member) external onlyWhiteList {
        require(isMember(_member), "Not member of whitelist.");

        delete members[_member];
        emit MemberRemoved(_member);
    }
}


// File contracts/MarketplaceV2.sol


pragma solidity 0.8.4;




/// @title Marketplace to list, sell and buy fixed price tokens
contract MarketplaceV2 is Whitelist {
    /// @dev For weth transfer in auction model
    IERC20 weth;

    struct saleStruct {
        uint256 amount; // minBidAmount in case of auction
        uint256 keyId; // index of listedTokenKeys - makes easier to trace
        address tokenOwner;
        bool active;
        bool isFixedPrice; // false, if auction
    }
    /// @dev To return data in required format
    struct saleResponseStruct {
        address contractAddress;
        uint32 tokenId;
        uint256 amount;
        address tokenOwner;
        bool isFixedPrice;
    }
    /// @dev Contains address and token Id
    struct KeyStruct {
        address contractAddress;
        uint32 tokenId;
    }
    /// @dev Contract Address to tokenID to Sell Token Struct. For easier access later
    mapping(address => mapping(uint256 => saleStruct)) public salesList;
    /// @dev Easier looping for data while retrieving
    KeyStruct[] public listedTokenKeys;

    bool private initialized;
    /// @dev Gross pay percent in terms of gross pay precent * 100 to support two decimal digits
    uint256 public grossPay;

    /// @notice Store owner address and gross pay
    /// @dev Supply commission percent multiplied by 100
    /// @param _commissionPercent Commission percent to calculate gross pay
    function initialize(uint256 _commissionPercent, address _weth) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        grossPay = (10000 - _commissionPercent);
        weth = IERC20(_weth);
        initializeWhitelist(msg.sender);
    }

    /// @notice Change of owner
    /// @param _prevOwner Address of the previous owner
    /// @param _newOwner Address of the new owner
    event OwnerAddressChanged(
        address indexed _prevOwner,
        address indexed _newOwner
    );

    /// @notice Change in Gross pay
    event GrossPayChanged(
        uint256 indexed _prevGrossPay,
        uint256 indexed _newGrossPay
    );

    /// @notice owner transferred funds to their address
    /// @param _amount In terms of wei
    event TransferredEthToOwner(uint256 _amount);

    /// @notice Token listed for sale
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _tokenOwner Owner of the token
    /// @param _amount Fixed price for buyer in Wei
    event TokenListed(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _tokenOwner,
        bool _isFixedPrice,
        uint256 _amount
    );

    /// @notice Seller updated the price
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _tokenOwner Owner of the token
    /// @param _prevAmount Price before the change
    /// @param _updatedAmount Price after the change
    event AmountUpdated(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _tokenOwner,
        uint256 _prevAmount,
        uint256 _updatedAmount
    );

    /// @notice Someone bought the token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token sold
    /// @param _tokenOwner Owner of the token
    /// @param _buyer Address of the buyer
    /// @param _netPay Amount paid to the seller/owner
    /// @param _commission Amount deducted as commission
    /// @param _royaltyReceiver Address of the original owner to receive royalty
    /// @param royaltyAmount Amount paid as royalty
    event TokenSold(
        address indexed _contractAddress,
        uint32 indexed _tokenId,
        address indexed _tokenOwner,
        address _buyer,
        uint256 _netPay,
        uint256 _commission,
        address _royaltyReceiver,
        uint256 royaltyAmount,
        bool _isFixedPrice
    );

    /// @notice Seller canceled the listing for sale
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    event ListingCanceled(
        address indexed _contractAddress,
        uint32 indexed _tokenId
    );

    /// modifiers
    modifier checkDuplicate(address _contractAddress, uint32 _tokenId) {
        require(
            !salesList[_contractAddress][_tokenId].active,
            "Duplicate listing."
        );
        _;
    }

    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0, "Must be greater than zero.");
        _;
    }

    modifier amountShouldBeAskingPrice(
        address _contractAddress,
        uint32 _tokenId
    ) {
        require(
            msg.value == salesList[_contractAddress][_tokenId].amount,
            "Asking price did not match."
        );
        _;
    }

    modifier amountShouldNotBeLessThanMinBidPrice(
        address _contractAddress,
        uint32 _tokenId,
        uint256 _amount
    ) {
        require(
            _amount >= salesList[_contractAddress][_tokenId].amount,
            "Min Bid price is higher."
        );
        _;
    }

    /// @notice Changes the existing owner
    /// @param _newOwner Address of the new owner
    /// @custom:modifier Only whitelist user can change the address
    function changeOwner(address _newOwner) external onlyWhiteList {
        owner = _newOwner;
        emit OwnerAddressChanged(msg.sender, _newOwner);
        delete _newOwner;
    }

    /// @notice Changes the existing gross pay
    /// @param _newCommissionPercent New commission percent multiplied by 100
    /// @custom:modifier Only whitelist user can change the gross pay
    function changeCommission(uint256 _newCommissionPercent)
        external
        onlyWhiteList
    {
        uint256 _grossPay = grossPay;
        grossPay = (10000 - _newCommissionPercent);
        emit GrossPayChanged(_grossPay, grossPay);
        delete _grossPay;
        delete _newCommissionPercent;
    }

    /// @notice Transfers ETH to owner address
    /// @param _amount Amount to be transferred in Wei
    /// @custom:modifier Only whitelist user can transfer funds
    function transferEthToOwner(uint256 _amount) external onlyWhiteList {
        payable(owner).transfer(_amount);
        emit TransferredEthToOwner(_amount);
        delete _amount;
    }

    /// @notice Lists token for sell by owner
    /// @dev Approval part handled in the frontend
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _amount Amount for the token to be sold in Wei
    /// @custom:modifier No duplicate entry is allowed
    /// @custom:modifier Amount must be greater than zero
    /// @custom:modifier Only owner of the token can list token for sale
    /// @custom:modifier Owner should approve marketplace address for token tranfer
    function sellToken(
        address _contractAddress,
        uint32 _tokenId,
        uint256 _amount,
        bool _isFixedPrice
    )
        external
        checkDuplicate(_contractAddress, _tokenId)
        greaterThanZero(_amount)
    {
        address tokenOwner = getTokenOwner(_contractAddress, _tokenId);
        require((tokenOwner == msg.sender), "Only token owner.");

        require(
            IERC721(_contractAddress).isApprovedForAll(
                tokenOwner,
                address(this)
            ),
            "Approval required."
        );

        listedTokenKeys.push(KeyStruct(_contractAddress, _tokenId));
        salesList[_contractAddress][_tokenId] = saleStruct(
            _amount,
            listedTokenKeys.length - 1,
            msg.sender,
            true,
            _isFixedPrice
        );

        emit TokenListed(
            _contractAddress,
            _tokenId,
            msg.sender,
            _isFixedPrice,
            _amount
        );

        delete _contractAddress;
        delete _tokenId;
        delete _amount;
        delete tokenOwner;
    }

    /// @notice Updates amount for listed token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @param _amount Updated amount for the token to be sold in Wei
    /// @custom:modifier Only owner of the token can list token for sale
    function updateAmount(
        address _contractAddress,
        uint32 _tokenId,
        uint256 _amount
    ) external {
        require(
            (salesList[_contractAddress][_tokenId].tokenOwner == msg.sender),
            "Only token owner."
        );

        uint256 prevAmount = salesList[_contractAddress][_tokenId].amount;
        salesList[_contractAddress][_tokenId].amount = _amount;

        emit AmountUpdated(
            _contractAddress,
            _tokenId,
            msg.sender,
            prevAmount,
            _amount
        );

        delete _contractAddress;
        delete _tokenId;
        delete prevAmount;
        delete _amount;
    }

    /// @notice Cancels listed token
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @dev Triggered when token is transferred to other address
    /// @custom:modifier Only token owner or holding contract of the token can list token for sale
    function cancelListing(address _contractAddress, uint32 _tokenId) external {
        require(
            (salesList[_contractAddress][_tokenId].tokenOwner == msg.sender) ||
                _contractAddress == msg.sender,
            "Only token owner or collectible contract."
        );

        removeSale(_contractAddress, _tokenId);
        emit ListingCanceled(_contractAddress, _tokenId);
        delete _contractAddress;
        delete _tokenId;
    }

    /// @notice Buys token for the sender
    /// @dev payment is divided by 10000. 100 for percent and 100 for we manually added
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed to be bought
    /// @custom:modifier Amount should match
    /// @custom:modifier Owner should approve marketplace address for token tranfer
    function buyToken(address _contractAddress, uint32 _tokenId)
        external
        payable
        amountShouldBeAskingPrice(_contractAddress, _tokenId)
    {
        require(
            salesList[_contractAddress][_tokenId].isFixedPrice == true,
            "Sale type mismatch."
        );

        address royaltyReceiver;
        uint256 royaltyAmount;
        uint256 netAmount;
        uint256 commissionAmount;
        address tokenOwner = validateSale(
            _contractAddress,
            _tokenId,
            msg.sender
        );

        (
            netAmount,
            royaltyAmount,
            commissionAmount,
            royaltyReceiver
        ) = calculatePayment(_contractAddress, tokenOwner, _tokenId, msg.value);

        if (royaltyReceiver != address(0)) {
            payable(royaltyReceiver).transfer(royaltyAmount);
        }

        payable(tokenOwner).transfer(netAmount);
        IERC721(_contractAddress).safeTransferFrom(
            tokenOwner,
            msg.sender,
            _tokenId
        );

        emit TokenSold(
            _contractAddress,
            _tokenId,
            tokenOwner,
            msg.sender,
            netAmount,
            commissionAmount,
            royaltyReceiver,
            royaltyAmount,
            true
        );

        delete _contractAddress;
        delete _tokenId;
        delete commissionAmount;
        delete netAmount;
        delete tokenOwner;
        delete royaltyReceiver;
        delete royaltyAmount;
    }

    /// @notice Buys auction token for the sender
    /// @dev payment is divided by 10000. 100 for percent and 100 for we manually added
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed to be bought
    /// @param _buyer Address of the buyer
    /// @param _amount Amount in wei that the buyer agreed to buy the token for
    /// @custom:modifier Only whitelisted marketplace address can call the method
    /// @custom:modifier Amount should not be less than the minimum bid price
    /// @custom:modifier Buyer needs to provide approval for marketplace to transfer Weth from their account
    /// @custom:modifier Buyer must have enough Weth in their account
    /// @custom:modifier ValidateSale()
    function closeAuction(
        address _contractAddress,
        uint32 _tokenId,
        address _buyer,
        uint256 _amount
    )
        external
        onlyWhiteList
        amountShouldNotBeLessThanMinBidPrice(
            _contractAddress,
            _tokenId,
            _amount
        )
    {
        require(
            weth.allowance(_buyer, address(this)) >= _amount,
            "Buyer did not allow WETH for the contract."
        );

        require(
            salesList[_contractAddress][_tokenId].isFixedPrice == false,
            "Sale type mismatch."
        );

        require(
            weth.balanceOf(_buyer) >= _amount,
            "Buyer does not have enough balance."
        );

        address tokenOwner = validateSale(_contractAddress, _tokenId, _buyer);
        uint256 netAmount;
        uint256 royaltyAmount;
        uint256 commissionAmount;
        address royaltyReceiver;

        (
            netAmount,
            royaltyAmount,
            commissionAmount,
            royaltyReceiver
        ) = calculatePayment(_contractAddress, tokenOwner, _tokenId, _amount);

        if (royaltyReceiver != address(0)) {
            weth.transferFrom(_buyer, royaltyReceiver, royaltyAmount);
        }

        weth.transferFrom(_buyer, tokenOwner, netAmount);
        weth.transferFrom(_buyer, owner, commissionAmount);

        IERC721(_contractAddress).safeTransferFrom(
            tokenOwner,
            _buyer,
            _tokenId
        );

        emit TokenSold(
            _contractAddress,
            _tokenId,
            tokenOwner,
            _buyer,
            netAmount,
            commissionAmount,
            royaltyReceiver,
            royaltyAmount,
            false
        );

        delete _contractAddress;
        delete _tokenId;
        delete _buyer;
        delete _amount;
        delete tokenOwner;
        delete netAmount;
        delete royaltyAmount;
        delete commissionAmount;
        delete royaltyReceiver;
    }

    /// @notice Returns list of token listed for sale
    /// @dev Deleted tokens' slot will be occupied by zeros in the end of the array
    /// @return Sale list with details contract address, token id, amount and owner
    function getAllSales() external view returns (saleResponseStruct[] memory) {
        saleResponseStruct[] memory sales = new saleResponseStruct[](
            listedTokenKeys.length
        );
        uint256 _count = 0;

        for (uint256 index = 0; index < listedTokenKeys.length; index++) {
            saleResponseStruct memory saleRes;
            saleStruct memory sale = salesList[
                listedTokenKeys[index].contractAddress
            ][listedTokenKeys[index].tokenId];

            saleRes.contractAddress = listedTokenKeys[index].contractAddress;
            saleRes.tokenId = listedTokenKeys[index].tokenId;
            saleRes.amount = sale.amount;
            saleRes.tokenOwner = sale.tokenOwner;
            saleRes.isFixedPrice = sale.isFixedPrice;

            if (sale.active) {
                sales[_count] = saleRes;
                _count += 1;
            }
        }
        return sales;
    }

    /// @notice Validates if the sale taking place is valid or not
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale taking place
    /// @param _buyer Address of the buyer agreed to buy the token
    /// @custom:modifier Owner can not buy the token
    /// @custom:modifier Seller should approve marketplace for transfer of token
    /// @return Returns the owner address for futher use in the parent methods
    function validateSale(
        address _contractAddress,
        uint32 _tokenId,
        address _buyer
    ) private returns (address) {
        address tokenOwner = getTokenOwner(_contractAddress, _tokenId);
        require(tokenOwner != _buyer, "Owner can not buy token.");
        require(
            IERC721(_contractAddress).isApprovedForAll(
                tokenOwner,
                address(this)
            ),
            "Approval required."
        );

        removeSale(_contractAddress, _tokenId);

        delete _contractAddress;
        delete _tokenId;
        delete _buyer;

        return tokenOwner;
    }

    function calculatePayment(
        address _contractAddress,
        address tokenOwner,
        uint32 _tokenId,
        uint256 _amount
    )
        private
        returns (
            uint256,
            uint256,
            uint256,
            address
        )
    {
        address royaltyReceiver;
        uint256 royaltyAmount;

        if (IERC721(_contractAddress).supportsInterface(0x2a55205a)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(_contractAddress)
                .royaltyInfo(_tokenId, _amount);
            if (royaltyReceiver == tokenOwner || royaltyAmount == 0) {
                royaltyReceiver = address(0);
                royaltyAmount = 0;
            }
        }

        uint256 grossAmount = (_amount * grossPay) / 10000;
        uint256 commissionAmount = _amount - grossAmount;
        uint256 netAmount = grossAmount - royaltyAmount;

        require(
            _amount >= (netAmount + royaltyAmount + commissionAmount),
            "Either commission or royalty is too high."
        );

        return (netAmount, royaltyAmount, commissionAmount, royaltyReceiver);
    }

    /// @notice Delete sale from listing and key array
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale taking place
    function removeSale(address _contractAddress, uint32 _tokenId) private {
        if (salesList[_contractAddress][_tokenId].active) {
            delete listedTokenKeys[salesList[_contractAddress][_tokenId].keyId];
            delete salesList[_contractAddress][_tokenId];
            delete _contractAddress;
            delete _tokenId;
        }
    }

    /// @notice Returns owner of the ERC-721 token
    /// @dev Re-used multiple times
    /// @param _contractAddress Address of the contract holding the token
    /// @param _tokenId Id of the token listed for sale
    /// @return Address of the token owner
    function getTokenOwner(address _contractAddress, uint32 _tokenId)
        private
        view
        returns (address)
    {
        return IERC721(_contractAddress).ownerOf(_tokenId);
    }
}