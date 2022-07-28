// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketplaceCore.sol";
import "../erc-721/IEndemicMasterNFT.sol";
import "../fee/IFeeProvider.sol";

contract Marketplace is MarketplaceCore {
    /// @param _feeProvider - fee provider contract
    /// @param _masterNFT - master NFT contract
    /// @param _feeClaimAddress - address to claim fee between 0-10,000.
    /// @param _royaltiesProvider - royalyies provider contract
    function __Marketplace_init(
        IFeeProvider _feeProvider,
        IEndemicMasterNFT _masterNFT,
        IRoyaltiesProvider _royaltiesProvider,
        address _feeClaimAddress
    ) external initializer {
        require(_feeClaimAddress != address(0));

        __Context_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __TransferManager___init_unchained(
            _feeProvider,
            _masterNFT,
            _royaltiesProvider,
            _feeClaimAddress
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./TransferManager.sol";

import "./LibNFT.sol";

abstract contract MarketplaceCore is
    PausableUpgradeable,
    OwnableUpgradeable,
    TransferManager
{
    using AddressUpgradeable for address;

    mapping(bytes32 => LibAuction.Auction) internal idToAuction;

    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        bytes32 indexed id,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        address seller,
        uint256 amount,
        bytes4 assetClass
    );

    event AuctionSuccessful(
        bytes32 indexed id,
        uint256 indexed totalPrice,
        address winner,
        uint256 amount,
        uint256 totalFees
    );

    event AuctionCancelled(bytes32 indexed id);

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 amount,
        bytes4 assetClass
    ) external whenNotPaused {
        bytes32 auctionId = createAuctionId(nftContract, tokenId, _msgSender());

        LibAuction.Auction memory auction = LibAuction.Auction(
            auctionId,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            endingPrice,
            duration,
            amount,
            block.timestamp,
            assetClass
        );

        LibAuction.validate(auction);

        LibNFT.requireTokenOwnership(
            auction.assetClass,
            auction.contractId,
            auction.tokenId,
            amount,
            auction.seller
        );

        LibNFT.requireTokenApproval(
            auction.assetClass,
            auction.contractId,
            auction.tokenId,
            auction.seller
        );

        idToAuction[auctionId] = auction;

        emit AuctionCreated(
            nftContract,
            tokenId,
            auction.id,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.seller,
            amount,
            assetClass
        );
    }

    function bid(bytes32 id, uint256 tokenAmount)
        external
        payable
        whenNotPaused
    {
        LibAuction.Auction storage auction = idToAuction[id];

        require(LibAuction.isOnAuction(auction), "NFT is not on auction");
        require(auction.seller != _msgSender(), "Cant buy from self");
        require(
            auction.amount >= tokenAmount && tokenAmount >= 0,
            "Amount incorrect"
        );

        LibNFT.requireTokenOwnership(
            auction.assetClass,
            auction.contractId,
            auction.tokenId,
            tokenAmount,
            auction.seller
        );

        LibNFT.requireTokenApproval(
            auction.assetClass,
            auction.contractId,
            auction.tokenId,
            auction.seller
        );

        uint256 price = LibAuction.currentPrice(auction) * tokenAmount;
        require(
            msg.value >= price,
            "Bid amount can not be lower then auction price"
        );

        address seller = auction.seller;
        bytes32 auctionId = auction.id;
        address contractId = auction.contractId;
        uint256 tokenId = auction.tokenId;
        bytes4 assetClass = auction.assetClass;

        if (auction.assetClass == LibAuction.ERC721_ASSET_CLASS) {
            _removeAuction(auction);
        } else if (auction.assetClass == LibAuction.ERC1155_ASSET_CLASS) {
            _deductFromAuction(auction, tokenAmount);
        } else {
            revert("Invalid asset class");
        }

        uint256 totalFees = _transferFunds(
            contractId,
            tokenId,
            seller,
            _msgSender(),
            price
        );

        _transferNFT(
            seller,
            _msgSender(),
            contractId,
            tokenId,
            tokenAmount,
            assetClass
        );

        emit AuctionSuccessful(
            auctionId,
            price,
            _msgSender(),
            tokenAmount,
            totalFees
        );
    }

    function cancelAuction(bytes32 id) external {
        LibAuction.Auction storage auction = idToAuction[id];
        require(LibAuction.isOnAuction(auction), "Invalid auction");
        require(_msgSender() == auction.seller, "Sender is not seller");
        _cancelAuction(auction);
    }

    function cancelAuctionWhenPaused(bytes32 id) external whenPaused onlyOwner {
        LibAuction.Auction storage auction = idToAuction[id];
        require(LibAuction.isOnAuction(auction));
        _cancelAuction(auction);
    }

    function getAuction(bytes32 id)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt,
            uint256 amount
        )
    {
        LibAuction.Auction storage auction = idToAuction[id];
        require(LibAuction.isOnAuction(auction), "Not on auction");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt,
            auction.amount
        );
    }

    function getCurrentPrice(bytes32 id) external view returns (uint256) {
        LibAuction.Auction storage auction = idToAuction[id];
        require(LibAuction.isOnAuction(auction));
        return LibAuction.currentPrice(auction);
    }

    function createAuctionId(
        address nftContract,
        uint256 tokenId,
        address seller
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(nftContract, "-", tokenId, "-", seller));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _cancelAuction(LibAuction.Auction storage auction) internal {
        bytes32 auctionId = auction.id;
        _removeAuction(auction);
        emit AuctionCancelled(auctionId);
    }

    function _removeAuction(LibAuction.Auction storage auction) internal {
        delete idToAuction[auction.id];
    }

    function _deductFromAuction(
        LibAuction.Auction storage auction,
        uint256 amount
    ) internal {
        idToAuction[auction.id].amount -= amount;
        if (idToAuction[auction.id].amount <= 0) {
            _removeAuction(auction);
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC721.sol";

interface IEndemicMasterNFT is IERC721 {
    function distributeShares() external payable;

    function balanceOf(address _owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFeeProvider {
    function getMakerFee(
        address seller,
        address nftContract,
        uint256 tokenId
    ) external view returns (uint256);

    function getTakerFee(address buyer) external view returns (uint256);

    function getMasterNftCut() external view returns (uint256);

    function onInitialSale(address nftContract, uint256 tokenId) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../erc-721/IERC721.sol";
import "../erc-1155/IERC1155.sol";
import "../erc-721/IEndemicMasterNFT.sol";
import "../fee/IFeeProvider.sol";
import "../royalties/IRoyaltiesProvider.sol";
import "./LibAuction.sol";

abstract contract TransferManager is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public masterNftShares;
    address public feeClaimAddress;

    IFeeProvider feeProvider;
    IEndemicMasterNFT masterNFT;
    IRoyaltiesProvider royaltiesProvider;

    function __TransferManager___init_unchained(
        IFeeProvider _feeProvider,
        IEndemicMasterNFT _masterNFT,
        IRoyaltiesProvider _royaltiesProvider,
        address _feeClaimAddress
    ) internal initializer {
        feeProvider = _feeProvider;
        masterNFT = _masterNFT;
        royaltiesProvider = _royaltiesProvider;
        feeClaimAddress = _feeClaimAddress;
    }

    function setRoyaltiesProvider(IRoyaltiesProvider _royaltiesProvider)
        external
        onlyOwner
    {
        royaltiesProvider = _royaltiesProvider;
    }

    function _computeMakerCut(
        uint256 price,
        address seller,
        address nftContract,
        uint256 tokenId
    ) internal view returns (uint256) {
        uint256 makerFee = feeProvider.getMakerFee(
            seller,
            nftContract,
            tokenId
        );

        return (price.mul(makerFee)).div(10000);
    }

    function _computeTakerCut(uint256 price, address buyer)
        internal
        view
        returns (uint256)
    {
        uint256 takerFee = feeProvider.getTakerFee(buyer);
        return (price.mul(takerFee)).div(10000);
    }

    function claimETH() external onlyOwner {
        uint256 claimableETH = address(this).balance.sub(masterNftShares);
        (bool success, ) = payable(feeClaimAddress).call{value: claimableETH}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function _transferFunds(
        address nftContract,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price
    ) internal returns (uint256 totalFees) {
        if (price > 0) {
            uint256 takerCut = _computeTakerCut(price, buyer);

            require(msg.value >= price.add(takerCut), "Not enough funds sent");

            (
                address royaltiesRecipient,
                uint256 royaltiesCut
            ) = _calculateRoyalties(nftContract, tokenId, price);

            uint256 makerCut = _computeMakerCut(
                price,
                seller,
                nftContract,
                tokenId
            );

            uint256 fees = takerCut.add(makerCut);
            uint256 sellerProceeds = price.sub(makerCut).sub(royaltiesCut);

            feeProvider.onInitialSale(nftContract, tokenId);

            if (royaltiesCut > 0) {
                (bool royaltiesSuccess, ) = payable(royaltiesRecipient).call{
                    value: royaltiesCut
                }("");
                require(royaltiesSuccess, "Royalties Transfer failed.");
            }

            if (fees > 0) {
                (bool feeTransferSuccess, ) = payable(feeClaimAddress).call{
                    value: fees
                }("");
                require(feeTransferSuccess, "Fee Transfer failed.");
            }

            (bool success, ) = payable(seller).call{value: sellerProceeds}("");
            require(success, "Transfer failed.");

            return fees;
        } else {
            revert("Invalid price");
        }
    }

    function _transferNFT(
        address owner,
        address receiver,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        bytes4 assetClass
    ) internal {
        if (assetClass == LibAuction.ERC721_ASSET_CLASS) {
            IERC721(nftContract).safeTransferFrom(owner, receiver, tokenId);
        } else if (assetClass == LibAuction.ERC1155_ASSET_CLASS) {
            IERC1155(nftContract).safeTransferFrom(
                owner,
                receiver,
                tokenId,
                amount,
                ""
            );
        } else {
            revert("Invalid asset class");
        }
    }

    function _calculateRoyalties(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 price
    ) internal view returns (address recipient, uint256 royaltiesCut) {
        (address account, uint256 royaltiesFee) = royaltiesProvider
            .getRoyalties(_tokenAddress, _tokenId);

        return (account, price.mul(royaltiesFee).div(10000));
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc-721/IERC721.sol";
import "../erc-1155/IERC1155.sol";
import "./LibAuction.sol";

library LibNFT {
    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);
    bytes4 public constant ERC1155_Interface = bytes4(0xd9b67a26);

    function validate(
        bytes4 assetClass,
        address contractId,
        uint256 tokenId,
        uint256 amount,
        address seller
    ) internal view {
        requireCorrectInterface(assetClass, contractId);
        requireTokenOwnership(assetClass, contractId, tokenId, amount, seller);
        requireTokenApproval(assetClass, contractId, tokenId, seller);
    }

    function isApproved(
        address _seller,
        address _nftContract,
        uint256 _tokenId
    ) internal view returns (bool) {}

    function requireCorrectInterface(bytes4 _assetClass, address _nftContract)
        internal
        view
    {
        if (_assetClass == LibAuction.ERC721_ASSET_CLASS) {
            require(
                IERC721(_nftContract).supportsInterface(ERC721_Interface),
                "Contract has an invalid ERC721 implementation"
            );
        } else if (_assetClass == LibAuction.ERC1155_ASSET_CLASS) {
            require(
                IERC1155(_nftContract).supportsInterface(ERC1155_Interface),
                "Contract has an invalid ERC1155 implementation"
            );
        } else {
            revert("Invalid asset class");
        }
    }

    function requireTokenOwnership(
        bytes4 assetClass,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address seller
    ) internal view {
        if (assetClass == LibAuction.ERC721_ASSET_CLASS) {
            require(
                IERC721(nftContract).ownerOf(tokenId) == seller,
                "Seller is not owner of the asset"
            );
        } else if (assetClass == LibAuction.ERC1155_ASSET_CLASS) {
            require(
                IERC1155(nftContract).balanceOf(seller, tokenId) >= amount,
                "Seller is not owner of the asset amount"
            );
        } else {
            revert("Invalid asset class");
        }
    }

    function requireTokenApproval(
        bytes4 assetClass,
        address nftContract,
        uint256 tokenId,
        address seller
    ) internal view {
        if (assetClass == LibAuction.ERC721_ASSET_CLASS) {
            IERC721 nft = IERC721(nftContract);
            require(
                nft.getApproved(tokenId) == address(this) ||
                    nft.isApprovedForAll(seller, address(this)),
                "Marketplace is not approved for the asset"
            );
        } else if (assetClass == LibAuction.ERC1155_ASSET_CLASS) {
            require(
                IERC1155(nftContract).isApprovedForAll(seller, address(this)),
                "Marketplace is not approved for the asset"
            );
        } else {
            revert("Invalid asset class");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function supportsInterface(bytes4) external view returns (bool);

    function mint(address recipient, string calldata tokenURI)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function supportsInterface(bytes4) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltiesProvider {
    function getRoyalties(address nftContract, uint256 tokenId)
        external
        view
        returns (address account, uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibAuction {
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

    struct Auction {
        bytes32 id;
        address contractId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 duration;
        uint256 amount;
        uint256 startedAt;
        bytes4 assetClass;
    }

    function validate(Auction memory auction) internal pure {
        require(auction.duration >= 1 minutes, "Auction too short");
        require(
            auction.startingPrice >= 0.0001 ether &&
                auction.endingPrice >= 0.0001 ether,
            "Prices too low"
        );
        require(auction.startingPrice >= auction.endingPrice, "Prices invalid");

        if (auction.assetClass == ERC721_ASSET_CLASS) {
            require(auction.amount == 1, "Invalid amount");
        } else if (auction.assetClass == ERC1155_ASSET_CLASS) {
            require(auction.amount > 0, "Invalid amount");
        } else {
            revert("Invalid asset class");
        }
    }

    function isOnAuction(LibAuction.Auction storage auction)
        internal
        view
        returns (bool)
    {
        return (auction.startedAt > 0);
    }

    function currentPrice(LibAuction.Auction storage auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (block.timestamp > auction.startedAt) {
            secondsPassed = block.timestamp - auction.startedAt;
        }

        return
            computeCurrentPrice(
                auction.startingPrice,
                auction.endingPrice,
                auction.duration,
                secondsPassed
            );
    }

    function computeCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 secondsPassed
    ) internal pure returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (secondsPassed >= duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(endingPrice) -
                int256(startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = (totalPriceChange *
                int256(secondsPassed)) / int256(duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            return uint256(int256(startingPrice) + currentPriceChange);
        }
    }
}