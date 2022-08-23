// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

library libERC1155Fee {
    uint256 constant TYPE_DEFAULT = 0;
    uint256 constant TYPE_SALE = 1;
    uint256 constant TYPE_AUCTION = 2;

    struct Part {
        address payable account;
        uint256 value;
    }

    struct Data {
        uint256 nTokens;
        address payable collectableOwner;
        Part[] creators;
        bool isSecondary;
    }
}

interface IERC1155 {
    struct Royalties {
        address payable account;
        uint256 percentage;
    }

    function mint(
        address receiver,
        uint256 collectibleId,
        uint256 ntokens,
        bytes memory IPFS_hash,
        Royalties calldata royalties
    ) external;

    // function ownerOf(uint256 _collectableId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 ntokens,
        bytes calldata data
    ) external;

    // function safeBatchTransferFrom(
    //     address from,
    //     address to,
    //     uint256[] calldata id,
    //     uint256[] calldata ntokens,
    //     bytes calldata data
    // ) external;
}

contract AsnMarketplaceUpgradable is
    Initializable,
    AccessControlEnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC1155ReceiverUpgradeable
{
    using SafeMathUpgradeable for uint256;

    function initialize(
        address rootAdmin,
        libERC1155Fee.Part memory _maintainer,
        uint16 _maintainerInitialFee,
        IERC1155 _tokenerc1155
    ) public virtual initializer {
        __AsnMarketplaceUpgradable_init(
            rootAdmin,
            _maintainer,
            _maintainerInitialFee,
            _tokenerc1155
        );
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function __AsnMarketplaceUpgradable_init(
        address rootAdmin,
        libERC1155Fee.Part memory _maintainer,
        uint16 _maintainerInitialFee,
        IERC1155 _tokenerc1155
    ) internal initializer {
        __AsnMarketplaceUpgradable_init_unchained(
            rootAdmin,
            _maintainer,
            _maintainerInitialFee,
            _tokenerc1155
        );
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __Ownable_init_unchained();
    }

    function __AsnMarketplaceUpgradable_init_unchained(
        address rootAdmin,
        libERC1155Fee.Part memory _maintainer,
        uint16 _maintainerInitialFee,
        IERC1155 _tokenerc1155
    ) internal initializer {
        _setMaintainer(_maintainer, _maintainerInitialFee);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, rootAdmin);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setNftToken(_tokenerc1155);
    }

    mapping(uint256 => libERC1155Fee.Data) private tokenSaleData;
    mapping(uint256 => uint256) private saleStatus;
    mapping(uint256 => libERC1155Fee.Part) auction;
    mapping(uint256 => libERC1155Fee.Part) sale;
    libERC1155Fee.Part private maintainer;
    uint16 private maintainerInitialFee;

    IERC1155 public tokenerc1155;

    event StartAuction(
        address indexed tokenOwner,
        uint256 indexed collectableId,
        uint256 ntokens,
        uint256 basePrice
    );
    event StartSale(
        address indexed tokenOwner,
        uint256 indexed collectableId,
        uint256 ntokens,
        uint256 basePrice
    );
    event Buy(
        address indexed from,
        address indexed to,
        uint256 indexed collectableId,
        uint256 ntokens,
        uint256 price
    );
    event Bid(
        uint256 indexed collectableId,
        uint256 ntokens,
        address indexed currentBidder,
        uint256 biddingAmount
    );
    event PlaceBid(
        address indexed from,
        address indexed to,
        uint256 indexed collectableId,
        uint256 ntokens,
        uint256 price
    );
    event Cancel(uint256 indexed collectableId, uint256 ntokens);

    /**
     * @dev overriding the inherited {transferOwnership} function to reflect the admin changes into the {DEFAULT_ADMIN_ROLE}
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev overriding the inherited {grantRole} function to have a single root admin
     */
    function grantRole(bytes32 role, address account) public override {
        if (role == ADMIN_ROLE)
            require(
                getRoleMemberCount(ADMIN_ROLE) == 0,
                "exactly one address can have admin role"
            );

        super.grantRole(role, account);
    }

    /**
     * @dev modifier to check admin rights.
     * contract owner and root admin have admin rights
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) || owner() == _msgSender(),
            "Restricted to admin."
        );
        _;
    }

    /**
     * @dev modifier to check mint rights.
     * contract owner, root admin and minter's have mint rights
     */
    modifier onlyMinter() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(MINTER_ROLE, _msgSender()) ||
                owner() == _msgSender(),
            "Restricted to minter."
        );
        _;
    }

    /**
     * @dev This function is to change the root admin
     * exaclty one root admin is allowed per contract
     * only contract owner have the authority to add, remove or change
     */
    function changeRootAdmin(address newAdmin) public {
        address oldAdmin = getRoleMember(ADMIN_ROLE, 0);
        revokeRole(ADMIN_ROLE, oldAdmin);
        grantRole(ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev This function is to add a minter into the contract,
     * only root admin and contract owner have the authority to add them
     * but only the root admin can revoke them using {revokeRole}
     * minter or pauser can also self renounce the access using {renounceRole}
     */
    function addMinter(address account, bytes32 role) public onlyAdmin {
        if (role == MINTER_ROLE) _setupRole(role, account);
    }

    function getCurrentBid(uint256 collectableId)
        public
        view
        returns (libERC1155Fee.Part memory)
    {
        return auction[collectableId];
    }

    function cancel(uint256 collectableId) public {
        require(
            tokenSaleData[collectableId].collectableOwner == msg.sender,
            "Not owner of the token"
        );
        require(
            auction[collectableId].account == address(0),
            "cannot cancel if bidding has started "
        );

        tokenerc1155.safeTransferFrom(
            address(this),
            tokenSaleData[collectableId].collectableOwner,
            collectableId,
            tokenSaleData[collectableId].nTokens,
            ""
        );

        delete auction[collectableId];
        delete saleStatus[collectableId];
        delete sale[collectableId];

        emit Cancel(collectableId, tokenSaleData[collectableId].nTokens);
    }

    function _checkPercentageValue(uint256 _value) internal virtual {
        require(_value <= 5000, "maintainer fee cannot exceed half");
    }

    function _setNftToken(IERC1155 _nfttoken) internal virtual {
        tokenerc1155 = _nfttoken;
    }

    function updateNftToken(IERC1155 _nfttoken) public virtual onlyOwner {
        tokenerc1155 = _nfttoken;
    }

    function _setMaintainer(
        libERC1155Fee.Part memory _maintainer,
        uint16 _maintainerInitialFee
    ) internal virtual {
        require(_maintainer.account != address(0));
        _checkPercentageValue(_maintainer.value);
        _checkPercentageValue(_maintainerInitialFee);
        maintainer = _maintainer;
        maintainerInitialFee = _maintainerInitialFee;
    }

    /**
     * @dev This funtion is to update maintainer account address,
     * primary commission percentage and secondery commission percentage.
     */
    function updateMaintainer(
        libERC1155Fee.Part memory _maintainer,
        uint16 _maintainerInitialFee
    ) public onlyAdmin {
        _setMaintainer(_maintainer, _maintainerInitialFee);
    }

    /**
     * @dev This funtion is to update primary commission percentage.
     */

    function updatemaintainerInitialFee(uint16 _value) public onlyAdmin {
        _checkPercentageValue(_value);
        maintainerInitialFee = _value;
    }

    /**
     * @dev This funtion is to update Secondery commission percentage.
     */

    function updateMaintainerValue(uint256 _value) public onlyAdmin {
        _checkPercentageValue(_value);
        maintainer.value = _value;
    }

    /**
     * @dev This funtion is to return maintainer account address
     *
     */
    function getMaintainer() public view returns (address) {
        return maintainer.account;
    }

    /**
     * @dev This funtion is to return maintainer fee (secondery sale)
     *
     */

    function getMaintainerValue() public view returns (uint256) {
        return maintainer.value;
    }

    /**
     * @dev This funtion is to return maintainer fee (primary sale)
     *
     */
    function getMaintainerInitialFee() public view returns (uint16) {
        return maintainerInitialFee;
    }

    /**
     * @dev This funtion is to return current bidder, current bid, buy now price of auction with tekenId
     *
     */

    function getAuctionDetails(uint256 collectableId)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            address,
            uint256
        )
    {
        return (
            auction[collectableId].account,
            auction[collectableId].value,
            sale[collectableId].value,
            tokenSaleData[collectableId].collectableOwner,
            tokenSaleData[collectableId].nTokens
        );
    }

    function _setTokenSaleStatus(uint256 collectableId, uint256 status)
        internal
    {
        require(
            status == libERC1155Fee.TYPE_DEFAULT ||
                status == libERC1155Fee.TYPE_SALE ||
                status == libERC1155Fee.TYPE_AUCTION,
            "Invalid token sale status"
        );
        saleStatus[collectableId] = status;
    }

    function _setBasePrice(uint256 collectableId, uint256 basePrice) internal {
        require(
            auction[collectableId].account == address(0),
            "The auction is not yet closed"
        );

        auction[collectableId].value = basePrice;
    }

    function _setSalePrice(uint256 collectableId, uint256 salePrice) internal {
        //sale active
        sale[collectableId].value = salePrice;
    }

    function _returnCurrentBid(uint256 collectableId) internal {
        address payable currentBidder = auction[collectableId].account;
        uint256 currentBid = auction[collectableId].value;

        if (currentBidder != address(0)) {
            currentBidder.transfer(currentBid);
        }
    }

    function _setBidder(
        uint256 collectableId,
        address payable bidder,
        uint256 amount
    ) internal {
        require(
            saleStatus[collectableId] == libERC1155Fee.TYPE_AUCTION,
            "No active auction"
        );

        auction[collectableId].account = bidder;
        auction[collectableId].value = amount;
    }

    // As part of the lazy minting this mint function can be called by rootAdmin
    function mintAndTransfer(
        libERC1155Fee.Part[] memory creators,
        address receiver,
        uint256 collectableId,
        uint256 ntokens,
        bytes memory IPFS_hash
    ) public onlyMinter nonReentrant {
        require(
            !_isShareExceedsHalf(creators),
            "Creators share shouldn't exceed half of price"
        );

        for (uint256 i = 0; i < creators.length; i++) {
            tokenSaleData[collectableId].creators.push(creators[i]);
        }

        IERC1155.Royalties memory royalties = IERC1155.Royalties(
            creators[0].account,
            creators[0].value
        );

        tokenerc1155.mint(
            receiver,
            collectableId,
            ntokens,
            IPFS_hash,
            royalties
        );
        emit Buy(address(0), receiver, collectableId, ntokens, 0);
    }

    function mintAndStartAuction(
        uint256 startingPrice,
        uint256 salePrice,
        libERC1155Fee.Part[] memory creators,
        address payable collectableOwner,
        uint256 collectableId,
        uint256 ntokens,
        bytes memory IPFS_hash
    ) public onlyMinter {
        require(
            !_isShareExceedsHalf(creators),
            "Creators share shouldn't exceed half of price"
        );

        for (uint256 i = 0; i < creators.length; i++) {
            tokenSaleData[collectableId].creators.push(creators[i]);
        }
        tokenSaleData[collectableId].collectableOwner = collectableOwner;
        tokenSaleData[collectableId].nTokens = ntokens;

        IERC1155.Royalties memory royalties = IERC1155.Royalties(
            creators[0].account,
            creators[0].value
        );

        tokenerc1155.mint(
            address(this),
            collectableId,
            1,
            IPFS_hash,
            royalties
        );

        _setTokenSaleStatus(collectableId, libERC1155Fee.TYPE_AUCTION);
        _setBasePrice(collectableId, startingPrice);
        _setSalePrice(collectableId, salePrice);

        emit StartAuction(
            collectableOwner,
            collectableId,
            ntokens,
            startingPrice
        );
    }

    function mintAndStartSale(
        uint256 salePrice,
        libERC1155Fee.Part[] memory creators,
        address payable collectableOwner,
        uint256 collectableId,
        uint256 ntokens,
        bytes memory IPFS_hash
    ) public onlyMinter {
        require(
            !_isShareExceedsHalf(creators),
            "Creators share shouldn't exceed half of price"
        );

        for (uint256 i = 0; i < creators.length; i++) {
            tokenSaleData[collectableId].creators.push(creators[i]);
        }
        tokenSaleData[collectableId].collectableOwner = collectableOwner;
        tokenSaleData[collectableId].nTokens = ntokens;

        IERC1155.Royalties memory royalties = IERC1155.Royalties(
            creators[0].account,
            creators[0].value
        );

        tokenerc1155.mint(
            address(this),
            collectableId,
            ntokens,
            IPFS_hash,
            royalties
        );

        _setTokenSaleStatus(collectableId, libERC1155Fee.TYPE_SALE);
        _setSalePrice(collectableId, salePrice);

        emit StartSale(collectableOwner, collectableId, ntokens, salePrice);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     *
     * Always returns `IERC1155Receiver.onERC1155Received.selector`.
     * 0 default, 1 sale, 2 auction
     */
    function onERC1155Received(
        address,
        address _from,
        uint256 _collectableId,
        uint256 _ntokens,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        if (bytes(_data).length > 0) {
            (uint256 saleType, uint256 basePrice, uint256 salePrice) = abi
                .decode(_data, (uint256, uint256, uint256));

            if (saleType == libERC1155Fee.TYPE_SALE) {
                startSale(_from, salePrice, _collectableId, _ntokens);
            } else if (saleType == libERC1155Fee.TYPE_AUCTION) {
                startAuction(
                    _from,
                    basePrice,
                    salePrice,
                    _collectableId,
                    _ntokens
                );
            }
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function startAuction(
        address tokenOwner,
        uint256 startingPrice,
        uint256 salePrice,
        uint256 collectableId,
        uint256 ntokens
    ) internal {
        _setTokenSaleStatus(collectableId, libERC1155Fee.TYPE_AUCTION);
        _setBasePrice(collectableId, startingPrice);
        _setSalePrice(collectableId, salePrice);
        tokenSaleData[collectableId].collectableOwner = payable(tokenOwner);
        tokenSaleData[collectableId].nTokens = ntokens;

        emit StartAuction(address(this), collectableId, ntokens, startingPrice);
    }

    function startSale(
        address tokenOwner,
        uint256 salePrice,
        uint256 collectableId,
        uint256 ntokens
    ) internal {
        _setTokenSaleStatus(collectableId, libERC1155Fee.TYPE_SALE);
        _setSalePrice(collectableId, salePrice);
        tokenSaleData[collectableId].collectableOwner = payable(tokenOwner);
        tokenSaleData[collectableId].nTokens = ntokens;

        emit StartSale(tokenOwner, collectableId, ntokens, salePrice);
    }

    function bid(uint256 collectableId) public payable nonReentrant {
        require(
            saleStatus[collectableId] == libERC1155Fee.TYPE_AUCTION,
            "There is no active auction"
        );
        require(
            msg.value > auction[collectableId].value,
            "Insufficient fund to make a bid"
        );
        // require(!msg.sender.isContract(), "Contracts cannot do bidding");

        _returnCurrentBid(collectableId);
        _setBidder(collectableId, payable(msg.sender), msg.value);

        emit Bid(
            collectableId,
            tokenSaleData[collectableId].nTokens,
            msg.sender,
            msg.value
        );
    }

    function placeBid(uint256 collectableId) public payable nonReentrant {
        // When there is no active bidding, return the asset to the owner
        // else transfer the asset to the heigest bidder and initiate the payout process
        if (auction[collectableId].account == address(0)) {
            tokenerc1155.safeTransferFrom(
                address(this),
                tokenSaleData[collectableId].collectableOwner,
                collectableId,
                tokenSaleData[collectableId].nTokens,
                ""
            );
        } else {
            tokenerc1155.safeTransferFrom(
                address(this),
                auction[collectableId].account,
                collectableId,
                tokenSaleData[collectableId].nTokens,
                ""
            );
            _payout(collectableId, auction[collectableId].value);
        }

        emit PlaceBid(
            tokenSaleData[collectableId].collectableOwner,
            auction[collectableId].account,
            collectableId,
            tokenSaleData[collectableId].nTokens,
            auction[collectableId].value
        );

        delete saleStatus[collectableId];
        delete auction[collectableId];
    }

    function buy(address receiver, uint256 collectableId)
        public
        payable
        nonReentrant
    {
        require(
            sale[collectableId].value > 0,
            "This operation not permitted for this asset"
        );
        require(
            msg.value >= sale[collectableId].value,
            "Insufficient fund to purchase token"
        );

        if (saleStatus[collectableId] == libERC1155Fee.TYPE_AUCTION) {
            _returnCurrentBid(collectableId);
            delete saleStatus[collectableId];
            delete auction[collectableId];
        } else {
            require(
                saleStatus[collectableId] == libERC1155Fee.TYPE_SALE,
                "Invalid purchase type"
            );
        }

        _payout(collectableId, sale[collectableId].value);
        emit Buy(
            tokenSaleData[collectableId].collectableOwner,
            receiver,
            collectableId,
            tokenSaleData[collectableId].nTokens,
            sale[collectableId].value
        );
        tokenerc1155.safeTransferFrom(
            address(this),
            receiver,
            collectableId,
            1,
            ""
        );
        delete sale[collectableId];
    }

    // function buyBatch(
    //     address receiver,
    //     uint256[] calldata collectableIds,
    //     uint256[] calldata quantities
    // ) public payable nonReentrant {
    //     for (uint256 i = 0; i < collectableIds.length; i++) {
    //         require(
    //             sale[collectableIds[i]].value > 0,
    //             "This operation not permitted for this asset"
    //         );
    //         require(
    //             msg.value >= sale[collectableIds[i]].value,
    //             "Insufficient fund to purchase token"
    //         );
    //         if (saleStatus[collectableIds[i]] == libERC1155Fee.TYPE_AUCTION) {
    //             _returnCurrentBid(collectableIds[i]);
    //             delete saleStatus[collectableIds[i]];
    //             delete auction[collectableIds[i]];
    //         } else {
    //             require(
    //                 saleStatus[collectableIds[i]] == libERC1155Fee.TYPE_SALE,
    //                 "Invalid purchase type"
    //             );
    //         }
    //         _payout(collectableIds[i], sale[collectableIds[i]].value);
    //     }

    //     // emit Buy(
    //     //     tokenSaleData[collectableId].collectableOwner,
    //     //     receiver,
    //     //     collectableId,
    //     //     tokenSaleData[collectableId].nTokens,
    //     //     sale[collectableId].value
    //     // );
    //     tokenerc1155.safeBatchTransferFrom(
    //         address(this),
    //         receiver,
    //         collectableIds,
    //         quantities,
    //         ""
    //     );

    //     for (uint256 i = 0; i < collectableIds.length; i++) {
    //         delete sale[collectableIds[i]];
    //     }
    // }

    function _payout(uint256 collectableId, uint256 price) internal {
        uint256 creatorsPayment;
        uint256 maintainerPayment;
        uint256 ownerPayout = price;
        libERC1155Fee.Part[] storage creators = tokenSaleData[collectableId]
            .creators;

        if (tokenSaleData[collectableId].isSecondary) {
            maintainerPayment = price.mul(maintainer.value).div(10000);

            for (uint256 i = 0; i < creators.length; i++) {
                creatorsPayment = price.mul(creators[i].value).div(10000);
                ownerPayout = ownerPayout.sub(creatorsPayment);
                creators[i].account.transfer(creatorsPayment);
            }
        } else {
            maintainerPayment = price.mul(maintainerInitialFee).div(10000);

            if (creators.length >= 0) {
                creatorsPayment = price.sub(maintainerPayment).div(
                    creators.length
                );
            }
            for (uint256 i = 0; i < creators.length; i++) {
                ownerPayout = ownerPayout.sub(creatorsPayment);
                creators[i].account.transfer(creatorsPayment);
            }

            tokenSaleData[collectableId].isSecondary = true;
        }

        if (maintainer.account != address(0)) {
            maintainer.account.transfer(maintainerPayment);
            ownerPayout = ownerPayout.sub(maintainerPayment);
        }

        payable(tokenSaleData[collectableId].collectableOwner).transfer(
            ownerPayout
        );
    }

    function _isShareExceedsHalf(libERC1155Fee.Part[] memory creators)
        internal
        pure
        returns (bool)
    {
        uint256 accumulatedShare;
        for (uint256 i = 0; i < creators.length; i++) {
            accumulatedShare = accumulatedShare + creators[i].value;
        }
        return accumulatedShare > 5000;
    }
}

// SPDX-License-Identifier: MIT

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
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}