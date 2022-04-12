//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./TokenTracker.sol";

contract MutualAccess is ERC1155, Ownable, ReentrancyGuard, IERC2981 {
    using NFTBalanceTracker for NFTBalanceTracker.Balances;
    using NFTBalanceTracker for NFTBalanceTracker.TokenType;

    uint256 private anticDefaultPrimaryFeesPercent; // Global fee that Multeez collects
    uint256 private anticDefaultSecondaryFeesPercent;
    uint256 public contentCount; // Number of created contents

    uint16 private constant PERCENTAGE_DIVIDER = 10000;
    uint256 private constant UINT256_MAX = type(uint256).max;

    TokenTracker private tracker;

    // Describe a fee recipient
    struct RoyaltyRecipient {
        address recipient;
        uint256 feePercentage; // 10000 -> 100.00%
    }

    struct FeePercents {
        // 10000 -> 100.00%
        uint256 primaryPercent;
        uint256 secondaryPercent;
    }

    struct TicketTier {
        uint256 ticketPrice;
        uint256 initialTicketSupply;
        uint256 currentTicketSupply;
    }

    struct TicketTierInput {
        uint256 ticketPrice;
        uint256 initialTicketSupply;
    }

    // Describe a content
    struct Content {
        TicketTier[] tickets;
        string contentUrl;
        uint256 startTime;
        uint256 endTime;
        bool primarySaleEnded;
        address contentOwnerAddress;
        FeePercents royalties;
        FeePercents anticFees;
        RoyaltyRecipient[] royaltyRecipients;
    }

    // Maps content id to secondary ticket price
    mapping(uint256 => mapping(address => uint256))
        private secondaryTicketPrices;
    // Maps content id to content
    mapping(uint256 => Content) private content;
    mapping(uint256 => RoyaltyRecipient) private IERC2981royalties;

    /// Only the content creator can call this function
    error OnlyContentCreator();
    /// Failed due to the primary sale not ended
    error PrimarySaleNotEnded();
    /// The ticket is not for sale
    error TicketNotForSale();
    /// The caller/seller has an insufficient amount of tickets
    error InsufficientTickets();
    /// The caller has an insufficient amount of funds
    error InsufficientFunds();
    /// Called with an invalid argument
    error InvalidArgument();
    /// Ticket for the content already sold so cannot change the antic fee for the content
    error CannotReassignContentFees();

    constructor(
        address owner_,
        uint256 anticPrimaryFeesPercentage_,
        uint256 anticSecondaryFeesPercentage_
    ) ERC1155("") Ownable() {
        transferOwnership(owner_);

        contentCount = 0;
        anticDefaultPrimaryFeesPercent = anticPrimaryFeesPercentage_;
        anticDefaultSecondaryFeesPercent = anticSecondaryFeesPercentage_;
        tracker = new TokenTracker(owner_);
    }

    modifier onlyContentOwner(uint256 contentId) {
        if (msg.sender != content[contentId].contentOwnerAddress)
            revert OnlyContentCreator();
        _;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (IERC2981royalties[tokenId].recipient == address(0)) {
            revert InvalidArgument();
        }
        receiver = IERC2981royalties[tokenId].recipient;
        royaltyAmount =
            (IERC2981royalties[tokenId].feePercentage * salePrice) /
            PERCENTAGE_DIVIDER;
    }

    function setRoyaltyInfo(
        uint256 tokenId,
        address receiver,
        uint256 percentage
    ) external onlyOwner {
        if (receiver == address(0) || percentage > PERCENTAGE_DIVIDER) {
            revert InvalidArgument();
        }
        if (content[tokenId].contentOwnerAddress == address(0)) {
            revert InvalidArgument();
        }
        IERC2981royalties[tokenId].recipient = receiver;
        IERC2981royalties[tokenId].feePercentage = percentage;
    }

    function getTicketSupply(uint256 contentId)
        public
        view
        onlyOwner
        returns (uint256 totalAmount)
    {
        totalAmount = 0;
        for (
            uint256 ticketIndex = 0;
            ticketIndex < content[contentId].tickets.length;
            ticketIndex++
        ) {
            totalAmount += content[contentId]
                .tickets[ticketIndex]
                .currentTicketSupply;
        }
    }

    function getInitialTicketSupply(uint256 contentId)
        internal
        view
        returns (uint256 totalAmount)
    {
        totalAmount = 0;
        for (
            uint256 ticketIndex = 0;
            ticketIndex < content[contentId].tickets.length;
            ticketIndex++
        ) {
            totalAmount += content[contentId]
                .tickets[ticketIndex]
                .initialTicketSupply;
        }
    }

    //expireAfterHours set to 0 if content should never expire
    function addNewContent(
        TicketTierInput[] calldata tickets,
        RoyaltyRecipient[] calldata royaltyRecipients,
        FeePercents calldata royalties,
        uint256 expireAfterHours,
        string memory contentURL
    ) external {
        contentCount++;
        uint256 newContentId = contentCount;
        // solhint-disable-next-line
        uint256 timeNow = block.timestamp;

        // Verify that the fee percentages add up to 100%
        if (isFeeRecipientsValid(royaltyRecipients) == false)
            revert InvalidArgument();

        content[newContentId].contentUrl = contentURL;
        content[newContentId].startTime = timeNow;
        content[newContentId].primarySaleEnded = false;
        if (expireAfterHours > 0) {
            content[newContentId].endTime =
                timeNow +
                (expireAfterHours * 1 hours);
        } else {
            //content never expires
            content[newContentId].endTime = UINT256_MAX;
        }

        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            content[newContentId].royaltyRecipients.push(royaltyRecipients[i]);
        }
        for (uint256 i = 0; i < tickets.length; i++) {
            TicketTier memory t;
            t.initialTicketSupply = tickets[i].initialTicketSupply;
            t.currentTicketSupply = tickets[i].initialTicketSupply;
            t.ticketPrice = tickets[i].ticketPrice;
            content[newContentId].tickets.push(t);
        }

        // feeRecipientsMap[newContentId].length = new FeeRecipient[feeRecipients.length];
        content[newContentId].contentOwnerAddress = msg.sender;
        content[newContentId].royalties = royalties;
        content[newContentId]
            .anticFees
            .primaryPercent = anticDefaultPrimaryFeesPercent;
        content[newContentId]
            .anticFees
            .secondaryPercent = anticDefaultSecondaryFeesPercent;
        // Mint all the tickets to the creator
        _mint(
            content[newContentId].contentOwnerAddress,
            newContentId,
            getInitialTicketSupply(newContentId),
            ""
        );
    }

    // Set the content's owner
    // Must be called with the new desired content owner address and fee address
    // Note: Can only be called by the current content owner
    function setContentOwner(
        uint256 contentId,
        address contentOwnerAddress,
        RoyaltyRecipient[] calldata feeRecipients
    ) external onlyContentOwner(contentId) {
        if (content[contentId].primarySaleEnded == false)
            revert PrimarySaleNotEnded();
        if (isFeeRecipientsValid(feeRecipients) == false)
            revert InvalidArgument();

        content[contentId].contentOwnerAddress = contentOwnerAddress;
        delete content[contentId].royaltyRecipients;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            content[contentId].royaltyRecipients.push(feeRecipients[i]);
        }
    }

    // Returns the address of the current content owner
    function getContentOwnerAddress(uint256 contentId)
        public
        view
        returns (address contentOwnerAddress)
    {
        contentOwnerAddress = content[contentId].contentOwnerAddress;
    }

    function setContentRoyaltyRecipients(
        uint256 contentId,
        RoyaltyRecipient[] calldata royaltyRecipients
    ) external onlyContentOwner(contentId) {
        if (isFeeRecipientsValid(royaltyRecipients) == false)
            revert InvalidArgument();

        delete content[contentId].royaltyRecipients;
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            content[contentId].royaltyRecipients.push(royaltyRecipients[i]);
        }
    }

    function getContentRoyaltyRecipients(uint256 contentId)
        public
        view
        returns (RoyaltyRecipient[] memory royaltyRecipients)
    {
        royaltyRecipients = content[contentId].royaltyRecipients;
    }

    function getContentRoyaltyRecipient(uint256 contentId, address ownerAddress)
        public
        view
        returns (uint256 percent)
    {
        RoyaltyRecipient[] memory royaltyRecipients = content[contentId]
            .royaltyRecipients;
        percent = 0;
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            if (royaltyRecipients[i].recipient == ownerAddress) {
                percent = royaltyRecipients[i].feePercentage;
            }
        }
    }

    function getContentTimestamp(uint256 contentId)
        public
        view
        returns (uint256 startTime, uint256 endTime)
    {
        Content memory myContent = content[contentId];
        startTime = myContent.startTime;
        endTime = myContent.endTime;
    }

    // Returns true if access to the content is allowed, can return false for the following reasons:
    // accessAddress has no tickets
    // content's sale has not started or sale has ended
    function isAccessAllowed(uint256 contentId, address accessAddress)
        public
        view
        returns (bool accessAllowed)
    {
        // Check that the sale is ongoing
        Content memory myContent = content[contentId];
        accessAllowed =
            // TODO: Talk about keeping the time based logic
            /* solhint-disable */
            block.timestamp >= myContent.startTime && // Sale has started
            block.timestamp <= myContent.endTime && // Sale has not ended
            /* solhint-enable */
            (balanceOf(accessAddress, contentId) > 0); // address has at least 1 ticket
    }

    // Sets the fee percentage that Antic collects
    // Note: Can only be called by governance
    function setDefaultAnticFees(
        uint256 primaryFeePercentage,
        uint256 secondaryFeePercentage
    ) external onlyOwner {
        if (
            primaryFeePercentage > PERCENTAGE_DIVIDER ||
            secondaryFeePercentage > PERCENTAGE_DIVIDER
        ) {
            revert InvalidArgument();
        }

        anticDefaultPrimaryFeesPercent = primaryFeePercentage;
        anticDefaultSecondaryFeesPercent = secondaryFeePercentage;
    }

    // Returns the fee percentage that Antic collects
    // Note: Can only be called by governance
    function getDefaultAnticFees()
        public
        view
        onlyOwner
        returns (uint256 primaryFee, uint256 secondaryFee)
    {
        primaryFee = anticDefaultPrimaryFeesPercent;
        secondaryFee = anticDefaultSecondaryFeesPercent;
    }

    function setContentAnticFees(
        uint256 contentId,
        uint256 primaryFeePercentage,
        uint256 secondaryFeePercentage
    ) external onlyOwner {
        if (
            primaryFeePercentage > PERCENTAGE_DIVIDER ||
            secondaryFeePercentage > PERCENTAGE_DIVIDER
        ) {
            revert InvalidArgument();
        }

        if (getInitialTicketSupply(contentId) != getTicketSupply(contentId)) {
            revert CannotReassignContentFees();
        }
        content[contentId].anticFees.primaryPercent = primaryFeePercentage;
        content[contentId].anticFees.secondaryPercent = secondaryFeePercentage;
    }

    // Returns the fee percentage that Multeez collects
    // Note: Can only be called by governance
    function getContentAnticFees(uint256 contentId)
        public
        view
        onlyOwner
        returns (uint256 primaryFee, uint256 secondaryFee)
    {
        primaryFee = content[contentId].anticFees.primaryPercent;
        secondaryFee = content[contentId].anticFees.secondaryPercent;
    }

    function setSecondaryTicketPrice(
        uint256 contentId,
        uint256 secondaryTicketPrice
    ) external {
        if (balanceOf(msg.sender, contentId) == 0) revert InsufficientTickets();

        secondaryTicketPrices[contentId][msg.sender] = secondaryTicketPrice;
    }

    function getSecondaryTicketPrice(uint256 contentId, address sellerAddress)
        public
        view
        returns (bool isForSale, uint256 ticketPrice)
    {
        ticketPrice = secondaryTicketPrices[contentId][sellerAddress];
        isForSale = ticketPrice > 0;
    }

    function getFees(uint256 contentId)
        // view
        internal
        returns (uint256 anticFeePercent, uint256 royaltiesPercent)
    {
        anticFeePercent = content[contentId].primarySaleEnded
            ? content[contentId].anticFees.secondaryPercent
            : content[contentId].anticFees.primaryPercent;
        royaltiesPercent = content[contentId].primarySaleEnded
            ? content[contentId].royalties.secondaryPercent
            : content[contentId].royalties.primaryPercent;
    }

    function getPrimaryTicketPrice(uint256 contentId)
        public
        view
        returns (uint256)
    {
        for (
            uint256 ticketIndex;
            ticketIndex < content[contentId].tickets.length;
            ticketIndex++
        ) {
            if (
                content[contentId].tickets[ticketIndex].currentTicketSupply > 0
            ) {
                return content[contentId].tickets[ticketIndex].ticketPrice;
            }
        }

        return 0;
    }

    function decrementTicketSupply(uint256 contentId) internal {
        for (
            uint256 ticketIndex;
            ticketIndex < content[contentId].tickets.length;
            ticketIndex++
        ) {
            if (
                content[contentId].tickets[ticketIndex].currentTicketSupply > 0
            ) {
                content[contentId].tickets[ticketIndex].currentTicketSupply--;
                return;
            }
        }
    }

    function buyAccess(uint256 contentId, address payable ticketSeller)
        external
        payable
        nonReentrant
    {
        // If this is a secondary sale,
        // check that primary sale is complete and use the appropriate price
        uint256 ticketPrice = getPrimaryTicketPrice(contentId);
        (uint256 anticFeePercent, uint256 royaltiesPercent) = getFees(
            contentId
        ); // 5678 ==> 0.5678%

        // Check if the seller tries to sell his ticket before
        // the primary sale has ended
        bool isSellerTriesToSellBeforePrimaryEnded = ticketSeller !=
            content[contentId].contentOwnerAddress &&
            !content[contentId].primarySaleEnded;

        if (isSellerTriesToSellBeforePrimaryEnded == true)
            revert PrimarySaleNotEnded();

        // If primary sale ended, check for secondary sale
        // and fetch secondary ticket price
        if (content[contentId].primarySaleEnded == true) {
            (
                bool isForSale,
                uint256 secondaryTicketPrice
            ) = getSecondaryTicketPrice(contentId, ticketSeller);

            if (isForSale == false) revert TicketNotForSale();

            ticketPrice = secondaryTicketPrice;
        } else {
            // if primary ticket sale reduce the amount left for ticket of that type by 1
            decrementTicketSupply(contentId);
        }

        // Verify that the buyer sent enough Eth to buy the ticket
        if (ticketPrice > msg.value) revert InsufficientFunds();

        // Verify that the seller owns at least one ticket
        if (balanceOf(ticketSeller, contentId) == 0)
            revert InsufficientTickets();

        // Calculate Multeez fees before the ticket fee
        uint256 anticFees = calculateTicketFees(ticketPrice, anticFeePercent);

        //collect royalties fee
        if (royaltiesPercent > 0) {
            uint256 ticketFee = calculateTicketFees(
                ticketPrice,
                royaltiesPercent
            );
            // Used to keep track of unpaid fees as a result of
            // fractional fees (1432.45)
            uint256 leftoverFees = ticketFee;

            // Each fee recipient gets his share of the collected ticket fee
            for (
                uint256 i = 0;
                i < content[contentId].royaltyRecipients.length;
                i++
            ) {
                uint256 recipientFee = calculateTicketFees(
                    ticketFee,
                    content[contentId].royaltyRecipients[i].feePercentage
                );
                payable(content[contentId].royaltyRecipients[i].recipient)
                    .transfer(recipientFee);
                leftoverFees -= recipientFee;
            }

            // Seller will receive the the ticket price minus the ticket fee
            // plus the ticket fee leftover (if there are any)
            ticketPrice -= ticketFee;
            ticketPrice += leftoverFees;
        }

        // Send the ticket to the buyer
        this.safeTransferFrom(ticketSeller, msg.sender, contentId, 1, "");

        // Collect Antic fees
        payable(owner()).transfer(anticFees);
        ticketPrice -= anticFees;

        // Send ticket price to the seller.
        ticketSeller.transfer(ticketPrice);

        // If the last primary sale ticket is being sold, end primary sale
        // solhint-disable-next-line
        content[contentId].primarySaleEnded =
            ticketSeller == content[contentId].contentOwnerAddress &&
            balanceOf(ticketSeller, contentId) == 0 &&
            content[contentId].primarySaleEnded == false;
    }

    function createMoreTickets(
        uint256 contentId,
        TicketTierInput calldata additionalTicketInfo
    ) external {
        // Only the content creator can mint new tickets
        if (msg.sender != content[contentId].contentOwnerAddress)
            revert OnlyContentCreator();

        // Primary sale must end before new tickets can be minted
        if (content[contentId].primarySaleEnded == false)
            revert PrimarySaleNotEnded();
        TicketTier memory t;
        t.initialTicketSupply = additionalTicketInfo.initialTicketSupply;
        t.currentTicketSupply = additionalTicketInfo.initialTicketSupply;
        t.ticketPrice = additionalTicketInfo.ticketPrice;
        content[contentId].tickets.push(t);

        _mint(
            msg.sender,
            contentId,
            additionalTicketInfo.initialTicketSupply,
            ""
        );
    }

    function isPrimarySaleComplete(uint256 contentId)
        public
        view
        returns (bool)
    {
        return content[contentId].primarySaleEnded;
    }

    // Overide the ERC1155 setApprovalForAll to allow setting only this contract to be the operator
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155)
    {
        if (operator != address(this)) {
            revert InvalidArgument();
        }

        ERC1155.setApprovalForAll(operator, approved);
    }

    function calculateTicketFees(uint256 sellPrice, uint256 ticketFee)
        public
        pure
        returns (uint256 fee)
    {
        fee = (sellPrice * ticketFee) / PERCENTAGE_DIVIDER;
    }

    // Returns true if all the fee percentages add to 100%, false otherwise
    function isFeeRecipientsValid(RoyaltyRecipient[] calldata feeRecipients)
        public
        pure
        returns (bool isValid)
    {
        uint256 feeSum = 0;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            feeSum += feeRecipients[i].feePercentage;
        }
        isValid = (feeSum == PERCENTAGE_DIVIDER);
    }

    receive() external payable {}

    function emergencyWithdrawBalance() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/NFTBalanceTracker.sol";

