/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IVault.sol


pragma solidity ^0.8.12;

interface IVault {
    function sendETH(address payable _to, uint256 _amount) external;

    function recieveERC20(
        address _token_address,
        address _from,
        uint256 _amount
    ) external;

    function sendERC20(
        address _token_address,
        address _to,
        uint256 _amount
    ) external;

    function recieveERC721(
        address _token_address,
        uint256 _tokenId,
        address _from
    ) external;

    function sendERC721(
        address _token_address,
        uint256 _tokenId,
        address _to
    ) external;
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IWhitelist.sol


pragma solidity ^0.8.12;

interface IWhitelist {
    function whitelistERC721Token(address _token_address) external;

    function whitelistERC20Token(address _token_address, uint256 _platform_fee)
        external;

    function getSupportedTokens() external view returns (address[] memory);

    function getPaymentTokens() external view returns (address[] memory);
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/ISwap.sol


pragma solidity ^0.8.12;

interface ISwap {
    function newSwapOffer(
        address _token_address,
        uint256 _tokenId,
        address[] memory offer_token_addresses,
        uint256[] memory offer_tokenIds,
        address[] memory payment_tokens,
        uint256[] memory _amounts,
        address caller,
        uint _value
    ) external payable;

    function cancelSwapOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function rejectSwapOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function acceptSwapOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function claimRejectedSwapOffer(uint256 _id,address caller) external;
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IListing.sol


pragma solidity ^0.8.12;

interface IListing {
    function listDirectSale(
        address _token_address,
        uint256 _tokenId,
        address[] memory _payment_tokens,
        uint256[] memory _prices,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    function listBuyNowPayLater(
        address _token_address,
        uint256 _tokenId,
        address payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    function listSwap(
        address _token_address,
        uint256 _tokenId,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    function listDirectSale_BuyNowPayLater(
        address _token_address,
        uint256 _tokenId,
        address[] memory _sale_payment_tokens,
        uint256[] memory _sale_prices,
        address _bnpl_payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    function listBuyNowPayLater_Swap(
        address _token_address,
        uint256 _tokenId,
        address payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    function listDirectSale_Swap(
        address _token_address,
        uint256 _tokenId,
        address[] memory sale_payment_tokens,
        uint256[] memory sale_prices,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period,
        address caller,
        uint256 value
    ) external payable;

    // function listAllType(
    //     address _token_address,
    //     uint256 _tokenId,
    //     address[] memory sale_payment_tokens,
    //     uint256[] memory sale_prices,
    //     address payment_token,
    //     uint256 deposit,
    //     uint256 remaining_amount,
    //     uint256 duration,
    //     address[] memory token_addresses,
    //     address[] memory _payment_tokens,
    //     uint256[] memory _amounts,
    //     uint256 _time_period,
    //     address caller
    // ) external payable;

    function cancelListing(
        address _token_address,
        uint256 _tokenId,
        address caller
    ) external;

    function claimExpiredListing(
        address _token_address,
        uint256 _tokenId,
        address caller
    ) external;
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IParams.sol


pragma solidity ^0.8.12;

interface IParams {
    // structs
    struct Item {
        uint256 id;
        address token;
        uint256 tokenId;
        address owner;
        Status status;
        uint256 time_period;
        bool[] listingType;
        DirectListing directListing;
        BuyNowPayLaterListing bnplListing;
        SwapListing swapListing;
        BuyNowPayLaterOffer[] bnplOffers;
        SwapOffer[] swapOffers;
    }

    struct DirectListing {
        address[] payment_tokens;
        uint256[] amounts;
    }

    struct BuyNowPayLaterListing {
        address payment_token;
        uint256 deposit;
        uint256 remaining_amount;
        uint256 duration;
        bool accpeted;
        address buyer;
        uint256 nextPaymentDate;
    }

    struct SwapListing {
        address[] token_addresses;
        address[] payment_tokens;
        uint256[] amounts;
    }

    struct BuyNowPayLaterOffer {
        address owner;
        address payment_token;
        uint256 deposit;
        uint256 remaining_amount;
        uint256 duration;
    }

    struct SwapOffer {
        address owner;
        address[] token_addresses;
        uint256[] tokenIds;
        address[] payment_tokens;
        uint256[] amounts;
    }

    enum Status {
        NOT_LISTED,
        LISTED,
        ON_HOLD,
        LOCKED
    }

    function setRejectedOffers(uint256 _itemId) external;

    function resetItem(uint256 _itemId) external;

    function paymentTokenSupported(address[] memory _payment_token)
        external
        view;

    function performChecks(
        address _token_address,
        uint256 _tokenId,
        Status _status
    ) external view returns (Item memory);

    function checkListingRequirement(
        address _token_address,
        uint256 _tokenId,
        uint256 _time_period,
        uint256 _value,
        address caller
    ) external;

    function getCurrentItem(
        address _token_address,
        uint256 _tokenId,
        address caller
    ) external returns (Item memory);

    function tokenSupported(address _token_address) external view;

    function getWhitelistedToken(address _token_address)
        external
        returns (bool);

    function setWhitelistedToken(address _token_address) external;

    function getPlatformFees(address _token_address) external returns (uint256);

    function setPlatformFees(address _token_address, uint256 _platform_fee)
        external;

    function getSupportedTokens() external view returns (address[] memory);

    function getPaymentTokens() external view returns (address[] memory);

    function markListed(uint256 id, uint256 _time_period) external;

    function directListing(
        address[] memory _payment_tokens,
        uint256[] memory _prices,
        uint256 id
    ) external;

    function buyNowPayLaterListing(
        address payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        uint256 id
    ) external;

    function swapListing(
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 id
    ) external;

    function startBuyNowPayLater(uint256 id, address caller) external;

    function addNewBuyNowPayLaterOffer(
        address caller,
        address _payment_token,
        uint256 _deposit,
        uint256 _remaining_amount,
        uint256 _duration,
        uint256 id
    ) external;

    function removeBuyNowPayLaterOffer(uint256 id, uint256 _offerId) external;

    function setItemOwner(uint256 id, address _currOwner) external;

    function addRejectedBuyNowPayLaterOffers(uint256 id, uint256 _offerId)
        external;

    function getRejectedBuyNowPayLaterOffers(address _currOwner)
        external
        returns (BuyNowPayLaterOffer[] memory);

    function deleteBuyNowPayLaterOffer(address caller, uint256 _id) external;

    function updateItemStatus(uint256 id, Status _status) external;

    function addNewSwapOffer(
        address caller,
        address[] memory offer_token_addresses,
        uint256[] memory offer_tokenIds,
        address[] memory payment_tokens,
        uint256[] memory _amounts,
        uint256 id
    ) external;

    function removeSwapOffer(uint256 id, uint256 _offerId) external;

    function addRejectedSwapOffer(uint256 id, uint256 _offerId) external;

    function getRejectedSwapOffers(address _currOwner)
        external
        returns (SwapOffer[] memory);

    function delteSwapOffer(address caller, uint256 _id) external;

    function getItemByAddress(address _token_address, uint256 _tokenId)
        external
        returns (Item memory);

    function getItemById(uint256 id) external returns (Item memory);

    function getItemId() external view returns (uint256);
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IGetters.sol


pragma solidity ^0.8.12;


interface IGetters {
    function getTokenDetails(address _token_address, uint _tokenId)external returns(string memory,string memory); 

    function getItemWithId(uint id)external returns(IParams.Item memory);

    function getItem(address _token_address, uint256 _tokenId)
        external
        returns (IParams.Item memory);

    function getListedItems() external returns (IParams.Item[] memory);

    function getPersonItems(address caller)
        external
        returns (IParams.Item[] memory);

    function getBuyNowPayLaterOffers(address _token_address, uint256 _tokenId)
        external
        returns (IParams.BuyNowPayLaterOffer[] memory);

    function getSwapOffers(address _token_address, uint256 _tokenId)
        external
        returns (IParams.SwapOffer[] memory);

    function getRejectedBuyNowPayLaterOffer(address caller)
        external
        returns (IParams.BuyNowPayLaterOffer[] memory);

    function getRejectedSwapOffer(address caller)
        external
        returns (IParams.SwapOffer[] memory);
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Interfaces/IBuyNowPayLater.sol


pragma solidity ^0.8.12;

interface IBuyNowPayLater {
    function buyTokenDirectly(
        address _token_address,
        uint256 tokenId,
        address caller,
        uint256 _value
    ) external payable;

    function buyNowPaylater(
        address _token_address,
        uint256 _tokenId,
        address caller,
        uint256 value
    ) external payable;

    function newBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        address _payment_token,
        uint256 _deposit,
        uint256 _remaining_amount,
        uint256 _duration,
        address caller,
        uint256 _value
    ) external payable;

    function cancelBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function payRemainingAmount(
        address _token_address,
        uint256 _tokenId,
        address caller,
        uint256 _value
    ) external payable;

    function rejectBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function acceptBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId,
        address caller
    ) external;

    function claimDefaultedPayment(
        address _token_address,
        uint256 _tokenId,
        address caller
    ) external;

    function claimRejectedBuyNowPayLaterOffer(uint256 _id, address caller)
        external;
}

// File: verified-sources/0xFa899d96a852ddcFB0A5630E607362492D2Bd05D/sources/contracts/Market/Contracts/Market.sol


pragma solidity ^0.8.12;









contract Market is Ownable {
    address private whitelistContract;
    address private listingContract;
    address private vaultContract;
    address private buyNowPayLaterContract;
    address private swapContract;

    function setWhitelist(address _whitelistContract) external onlyOwner {
        whitelistContract = _whitelistContract;
    }

    function setListing(address _listingContract) external onlyOwner {
        listingContract = _listingContract;
    }

    function setBuyNowPayLater(address _buyNowPayLaterContract)
        external
        onlyOwner
    {
        buyNowPayLaterContract = _buyNowPayLaterContract;
    }

    function setSwap(address _swapContract) external onlyOwner {
        swapContract = _swapContract;
    }

    function setVault(address _vaultContract) external onlyOwner {
        vaultContract = _vaultContract;
    }

    // Whitelisteing
    function whitelistERC721Token(address _token_address) external onlyOwner {
        IWhitelist(whitelistContract).whitelistERC721Token(_token_address);
    }

    function whitelistERC20Token(address _token_address, uint256 _platform_fee)
        external
        onlyOwner
    {
        IWhitelist(whitelistContract).whitelistERC20Token(
            _token_address,
            _platform_fee
        );
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return IWhitelist(whitelistContract).getSupportedTokens();
    }

    function getPaymentTokens() external view returns (address[] memory) {
        return IWhitelist(whitelistContract).getPaymentTokens();
    }

    // listing
    function listDirectSale(
        address _token_address,
        uint256 _tokenId,
        address[] memory _payment_tokens,
        uint256[] memory _prices,
        uint256 _time_period
    ) external payable {
        payable(vaultContract).transfer(msg.value);
        IListing(listingContract).listDirectSale(
            _token_address,
            _tokenId,
            _payment_tokens,
            _prices,
            _time_period,
            msg.sender,
            msg.value
        );
    }

    function listBuyNowPayLater(
        address _token_address,
        uint256 _tokenId,
        address payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        uint256 _time_period
    ) external payable {
        payable(vaultContract).transfer(msg.value);
        IListing(listingContract).listBuyNowPayLater(
            _token_address,
            _tokenId,
            payment_token,
            deposit,
            remaining_amount,
            duration,
            _time_period,
            msg.sender,
            msg.value
        );
    }

    function listSwap(
        address _token_address,
        uint256 _tokenId,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period
    ) external payable {
        IListing(listingContract).listSwap(
            _token_address,
            _tokenId,
            token_addresses,
            _payment_tokens,
            _amounts,
            _time_period,
            msg.sender,
            msg.value
        );
        payable(vaultContract).transfer(msg.value);
    }

    function listDirectSale_BuyNowPayLater(
        address _token_address,
        uint256 _tokenId,
        address[] memory _sale_payment_tokens,
        uint256[] memory _sale_prices,
        address _bnpl_payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        uint256 _time_period
    ) external payable {
        IListing(listingContract).listDirectSale_BuyNowPayLater(
            _token_address,
            _tokenId,
            _sale_payment_tokens,
            _sale_prices,
            _bnpl_payment_token,
            deposit,
            remaining_amount,
            duration,
            _time_period,
            msg.sender,
            msg.value
        );
        payable(vaultContract).transfer(msg.value);
    }

    function listBuyNowPayLater_Swap(
        address _token_address,
        uint256 _tokenId,
        address payment_token,
        uint256 deposit,
        uint256 remaining_amount,
        uint256 duration,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period
    ) external payable {
        IListing(listingContract).listBuyNowPayLater_Swap(
            _token_address,
            _tokenId,
            payment_token,
            deposit,
            remaining_amount,
            duration,
            token_addresses,
            _payment_tokens,
            _amounts,
            _time_period,
            msg.sender,
            msg.value
        );
        payable(vaultContract).transfer(msg.value);
    }

    function listDirectSale_Swap(
        address _token_address,
        uint256 _tokenId,
        address[] memory sale_payment_tokens,
        uint256[] memory sale_prices,
        address[] memory token_addresses,
        address[] memory _payment_tokens,
        uint256[] memory _amounts,
        uint256 _time_period
    ) external payable {
        IListing(listingContract).listDirectSale_Swap(
            _token_address,
            _tokenId,
            sale_payment_tokens,
            sale_prices,
            token_addresses,
            _payment_tokens,
            _amounts,
            _time_period,
            msg.sender,
            msg.value
        );
        payable(vaultContract).transfer(msg.value);
    }

    function cancelListing(address _token_address, uint256 _tokenId) external {
        IListing(listingContract).cancelListing(
            _token_address,
            _tokenId,
            msg.sender
        );
    }

    function claimExpiredListing(address _token_address, uint256 _tokenId)
        external
    {
        IListing(listingContract).claimExpiredListing(
            _token_address,
            _tokenId,
            msg.sender
        );
    }

    // buy now pay later
    function buyTokenDirectly(address _token_address, uint256 tokenId)
        external
        payable
    {
        payable(vaultContract).transfer(msg.value);
        IBuyNowPayLater(buyNowPayLaterContract).buyTokenDirectly(
            _token_address,
            tokenId,
            msg.sender,
            msg.value
        );
    }

    function buyNowPayLater(address _token_address, uint256 _tokenId)
        external
        payable
    {
        payable(vaultContract).transfer(msg.value);
        IBuyNowPayLater(buyNowPayLaterContract).buyNowPaylater(
            _token_address,
            _tokenId,
            msg.sender,
            msg.value
        );
    }

    function newBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        address _payment_token,
        uint256 _deposit,
        uint256 _remaining_amount,
        uint256 _duration
    ) external payable {
        if (_payment_token == address(0)) {
            payable(vaultContract).transfer(msg.value);
        } else {
            payable(vaultContract).transfer(msg.value);
            IVault(vaultContract).recieveERC20(
                _payment_token,
                msg.sender,
                _deposit
            );
        }

        IBuyNowPayLater(buyNowPayLaterContract).newBuyNowPayLaterOffer(
            _token_address,
            _tokenId,
            _payment_token,
            _deposit,
            _remaining_amount,
            _duration,
            msg.sender,
            msg.value
        );
    }

    function cancelBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        IBuyNowPayLater(buyNowPayLaterContract).cancelBuyNowPayLaterOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function payRemainingAmount(address _token_address, uint256 _tokenId)
        external
        payable
    {
        payable(vaultContract).transfer(msg.value);
        IBuyNowPayLater(buyNowPayLaterContract).payRemainingAmount(
            _token_address,
            _tokenId,
            msg.sender,
            msg.value
        );
    }

    function rejectBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        IBuyNowPayLater(buyNowPayLaterContract).rejectBuyNowPayLaterOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function acceptBuyNowPayLaterOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        IBuyNowPayLater(buyNowPayLaterContract).acceptBuyNowPayLaterOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function claimDefaultedPayment(address _token_address, uint256 _tokenId)
        external
    {
        IBuyNowPayLater(buyNowPayLaterContract).claimDefaultedPayment(
            _token_address,
            _tokenId,
            msg.sender
        );
    }

    function claimRejectedBuyNowPayLaterOffer(uint256 _id) external {
        IBuyNowPayLater(buyNowPayLaterContract)
            .claimRejectedBuyNowPayLaterOffer(_id, msg.sender);
    }

    // swap
    function newSwapOffer(
        address _token_address,
        uint256 _tokenId,
        address[] memory offer_token_addresses,
        uint256[] memory offer_tokenIds,
        address[] memory payment_tokens,
        uint256[] memory _amounts
    ) external payable {
        payable(vaultContract).transfer(msg.value);
        ISwap(swapContract).newSwapOffer(
            _token_address,
            _tokenId,
            offer_token_addresses,
            offer_tokenIds,
            payment_tokens,
            _amounts,
            msg.sender,
            msg.value
        );
    }

    function cancelSwap(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        ISwap(swapContract).cancelSwapOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function rejectSwapOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        ISwap(swapContract).rejectSwapOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function acceptSwapOffer(
        address _token_address,
        uint256 _tokenId,
        uint256 _offerId
    ) external {
        ISwap(swapContract).acceptSwapOffer(
            _token_address,
            _tokenId,
            _offerId,
            msg.sender
        );
    }

    function claimRejectedSwapOffer(uint256 id) external {
        ISwap(swapContract).claimRejectedSwapOffer(id, msg.sender);
    }
}