contract TokenTracker is
    Ownable,
    ERC1155Receiver,
    IERC721Receiver,
    ReentrancyGuard
{
    using NFTBalanceTracker for NFTBalanceTracker.Balances;
    using NFTBalanceTracker for NFTBalanceTracker.TokenType;

    NFTBalanceTracker.Balances private _nftBalances;

    error InvalidArgument();

    constructor(address owner_) Ownable() {
        transferOwnership(owner_);
    }

    //
    // ERC721, ERC1155 Receiver
    //

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        _nftBalances.inc(
            NFTBalanceTracker.TokenType.ERC721,
            msg.sender,
            tokenId,
            1
        );

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) public virtual override returns (bytes4) {
        _nftBalances.inc(
            NFTBalanceTracker.TokenType.ERC1155,
            msg.sender,
            tokenId,
            amount
        );

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory tokenIds,
        uint256[] memory values,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(tokenIds.length == values.length, "Mismatched lengths");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _nftBalances.inc(
                NFTBalanceTracker.TokenType.ERC1155,
                msg.sender,
                tokenIds[i],
                values[i]
            );
        }

        return this.onERC1155BatchReceived.selector;
    }

    //
    // Emergency Withdraw
    //

    function emergencyWithdrawERC721(address operatorAddress, uint256 id)
        external
        onlyOwner
        nonReentrant
        returns (bool)
    {
        (bool exist, ) = _nftBalances.fetch(
            NFTBalanceTracker.TokenType.ERC721,
            operatorAddress,
            id
        );

        // Item not in balance
        if (exist == false) {
            return false;
        }

        // Transfer the token ownership to the governance
        ERC721 c = ERC721(operatorAddress);
        c.safeTransferFrom(address(this), owner(), id);
        // Decrease the sent amount from the balance
        _nftBalances.dec(
            NFTBalanceTracker.TokenType.ERC721,
            operatorAddress,
            id,
            1
        );

        return true;
    }

    function emergencyWithdrawERC1155(address operatorAddress, uint256 id)
        external
        onlyOwner
        nonReentrant
        returns (bool)
    {
        (bool exist, uint256 amount) = _nftBalances.fetch(
            NFTBalanceTracker.TokenType.ERC1155,
            operatorAddress,
            id
        );

        // Item not in balance
        if (exist == false) {
            return false;
        }

        // Transfer the token ownership to the governance
        ERC1155 c = ERC1155(operatorAddress);
        c.safeTransferFrom(address(this), owner(), id, amount, "");
        // Decrease the sent amount from the balance
        _nftBalances.dec(
            NFTBalanceTracker.TokenType.ERC1155,
            operatorAddress,
            id,
            amount
        );

        return true;
    }

    function emergencyWithdrawAllERC721(uint8 batchSize)
        external
        onlyOwner
        nonReentrant
        returns (bool)
    {
        if (batchSize == 0) {
            revert InvalidArgument();
        }

        (address[] memory addresses, uint256[] memory ids, ) = _nftBalances
            .fetchAll(NFTBalanceTracker.TokenType.ERC721);

        // If no ERC721 exist, return
        if (addresses.length == 0) {
            return false;
        }

        // Iterate over all the records
        for (uint256 i = 0; i < addresses.length; i++) {
            if (batchSize == 0) return true;
            batchSize--;

            ERC721 c = ERC721(addresses[i]);
            // Transfer the token ownership to the governance
            // Note: ERC721 are unique and you can't mint multiple
            // tokens with the same id.
            // That is why we send only 1 token and ignore the 'amounts' field
            c.safeTransferFrom(address(this), owner(), ids[i]);
            // Decrease the sent amount from the balance
            _nftBalances.dec(
                NFTBalanceTracker.TokenType.ERC721,
                addresses[i],
                ids[i],
                1
            );
        }

        return true;
    }

    function emergencyWithdrawAllERC1155(uint8 batchSize)
        external
        onlyOwner
        nonReentrant
        returns (bool)
    {
        if (batchSize == 0) {
            revert InvalidArgument();
        }

        (
            address[] memory addresses,
            uint256[] memory ids,
            uint256[] memory amounts
        ) = _nftBalances.fetchAll(NFTBalanceTracker.TokenType.ERC1155);

        // if no ERC1155 balance exist, return
        if (addresses.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            if (batchSize == 0) return true;
            batchSize--;

            ERC1155 c = ERC1155(addresses[i]);
            c.safeTransferFrom(address(this), owner(), ids[i], amounts[i], "");
            // Decrease the sent amount from the balance
            _nftBalances.dec(
                NFTBalanceTracker.TokenType.ERC1155,
                addresses[i],
                ids[i],
                amounts[i]
            );
        }

        return true;
    }

    //
    // Funds
    //

    receive() external payable {}

    function emergencyWithdrawBalance() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    //
    // Fetch
    //

    function fetchERC721(address operatorAddress, uint256 id)
        external
        view
        onlyOwner
        returns (bool exist)
    {
        (exist, ) = _nftBalances.fetch(
            NFTBalanceTracker.TokenType.ERC721,
            operatorAddress,
            id
        );
    }

    function fetchERC1155(address operatorAddress, uint256 id)
        external
        view
        onlyOwner
        returns (bool exist, uint256 amount)
    {
        (exist, amount) = _nftBalances.fetch(
            NFTBalanceTracker.TokenType.ERC1155,
            operatorAddress,
            id
        );
    }

    function fetchAllERC1155()
        external
        view
        onlyOwner
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return _nftBalances.fetchAll(NFTBalanceTracker.TokenType.ERC1155);
    }

    function fetchAllERC721()
        external
        view
        onlyOwner
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return _nftBalances.fetchAll(NFTBalanceTracker.TokenType.ERC721);
    }

    //
    // Interface support
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IterableAddressKeyToValueMap.sol";

/// @title NFTBalanceTracker
/// @author Amit Molek
/// @notice Provies the ability to track from which contract the token (ERC721/ERC1155)
/// came from, it's id and the amount of it
library NFTBalanceTracker {
    using IterableAddressKeyToValueMap for IterableAddressKeyToValueMap.Map;

    struct Balances {
        IterableAddressKeyToValueMap.Map _nfts1155;
        IterableAddressKeyToValueMap.Map _nfts721;
    }

    enum TokenType {
        ERC1155,
        ERC721
    }

    function _dec(
        IterableAddressKeyToValueMap.Map storage map,
        address addr,
        uint256 id,
        uint256 amount
    ) private returns (bool, uint256) {
        (bool exist, uint256 value) = map.tryGet(addr, id);

        // Item not in map
        if (exist == false) {
            return (false, 0);
        }

        // id's balance is empty, remove the entry
        if (value <= amount) {
            map.remove(addr, id);
            return (true, 0);
        } else {
            // Decrease amount from the balance
            uint256 updatedBalance = value - amount;
            map.set(addr, id, updatedBalance);
            return (true, updatedBalance);
        }
    }

    function _inc(
        IterableAddressKeyToValueMap.Map storage map,
        address addr,
        uint256 id,
        uint256 amount
    ) private returns (uint256) {
        uint256 toInc = amount;

        (bool exist, uint256 value) = map.tryGet(addr, id);
        if (exist == true) {
            toInc += value;
        }
        map.set(addr, id, toInc);

        return toInc;
    }

    function _fetchAll(IterableAddressKeyToValueMap.Map storage map)
        private
        view
        returns (
            address[] memory addresses,
            uint256[] memory ids,
            uint256[] memory amounts
        )
    {
        uint256 size = map.size();
        addresses = new address[](size);
        ids = new uint256[](size);
        amounts = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            (address addr, uint256 id, uint256 value) = map.at(i);

            addresses[i] = addr;
            ids[i] = id;
            amounts[i] = value;
        }
    }

    /// @notice Increase the balance of the token for the specific address & token id
    /// @param balances The balances object you want to work on
    /// @param token The token type (ERC721, ERC1155) you want to increase the balance of
    /// @param addr The address you want to increase the balance of
    /// @param id The token id you want to increase the balance of
    /// @param amount The amount you want to increase the balance
    /// @return uint256 Returns the new balance
    function inc(
        Balances storage balances,
        TokenType token,
        address addr,
        uint256 id,
        uint256 amount
    ) internal returns (uint256) {
        if (token == TokenType.ERC1155) {
            return _inc(balances._nfts1155, addr, id, amount);
        }
        // ERC721
        return _inc(balances._nfts721, addr, id, amount);
    }

    /// @notice Decrease the balance of the token for the specific address & token id
    /// @dev If the new balance is less than or equal to 0, the item is removed from the tracker
    /// @param balances The balances object you want to work on
    /// @param token The token type (ERC721, ERC1155) you want to decrease the balance of
    /// @param addr The address you want to decrease the balance of
    /// @param id The token id you want to decrease the balance of
    /// @param amount The amount you want to decrease the balance
    /// @return bool Returns true if the item exist, false otherwise
    /// @return uint256 Returns the new balance
    function dec(
        Balances storage balances,
        TokenType token,
        address addr,
        uint256 id,
        uint256 amount
    ) internal returns (bool, uint256) {
        if (token == TokenType.ERC1155) {
            return _dec(balances._nfts1155, addr, id, amount);
        }
        // ERC721
        return _dec(balances._nfts721, addr, id, amount);
    }

    /// @notice Fetches the balance amount of address & token id
    /// @param balances The balances object you want to work on
    /// @param token The token type (ERC721, ERC1155) you want to fetch the balance of
    /// @param addr The address you want to get the balance of
    /// @param id The token id you want to get the balance of
    /// @return bool Returns true if the item exist in the map, false otherwise
    /// @return uint256 Returns the balance amount
    function fetch(
        Balances storage balances,
        TokenType token,
        address addr,
        uint256 id
    ) internal view returns (bool, uint256) {
        if (token == TokenType.ERC1155) {
            return balances._nfts1155.tryGet(addr, id);
        }
        // ERC721
        return balances._nfts721.tryGet(addr, id);
    }

    /// @notice Explain to an end user what this does
    /// @dev Item at index i:
    /// addresses[i], token_ids[i], amounts[i]
    /// @param balances The balances object you want to work on
    /// @param token The token type (ERC721, ERC1155)
    /// you want to fetch the all the balances of
    /// @return address[] addresses Returns all the addresses that the token came from
    /// @return uint256[] token ids Returns all the token ids of the tokens
    /// @return uint256[] amounts Returns all the amounts of the tokens
    function fetchAll(Balances storage balances, TokenType token)
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        if (token == TokenType.ERC1155) {
            return _fetchAll(balances._nfts1155);
        }
        // ERC721
        return _fetchAll(balances._nfts721);
    }

    /// @notice Clears all the balances
    /// @param balances The balances object you want to clear
    /// @param token The token type (ERC721, ERC1155) you want to clear the balance of
    function clear(Balances storage balances, TokenType token) internal {
        if (token == TokenType.ERC1155) {
            balances._nfts1155.clear();
        }
        // ERC721
        balances._nfts721.clear();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title IterableAddressKeyToValueMap
/// @author Amit Molek
/// @notice This map provides mapping between [address & key] to a [value],
///         and also the ability to iterate over the map's items.
/// @dev The actual key used to index inside the map is the hash of address & key
library IterableAddressKeyToValueMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Item {
        address addr;
        uint256 key;
        uint256 value;
    }

    struct Map {
        // hash(address + key) = actual key
        EnumerableSet.Bytes32Set keys;
        mapping(bytes32 => Item) values;
    }

    /// @notice Set a value in the map.
    /// @dev
    /// @param map The map object you want to work on
    /// @param addr The address you want to set the value to
    /// @param key The key you want to set the value to
    /// @param value The value you want to set
    /// @return bool Returns true if the an iten was added to the map, false if the item already exists
    function set(
        Map storage map,
        address addr,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));

        map.values[hash].value = value;
        map.values[hash].addr = addr;
        map.values[hash].key = key;

        return map.keys.add(hash);
    }

    /// @notice Returns the item at index
    /// @dev Should not be called with invalid index (out of bounds).
    /// This map does'nt guarantee that item x will be always at index i,
    /// use tryGet to fetch items and use at to iterate over the map.
    /// @param map The map object you want to work on
    /// @param index The index you want to fetch the item from
    /// @return addr The address of the item
    /// @return key The key of the item
    /// @return value The value of the item
    function at(Map storage map, uint256 index)
        internal
        view
        returns (
            address addr,
            uint256 key,
            uint256 value
        )
    {
        bytes32 hash = map.keys.at(index);

        addr = map.values[hash].addr;
        key = map.values[hash].key;
        value = map.values[hash].value;
    }

    function _remove(Map storage map, bytes32 hash) private returns (bool) {
        delete map.values[hash];
        return map.keys.remove(hash);
    }

    /// @notice Removes an item from the map
    /// @param map The map object you want to remove from
    /// @param addr The address you want to remove the value from
    /// @param key The key you want to remove the value from
    /// @return bool Returns true if the item was removed, false if doesn't exist
    function remove(
        Map storage map,
        address addr,
        uint256 key
    ) internal returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        return _remove(map, hash);
    }

    /// @notice Clears all item from the map
    /// @param map The map object you want to clear
    function clear(Map storage map) internal {
        // Get the map length first, because
        // every time we removed an item from it, the length
        // decreases by 1
        uint256 length = map.keys.length();
        for (uint256 i = 0; i < length; i++) {
            // Always remove the item at index 0
            // because every iteration the map shrinks by 1
            // so we always remove the first item (n times)
            bytes32 hash = map.keys.at(0);
            _remove(map, hash);
        }
    }

    /// @notice Explain to an end user what this does
    /// @param map The map object you want work on
    /// @param addr The address you want to check if the map contains
    /// @param key The key you want to check if the map contains
    /// @return bool Returns true if the map contains the address & key, false otherwise
    function contains(
        Map storage map,
        address addr,
        uint256 key
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        return map.keys.contains(hash);
    }

    /// @notice The size of the map
    /// @param map The map object you want to check the size of
    /// @return uint256 Returns the size of the map (number of items)
    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length();
    }

    /// @notice Tries to get the item from the map
    /// @param map The map object you want to get the item from
    /// @param addr The address you want to get the value of
    /// @param key The key you want to get the value of
    /// @return bool Returns true if the item exist in the map, false otherwise
    /// @return uint256 The value of address & key
    function tryGet(
        Map storage map,
        address addr,
        uint256 key
    ) internal view returns (bool, uint256) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        uint256 v = map.values[hash].value;

        if (v == 0) {
            return (contains(map, addr, key), 0);
        } else {
            return (true, v);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}